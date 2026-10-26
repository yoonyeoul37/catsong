import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/nature_overlay.dart';
import '../services/sound_effects.dart';
import '../services/cast_service.dart';
import '../services/loudness.dart';
import '../services/headset_resume.dart';
import '../services/car_browse.dart';
import '../services/open_audio.dart';
import 'package:rxdart/rxdart.dart' show ValueStream;
import '../utils/no_album_helper.dart';
import '../utils/widget_go.dart';
import '../l10n/locale_holder.dart';
import '../utils/nature_sound_catalog.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);
  AudioHandler? _audioHandler;
  Function(Song)? onSongPlayed;
  Function(Song)? onSongChanged;
  VoidCallback? _onStopRadio;
  static const _channel = MethodChannel('kr.ssing.catsong/media');

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffled = false;
  double _playbackSpeed = 1.0;
  LoopMode _loopMode = LoopMode.off;
  Timer? _positionTimer;
  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;
  DateTime? _sleepTimerEnd;

  Song? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
  // TV로 보내는 중이면 TV 상태를 따라감 (재생 버튼·미니플레이어 모양)
  bool get isPlaying => CastService.instance.isConnected ? CastService.instance.tvPlaying : _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffled => _isShuffled;
  double get playbackSpeed => _playbackSpeed;
  LoopMode get loopMode => _loopMode;
  bool get hasPrevious => _currentIndex > 0;
  bool get hasNext => _currentIndex < _queue.length - 1;
  AudioPlayer get player => _player;
  Duration? get sleepTimerDuration => _sleepTimerDuration;
  DateTime? get sleepTimerEnd => _sleepTimerEnd;
  bool get isSleepTimerActive => _sleepTimer != null;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  PlayerProvider() {
    _initStreams();
    _initWidgetChannel();
    _loadLoopMode();
    NatureOverlay.instance.attach(this); // 음악 + 자연소리 섞기
    SoundEffects.instance.attach(this); // 이퀄라이저 · 울림 (저장된 값 자동 적용)
    // TV: TV 상태가 바뀌면 화면도 같이 바뀌고, TV에서 곡이 끝나면 다음 곡
    CastService.instance.addListener(notifyListeners);
    CastService.instance.onTrackEnded = () => playNext();
    Loudness.load(); // 곡마다 소리 크기 (기억해둔 것)
    Loudness.enabled.addListener(() {
      final s = currentSong;
      if (s != null) _applyLoudness(s);
    });
  }

  // ───── 곡마다 소리 크기 맞추기 ─────
  double _normGain = 1.0; // 이 곡을 얼마나 줄일지 (1.0 = 그대로)
  double get normGain => _normGain;

  /// 알람이 소리 크기를 쥐고 있는 동안 true (그동안 맞추기 안 함)
  bool volumeLocked = false;

  void _setNorm(double g) {
    _normGain = g;
    if (!volumeLocked && _sleepFade == null) _player.setVolume(g);
  }

  /// 잰 적 있으면 바로 맞추고, 없으면 재서 곡 앞부분일 때 맞추기 + 다음 곡 미리 재기
  void _applyLoudness(Song song) {
    final uri = song.uri;
    if (uri == null) return;
    if (!Loudness.enabled.value) {
      _setNorm(1.0);
      return;
    }
    final db = Loudness.cached(uri);
    if (db != null) {
      _setNorm(Loudness.gainFor(db));
    } else {
      _setNorm(1.0);
      Loudness.measure(uri).then((d) {
        if (d == null || currentSong?.uri != uri) return;
        // 곡 중간에 갑자기 바뀌면 어색해서, 앞부분일 때만 (다음부터는 처음부터 맞춰짐)
        if (_player.position < const Duration(seconds: 4)) _setNorm(Loudness.gainFor(d));
      });
    }
    if (hasNext) {
      final next = _queue[_currentIndex + 1].uri;
      if (next != null) Loudness.measure(next);
    }
  }

  Future<void> _loadLoopMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('loop_mode') ?? 0;
    _loopMode = LoopMode.values[saved];
    notifyListeners();
    _saveWidgetModes(redraw: false);
  }

  /// 위젯이 직접 읽는 반복·섞기 값 저장 (+ 위젯 다시 그리기)
  static VoidCallback? widgetResend; // 가사 줄까지 다시 보내기 (lyrics_provider가 채움)
  Future<void> _saveWidgetModes({bool redraw = true}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('w_loop', _loopMode == LoopMode.one ? 1 : _loopMode == LoopMode.all ? 2 : 0);
      await p.setBool('w_shuffle', _isShuffled);
    } catch (_) {}
    if (!redraw || currentSong == null) return;
    _updateWidgetPlayState(_isPlaying);
    widgetResend?.call();
  }

  Future<void> _saveLoopMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('loop_mode', _loopMode.index);
  }

  // 라디오도 같은 통로로 신호를 받아서, 받는 곳을 하나로 합침 (둘이 따로 받으면 하나가 묻힘)
  static Future<void> Function(MethodCall call)? extraHandler;
  static VoidCallback? onMusicChanged; // 폰에 음악 파일이 생기거나 지워짐 → 새 곡 찾기 (main.dart가 채움)

  bool _pausedByFocus = false; // 다른 소리(전화 등) 때문에 멈췄는지

  void _initWidgetChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'widgetPlayPause':
          HeadsetResume.widgetPlay(); // 안 틀었으면 마지막에 듣던 것 (기다리지 않고 바로 대답)
          break;
        case 'widgetNext':
          await playNext();
          break;
        case 'widgetPrev':
          await playPrevious();
          break;
        case 'onHeadsetConnected':
        case 'onHeadsetResume':
          await HeadsetResume.onCall(call.method); // 이어폰 연결하면 이어서 듣기
          break;
        case 'onAudioFocusLost':
          // 방금 곡을 틀었으면 무시 (라디오가 잡고 있던 소리 주도권이 넘어오면서 오는 신호라서)
          if (_isPlaying && DateTime.now().difference(_startedAt).inSeconds >= 2) {
            await _player.pause();
            _pausedByFocus = true;
          }
          break;
        case 'widgetPlayKind':
          HeadsetResume.widgetPlayKind(call.arguments as String); // 위젯 아래 버튼 (바로 대답)
          break;
        case 'widgetRepeat':
          toggleLoopMode(); // 위젯: 반복 안 함 → 한 곡 → 전체
          break;
        case 'widgetShuffle':
          toggleShuffle(); // 위젯: 섞기 켜기·끄기
          break;
        case 'widgetSleep':
          HeadsetResume.widgetSleep(call.arguments as int? ?? 0); // 위젯 ⋮ → 수면 타이머 (0이면 끄기)
          break;
        case 'musicChanged':
          onMusicChanged?.call(); // 쓸어내리지 않아도 새 곡이 목록에
          break;
        case 'openAudio':
          OpenAudio.request(call.arguments as String); // 다른 앱에서 '파란소리로 열기'
          break;
        case 'widgetGo':
          WidgetGo.launched = true; // 위젯으로 켜졌으면 인삿말 목소리 안 함
          WidgetGo.target.value = call.arguments as String?; // 홈 위젯 바로가기
          break;
        case 'onAudioFocusGain':
          // 다른 소리 때문에 멈춘 것만 다시 (내가 멈춰 둔 건 그대로)
          if (_pausedByFocus && !_isPlaying && (_currentIndex >= 0 || _natureSoundName != null)) {
            await _player.play();
          }
          _pausedByFocus = false;
          break;
      }
      await extraHandler?.call(call); // 라디오에도 전달
      return null;
    });
  }

  AudioHandler? get audioHandler => _audioHandler;

  void setAudioHandler(AudioHandler handler) {
    _audioHandler = handler;
  }

  /// 미니플레이어 ×로 닫을 때: 알림을 끝내고, 알림창 카드의 재생 버튼으로 다시 틀 수 있게
  void dismissMediaNotification({Future<void> Function()? resume}) {
    final h = _audioHandler;
    if (h is SimpleAudioHandler) {
      h.dismiss();
      h.onResumeLast = resume;
    }
  }

  /// 지금 곡을 나중에 다시 틀기 (닫기 전에 불러 둠)
  Future<void> Function()? songResumer() {
    final i = _currentIndex;
    if (i < 0 || i >= _queue.length) return null;
    final q = List<Song>.from(_queue);
    return () => playFromList(q, i);
  }

  /// 지금 자연소리를 나중에 다시 틀기 (닫기 전에 불러 둠)
  Future<void> Function()? natureResumer() {
    final name = _natureSoundName;
    if (name == null) return null;
    final i = natureSoundOrder.indexWhere((s) => s['name'] == name);
    if (i < 0) return null;
    final path = natureSoundOrder[i]['assetPath']!;
    return () => playNatureSound(path, name);
  }

  VoidCallback? _onStopMixMusic;
  void setOnStopMixMusic(VoidCallback cb) {
    _onStopMixMusic = cb;
  }

  void setOnStopRadio(VoidCallback cb) {
    _onStopRadio = cb;
  }

  void handleWidgetAction(String action) {
    switch (action) {
      case 'widgetPlayPause':
        togglePlayPause();
        break;
      case 'widgetNext':
        playNext();
        break;
      case 'widgetPrev':
        playPrevious();
        break;
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final handler = _audioHandler;
      if (handler is SimpleAudioHandler) {
        handler.updatePosition(_player.position);
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _initStreams() {
    _player.playingStream.listen((playing) {
      // TV로 보내는 중이면 폰에서는 소리 안 내고, 그 곡을 TV로 (다음 곡·목록에서 고른 곡도)
      if (playing && CastService.instance.isConnected) {
        _player.pause();
        _sendToTv();
      }
      _isPlaying = playing;
      if (playing) {
        _startPositionTimer();
      } else {
        _stopPositionTimer();
      }
      _updateWidgetPlayState(playing);
      notifyListeners();
    });

    _player.positionStream.listen((position) {
      _position = position;
      _trackListen(position); // 30초 이상 들으면 기록
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((state) {
      final loading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _checkStall(state.processingState); // 같은 자리에서 계속 걸리면 건너뛰기
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      // 진짜 바뀔 때만 화면 다시 그리기 (걸림 반복 때 화면이 멈추지 않게)
      if (loading != _isLoading) {
        _isLoading = loading;
        notifyListeners();
      }
    });
  }

  // ───── 걸림 지킴이: 같은 자리에서 '불러오는 중'이 계속 반복되면 ─────
  // 1~2번은 2초 건너뛰고, 그래도 걸리면 다음 곡으로 (깨진 파일에서 앱이 멈추지 않게)
  int _stallCount = 0;
  int _stallPosMs = -1;
  DateTime _stallAt = DateTime.now();
  bool _stallFixing = false;
  String _stallSong = '';
  int _stallSkips = 0;

  void _checkStall(ProcessingState ps) {
    if (podcastActive || ps != ProcessingState.buffering || !_player.playing || _stallFixing) return;
    final pos = _player.position.inMilliseconds;
    final now = DateTime.now();
    // 자리가 달라졌거나 5초 지났으면 새로 세기
    if ((pos - _stallPosMs).abs() > 1500 || now.difference(_stallAt).inSeconds > 5) {
      _stallPosMs = pos;
      _stallAt = now;
      _stallCount = 0;
    }
    if (++_stallCount < 15) return;
    _stallCount = 0;
    _stallFixing = true;
    final song = currentSong?.uri ?? '';
    if (song != _stallSong) {
      _stallSong = song;
      _stallSkips = 0;
    }
    final dur = _player.duration ?? Duration.zero;
    final to = Duration(milliseconds: pos + 2000);
    Future(() async {
      try {
        if (_stallSkips < 2 && to < dur - const Duration(seconds: 3)) {
          _stallSkips++;
          await _player.seek(to);
        } else {
          await playNext();
        }
      } catch (_) {}
      _stallFixing = false;
    });
  }

  void _onSongCompleted() {
    if (podcastActive) return; // 팟캐스트는 끝나면 그대로 (podcast.dart가 정리)
    switch (_loopMode) {
      case LoopMode.one:
        _player.seek(Duration.zero);
        _player.play();
        // 한 곡 반복: 다시 30초 이상 들으면 또 +1
        final song = currentSong;
        if (song != null) _startListen(song);
        break;
      case LoopMode.all:
        if (hasNext) {
          playNext();
        } else {
          _playAtIndex(0);
        }
        break;
      case LoopMode.off:
      default:
        if (hasNext) {
          playNext();
        } else {
          // 마지막 곡이 끝나면 멈춤 (재생 버튼 누르면 그 곡 처음부터)
          _player.pause();
          _player.seek(Duration.zero);
        }
        break;
    }
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    // 라디오 재생 중이면 정지
    _onStopRadio?.call();
    _onStopMixMusic?.call();
    _natureSoundName = null;
    podcastActive = false;

    _currentIndex = index;
    _isLoading = true;
    notifyListeners();

    try {
      final song = _queue[index];
      if (song.uri == null) return;

      final handler = _audioHandler;
      if (handler is SimpleAudioHandler) {
        handler.setRadioMode(false);
        handler.setMixMode(false);
        handler.setNatureMode(false); // 자연 소리 듣다 음악으로 바꿔도 다음·이전 곡이 되게
        handler.setPodcastMode(false);
        handler.updateMediaItem(MediaItem(
          id: song.uri!,
          title: song.titleDisplay,
          artist: song.artistDisplay,
          album: song.albumDisplay,
          duration: Duration(milliseconds: song.duration),
        ));
        MediaArt.attachSong(handler, song);
      }

      _startListen(song); // 틀자마자 세지 않고, 30초 이상 들으면 기록
      onSongChanged?.call(song);
      _switching = true;
      try {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      } finally {
        _switching = false;
      }
      // 자연소리가 남긴 "무한반복" 설정을 꺼준다 (반복은 앱이 직접 처리함)
      await _player.setLoopMode(LoopMode.off);
      if (_player.speed != _playbackSpeed) await _player.setSpeed(_playbackSpeed); // 팟캐스트 속도가 음악에 남지 않게
      _applyLoudness(song); // 곡마다 소리 크기 맞추기
      _startedAt = DateTime.now();
      await _player.play();
      await WakelockPlus.enable().catchError((Object _) {});
      _updateWidgetSongInfo(song);
    } catch (e) {
      debugPrint('재생 오류: $e');
      _isLoading = false;
      notifyListeners();
      if (hasNext) playNext();
    }
  }

  void _updateWidgetSongInfo(Song song) {
    try {
      _channel.invokeMethod('updateWidget', {
        'title': song.titleDisplay,
        'artist': song.artistDisplay,
        'isPlaying': true,
      }).catchError((Object _) => null); // 위젯 없거나 준비 전이면 조용히 넘어가기
    } catch (e) {}
  }

  void _updateWidgetPlayState(bool isPlaying) {
    try {
      final song = currentSong;
      _channel.invokeMethod('updateWidget', {
        'title': song?.titleDisplay ?? tr.appName,
        'artist': song?.artistDisplay ?? tr.widgetIdle,
        'isPlaying': isPlaying,
      }).catchError((Object _) => null); // 위젯 없거나 준비 전이면 조용히 넘어가기
    } catch (e) {}
  }

  void addToPlayNext(Song song) {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _queue.insert(_currentIndex + 1, song);
    } else {
      _queue.add(song);
    }
    notifyListeners();
  }

  Future<void> playFromList(List<Song> songs, int index, {bool isPlayAllAction = false}) async {
    _queue = List.from(songs);
    final handler = _audioHandler;
    if (handler is SimpleAudioHandler) {
      handler.setRadioMode(false);
    }
    if (isPlayAllAction && _loopMode == LoopMode.one) {
      setLoopMode(LoopMode.all);
    }
    await _playAtIndex(index);
  }

  String? _natureSoundName;
  String? get natureSoundName => _natureSoundName;
  void Function(String assetPath, String displayName)? onNaturePlayed;

  void clearNatureSoundState() {
    if (_natureSoundName != null) {
      _natureSoundName = null;
      notifyListeners();
    }
  }

  void clearCurrentSong() {
    if (_currentIndex != -1) {
      _currentIndex = -1;
      notifyListeners();
    }
  }

  /// 팟캐스트가 재생기를 쓰는 동안 true (곡 끝·걸림 때 음악 다음 곡으로 넘어가지 않게)
  bool podcastActive = false;

  /// 팟캐스트 틀기 전: 라디오·믹스·자연소리·음악 자리를 비우고 알림창을 팟캐스트 모드로
  void preparePodcast({required VoidCallback onBack, required VoidCallback onForward}) {
    _onStopRadio?.call();
    _onStopMixMusic?.call();
    _natureSoundName = null;
    _natureTimer?.cancel();
    _listenSong = null;
    _currentIndex = -1;
    podcastActive = true;
    final h = _audioHandler;
    if (h is SimpleAudioHandler) {
      h.setRadioMode(false);
      h.setMixMode(false);
      h.setNatureMode(false);
      h.setPodcastMode(true, onBack: onBack, onForward: onForward);
    }
    notifyListeners();
  }

  static const List<Map<String, String>> natureSoundOrder = [
    {'name': '파도소리', 'assetPath': 'https://files.ssing.kr/nature-sounds/wave_sound.mp3'},
    {'name': '잔잔한 파도', 'assetPath': 'https://files.ssing.kr/nature-sounds/wave_calm_sound.mp3'},
    {'name': '갈매기와 파도', 'assetPath': 'https://files.ssing.kr/nature-sounds/wave_seagull_sound.mp3'},
    {'name': '바위에 부딪히는 파도', 'assetPath': 'https://files.ssing.kr/nature-sounds/wave_rocks_sound.mp3'},
    {'name': '멀리서 들리는 갈매기', 'assetPath': 'https://files.ssing.kr/nature-sounds/wave_distant_seagull_sound.mp3'},
    {'name': '거친 파도', 'assetPath': 'https://files.ssing.kr/nature-sounds/wave_rough_sound.mp3'},
    {'name': '빗소리', 'assetPath': 'https://files.ssing.kr/nature-sounds/rain_sound.mp3'},
    {'name': '창문에 떨어지는 비', 'assetPath': 'https://files.ssing.kr/nature-sounds/rain_window_sound.mp3'},
    {'name': '숲속의 비와 새소리', 'assetPath': 'https://files.ssing.kr/nature-sounds/rain_forest_sound.mp3'},
    {'name': '숲속의 거센 밤비', 'assetPath': 'https://files.ssing.kr/nature-sounds/rain_night_forest_sound.mp3'},
    {'name': '새소리', 'assetPath': 'https://files.ssing.kr/nature-sounds/bird_sound.mp3'},
    {'name': '뻐꾸기와 숲속 새소리', 'assetPath': 'https://files.ssing.kr/nature-sounds/bird_forest_cuckoo_sound.mp3'},
    {'name': '모닥불', 'assetPath': 'https://files.ssing.kr/nature-sounds/campfire_sound.mp3'},
    {'name': '시냇물', 'assetPath': 'https://files.ssing.kr/nature-sounds/stream_sound.mp3'},
    {'name': '잔잔한 강물', 'assetPath': 'https://files.ssing.kr/nature-sounds/stream_river_sound.mp3'},
  ];

  Future<void> playAdjacentNatureSound(int direction) async {
    final idx = natureSoundOrder.indexWhere((s) => s['name'] == _natureSoundName);
    if (idx == -1) return;
    final nextIdx = (idx + direction + natureSoundOrder.length) % natureSoundOrder.length;
    final next = natureSoundOrder[nextIdx];
    await playNatureSound(next['assetPath']!, next['name']!);
  }

  Future<void> playNatureSound(String assetPath, String displayName) async {
    _onStopRadio?.call();
    _natureSoundName = displayName;
    podcastActive = false;
    _listenSong = null;
    // 30초 이상 들었을 때만 "최근에 들었어요"에 넣기
    _natureTimer?.cancel();
    _natureTimer = Timer(const Duration(seconds: 30), () {
      if (_natureSoundName == displayName && _player.playing) {
        onNaturePlayed?.call(assetPath, displayName);
      }
    });
    _currentIndex = -1;
    _isLoading = true;
    notifyListeners();

    final handler = _audioHandler;
    if (handler is SimpleAudioHandler) {
      handler.setRadioMode(false);
      handler.setMixMode(false);
      handler.setNatureMode(true);
      handler.setPodcastMode(false);
      // 못 받아 와서 멈춰 있으면(인터넷 없음 등) 재생 버튼 → 다시 받아 오기
      handler.onNaturePlay = () => _player.processingState == ProcessingState.idle
          ? playNatureSound(assetPath, displayName)
          : resumeNatureSound();
      handler.onNaturePause = () => pauseNatureSound();
      handler.onNatureNext = () => playAdjacentNatureSound(1);
      handler.onNaturePrevious = () => playAdjacentNatureSound(-1);
      handler.updateMediaItem(MediaItem(
        id: assetPath,
        title: natureName(displayName),
        artist: tr.natureSounds,
      ));
      MediaArt.attachAsset(handler, MediaArt.natureImage(displayName), assetPath, displayName);
    }

    try {
      final source = assetPath.startsWith('http')
          ? LockCachingAudioSource(Uri.parse(assetPath))
          : AudioSource.asset(assetPath);
      _switching = true;
      try {
        await _player.setAudioSource(source).timeout(const Duration(seconds: 15)); // 인터넷 없으면 오래 기다리지 않게
      } finally {
        _switching = false;
      }
      await _player.setLoopMode(LoopMode.one);
      await _player.setSpeed(1.0);
      _setNorm(1.0); // 자연은 크기 맞추기 안 함
      await _player.play();
      await WakelockPlus.enable().catchError((Object _) {});
    } catch (e) {
      debugPrint('자연소리 재생 오류: $e');
      // 차 화면 · 알림창에도 안내 (재생 중처럼 멈춰 있지 않게)
      if (handler is SimpleAudioHandler && _natureSoundName == displayName) {
        handler.showError(tr.checkInternet); // 먼저 안내를 띄우고 멈추기 (멈출 때 '정지'로 바뀌지 않게)
        await _player.stop().catchError((Object _) {});
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> stopNatureSound() async {
    _natureSoundName = null;
    final handler = _audioHandler;
    if (handler is SimpleAudioHandler) {
      handler.setNatureMode(false);
    }
    await _player.stop();
    await WakelockPlus.disable().catchError((Object _) {});
    notifyListeners();
  }

  Future<void> pauseNatureSound() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resumeNatureSound() async {
    await _player.play();
    _isPlaying = true;
    notifyListeners();
  }

  /// 지금 곡을 TV로 (이미 보낸 곡이면 이어서 재생만)
  void _sendToTv() {
    final cast = CastService.instance;
    final s = currentSong;
    if (s == null) return;
    if (cast.currentUri != s.uri) {
      cast.castSong(s);
    } else if (!cast.tvPlaying) {
      cast.play();
    }
  }

  Future<void> togglePlayPause() async {
    // TV로 보내는 중이면 TV를 재생/일시정지
    final cast = CastService.instance;
    if (cast.isConnected) {
      cast.tvPlaying ? await cast.pause() : await cast.play();
      return;
    }
    if (_player.playing) {
      await _player.pause();
      await WakelockPlus.disable().catchError((Object _) {});
    } else {
      _onStopRadio?.call();
      final handler = _audioHandler;
      if (handler is SimpleAudioHandler) {
        handler.setRadioMode(false);
        final song = currentSong;
        if (song != null) {
          handler.updateMediaItem(MediaItem(
            id: song.uri ?? '',
            title: song.titleDisplay,
            artist: song.artistDisplay,
            album: song.albumDisplay,
            duration: Duration(milliseconds: song.duration),
          ));
          MediaArt.attachSong(handler, song);
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
      await _player.play();
      await WakelockPlus.enable().catchError((Object _) {});
    }
  }

  bool _isChangingSong = false;
  bool _switching = false; // 곡 바꾸는 중 (차 화면에 '정지'로 알리지 않게)
  DateTime _startedAt = DateTime(2000); // 곡을 막 튼 시각

  // ───── 들은 기록: 30초 이상(1분보다 짧은 곡은 절반 이상) 들어야 재생 횟수·최근에 넣음 ─────
  Song? _listenSong; // 지금 재고 있는 곡
  int _listenMs = 0; // 실제로 들은 시간
  int _lastPosMs = 0;
  bool _listenCounted = false; // 이번에 이미 셌는지
  Timer? _natureTimer;

  void _startListen(Song song) {
    _listenSong = song;
    _listenMs = 0;
    _lastPosMs = 0;
    _listenCounted = false;
  }

  void _trackListen(Duration pos) {
    final song = _listenSong;
    final p = pos.inMilliseconds;
    final d = p - _lastPosMs;
    _lastPosMs = p;
    if (song == null || _listenCounted || !_player.playing) return;
    if (d <= 0 || d > 2000) return; // 앞뒤로 넘긴 건 안 셈
    _listenMs += d;
    final total = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : song.duration;
    final need = total > 0 && total < 60000 ? total ~/ 2 : 30000;
    if (_listenMs >= need) {
      _listenCounted = true;
      onSongPlayed?.call(song);
    }
  }

  Future<void> playNext() async {
    if (_isChangingSong) return;
    _isChangingSong = true;
    if (hasNext) {
      await _playAtIndex(_currentIndex + 1);
    } else if (_queue.isNotEmpty) {
      await _playAtIndex(0);
    }
    _isChangingSong = false;
  }

  Future<void> playPrevious() async {
    if (_isChangingSong) return;
    _isChangingSong = true;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (hasPrevious) {
      await _playAtIndex(_currentIndex - 1);
    } else if (_queue.isNotEmpty) {
      await _playAtIndex(_queue.length - 1);
    }
    _isChangingSong = false;
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      final current = currentSong;
      _queue.shuffle();
      if (current != null) {
        final idx = _queue.indexWhere((s) => s.id == current.id);
        if (idx != -1) {
          _queue.removeAt(idx);
          _queue.insert(0, current);
          _currentIndex = 0;
        }
      }
    }
    notifyListeners();
    _saveWidgetModes();
  }

  void toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.off;
        break;
    }
    notifyListeners();
    _saveLoopMode();
    _saveWidgetModes();
  }

  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
    notifyListeners();
    _saveLoopMode();
    _saveWidgetModes();
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ───── 수면 타이머: 끝나기 1분 전부터 천천히 작게 ─────
  Timer? _sleepFadeStart; // 1분 전에 줄이기 시작
  Timer? _sleepFade; // 1초마다 조금씩 작게

  void _beginSleepFade() {
    _sleepFade?.cancel();
    _sleepFade = Timer.periodic(const Duration(seconds: 1), (t) {
      final end = _sleepTimerEnd;
      if (end == null) {
        t.cancel();
        return;
      }
      final left = end.difference(DateTime.now()).inMilliseconds / 60000.0;
      _player.setVolume(left.clamp(0.0, 1.0) * _normGain);
    });
  }

  /// 줄이던 걸 멈추고 소리 크기 원래대로
  void _endSleepFade() {
    _sleepFadeStart?.cancel();
    _sleepFadeStart = null;
    if (_sleepFade == null) return;
    _sleepFade!.cancel();
    _sleepFade = null;
    _player.setVolume(_normGain);
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _endSleepFade();
    _sleepTimerDuration = duration;
    _sleepTimerEnd = DateTime.now().add(duration);
    HeadsetResume.saveSleepEnd('m', _sleepTimerEnd); // 위젯에 남은 시간
    final fadeAt = duration - const Duration(minutes: 1);
    _sleepFadeStart = Timer(fadeAt.isNegative ? Duration.zero : fadeAt, _beginSleepFade);
    _sleepTimer = Timer(duration, () {
      // 다 작아진 뒤 멈추고, 멈춘 다음 소리 크기 원래대로
      _player.pause().then((_) => _endSleepFade());
      _sleepTimer = null;
      _sleepTimerDuration = null;
      _sleepTimerEnd = null;
      HeadsetResume.saveSleepEnd('m', null);
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _endSleepFade();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    if (_sleepTimerEnd != null) HeadsetResume.saveSleepEnd('m', null);
    _sleepTimerEnd = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _sleepTimer?.cancel();
    _player.dispose();
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }
}

class SimpleAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;
  final PlayerProvider _provider;
  bool _radioMode = false;
  VoidCallback? onRadioPlay;
  VoidCallback? onRadioPause;
  VoidCallback? onRadioNext;
  VoidCallback? onRadioPrevious;

  bool _mixMode = false;
  VoidCallback? onMixPlay;
  VoidCallback? onMixPause;
  VoidCallback? onMixNext;
  VoidCallback? onMixPrevious;

  bool _natureMode = false;
  VoidCallback? onNaturePlay;
  VoidCallback? onNaturePause;
  VoidCallback? onNatureNext;
  VoidCallback? onNaturePrevious;

  bool _podcastMode = false;
  VoidCallback? onPodcastBack; // 알림창 ⏮ = 15초 뒤로
  VoidCallback? onPodcastForward; // 알림창 ⏭ = 30초 앞으로
  void setPodcastMode(bool enabled, {VoidCallback? onBack, VoidCallback? onForward}) {
    _podcastMode = enabled;
    if (onBack != null) onPodcastBack = onBack;
    if (onForward != null) onPodcastForward = onForward;
  }

  /// ×로 닫은 뒤 알림창(미디어 출력) 카드의 재생 버튼: 닫았던 걸 다시 틀기
  Future<void> Function()? onResumeLast;

  SimpleAudioHandler(this._provider) : _player = _provider.player {
    _player.playbackEventStream.listen((event) {
      if (!_radioMode) {
        // 안내 글을 띄운 뒤 멈춰 있는 동안은 그대로 (다시 틀기 시작하면 보통 상태로)
        if (_holdError && _player.processingState == ProcessingState.idle) return;
        _holdError = false;
        playbackState.add(_transformEvent(event));
      }
    });

    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null && !_radioMode) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  void setRadioMode(bool enabled) {
    _radioMode = enabled;
  }

  bool _holdError = false; // 안내 글을 띄워 둔 동안 true

  /// 못 틀었을 때 (인터넷 없음 등): 차 화면 · 알림창에 안내 글 — 재생 버튼을 다시 누르면 다시
  void showError(String message) {
    _holdError = true;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: false,
      processingState: AudioProcessingState.error,
      errorCode: 1, // 앱 오류 (안드로이드 ERROR_CODE_APP_ERROR)
      errorMessage: message,
      updatePosition: Duration.zero,
      speed: 0.0,
    ));
  }

  void setMixMode(bool enabled) {
    _mixMode = enabled;
  }

  bool get isMixMode => _mixMode;
  bool get isRadioMode => _radioMode;

  void setNatureMode(bool enabled) {
    _natureMode = enabled;
  }

  void setMixPlaybackState({required bool playing}) {
    if (playing) _mixMode = true;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: playing,
      processingState: AudioProcessingState.ready,
    ));
  }

  void setMixMediaItem({
    required String title,
    required String subtitle,
    Song? song,
  }) {
    onResumeLast = null;
    mediaItem.add(MediaItem(
      id: 'sound_mix',
      title: title,
      artist: subtitle,
      album: tr.paransoriMix,
    ));
    if (song != null) MediaArt.attachSong(this, song, id: 'sound_mix', title: title);
  }

  void setRadioPlaybackState({required bool playing}) {
    if (playing) _radioMode = true;
    final pos = _radioPos();
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: playing,
      processingState: AudioProcessingState.ready,
      updatePosition: pos ?? const Duration(milliseconds: -1), // -1 = 위치 모름 → 시간 줄 안 보임
      speed: pos != null && playing ? 1.0 : 0.0,
    ));
  }

  /// 라디오 연결 실패: 차 화면 · 알림창에 안내 글 (재생 버튼을 다시 누르면 다시 연결)
  /// 다시 소리가 나면 setRadioPlaybackState가 보통 상태로 돌려놓음
  void setRadioError(String message) {
    if (!_radioMode) return;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: false,
      processingState: AudioProcessingState.error,
      errorCode: 1, // 앱 오류 (안드로이드 ERROR_CODE_APP_ERROR)
      errorMessage: message,
      updatePosition: const Duration(milliseconds: -1),
      speed: 0.0,
    ));
  }

  // ───── 라디오 시간 줄: 지금 프로그램 시작~끝 (편성표) ─────
  String? _progFor; // 어느 방송의 프로그램 시간인지
  DateTime? _progStart;
  DateTime? _progEnd;

  /// 지금 프로그램이 시작한 뒤 지난 시간 (편성표 없거나 시간 밖이면 null)
  Duration? _radioPos() {
    final s = _progStart, e = _progEnd;
    if (s == null || e == null) return null;
    final now = DateTime.now();
    if (now.isBefore(s) || !now.isBefore(e)) return null;
    return now.difference(s);
  }

  Duration? _radioLength() {
    final s = _progStart, e = _progEnd;
    if (_radioPos() == null || s == null || e == null) return null;
    return e.difference(s);
  }

  /// 편성표에서 지금 프로그램 시간이 오면 (없으면 null, null) → 시간 줄 다시
  void setRadioProgramTime(String station, DateTime? start, DateTime? end) {
    _progFor = station;
    _progStart = start;
    _progEnd = end;
    if (!_radioMode) return;
    final pos = _radioPos();
    playbackState.add(playbackState.value.copyWith(
      updatePosition: pos ?? const Duration(milliseconds: -1),
      speed: pos != null && playbackState.value.playing ? 1.0 : 0.0,
    ));
    // 길이를 없앨 때도 있어서 copyWith 말고 새로 (copyWith는 null을 넣어도 예전 길이가 남음)
    final cur = mediaItem.value;
    if (cur != null) {
      mediaItem.add(MediaItem(
        id: cur.id,
        title: cur.title,
        artist: cur.artist,
        album: cur.album,
        artUri: cur.artUri,
        displaySubtitle: cur.displaySubtitle,
        duration: _radioLength(),
      ));
    }
  }

  void setRadioMediaItem({
    required String title,
    required String artist,
    String? url,
  }) {
    onResumeLast = null;
    if (_player.processingState == ProcessingState.idle) {
      _radioMode = true;
    }
    // 다른 방송으로 바뀌었으면 지난 프로그램 시간은 버리기
    if (_progFor != title) {
      _progFor = title;
      _progStart = null;
      _progEnd = null;
    }
    // 차에 연결돼 있으면: 차 화면 목록과 같은 방송 그림 / 아니면 시간대 사진
    final carArt = CarBrowse.nowPlayingArt();
    mediaItem.add(MediaItem(
      id: url ?? '',
      title: title,
      artist: artist,
      album: tr.paransoriRadio,
      artUri: carArt,
      duration: _radioLength(), // 프로그램 길이 (편성표 없으면 없음)
    ));
    if (carArt == null) MediaArt.attachAsset(this, MediaArt.radioHero(), url ?? '', title);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    var ps = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;
    // 곡 바꾸는 순간의 '정지'는 '불러오는 중'으로 (차가 재생 끝난 줄 알고 목록으로 돌아가지 않게)
    if (ps == AudioProcessingState.idle && _provider._switching) ps = AudioProcessingState.loading;
    return PlaybackState(
      controls: [
        // 팟캐스트: 15초 뒤로 · 30초 앞으로 모양 (차 화면 · 알림창 둘 다)
        _podcastMode ? _back15 : MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        _podcastMode ? _fwd30 : MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: ps,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  void updatePosition(Duration position) {
    if (_radioMode) return;
    try {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    } catch (e) {}
  }

  // ───── 안드로이드 오토 (차 화면) ─────
  // 기본 '되감기 · 빨리 감기' 자리에 15초 · 30초 아이콘 (안드로이드 13 이상은 차 화면 · 알림창 버튼으로, 그 밑은 알림창 버튼으로)
  static const _back15 = MediaControl(androidIcon: 'drawable/paran_ic_back15', label: '-15s', action: MediaAction.rewind);
  static const _fwd30 = MediaControl(androidIcon: 'drawable/paran_ic_fwd30', label: '+30s', action: MediaAction.fastForward);

  @override
  Future<void> rewind() async => onPodcastBack?.call();

  @override
  Future<void> fastForward() async => onPodcastForward?.call();

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) =>
      CarBrowse.children(parentMediaId);

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) =>
      CarBrowse.subscribe(parentMediaId);

  @override
  Future<List<MediaItem>> search(String query, [Map<String, dynamic>? extras]) => CarBrowse.search(query);

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) => CarBrowse.play(mediaId);

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) => CarBrowse.playFromSearch(query);

  @override
  Future<void> onTaskRemoved() async {
    // 최근 앱 목록에서 위로 밀어서 앱을 끄면, 재생 중이던 걸(라디오/믹스/음악/자연소리
    // 뭐든) 확실하게 다 멈춘다.
    if (_radioMode && onRadioPause != null) {
      onRadioPause!();
    } else if (_mixMode && onMixPause != null) {
      onMixPause!();
    } else if (_natureMode && onNaturePause != null) {
      onNaturePause!();
    } else {
      await _player.pause();
    }
    await super.onTaskRemoved();
  }

  @override
  Future<void> play() async {
    if (_radioMode && onRadioPlay != null) {
      onRadioPlay!();
    } else if (_mixMode && onMixPlay != null) {
      onMixPlay!();
    } else if (_natureMode && onNaturePlay != null) {
      onNaturePlay!();
    } else {
      if (_player.processingState != ProcessingState.idle) {
        _radioMode = false;
        await _player.play();
      } else if (onResumeLast != null) {
        final f = onResumeLast!;
        onResumeLast = null;
        await f();
      } else {
        // 틀 게 없으면 마지막에 듣던 것 (위젯·블루투스 재생 버튼)
        // 조금 늦게: 위젯 아래 버튼으로 깨어난 경우엔 그쪽이 먼저 틀게
        Future.delayed(const Duration(milliseconds: 800), HeadsetResume.widgetPlay);
      }
    }
  }

  @override
  Future<void> pause() async {
    if (_radioMode && onRadioPause != null) {
      onRadioPause!();
    } else if (_mixMode && onMixPause != null) {
      onMixPause!();
    } else if (_natureMode && onNaturePause != null) {
      onNaturePause!();
    } else {
      // 알림바 클릭 등 외부 이벤트로 인한 자동 pause 방지
      // 실제 재생 중일 때만 pause 허용
      if (_player.playing) {
        await _player.pause();
      }
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_radioMode && onRadioNext != null) {
      onRadioNext!();
    } else if (_mixMode && onMixNext != null) {
      onMixNext!();
    } else if (_natureMode && onNatureNext != null) {
      onNatureNext!();
    } else if (_podcastMode && onPodcastForward != null) {
      onPodcastForward!();
    } else {
      await _provider.playNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_radioMode && onRadioPrevious != null) {
      onRadioPrevious!();
    } else if (_mixMode && onMixPrevious != null) {
      onMixPrevious!();
    } else if (_natureMode && onNaturePrevious != null) {
      onNaturePrevious!();
    } else if (_podcastMode && onPodcastBack != null) {
      onPodcastBack!();
    } else {
      await _provider.playPrevious();
    }
  }

  /// 완전히 끝: '정지(idle)'로 알려야 알림창 미디어 출력이 사라짐
  /// (그냥 멈추면 '일시정지'로 남아서, 눌러도 안 되는 알림이 남았음)
  void dismiss() {
    _radioMode = false;
    _mixMode = false;
    _natureMode = false;
    _podcastMode = false;
    if (playbackState.value.processingState != AudioProcessingState.idle) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    }
  }

  Future<void> updateMediaItem(MediaItem item) async {
    onResumeLast = null;
    mediaItem.add(item);
  }
}

