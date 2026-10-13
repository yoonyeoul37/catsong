import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 홈 위젯 바로가기 (music · radio · nature · sleep)
/// 눌러서 앱이 열리면 홈 화면이 이 값을 보고 그 화면으로 감
class WidgetGo {
  static final target = ValueNotifier<String?>(null);
  /// 이번에 위젯으로 켜졌는지 (첫인사 목소리 안 하게)
  static bool launched = false;

  /// 앱이 꺼져 있다가 위젯 바로가기로 켜졌는지 (켤 때 한 번 물어봄)
  static Future<void> loadLaunch() async {
    for (var k = 0; k < 5; k++) {
      try {
        final t = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('takeWidgetGo');
        if (t != null && t.isNotEmpty) {
          launched = true;
          target.value = t;
        }
        return;
      } on MissingPluginException {
        await Future.delayed(const Duration(milliseconds: 150)); // 안드로이드 쪽이 아직 준비 중
      } catch (_) {
        return;
      }
    }
  }

  /// 가져가고 비우기
  static String? take() {
    final t = target.value;
    target.value = null;
    return t;
  }
}
