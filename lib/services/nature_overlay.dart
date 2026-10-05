import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/player_provider.dart';
import '../providers/sound_mix_provider.dart';
import 'cast_service.dart';

/// 음악 위에 자연소리(빗소리·파도 등)를 살짝 깔아서 같이 듣기
/// - 음악이 재생될 때만 같이 나오고, 음악을 멈추면 같이 멈춤
/// - 소리별 크기는 저장돼서 다음에도 그대로
class NatureOverlay extends ChangeNotifier {
  NatureOverlay._();
  static final NatureOverlay instance = NatureOverlay._();

  /// 이름 → 소리 주소 (나만의 소리 믹스와 같은 5가지)
  static Map<String, String> get sounds => SoundMixProvider.natureAssets;

  /// 칸마다 고를 수 있는 종류 (예: 파도소리 → 잔잔한 파도, 거친 파도 …)
  static Map<String, Map<String, String>> get variants => SoundMixProvider.natureVariants;

  static const icons = <String, IconData>{
    '파도소리': Icons.waves,
    '빗소리': Icons.water_drop_outlined,
    '새소리': Icons.flutter_dash,
    '모닥불': Icons.local_fire_department_outlined,
    '시냇물': Icons.water_outlined,
  };

  final Map<String, double> _vol = {for (final k in SoundMixProvider.natureAssets.keys) k: 0.0};
  final Map<String, AudioPlayer> _players = {};
  // 칸 이름 → 고른 종류 이름 (처음엔 칸 이름과 같은 기본 종류)
  final Map<String, String> _variant = {for (final k in SoundMixProvider.natureAssets.keys) k: k};
  final Set<String> _starting = {};
  PlayerProvider? _music;
  bool _musicPlaying = false;

  double volumeOf(String k) => _vol[k] ?? 0.0;
  String variantOf(String k) => _variant[k] ?? k;
  String _urlFor(String k) => variants[k]?[variantOf(k)] ?? sounds[k]!;
  bool get anyOn => _vol.values.any((v) => v > 0);
  bool get musicPlaying => _musicPlaying;
  String? get songTitle => _music?.currentSong?.titleDisplay; // 지금 섞고 있는 노래
  String? _lastSongUri;

  /// 메뉴 오른쪽에 보여줄 요약 (예: 빗소리 / 빗소리 외 1 / 끔)
  String get summary {
    final on = [for (final e in _vol.entries) if (e.value > 0) variantOf(e.key)];
    if (on.isEmpty) return '끔';
    if (on.length == 1) return on.first;
    return '${on.first} 외 ${on.length - 1}개';
  }

  /// 받침 있으면 '과', 없으면 '와' (예: 빗소리와 / 모닥불과)
  static String withJosa(String s) {
    if (s.isEmpty) return s;
    final c = s.codeUnitAt(s.length - 1);
    if (c < 0xAC00 || c > 0xD7A3) return '$s와';
    return (c - 0xAC00) % 28 == 0 ? '$s와' : '$s과';
  }

  /// 예: "잔잔한 파도와 함께" / "빗소리 외 1개와 함께"
  String get withLabel => '${withJosa(summary)} 함께';

  /// 음악 플레이어와 연결 (PlayerProvider가 만들어질 때 한 번)
  void attach(PlayerProvider p) {
    if (_music == p) return;
    _music = p;
    p.addListener(_onMusicChanged);
    _load();
  }

  void _onMusicChanged() {
    // 노래가 바뀌면 "OO 섞는 중" 글자도 바꾸기
    final uri = _music?.currentSong?.uri;
    if (uri != _lastSongUri) {
      _lastSongUri = uri;
      notifyListeners();
    }
    // TV로 듣는 중엔 폰에서 자연소리 안 나게
    final playing = (_music?.isPlaying ?? false) && !CastService.instance.isConnected;
    if (playing == _musicPlaying) return;
    _musicPlaying = playing;
    notifyListeners();
    _applyAll();
  }

  Future<void> setVolume(String k, double v) async {
    _vol[k] = v;
    notifyListeners();
    _save();
    await _applyOne(k);
  }

  /// 종류 바꾸기 (예: 파도소리 → 잔잔한 파도). 듣는 중이면 바로 새 소리로
  Future<void> setVariant(String k, String v) async {
    if (variantOf(k) == v) return;
    _variant[k] = v;
    notifyListeners();
    _save();
    final old = _players.remove(k);
    try {
      await old?.stop();
      await old?.dispose();
    } catch (_) {}
    await _applyOne(k);
  }

  Future<void> allOff() async {
    for (final k in _vol.keys) {
      _vol[k] = 0;
    }
    notifyListeners();
    _save();
    await _applyAll();
  }

  Future<void> _applyAll() async {
    for (final k in _vol.keys.toList()) {
      await _applyOne(k);
    }
  }

