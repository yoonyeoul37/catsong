import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
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
  bool get isPlaying => _isPlaying;
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
  }

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
      }
      return null;
    });
  }

  void setAudioHandler(AudioHandler handler) {
    _audioHandler = handler;
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
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      notifyListeners();
    });
  }

  void _onSongCompleted() {
    switch (_loopMode) {
      case LoopMode.one:
        _player.seek(Duration.zero);
        _player.play();
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
        }
        break;
    }
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    // 라디오 재생 중이면 정지
    _onStopRadio?.call();

    _currentIndex = index;
    _isLoading = true;
    notifyListeners();

    try {
      final song = _queue[index];
      if (song.uri == null) return;

      final handler = _audioHandler;
      if (handler is SimpleAudioHandler) {
        handler.setRadioMode(false);
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
      await _player.play();
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

  Future<void> playFromList(List<Song> songs, int index) async {
    _queue = List.from(songs);
    await _playAtIndex(index);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  bool _isChangingSong = false;

  Future<void> playNext() async {
    if (_isChangingSong) return;
    _isChangingSong = true;
    if (hasNext) await _playAtIndex(_currentIndex + 1);
    _isChangingSong = false;
  }

  Future<void> playPrevious() async {
    if (_isChangingSong) return;
    _isChangingSong = true;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (hasPrevious) {
      await _playAtIndex(_currentIndex - 1);
    } else {
      await _player.seek(Duration.zero);
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
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    notifyListeners();
  }

  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
    notifyListeners();
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

  void setRadioPlaybackState({required bool playing}) {
    _radioMode = true;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: playing,
      processingState: playing
          ? AudioProcessingState.ready
          : AudioProcessingState.idle,
    ));
  }

  void setRadioMediaItem({
    required String title,
    required String artist,
    String? url,
  }) {
    _radioMode = true;
    mediaItem.add(MediaItem(
      id: url ?? '',
      title: title,
      artist: artist,
      album: 'CatSong Radio',
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
  Future<void> play() async {
    if (_radioMode && onRadioPlay != null) {
      onRadioPlay!();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_radioMode && onRadioPause != null) {
      onRadioPause!();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_radioMode && onRadioNext != null) {
      onRadioNext!();
    } else {
      await _provider.playNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_radioMode && onRadioPrevious != null) {
      onRadioPrevious!();
    } else {
      await _provider.playPrevious();
    }
  }

  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }
}