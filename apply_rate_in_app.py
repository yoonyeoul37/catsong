# -*- coding: utf-8 -*-
# '앱 평가하기': 앱 안에서 바로 별점 (구글 평가 창) · 안 뜨면 지금처럼 플레이 스토어로
import os, sys

def find(name):
    for r, _, fs in os.walk('lib'):
        if name in fs: return os.path.join(r, name)
    return None

PUB = 'pubspec.yaml'
HOME = find('home_screen.dart')
RPS = find('radio_player_screen.dart')
NEW = os.path.join('lib', 'utils', 'rate_app.dart')
for n, p in [('pubspec.yaml', PUB if os.path.exists(PUB) else None), ('home_screen.dart', HOME), ('radio_player_screen.dart', RPS)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)
if not os.path.isdir(os.path.join('lib', 'utils')):
    print('❌ lib/utils 폴더를 못 찾았어요'); sys.exit(1)

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

pub, PNL = load(PUB)
hs, HNL = load(HOME)
rs, RNL = load(RPS)
if 'in_app_review' in pub and os.path.exists(NEW):
    print('이미 적용돼 있어요'); sys.exit(0)

STORE_OPEN_H = (
 "                                    final uri = Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong');\n"
 "                                    if (await canLaunchUrl(uri)) {\n"
 "                                      await launchUrl(uri, mode: LaunchMode.externalApplication);\n"
 "                                    }\n")
STORE_OPEN_R = (
 "                                                            final uri = Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong');\n"
 "                                                            if (await canLaunchUrl(uri)) {\n"
 "                                                              await launchUrl(uri, mode: LaunchMode.externalApplication);\n"
 "                                                            }\n")

pub_steps = [('[pubspec.yaml] 구글 앱 안 평가 패키지',
  "  in_app_update: ^5.0.0\n",
  "  in_app_update: ^5.0.0\n"
  "  in_app_review: ^2.0.12 # '앱 평가하기': 앱 안에서 바로 별점\n")]
home_steps = [
 ('[home_screen] rate_app 불러오기',
  "import 'package:permission_handler/permission_handler.dart';\n",
  "import 'package:permission_handler/permission_handler.dart';\n"
  "import '../utils/rate_app.dart';\n"),
 ('[home_screen] ⋮ 메뉴 앱 평가하기 → 앱 안에서',
  STORE_OPEN_H,
  "                                    await RateApp.open(); // 앱 안에서 바로 별점 (안 뜨면 플레이 스토어로)\n"),
]
rps_steps = [
 ('[radio_player_screen] rate_app 불러오기',
  "import '../l10n/locale_holder.dart';\n",
  "import '../l10n/locale_holder.dart';\n"
  "import '../utils/rate_app.dart';\n"),
 ('[radio_player_screen] ⋮ 메뉴 앱 평가하기 → 앱 안에서',
  STORE_OPEN_R,
  "                                                            await RateApp.open(); // 앱 안에서 바로 별점 (안 뜨면 플레이 스토어로)\n"),
]

NEW_CODE = r'''import 'package:in_app_review/in_app_review.dart';
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
'''

def apply(s, nl, steps):
    ok = True
    for name, old, new in steps:
        o = old.replace('\n', nl); n = new.replace('\n', nl)
        c = s.count(o)
        if c == 1:
            s = s.replace(o, n); print('✔', name)
        else:
            ok = False; print('❌', name, '(찾은 개수: %d)' % c)
    return s, ok

pub, a = apply(pub, PNL, pub_steps)
hs, b = apply(hs, HNL, home_steps)
rs, c = apply(rs, RNL, rps_steps)
if not (a and b and c):
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(PUB, 'wb').write(pub.encode('utf-8'))
open(HOME, 'wb').write(hs.encode('utf-8'))
open(RPS, 'wb').write(rs.encode('utf-8'))
open(NEW, 'wb').write(NEW_CODE.replace('\n', HNL).encode('utf-8'))
print('✔ 새 파일 만들었어요:', NEW)
print('저장했어요')
