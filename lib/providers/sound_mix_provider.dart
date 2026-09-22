import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'player_provider.dart';

/// 자연소리 5개(각자 반복 재생, 동시에 섞임) + 선택한 노래들(순서대로 이어서 재생, 끝나면 처음으로)
/// 을 함께 트는 믹스 Provider.
class SoundMixProvider extends ChangeNotifier {
  // 자연소리 고정 레이어 (asset 기반, 각자 무한 반복)
  static const natureAssets = <String, String>{
    '파도소리': 'assets/wave_sound.mp3',
    '빗소리': 'assets/rain_sound.mp3',
    '새소리': 'assets/bird_sound.mp3',
    '모닥불': 'assets/campfire_sound.mp3',
    '시냇물': 'assets/stream_sound.mp3',
  };

  static const double _defaultSongVolume = 0.7;

  final Map<String, double> _volumes = {
    for (final name in natureAssets.keys) name: 0.0,
  };
  final Map<String, AudioPlayer> _natureLayers = {};

  // 선택한 노래들: 하나의 재생목록(플레이리스트)으로 순서대로 이어서 재생
  final List<Song> _selectedSongs = [];
  AudioPlayer? _songPlayer;
  double _songVolume = _defaultSongVolume;

  bool _isPlaying = false;
  Timer? _sleepTicker;
  PlayerProvider? _playerProvider;

  /// main.dart에서 SoundMixProvider를 만든 직후 한 번 연결해줘야 해요.
  /// 이게 연결되어야 알림(백그라운드 미디어 컨트롤)이 믹스랑 이어져요.
  void attachPlayerProvider(PlayerProvider provider) {
    _playerProvider = provider;
    final handler = provider.audioHandler;
    if (handler is SimpleAudioHandler) {
      handler.onMixPlay = () => playAll();
      handler.onMixPause = () => stopAll();
      handler.onMixNext = () => skipToNextSong();
      handler.onMixPrevious = () => skipToPreviousSong();
    }
  }
  DateTime? _sleepEndTime;
  int? _sleepMinutes;

  Map<String, double> get volumes => _volumes;
  bool get isPlaying => _isPlaying;
  bool get hasSession => _natureLayers.isNotEmpty || _songPlayer != null;
  List<Song> get selectedSongs => List.unmodifiable(_selectedSongs);
  double get songVolume => _songVolume;

  /// 선택된 노래들 전체(재생목록)의 음량을 한번에 조절한다.
  Future<void> setSongVolume(double value) async {
    _songVolume = value;
    notifyListeners();
    await _songPlayer?.setVolume(value);
  }
  int? get sleepMinutes => _sleepMinutes;

  bool isSongSelected(Song song) =>
      song.uri != null && _selectedSongs.any((s) => s.uri == song.uri);

  Song? get currentSong {
    final idx = _songPlayer?.currentIndex;
    if (idx == null || idx < 0 || idx >= _selectedSongs.length) return null;
    return _selectedSongs[idx];
  }