  Future<void> _applyOne(String k) async {
    final want = _musicPlaying && (_vol[k] ?? 0) > 0;
    var p = _players[k];
    if (!want) {
      try {
        await p?.pause();
      } catch (_) {}
      return;
    }
    if (p == null) {
      if (_starting.contains(k)) return; // 이미 불러오는 중
      _starting.add(k);
      try {
        p = AudioPlayer(handleInterruptions: false);
        await p.setAudioSource(LockCachingAudioSource(Uri.parse(_urlFor(k))));
        await p.setLoopMode(LoopMode.one);
        _players[k] = p;
      } catch (_) {
        _starting.remove(k);
        return;
      }
      _starting.remove(k);
    }
    // 불러오는 동안 값이 바뀌었을 수 있어서 다시 확인
    if (!_musicPlaying || (_vol[k] ?? 0) <= 0) {
      await p.pause();
      return;
    }
    await p.setVolume(_vol[k]!);
    // 무한 반복이라 play()는 끝나지 않으니 기다리지 않기
    if (!p.playing) p.play();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final rawV = prefs.getString('music_nature_variants');
      if (rawV != null) {
        final Map m = jsonDecode(rawV);
        m.forEach((k, v) {
          if (v is String && (variants[k]?.containsKey(v) ?? false)) _variant[k] = v;
        });
      }
      final raw = prefs.getString('music_nature_volumes');
      if (raw != null) {
        final Map m = jsonDecode(raw);
        m.forEach((k, v) {
          if (_vol.containsKey(k) && v is num) _vol[k] = v.toDouble();
        });
      }
      notifyListeners();
      _onMusicChanged();
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('music_nature_volumes', jsonEncode(_vol));
    await prefs.setString('music_nature_variants', jsonEncode(_variant));
  }
}

/// 🌿 자연소리 섞기 창 (재생화면 ⋮ 메뉴에서)
void showNatureOverlaySheet(BuildContext context) {
  const blue = Color(0xFF2589E8);
  final o = NatureOverlay.instance;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // 칸이 많아져도 잘리지 않게
    builder: (ctx) => AnimatedBuilder(
      animation: o,
      builder: (ctx, _) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EFE5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.forest_outlined, color: blue, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('자연소리 섞기',
                        style: TextStyle(color: Color(0xFF17140F), fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  if (o.anyOn)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        o.allOff();
                      },
                      child: const Text('모두 끄기', style: TextStyle(color: Color(0xFF8A857B))),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, bottom: 10),
                child: (o.musicPlaying && o.anyOn)
                    // 지금 섞는 중: 🎵 노래 제목 + 자연소리
                    ? Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: '🎵 '),
                          TextSpan(
                            text: o.songTitle ?? '음악',
                            style: const TextStyle(color: Color(0xFF17140F), fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' · ${o.withLabel}'),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF8A857B), fontSize: 12.5),
                      )
                    : Text(
                        o.musicPlaying ? '음악 위에 자연소리를 살짝 깔아 같이 들어요' : '음악이 재생될 때 같이 나와요',
                        style: const TextStyle(color: Color(0xFF8A857B), fontSize: 12.5),
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    for (final k in NatureOverlay.sounds.keys)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 6, 0),
                        child: Row(
                          children: [
                            Icon(NatureOverlay.icons[k] ?? Icons.music_note,
                                size: 20, color: o.volumeOf(k) > 0 ? blue : const Color(0xFFB0A99D)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(k,
                                          style: TextStyle(
                                              color: const Color(0xFF17140F)
                                                  .withOpacity(o.volumeOf(k) > 0 ? 1 : 0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      // 종류 고르기 (여러 개 있을 때만)
                                      if ((NatureOverlay.variants[k]?.length ?? 0) > 1)
                                        PopupMenuButton<String>(
                                          tooltip: '종류 고르기',
                                          onSelected: (v) => o.setVariant(k, v),
                                          itemBuilder: (_) => [
                                            for (final name in NatureOverlay.variants[k]!.keys)
                                              CheckedPopupMenuItem(
                                                value: name,
                                                checked: o.variantOf(k) == name,
                                                child: Text(name),
                                              ),
                                          ],
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF4EFE5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(o.variantOf(k),
                                                    style: const TextStyle(
                                                        color: Color(0xFF5A5348), fontSize: 12)),
                                                const Icon(Icons.expand_more, size: 16, color: Color(0xFF8A857B)),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(ctx).copyWith(
                                      trackHeight: 3,
                                      activeTrackColor: blue,
                                      inactiveTrackColor: const Color(0xFFE2DACB),
                                      thumbColor: blue,
                                      overlayColor: blue.withOpacity(0.1),
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    ),
                                    child: Slider(
                                      value: o.volumeOf(k),
                                      onChanged: (v) => o.setVolume(k, v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}