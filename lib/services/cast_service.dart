import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../utils/no_album_helper.dart';

/// TV 연결 방식: DLNA(삼성·LG 스마트 TV) / 구글 캐스트(셋톱박스·크롬캐스트·구글 TV)
enum CastKind { dlna, google }

/// 같은 와이파이의 TV
class CastDevice {
  final String name;
  final CastKind kind;
  final String controlUrl; // DLNA: AVTransport 제어 주소
  final String host; // 구글 캐스트: 기기 IP
  const CastDevice(this.name, this.kind, {this.controlUrl = '', this.host = ''});
}

/// TV로 듣기
/// 1) 같은 와이파이에서 TV 찾기  2) 폰이 작은 서버가 되어 음악 파일을 TV에 보내기
/// 3) TV 재생/일시정지/정지  4) TV에서 곡이 끝나면 알려주기(다음 곡으로)
class CastService extends ChangeNotifier {
  CastService._();
  static final CastService instance = CastService._();

  CastDevice? _device;
  CastDevice? get device => _device;
  bool get isConnected => _device != null;

  bool _tvPlaying = false;
  bool get tvPlaying => _tvPlaying;

  String? _currentUri; // 지금 TV로 보낸 곡 파일 경로
  String? get currentUri => _currentUri;

  /// TV에서 곡이 끝났을 때 (재생화면에서 다음 곡으로 넘기게)
  VoidCallback? onTrackEnded;

  HttpServer? _server;
  String? _servingPath;
  Timer? _poll; // DLNA 상태 확인용
  bool _wasPlaying = false;
  DateTime _cmdAt = DateTime(2000); // 마지막으로 재생/일시정지 누른 시각
  // 누른 직후 2초는 TV가 보내는 예전 상태를 무시 (아이콘이 되돌아가는 것 방지)
  bool get _justCommanded => DateTime.now().difference(_cmdAt) < const Duration(seconds: 2);

  // ───── 파란포토 사진을 TV로 ─────
  Uint8List? _paranArt; // 파란포토 화면 그대로 찍은 사진 (null이면 곡 앨범 사진)
  /// 앨범 카드(인화 모양)를 곡마다 찍어주는 함수 — 재생화면이 열려 있을 때만 들어 있음
  Future<Uint8List?> Function(Song song)? cardArt;

  Future<Uint8List?> _cardArtFor(Song song) async {
    if (cardArt == null) return null;
    try {
      return await cardArt!(song).timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  /// 지금 곡의 TV 사진을 다시 만들어 보내기 (인화 모양을 바꿨을 때)
  Future<void> refreshArt() => setParanArt(_paranArt);
  int _artVer = 0; // 사진이 바뀔 때마다 주소를 바꿔서 TV가 새로 받게
  Song? _song; // 지금 TV로 보낸 곡
  Duration _posBase = Duration.zero; // TV 재생 위치 어림잡기 (사진 바꿀 때 같은 위치부터)
  DateTime _posAt = DateTime.now();
  Duration get _tvPos => _tvPlaying ? _posBase + DateTime.now().difference(_posAt) : _posBase;
  _GoogleCast? _gc; // 구글 캐스트 연결
Uint8List? _artBytes; // TV 화면에 보여줄 앨범 사진
bool _isRadio = false; // 라디오를 보내는 중인지 (라디오는 "곡 끝"이 없음)
Map<String, String> _proxyHeaders = const {}; // 라디오 방송국이 요구하는 헤더

  static const _channel = MethodChannel('kr.ssing.catsong/media');

  // ───────────────── 1) TV 찾기 ─────────────────
  Future<List<CastDevice>> discover({Duration timeout = const Duration(seconds: 4)}) async {
    final found = <String, CastDevice>{};
    final locations = <String>{};
    RawDatagramSocket? socket;
    try {
      // 일부 폰은 이걸 켜야 TV 응답을 받음
      try {
        await _channel.invokeMethod('multicastLock', {'on': true});
      } catch (_) {}
      // 모바일 데이터 말고 와이파이로 보내도록 와이파이 주소에 묶기
      final ip = await _wifiIp();
      socket = await RawDatagramSocket.bind(ip != null ? InternetAddress(ip) : InternetAddress.anyIPv4, 0);
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket!.receive();
        if (dg == null) return;
        final text = utf8.decode(dg.data, allowMalformed: true);
        final m = RegExp(r'^location:\s*(.+)$', caseSensitive: false, multiLine: true).firstMatch(text);
        if (m != null) locations.add(m.group(1)!.trim());
      });
      final target = InternetAddress('239.255.255.250');
      // 기기마다 대답하는 이름이 달라서 여러 가지로 물어봄
      const searchTypes = [
        'urn:schemas-upnp-org:service:AVTransport:1',
        'urn:schemas-upnp-org:device:MediaRenderer:1',
        'urn:dial-multiscreen-org:service:dial:1', // 구글 캐스트 기기
        'ssdp:all',
      ];
      for (var i = 0; i < 2; i++) {
        for (final st in searchTypes) {
          final msg = 'M-SEARCH * HTTP/1.1\r\n'
              'HOST: 239.255.255.250:1900\r\n'
              'MAN: "ssdp:discover"\r\n'
              'MX: 2\r\n'
              'ST: $st\r\n\r\n';
          socket.send(utf8.encode(msg), target, 1900);
        }
      }
      await Future.delayed(timeout);
    } catch (e) {
      debugPrint('TV 찾기 오류: $e');
    } finally {
      socket?.close();
      try {
        await _channel.invokeMethod('multicastLock', {'on': false});
      } catch (_) {}
    }

    // 찾은 기기들을 한 번에 확인 (TV로 보낼 수 있는 것만 골라냄)
    final results = await Future.wait(locations.map(_readDevice));
    for (final d in results) {
      if (d == null) continue;
      final key = d.kind == CastKind.google ? 'g:${d.host}' : d.controlUrl;
      found[key] = d;
    }
    return found.values.toList();
  }

