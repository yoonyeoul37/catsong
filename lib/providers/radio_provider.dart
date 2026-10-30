import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import 'player_provider.dart' show SimpleAudioHandler, PlayerProvider;
import '../services/schedule_service.dart';
import '../services/headset_resume.dart' show HeadsetResume;
import '../services/car_browse.dart' show CarBrowse;
import '../l10n/locale_holder.dart';
import '../screens/radio_korea_screen2.dart' show koreanStationDesc, koreanRadioStations;
import '../l10n/locale_holder.dart';

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

  List<ScheduledStation> _schedules = [];
  Timer? _scheduleCheckTimer;
  List<ScheduledStation> get schedules => _schedules;
  static const _maxSchedules = 5;
  Timer? _sleepTimer;
  Duration? _sleepRemaining;
  Timer? _sleepCountdown;
  /// 수면 타이머 남은 시간 (1초마다 바뀜). 이 값만 따로 알려서 화면 전체가 1초마다 다시 그려지지 않게
  final ValueNotifier<Duration?> sleepTick = ValueNotifier<Duration?>(null);
  bool _sleepFading = false; // 수면 타이머 끝나기 1분 전부터 작게 하는 중

  static const _keyFavorites = 'radio_favorites';
  static const _keyRecent = 'radio_recent';
  static const _keySchedules = 'radio_schedules';
  static const _maxRecent = 50;

  static const _apiServers = [
    'de1.api.radio-browser.info',
    'de2.api.radio-browser.info',
    'nl1.api.radio-browser.info',
  ];

  List<String>? _resolvedServers;

  Future<List<String>> _getApiServers() async {
    if (_resolvedServers != null && _resolvedServers!.isNotEmpty) {
      return _resolvedServers!;
    }
    try {
      final response = await http
          .get(Uri.https('all.api.radio-browser.info', '/json/servers'), headers: _apiHeaders)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final servers = data
            .map((e) => e['name'] as String?)
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
        if (servers.isNotEmpty) {
          _resolvedServers = servers;
          debugPrint('동적 서버 목록 획득: $servers');
          return servers;
        }
      }
    } catch (e) {
      debugPrint('서버 목록 조회 실패, 기본 목록 사용: $e');
    }
    return _apiServers;
  }
  static const _apiHeaders = {
    'User-Agent': 'CatSong/1.0 (kr.ssing.catsong)'
  };

  RadioPlayerState get playerState => _playerState;
  RadioStation? get currentStation => _currentStation;
  String? get errorMessage => _errorMessage;

  // TV로 보내기(캐스팅)용: 마지막으로 실제 재생한 방송 주소
  String? _lastPlayUrl;
  String? _lastPlayStationId;
  String? get lastPlayUrl => _lastPlayUrl;
  String? get lastPlayStationId => _lastPlayStationId;

  /// 방송국이 요구하는 헤더 (TV로 보낼 때 폰이 대신 붙여줌)
  Map<String, String> castHeadersFor(RadioStation s) => {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
        'Referer': _getReferer(s),
        'Origin': _getOrigin(s),
      };
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

  final ScheduleService _scheduleService = ScheduleService();

  StreamSubscription? _connectivitySubscription;

  RadioProvider() {
    _listenConnectivity();
    _player = Player(
      configuration: PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
      ),
    );
    _configurePlayer();
    _listenAudioFocus();
    _listenNativeAudioFocus();
    _initPlayerStreams();
    _startStreamTitleWatch();
    _initAudioSession();
    _loadFromPrefs();
    loadSavedSongs();
    _loadBlocklist(); // 안 나오는 해외 방송 목록
    _startScheduleRefreshTimer();
    _scheduleService.loadSchedule().then((_) {
      fetchJsonSchedule('CBS 음악FM');
      fetchJsonSchedule('CBS 표준FM');
      notifyListeners();
    });
  }

  // ── 안 나오는 해외 방송 빼기 (두 번 점검해서 확실히 안 나온 방송 · 백신이 막는 주소) ──
  Set<String> _blockedUuids = {};
  List<String> _blockedDomains = [];
  static const _blockUrl = 'https://files.ssing.kr/radio/block.json';

  bool _isBlocked(RadioStation s) {
    if (_blockedUuids.contains(s.stationUuid)) return true;
    if (_blockedDomains.isEmpty) return false;
    for (final u in [s.streamUrl, s.urlResolved ?? '']) {
      final host = (Uri.tryParse(u)?.host ?? '').toLowerCase();
      if (host.isEmpty) continue;
      if (_blockedDomains.any((d) => host == d || host.endsWith('.$d'))) return true;
    }
    return false;
  }

  void _applyBlock(String body) {
    final j = json.decode(body) as Map<String, dynamic>;
    _blockedUuids = {for (final u in (j['uuids'] as List? ?? [])) u.toString()};
    _blockedDomains = [for (final d in (j['domains'] as List? ?? [])) d.toString().toLowerCase()];
  }

  /// 저장해 둔 목록 먼저 (인터넷 없어도) → 새 목록 받으면 바꿔 끼우고 저장
  Future<void> _loadBlocklist() async {
    final p = await SharedPreferences.getInstance();
    try {
      final cached = p.getString('radio_block_json');
      if (cached != null) _applyBlock(cached);
    } catch (_) {}
    try {
      final r = await http.get(Uri.parse(_blockUrl)).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        _applyBlock(r.body);
        await p.setString('radio_block_json', r.body);
      }
    } catch (_) {}
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          debugPrint('오디오 인터럽트 발생 - 라디오 정지');
          if (_playerState == RadioPlayerState.playing) {
          _player.pause();
          _pausedByInterrupt = true; // 전화 등으로 멈춘 것만 나중에 다시 틀기
          _setPlayerState(RadioPlayerState.paused);
          _updateForeground(false);
          }
        } else {
          debugPrint('오디오 인터럽트 종료 - 라디오 재개');
          // 내가 직접 멈춰 둔 거면 그대로 (전화 끝나고 저절로 틀어지지 않게)
          if (_pausedByInterrupt && _currentStation != null && _playerState == RadioPlayerState.paused) {
            playStation(_currentStation!);
          }
          _pausedByInterrupt = false;
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        debugPrint('이어폰 제거 - 라디오 정지');
        stopRadio();
      });
    } catch (e) {
      debugPrint('AudioSession 초기화 오류: $e');
    }
  }

  bool _pausedByFocusLoss = false;
  bool _pausedByInterrupt = false; // 전화 등(인터럽트)으로 멈췄는지

  void _listenNativeAudioFocus() {
    // 신호 받는 곳은 음악 쪽 하나로 합치고, 라디오는 넘겨받기만
    PlayerProvider.extraHandler = (call) async {
      if (call.method == 'onAudioFocusLost') {
        // 이미 완전히 꺼진(idle) 상태거나, 사용자가 이미 직접 정지해둔 상태라면 건드리지 않음
        if (_playerState == RadioPlayerState.idle) return;
        if (_playerState == RadioPlayerState.paused) return;
        debugPrint('오디오 포커스 손실 - 라디오 일시정지');
        await _player.pause();
        _isActuallyPlaying = false;
        _pausedByFocusLoss = true;
        _setPlayerState(RadioPlayerState.paused);
        _updateForeground(false);
      } else if (call.method == 'onAudioFocusGain') {
        debugPrint('오디오 포커스 복구 - 라디오 재개');
        if (_currentStation != null &&
            _playerState == RadioPlayerState.paused &&
            _pausedByFocusLoss) {
          _pausedByFocusLoss = false;
          await playStation(_currentStation!);
        }
      }
    };
  }

  Future<void> _listenAudioFocus() async {
    try {
      final nativePlayer = _player.platform as NativePlayer;
      await nativePlayer.setProperty('audio-stream-exclusive', 'no');
      await nativePlayer.setProperty('audio-exclusive', 'no');
      await nativePlayer.setProperty('android-audio-focus', 'no');
    } catch (e) {
      debugPrint('오디오 포커스 설정 오류: $e');
    }
  }

  Future<void> _configurePlayer() async {
    try {
      final nativePlayer = _player.platform as NativePlayer;
      await nativePlayer.setProperty('user-agent', 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36');
      await nativePlayer.setProperty('demuxer-lavf-probesize', '4096');
      await nativePlayer.setProperty('stream-lavf-o', 'reconnect=1');
      await nativePlayer.setProperty('network-timeout', '15'); // 끊긴 연결을 30초씩 기다리지 않게
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

  /// 미디어 출력 둘째 줄 (편성표 없을 때): 한국 방송은 목록 설명, 해외는 나라 이름 (앱 언어로)
  String _mediaSubtitle(RadioStation station) {
    final code = (station.countryCode ?? '').toUpperCase();
    final isKo = AppLocale.current?.localeName.startsWith('ko') ?? false;
    if (code == 'KR' && isKo) {
      final d = koreanStationDesc(station.name);
      if (d != null) return d;
    }
    for (final c in RadioCountry.supported) {
      if (c.code == code) return c.displayName;
    }
    return station.country ?? 'Radio';
  }

  void _startForeground(RadioStation station, String url) {
    try {
      _simpleHandler?.setRadioMediaItem(
        title: station.name,
        artist: _mediaSubtitle(station),
        url: url,
      );
      _simpleHandler?.setRadioPlaybackState(playing: true);
      // 편성표를 이미 받았으면 둘째 줄을 프로그램으로 다시 (방송 설명으로 덮이지 않게)
      _updateNotification(station.name);
      debugPrint('포그라운드 서비스 시작');
    } catch (e) {
      debugPrint('포그라운드 서비스 오류: $e');
    }
  }

  void _updateForeground(bool playing) {
    try {
      if (_playerState != RadioPlayerState.idle) {
        _simpleHandler?.setRadioPlaybackState(playing: playing);
      }
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
        _stallTimer?.cancel(); // 소리 나옴 → 다시 연결 그만
        _stallRetries = 0;
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
      // 10초 넘게 계속 불러오는 중이면 새로 연결
      if (buffering) _armStall(10);
    });

    _player.stream.completed.listen((completed) async {
      if (completed) {
        debugPrint('재생 완료 신호 감지 - 자동 재연결 시도');
        _isActuallyPlaying = false;
        final station = _currentStation;
        if (station != null) {
          await Future.delayed(const Duration(seconds: 2));
          if (_currentStation?.stationUuid == station.stationUuid && !_isActuallyPlaying) {
            await playStation(station);
          }
        } else {
          _setPlayerState(RadioPlayerState.idle);
          _stopForeground();
        }
      }
    });

    _player.stream.error.listen((error) {
      debugPrint('media_kit 오류: $error');
      // 실제로 소리가 계속 나오고 있으면(mpv 자체 재연결 성공) 무시 - 순간적인 네트워크 흔들림
      if (error.isNotEmpty && !_player.state.playing) {
        _errorMessage = tr.stationLoadFailed;
        _isActuallyPlaying = false;
        _setPlayerState(RadioPlayerState.error);
      }
    });
  }

  Future<String?> _resolveStreamUrl(String url) async {
    try {
      if (url.contains('cfpwwwapi.kbs.co.kr')) {
        try {
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
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

      // MBC 표준FM/FM4U/올댓뮤직: 개인 중계 서버(serpent0) 대신 iMBC 공식 토큰 API 직접 호출
      if (url.contains('mbcsfm.pls') || url.contains('mbcfm.pls') || url.contains('mbcatm.pls') ||
          url.contains('sminiplay.imbc.com')) {
        final channel = (url.contains('mbcsfm.pls') || url.contains('channel=sfm'))
            ? 'sfm'
            : (url.contains('mbcatm.pls') || url.contains('channel=chm'))
                ? 'chm'
                : 'mfm';
        try {
          final tokenUri = Uri.parse('https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel=$channel');
          final response = await http.get(tokenUri).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final fresh = response.body.trim();
            if (fresh.startsWith('http')) {
              debugPrint('MBC 토큰 URL 추출: $fresh');
              return fresh;
            }
          }
        } catch (e) {
          debugPrint('MBC 토큰 발급 오류: $e');
        }
        return null;
      }

      // SBS 파워FM/러브FM: 개인 중계 서버 대신 SBS 공식 주소 (틀 때마다 새로 받음 · 시간이 지나면 못 쓰는 주소)
      if (url.contains('sbsfm.pls') || url.contains('sbs2fm.pls') || url.contains('apis.sbs.co.kr')) {
        final love = url.contains('sbs2fm.pls') || url.contains('lovefm');
        final api = love
            ? 'https://apis.sbs.co.kr/play-api/1.0/livestream/lovepc/lovefm?protocol=hls&ssl=Y'
            : 'https://apis.sbs.co.kr/play-api/1.0/livestream/powerpc/powerfm?protocol=hls&ssl=Y';
        try {
          final response = await http.get(Uri.parse(api), headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Referer': 'https://www.sbs.co.kr/',
          }).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final fresh = response.body.trim();
            if (fresh.startsWith('http')) return fresh;
          }
        } catch (e) {
          debugPrint('SBS 주소 받기 오류: $e');
        }
        return null;
      }

      // CPBC 가톨릭평화방송(서울): 개인 중계 서버 대신 공식 주소 (틀 때마다 새로 받음)
      if (url.contains('cpbc.pls') || url.contains('apis.cpbc.co.kr')) {
        try {
          final response = await http.get(Uri.parse('https://apis.cpbc.co.kr/play-api/2.0/onair/channel/radio'), headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Referer': 'https://www.cpbc.co.kr/',
          }).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final data = json.decode(utf8.decode(response.bodyBytes));
            final fresh = data['onair']?['source']?['mediasource']?['mediaurl'];
            if (fresh is String && fresh.startsWith('http')) return fresh;
          }
        } catch (e) {
          debugPrint('CPBC 주소 받기 오류: $e');
        }
        return null;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
      request.followRedirects = false;

      final response = await client.send(request).timeout(const Duration(seconds: 10));
      final statusCode = response.statusCode;
      debugPrint('resolve statusCode: $statusCode');

      if (statusCode == 301 || statusCode == 302 || statusCode == 307 || statusCode == 308) {
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
          final fileUrl = trimmed.substring(trimmed.indexOf('=') + 1).trim();
          if (fileUrl.startsWith('http')) {
            debugPrint('PLS에서 URL 추출: $fileUrl');
            client.close();
            return await _resolveStreamUrl(fileUrl) ?? fileUrl;
          }
        }
        if (trimmed.isNotEmpty && !trimmed.startsWith('#') && trimmed.startsWith('http')) {
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

  void Function(RadioStation station, String? image)? onStationPlayed; // image: 그때 프로그램 사진 (없으면 null)
  Timer? _playedTimer; // 30초 이상 들었을 때만 최근에 넣기
  bool _userPaused = false; // 사용자가 직접 멈춤 → 자동 다시 연결 안 함
  Timer? _stallTimer; // 너무 오래 '불러오는 중'이면 다시 연결
  int _stallRetries = 0;
  // 브라우저 이름표로는 웹페이지만 주는 해외 방송 → 재생기 이름표로 다시 (한 번 바꾸면 앱 켜져 있는 동안 기억)
  final Set<String> _playerUa = {};
  static const _browserUa = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
  static const _playerUaName = 'VLC/3.0.20 LibVLC/3.0.20'; // 연달아 다시 연결한 횟수 (3번까지)

  /// [secs]초 뒤에도 소리가 안 나오면 새로 연결 (와이파이↔LTE 바뀔 때 뱅뱅 도는 것 막기)
  void _armStall([int secs = 10]) {
    _stallTimer?.cancel();
    _stallTimer = Timer(Duration(seconds: secs), () {
      final st = _currentStation;
      if (st == null || _userPaused || _isActuallyPlaying) return;
      if (_playerState == RadioPlayerState.idle) return;
      if (_stallRetries >= 3) {
        // 계속 안 되면 그만하고 안내 (방송 자체 문제일 수 있음)
        _errorMessage = tr.stationLoadFailed;
        _setPlayerState(RadioPlayerState.error);
        return;
      }
      // 해외 방송이면 다음 연결은 재생기 이름표로 (옛날 방송 서버는 브라우저에겐 웹페이지를 줌)
      if ((st.countryCode ?? '') != 'KR') _playerUa.add(st.stationUuid);
      _stallRetries++;
      debugPrint('$secs초 넘게 소리 없음 → 다시 연결 ($_stallRetries번째)');
      playStation(st, force: true);
    });
  }
  Timer? _playedTick; // 듣는 동안 5분마다: 프로그램 사진이 바뀌면 '최근에 들었어요' 사진도 새로

  int _playGen = 0; // 가장 마지막에 누른 방송 번호 (늦게 끝난 예전 요청이 새 방송을 덮어쓰지 않게)

  Future<void> playStation(RadioStation station, {bool force = false}) async {
    // force: 네트워크가 바뀌어서 다시 연결할 때는 '불러오는 중'이어도 새로 시작
    if (_playerState == RadioPlayerState.loading && !force) {
      debugPrint('이미 로딩 중 - 중복 호출 무시');
      return;
    }
    final gen = ++_playGen;
    _userPaused = false;
    _armStall(15); // 연결하는 데 15초 넘게 걸리면 한 번 더
    // 30초 이상 들었을 때만 "최근에 들었어요"에 넣기
    _playedTimer?.cancel();
    _playedTick?.cancel();
    String? programImg() {
      final img = (currentProgramFor(station.name)?['image'] ?? '').toString().trim();
      return img.isEmpty ? null : img;
    }

    _playedTimer = Timer(const Duration(seconds: 30), () {
      if (_currentStation?.stationUuid != station.stationUuid || !isPlaying) return;
      // 들었을 때 나오던 프로그램 사진도 같이 (홈 '최근에 들었어요' 카드 사진)
      var sent = programImg();
      onStationPlayed?.call(station, sent);
      // 계속 듣는 동안 프로그램이 바뀌면 → 마지막으로 듣던 프로그램 사진으로 바꾸기
      _playedTick = Timer.periodic(const Duration(minutes: 5), (t) {
        if (_currentStation?.stationUuid != station.stationUuid || !isPlaying) {
          t.cancel(); // 다른 방송으로 바꿨거나 멈추면 그만
          return;
        }
        final img = programImg();
        if (img != sent) {
          sent = img;
          onStationPlayed?.call(station, img);
        }
      });
    });

    try {
      _errorMessage = null;
      _isActuallyPlaying = false;
      // 다른 방송국으로 바뀔 때만 편성표 초기화
      final prevStationName = _currentStation?.name;
      _setPlayerState(RadioPlayerState.loading);
      _currentStation = station;
      _streamTitle = null;
      if (prevStationName != station.name) {
        _currentProgramMap.remove(station.name);
        _nowPlayingMap.remove(station.name);
      }
      var qIdx = _currentQueue.indexWhere((s) => s.name == station.name);
      if (qIdx < 0) {
        // 목록 없이 틀었을 때(주사위·최근 청취 등): 이 방송이 들어 있는 목록으로 ⏮⏭ 맞추기
        final kr = koreanRadioStations();
        final k = kr.indexWhere((s) => s.name == station.name);
        if (k >= 0) {
          _currentQueue = kr; // 국내: 국내 전체 목록
          qIdx = k;
        } else {
          final cc = (station.countryCode ?? '').toUpperCase();
          final pool = (cc.isNotEmpty && (_countryCode ?? '').toUpperCase() == cc)
              ? _countryStations
              : <RadioStation>[];
          final j = pool.indexWhere((s) => s.stationUuid == station.stationUuid);
          if (j >= 0) {
            _currentQueue = List.from(pool); // 해외: 지금 보는 나라 목록
            qIdx = j;
          } else {
            _currentQueue = [station]; // 목록을 찾을 수 없으면 이 방송 하나만
            qIdx = 0;
          }
        }
      }
      _currentQueueIndex = qIdx;
      _startSchedule(station); // 편성표는 소리 연결을 기다리지 않고 바로 받기 시작
      notifyListeners();

      // 인터넷이 아예 없으면 바로 안내 (차 화면 · 알림창이 '재생 중'으로 멈춰 있지 않게)
      final net = await Connectivity().checkConnectivity();
      if (gen != _playGen) return;
      if (net.isEmpty || net.every((r) => r == ConnectivityResult.none)) {
        _stallTimer?.cancel();
        _simpleHandler?.setRadioMediaItem(title: station.name, artist: _mediaSubtitle(station), url: station.streamUrl);
        _simpleHandler?.setRadioMode(true);
        _errorMessage = tr.checkInternet;
        _setPlayerState(RadioPlayerState.error);
        return;
      }

      _onStopMusic?.call();
      await Future.delayed(const Duration(milliseconds: 200));
      // 차·위젯처럼 앱 화면이 없을 때도 오류 안 나게 (기다리지 않고 오류만 조용히 넘김)
      const MethodChannel('kr.ssing.catsong/media')
          .invokeMethod('requestAudioFocus')
          .catchError((Object _) => null);

      debugPrint('=== 라디오 재생 시작 ===');
      debugPrint('방송국: ${station.name}');
      debugPrint('station.url: ${station.streamUrl}');
      debugPrint('station.url_resolved: ${station.urlResolved}');

      String playUrl = station.playableUrl;
      final isKoreanDomestic = station.streamUrl.contains('cfpwwwapi.kbs.co.kr') ||
          station.streamUrl.contains('imbc.com') ||
          station.streamUrl.contains('mbcsfm.pls') ||
          station.streamUrl.contains('mbcfm.pls') ||
          station.streamUrl.contains('mbcatm.pls') ||
          station.streamUrl.contains('sbs.co.kr') ||
          station.streamUrl.contains('sbsfm.pls') ||
          station.streamUrl.contains('sbs2fm.pls') ||
          station.streamUrl.contains('cpbc') ||
          station.streamUrl.contains('ebs.co.kr');

      try {
        final freshUrl = await _resolveStreamUrl(station.streamUrl);
        if (freshUrl != null && freshUrl.isNotEmpty) {
          playUrl = freshUrl;
          debugPrint('리다이렉트 URL 추출: $playUrl');
        }
      } catch (e) {
        debugPrint('리다이렉트 실패 → url_resolved 사용');
      }

      if (!isKoreanDomestic && playUrl == station.playableUrl) {
        try {
          for (final server in _apiServers) {
            final uri = Uri.https(server, '/json/url/${station.stationUuid}');
            final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 10));
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

      if (gen != _playGen) return; // 주소 찾는 사이 다른 방송을 눌렀으면 이건 그만
      // 예전에 저장된 개인 중계 서버 주소로는 틀지 않음 (공식 주소를 못 받았으면 '불러올 수 없어요')
      if (playUrl.contains('duckdns.org')) {
        _stallTimer?.cancel();
        _errorMessage = tr.stationLoadFailed;
        _setPlayerState(RadioPlayerState.error);
        return;
      }
      debugPrint('FINAL_URL: $playUrl');
      _lastPlayUrl = playUrl;
      _lastPlayStationId = station.stationUuid;

      await WakelockPlus.disable().catchError((Object _) {});
      _startForeground(station, playUrl);

      // 해외 방송: 주소가 서버 첫 화면(http://주소:8000/)이거나 한 번 안 나왔던 방송이면 재생기 이름표로
      final isKr = (station.countryCode ?? '') == 'KR';
      final path = Uri.tryParse(playUrl)?.path ?? '';
      if (!isKr && (path.isEmpty || path == '/')) _playerUa.add(station.stationUuid);
      final ua = (!isKr && _playerUa.contains(station.stationUuid)) ? _playerUaName : _browserUa;
      try {
        await (_player.platform as NativePlayer).setProperty('user-agent', ua);
      } catch (_) {}
      await _player.open(
        Media(
          playUrl,
          httpHeaders: {
            'User-Agent': ua,
            'Referer': _getReferer(station),
            'Origin': _getOrigin(station),
          },
        ),
        play: true,
      );

      if (gen != _playGen) return; // 연결되는 사이 다른 방송을 눌렀으면 기록 안 함
      await recordListened(station);
      _updateWidget(station.name, _mediaSubtitle(station), true); // 알림창과 같은 한글 설명

    } catch (e) {
      if (gen != _playGen) return; // 예전 요청이 실패한 건 무시 (지금 방송은 따로 연결 중)
      debugPrint('라디오 재생 실패: $e');
      _errorMessage = tr.stationLoadFailed;
      _setPlayerState(RadioPlayerState.error);
    }
  }

  /// 편성표 받기 시작 (방송을 틀 때마다) — 받는 동안은 '받는 중'이라 화면에 설명 카드를 안 보여 줌
  /// (예전엔 소리가 연결된 뒤에 받아서 그동안 설명 카드가 번쩍 보였음 → 이제는 틀자마자 받기 시작)
  void _startSchedule(RadioStation station) {
    final name = station.name;
    final jobs = <Future<void>>[];
    // JSON 편성표 확인 (KBS/MBC/SBS 아닌 경우만)
    if (name == '국방FM') {
      jobs.add(fetchKfnSchedule());
    }
    // KBS 편성표
    if (station.broadcaster == null && station.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
      jobs.add(fetchScheduleByUrl(name, station.streamUrl));
    } else if (name.contains('KBS')) {
      jobs.add(fetchScheduleByUrl(name, station.streamUrl));
    }
    // MBC/SBS 편성표
    if (name == 'MBC 표준FM' || name == 'MBC FM4U') {
      jobs.add(fetchMbcSchedule(name));
    }
    if (name == 'SBS 파워FM' || name == 'SBS 러브FM') {
      jobs.add(fetchSbsSchedule(name));
    }
    if (name == 'EBS 반디') {
      jobs.add(fetchEbsBandiSchedule());
    }
    if (name == 'EBS FM') {
      jobs.add(fetchEbsFmSchedule());
    }
    final isKbsMbcSbs = name.contains('KBS') ||
        _mbcChannelTypes.containsKey(name) || // 서울 MBC만 (지역 MBC는 편성표 파일 사용)
        name.contains('SBS');
    // 편성표 파일(schedule.json)에 있는 방송은 바로 채움
    if (!isKbsMbcSbs && _scheduleService.hasSchedule(name)) {
      final program = _scheduleService.getCurrentProgram(name);
      if (program != null) {
        _currentProgramMap[name] = {
          'program_title': program['title'],
          'start_time': program['start'],
          'end_time': program['end'],
          'is_rerun': false,
          'image': program['image'], // 편성표 파일에 사진이 있으면 (CBS)
        };
        _nowPlayingMap[name] = program['title'] as String? ?? '';
      }
      _scheduleListMap[name] =
          _scheduleService.getScheduleList(name).map((p) => {
            'program_title': p['title'],
            'start_time': p['start'],
            'end_time': p['end'],
            'image': p['image'],
          }).toList();
    }
    // 인터넷에서 받는 편성표: 다 받을 때까지 '받는 중' → 끝나면 풀고 화면 다시 그리기
    if (jobs.isEmpty) return;
    _scheduleLoading.add(name);
    () async {
      try {
        await Future.wait(jobs);
      } catch (_) {}
      _scheduleLoading.remove(name);
      notifyListeners();
    }();
  }

  String _getReferer(RadioStation station) {
    final url = station.playableUrl.toLowerCase();
    if (url.contains('kbs')) return 'https://www.kbs.co.kr/';
    if (url.contains('imbc') || url.contains('mbc')) return 'https://www.imbc.com/';
    if (url.contains('sbs')) return 'https://www.sbs.co.kr/';
    if (url.contains('cpbc')) return 'https://www.cpbc.co.kr/';
    if (url.contains('ebs')) return 'https://www.ebs.co.kr/';
    if (url.contains('ytn')) return 'https://www.ytn.co.kr/';
    if (url.contains('cbs')) return 'https://www.cbs.co.kr/';
    if (url.contains('tbn')) return 'https://tbn.or.kr/';
    return '';
  }

  String _getOrigin(RadioStation station) {
    final url = station.playableUrl.toLowerCase();
    if (url.contains('kbs')) return 'https://www.kbs.co.kr';
    if (url.contains('imbc') || url.contains('mbc')) return 'https://www.imbc.com';
    if (url.contains('sbs')) return 'https://www.sbs.co.kr';
    if (url.contains('cpbc')) return 'https://www.cpbc.co.kr';
    if (url.contains('ebs')) return 'https://www.ebs.co.kr';
    if (url.contains('ytn')) return 'https://www.ytn.co.kr';
    if (url.contains('cbs')) return 'https://www.cbs.co.kr';
    if (url.contains('tbn')) return 'https://tbn.or.kr';
    return '';
  }

  /// 아침 알람: 작게 시작해서 천천히 키우기 (0.0 ~ 1.0)
  Future<void> setAlarmVolume(double v) async {
    try {
      await _player.setVolume(v.clamp(0.0, 1.0) * 100);
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    if (_playerState == RadioPlayerState.playing) {
      _userPaused = true; // 직접 멈춤 → 네트워크 바뀌어도 다시 켜지 않음
      _stallTimer?.cancel();
      await _player.pause();
      await WakelockPlus.disable().catchError((Object _) {});
    } else if (_playerState == RadioPlayerState.paused) {
      if (_currentStation != null) {
        await playStation(_currentStation!);
      }
    }
  }

  Future<void> stopRadio() async {
    _stallTimer?.cancel();
    _setPlayerState(RadioPlayerState.idle);
    await _player.stop();
    _isActuallyPlaying = false;
    _stopForeground();
    await WakelockPlus.disable().catchError((Object _) {});
    cancelSleepTimer();
  }

  Future<void> stopRadioAndClear() async {
    await stopRadio();
    _currentStation = null;
    notifyListeners();
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
  final Map<String, int> _countryStationCounts = {};
  int? getCountryStationCount(String countryCode) => _countryStationCounts[countryCode];

  // ── 나라 방송 전체를 200개씩 이어서 불러오기 ──
  String? _countryCode;
  int _countryOffset = 0; // 서버에서 받은 개수 (같은 방송 포함)
  bool _countryHasMore = false;
  bool _isLoadingMoreCountry = false;
  final Set<String> _countryNameKeys = {}; // 같은 이름 방송은 하나만
  final Map<String, String> _stationLanguage = {}; // 방송 → 언어 (언어 칩용)
  final Map<String, int> _stationTrend = {}; // 방송 → 최근 이틀 사이 늘어난 청취 수 (요즘 뜨는 탭용)
  bool get countryHasMore => _countryHasMore;
  bool get isLoadingMoreCountry => _isLoadingMoreCountry;
  String languageOf(String stationUuid) => _stationLanguage[stationUuid] ?? '';
  int trendOf(String stationUuid) => _stationTrend[stationUuid] ?? 0;

  static String _nameKey(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  Future<void> fetchAllCountryCounts() async {
    if (_countryStationCounts.isNotEmpty) return;
    try {
      final servers = await _getApiServers();
      final uri = Uri.https(servers.first, '/json/countrycodes', {
        'hidebroken': 'true',
      });
      final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (final item in data) {
          final code = item['name'] as String? ?? '';
          final count = item['stationcount'] as int? ?? 0;
          if (code.isNotEmpty && count > 0) {
            _countryStationCounts[code] = count; // 이제 200개로 자르지 않음 (전부 불러옴)
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('국가별 채널 수 로드 실패: $e');
    }
  }

  /// 한 번에 [limit]개 받아서 같은 방송은 빼고 뒤에 붙이기. 서버가 준 개수 (실패면 -1)
  Future<int> _fetchCountryPage(String countryCode, int offset, int limit) async {
    List<String> servers;
    try {
      servers = await _getApiServers();
    } catch (e) {
      return -1;
    }
    for (final server in servers) {
      try {
        final uri = Uri.https(server, '/json/stations/bycountrycodeexact/$countryCode', {
          'order': 'clickcount',
          'reverse': 'true',
          'offset': '$offset',
          'limit': '$limit',
          'hidebroken': 'true',
          'lastcheckok': '1',
          'codec': 'MP3,AAC,AAC+,OGG',
        });
        final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) continue;
        final List<dynamic> data = json.decode(response.body);
        if (_countryCode != countryCode) return 0; // 그 사이 다른 나라로 바뀜
        final added = <RadioStation>[];
        for (final j in data) {
          final m = j as Map<String, dynamic>;
          if (_countryApiName == null && (m['country'] ?? '').toString().trim().isNotEmpty) {
            _countryApiName = m['country'].toString().trim();
          }
          final s = RadioStation.fromJson(m);
          if (s.streamUrl.isEmpty) continue;
          if (_isBlocked(s)) continue; // 안 나오는 방송 빼기
          final key = _nameKey(s.name);
          if (key.isEmpty || !_countryNameKeys.add(key)) continue; // 인기 많은 쪽 하나만 남김
          final lang = (m['language'] ?? '').toString().split(',').first.trim();
          if (lang.isNotEmpty) _stationLanguage[s.stationUuid] = lang;
          final trend = m['clicktrend'];
          if (trend is num) _stationTrend[s.stationUuid] = trend.toInt();
          added.add(s);
        }
        _mergeFavoriteFlags(added);
        _countryStations = [..._countryStations, ...added];
        return data.length;
      } catch (e) {
        debugPrint('국가별 방송 로드 오류($server): $e');
      }
    }
    return -1;
  }

  /// 차 화면(안드로이드 오토)용 나라별 인기 방송 — 화면에 보이는 목록은 건드리지 않음
  Future<List<RadioStation>> fetchTopForCar(String countryCode, {int limit = 60}) async {
    List<String> servers;
    try {
      servers = await _getApiServers();
    } catch (_) {
      return const [];
    }
    for (final server in servers) {
      try {
        final uri = Uri.https(server, '/json/stations/bycountrycodeexact/$countryCode', {
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '${limit * 2}',
          'hidebroken': 'true',
          'lastcheckok': '1',
          'codec': 'MP3,AAC,AAC+,OGG',
        });
        final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final List<dynamic> data = json.decode(response.body);
        final keys = <String>{};
        final out = <RadioStation>[];
        for (final j in data) {
          final s = RadioStation.fromJson(j as Map<String, dynamic>);
          if (s.streamUrl.isEmpty || _isBlocked(s)) continue; // 안 나오는 방송 빼기
          final key = _nameKey(s.name);
          if (key.isEmpty || !keys.add(key)) continue; // 같은 방송은 인기 많은 쪽 하나만
          out.add(s);
          if (out.length >= limit) break;
        }
        _mergeFavoriteFlags(out);
        return out;
      } catch (_) {}
    }
    return const [];
  }

  Future<void> fetchTopStations(String countryCode, {int limit = 200, int retryCount = 0}) async {
    if (retryCount == 0) {
      _countryCode = countryCode;
      _countryStations = [];
      _countryNameKeys.clear();
      _countryApiName = null;
      _countryStates = {};
      _stateRawNames.clear();
      _stateTried.clear();
      _loadingState = null;
      _countryOffset = 0;
      _countryHasMore = false;
      _isLoadingMoreCountry = false;
      _isLoadingCountryStations = true;
      notifyListeners();
    }

    final got = await _fetchCountryPage(countryCode, 0, limit);
    if (_countryCode != countryCode) return;

    if (_countryStations.isEmpty && retryCount < 4) {
      debugPrint('국가별 방송 재시도: ${retryCount + 1}회차');
      await Future.delayed(const Duration(milliseconds: 1000));
      return fetchTopStations(countryCode, limit: limit, retryCount: retryCount + 1);
    }

    if (got > 0) {
      _countryOffset = got;
      _countryHasMore = got >= limit;
      _fetchCountryStates(countryCode);
    }
    _countryStationCounts.putIfAbsent(countryCode, () => _countryStations.length);
    _isLoadingCountryStations = false;
    notifyListeners();
  }

  // ── 지역(주): 서버에 이 나라 지역 목록과 방송 수를 물어봄 ──
  String? _countryApiName; // 서버가 쓰는 나라 이름 (예: The United States Of America)
  Map<String, int> _countryStates = {}; // 맞춘 지역 이름 → 방송 수
  final Map<String, Set<String>> _stateRawNames = {}; // 맞춘 이름 → 서버 이름들 (CA, California)
  final Set<String> _stateTried = {}; // 이미 불러온 지역
  String? _loadingState;
  static List<dynamic>? _allStatesCache;
  Map<String, int> get countryStates => _countryStates;
  bool stateTried(String state) => _stateTried.contains(state);
  bool isStateLoading(String state) => _loadingState == state;

  // 미국 주 약자 → 이름 (CA, California 를 한 지역으로 묶기)
  static const Map<String, String> _usStates = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California',
    'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia',
    'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa',
    'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri',
    'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
    'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio',
    'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
    'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
    'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming',
    'DC': 'District of Columbia',
  };

  /// 지역 이름을 하나로 맞추기 (대소문자·띄어쓰기·미국 주 약자)
  static String normState(String raw, String countryCode) {
    var st = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (st.isEmpty) return '';
    if (countryCode.toUpperCase() == 'US') {
      final full = _usStates[st.toUpperCase()];
      if (full != null) return full;
    }
    // 전부 대문자이거나 전부 소문자면 첫 글자만 대문자로 (CALIFORNIA, california → California)
    if (st.length > 3 && (st == st.toUpperCase() || st == st.toLowerCase())) {
      st = st.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    }
    return st;
  }

  Map<String, int> _statesFrom(List<dynamic> items, String countryCode, String name) {
    final counts = <String, int>{};
    _stateRawNames.clear();
    for (final it in items) {
      if (it is! Map) continue;
      if ((it['country'] ?? '').toString().toLowerCase() != name.toLowerCase()) continue;
      final raw = (it['name'] ?? '').toString();
      final key = normState(raw, countryCode);
      if (key.isEmpty) continue;
      final c = it['stationcount'] is num ? (it['stationcount'] as num).toInt() : 0;
      if (c <= 0) continue;
      counts[key] = (counts[key] ?? 0) + c;
      _stateRawNames.putIfAbsent(key, () => <String>{}).add(raw);
    }
    return counts;
  }

  Future<void> _fetchCountryStates(String countryCode) async {
    final name = _countryApiName;
    if (name == null || name.isEmpty) return;
    List<String> servers;
    try {
      servers = await _getApiServers();
    } catch (e) {
      return;
    }
    var counts = <String, int>{};
    // 먼저 이 나라 지역만
    for (final server in servers) {
      try {
        final uri = Uri.https(server, '/json/states/$name/', {'hidebroken': 'true'});
        final r = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) continue;
        final d = json.decode(r.body);
        if (d is List) counts = _statesFrom(d, countryCode, name);
        break;
      } catch (e) {
        debugPrint('지역 목록 오류($server): $e');
      }
    }
    // 안 되면 전체 지역 목록에서 이 나라 것만 (한 번 받아서 계속 씀)
    if (counts.isEmpty) {
      if (_allStatesCache == null) {
        for (final server in servers) {
          try {
            final uri = Uri.https(server, '/json/states', {'hidebroken': 'true'});
            final r = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 25));
            if (r.statusCode != 200) continue;
            final d = json.decode(r.body);
            if (d is List) _allStatesCache = d;
            break;
          } catch (e) {
            debugPrint('전체 지역 목록 오류($server): $e');
          }
        }
      }
      if (_allStatesCache != null) counts = _statesFrom(_allStatesCache!, countryCode, name);
    }
    if (_countryCode != countryCode) return;
    _countryStates = counts;
    notifyListeners();
  }

  /// 지역을 고르면 그 지역 방송을 서버에서 따로 불러와 목록에 붙이기
  Future<void> fetchStateStations(String state) async {
    final code = _countryCode;
    if (code == null || _stateTried.contains(state) || _loadingState != null) return;
    _stateTried.add(state);
    _loadingState = state;
    notifyListeners();
    final raws = _stateRawNames[state] ?? {state};
    final added = <RadioStation>[];
    try {
      final servers = await _getApiServers();
      for (final raw in raws.take(5)) {
        for (final server in servers) {
          try {
            final uri = Uri.https(server, '/json/stations/search', {
              'countrycode': code,
              'state': raw,
              'order': 'clickcount',
              'reverse': 'true',
              'limit': '300',
              'hidebroken': 'true',
            });
            final r = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
            if (r.statusCode != 200) continue;
            final List<dynamic> data = json.decode(r.body);
            if (_countryCode != code) break;
            for (final j in data) {
              final m = j as Map<String, dynamic>;
              final codec = (m['codec'] ?? '').toString().toUpperCase();
              if (codec.isNotEmpty && !const ['MP3', 'AAC', 'AAC+', 'OGG'].contains(codec)) continue;
              if (m['lastcheckok'] == 0) continue;
              final s = RadioStation.fromJson(m);
              if (s.streamUrl.isEmpty) continue;
              if (_isBlocked(s)) continue; // 안 나오는 방송 빼기
              if (normState(s.state ?? '', code) != state) continue;
              final key = _nameKey(s.name);
              if (key.isEmpty || !_countryNameKeys.add(key)) continue;
              final lang = (m['language'] ?? '').toString().split(',').first.trim();
              if (lang.isNotEmpty) _stationLanguage[s.stationUuid] = lang;
              final trend = m['clicktrend'];
              if (trend is num) _stationTrend[s.stationUuid] = trend.toInt();
              added.add(s);
            }
            break;
          } catch (e) {
            debugPrint('지역 방송 로드 오류($server): $e');
          }
        }
      }
    } catch (e) {
      debugPrint('지역 방송 로드 실패: $e');
    }
    if (_countryCode == code && added.isNotEmpty) {
      _mergeFavoriteFlags(added);
      _countryStations = [..._countryStations, ...added];
    }
    _loadingState = null;
    notifyListeners();
  }

  /// 목록 끝에 가까워지면 다음 200개 더 불러오기
  Future<void> fetchMoreCountryStations({int limit = 200}) async {
    final code = _countryCode;
    if (code == null || !_countryHasMore || _isLoadingMoreCountry || _isLoadingCountryStations) return;
    _isLoadingMoreCountry = true;
    notifyListeners();
    final got = await _fetchCountryPage(code, _countryOffset, limit);
    if (_countryCode == code && got >= 0) {
      _countryOffset += got;
      _countryHasMore = got >= limit;
    }
    // 실패(-1)면 그대로 두고, 다음에 내리면 다시 시도
    _isLoadingMoreCountry = false;
    notifyListeners();
  }

  // ── 지금 나오는 곡 (방송이 소리와 같이 보내 주는 곡 이름) ──
  String? _streamTitle;
  String? get streamTitle => _streamTitle;

  // ── 저장한 곡 (라디오에서 ♡ 누른 곡) ──
  static const _keySongs = 'radio_saved_songs';
  List<Map<String, dynamic>> _savedSongs = [];
  bool _songsLoaded = false;
  List<Map<String, dynamic>> get savedSongs => _savedSongs;

  Future<void> loadSavedSongs() async {
    if (_songsLoaded) return;
    _songsLoaded = true;
    final p = await SharedPreferences.getInstance();
    _savedSongs = (p.getStringList(_keySongs) ?? [])
        .map((s) {
          try {
            return json.decode(s) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
    notifyListeners();
  }

  bool isSongSaved(String title) => _savedSongs.any((m) => m['title'] == title);

  /// ♡: 곡 저장 (이미 있으면 빼기). 저장했으면 true
  Future<bool> toggleSavedSong(String title, RadioStation station) async {
    await loadSavedSongs();
    final i = _savedSongs.indexWhere((m) => m['title'] == title);
    final saved = i < 0;
    if (saved) {
      _savedSongs.insert(0, {
        'title': title,
        'station': station.name,
        'cc': station.countryCode ?? '',
        'at': DateTime.now().toIso8601String(),
      });
      if (_savedSongs.length > 300) _savedSongs = _savedSongs.sublist(0, 300);
    } else {
      _savedSongs.removeAt(i);
    }
    notifyListeners();
    await _saveSongs();
    return saved;
  }

  /// 지운 자리 번호를 돌려줌 (되돌리기용)
  int removeSavedSong(Map<String, dynamic> song) {
    final i = _savedSongs.indexOf(song);
    if (i >= 0) {
      _savedSongs.removeAt(i);
      notifyListeners();
      _saveSongs();
    }
    return i;
  }

  void restoreSavedSong(int index, Map<String, dynamic> song) {
    if (_savedSongs.contains(song)) return;
    _savedSongs.insert(index.clamp(0, _savedSongs.length), song);
    notifyListeners();
    _saveSongs();
  }

  Future<void> _saveSongs() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_keySongs, _savedSongs.map((m) => json.encode(m)).toList());
  }
  Timer? _streamTitleTimer;

  void _startStreamTitleWatch() {
    _streamTitleTimer?.cancel();
    _streamTitleTimer = Timer.periodic(const Duration(seconds: 4), (_) => _readStreamTitle());
  }

  Future<void> _readStreamTitle() async {
    final st = _currentStation;
    if (st == null || !isPlaying) return;
    var raw = '';
    try {
      final native = _player.platform as NativePlayer;
      raw = (await native.getProperty('metadata/by-key/icy-title')).trim();
    } catch (_) {}
    String? t = (raw.isEmpty || raw == 'null') ? null : raw;
    if (t != null) {
      final low = t.toLowerCase();
      // 방송 이름만 보내거나 광고·빈 값이면 안 보여줌
      if (t.length < 3 ||
          low == st.name.toLowerCase() ||
          low.contains('advert') ||
          low == 'unknown' ||
          RegExp(r'^[\s\-–_|.]+$').hasMatch(t)) {
        t = null;
      }
    }
    if (t != _streamTitle) {
      _streamTitle = t;
      notifyListeners();
    }
  }

  // ══════ 편성표 ══════
  final Map<String, List<Map<String, dynamic>>> _scheduleListMap = {};
  final Set<String> _scheduleLoading = {}; // 지금 인터넷에서 편성표 받는 중인 방송
  /// 편성표를 받는 중인지 (받는 동안은 설명 카드 안 보여 주기)
  bool isScheduleLoading(String name) => _scheduleLoading.contains(name);
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

  /// 편성표 파일(schedule.json)에 이 방송이 있는지 (지역 MBC 등)
  bool hasFileSchedule(String name) => _scheduleService.hasSchedule(name);

  /// 지금 방송을 쉬는 시간인지 (주사위에서 빼려고)
  bool isOffAirNow(String name) {
    // 1) 지금 프로그램 이름이 '방송 안 함'
    final title = (_nowPlayingMap[name] ?? '').replaceAll(' ', '');
    if (title.contains('방송시간이아닙니다') || title.contains('정파') || title.contains('휴지')) return true;
    // 2) 편성표 파일 방송: 편성은 있는데 지금 시간에 맞는 프로그램이 없음 (예: CPBC 새벽 2~5시)
    if (_scheduleService.hasSchedule(name) && _scheduleService.getCurrentProgram(name) == null) return true;
    // 3) EBS: 받아 둔 하루 편성표에 지금 시간이 비어 있음
    if (name == 'EBS 반디' || name == 'EBS FM') {
      final list = _scheduleListMap[name];
      if (list != null && list.isNotEmpty) {
        final n = DateTime.now();
        final hm = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
        final on = list.any((s) {
          final st = s['start_time'] as String? ?? '';
          final en = s['end_time'] as String? ?? '';
          if (st.length < 5 || en.length < 5) return false;
          return en.compareTo(st) > 0
              ? st.compareTo(hm) <= 0 && hm.compareTo(en) < 0
              : st.compareTo(hm) <= 0 || hm.compareTo(en) < 0; // 자정 넘는 프로그램
        });
        if (!on) return true;
      }
    }
    return false;
  }
  final Map<String, String> _nowPlayingMap = {};
  String? nowPlayingFor(String stationName) => _nowPlayingMap[stationName];

  final Set<String> _scheduleAttempted = {};
  bool hasAttemptedSchedule(String stationName) => _scheduleAttempted.contains(stationName);
  void markScheduleAttempted(String stationName) => _scheduleAttempted.add(stationName);

  // 문자 참여 번호
  static const _homepageUrls = {
    'KBS 제1라디오': 'https://radio.kbs.co.kr/',
    'KBS 해피FM': 'https://radio.kbs.co.kr/',
    'KBS Cool FM': 'https://radio.kbs.co.kr/',
    'KBS Classic FM': 'https://radio.kbs.co.kr/',
    'MBC 표준FM': 'https://www.imbc.com/broad/radio/',
    'MBC FM4U': 'https://www.imbc.com/broad/radio/',
    'SBS 파워FM': 'https://www.sbs.co.kr/radio',
    'SBS 러브FM': 'https://www.sbs.co.kr/radio',
    'EBS 반디': 'https://www.ebs.co.kr/radio/home',
    'CBS 표준FM': 'https://www.cbs.co.kr/radio',
    'CBS 음악FM': 'https://www.cbs.co.kr/radio',
  };

  String? homepageFor(String stationName) => _homepageUrls[stationName];

  static const _stationDescriptions = {
    'YTN 라디오': '대한민국 24시간 뉴스 채널',
    'CBS 표준FM': '기독교 정신으로 소통하는 방송',
    'CBS 음악FM': '좋은 음악으로 채우는 하루',
    'BBS 불교방송': '지혜와 자비를 전하는 불교 방송',
    'FEBC 극동방송': '복음을 전하는 기독교 방송',
    '국방FM': '군 장병과 함께하는 방송',
    '국악FM': '우리 소리를 지키는 국악 전문 방송',
    'TBS FM': '시민과 함께하는 교통·생활 정보 방송',
    '경인방송': '인천·경기를 대표하는 라디오 방송',
    'CPBC 가톨릭': '평화와 나눔을 전하는 가톨릭 방송',
    'JTV 매직FM': '전북을 사랑하는 라디오 방송',
    'OBS 라디오': '경인 지역 라디오 방송',
    'BeFM': '부산을 대표하는 FM 방송',
    'TBN 경인교통': '경인 지역 교통·생활 정보 방송',
    'TBN 울산교통': '울산 지역 교통·생활 정보 방송',
    '부산MBC 표준FM': '부산·경남을 대표하는 MBC 방송',
    '부산MBC FM4U': '부산·경남을 대표하는 MBC 방송',
    '광주MBC 표준FM': '광주·전남을 대표하는 MBC 방송',
    '광주MBC FM4U': '광주·전남을 대표하는 MBC 방송',
    '안동MBC 표준FM': '경북 북부를 대표하는 MBC 방송',
    '안동MBC FM4U': '경북 북부를 대표하는 MBC 방송',
    '울산MBC 표준FM': '울산을 대표하는 MBC 방송',
    '제주MBC 표준FM': '제주를 대표하는 MBC 방송',
    '제주MBC FM4U': '제주를 대표하는 MBC 방송',
    '춘천MBC 표준FM': '강원을 대표하는 MBC 방송',
    '춘천MBC FM4U': '강원을 대표하는 MBC 방송',
    '포항MBC 표준FM': '경북 동부를 대표하는 MBC 방송',
    '대전MBC 표준FM': '대전·충남을 대표하는 MBC 방송',
    '목포MBC 표준FM': '전남 서부를 대표하는 MBC 방송',
    'MBC경남 표준FM': '경남을 대표하는 MBC 방송',
    'MBC충북 표준FM': '충북을 대표하는 MBC 방송',
    'MBC충북 FM4U': '충북을 대표하는 MBC 방송',
  };

  String? descriptionFor(String stationName) => _stationDescriptions[stationName];

  static const _smsNumbers = {
    'MBC 표준FM': '8001',
    'MBC FM4U': '8000',
  };

  String? smsNumberFor(String stationName) => _smsNumbers[stationName];

  // KBS
  static const _kbsChannelCodes = {
    'KBS 제1라디오': '21',
    'KBS 해피FM': '22',
    'KBS 3라디오': '23',
    'KBS Classic FM': '24',
    'KBS Cool FM': '25',
  };

  /// KBS 편성 사진: 바깥에서 못 여는 주소(접근 거부)는 '사진 없음'으로 → 바로 기본 이미지
  static String? _kbsImage(dynamic url) {
    final u = url?.toString() ?? '';
    if (u.isEmpty || u.contains('padmin.static.kbs.co.kr')) return null;
    return u;
  }

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
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final yesterdayStr = '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';

    try {
      final uri = Uri.parse(
        'https://static.api.kbs.co.kr/mediafactory/v1/schedule/weekly'
            '?&rtype=json&local_station_code=00'
            '&channel_code=$channelCode'
            '&program_planned_date_from=$yesterdayStr'
            '&program_planned_date_to=$dateStr',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final List<dynamic> allSchedules = [];
          for (final d in data) {
            allSchedules.addAll(d['schedules'] as List<dynamic>? ?? []);
          }
          // program_code 기준으로 연속된 항목 병합
          final merged = _mergeKbsSchedules(allSchedules.cast<Map<String, dynamic>>());
          for (final s in merged) {
            s['image'] = _kbsImage(s['image_w']);
          }
          _scheduleListMap[stationName] = merged;
          final nowHour = now.hour;
          final nowMin = now.minute;
          // 자정 이후면 24시간 형식으로 변환 (예: 00:30 → 2430 형식)
          final nowTimeInt = nowHour < 6
              ? (24 + nowHour) * 1000000 + nowMin * 10000
              : nowHour * 1000000 + nowMin * 10000;
          final currentSchedules = _scheduleListMap[stationName] ?? [];
          for (int i = 0; i < currentSchedules.length; i++) {
            final s = currentSchedules[i];
            final start = s['program_planned_start_time'] as String? ?? '';
            final end = s['program_planned_end_time'] as String? ?? '';
            final startInt = int.tryParse(start) ?? 0;
            final endInt = int.tryParse(end) ?? 0;
            if (nowTimeInt >= startInt && nowTimeInt < endInt) {
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
              merged['image'] = _kbsImage(s['image_w']);
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
    debugPrint('fetchScheduleByUrl 호출됨: $stationName / codes: $codes');
    if (codes == null) return;
    final localCode = codes['local']!;
    final channelCode = codes['channel']!;

    _scheduleListMap.remove(stationName);
    _currentProgramMap.remove(stationName);
    _nowPlayingMap.remove(stationName);

    final now = DateTime.now();
    // 새벽 0~5시는 어제 날짜 데이터에 자정 이후 편성이 포함되어 있음
    final targetDay = now.hour < 5
        ? DateTime.now().subtract(const Duration(days: 1))
        : DateTime.now();
    final dateStr = '${targetDay.year}${targetDay.month.toString().padLeft(2, '0')}${targetDay.day.toString().padLeft(2, '0')}';

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
          final List<dynamic> allSchedules = [];
          for (final d in data) {
            allSchedules.addAll(d['schedules'] as List<dynamic>? ?? []);
          }
          // program_code 기준으로 연속된 항목 병합
          final merged = _mergeKbsSchedules(allSchedules.cast<Map<String, dynamic>>());
          for (final s in merged) {
            s['image'] = _kbsImage(s['image_w']);
          }
          _scheduleListMap[stationName] = merged;
          final nowHour = now.hour;
          final nowMin = now.minute;
          final nowTimeInt = nowHour < 6
              ? (24 + nowHour) * 1000000 + nowMin * 10000
              : nowHour * 1000000 + nowMin * 10000;
          final currentSchedules = _scheduleListMap[stationName] ?? [];
          for (int i = 0; i < currentSchedules.length; i++) {
            final s = currentSchedules[i];
            final start = s['program_planned_start_time'] as String? ?? '';
            final end = s['program_planned_end_time'] as String? ?? '';
            final startInt = int.tryParse(start) ?? 0;
            final endInt = int.tryParse(end) ?? 0;
            if (nowTimeInt >= startInt && nowTimeInt < endInt) {
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
    _updateNotification(stationName);
    notifyListeners();
  }

  // KBS 편성표: 같은 program_code 연속 항목을 하나로 병합
  // 재방송 여부: rerun_classification == '재방'
  List<Map<String, dynamic>> _mergeKbsSchedules(List<Map<String, dynamic>> schedules) {
    if (schedules.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    Map<String, dynamic>? current;

    for (final s in schedules) {
      final code = s['program_code'] as String? ?? '';
      final isRerun = (s['rerun_classification'] as String? ?? '') == '재방';

      if (current == null) {
        current = Map<String, dynamic>.from(s);
        current['is_rerun'] = isRerun;
      } else {
        final currentCode = current['program_code'] as String? ?? '';
        if (code == currentCode) {
          // 같은 프로그램 → 끝 시간만 업데이트
          current['program_planned_end_time'] = s['program_planned_end_time'];
        } else {
          result.add(current);
          current = Map<String, dynamic>.from(s);
          current['is_rerun'] = isRerun;
        }
      }
    }
    if (current != null) result.add(current);
    return result;
  }

  String formatScheduleTime(String time) {
    if (time.length < 4) return time;
    int hour = int.tryParse(time.substring(0, 2)) ?? 0;
    final min = time.substring(2, 4);
    if (hour >= 24) hour -= 24;
    final period = hour < 12 ? '오전' : '오후';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $h12:$min';
  }

  // MBC
  static const _mbcChannelTypes = {
    'MBC 표준FM': 'FM',
    'MBC FM4U': 'FM4U',
  };

  Future<void> fetchMbcSchedule(String stationName) async {
    debugPrint('=== fetchMbcSchedule 호출됨: $stationName ===');
    final sType = _mbcChannelTypes[stationName];
    debugPrint('=== sType: $sType ===');
    if (sType == null) return;

    _scheduleListMap.remove(stationName);
    _currentProgramMap.remove(stationName);
    _nowPlayingMap.remove(stationName);

    try {
      final now = DateTime.now();
      final targetDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      debugPrint('=== MBC API 호출: sType=$sType, date=$targetDateStr ===');

      final response = await http.get(
        Uri.parse('https://control.imbc.com/Schedule/Radio/Time?sType=$sType&broadDate=$targetDateStr'),
      ).timeout(const Duration(seconds: 10));

      debugPrint('=== MBC API statusCode: ${response.statusCode} ===');
      debugPrint('=== MBC API body 앞부분: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)} ===');

      final List<dynamic> data = [];
      if (response.statusCode == 200) {
        data.addAll(json.decode(response.body) as List<dynamic>);
      }
      debugPrint('=== MBC data.length: ${data.length} ===');
      if (data.isNotEmpty) {
        var filtered = data.where((s) {
          final isToday = s['IsToday'] as String? ?? 'N';
          final start = s['StartTime'] as String? ?? '';
          if (isToday == 'Y') return true;
          final startInt = int.tryParse(start) ?? 9999;
          return startInt < 600;
        }).toList();
        // 필터 결과가 비면(새벽 시간대처럼 새벽 프로그램 정보가 없는 경우) 전체 데이터 사용
        if (filtered.isEmpty) {
          filtered = List.from(data);
        }

        // 시간 순 정렬: 새벽(0000~0559)은 맨 뒤로
        filtered.sort((a, b) {
          final sa = int.tryParse(a['StartTime'] as String? ?? '0') ?? 0;
          final sb = int.tryParse(b['StartTime'] as String? ?? '0') ?? 0;
          final wa = sa < 600 ? sa + 2400 : sa;
          final wb = sb < 600 ? sb + 2400 : sb;
          return wa.compareTo(wb);
        });
        for (final s in filtered) {
          s['image'] = s['Photo'];
        }
        _scheduleListMap[stationName] = filtered.cast<Map<String, dynamic>>();
        final now = DateTime.now();
        final nowH = now.hour;
        final nowM = now.minute;
        final nowHHMM = nowH < 6
            ? '${(nowH + 24).toString().padLeft(2, '0')}${nowM.toString().padLeft(2, '0')}'
            : '${nowH.toString().padLeft(2, '0')}${nowM.toString().padLeft(2, '0')}';
        for (final s in data) {
          String start = s['StartTime']?.toString() ?? '';
          String end = s['EndTime']?.toString() ?? '';
          if (start.isEmpty || end.isEmpty) continue;
          // 새벽 방송 시간 보정
          final startInt = int.tryParse(start) ?? 0;
          if (startInt < 600) start = '${startInt + 2400}';
          final endInt = int.tryParse(end) ?? 0;
          final endAdj = endInt >= 2400 ? '$endInt' : (endInt < 600 ? '${endInt + 2400}' : end);
          if (nowHHMM.compareTo(start) >= 0 && nowHHMM.compareTo(endAdj) < 0) {
            final merged = Map<String, dynamic>.from(s);
            merged['image'] = s['Photo'];
            _currentProgramMap[stationName] = merged;
            _nowPlayingMap[stationName] = s['Title'] as String? ?? '';
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('MBC 편성표 로드 오류: $e');
    }
    _updateNotification(stationName);
    notifyListeners();
  }

  // SBS
  static const _sbsChannelTypes = {
    'SBS 파워FM': 'Power',
    'SBS 러브FM': 'Love',
  };

  Future<void> fetchBbsSchedule() async {
    const stationName = 'BBS 불교방송';
    _scheduleListMap.remove(stationName);
    _currentProgramMap.remove(stationName);
    _nowPlayingMap.remove(stationName);
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => host == 'm.bbsi.co.kr';
      final ioClient = IOClient(httpClient);

      const commonUA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';

      // 1단계: 메인 페이지 먼저 방문해서 쿠키 받기
      String cookieHeader = '';
      try {
        final mainResponse = await ioClient.get(
          Uri.parse('https://m.bbsi.co.kr/M/?ACT=RADIO_FM'),
          headers: {'User-Agent': commonUA},
        ).timeout(const Duration(seconds: 10));
        final setCookie = mainResponse.headers['set-cookie'];
        if (setCookie != null) {
          cookieHeader = setCookie.split(',').map((c) => c.split(';').first.trim()).join('; ');
        }
        debugPrint('BBS 쿠키 획득: $cookieHeader');
      } catch (e) {
        debugPrint('BBS 메인페이지 접속 오류: $e');
      }

      // 2단계: 쿠키 들고 편성표 요청
      final response = await ioClient.get(
        Uri.parse('https://m.bbsi.co.kr/M/ajaxSchedule.html?CODE=WWW&SchGubun=RADIO&SchDate=$dateStr'),
        headers: {
          'User-Agent': commonUA,
          'Referer': 'https://m.bbsi.co.kr/M/?ACT=RADIO_FM',
          'X-Requested-With': 'XMLHttpRequest',
          if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
        },
      ).timeout(const Duration(seconds: 10));
      ioClient.close();

      debugPrint('BBS statusCode: ${response.statusCode}, body length: ${response.body.length}');
      if (response.statusCode == 200) {
        final body = response.body;
        debugPrint('BBS body 앞부분: ${body.substring(0, body.length > 300 ? 300 : body.length)}');
        final blockRegex = RegExp(
          r'<div class="program( onairbox)?">(.*?)<!-- UNIT E -->|<div class="program( onairbox)?">(.*?)<!-- ONAIR E -->',
          dotAll: true,
        );
        final timeRegex = RegExp(r'<p>(\d{2}:\d{2})</p>');
        final titleRegex = RegExp(r'<strong>(.*?)</strong>');
        final onAirRegex = RegExp(r'ON AIR');
        final imgRegex = RegExp(r'<img src="(.*?)">');

        final matches = blockRegex.allMatches(body).toList();
        debugPrint('BBS 매칭된 방송 개수: ${matches.length}');
        final schedules = <Map<String, dynamic>>[];
        int? currentIdx;
        for (final m in matches) {
          final block = (m.group(2) ?? m.group(4) ?? '');
          final time = timeRegex.firstMatch(block)?.group(1) ?? '';
          final title = titleRegex.firstMatch(block)?.group(1)?.trim() ?? '';
          final image = imgRegex.firstMatch(block)?.group(1);
          final isOnAir = onAirRegex.hasMatch(block);
          if (time.isEmpty || title.isEmpty) continue;
          if (schedules.isEmpty) {
            debugPrint('BBS 블록 예시(이미지 태그 확인용): ${block.substring(0, block.length > 400 ? 400 : block.length)}');
            debugPrint('BBS 추출된 image 값: $image');
          }
          schedules.add({'start_time': time, 'title': title, 'image': image});
          if (isOnAir) currentIdx = schedules.length - 1;
        }
        _scheduleListMap[stationName] = schedules;
        if (currentIdx != null) {
          final cur = schedules[currentIdx];
          final end = currentIdx + 1 < schedules.length
              ? schedules[currentIdx + 1]['start_time'] as String
              : '';
          _currentProgramMap[stationName] = {
            'program_title': cur['title'],
            'start_time': cur['start_time'],
            'end_time': end,
            'is_rerun': false,
            'image': cur['image'],
          };
          _nowPlayingMap[stationName] = cur['title'] as String? ?? '';
        }
      }
    } catch (e) {
      debugPrint('BBS 편성표 로드 오류: $e');
    }
    _updateNotification(stationName);
    notifyListeners();
  }

  void _listenConnectivity() {
    List<ConnectivityResult> lastResults = [];
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final isNone = results.isEmpty || (results.contains(ConnectivityResult.none) && results.length == 1);
      final wasNone = lastResults.isEmpty || (lastResults.contains(ConnectivityResult.none) && lastResults.length == 1);
      final hadWifi = lastResults.contains(ConnectivityResult.wifi);
      final hasWifi = results.contains(ConnectivityResult.wifi);
      lastResults = List.from(results);

      if (_currentStation == null || isNone || _userPaused) return;
      if (_playerState == RadioPlayerState.idle) return;

      // 끊겼다 다시 연결됨 · 또는 와이파이↔LTE가 바뀜 → 소리가 나오는 중이어도 새 네트워크로 다시 연결
      // (예전엔 '소리 안 날 때만' · '불러오는 중이면 무시'라서, 옛 네트워크에 매달려 30초 넘게 뱅뱅 돌았음)
      if (wasNone || hadWifi != hasWifi) {
        debugPrint('네트워크 바뀜 감지 (와이파이 $hadWifi → $hasWifi) - 라디오 다시 연결');
        await Future.delayed(const Duration(milliseconds: 1500)); // 새 네트워크를 실제로 쓸 수 있을 때까지 잠깐
        final cur = _currentStation;
        if (cur == null || _userPaused || _playerState == RadioPlayerState.idle) return;
        _stallRetries = 0;
        await playStation(cur, force: true);
      }
    });
  }

  // dispose는 아래 기존 것에 합칩니다

  /// 위젯 둘째 줄에 쓸 지금 프로그램 (방송 이름 → "프로그램 9:00~11:00")
  final Map<String, String> _widgetProgram = {};

  /// 차 화면 재생 화면 둘째 줄: "지금 프로그램 · 다음 방송 12:00 다음 프로그램"
  /// 차에 연결돼 있을 때만 (아니면 null → 지금 글자 그대로) — 앱 재생 화면 '다음 방송'과 같은 규칙
  /// (편성표에서 지금 방송 다음 칸 · 오늘 마지막이면 첫 칸)
  String? _carLine(String stationName, String nowTitle, String nowStart) {
    if (!CarBrowse.inCarRecently || nowTitle.isEmpty) return null;
    final list = _scheduleListMap[stationName];
    if (list == null || list.length < 2) return null;
    String titleOf(Map<String, dynamic> p) => (p['program_title'] ?? p['Title'] ?? p['title'] ?? '').toString();
    String startOf(Map<String, dynamic> p) {
      for (final k in ['program_planned_start_time', 'StartTime', 'start_time']) {
        final v = p[k]?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    var i = nowStart.isEmpty ? -1 : list.indexWhere((p) => titleOf(p) == nowTitle && startOf(p) == nowStart);
    if (i < 0) i = list.indexWhere((p) => titleOf(p) == nowTitle);
    if (i < 0) return null;
    final next = list[(i + 1) % list.length];
    final t = titleOf(next);
    if (t.isEmpty || t == nowTitle) return null;
    var s = startOf(next);
    if (!s.contains(':')) {
      if (s.length >= 4) {
        var h = int.tryParse(s.substring(0, 2)) ?? 0;
        if (h >= 24) h -= 24;
        s = '${h.toString().padLeft(2, '0')}:${s.substring(2, 4)}';
      } else {
        s = '';
      }
    }
    return '$nowTitle\n[${tr.radioNextProgram}] ${s.isEmpty ? '' : '$s · '}$t'; // 다음 방송은 줄을 바꿔서, [다음 방송] 칸처럼 (지금 방송과 안 섞이게)
  }

  /// 편성표 시간("11050000" · "1100" · "11:00", 24시 넘는 것도) → 지금 프로그램의 (시작, 끝) — 지금이 그 안이 아니면 null
  (DateTime, DateTime)? _programSpan(String start, String end) {
    (int, int)? hm(String t) {
      final s = t.trim();
      if (s.contains(':')) {
        final p = s.split(':');
        final h = int.tryParse(p[0].replaceAll(RegExp(r'[^0-9]'), ''));
        final m = int.tryParse(p.length > 1 ? p[1].replaceAll(RegExp(r'[^0-9]'), '') : '');
        return (h == null || m == null) ? null : (h, m);
      }
      if (s.length < 4) return null;
      final h = int.tryParse(s.substring(0, 2));
      final m = int.tryParse(s.substring(2, 4));
      return (h == null || m == null) ? null : (h, m);
    }

    final a = hm(start), b = hm(end);
    if (a == null || b == null) return null;
    final now = DateTime.now();
    var st = DateTime(now.year, now.month, now.day, a.$1, a.$2);
    if (st.isAfter(now)) st = st.subtract(const Duration(days: 1)); // 어제 시작한 밤 프로그램
    var en = DateTime(st.year, st.month, st.day, b.$1, b.$2);
    while (!en.isAfter(st)) {
      en = en.add(const Duration(days: 1)); // 자정 넘어 끝나는 프로그램
    }
    if (now.isBefore(st) || !now.isBefore(en) || en.difference(st) > const Duration(hours: 12)) return null;
    return (st, en);
  }

  void _updateNotification(String stationName) {
    if (_currentStation?.name != stationName) return;
    final program = _currentProgramMap[stationName];
    debugPrint('=== _updateNotification: $stationName / program: $program ===');
    if (program == null) return;
    final programTitle = program['program_title'] as String?
        ?? program['Title'] as String?
        ?? program['title'] as String?
        ?? _nowPlayingMap[stationName]
        ?? '';
    if (programTitle.isEmpty) return;
    // 시간 추출
    final start = program['program_planned_start_time'] as String?
        ?? program['StartTime'] as String?
        ?? program['start_time'] as String?
        ?? '';
    final end = program['program_planned_end_time'] as String?
        ?? program['EndTime'] as String?
        ?? program['end_time'] as String?
        ?? '';
    String artist = programTitle;
    if (start.isNotEmpty && end.isNotEmpty) {
      // KBS 시간 포맷 변환 (20000000 → 20:00)
      String fmtTime(String t) {
        if (t.length >= 6) {
          int h = int.tryParse(t.substring(0, 2)) ?? 0;
          final m = t.substring(2, 4);
          if (h >= 24) h -= 24;
          return '$h:$m';
        }
        if (t.contains(':')) return t;
        if (t.length == 4) {
          int h = int.tryParse(t.substring(0, 2)) ?? 0;
          final m = t.substring(2, 4);
          if (h >= 24) h -= 24;
          return '$h:$m';
        }
        return t;
      }
      artist = '$programTitle ${fmtTime(start)}~${fmtTime(end)}';
    }
    // 시간 줄: 지금 프로그램 시작~끝 (편성표 시간 그대로)
    final span = _programSpan(start, end);
    _simpleHandler?.setRadioProgramTime(stationName, span?.$1, span?.$2);
    _simpleHandler?.setRadioMediaItem(
      title: stationName,
      artist: _carLine(stationName, programTitle, start) ?? artist, // 차에선 다음 방송까지
      url: _currentStation?.streamUrl ?? '',
    );
    // 위젯에도 지금 하는 프로그램 (늦게 도착해도 바로 바뀌게)
    _widgetProgram[stationName] = artist;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('updateWidget', {
      'title': stationName,
      'artist': artist,
      'isPlaying': isPlaying,
      'schedule': '',
    }).catchError((Object _) => null);
  }

  Future<void> _updateWidget(String title, String artist, bool isPlaying) async {
    try {
      const platform = MethodChannel('kr.ssing.catsong/media');
      final program = _currentProgramMap[title];
      String schedule = '';
      String programTitle = '';
      if (program != null) {
        programTitle = program['program_title'] as String? ?? '';
        final start = program['start_time'] as String? ?? '';
        final end = program['end_time'] as String? ?? '';
        if (programTitle.isNotEmpty) {
          schedule = start.isNotEmpty ? '$programTitle $start~$end' : programTitle;
        }
      }
      await platform.invokeMethod('updateWidget', {
        'title': title,
        // 지금 하는 프로그램이 있으면 둘째 줄에 (누가 방송하는지), 없으면 방송 설명
        'artist': schedule.isNotEmpty ? schedule : (_widgetProgram[title] ?? artist),
        'isPlaying': isPlaying,
        'schedule': '',
      });
      // 알림바(미디어 컨트롤)도 업데이트
      if (programTitle.isNotEmpty) {
        _simpleHandler?.setRadioMediaItem(
          title: title,
          artist: _carLine(title, programTitle, '') ?? programTitle, // 차에선 다음 방송까지
          url: '',
        );
      }
    } catch (e) {
      debugPrint('위젯 업데이트 오류: $e');
    }
  }

  Future<void> fetchKfnSchedule() async {
    const stationName = '국방FM';
    debugPrint('=== fetchKfnSchedule 호출됨 ===');
    try {
      final response = await http.post(
        Uri.parse('https://radio.dema.mil.kr/web/api/v1/media/fm/nowProgram/ajaxList.do'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          'Referer': 'https://radio.dema.mil.kr/web/radio/main.do',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sort_type': 'TIME',
          'program_type': '',
          'select_type': '',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('=== KFN API 응답: ${response.body} ===');
        final map = data['map'];
        if (map == null) {
          debugPrint('=== KFN map null ===');
          return;
        }

        // 현재 방송 중인 프로그램
        final current = map['timeTableExt'];
        final title = current['fm_program_title'] as String? ?? '';
        final start = current['fm_program_time'] as String? ?? '';
        final end = current['fm_program_end_time'] as String? ?? '';

        if (title.isNotEmpty) {
          // 시간 포맷 변환 (1605 → 16:05)
          String fmt(String t) {
            if (t.length < 4) return t;
            return '${t.substring(0, 2)}:${t.substring(2, 4)}';
          }
          _currentProgramMap[stationName] = {
            'program_title': title,
            'start_time': fmt(start),
            'end_time': fmt(end),
            'is_rerun': false,
          };
          _nowPlayingMap[stationName] = title;
        }

        // 전체 편성표
        final list = map['fmNowHomeList'] as List<dynamic>? ?? [];
        final schedules = <Map<String, dynamic>>[];
        for (final item in list) {
          final name = item['homepage_nm'] as String? ?? '';
          final time = item['regular_brodcasting'] as String? ?? '';
          if (name.isEmpty || time.isEmpty || time.trim().isEmpty) continue;

          // "(월~일) 16:05~18:00" 파싱
          final match = RegExp(r'(\d{2}:\d{2})~(\d{2}:\d{2})').firstMatch(time);
          if (match != null) {
            final icon = item['movie_icon'] as String? ?? '';
            schedules.add({
              'program_title': name,
              'start_time': match.group(1)!,
              'end_time': match.group(2)!,
              // 프로그램 사진 (예: /data/fm_thumb/2025/276/276_1.jpg)
              if (icon.isNotEmpty) 'image': icon.startsWith('http') ? icon : 'https://radio.dema.mil.kr$icon',
            });
          }
        }
        // 시간순 정렬
        schedules.sort((a, b) {
          final sa = a['start_time'] as String;
          final sb = b['start_time'] as String;
          return sa.compareTo(sb);
        });
        _scheduleListMap[stationName] = schedules;
        // 지금 방송에도 같은 프로그램 사진
        final curMap = _currentProgramMap[stationName];
        if (curMap != null) {
          for (final item in list) {
            final icon = item['movie_icon'] as String? ?? '';
            if (item['homepage_nm'] == curMap['program_title'] && icon.isNotEmpty) {
              curMap['image'] = icon.startsWith('http') ? icon : 'https://radio.dema.mil.kr$icon';
              break;
            }
          }
        }
        notifyListeners();
        if (_currentStation?.name == stationName) {
          _updateWidget(stationName, _currentStation == null ? '' : _mediaSubtitle(_currentStation!), true);
        }
      }
    } catch (e) {
      debugPrint('국방FM 편성표 로드 오류: $e');
    }
  }

  Future<void> fetchEbsFmSchedule() async {
    const stationName = 'EBS FM';
    try {
      final response = await http.get(
        Uri.parse('https://www.ebs.co.kr/onair/scheduleNew.json?channelCodeString=RADIO&mode=newlist'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final now = data['nowProgram'];
        if (now != null) {
          final title = now['title'] as String? ?? '';
          final start = now['start'] as String? ?? '';
          final end = now['end'] as String? ?? '';
          if (title.isNotEmpty) {
            _currentProgramMap[stationName] = {
              'program_title': title,
              'start_time': start,
              'end_time': end,
              // 프로그램 사진 (EBS는 앞부분 빠진 주소로 줌)
              if ((now['thumbnail7'] ?? '').toString().isNotEmpty)
                'image': 'https://static.ebs.co.kr/images${now['thumbnail7']}',
            };
            _nowPlayingMap[stationName] = title;
          }
        }
        final list = data['program'] as List<dynamic>? ?? [];
        final schedules = <Map<String, dynamic>>[];
        final seenTimes = <String>{};
        for (final item in list) {
          final title = item['title'] as String? ?? '';
          final start = item['start'] as String? ?? '';
          final end = item['end'] as String? ?? '';
          if (title.isEmpty || title == '라디오 캠페인') continue;
          if (seenTimes.contains(start)) continue;
          seenTimes.add(start);
          schedules.add({
            'program_title': title,
            'start_time': start,
            'end_time': end,
          });
        }
        _scheduleListMap[stationName] = schedules;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('EBS FM 편성표 로드 오류: $e');
    }
  }

  Future<void> fetchEbsBandiSchedule() async {
    const stationName = 'EBS 반디';
    try {
      final response = await http.get(
        Uri.parse('https://www.ebs.co.kr/onair/scheduleNew.json?channelCodeString=IRADIO&mode=newlist'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 현재 방송 중인 프로그램
        final now = data['nowProgram'];
        if (now != null) {
          final title = now['title'] as String? ?? '';
          final start = now['start'] as String? ?? '';
          final end = now['end'] as String? ?? '';
          if (title.isNotEmpty) {
            _currentProgramMap[stationName] = {
              'program_title': title,
              'start_time': start,
              'end_time': end,
            };
            _nowPlayingMap[stationName] = title;
          }
        }

        // 전체 편성표 (라디오 캠페인 제외, 중복 시간 제거)
        final list = data['program'] as List<dynamic>? ?? [];
        final schedules = <Map<String, dynamic>>[];
        final seenTimes = <String>{};
        for (final item in list) {
          final title = item['title'] as String? ?? '';
          final start = item['start'] as String? ?? '';
          final end = item['end'] as String? ?? '';
          if (title.isEmpty || title == '라디오 캠페인') continue;
          if (seenTimes.contains(start)) continue;
          seenTimes.add(start);
          schedules.add({
            'program_title': title,
            'start_time': start,
            'end_time': end,
            if ((item['thumbnail7'] ?? '').toString().isNotEmpty)
              'image': 'https://static.ebs.co.kr/images${item['thumbnail7']}',
          });
        }
        _scheduleListMap[stationName] = schedules;
        // 지금 방송에 사진이 없으면: 편성표 목록에서 같은 제목(없으면 지금 시간)의 사진
        final curMap = _currentProgramMap[stationName];
        if (curMap != null && curMap['image'] == null) {
          final n = DateTime.now();
          final nowHM = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
          for (final s in schedules) {
            final sameTitle = s['program_title'] == curMap['program_title'];
            final st = s['start_time'] as String;
            final en = s['end_time'] as String;
            final nowIn = st.compareTo(nowHM) <= 0 && nowHM.compareTo(en) < 0;
            if (s['image'] != null && (sameTitle || nowIn)) {
              curMap['image'] = s['image'];
              break;
            }
          }
        }
        debugPrint('[EBS 반디 사진] 지금: ${curMap?['program_title']} → ${curMap?['image']}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('EBS 반디 편성표 로드 오류: $e');
    }
  }

  Future<void> fetchJsonSchedule(String stationName) async {
    debugPrint('=== fetchJsonSchedule 호출: $stationName ===');
    debugPrint('=== hasSchedule: ${_scheduleService.hasSchedule(stationName)} ===');
    if (!_scheduleService.hasSchedule(stationName)) return;
    final program = _scheduleService.getCurrentProgram(stationName);
    debugPrint('=== getCurrentProgram: $program ===');
    if (program != null) {
      _currentProgramMap[stationName] = {
        'program_title': program['title'],
        'start_time': program['start'],
        'end_time': program['end'],
        'is_rerun': false,
        'image': program['image'], // 편성표 파일에 사진이 있으면 (CBS)
      };
      _nowPlayingMap[stationName] = program['title'] as String? ?? '';
    }
    _scheduleListMap[stationName] =
        _scheduleService.getScheduleList(stationName).map((p) => {
          'program_title': p['title'],
          'start_time': p['start'],
          'end_time': p['end'],
          'image': p['image'],
        }).toList();
    notifyListeners();
    if (_currentStation?.name == stationName) {
      _updateWidget(stationName, _currentStation == null ? '' : _mediaSubtitle(_currentStation!), true);
    }
  }

  Future<void> fetchSbsSchedule(String stationName) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cacheKey = '${stationName}_$today';
    if (_scheduleListMap.containsKey(cacheKey) && _scheduleListMap[cacheKey]!.isNotEmpty) return;
    final type = _sbsChannelTypes[stationName];
    if (type == null) return;

    _scheduleListMap.remove(stationName);
    _currentProgramMap.remove(stationName);
    _nowPlayingMap.remove(stationName);

    try {
      final now = DateTime.now();
      // 새벽 0~5시는 어제 날짜 데이터에 새벽 방송 포함
      final targetDay = now.hour < 5
          ? now.subtract(const Duration(days: 1))
          : now;
      final uri = Uri.parse(
        'https://static.cloud.sbs.co.kr/schedule/${targetDay.year}/${targetDay.month}/${targetDay.day}/$type.json',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      final List<dynamic> data = [];
      if (response.statusCode == 200) {
        data.addAll(json.decode(response.body) as List<dynamic>);
      }
      if (data.isNotEmpty) {
        for (final s in data) {
          if (s is Map<String, dynamic>) {
            s['image'] = s['program_image'];
          }
        }
        _scheduleListMap[stationName] = data.cast<Map<String, dynamic>>();
        // 현재 방송 찾기 (25:00 형식 처리)
        final nowH = now.hour;
        final nowM = now.minute;
        // 새벽이면 24 더해서 비교 (예: 01:30 → 25:30)
        final nowTotal = nowH < 5 ? (nowH + 24) * 60 + nowM : nowH * 60 + nowM;
        for (final s in data) {
          final start = s['start_time'] as String? ?? '';
          final end = s['end_time'] as String? ?? '';
          if (start.isEmpty || end.isEmpty) continue;
          final startParts = start.split(':');
          final endParts = end.split(':');
          final startTotal = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endTotal = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          if (nowTotal >= startTotal && nowTotal < endTotal) {
            final merged = Map<String, dynamic>.from(s);
            merged['image'] = s['program_image'];
            _currentProgramMap[stationName] = merged;
            _nowPlayingMap[stationName] = s['title'] as String? ?? '';
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('SBS 편성표 로드 오류: $e');
    }
    _updateNotification(stationName);
    notifyListeners();
  }

  void _updateCurrentPrograms() {
    final now = DateTime.now();
    final nowTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}0000';
    final nowHHMM = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final nowHHMMno = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    bool changed = false;

    // MBC
    for (final stationName in _mbcChannelTypes.keys) {
      if (!_scheduleListMap.containsKey(stationName)) continue;
      final schedules = _scheduleListMap[stationName] ?? [];
      for (final s in schedules) {
        final start = s['StartTime'] as String? ?? '';
        final end = s['EndTime'] as String? ?? '';
        final endAdj = end == '2400' ? '0000' : end;
        if (nowHHMMno.compareTo(start) >= 0 &&
            (end == '2400' || nowHHMMno.compareTo(endAdj) < 0)) {
          final newTitle = s['Title'] as String? ?? '';
          if (_nowPlayingMap[stationName] != newTitle) {
            _currentProgramMap[stationName] = Map<String, dynamic>.from(s);
            _nowPlayingMap[stationName] = newTitle;
            changed = true;
          }
          break;
        }
      }
    }

    // SBS
    for (final stationName in _sbsChannelTypes.keys) {
      if (!_scheduleListMap.containsKey(stationName)) continue;
      final schedules = _scheduleListMap[stationName] ?? [];
      for (final s in schedules) {
        final start = s['start_time'] as String? ?? '';
        var end = s['end_time'] as String? ?? '';
        if (end.isNotEmpty && int.parse(end.split(':')[0]) >= 24) end = '23:59';
        if (nowHHMM.compareTo(start) >= 0 && nowHHMM.compareTo(end) < 0) {
          final newTitle = s['title'] as String? ?? '';
          if (_nowPlayingMap[stationName] != newTitle) {
            _currentProgramMap[stationName] = Map<String, dynamic>.from(s);
            _nowPlayingMap[stationName] = newTitle;
            changed = true;
          }
          break;
        }
      }
    }

    // KBS
    final nowHour2 = now.hour;
    final nowMin2 = now.minute;
    final nowTimeInt2 = nowHour2 < 5
        ? (24 + nowHour2) * 1000000 + nowMin2 * 10000
        : nowHour2 * 1000000 + nowMin2 * 10000;
    for (final stationName in _scheduleListMap.keys) {
      if (_mbcChannelTypes.containsKey(stationName)) continue;
      if (_sbsChannelTypes.containsKey(stationName)) continue;
      final currentSchedules = _scheduleListMap[stationName] ?? [];
      for (int i = 0; i < currentSchedules.length; i++) {
        final s = currentSchedules[i];
        final start = s['program_planned_start_time'] as String? ?? '';
        final end = s['program_planned_end_time'] as String? ?? '';
        final startInt = int.tryParse(start) ?? 0;
        final endInt = int.tryParse(end) ?? 0;
        if (nowTimeInt2 >= startInt && nowTimeInt2 < endInt) {
          final newTitle = s['program_title'] as String? ?? '';
          if (_nowPlayingMap[stationName] != newTitle) {
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
            _nowPlayingMap[stationName] = newTitle;
            changed = true;
          }
          break;
        }
      }
    }

    // 국방FM · EBS: 받아 둔 편성표(시간 "07:00" 모양)로 '지금 프로그램' 넘기기
    for (final stationName in const ['국방FM', 'EBS 반디', 'EBS FM']) {
      final list = _scheduleListMap[stationName];
      if (list == null || list.isEmpty) continue;
      for (final s in list) {
        final st = s['start_time'] as String? ?? '';
        final en = s['end_time'] as String? ?? '';
        if (st.length < 5 || en.length < 5) continue;
        final inRange = en.compareTo(st) > 0
            ? (st.compareTo(nowHHMM) <= 0 && nowHHMM.compareTo(en) < 0)
            : (st.compareTo(nowHHMM) <= 0 || nowHHMM.compareTo(en) < 0); // 자정 넘는 프로그램
        if (!inRange) continue;
        final title = s['program_title'] as String? ?? '';
        if (title.isNotEmpty && _nowPlayingMap[stationName] != title) {
          _currentProgramMap[stationName] = Map<String, dynamic>.from(s);
          _nowPlayingMap[stationName] = title;
          changed = true;
        }
        break;
      }
    }

    // 편성표 파일(schedule.json) 방송국: 듣는 동안 시간이 지나면 '지금 프로그램'도 다음 것으로
    for (final stationName in _scheduleService.stationNames) {
      if (!_scheduleListMap.containsKey(stationName)) continue;
      final p = _scheduleService.getCurrentProgram(stationName);
      if (p != null && _nowPlayingMap[stationName] != p['title']) {
        fetchJsonSchedule(stationName); // 지금 프로그램 · 사진 · 오늘 편성표 다시 맞추기
      }
    }

    if (changed) notifyListeners();
  }

  Timer? _scheduleRefreshTimer;
  Timer? _scheduleDisplayTimer;

  void _startScheduleRefreshTimer() {
    _scheduleRefreshTimer?.cancel();
    _scheduleRefreshTimer = Timer.periodic(
      const Duration(minutes: 10),
          (_) {
            for (final name in _kbsChannelCodes.keys) {
              if (_scheduleListMap.containsKey(name)) fetchSchedule(name);
            }
        for (final name in _mbcChannelTypes.keys) {
          if (_scheduleListMap.containsKey(name)) fetchMbcSchedule(name);
        }
        for (final name in _sbsChannelTypes.keys) {
          if (_scheduleListMap.containsKey(name)) fetchSbsSchedule(name);
        }
      },
    );
    _scheduleDisplayTimer?.cancel();
    // 프로그램은 매 분 0초에 바뀌니까: 다음 분 0초(+1초 여유)에 맞춰 시작해서, 그 뒤로 매 분 같은 때 확인
    final now = DateTime.now();
    final toNextMinute = Duration(seconds: 61 - now.second, milliseconds: -now.millisecond);
    _scheduleDisplayTimer = Timer(toNextMinute, () {
      _updateCurrentPrograms();
      _scheduleDisplayTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _updateCurrentPrograms(),
      );
    });
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
        final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _broadcasterStations = data
              .map((j) => RadioStation.fromJson(j as Map<String, dynamic>))
              .where((s) => s.streamUrl.isNotEmpty && !_isBlocked(s))
              .toList();
          _mergeFavoriteFlags(_broadcasterStations);
          notifyListeners();
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
        final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _searchResults = data
              .map((j) => RadioStation.fromJson(j as Map<String, dynamic>))
              .where((s) => s.streamUrl.isNotEmpty && !_isBlocked(s))
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
    final idx = _favorites.indexWhere((s) => s.stationUuid == station.stationUuid);
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
    _recentlyListened.removeWhere((s) => s.stationUuid == station.stationUuid);
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
    sleepTick.value = duration;
    HeadsetResume.saveSleepEnd('r', DateTime.now().add(duration)); // 위젯에 남은 시간
    _sleepTimer = Timer(duration, () async {
      await _player.stop();
      if (_sleepFading) {
        _sleepFading = false;
        await setAlarmVolume(1.0);
      }
      await WakelockPlus.disable().catchError((Object _) {});
      _isActuallyPlaying = false;
      _setPlayerState(RadioPlayerState.idle);
      _updateForeground(false);
      cancelSleepTimer();
    });
    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sleepRemaining == null || _sleepRemaining!.inSeconds <= 0) {
        cancelSleepTimer();
        return;
      }
      _sleepRemaining = _sleepRemaining! - const Duration(seconds: 1);
      // 끝나기 1분 전부터 천천히 작게 (뚝 끊겨서 잠이 깨지 않게)
      final left = _sleepRemaining!.inSeconds;
      if (left < 60) {
        _sleepFading = true;
        setAlarmVolume(left / 60);
      }
      sleepTick.value = _sleepRemaining; // 남은 시간 글자만 바뀜
      if (left % 60 == 59) notifyListeners(); // 'N분' 표시는 분이 바뀔 때만
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    if (_sleepFading) {
      _sleepFading = false;
      setAlarmVolume(1.0);
    }
    _scheduleCheckTimer?.cancel();
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    if (_sleepRemaining != null) HeadsetResume.saveSleepEnd('r', null); // 위젯 남은 시간 지우기
    _sleepTimer = null;
    _sleepCountdown = null;
    _sleepRemaining = null;
    sleepTick.value = null;
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

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final favJson = prefs.getStringList(_keyFavorites) ?? [];
    _favorites = favJson.map((s) {
      try {
        return RadioStation.fromJson(json.decode(s) as Map<String, dynamic>)..isFavorite = true;
      } catch (_) {
        return null;
      }
    }).whereType<RadioStation>().toList();

    final recentJson = prefs.getStringList(_keyRecent) ?? [];
    _recentlyListened = recentJson.map((s) {
      try {
        return RadioStation.fromJson(json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<RadioStation>().toList();
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    _recentlyListened.removeWhere((s) => s.lastListened != null && s.lastListened!.isBefore(oneMonthAgo));

    final scheduleJson = prefs.getStringList(_keySchedules) ?? [];
    _schedules = scheduleJson.map((s) {
      try {
        return ScheduledStation.fromJson(json.decode(s) as Map<String, dynamic>);
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
    await prefs.setStringList(_keyFavorites, _favorites.map((s) => json.encode(s.toJson())).toList());
    await prefs.setStringList(_keyRecent, _recentlyListened.map((s) => json.encode(s.toJson())).toList());
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySchedules, _schedules.map((s) => json.encode(s.toJson())).toList());
  }

  void _setPlayerState(RadioPlayerState state) {
    _playerState = state;
    if (state == RadioPlayerState.error) {
      _onStationFailed();
      // 차 화면 · 알림창에도 "재생하지 못했어요" (차에서는 앱 화면을 볼 수 없어서)
      _simpleHandler?.setRadioError((_errorMessage ?? tr.radioPlaybackFailed).replaceAll('\n', ' '));
    } else if (state == RadioPlayerState.loading) {
      _similar = null;
    }
    notifyListeners();
  }

  // ── 안 나오는 방송 → 비슷한 방송 추천 (해외 방송만) ──
  final Set<String> _failedToday = {}; // 오늘 안 나왔던 방송은 추천 안 함
  String _failedDay = '';
  RadioStation? _similar;
  RadioStation? get similarStation => _playerState == RadioPlayerState.error ? _similar : null;

  static Set<String> _tagSet(RadioStation s) => (s.tags ?? '')
      .toLowerCase()
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet();

  void _onStationFailed() {
    final cur = _currentStation;
    _similar = null;
    if (cur == null) return;
    final now = DateTime.now();
    final day = '${now.year}-${now.month}-${now.day}';
    if (day != _failedDay) {
      _failedDay = day;
      _failedToday.clear();
    }
    _failedToday.add(cur.stationUuid);
    final code = cur.countryCode ?? '';
    if (code.isEmpty || code.toUpperCase() == 'KR') return;
    // 같은 나라 목록 (인기순) 에서 장르가 가장 많이 겹치는 방송, 같으면 더 인기 있는 쪽
    final pool = (_countryCode == code && _countryStations.isNotEmpty) ? _countryStations : _currentQueue;
    final tags = _tagSet(cur);
    var best = -1;
    for (final s in pool.take(400)) {
      if (s.stationUuid == cur.stationUuid || _failedToday.contains(s.stationUuid)) continue;
      if ((s.countryCode ?? code) != code) continue;
      final score = _tagSet(s).intersection(tags).length;
      if (score > best) {
        best = score;
        _similar = s;
      }
    }
  }

  /// '비슷한 방송 듣기' 누르면
  Future<void> playSimilar() async {
    final s = similarStation;
    if (s == null) return;
    final i = _currentQueue.indexWhere((x) => x.stationUuid == s.stationUuid);
    if (i >= 0) _currentQueueIndex = i;
    await playStation(s);
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
    _connectivitySubscription?.cancel();
    _streamTitleTimer?.cancel();
    _player.dispose();
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _scheduleRefreshTimer?.cancel();
    _scheduleDisplayTimer?.cancel();
    WakelockPlus.disable().catchError((Object _) {});
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
    final period = time.period == DayPeriod.am ? tr.am : tr.pm;
    return tr.timeAmPm(period, '$h:$m');
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