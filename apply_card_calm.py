# 메인 홈 알림 카드: 강조 색 빼기 (이름표 = 회색 굵은 글자, 지금 카드 점 = 먹색) → 색은 왼쪽 동그라미 그림만
import sys

H = "lib/screens/home_screen.dart"

EDITS = [
    ("이름표 회색",
     "                        style: TextStyle(color: accent, fontSize: 10, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: 0.6)),\n",
     "                        style: TextStyle(color: subC, fontSize: 10, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: 0.6)),\n"),
    ("점 먹색 (다크는 크림색)",
     "_cardDots(dot, dots, accent, subC.withOpacity(0.35))",
     "_cardDots(dot, dots, ink, subC.withOpacity(0.3))"),
    ("안 쓰게 된 강조 색 정리",
     "    final point = context.watch<ThemeProvider>().primaryColor;\n"
     "    final accent = _readable(\n"
     "        point.value == 0xFF2589E8\n"
     "            ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))\n"
     "            : point,\n"
     "        isDark);\n"
     "    final showDots = dots > 1;\n",
     "    final showDots = dots > 1; // 색은 왼쪽 동그라미 그림만 (이름표·점은 회색·먹색)\n"),
]

try:
    raw = open(H, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({H})")
    sys.exit(1)
crlf = "\r\n" in raw
t = raw.replace("\r\n", "\n")

if "_cardDots(dot, dots, ink, subC.withOpacity(0.3))" in t:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
for label, old, new in EDITS:
    if t.count(old) == 1:
        t = t.replace(old, new)
        print(f"✔ {label}")
    else:
        print(f"❌ {label} 못 찾음")
        ok = False

if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
    print("❌ 괄호 짝이 안 맞아요")
    ok = False
if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if crlf:
    t = t.replace("\n", "\r\n")
open(H, "wb").write(t.encode("utf-8"))
print("완료")
