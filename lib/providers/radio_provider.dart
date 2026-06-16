import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import 'player_provider.dart' show SimpleAudioHandler;

enum RadioPlayerState { idle, loading, playing, paused, error }

class RadioProvider extends ChangeNotifier {
  late final Player _player;
  AudioHandler? _audioHandler;
  bool _isActuallyPlaying = false;
  VoidCallback? _onStopMusic;

  RadioPlayerState _playerState = RadioPlayerState.idle;
  RadioStation? _currentStation;
  List<RadioStation> _currentQueue = [];
  int _currentQueueIndex = -1;
  List<RadioStation> get currentQueue => _currentQueue;
  int get currentQueueIndex => _currentQueueIndex;
  String? _errorMessage;

  RadioCountry? _selectedCountry;
  RadioBroadcaster? _selectedBroadcaster;

  List<RadioStation> _broadcasterStations = [];
  List<RadioStation> _searchResults = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _recentlyListened = [];

  // 예약 채널 전환
  List<ScheduledStation> _schedules = [];
  Timer? _scheduleCheckTimer;
  List<ScheduledStation> get schedules => _schedules;
  static const _maxSchedules = 5;
  Timer? _sleepTimer;
  Duration? _sleepRemaining;
  Timer? _sleepCountdown;

  static const _keyFavorites = 'radio_favorites';
  static const _keyRecent = 'radio_recent';
  static const _keySchedules = 'radio_schedules';
  static const _maxRecent = 20;

  static const _apiServers = [
    'de1.api.radio-browser.info',
    'nl1.api.radio-browser.info',
    'at1.api.radio-browser.info',
  ];
  static const _apiHeaders = {
    'User-Agent': 'CatSong/1.0 (kr.ssing.catsong)'
  };

  RadioPlayerState get playerState => _playerState;
  RadioStation? get currentStation => _currentStation;
  String? get errorMessage => _errorMessage;
  RadioCountry? get selectedCountry => _selectedCountry;
  RadioBroadcaster? get selectedBroadcaster => _selectedBroadcaster;
  List<RadioStation> get broadcasterStations => _broadcasterStations;
  List<RadioStation> get searchResults => _searchResults;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get recentlyListened => _recentlyListened;
  bool get isLoadingBroadcaster => false;
  bool get isLoadingCountry => false;
  bool get isSearching => false;
  bool get isPlaying => _playerState == RadioPlayerState.playing;
  bool get isLoading => _playerState == RadioPlayerState.loading;
  Duration? get sleepRemaining => _sleepRemaining;
  bool get isSleepTimerActive => _sleepTimer != null;

