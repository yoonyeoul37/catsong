import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

/// 자연소리 5개 + 음악 1곡을 동시에 재생할 수 있는 믹스 Provider.
/// 각 레이어는 0.0~1.0 사이의 음량을 가지고, 0이면 꺼진 것으로 취급한다.
class SoundMixProvider extends ChangeNotifier {
  // 자연소리 고정 레이어 (asset 기반)
  static const natureAssets = <String, String>{
    '파도소리': 'assets/wave_sound.mp3',
    '빗소리': 'assets/rain_sound.mp3',
    '새소리': 'assets/bird_sound.mp3',
    '모닥불': 'assets/campfire_sound.mp3',
    '시냇물': 'assets/stream_sound.mp3',
  };

  final Map<String, double> _volumes = {
    for (final name in natureAssets.keys) name: 0.0,
    'music': 0.0,
  };
  final Map<String, AudioPlayer> _players = {};
  bool _isPlaying = false;
  Song? _musicSong;

  Map<String, double> get volumes => _volumes;
  bool get isPlaying => _isPlaying;
  Song? get musicSong => _musicSong;

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

  /// 슬라이더를 움직였을 때 호출. 재생 중이면 실시간으로 음량도 반영한다.
  Future<void> setVolume(String key, double value) async {
    _volumes[key] = value;
    notifyListeners();
    if (_isPlaying) {
      if (value > 0) {
        await _ensureLayerPlaying(key);
      } else {
        await _players[key]?.pause();
      }
    } else {
      await _players[key]?.setVolume(value);
    }
    _saveVolumes();
  }

  void setMusicSong(Song song) {
    _musicSong = song;
    notifyListeners();
    if (_isPlaying && (_volumes['music'] ?? 0.0) > 0) {
      _ensureLayerPlaying('music', forceReload: true);
    }
  }

  Future<void> _ensureLayerPlaying(String key, {bool forceReload = false}) async {
    final vol = _volumes[key] ?? 0.0;
    if (vol <= 0) return;

    var player = _players[key];
    final needsLoad = player == null || forceReload;

    if (needsLoad) {
      player ??= AudioPlayer();
      _players[key] = player;
      if (key == 'music') {
        if (_musicSong?.uri == null) return;
        await player.setAudioSource(AudioSource.uri(Uri.parse(_musicSong!.uri!)));
      } else {
        final assetPath = natureAssets[key];
        if (assetPath == null) return;
        await player.setAudioSource(AudioSource.asset(assetPath));
      }
      await player.setLoopMode(LoopMode.one);
    }

    await player.setVolume(vol);
    await player.play();
  }

  /// 지금 음량이 0보다 큰 레이어들을 전부 동시에 재생 시작한다.
  Future<void> playAll() async {
    _isPlaying = true;
    notifyListeners();
    for (final key in _volumes.keys) {
      if ((_volumes[key] ?? 0.0) > 0) {
        await _ensureLayerPlaying(key);
      }
    }
  }

  /// 재생 중인 레이어를 전부 멈춘다 (음량 값 자체는 유지).
  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.pause();
    }
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}