import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 홈 위젯 바로가기 (music · radio · nature · sleep)
/// 눌러서 앱이 열리면 홈 화면이 이 값을 보고 그 화면으로 감
class WidgetGo {
  static final target = ValueNotifier<String?>(null);

  /// 앱이 꺼져 있다가 위젯 바로가기로 켜졌는지 (켤 때 한 번 물어봄)
  static Future<void> loadLaunch() async {
    try {
      final t = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('takeWidgetGo');
      if (t != null && t.isNotEmpty) target.value = t;
    } catch (_) {}
  }

  /// 가져가고 비우기
  static String? take() {
    final t = target.value;
    target.value = null;
    return t;
  }
}
