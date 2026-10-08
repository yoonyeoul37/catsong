import 'dart:async';
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
  }

  Future<void> _loadLoopMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('loop_mode') ?? 0;
    _loopMode = LoopMode.values[saved];
    notifyListeners();
  }

  Future<void> _saveLoopMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('loop_mode', _loopMode.index);
  }

  // 라디오도 같은 통로로 신호를 받아서, 받는 곳을 하나로 합침 (둘이 따로 받으면 하나가 묻힘)
  static Future<void> Function(MethodCall call)? extraHandler;

  void _initWidgetChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'widgetPlayPause':
          await togglePlayPause();
          break;
        case 'widgetNext':
          await playNext();
          break;
        case 'widgetPrev':
          await playPrevious();
          break;
        case 'onAudioFocusLost':
          if (_isPlaying) {
            await _player.pause();
          }
          break;
        case 'onAudioFocusGain':
          if (!_isPlaying && _currentIndex >= 0) {
            await _player.play();
          }
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
    if (ps != ProcessingState.buffering || !_player.playing || _stallFixing) return;
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
    switch (_loopMode) {
      case LoopMode.one:
        _player.seek(Duration.zero);
        _player.play();
        // 한 곡 반복도 끝까지 한 번 들을 때마다 재생 횟수 +1
        final song = currentSong;
        if (song != null) onSongPlayed?.call(song);
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
        handler.updateMediaItem(MediaItem(
          id: song.uri!,
          title: song.titleDisplay,
          artist: song.artistDisplay,
          album: song.albumDisplay,
          duration: Duration(milliseconds: song.duration),
        ));
      }

      onSongPlayed?.call(song);
      onSongChanged?.call(song);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      // 자연소리가 남긴 "무한반복" 설정을 꺼준다 (반복은 앱이 직접 처리함)
      await _player.setLoopMode(LoopMode.off);
      await _player.play();
      await WakelockPlus.enable();
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
      });
    } catch (e) {}
  }

  void _updateWidgetPlayState(bool isPlaying) {
    try {
      final song = currentSong;
      _channel.invokeMethod('updateWidget', {
        'title': song?.titleDisplay ?? '플레이쏭',
        'artist': song?.artistDisplay ?? '음악을 재생해보세요',
        'isPlaying': isPlaying,
      });
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

  static const List<Map<String, String>> natureSoundOrder = [
    {'name': '파도소리', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_sound.mp3'},
    {'name': '잔잔한 파도', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_calm_sound.mp3'},
    {'name': '갈매기와 파도', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_seagull_sound.mp3'},
    {'name': '바위에 부딪히는 파도', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_rocks_sound.mp3'},
    {'name': '멀리서 들리는 갈매기', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_distant_seagull_sound.mp3'},
    {'name': '거친 파도', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_rough_sound.mp3'},
    {'name': '빗소리', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_sound.mp3'},
    {'name': '창문에 떨어지는 비', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_window_sound.mp3'},
    {'name': '숲속의 비와 새소리', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_forest_sound.mp3'},
    {'name': '숲속의 거센 밤비', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_night_forest_sound.mp3'},
    {'name': '새소리', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_sound.mp3'},
    {'name': '뻐꾸기와 숲속 새소리', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_forest_cuckoo_sound.mp3'},
    {'name': '모닥불', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/campfire_sound.mp3'},
    {'name': '시냇물', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_sound.mp3'},
    {'name': '잔잔한 강물', 'assetPath': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_river_sound.mp3'},
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
    onNaturePlayed?.call(assetPath, displayName);
    _currentIndex = -1;
    _isLoading = true;
    notifyListeners();

    final handler = _audioHandler;
    if (handler is SimpleAudioHandler) {
      handler.setRadioMode(false);
      handler.setMixMode(false);
      handler.setNatureMode(true);
      handler.onNaturePlay = () => resumeNatureSound();
      handler.onNaturePause = () => pauseNatureSound();
      handler.onNatureNext = () => playAdjacentNatureSound(1);
      handler.onNaturePrevious = () => playAdjacentNatureSound(-1);
      handler.updateMediaItem(MediaItem(
        id: assetPath,
        title: displayName,
        artist: '자연소리',
      ));
    }

    try {
      final source = assetPath.startsWith('http')
          ? LockCachingAudioSource(Uri.parse(assetPath))
          : AudioSource.asset(assetPath);
      await _player.setAudioSource(source);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('자연소리 재생 오류: $e');
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
    await WakelockPlus.disable();
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
      await WakelockPlus.disable();
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
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
      await _player.play();
      await WakelockPlus.enable();
    }
  }

  bool _isChangingSong = false;

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
  }

  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
    notifyListeners();
    _saveLoopMode();
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

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _player.pause();
      _sleepTimer = null;
      _sleepTimerDuration = null;
      _sleepTimerEnd = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _sleepTimer?.cancel();
    _player.dispose();
    WakelockPlus.disable();
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

  SimpleAudioHandler(this._provider) : _player = _provider.player {
    _player.playbackEventStream.listen((event) {
      if (!_radioMode) {
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
  }) {
    mediaItem.add(MediaItem(
      id: 'sound_mix',
      title: title,
      artist: subtitle,
      album: '파란소리 믹스',
    ));
  }

  void setRadioPlaybackState({required bool playing}) {
    if (playing) _radioMode = true;
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

  void setRadioMediaItem({
    required String title,
    required String artist,
    String? url,
  }) {
    if (_player.processingState == ProcessingState.idle) {
      _radioMode = true;
    }
    mediaItem.add(MediaItem(
      id: url ?? '',
      title: title,
      artist: artist,
      album: '파란소리 라디오',
    ));
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
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
    } else {
      await _provider.playPrevious();
    }
  }

  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }
}