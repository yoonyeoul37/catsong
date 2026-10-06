import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/player_provider.dart';

/// 내가 저장한 이퀄라이저 설정 하나
class FxPreset {
  final String name;
  final List<int> bands;
  final int bass;
  final int virt;
  final int reverb;
  FxPreset(this.name, this.bands, this.bass, this.virt, this.reverb);

  Map<String, dynamic> toJson() => {'name': name, 'bands': bands, 'bass': bass, 'virt': virt, 'reverb': reverb};
  static FxPreset fromJson(Map m) => FxPreset(
    m['name'] as String,
    (m['bands'] as List).map((e) => (e as num).toInt()).toList(),
    (m['bass'] as num?)?.toInt() ?? 0,
    (m['virt'] as num?)?.toInt() ?? 0,
    (m['reverb'] as num?)?.toInt() ?? 0,
  );
}

/// 이퀄라이저 · 저음 강화 · 공간감 · 울림(리버브)
/// - 화면을 닫아도 계속 적용되고, 앱을 다시 켜도 저장된 값으로 돌아옴
/// - 음악 플레이어의 소리 통로(세션)가 바뀌면 알아서 다시 연결
class SoundEffects extends ChangeNotifier {
  SoundEffects._();
  static final SoundEffects instance = SoundEffects._();
  static const _ch = MethodChannel('kr.ssing.catsong/media');

  /// 울림(리버브) 종류: 안드로이드 PresetReverb 순서 그대로
  static const reverbNames = ['끄기', '작은 방', '거실', '큰 방', '공연장', '대극장', '스튜디오'];

  bool ready = false;
  int minLevel = -1500;
  int maxLevel = 1500;
  List<int> freqs = []; // 밴드별 주파수
  List<int> bands = []; // 밴드별 크기
  List<String> devicePresets = []; // 폰에 들어 있는 프리셋 (Normal, Rock …)
  int bass = 0; // 0~1000
  int virt = 0; // 0~1000
  int reverb = 0; // reverbNames 순서
  bool reverbSupported = false;
  String label = ''; // 지금 고른 프리셋 이름 (직접 바꾸면 '')
  List<FxPreset> custom = []; // 내가 저장한 설정들

  PlayerProvider? _music;
  int? _session;
  bool _loaded = false;

  /// 음악 플레이어와 연결 (PlayerProvider가 만들어질 때 한 번)
  void attach(PlayerProvider p) {
    if (_music == p) return;
    _music = p;
    p.player.androidAudioSessionIdStream.listen((id) {
      if (id != null && id != _session) {
        _session = id;
        _connect(id);
      }
    });
  }

