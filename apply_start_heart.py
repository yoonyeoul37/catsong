# -*- coding: utf-8 -*-
# 홈 사진 카드 하트(시작 화면): 포인트 색 따라가기 + 취소하면 '취소했어요' (저장했어요처럼 슝)
import os, sys, shutil, re

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw

def balanced(t):
    return all(t.count(a) == t.count(b) for a, b in ('()', '{}', '[]'))

hp, fp = find('home_screen.dart'), find('action_feedback.dart')
if not hp or not fp:
    print('❌ 파일을 못 찾았어요:', 'home_screen.dart' if not hp else 'action_feedback.dart'); sys.exit(1)
h, hc = load(hp)
f, fc = load(fp)
if 'ActionFeedbackType.canceled' in h:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(t, name, a, b):
    global ok
    if t.count(a) == 1:
        print('✔', name); return t.replace(a, b)
    ok = False; print('❌', name, '(찾은 개수: %d)' % t.count(a)); return t

# ── action_feedback.dart: '취소했어요' 종류 추가 ──
f = rep(f, "취소 종류 추가",
        "enum ActionFeedbackType { edited, deleted, saved, added }",
        "enum ActionFeedbackType { edited, deleted, saved, added, canceled }")
f = rep(f, "취소했어요 모양 (빈 하트 · 차분한 회색)",
        "      case ActionFeedbackType.added:\n        return (Icons.add_circle_rounded, blue, '추가했어요');\n",
        "      case ActionFeedbackType.added:\n        return (Icons.add_circle_rounded, blue, '추가했어요');\n      case ActionFeedbackType.canceled:\n        return (Icons.heart_broken_rounded, const Color(0xFF8A8378), '취소했어요');\n")

# ── home_screen.dart: 딱딱한 알림 → 취소했어요 ──
m = re.search(r"      provider\.setStartScreen\(null\);\n      final overlay = Overlay\.of\(context\);\n.*?'시작 화면이 취소되었습니다\.',.*?      Future\.delayed\(const Duration\(seconds: 2\), \(\) => entry\.remove\(\)\);\n", h, re.S)
if m and h.count("'시작 화면이 취소되었습니다.'") == 1:
    h = h[:m.start()] + "      provider.setStartScreen(null);\n      showActionFeedback(context, type: ActionFeedbackType.canceled); // 취소했어요 (저장했어요처럼 슝)\n" + h[m.end():]
    print('✔ 취소 알림을 취소했어요로')
else:
    ok = False; print('❌ 취소 알림을 취소했어요로')

h = rep(h, "하트 색: 포인트 색 따라가기",
        "                                    ? const Color(0xFF6FA8DC)\n",
        "                                    ? (context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8\n                                        ? const Color(0xFF2F7DE8) // 기본이면 로고 파랑\n                                        : context.watch<ThemeProvider>().primaryColor)\n")

if ok and not (balanced(h) and balanced(f)):
    ok = False; print('❌ 괄호 개수가 안 맞아요')
if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
for p, t, c in ((hp, h, hc), (fp, f, fc)):
    shutil.copyfile(p, p + '.bak')
    if c:
        t = t.replace('\n', '\r\n')
    open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
