import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// '앱 평가하기' 버튼: 앱 안에서 바로 별점 (구글 평가 창) → 안 뜨면 지금처럼 플레이 스토어로
/// - 구글은 평가 창을 자주 못 띄우게 막아 둠 (이미 평가했거나 최근에 떴으면 안 뜸)
///   → 한 달 안에 다시 누르면 바로 스토어로 · 창이 안 뜨고 바로 끝나면 스토어로 (버튼이 먹통이 되지 않게)
/// - 창 모양·글자는 구글이 정함 (바꿀 수 없음)
class RateApp {
  static const _store = 'https://play.google.com/store/apps/details?id=kr.ssing.catsong';
  static const _key = 'in_app_review_at'; // 마지막으로 앱 안 평가 창을 띄워 본 때

  static Future<void> open() async {
    var shown = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs.getInt(_key) ?? 0;
      final recent = now - last < const Duration(days: 30).inMilliseconds;
      final review = InAppReview.instance;
      if (!recent && await review.isAvailable()) {
        await prefs.setInt(_key, now);
        final sw = Stopwatch()..start();
        await review.requestReview();
        // 창이 떴으면 사용자가 닫을 때까지 기다렸다 끝남 · 안 떴으면 거의 바로 끝남
        shown = sw.elapsedMilliseconds > 1200;
      }
    } catch (_) {}
    if (shown) return;
    try {
      await launchUrl(Uri.parse(_store), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