  /// 소리 통로에 효과 붙이고 저장된 값 다시 적용
  Future<void> _connect(int session) async {
    await _load();
    try {
      final r = await _ch.invokeMethod('initEqualizer', {'audioSessionId': session});
      minLevel = r['minLevel'] as int;
      maxLevel = r['maxLevel'] as int;
      final list = (r['bands'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      freqs = [for (final b in list) b['freq'] as int];
      final deviceLevels = [for (final b in list) b['level'] as int];
      if (bands.length != freqs.length) bands = deviceLevels; // 저장된 게 없거나 폰이 바뀌면 기본값
      devicePresets = (r['presets'] as List).map((e) => e.toString()).toList();
      for (var i = 0; i < bands.length; i++) {
        await _ch.invokeMethod('setEqualizerBand', {'band': i, 'level': bands[i]});
      }
    } catch (_) {}
    try {
      await _ch.invokeMethod('initBassBoost', {'audioSessionId': session});
      await _ch.invokeMethod('setBassBoost', {'strength': bass});
    } catch (_) {}
    try {
      await _ch.invokeMethod('initVirtualizer', {'audioSessionId': session});
      await _ch.invokeMethod('setVirtualizer', {'strength': virt});
    } catch (_) {}
    try {
      reverbSupported = (await _ch.invokeMethod('initReverb', {'audioSessionId': session})) == true;
      if (reverbSupported) await _ch.invokeMethod('setReverb', {'preset': 0}); // 울림 칸 뺐으니 항상 끄기
    } catch (_) {
      reverbSupported = false;
    }
    ready = true;
    notifyListeners();
  }

  // ───────── 바꾸기 ─────────
  Future<void> setBand(int i, int level) async {
    bands[i] = level;
    label = '';
    notifyListeners();
    await _ch.invokeMethod('setEqualizerBand', {'band': i, 'level': level});
    _save();
  }

  Future<void> setBass(int v) async {
    bass = v;
    notifyListeners();
    await _ch.invokeMethod('setBassBoost', {'strength': v});
    _save();
  }

  Future<void> setVirt(int v) async {
    virt = v;
    notifyListeners();
    await _ch.invokeMethod('setVirtualizer', {'strength': v});
    _save();
  }

  Future<void> setReverb(int v) async {
    reverb = v;
    notifyListeners();
    await _ch.invokeMethod('setReverb', {'preset': v});
    _save();
  }

  /// 폰에 들어 있는 프리셋 고르기 (Rock, Jazz …)
  Future<void> useDevicePreset(int index) async {
    await _ch.invokeMethod('setEqualizerPreset', {'preset': index});
    for (var i = 0; i < bands.length; i++) {
      try {
        bands[i] = await _ch.invokeMethod('getEqualizerBandLevel', {'band': i}) as int;
      } catch (_) {}
    }
    label = devicePresets[index];
    notifyListeners();
    _save();
  }

  /// 내가 저장한 설정 고르기
  Future<void> useCustom(FxPreset p) async {
    if (p.bands.length == bands.length) {
      bands = List.of(p.bands);
      for (var i = 0; i < bands.length; i++) {
        await _ch.invokeMethod('setEqualizerBand', {'band': i, 'level': bands[i]});
      }
    }
    await setBass(p.bass);
    await setVirt(p.virt);
    if (reverbSupported) await setReverb(p.reverb);
    label = p.name;
    notifyListeners();
    _save();
  }

  /// 지금 설정을 이름 붙여 저장 (같은 이름이 있으면 덮어쓰기)
  Future<void> saveCustom(String name) async {
    custom.removeWhere((c) => c.name == name);
    custom.add(FxPreset(name, List.of(bands), bass, virt, reverb));
    label = name;
    notifyListeners();
    _save();
  }

  Future<void> deleteCustom(FxPreset p) async {
    custom.removeWhere((c) => c.name == p.name);
    if (label == p.name) label = '';
    notifyListeners();
    _save();
  }

  /// 모두 0으로
  Future<void> reset() async {
    for (var i = 0; i < bands.length; i++) {
      bands[i] = 0;
      await _ch.invokeMethod('setEqualizerBand', {'band': i, 'level': 0});
    }
    label = '';
    await setBass(0);
    await setVirt(0);
    if (reverbSupported) await setReverb(0);
  }

  // ───────── 저장 ─────────
  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('fx_state');
      if (raw != null) {
        final m = jsonDecode(raw) as Map;
        bands = (m['bands'] as List? ?? []).map((e) => (e as num).toInt()).toList();
        bass = (m['bass'] as num?)?.toInt() ?? 0;
        virt = (m['virt'] as num?)?.toInt() ?? 0;
        reverb = (m['reverb'] as num?)?.toInt() ?? 0;
        label = m['label'] as String? ?? '';
      }
      final rawC = prefs.getString('fx_custom');
      if (rawC != null) {
        custom = (jsonDecode(rawC) as List).map((e) => FxPreset.fromJson(e as Map)).toList();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fx_state',
        jsonEncode({'bands': bands, 'bass': bass, 'virt': virt, 'reverb': reverb, 'label': label}));
    await prefs.setString('fx_custom', jsonEncode([for (final c in custom) c.toJson()]));
  }
}