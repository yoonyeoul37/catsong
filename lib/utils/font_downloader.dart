import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 설정 → 글꼴: 앱에 안 넣은 8종은 고를 때 R2(files.ssing.kr/fonts)에서 받아 폰에 저장
/// 한 번 받으면 다음부터는 인터넷 없이 바로 씀 (앱 크기 약 10MB 줄이기)
class FontDownloader {
  static const _base = 'https://files.ssing.kr/fonts/';

  /// 글꼴 키 → (글꼴 이름(family), 파일들) — 굵기는 파일 안에 적힌 대로 알아서 맞춰짐
  static const remote = <String, (String, List<String>)>{
    'line_seed': ('LINESeedKR', ['LINESeedKR-Regular.otf', 'LINESeedKR-Bold.otf']),
    'suit': ('SUIT', ['SUIT-Regular.ttf', 'SUIT-Bold.ttf']),
    'wanted_sans': ('WantedSans', ['WantedSans-Regular.ttf', 'WantedSans-Bold.ttf']),
    'nanum_gothic': ('NanumGothic', ['NanumGothic-Regular.ttf', 'NanumGothic-Bold.ttf']),
    'ibm_plex': ('IBMPlexSansKR', ['IBMPlexSansKR-Regular.ttf', 'IBMPlexSansKR-Bold.ttf']),
    'nanum_square_round': ('NanumSquareRound', ['NanumSquareRound-Regular.ttf', 'NanumSquareRound-Bold.ttf']),
    'gowun_dodum': ('GowunDodum', ['GowunDodum-Regular.ttf']),
    'maru_buri': ('MaruBuri', ['MaruBuri-Regular.ttf', 'MaruBuri-Bold.ttf']),
  };

  static final Set<String> _downloaded = {}; // 폰에 파일이 다 있는 글꼴
  static final Set<String> _loaded = {}; // 앱에 불러와서 바로 쓸 수 있는 글꼴
  static final Map<String, Future<bool>> _busy = {}; // 받는 중 (두 번 누르지 않게)

  static bool isRemote(String key) => remote.containsKey(key);

  /// 앱 안 글꼴이거나, 받아서 불러온 글꼴이면 true
  static bool isLoaded(String key) => !isRemote(key) || _loaded.contains(key);

  /// 아직 한 번도 안 받은 글꼴이면 true (고르는 창에 ⬇ 표시)
  static bool needsDownload(String key) => isRemote(key) && !_downloaded.contains(key);

  static Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/fonts');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// 앱 켤 때 한 번: 이미 받아 둔 글꼴 목록 읽기
  static Future<void> init() async {
    try {
      final d = await _dir();
      for (final e in remote.entries) {
        var all = true;
        for (final f in e.value.$2) {
          final file = File('${d.path}/$f');
          if (!await file.exists() || await file.length() == 0) {
            all = false;
            break;
          }
        }
        if (all) _downloaded.add(e.key);
      }
    } catch (_) {}
  }

  /// 없으면 받고, 앱에 불러오기 — 성공하면 true (인터넷 없음 등은 false)
  /// 무슨 일이 있어도 25초 넘으면 false (동그라미가 끝없이 돌지 않게)
  static Future<bool> ensure(String key) {
    if (isLoaded(key)) return Future.value(true);
    return _busy[key] ??= _ensure(key)
        .timeout(const Duration(seconds: 25), onTimeout: () => false)
        .whenComplete(() {
      _busy.remove(key);
    });
  }

  static Future<bool> _ensure(String key) async {
    try {
      final d = await _dir();
      final (family, files) = remote[key]!;
      final datas = <ByteData>[];
      for (final f in files) {
        final file = File('${d.path}/$f');
        if (!await file.exists() || await file.length() == 0) {
          final res = await http.get(Uri.parse('$_base$f')).timeout(const Duration(seconds: 20));
          if (res.statusCode != 200 || res.bodyBytes.isEmpty) return false;
          final tmp = File('${file.path}.part'); // 받다가 끊기면 반쪽 파일이 남지 않게
          await tmp.writeAsBytes(res.bodyBytes, flush: true);
          await tmp.rename(file.path);
        }
        datas.add(ByteData.sublistView(await file.readAsBytes()));
      }
      _downloaded.add(key);
      final loader = FontLoader(family);
      for (final b in datas) {
        loader.addFont(Future.value(b));
      }
      await loader.load();
      _loaded.add(key);
      return true;
    } catch (_) {
      return false;
    }
  }
}