import 'dart:ui' show DisplayFeatureType;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// SOS 긴급 신호 — 설정에서 켜면 앱 어느 화면에서든 계속 깜빡임
/// 끄기: 설정 스위치 · 위쪽 빨간 'SOS ✕' 띠 · 앱 밖(폰 홈 화면)으로 나가기
/// (앱 밖에서는 삼성 '손전등' 표시 때문에 폰 상단 줄이 흔들려서 끔)
class SosService with WidgetsBindingObserver {
  SosService._();
  static final SosService _i = SosService._();

  /// 켜졌는지 (설정 스위치·위쪽 띠가 보고 바뀜)
  static final ValueNotifier<bool> on = ValueNotifier(false);
  static bool get isOn => on.value;

  static int _run = 0; // 켤 때마다 번호 (껐다 바로 켜도 예전 깜빡임이 섞이지 않게)
  static bool _observing = false;

  // ··· ─── ··· (짧게 3번 · 길게 3번 · 짧게 3번)
  static const _p = [200, 200, 200, 200, 200, 400, 600, 200, 600, 200, 600, 400, 200, 200, 200, 200, 200, 800];

  static Future<void> start() async {
    if (on.value) return;
    on.value = true;
    final run = ++_run;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(_i);
      _observing = true;
    }
    // 상단 줄 숨기기 (아래 줄은 그대로) · 화면 꺼지지 않게
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
    WakelockPlus.enable().catchError((Object _) {});
    try {
      while (on.value && run == _run) {
        for (int i = 0; i < _p.length; i++) {
          if (!on.value || run != _run) break;
          if (i.isEven) {
            await TorchLight.enableTorch();
          } else {
            await TorchLight.disableTorch();
          }
          await Future.delayed(Duration(milliseconds: _p[i]));
        }
      }
    } catch (_) {
      // 손전등을 못 쓰는 폰 → 끄기
      if (run == _run) await stop();
    }
    // 끈 뒤 마지막 깜빡임이 켜진 채로 남지 않게 (그 사이 다시 켰으면 새 깜빡임에 맡김)
    if (!on.value) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
    }
  }

  static Future<void> stop() async {
    if (!on.value) return;
    on.value = false;
    _run++;
    // 상단 줄 다시 보이기 · 화면 꺼짐 원래대로
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    WakelockPlus.disable().catchError((Object _) {});
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) stop(); // 앱 밖으로 나가면 끄기
  }
}

/// SOS가 켜져 있는 동안 위쪽(숨긴 상단 줄 자리)에 뜨는 작은 빨간 띠 — 누르면 SOS 끄기
/// 글자는 'SOS'만 써서 어느 언어나 같게
class SosBanner extends StatelessWidget {
  const SosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SosService.on,
      builder: (context, isOn, _) {
        if (!isOn) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        final top = mq.padding.top;
        const h = 28.0; // 조금 크게 (긴급할 때 누르기 쉽게)
        // 카메라 구멍 피하기: 구멍이 가운데·오른쪽이면 왼쪽 위(시계 자리), 왼쪽이면 오른쪽 위
        var right = false;
        for (final f in mq.displayFeatures) {
          if (f.type == DisplayFeatureType.cutout && f.bounds.top < top + 1) {
            right = f.bounds.center.dx < mq.size.width * 0.35;
          }
        }
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            // 상단 줄 자리 (자리가 좁으면 맨 위에서 2) · 옆 끝에서 16
            // 누르는 자리를 둘레 8씩 넓힌 만큼(아래 margin) 빼기
            padding: EdgeInsets.only(top: ((top > h + 4 ? (top - h) / 2 : 2.0) - 8).clamp(0.0, 100.0).toDouble(), left: 8, right: 8),
            child: Align(
              alignment: right ? Alignment.topRight : Alignment.topLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  SosService.stop();
                },
                child: Container(
                  height: h,
                  margin: const EdgeInsets.all(8), // 보이는 띠보다 누르는 자리를 넓게
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD84A3A), // LIVE와 같은 빨강
                    borderRadius: BorderRadius.circular(h / 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SOS',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.close_rounded, size: 17, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}