  Future<CastDevice?> _readDevice(String location) async {
    try {
      final res = await http.get(Uri.parse(location)).timeout(const Duration(seconds: 3));
      final xml = utf8.decode(res.bodyBytes, allowMalformed: true);
      final name = _unescape(
          RegExp(r'<friendlyName>(.*?)</friendlyName>', dotAll: true).firstMatch(xml)?.group(1)?.trim() ?? 'TV');

      // 구글 캐스트 기기 (셋톱박스·크롬캐스트·구글 TV): 8008 포트 설명 주소
      if (location.contains(':8008/')) {
        return CastDevice(name, CastKind.google, host: Uri.parse(location).host);
      }

      // DLNA: AVTransport 서비스 안의 controlURL 찾기
      final services = RegExp(r'<service>(.*?)</service>', dotAll: true).allMatches(xml);
      for (final s in services) {
        final body = s.group(1)!;
        if (!body.contains('AVTransport')) continue;
        final ctrl = RegExp(r'<controlURL>(.*?)</controlURL>', dotAll: true).firstMatch(body)?.group(1)?.trim();
        if (ctrl == null) continue;
        final url = Uri.parse(location).resolve(ctrl).toString();
        return CastDevice(name, CastKind.dlna, controlUrl: url);
      }
    } catch (e) {
      debugPrint('TV 정보 읽기 오류: $e');
    }
    return null;
  }

  // ───────────────── 2) 연결 / 곡 보내기 ─────────────────
  Future<bool> connect(CastDevice device, Song song) async {
    _device = device; // 화면 갱신은 TV에서 실제로 재생된 뒤에 (castSong 안에서)
    try {
      if (device.kind == CastKind.google) {
        _gc = _GoogleCast(device.host);
        _gc!.onMediaStatus = _onGoogleStatus;
        await _gc!.connect();
      }
    } catch (e) {
      debugPrint('구글 캐스트 연결 오류: $e');
      _gc?.close();
      _gc = null;
      _device = null;
      notifyListeners();
      return false;
    }
    final ok = await castSong(song);
    if (!ok) {
      await disconnect();
      return false;
    }
    if (device.kind == CastKind.dlna) _startPolling();
    return true;
  }

