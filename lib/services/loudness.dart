import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 곡마다 소리 크기 맞추기 (볼륨 평준화)
/// 곡 가운데 몇 군데를 잠깐 들어 보고 소리 크기(dB)를 재서 폰에 기억
/// → 큰 곡만 조금 줄여서 다른 곡들과 비슷하게 (작은 곡은 키우지 않음: 소리가 찢어질 수 있어서)
class Loudness {
  static const _ch = MethodChannel('kr.ssing.catsong/media');
  static const _keyOn = 'loudnessOn';
  static const _keyDb = 'loudnessDb';

  /// 맞출 크기 (이보다 큰 곡만 줄임)
  static const target = -14.0;

  /// 아무리 커도 이 정도까지만 줄임
  static const minGain = 0.45;

  /// 설정 → 곡마다 소리 크기 맞추기 (기본 켜짐)
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  static final Map<String, double> _db = {};
  static final Set<String> _busy = {};
  static bool _loaded = false;
  static Timer? _saveTimer;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_keyOn) ?? true;
      final s = p.getString(_keyDb);
      if (s != null) {
        (jsonDecode(s) as Map).forEach((k, v) {
          if (v is num) _db[k.toString()] = v.toDouble();
        });
      }
    } catch (_) {}
  }

  static Future<void> setEnabled(bool v) async {
    enabled.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyOn, v);
  }

  /// 전에 잰 크기 (없으면 null)
  static double? cached(String uri) => _db[uri];

  /// 곡 크기 → 소리 비율 (큰 곡만 줄임, 0.45 ~ 1.0)
  static double gainFor(double db) {
    final diff = target - db;
    if (diff >= 0) return 1.0;
    return math.pow(10, diff / 20).toDouble().clamp(minGain, 1.0);
  }

  /// 소리 크기 재기 (한 곡에 한 번만, 결과는 폰에 기억)
  static Future<double?> measure(String uri) async {
    final c = _db[uri];
    if (c != null) return c;
    if (!_busy.add(uri)) return null; // 이미 재는 중
    try {
      final r = await _ch.invokeMethod('measureLoudness', {'path': uri});
      if (r is num && r.isFinite && r > -80) {
        _db[uri] = r.toDouble();
        _scheduleSave();
        return r.toDouble();
      }
    } catch (_) {
    } finally {
      _busy.remove(uri);
    }
    return null;
  }

  /// 여러 곡을 연달아 재도 저장은 한 번에
  static void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () async {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_keyDb, jsonEncode(_db));
      } catch (_) {}
    });
  }
}
