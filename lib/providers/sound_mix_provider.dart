import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../utils/nature_sound_catalog.dart';
import 'player_provider.dart';

/// 자연소리 5개(각자 반복 재생, 동시에 섞임) + 선택한 노래들(순서대로 이어서 재생, 끝나면 처음으로)
/// 을 함께 트는 믹스 Provider.
class SoundMixProvider extends ChangeNotifier {
  // 자연소리 고정 레이어 (asset 기반, 각자 무한 반복)
  static const natureAssets = <String, String>{
    '파도소리': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_sound.mp3',
    '빗소리': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_sound.mp3',
    '새소리': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_sound.mp3',
    '모닥불': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/campfire_sound.mp3',
    '시냇물': 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_sound.mp3',
  };

  /// 칸마다 고를 수 있는 종류 — 자연소리 목록(nature_sound_catalog.dart)에서 자동으로 만든다.
  /// 같은 category끼리 한 칸에 묶이고, 목록에서 먼저 나온 게 기본.
  static Map<String, Map<String, String>> get natureVariants {
    final map = <String, Map<String, String>>{};
    for (final s in natureSoundCatalog) {
      if (s.assetPath == null || !natureAssets.containsKey(s.category)) continue;
      map.putIfAbsent(s.category, () => {})[s.name] = s.assetPath!;
    }
    return map;
  }


  static const double _defaultSongVolume = 0.7;

  final Map<String, double> _volumes = {
    for (final name in natureAssets.keys) name: 0.0,
  };
  final Map<String, AudioPlayer> _natureLayers = {};
  // 칸 이름 → 고른 종류 이름 (처음엔 칸 이름과 같은 기본 종류)
  final Map<String, String> _variants = {
    for (final name in natureAssets.keys) name: name,
  };

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

  // ───── 수면 타이머: 끝나기 1분 전부터 천천히 작게 ─────
  bool _sleepFading = false;

  void _applySleepFade(double f) {
    _natureLayers.forEach((key, p) {
      p.setVolume((_volumes[key] ?? 0.0) * f);
    });
    _songPlayer?.setVolume(_songVolume * f);
  }

  /// 소리 크기 원래대로 (다음에 틀 때 작게 나오지 않게)
  void _restoreSleepFade() {
    if (!_sleepFading) return;
    _sleepFading = false;
    _applySleepFade(1.0);
  }

  void setSleepTimer(int? minutes) {
    _sleepTicker?.cancel();
    _restoreSleepFade();
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
        stopAll().then((_) => _restoreSleepFade());
        _sleepMinutes = null;
        _sleepEndTime = null;
      } else if (remaining.inSeconds < 60) {
        // 끝나기 1분 전부터 천천히 작게
        _sleepFading = true;
        _applySleepFade(remaining.inMilliseconds / 60000.0);
      }
      notifyListeners();
    });
  }

  double volumeOf(String key) => _volumes[key] ?? 0.0;

  /// 이 칸에서 지금 고른 종류 이름
  String variantOf(String key) => _variants[key] ?? key;

  String _urlFor(String key) =>
      natureVariants[key]?[variantOf(key)] ?? natureAssets[key]!;

  /// 칸의 종류를 바꾼다. 재생 중이면 새 소리를 먼저 틀고 예전 소리를 끈다 (끊김 없이).
  Future<void> setVariant(String key, String variant) async {
    if (variantOf(key) == variant) return;
    _variants[key] = variant;
    notifyListeners();
    _saveVariants();
    final old = _natureLayers.remove(key);
    if (_isPlaying && (_volumes[key] ?? 0.0) > 0) {
      await _ensureNatureLayerPlaying(key);
    }
    try {
      await old?.stop();
      await old?.dispose();
    } catch (_) {}
    _updateNotification(playing: _isPlaying);
  }

  Future<void> _saveVariants() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sound_mix_variants', jsonEncode(_variants));
  }

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
    final rawV = prefs.getString('sound_mix_variants');
    if (rawV != null) {
      try {
        final Map decoded = jsonDecode(rawV);
        decoded.forEach((k, v) {
          if (v is String && (natureVariants[k]?.containsKey(v) ?? false)) {
            _variants[k] = v;
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
    // 재생 시작(playing: true)은 플레이어가 만들어지기 전에 불릴 수 있어서
    // 세션이 없어도 알림을 가져와야 한다. 정지 갱신만 세션이 있을 때 한다.
    if (!playing && !hasSession) return;
    final handler = _playerProvider?.audioHandler;
    if (handler is! SimpleAudioHandler) return;

    // "정지" 알림 갱신은, 알림의 주인이 아직 믹스일 때만 한다.
    // (음악/자연소리/라디오가 새로 시작되면 그쪽이 알림을 가져가는데,
    //  믹스의 정지 처리가 뒤늦게 끝나면서 믹스 정보로 덮어쓰는 걸 막는다.)
    if (!playing && (!handler.isMixMode || handler.isRadioMode)) return;

    final activeNature = <String>[
      for (final entry in natureAssets.keys)
        if ((_volumes[entry] ?? 0.0) > 0) variantOf(entry),
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
      final String? assetPath = _urlFor(key);
      if (assetPath == null) return;
      final source = assetPath.startsWith('http')
          ? LockCachingAudioSource(Uri.parse(assetPath))
          : AudioSource.asset(assetPath);
      await player.setAudioSource(source);
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

  /// 미니플레이어 닫기: 멈추고 플레이어를 정리해서 미니플레이어가 사라지게
  /// (고른 소리·노래·음량은 그대로 → 다음에 믹스 화면에서 그대로 다시 재생)
  Future<void> closeSession() async {
    await stopAll();
    for (final p in _natureLayers.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _natureLayers.clear();
    try {
      await _songPlayer?.dispose();
    } catch (_) {}
    _songPlayer = null;
    _sleepTicker?.cancel();
    _sleepFading = false;
    _sleepMinutes = null;
    _sleepEndTime = null;
    notifyListeners();
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