  String get remainingLabel {
    if (_sleepEndTime == null) return '타이머';
    final remaining = _sleepEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return '타이머';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h > 0) return '$h시간 $m분';
    return '$m분';
  }

  void setSleepTimer(int? minutes) {
    _sleepTicker?.cancel();
    if (minutes == null) {
      _sleepMinutes = null;
      _sleepEndTime = null;
      notifyListeners();
      return;
    }
    _sleepMinutes = minutes;
    _sleepEndTime = DateTime.now().add(Duration(minutes: minutes));
    notifyListeners();
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _sleepEndTime!.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        timer.cancel();
        stopAll();
        _sleepMinutes = null;
        _sleepEndTime = null;
      }
      notifyListeners();
    });
  }

  double volumeOf(String key) => _volumes[key] ?? 0.0;

  SoundMixProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sound_mix_volumes');
    if (raw != null) {
      try {
        final Map decoded = jsonDecode(raw);
        decoded.forEach((k, v) {
          if (_volumes.containsKey(k) && v is num) {
            _volumes[k] = v.toDouble();
          }
        });
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _saveVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sound_mix_volumes', jsonEncode(_volumes));
  }

  /// 자연소리 슬라이더를 움직였을 때 호출. 재생 중이면 실시간으로 음량도 반영한다.
  Future<void> setVolume(String key, double value) async {
    _volumes[key] = value;
    notifyListeners();
    if (_isPlaying) {
      if (value > 0) {
        await _ensureNatureLayerPlaying(key);
      } else {
        await _natureLayers[key]?.pause();
      }
    } else {
      await _natureLayers[key]?.setVolume(value);
    }
    _saveVolumes();
  }

  void _updateNotification({required bool playing}) {
    final handler = _playerProvider?.audioHandler;
    if (handler is! SimpleAudioHandler) return;

    final activeNature = <String>[
      for (final entry in natureAssets.keys)
        if ((_volumes[entry] ?? 0.0) > 0) entry,
    ];
    final title = currentSong?.titleDisplay ?? '나만의 소리 믹스';
    final subtitle = activeNature.isNotEmpty ? activeNature.join(' · ') : '파란소리 믹스';

    handler.setMixMediaItem(title: title, subtitle: subtitle);
    handler.setMixPlaybackState(playing: playing);
  }

  Future<void> _ensureNatureLayerPlaying(String key) async {
    final vol = _volumes[key] ?? 0.0;
    if (vol <= 0) return;

    var player = _natureLayers[key];
    if (player == null) {
      player = AudioPlayer();
      _natureLayers[key] = player;
      final assetPath = natureAssets[key];
      if (assetPath == null) return;
      await player.setAudioSource(AudioSource.asset(assetPath));
      await player.setLoopMode(LoopMode.one);
    }

    if (!_isPlaying) return;
    await player.setVolume(vol);
    // 주의: LoopMode.one으로 무한반복 중이라 play()의 Future는 절대 끝나지 않는다.
    // await로 기다리면 이 함수가 영원히 멈추고 그 뒤 레이어들은 재생 시도조차 못 한다.
    player.play();
  }

  /// 노래 선택 목록에서 체크박스를 눌렀을 때 호출. 선택된 노래들은 하나의
  /// 재생목록으로 만들어져서 순서대로 이어서 재생된다 (동시에 겹쳐 나오지 않음).
  Future<void> toggleSong(Song song) async {
    if (song.uri == null) return;

    if (isSongSelected(song)) {
      _selectedSongs.removeWhere((s) => s.uri == song.uri);
    } else {
      _selectedSongs.add(song);
    }
    notifyListeners();
    await _rebuildSongPlaylist();
  }

  /// 알림(백그라운드 미디어 컨트롤)에서 다음곡 눌렀을 때
  Future<void> skipToNextSong() async {
    try {
      await _songPlayer?.seekToNext();
    } catch (_) {}
  }

  /// 알림(백그라운드 미디어 컨트롤)에서 이전곡 눌렀을 때
  Future<void> skipToPreviousSong() async {
    try {
      await _songPlayer?.seekToPrevious();
    } catch (_) {}
  }

  Future<void> _rebuildSongPlaylist() async {
    if (_selectedSongs.isEmpty) {
      await _songPlayer?.stop();
      await _songPlayer?.dispose();
      _songPlayer = null;
      return;
    }

    final isNewPlayer = _songPlayer == null;
    _songPlayer ??= AudioPlayer();
    if (isNewPlayer) {
      _songPlayer!.currentIndexStream.listen((_) {
        notifyListeners();
        _updateNotification(playing: _isPlaying);
      });
    }
    final source = ConcatenatingAudioSource(
      children: _selectedSongs
          .where((s) => s.uri != null)
          .map((s) => AudioSource.uri(Uri.parse(s.uri!)))
          .toList(),
    );
    try {
      await _songPlayer!.setAudioSource(source);
      await _songPlayer!.setLoopMode(LoopMode.all);
      await _songPlayer!.setVolume(_songVolume);
      if (_isPlaying) {
        _songPlayer!.play();
      }
    } catch (_) {}
  }

  /// 지금 음량이 0보다 큰 자연소리 + 선택된 노래 재생목록을 전부 동시에 재생 시작한다.
  Future<void> playAll() async {
    _isPlaying = true;
    notifyListeners();
    _updateNotification(playing: true);
    for (final key in _volumes.keys.toList()) {
      if ((_volumes[key] ?? 0.0) > 0) {
        await _ensureNatureLayerPlaying(key);
      }
    }
    if (_selectedSongs.isNotEmpty) {
      if (_songPlayer == null) {
        await _rebuildSongPlaylist();
      } else {
        _songPlayer!.play();
      }
    }
  }

  /// 재생 중인 것을 전부 멈춘다 (선택/음량 값 자체는 유지).
  Future<void> stopAll() async {
    final natureSnapshot = _natureLayers.values.toList();
    for (final player in natureSnapshot) {
      try {
        await player.pause();
      } catch (_) {}
    }
    try {
      await _songPlayer?.pause();
    } catch (_) {}
    _isPlaying = false;
    notifyListeners();
    _updateNotification(playing: false);
  }

  @override
  void dispose() {
    _sleepTicker?.cancel();
    for (final p in _natureLayers.values) {
      p.dispose();
    }
    _songPlayer?.dispose();
    super.dispose();
  }
}