/// 폰 미디어 출력(알림창)에 보일 사진 — 폰이 이 사진 색으로 배경·버튼 색을 칠함
class MediaArt {
  static final Map<String, Uri> _done = {};

  static String? _dir;
  static Future<String?> _folder() async {
    if (_dir != null) return _dir;
    try {
      final d = Directory('${Directory.systemTemp.path}/media_art');
      if (!await d.exists()) await d.create(recursive: true);
      _dir = d.path;
    } catch (_) {}
    return _dir;
  }

  /// 사진을 작은 파일로 저장해서 주소 돌려주기 (앱 켜져 있는 동안 한 번만)
  static Future<Uri?> _file(String name, Future<List<int>?> Function() bytes) async {
    final hit = _done[name];
    if (hit != null) return hit;
    try {
      final dir = await _folder();
      if (dir == null) return null;
      final b = await bytes();
      if (b == null || b.isEmpty) return null;
      final f = File('$dir/$name');
      await f.writeAsBytes(b, flush: true);
      return _done[name] = Uri.file(f.path);
    } catch (_) {
      return null;
    }
  }

  /// 사진 준비되면 지금 알림창 항목에 붙이기 (그사이 다른 곡으로 바뀌었으면 안 붙임)
  static void _put(SimpleAudioHandler h, String id, String title, Future<Uri?> art) {
    art.then((uri) {
      final cur = h.mediaItem.value;
      if (uri == null || cur == null || cur.id != id || cur.title != title) return;
      h.mediaItem.add(cur.copyWith(artUri: uri));
    });
  }