  Future<bool> castSong(Song song) async {
    if (_device == null || song.uri == null) return false;
    _currentUri = song.uri; // 먼저 적어둬서 같은 곡을 여러 번 보내지 않게
    _isRadio = false;
    try {
      final url = await _serve(song.uri!);
      if (url == null) return false;
// TV 화면에 보여줄 앨범 사진 (없으면 기본 이미지)
_song = song;
// 파란포토 사진이 있으면 그걸, 없으면 곡 앨범 사진
_artBytes = _paranArt ?? (await _cardArtFor(song)) ?? await _artFor(song);
final artUrl = url.replaceFirst(RegExp(r'/song/.*$'), '/art/${song.uri.hashCode.abs()}_${_artVer++}.jpg');
      if (_device!.kind == CastKind.google) {
        await _gc!.load(url, _mime(song.uri!), song.titleDisplay, song.artistDisplay, artUrl);
      } else {
        final meta = _didl(song, url, artUrl);
        await _soap('SetAVTransportURI',
            '<InstanceID>0</InstanceID><CurrentURI>${_escape(url)}</CurrentURI>'
                '<CurrentURIMetaData>${_escape(meta)}</CurrentURIMetaData>');
        await _soap('Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
      }
      _tvPlaying = true;
      _wasPlaying = true;
      _posBase = Duration.zero; // 새 곡은 처음부터
      _posAt = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TV로 보내기 오류: $e');
      return false;
    }
  }

  // ───────────────── 라디오 보내기 ─────────────────
  /// 라디오: 처음 TV에 연결하면서 방송 보내기
  Future<bool> connectRadio(CastDevice device,
      {required String key,
      required String url,
      Map<String, String> headers = const {},
      required String title,
      String subtitle = '',
      String? logoUrl}) async {
    _device = device;
    try {
      if (device.kind == CastKind.google) {
        _gc = _GoogleCast(device.host);
        _gc!.onMediaStatus = _onGoogleStatus;
        await _gc!.connect();
      }
    } catch (e) {
      debugPrint('구글 캐스트 연결 오류: $e');
      _gc?.close();
      _gc = null;
      _device = null;
      notifyListeners();
      return false;
    }
    final ok = await castRadio(
        key: key, url: url, headers: headers, title: title, subtitle: subtitle, logoUrl: logoUrl);
    if (!ok) {
      await disconnect();
      return false;
    }
    if (device.kind == CastKind.dlna) _startPolling();
    return true;
  }

  /// 라디오: 방송 주소를 폰을 거쳐서 TV로 (방송국이 요구하는 헤더를 폰이 붙여줌)
  Future<bool> castRadio(
      {required String key,
      required String url,
      Map<String, String> headers = const {},
      required String title,
      String subtitle = '',
      String? logoUrl}) async {
    if (_device == null) return false;
    _currentUri = key; // 먼저 적어둬서 같은 방송을 여러 번 보내지 않게
    _isRadio = true;
    _proxyHeaders = headers;
    try {
      if (_server == null) {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        _server!.listen(_handle);
      }
      final ip = await _wifiIp();
      if (ip == null) return false;
      final proxied = 'http://$ip:${_server!.port}/p?u=${Uri.encodeComponent(url)}';
      // TV 화면에 보여줄 이미지 (로고가 없거나 너무 작으면 파란소리 라디오 사진)
      _artBytes = await _radioArt(logoUrl, key);
      final artUrl = _artBytes == null ? '' : 'http://$ip:${_server!.port}/art/r${key.hashCode.abs()}.jpg';
      final isHls = url.toLowerCase().contains('.m3u8');
      if (_device!.kind == CastKind.google) {
        await _gc!.load(proxied, isHls ? 'application/x-mpegurl' : 'audio/mpeg', title, subtitle, artUrl,
            live: true);
      } else {
        final mime = isHls ? 'application/vnd.apple.mpegurl' : 'audio/mpeg';
        final meta = '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
            'xmlns:dc="http://purl.org/dc/elements/1.1/" '
            'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
            '<item id="1" parentID="0" restricted="1">'
            '<dc:title>${_escape(title)}</dc:title>'
            '<upnp:artist>${_escape(subtitle)}</upnp:artist>'
            '${artUrl.isNotEmpty ? '<upnp:albumArtURI>${_escape(artUrl)}</upnp:albumArtURI>' : ''}'
            '<upnp:class>object.item.audioItem.audioBroadcast</upnp:class>'
            '<res protocolInfo="http-get:*:$mime:*">${_escape(proxied)}</res>'
            '</item></DIDL-Lite>';
        await _soap('SetAVTransportURI',
            '<InstanceID>0</InstanceID><CurrentURI>${_escape(proxied)}</CurrentURI>'
            '<CurrentURIMetaData>${_escape(meta)}</CurrentURIMetaData>');
        await _soap('Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
      }
      _tvPlaying = true;
      _wasPlaying = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('라디오 TV로 보내기 오류: $e');
      return false;
    }
  }

  /// 파란포토 사진 정하기 (null이면 곡 앨범 사진)
  /// TV로 듣는 중이면 지금 곡을 같은 위치에서 다시 보내서 TV 사진도 바꿈
  Future<void> setParanArt(Uint8List? bytes) async {
    _paranArt = bytes;
    if (_device == null || _isRadio || _song == null || _song!.uri == null) return;
    try {
      final song = _song!;
      final pos = _tvPos;
      final wasPlaying = _tvPlaying;
      final url = await _serve(song.uri!);
      if (url == null) return;
      _artBytes = _paranArt ?? (await _cardArtFor(song)) ?? await _artFor(song);
      final artUrl = url.replaceFirst(RegExp(r'/song/.*$'), '/art/${song.uri.hashCode.abs()}_${_artVer++}.jpg');
      _cmdAt = DateTime.now();
      if (_device!.kind == CastKind.google) {
        await _gc!.load(url, _mime(song.uri!), song.titleDisplay, song.artistDisplay, artUrl,
            startSec: pos.inSeconds);
      } else {
        final meta = _didl(song, url, artUrl);
        await _soap('SetAVTransportURI',
            '<InstanceID>0</InstanceID><CurrentURI>${_escape(url)}</CurrentURI>'
                '<CurrentURIMetaData>${_escape(meta)}</CurrentURIMetaData>');
        await _soap('Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
        final s = pos.inSeconds;
        final hms = '${s ~/ 3600}:${((s ~/ 60) % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
        try {
          await _soap('Seek', '<InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>$hms</Target>');
        } catch (_) {}
      }
      _cmdAt = DateTime.now(); // 다시 보내는 동안의 "멈춤"을 곡 끝으로 착각하지 않게
      _posBase = pos;
      _posAt = DateTime.now();
      _tvPlaying = true;
      _wasPlaying = true;
      if (!wasPlaying) await pause(); // 멈춰 있었으면 다시 멈춤
      notifyListeners();
    } catch (e) {
      debugPrint('TV 사진 바꾸기 오류: $e');
    }
  }

  // ───────────────── 3) TV 조작 ─────────────────
  Future<void> play() async {
    if (_device == null) return;
    _cmdAt = DateTime.now();
    _posAt = DateTime.now(); // 이어서 재생 → 여기서부터 다시 세기
    try {
      if (_device!.kind == CastKind.google) {
        _gc?.play();
      } else {
        await _soap('Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
      }
      _tvPlaying = true;
      _wasPlaying = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> pause() async {
    if (_device == null) return;
    _cmdAt = DateTime.now();
    if (_tvPlaying) _posBase = _tvPos; // 멈춘 위치 기억
    try {
      if (_device!.kind == CastKind.google) {
        _gc?.pause();
      } else {
        await _soap('Pause', '<InstanceID>0</InstanceID>');
      }
      _tvPlaying = false;
      _wasPlaying = false;
      notifyListeners();
    } catch (_) {}
  }

  /// 연결 끊기 (TV 정지)
  Future<void> disconnect() async {
    _poll?.cancel();
    _poll = null;
    if (_device != null) {
      try {
        if (_device!.kind == CastKind.google) {
          await _gc?.stop();
        } else {
          await _soap('Stop', '<InstanceID>0</InstanceID>');
        }
      } catch (_) {}
    }
    _gc?.close();
    _gc = null;
    _device = null;
    _tvPlaying = false;
    _wasPlaying = false;
    _currentUri = null;
    await _server?.close(force: true);
    _server = null;
    notifyListeners();
  }

  // ───────────────── 4) TV에서 곡이 끝났는지 확인 ─────────────────
  /// 구글 캐스트: TV가 상태를 알려줌
  void _onGoogleStatus(String state, String? idleReason) {
    if (_justCommanded && state != 'IDLE') return; // 방금 누른 거면 예전 상태 무시
    if (state == 'PLAYING' || state == 'BUFFERING') {
      if (!_tvPlaying) {
        _tvPlaying = true;
        notifyListeners();
      }
    } else if (state == 'PAUSED') {
      if (_tvPlaying) {
        _tvPlaying = false;
        notifyListeners();
      }
    } else if (state == 'IDLE' && idleReason == 'FINISHED') {
      _tvPlaying = false;
      notifyListeners();
      if (!_isRadio) onTrackEnded?.call(); // 곡 끝 → 다음 곡 (라디오는 제외)
    }
  }

  /// DLNA: 2초마다 TV 상태를 물어봄
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_device == null) return;
      try {
        final xml = await _soap('GetTransportInfo', '<InstanceID>0</InstanceID>');
        final state = RegExp(r'<CurrentTransportState>(.*?)</CurrentTransportState>').firstMatch(xml)?.group(1) ?? '';
        if (_justCommanded) return; // 방금 누른 거면 예전 상태 무시
        if (state == 'PLAYING') {
          _wasPlaying = true;
          if (!_tvPlaying) {
            _tvPlaying = true;
            notifyListeners();
          }
        } else if (state == 'PAUSED_PLAYBACK') {
          // TV 리모컨으로 멈춘 경우도 아이콘 맞추기
          if (_tvPlaying) {
            _tvPlaying = false;
            notifyListeners();
          }
        } else if (state == 'STOPPED' && _wasPlaying && _tvPlaying) {
          // 사용자가 멈춘 게 아니라 곡이 끝남 → 다음 곡
          _wasPlaying = false;
          _tvPlaying = false;
          notifyListeners();
          if (!_isRadio) onTrackEnded?.call();
        }
      } catch (_) {}
    });
  }

  // ───────────────── 폰을 작은 서버로 ─────────────────
  Future<String?> _serve(String path) async {
    _servingPath = path;
    if (_server == null) {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _server!.listen(_handle);
    }
    final ip = await _wifiIp();
    if (ip == null) return null;
    final ext = path.split('.').last.toLowerCase();
    // 곡마다 주소가 달라야 TV가 새 곡으로 인식
    return 'http://$ip:${_server!.port}/song/${path.hashCode.abs()}.$ext';
  }

  Future<void> _handle(HttpRequest req) async {
    // 라디오 중계: 방송국이 요구하는 헤더를 붙여서 받아 TV로 넘겨줌
if (req.uri.path == '/p') {
final target = req.uri.queryParameters['u'];
final r = req.response;
if (target == null) {
r.statusCode = HttpStatus.notFound;
await r.close();
return;
}
final client = HttpClient();
try {
final up = await client.getUrl(Uri.parse(target));
_proxyHeaders.forEach((k, v) {
if (v.isNotEmpty) up.headers.set(k, v);
});
final upRes = await up.close();
r.statusCode = upRes.statusCode;
r.headers.set('Access-Control-Allow-Origin', '*');
var finalUri = Uri.parse(target);
for (final rd in upRes.redirects) {
finalUri = finalUri.resolveUri(rd.location);
}
final ct = upRes.headers.contentType?.mimeType ?? '';
final isPlaylist = finalUri.path.toLowerCase().endsWith('.m3u8') || ct.contains('mpegurl');
if (isPlaylist) {
// HLS 목록: 안의 조각 주소들도 폰을 거치게 바꿔줌
final text = await upRes.transform(utf8.decoder).join();
final self = '${req.requestedUri.scheme}://${req.requestedUri.authority}';
final out = text.split('\n').map((line) {
final t = line.trim();
if (t.isEmpty || t.startsWith('#')) return line;
return '$self/p?u=${Uri.encodeComponent(finalUri.resolve(t).toString())}';
}).join('\n');
r.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
r.write(out);
await r.close();
} else {
r.headers.contentType = upRes.headers.contentType;
await r.addStream(upRes);
await r.close();
}
} catch (_) {
try {
await r.close();
} catch (_) {}
} finally {
client.close();
}
return;
}
// 앨범 사진 요청
if (req.uri.path.startsWith('/art/')) {
final art = _artBytes;
final r = req.response;
if (art == null) {
r.statusCode = HttpStatus.notFound;
await r.close();
return;
}
final isPng = art.length > 4 && art[0] == 0x89 && art[1] == 0x50;
r.headers.contentType = ContentType.parse(isPng ? 'image/png' : 'image/jpeg');
r.headers.set('Access-Control-Allow-Origin', '*');
r.contentLength = art.length;
r.add(art);
await r.close();
return;
}
final path = _servingPath;
    final res = req.response;
    try {
      if (path == null || !await File(path).exists()) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final file = File(path);
      final total = await file.length();
      res.headers.contentType = ContentType.parse(_mime(path));
      res.headers.set('Accept-Ranges', 'bytes');
      res.headers.set('Access-Control-Allow-Origin', '*');
      res.headers.set('transferMode.dlna.org', 'Streaming');
      res.headers.set('contentFeatures.dlna.org', 'DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000');

      var start = 0;
      var end = total - 1;
      final range = req.headers.value(HttpHeaders.rangeHeader);
      if (range != null && range.startsWith('bytes=')) {
        final parts = range.substring(6).split('-');
        start = int.tryParse(parts[0]) ?? 0;
        if (parts.length > 1 && parts[1].isNotEmpty) end = int.tryParse(parts[1]) ?? end;
        res.statusCode = HttpStatus.partialContent;
        res.headers.set('Content-Range', 'bytes $start-$end/$total');
      }
      res.contentLength = end - start + 1;
      if (req.method == 'HEAD') {
        await res.close();
        return;
      }
      await res.addStream(file.openRead(start, end + 1));
      await res.close();
    } catch (_) {
      try {
        await res.close();
      } catch (_) {}
    }
  }

  Future<String?> _wifiIp() async {
    final list = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
    // 와이파이(wlan) 먼저
    for (final ni in list) {
      if (ni.name.toLowerCase().contains('wlan')) return ni.addresses.first.address;
    }
    for (final ni in list) {
      for (final a in ni.addresses) {
        final ip = a.address;
        if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) return ip;
      }
    }
    return null;
  }

  // ───────────────── DLNA 도우미 ─────────────────
  Future<String> _soap(String action, String args) async {
    final body = '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body><u:$action xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">$args</u:$action></s:Body>'
        '</s:Envelope>';
    final res = await http
        .post(
      Uri.parse(_device!.controlUrl),
      headers: {
        'Content-Type': 'text/xml; charset="utf-8"',
        'SOAPACTION': '"urn:schemas-upnp-org:service:AVTransport:1#$action"',
      },
      body: utf8.encode(body),
    )
        .timeout(const Duration(seconds: 5));
    if (res.statusCode >= 400) throw Exception('$action 실패 ${res.statusCode}');
    return utf8.decode(res.bodyBytes, allowMalformed: true);
  }

  String _didl(Song song, String url, String artUrl) {
    return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
        '<item id="1" parentID="0" restricted="1">'
        '<dc:title>${_escape(song.titleDisplay)}</dc:title>'
        '<upnp:artist>${_escape(song.artistDisplay)}</upnp:artist>'
        '<upnp:albumArtURI>${_escape(artUrl)}</upnp:albumArtURI>'
'<upnp:class>object.item.audioItem.musicTrack</upnp:class>'
        '<res protocolInfo="http-get:*:${_mime(song.uri ?? '')}:*">${_escape(url)}</res>'
        '</item></DIDL-Lite>';
  }

  /// 라디오 이미지: 방송국 로고(충분히 크면) → 아니면 파란소리 라디오 사진
Future<Uint8List?> _radioArt(String? logoUrl, String key) async {
bool isImage(Uint8List b) =>
(b.length > 4 && b[0] == 0x89 && b[1] == 0x50) || (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8);
if (logoUrl != null && logoUrl.startsWith('http')) {
try {
final res = await http.get(Uri.parse(logoUrl)).timeout(const Duration(seconds: 4));
final b = res.bodyBytes;
if (res.statusCode == 200 && b.length > 3000 && isImage(b)) return b;
} catch (_) {}
}
try {
final n = key.hashCode.abs() % 10 + 1;
final res = await http
.get(Uri.parse('https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images/rest_radio_$n.jpg'))
.timeout(const Duration(seconds: 5));
if (res.statusCode == 200 && isImage(res.bodyBytes)) return res.bodyBytes;
} catch (_) {}
return null;
}

/// 앨범 사진 (없으면 앱 기본 이미지)
Future<Uint8List?> _artFor(Song song) async {
if (song.albumArt != null) return Uint8List.fromList(song.albumArt!);
try {
final d = await rootBundle.load(noAlbumImagePath(song.uri ?? song.title));
return d.buffer.asUint8List();
} catch (_) {
return null;
}
}

String _mime(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'm4a':
      case 'aac':
      case 'mp4':
        return 'audio/mp4';
      case 'flac':
        return 'audio/flac';
      case 'wav':
        return 'audio/wav';
      default:
        return 'audio/mpeg';
    }
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&');
}

// ═════════════════ 구글 캐스트 (Cast V2) ═════════════════
const _nsConn = 'urn:x-cast:com.google.cast.tp.connection';
const _nsHeart = 'urn:x-cast:com.google.cast.tp.heartbeat';
const _nsRecv = 'urn:x-cast:com.google.cast.receiver';
const _nsMedia = 'urn:x-cast:com.google.cast.media';
const _defaultReceiver = 'CC1AD845'; // 구글 기본 미디어 재생기

/// 구글 캐스트 기기와 직접 대화 (TLS 8009 포트)
class _GoogleCast {
  final String host;
  _GoogleCast(this.host);

