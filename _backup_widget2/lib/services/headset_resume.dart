import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext;
import '../widgets/paran_dialog.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import 'cast_service.dart';

/// 이어폰·블루투스를 연결하면 듣던 것 이어서 듣기
/// 0 끄기 · 1 알림으로 묻기 · 2 바로 재생 (작게 시작해서 천천히 커짐)
class HeadsetResume {
  static final mode = ValueNotifier<int>(0);
  static const names = ['끄기', '알림으로 묻기', '바로 재생'];
  static const _ch = MethodChannel('kr.ssing.catsong/media');
  static PlayerProvider? _pp;
  static RadioProvider? _radio;
  static Timer? _fade;

  static Future<void> init(PlayerProvider pp, RadioProvider radio) async {
    _pp = pp;
    _radio = radio;
    try {
      final p = await SharedPreferences.getInstance();
      mode.value = p.getInt('headsetResumeMode') ?? 0;
    } catch (_) {}
  }

  /// 배터리 사용 "제한 없음" 부탁 — 필요한 기능을 켤 때만, 기능마다 한 번만
  /// (이미 제한 없음이면 안 물어봄)
  static Future<void> askBattery(BuildContext context, String key, String why) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool('battery_ask_$key') ?? false) return;
      final optimized = await _ch.invokeMethod('isBatteryOptimized');
      if (optimized != true || !context.mounted) return;
      await p.setBool('battery_ask_$key', true);
      final go = await showParanConfirm(
        context,
        title: '배터리 사용을 "제한 없음"으로',
        message: why,
        confirmLabel: '허용하기',
        cancelLabel: '나중에',
      );
      if (go) await _ch.invokeMethod('requestBatteryOptimization');
    } catch (_) {}
  }

  static Future<void> setMode(int m) async {
    mode.value = m;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('headsetResumeMode', m);
    } catch (_) {}
  }

  /// 이어서 들을 게 있으면 (종류, 이름) — 없으면 null
  static (String, String)? _target() {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return null;
    if (CastService.instance.isConnected) return null; // TV로 듣는 중
    if (pp.volumeLocked) return null; // 알람 울리는 중
    if (pp.isPlaying || radio.isPlaying || radio.isLoading) return null; // 이미 듣는 중
    final st = radio.currentStation;
    if (st != null) return ('radio', st.name);
    final nature = pp.natureSoundName;
    if (nature != null) return ('nature', nature);
    final song = pp.currentSong;
    if (song != null) return ('music', '${song.titleDisplay} · ${song.artistDisplay}');
    return null;
  }

  /// 안드로이드에서 오는 신호 (연결됨 / 알림의 재생 누름)
  static Future<void> onCall(String method) async {
    if (method == 'onHeadsetResume') {
      await _resume();
      return;
    }
    if (method != 'onHeadsetConnected' || mode.value == 0) return;
    final t = _target();
    if (t == null) return;
    if (mode.value == 1) {
      try {
        await _ch.invokeMethod('showHeadsetAsk', {'title': '이어서 들을까요?', 'text': t.$2});
      } catch (_) {}
    } else {
      await Future.delayed(const Duration(milliseconds: 900)); // 소리 길이 이어폰으로 바뀔 시간
      await _resume();
    }
  }

  static Future<void> _resume() async {
    final t = _target();
    final pp = _pp, radio = _radio;
    if (t == null || pp == null || radio == null) return;
    _fade?.cancel();
    try {
      switch (t.$1) {
        case 'radio':
          await radio.setAlarmVolume(0.05);
          await radio.playStation(radio.currentStation!);
          _rampUp((v) => radio.setAlarmVolume(v));
        case 'nature':
          await pp.player.setVolume(0.05);
          await pp.resumeNatureSound();
          _rampUp((v) => pp.player.setVolume(v));
        default:
          final full = pp.normGain; // 곡마다 소리 크기 맞추기 값까지만
          await pp.player.setVolume(0.05 * full);
          await pp.togglePlayPause();
          _rampUp((v) => pp.player.setVolume(v * full));
      }
    } catch (e) {
      debugPrint('이어서 듣기 오류: $e');
    }
  }

  /// 3초 동안 천천히 원래 크기로 (처음엔 아주 천천히)
  static void _rampUp(void Function(double v) set) {
    var step = 0;
    _fade = Timer.periodic(const Duration(milliseconds: 150), (t) {
      step++;
      final x = (step / 20).clamp(0.0, 1.0);
      set(0.05 + 0.95 * x * x);
      if (step >= 20) t.cancel();
    });
  }
}