  /// 음악: 곡의 앨범 사진 (없으면 그냥 둠)
  static void attachSong(SimpleAudioHandler h, Song song, {String? id, String? title}) {
    final art = song.albumArt;
    if (art == null || art.isEmpty) {
      // 앨범 사진 없는 곡: 재생 화면과 같은 고양이 사진
      attachAsset(h, noAlbumImagePath(song.uri ?? song.title).replaceFirst('.jpg', '_media.jpg'), id ?? song.uri ?? '', title ?? song.titleDisplay);
      return;
    }
    _put(h, id ?? song.uri ?? '', title ?? song.titleDisplay,
        _file('song_${song.id}_${art.length}.img', () async => art));
  }

  /// 앱 안의 사진 (라디오 등)
  static void attachAsset(SimpleAudioHandler h, String asset, String id, String title) {
    final name = asset.split('/').last;
    _put(h, id, title, _file(name, () async {
      final data = await rootBundle.load(asset);
      return data.buffer.asUint8List();
    }));
  }

  /// 라디오: 지금 시간대 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
  static String radioHero() {
    final h = DateTime.now().hour;
    final slot = h >= 5 && h < 11
        ? 'morning'
        : h >= 11 && h < 17
            ? 'day'
            : h >= 17 && h < 22
                ? 'evening'
                : 'night';
    return 'assets/radio_media_$slot.jpg';
  }

  /// 자연소리: 이름에 맞는 사진
  static String natureImage(String name) {
    if (name.contains('비')) return 'assets/rest_rain.jpg';
    if (name.contains('파도') || name.contains('갈매기')) return 'assets/rest_wave.jpg';
    if (name.contains('모닥불')) return 'assets/rest_fire.jpg';
    if (name.contains('시냇물') || name.contains('강물')) return 'assets/rest_stream.jpg';
    if (name.contains('새') || name.contains('뻐꾸기')) return 'assets/rest_bird.jpg';
    return 'assets/nature_bg.jpg';
  }
}