  RadioProvider() {
    _player = Player(
      configuration: PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
      ),
    );
    _configurePlayer();
    _initPlayerStreams();
    _loadFromPrefs();
    _startScheduleRefreshTimer();
  }

  Future<void> _configurePlayer() async {
    try {
      final nativePlayer = _player.platform as NativePlayer;
      await nativePlayer.setProperty(
          'user-agent',
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36');
      await nativePlayer.setProperty('demuxer-lavf-probesize', '4096');
      await nativePlayer.setProperty('stream-lavf-o', 'reconnect=1');
      await nativePlayer.setProperty('network-timeout', '30');
      await nativePlayer.setProperty('demuxer-max-bytes', '5242880');
      await nativePlayer.setProperty('cache', 'yes');
      await nativePlayer.setProperty('cache-secs', '10');
      debugPrint('mpv HLS 설정 완료');
    } catch (e) {
      debugPrint('mpv 설정 오류: $e');
    }
  }

  void setAudioHandler(AudioHandler handler) {
    _audioHandler = handler;
  }

  void setOnStopMusic(VoidCallback cb) {
    _onStopMusic = cb;
  }

  SimpleAudioHandler? get _simpleHandler {
    final h = _audioHandler;
    if (h is SimpleAudioHandler) return h;
    return null;
  }

  void _startForeground(RadioStation station, String url) {
    try {
      _simpleHandler?.setRadioMediaItem(
        title: station.name,
        artist: station.country ?? 'Radio',
        url: url,
      );
      _simpleHandler?.setRadioPlaybackState(playing: true);
      debugPrint('포그라운드 서비스 시작');
    } catch (e) {
      debugPrint('포그라운드 서비스 오류: $e');
    }
  }

  void _updateForeground(bool playing) {
    try {
      _simpleHandler?.setRadioPlaybackState(playing: playing);
    } catch (e) {
      debugPrint('포그라운드 업데이트 오류: $e');
    }
  }

  void _stopForeground() {
    try {
      _simpleHandler?.setRadioPlaybackState(playing: false);
      _simpleHandler?.setRadioMode(false);
    } catch (e) {
      debugPrint('포그라운드 종료 오류: $e');
    }
  }

  void _initPlayerStreams() {
    _player.stream.playing.listen((playing) {
      debugPrint('stream.playing: $playing');
      _isActuallyPlaying = playing;
      if (playing) {
        _setPlayerState(RadioPlayerState.playing);
        _updateForeground(true);
      } else {
        if (_playerState == RadioPlayerState.playing) {
          _setPlayerState(RadioPlayerState.paused);
          _updateForeground(false);
        }
      }
    });

    _player.stream.buffering.listen((buffering) {
      debugPrint('stream.buffering: $buffering');
      if (buffering && !_isActuallyPlaying) {
        _setPlayerState(RadioPlayerState.loading);
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _isActuallyPlaying = false;
        _setPlayerState(RadioPlayerState.idle);
        _stopForeground();
      }
    });

    _player.stream.error.listen((error) {
      debugPrint('media_kit 오류: $error');
      if (error.isNotEmpty) {
        _errorMessage = '방송을 불러올 수 없습니다.\n다른 채널을 선택해 주세요.';
        _isActuallyPlaying = false;
        _setPlayerState(RadioPlayerState.error);
      }
    });
  }

  Future<String?> _resolveStreamUrl(String url) async {
    try {
      // KBS API JSON 처리
      if (url.contains('cfpwwwapi.kbs.co.kr')) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final items = data['channel_item'] as List?;
            if (items != null && items.isNotEmpty) {
              final serviceUrl = items[0]['service_url'] as String?;
              if (serviceUrl != null && serviceUrl.isNotEmpty) {
                debugPrint('KBS API URL 추출: $serviceUrl');
                return serviceUrl;
              }
            }
          }
        } catch (e) {
          debugPrint('KBS API 파싱 오류: $e');
        }
        return null;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
      'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
      request.followRedirects = false;

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 10));
      final statusCode = response.statusCode;

      debugPrint('resolve statusCode: $statusCode');

      if (statusCode == 301 ||
          statusCode == 302 ||
          statusCode == 307 ||
          statusCode == 308) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          debugPrint('리다이렉트: $location');
          client.close();
          return location;
        }
      }

      final body = await response.stream.bytesToString();
      final lines = body.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.startsWith('File') && trimmed.contains('=')) {
          final fileUrl =
          trimmed.substring(trimmed.indexOf('=') + 1).trim();
          if (fileUrl.startsWith('http')) {
            debugPrint('PLS에서 URL 추출: $fileUrl');
            client.close();
            return await _resolveStreamUrl(fileUrl) ?? fileUrl;
          }
        }

        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('#') &&
            trimmed.startsWith('http')) {
          debugPrint('M3U에서 URL 추출: $trimmed');
          client.close();
          return trimmed;
        }
      }

      client.close();
      return null;
    } catch (e) {
      debugPrint('URL resolve 오류: $e');
      return null;
    }
  }
  Future<void> playStation(RadioStation station) async {
    if (_playerState == RadioPlayerState.loading) {
      debugPrint('이미 로딩 중 - 중복 호출 무시');
      return;
    }

    try {
      _errorMessage = null;
      _isActuallyPlaying = false;
      _setPlayerState(RadioPlayerState.loading);
      _currentStation = station;
      final qIdx = _currentQueue.indexWhere((s) => s.name == station.name);
      if (qIdx >= 0) _currentQueueIndex = qIdx;
      notifyListeners();

      // 음악 재생 중이면 정지
      _onStopMusic?.call();

      debugPrint('=== 라디오 재생 시작 ===');
      debugPrint('방송국: ${station.name}');
      debugPrint('station.url: ${station.streamUrl}');
      debugPrint('station.url_resolved: ${station.urlResolved}');

      String playUrl = station.playableUrl;
      try {
        final freshUrl = await _resolveStreamUrl(station.streamUrl);
        if (freshUrl != null && freshUrl.isNotEmpty) {
          playUrl = freshUrl;
          debugPrint('리다이렉트 URL 추출: $playUrl');
        }
      } catch (e) {
        debugPrint('리다이렉트 실패 → url_resolved 사용');
      }

      if (playUrl == station.playableUrl) {
        try {
          for (final server in _apiServers) {
            final uri = Uri.https(
                server, '/json/url/${station.stationUuid}');
            final response = await http
                .get(uri, headers: _apiHeaders)
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final freshUrl = data['url'] as String?;
              if (freshUrl != null && freshUrl.isNotEmpty) {
                playUrl = freshUrl;
                debugPrint('API 최신 URL: $playUrl');
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('API URL 실패');
        }
      }

      debugPrint('FINAL_URL: $playUrl');

      await WakelockPlus.disable();
      _startForeground(station, playUrl);

      await _player.open(
        Media(
          playUrl,
          httpHeaders: {
            'User-Agent':
            'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Referer': _getReferer(station),
            'Origin': _getOrigin(station),
          },
        ),
        play: true,
      );

      await recordListened(station);
    } catch (e) {
      debugPrint('라디오 재생 실패: $e');
      _errorMessage = '방송을 불러올 수 없습니다.\n다른 채널을 선택해 주세요.';
      _setPlayerState(RadioPlayerState.error);
    }
  }

  String _getReferer(RadioStation station) {
    final url = station.playableUrl.toLowerCase();
    if (url.contains('kbs')) return 'https://www.kbs.co.kr/';
    if (url.contains('imbc') || url.contains('mbc')) {
      return 'https://www.imbc.com/';
    }
    if (url.contains('sbs')) return 'https://www.sbs.co.kr/';
    if (url.contains('ebs')) return 'https://www.ebs.co.kr/';
    if (url.contains('ytn')) return 'https://www.ytn.co.kr/';
    if (url.contains('cbs')) return 'https://www.cbs.co.kr/';
    if (url.contains('tbn')) return 'https://tbn.or.kr/';
    return '';
  }

  String _getOrigin(RadioStation station) {
    final url = station.playableUrl.toLowerCase();
    if (url.contains('kbs')) return 'https://www.kbs.co.kr';
    if (url.contains('imbc') || url.contains('mbc')) {
      return 'https://www.imbc.com';
    }
    if (url.contains('sbs')) return 'https://www.sbs.co.kr';
    if (url.contains('ebs')) return 'https://www.ebs.co.kr';
    if (url.contains('ytn')) return 'https://www.ytn.co.kr';
    if (url.contains('cbs')) return 'https://www.cbs.co.kr';
    if (url.contains('tbn')) return 'https://tbn.or.kr';
    return '';
  }

  Future<void> togglePlayPause() async {
    if (_playerState == RadioPlayerState.playing) {
      await _player.pause();
      await WakelockPlus.disable();
    } else {
      await _player.play();
    }
  }

  Future<void> stopRadio() async {
    await _player.stop();
    _isActuallyPlaying = false;
    _stopForeground();
    _currentStation = null;
    _setPlayerState(RadioPlayerState.idle);
    await WakelockPlus.disable();
    cancelSleepTimer();
  }

  void setQueue(List<RadioStation> stations, int index) {
    _currentQueue = List.from(stations);
    _currentQueueIndex = index;
  }
  Future<void> selectCountry(RadioCountry country) async {
    _selectedCountry = country;
    _selectedBroadcaster = null;
    _broadcasterStations = [];
    notifyListeners();
  }

  List<RadioStation> _countryStations = [];
  bool _isLoadingCountryStations = false;
  List<RadioStation> get countryStations => _countryStations;
  bool get isLoadingCountryStations => _isLoadingCountryStations;

  Future<void> fetchTopStations(String countryCode, {int limit = 200}) async {
    _countryStations = [];
    _isLoadingCountryStations = true;
    notifyListeners();

    try {
      for (final server in _apiServers) {
        final uri = Uri.https(server, '/json/stations/bycountrycodeexact/$countryCode', {
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '$limit',
          'hidebroken': 'true',
          'lastcheckok': '1',
          'codec': 'MP3,AAC,AAC+,OGG',
        });

        final response = await http
            .get(uri, headers: _apiHeaders)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _countryStations = data
              .map((j) => RadioStation.fromJson(j as Map<String, dynamic>))
              .where((s) => s.streamUrl.isNotEmpty)
              .toList();
          _mergeFavoriteFlags(_countryStations);
          break;
        }
      }
    } catch (e) {
      debugPrint('국가별 방송 로드 오류: $e');
    }

    _isLoadingCountryStations = false;
    notifyListeners();
  }

  // KBS 편성표
  final Map<String, List<Map<String, dynamic>>> _scheduleListMap = {};
  List<Map<String, dynamic>> get scheduleList =>
      _scheduleListMap[_currentStation?.name ?? ''] ?? [];
  final Map<String, Map<String, dynamic>> _currentProgramMap = {};
  Map<String, dynamic>? get currentProgram {
    final station = _currentStation;
    if (station == null) return null;
    return _currentProgramMap[station.name];
  }
  Map<String, dynamic>? currentProgramFor(String stationName) =>
      _currentProgramMap[stationName];
  final Map<String, String> _nowPlayingMap = {};
  String? nowPlayingFor(String stationName) => _nowPlayingMap[stationName];

  static const _kbsChannelCodes = {
    'KBS 제1라디오': '21',
    'KBS 해피FM': '22',
    'KBS 3라디오': '23',
    'KBS Classic FM': '24',
    'KBS Cool FM': '25',
  };

  // 스트림 URL에서 local_station_code와 channel_code 추출
  // 예: channel_code/10_21 → ('10', '21')
  // 예: channel_code/24 → ('00', '24')
  static Map<String, String>? _parseKbsChannelFromUrl(String streamUrl) {
    final match = RegExp(r'channel_code/(\d+)(?:_(\d+))?$').firstMatch(streamUrl);
    if (match == null) return null;
    if (match.group(2) != null) {
      return {'local': match.group(1)!, 'channel': match.group(2)!};
    } else {
      return {'local': '00', 'channel': match.group(1)!};
    }
  }

  Future<void> fetchSchedule(String stationName) async {
    _scheduleListMap.remove(stationName);
    _currentProgramMap.remove(stationName);
    _nowPlayingMap.remove(stationName);
    notifyListeners();

    String? channelCode;
    for (final entry in _kbsChannelCodes.entries) {
      if (stationName.contains(entry.key)) {
        channelCode = entry.value;
        break;
      }
    }
    debugPrint('fetchSchedule 호출됨: $stationName / channelCode: $channelCode');
    if (channelCode == null) return;

    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    try {
      final uri = Uri.parse(
        'https://static.api.kbs.co.kr/mediafactory/v1/schedule/weekly'
            '?&rtype=json&local_station_code=00'
            '&channel_code=$channelCode'
            '&program_planned_date_from=$dateStr'
            '&program_planned_date_to=$dateStr',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final schedules = data[0]['schedules'] as List<dynamic>? ?? [];
          _scheduleListMap[stationName] = schedules.cast<Map<String, dynamic>>();
          debugPrint('편성표 샘플: ${schedules.isNotEmpty ? schedules[0] : "없음"}');

          // 현재 방송 중인 프로그램 찾기
          final nowTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}0000';
          debugPrint('현재시각: $nowTime');
          for (final s in _scheduleListMap[stationName] ?? []) {
            debugPrint('프로그램: ${s['program_title']} / ${s['program_planned_start_time']} ~ ${s['program_planned_end_time']}');
          }
          final currentSchedules = _scheduleListMap[stationName] ?? [];
          for (int i = 0; i < currentSchedules.length; i++) {
            final s = currentSchedules[i];
            final start = s['program_planned_start_time'] as String? ?? '';
            final end = s['program_planned_end_time'] as String? ?? '';
            if (nowTime.compareTo(start) >= 0 && nowTime.compareTo(end) < 0) {
              // 같은 프로그램 코드로 연속된 항목의 마지막 종료 시간 찾기
              final programCode = s['program_code'] as String? ?? '';
              String finalEnd = end;
              for (int j = i + 1; j < currentSchedules.length; j++) {
                final next = currentSchedules[j];
                if (next['program_code'] == programCode) {
                  finalEnd = next['program_planned_end_time'] as String? ?? finalEnd;
                } else {
                  break;
                }
              }
              // 종료 시간을 합산한 가상 항목으로 저장
              final merged = Map<String, dynamic>.from(s);
              merged['program_planned_end_time'] = finalEnd;
              _currentProgramMap[stationName] = merged;
              _nowPlayingMap[stationName] = s['program_title'] as String? ?? '';
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('편성표 로드 오류: $e');
    }
    notifyListeners();
  }

  Future<void> fetchScheduleByUrl(String stationName, String streamUrl) async {
    final codes = _parseKbsChannelFromUrl(streamUrl);
    if (codes == null) return;
    final localCode = codes['local']!;
    final channelCode = codes['channel']!;

    _scheduleListMap.remove(stationName);
    _currentProgramMap.remove(stationName);
    _nowPlayingMap.remove(stationName);

    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    try {
      final uri = Uri.parse(
        'https://static.api.kbs.co.kr/mediafactory/v1/schedule/weekly'
            '?rtype=json&local_station_code=$localCode'
            '&channel_code=$channelCode'
            '&program_planned_date_from=$dateStr'
            '&program_planned_date_to=$dateStr',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final schedules = data[0]['schedules'] as List<dynamic>? ?? [];
          _scheduleListMap[stationName] = schedules.cast<Map<String, dynamic>>();
          final nowTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}0000';
          final currentSchedules = _scheduleListMap[stationName] ?? [];
          for (int i = 0; i < currentSchedules.length; i++) {
            final s = currentSchedules[i];
            final start = s['program_planned_start_time'] as String? ?? '';
            final end = s['program_planned_end_time'] as String? ?? '';
            if (nowTime.compareTo(start) >= 0 && nowTime.compareTo(end) < 0) {
              final programCode = s['program_code'] as String? ?? '';
              String finalEnd = end;
              for (int j = i + 1; j < currentSchedules.length; j++) {
                final next = currentSchedules[j];
                if (next['program_code'] == programCode) {
                  finalEnd = next['program_planned_end_time'] as String? ?? finalEnd;
                } else {
                  break;
                }
              }
              final merged = Map<String, dynamic>.from(s);
              merged['program_planned_end_time'] = finalEnd;
              _currentProgramMap[stationName] = merged;
              _nowPlayingMap[stationName] = s['program_title'] as String? ?? '';
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('지방 편성표 로드 오류: $e');
    }
    notifyListeners();
  }
  String formatScheduleTime(String time) {
    if (time.length < 4) return time;
    int hour = int.tryParse(time.substring(0, 2)) ?? 0;
    final min = time.substring(2, 4);
    if (hour >= 24) hour -= 24;
    final period = hour < 12 ? '오전' : '오후';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$min';
  }
  Future<void> selectBroadcaster(RadioBroadcaster broadcaster) async {
    _selectedBroadcaster = broadcaster;
    _broadcasterStations = [];
    notifyListeners();

    try {
      for (final server in _apiServers) {
        final uri = Uri.https(server, '/json/stations/search', {
          'name': broadcaster.keyword,
          'countrycode': _selectedCountry?.code ?? '',
          'limit': '20',
          'order': 'votes',
          'reverse': 'true',
          'hidebroken': 'true',
        });

        final response = await http
            .get(uri, headers: _apiHeaders)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _broadcasterStations = data
              .map((j) =>
              RadioStation.fromJson(j as Map<String, dynamic>))
              .where((s) => s.streamUrl.isNotEmpty)
              .toList();
          _mergeFavoriteFlags(_broadcasterStations);
          notifyListeners();
          // KBS 채널이면 편성표 자동 fetch
          for (final station in _broadcasterStations) {
            if (_kbsChannelCodes.keys.any((k) => station.name.contains(k))) {
              fetchSchedule(station.name);
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('방송사 로드 오류: $e');
    }
    notifyListeners();
  }

  Future<void> searchStations(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      for (final server in _apiServers) {
        final uri = Uri.https(server, '/json/stations/search', {
          'name': query,
          'limit': '30',
          'order': 'votes',
          'reverse': 'true',
          'hidebroken': 'true',
        });

        final response = await http
            .get(uri, headers: _apiHeaders)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _searchResults = data
              .map((j) =>
              RadioStation.fromJson(j as Map<String, dynamic>))
              .where((s) => s.streamUrl.isNotEmpty)
              .toList();
          _mergeFavoriteFlags(_searchResults);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      _searchResults = [];
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> toggleFavorite(RadioStation station) async {
    final idx = _favorites
        .indexWhere((s) => s.stationUuid == station.stationUuid);
    if (idx >= 0) {
      _favorites.removeAt(idx);
      station.isFavorite = false;
    } else {
      station.isFavorite = true;
      _favorites.add(station);
    }
    _syncFavoriteFlag(station.stationUuid, station.isFavorite);
    notifyListeners();
    await _saveToPrefs();
  }

  bool isFavorite(String stationUuid) =>
      _favorites.any((s) => s.stationUuid == stationUuid);

  Future<void> recordListened(RadioStation station) async {
    station.lastListened = DateTime.now();
    _recentlyListened
        .removeWhere((s) => s.stationUuid == station.stationUuid);
    _recentlyListened.insert(0, station);
    if (_recentlyListened.length > _maxRecent) {
      _recentlyListened = _recentlyListened.sublist(0, _maxRecent);
    }
    notifyListeners();
    await _saveToPrefs();
  }

  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepRemaining = duration;
    _sleepTimer = Timer(duration, () async {
      await _player.pause();
      await WakelockPlus.disable();
      _isActuallyPlaying = false;
      _setPlayerState(RadioPlayerState.paused);
      _updateForeground(false);
      cancelSleepTimer();
    });
    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sleepRemaining == null ||
          _sleepRemaining!.inSeconds <= 0) {
        cancelSleepTimer();
        return;
      }
      _sleepRemaining =
          _sleepRemaining! - const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void addSchedule(TimeOfDay time, RadioStation station) {
    if (_schedules.length >= _maxSchedules) return;
    _schedules.add(ScheduledStation(time: time, station: station));
    _schedules.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
    _startScheduleCheck();
    _saveSchedules();
    notifyListeners();
  }

  void removeSchedule(int index) {
    if (index >= 0 && index < _schedules.length) {
      _schedules.removeAt(index);
      if (_schedules.isEmpty) _stopScheduleCheck();
      _saveSchedules();
      notifyListeners();
    }
  }

  Timer? _scheduleRefreshTimer;
  Timer? _scheduleDisplayTimer;

  void _startScheduleRefreshTimer() {
    _scheduleRefreshTimer?.cancel();
    _scheduleRefreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) {
        for (final name in _kbsChannelCodes.keys) {
          if (_scheduleListMap.containsKey(name)) {
            fetchSchedule(name);
          }
        }
      },
    );
    _scheduleDisplayTimer?.cancel();
    _scheduleDisplayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateCurrentPrograms(),
    );
  }

  void _updateCurrentPrograms() {
    final now = DateTime.now();
    final nowTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}0000';
    bool changed = false;
    for (final stationName in _scheduleListMap.keys) {
      final currentSchedules = _scheduleListMap[stationName] ?? [];
      for (int i = 0; i < currentSchedules.length; i++) {
        final s = currentSchedules[i];
        final start = s['program_planned_start_time'] as String? ?? '';
        final end = s['program_planned_end_time'] as String? ?? '';
        if (nowTime.compareTo(start) >= 0 && nowTime.compareTo(end) < 0) {
          final programCode = s['program_code'] as String? ?? '';
          String finalEnd = end;
          for (int j = i + 1; j < currentSchedules.length; j++) {
            final next = currentSchedules[j];
            if (next['program_code'] == programCode) {
              finalEnd = next['program_planned_end_time'] as String? ?? finalEnd;
            } else {
              break;
            }
          }
          final merged = Map<String, dynamic>.from(s);
          merged['program_planned_end_time'] = finalEnd;
          _currentProgramMap[stationName] = merged;
          _nowPlayingMap[stationName] = s['program_title'] as String? ?? '';
          changed = true;
          break;
        }
      }
    }
    if (changed) notifyListeners();
  }

  void clearSchedules() {
    _schedules.clear();
    _stopScheduleCheck();
    _saveSchedules();
    notifyListeners();
  }

  void _startScheduleCheck() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkSchedules(),
    );
  }

  void _stopScheduleCheck() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = null;
  }

  void _checkSchedules() {
    if (_schedules.isEmpty) return;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    for (int i = 0; i < _schedules.length; i++) {
      final s = _schedules[i];
      final sMin = s.time.hour * 60 + s.time.minute;
      if (nowMin == sMin && !s.triggered) {
        playStation(s.station);
        _schedules.removeAt(i);
        if (_schedules.isEmpty) _stopScheduleCheck();
        _saveSchedules();
        notifyListeners();
        break;
      }
    }
  }
  void cancelSleepTimer() {
    _scheduleCheckTimer?.cancel();
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _sleepTimer = null;
    _sleepCountdown = null;
    _sleepRemaining = null;
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final favJson = prefs.getStringList(_keyFavorites) ?? [];
    _favorites = favJson.map((s) {
      try {
        return RadioStation.fromJson(
            json.decode(s) as Map<String, dynamic>)
          ..isFavorite = true;
      } catch (_) {
        return null;
      }
    }).whereType<RadioStation>().toList();

    final recentJson = prefs.getStringList(_keyRecent) ?? [];
    _recentlyListened = recentJson.map((s) {
      try {
        return RadioStation.fromJson(
            json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<RadioStation>().toList();
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    _recentlyListened.removeWhere((s) =>
    s.lastListened != null && s.lastListened!.isBefore(oneMonthAgo));

    final scheduleJson = prefs.getStringList(_keySchedules) ?? [];
    _schedules = scheduleJson.map((s) {
      try {
        return ScheduledStation.fromJson(
            json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<ScheduledStation>().toList();
    if (_schedules.isNotEmpty) {
      _startScheduleCheck();
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyFavorites,
      _favorites.map((s) => json.encode(s.toJson())).toList(),
    );
    await prefs.setStringList(
      _keyRecent,
      _recentlyListened.map((s) => json.encode(s.toJson())).toList(),
    );
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keySchedules,
      _schedules.map((s) => json.encode(s.toJson())).toList(),
    );
  }

  void _setPlayerState(RadioPlayerState state) {
    _playerState = state;
    notifyListeners();
  }

  void _mergeFavoriteFlags(List<RadioStation> stations) {
    for (final s in stations) {
      s.isFavorite = isFavorite(s.stationUuid);
    }
  }

  void _syncFavoriteFlag(String uuid, bool value) {
    for (final list in [_broadcasterStations, _searchResults]) {
      for (final s in list) {
        if (s.stationUuid == uuid) s.isFavorite = value;
      }
    }
    if (_currentStation?.stationUuid == uuid) {
      _currentStation?.isFavorite = value;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _scheduleRefreshTimer?.cancel();
    _scheduleDisplayTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
class ScheduledStation {
  final TimeOfDay time;
  final RadioStation station;
  bool triggered;

  ScheduledStation({
    required this.time,
    required this.station,
    this.triggered = false,
  });

  String get timeString {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $h:$m';
  }

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'station': station.toJson(),
  };

  factory ScheduledStation.fromJson(Map<String, dynamic> json) {
    return ScheduledStation(
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      station: RadioStation.fromJson(json['station'] as Map<String, dynamic>),
    );
  }
}