  SecureSocket? _sock;
  final List<int> _buf = [];
  int _reqId = 1;
  String? _transportId;
  String? _sessionId;
  int? _mediaSessionId;
  Timer? _heartbeat;
  Completer<void>? _appReady;
  Completer<void>? _mediaReady;

  /// (재생 상태, 멈춘 이유)
  void Function(String state, String? idleReason)? onMediaStatus;

  Future<void> connect() async {
    _sock = await SecureSocket.connect(host, 8009,
        onBadCertificate: (_) => true, timeout: const Duration(seconds: 5));
    _sock!.listen(_onData, onError: (_) {}, onDone: () => _heartbeat?.cancel());
    _send('receiver-0', _nsConn, {'type': 'CONNECT'});
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      _send('receiver-0', _nsHeart, {'type': 'PING'});
    });
    // 기본 재생기 앱 실행
    _appReady = Completer<void>();
    _send('receiver-0', _nsRecv, {'type': 'LAUNCH', 'appId': _defaultReceiver, 'requestId': _reqId++});
    await _appReady!.future.timeout(const Duration(seconds: 12));
    _send(_transportId!, _nsConn, {'type': 'CONNECT'});
  }

  Future<void> load(String url, String contentType, String title, String artist, String artUrl,
      {bool live = false, int startSec = 0}) async {
    if (_transportId == null) throw Exception('캐스트 앱이 준비 안 됨');
    _mediaReady = Completer<void>();
    _mediaSessionId = null;
    _send(_transportId!, _nsMedia, {
      'type': 'LOAD',
      'requestId': _reqId++,
      'sessionId': _sessionId,
      'autoplay': true,
      'currentTime': startSec,
      'media': {
        'contentId': url,
        'contentType': contentType,
        'streamType': live ? 'LIVE' : 'BUFFERED',
        'metadata': {
'metadataType': 3,
'title': title,
'artist': artist,
if (artUrl.isNotEmpty)
'images': [
{'url': artUrl},
],
},
      },
    });
    await _mediaReady!.future.timeout(const Duration(seconds: 15));
  }

  void play() {
    if (_transportId == null || _mediaSessionId == null) return;
    _send(_transportId!, _nsMedia, {'type': 'PLAY', 'mediaSessionId': _mediaSessionId, 'requestId': _reqId++});
  }

  void pause() {
    if (_transportId == null || _mediaSessionId == null) return;
    _send(_transportId!, _nsMedia, {'type': 'PAUSE', 'mediaSessionId': _mediaSessionId, 'requestId': _reqId++});
  }

  Future<void> stop() async {
    if (_sessionId != null) {
      _send('receiver-0', _nsRecv, {'type': 'STOP', 'sessionId': _sessionId, 'requestId': _reqId++});
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void close() {
    _heartbeat?.cancel();
    try {
      _sock?.destroy();
    } catch (_) {}
    _sock = null;
  }

  // ─── 받은 데이터: [길이 4바이트][메시지] 단위로 잘라서 처리 ───
  void _onData(Uint8List data) {
    _buf.addAll(data);
    while (_buf.length >= 4) {
      final len = (_buf[0] << 24) | (_buf[1] << 16) | (_buf[2] << 8) | _buf[3];
      if (_buf.length < 4 + len) break;
      final msg = _buf.sublist(4, 4 + len);
      _buf.removeRange(0, 4 + len);
      _handle(msg);
    }
  }

  void _handle(List<int> bytes) {
    final f = _decode(bytes);
    final ns = f[4];
    final payload = f[6];
    if (payload == null) return;
    Map<String, dynamic> j;
    try {
      j = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = j['type'];

    if (ns == _nsHeart && type == 'PING') {
      _send(f[2] ?? 'receiver-0', _nsHeart, {'type': 'PONG'});
      return;
    }
    if (ns == _nsRecv && type == 'RECEIVER_STATUS') {
      final apps = (j['status']?['applications'] as List?) ?? const [];
      for (final a in apps) {
        if (a is Map && a['appId'] == _defaultReceiver) {
          _transportId = a['transportId'] as String?;
          _sessionId = a['sessionId'] as String?;
          if (_transportId != null && !(_appReady?.isCompleted ?? true)) _appReady!.complete();
        }
      }
      return;
    }
    if (ns == _nsMedia) {
      if (type == 'MEDIA_STATUS') {
        final list = (j['status'] as List?) ?? const [];
        if (list.isEmpty) return;
        final s = list.first as Map;
        if (s['mediaSessionId'] != null) _mediaSessionId = s['mediaSessionId'] as int;
        if (_mediaSessionId != null && !(_mediaReady?.isCompleted ?? true)) _mediaReady!.complete();
        onMediaStatus?.call((s['playerState'] ?? '') as String, s['idleReason'] as String?);
      } else if (type == 'LOAD_FAILED' || type == 'LOAD_CANCELLED' || type == 'INVALID_REQUEST') {
        if (!(_mediaReady?.isCompleted ?? true)) _mediaReady!.completeError(Exception(type));
      }
    }
  }

  // ─── 보낼 메시지 만들기 (구글 캐스트 형식) ───
  void _send(String dest, String ns, Map<String, dynamic> payload) {
    final body = <int>[];
    void varint(int v) {
      while (v >= 0x80) {
        body.add((v & 0x7F) | 0x80);
        v >>= 7;
      }
      body.add(v);
    }

    void str(int field, String s) {
      final b = utf8.encode(s);
      varint((field << 3) | 2);
      varint(b.length);
      body.addAll(b);
    }

    varint((1 << 3) | 0);
    varint(0); // 프로토콜 버전
    str(2, 'sender-0');
    str(3, dest);
    str(4, ns);
    varint((5 << 3) | 0);
    varint(0); // 글자 형식
    str(6, jsonEncode(payload));

    final len = body.length;
    try {
      _sock?.add([(len >> 24) & 0xFF, (len >> 16) & 0xFF, (len >> 8) & 0xFF, len & 0xFF, ...body]);
    } catch (_) {}
  }

  Map<int, String> _decode(List<int> b) {
    final out = <int, String>{};
    var i = 0;
    int readVarint() {
      var shift = 0;
      var r = 0;
      while (i < b.length) {
        final x = b[i++];
        r |= (x & 0x7F) << shift;
        if ((x & 0x80) == 0) break;
        shift += 7;
      }
      return r;
    }

    while (i < b.length) {
      final tag = readVarint();
      final field = tag >> 3;
      final wt = tag & 7;
      if (wt == 0) {
        readVarint();
      } else if (wt == 2) {
        final l = readVarint();
        if (i + l > b.length) break;
        final s = b.sublist(i, i + l);
        i += l;
        if (field != 7) out[field] = utf8.decode(s, allowMalformed: true);
      } else {
        break;
      }
    }
    return out;
  }
}