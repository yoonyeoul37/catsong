import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class VideoProvider extends ChangeNotifier {
  List<Video> _videos = [];
  Set<String>? _seen; // 열어본(또는 처음부터 있던) 영상
  final Map<String, int> _dates = {}; // 영상마다 찍은 날짜 (밀리초)
  String _sort = 'new'; // new 최신순 · old 오래된순 · name 이름순 · long 긴 영상순 · short 짧은 영상순
  final Map<String, String> _places = {}; // 영상마다 찍은 곳 ('' = 위치 없는 영상)
  final Set<String> _placeLoading = {};
  bool _placesRestored = false;
  bool _mediaLocAsked = false;
  Timer? _placeSaveTimer;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasPermission = false;
  bool _permissionDenied = false;
  VoidCallback? _onStopRadio;
  VoidCallback? _onStopMusic;

  void setOnStopRadio(VoidCallback cb) => _onStopRadio = cb;
  void setOnStopMusic(VoidCallback cb) => _onStopMusic = cb;

  void stopOtherPlayers() {
    _onStopRadio?.call();
    _onStopMusic?.call();
  }

  static const _channel = MethodChannel('kr.ssing.catsong/media');

  List<Video> get videos => _videos;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasPermission => _hasPermission;
  bool get permissionDenied => _permissionDenied;

  String get sort => _sort;
  int dateOf(String uri) => _dates[uri] ?? 0;

  // 정렬 바꾸기 (앱 다시 켜도 기억)
  Future<void> setSort(String s) async {
    if (s == _sort) return;
    _sort = s;
    _applySort();
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('videoSort', s);
  }

  void _applySort() {
    switch (_sort) {
      case 'old':
        _videos.sort((a, b) => dateOf(a.uri).compareTo(dateOf(b.uri)));
        break;
      case 'name':
        _videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'long':
        _videos.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case 'short':
        _videos.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      default:
        _videos.sort((a, b) => dateOf(b.uri).compareTo(dateOf(a.uri)));
    }
  }

  // 새로 찍은 영상인지 (아직 안 열어본 것)
  bool isNew(String uri) => _seen != null && !_seen!.contains(uri);

  // 열어보면 NEW 지우기
  Future<void> markSeen(String uri) async {
    if (_seen == null || _seen!.contains(uri)) return;
    _seen!.add(uri);
    notifyListeners();
    (await SharedPreferences.getInstance()).setStringList('videoSeenUris', _seen!.toList());
  }

  // 찍은 곳 ("서울 중구"), 없으면 null
  String? placeOf(String uri) {
    final p = _places[uri];
    return (p == null || p.isEmpty) ? null : p;
  }

  // 찍은 곳 찾아오기 — 한 번 찾은 건 폰에 기억해서 다음엔 바로
  Future<void> loadPlace(String uri) async {
    if (!_placesRestored) {
      _placesRestored = true;
      final saved = (await SharedPreferences.getInstance()).getStringList('videoPlaces3') ?? []; // 3 = 후보 주소에서 동 찾기 (예전 것은 새로 찾기)
      for (final s in saved) {
        final i = s.indexOf('\t');
        // '위치 없음'으로 기억된 건 버리고 다시 찾기 (권한이 나중에 켜질 수 있어서)
        if (i > 0 && i < s.length - 1) _places.putIfAbsent(s.substring(0, i), () => s.substring(i + 1));
      }
      if (saved.isNotEmpty) notifyListeners();
    }
    if (_places.containsKey(uri) || _placeLoading.contains(uri)) return;
    _placeLoading.add(uri);
    try {
      // 영상 속 위치를 읽는 권한 (보통 따로 묻는 창 없이 허용돼요)
      if (!_mediaLocAsked) {
        _mediaLocAsked = true;
        try {
          final st = await Permission.accessMediaLocation.request();
          debugPrint('VideoPlace 권한: $st');
        } catch (_) {}
      }
      final r = await _channel.invokeMethod('getVideoPlace', {'path': uri});
      final m = r == null ? null : Map<String, dynamic>.from(r);
      if (m == null || m['lat'] == null) {
        _places[uri] = ''; // 위치 태그 없는 영상
      } else if (m['place'] != null) {
        _places[uri] = m['place'] as String;
      } else {
        return; // 좌표는 있는데 주소를 못 바꿈 (인터넷 없음 등) → 다음에 다시
      }
      notifyListeners();
      _placeSaveTimer?.cancel();
      _placeSaveTimer = Timer(const Duration(seconds: 1), () async {
        (await SharedPreferences.getInstance())
            .setStringList('videoPlaces3', [
              for (final e in _places.entries)
                if (e.value.isNotEmpty) '${e.key}\t${e.value}' // 찾은 지역만 기억
            ]);
      });
    } catch (_) {
    } finally {
      _placeLoading.remove(uri);
    }
  }

  // 이름을 바꾸면 경로가 바뀌어 새 영상으로 보이니까, '본 것' 표시를 새 이름으로 옮기기
  Future<void> carrySeen(String oldUri, String newName) async {
    final slash = oldUri.lastIndexOf('/');
    final dot = oldUri.lastIndexOf('.');
    final ext = dot > slash ? oldUri.substring(dot + 1) : 'mp4';
    final newUri = '${oldUri.substring(0, slash + 1)}${newName.contains('.') ? newName : '$newName.$ext'}';
    if (_seen != null && _seen!.contains(oldUri)) {
      _seen!.add(newUri);
      await (await SharedPreferences.getInstance()).setStringList('videoSeenUris', _seen!.toList());
    }
  }

  Future<void> requestPermissionAndLoad() async {
    _isLoading = true;
    _permissionDenied = false;
    notifyListeners();

    final status = await Permission.videos.request();

    if (status.isGranted) {
      _hasPermission = true;
      _permissionDenied = false;
      await loadVideos();
    } else {
      _hasPermission = false;
      _permissionDenied = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideos({bool quiet = false}) async {
    // quiet: 뒤에서 조용히 새로고침 (빙글빙글 안 띄움)
    if (!quiet) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = '';

    try {
      try {
        await _channel.invokeMethod('refreshMediaStore');
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {}
      final result = await _channel.invokeMethod('getVideoList');
      final List<Video> foundVideos = [];
      int idCounter = 0;

      if (result != null) {
        for (final item in result) {
          final map = Map<String, dynamic>.from(item);
          foundVideos.add(Video(
            id: idCounter++,
            title: map['title'] ?? '제목 없음',
            uri: map['uri'] ?? '',
            duration: map['duration'] ?? 0,
          ));
          _dates[map['uri'] ?? ''] = (map['date'] as num?)?.toInt() ?? 0;
        }
      }

      // 고른 정렬대로 줄 세우기 (처음엔 최신순)
      _sort = (await SharedPreferences.getInstance()).getString('videoSort') ?? 'new';
      _videos = foundVideos;
      _applySort();
      // NEW 표시: 맨 처음엔 지금 있는 영상 모두 '본 것'으로 (전부 NEW 뜨지 않게)
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('videoSeenUris');
      if (saved == null) {
        _seen = foundVideos.map((v) => v.uri).toSet();
        await prefs.setStringList('videoSeenUris', _seen!.toList());
      } else {
        _seen = saved.toSet();
      }
      debugPrint('비디오 스캔 완료: ${_videos.length}개');
      debugPrint('NEW 확인: 본 영상 ${_seen?.length}개 기억 / NEW = ${_videos.where((v) => isNew(v.uri)).map((v) => v.title).toList()}');
      debugPrint('비디오 목록: ${foundVideos.map((v) => v.title).toList()}');
    } catch (e) {
      _errorMessage = '비디오 스캔 오류: $e';
      debugPrint('비디오 스캔 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}