# 메인 홈 카드: 날짜·인사 카드 빼기 (나만의 색 → 지금 방송 → 오늘의 팁, 다 닫으면 오늘은 카드 없음)
import re, sys

PATH = "lib/screens/home_screen.dart"

try:
    raw = open(PATH, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({PATH})")
    sys.exit(1)

crlf = "\r\n" in raw
text = raw.replace("\r\n", "\n")

if "_buildHomeCard" not in text:
    print("❌ 먼저 python apply_home_cards.py 를 돌려 주세요. 아무것도 저장 안 했어요.")
    sys.exit(1)
if "class _SkyBadge" not in text and "// ④ 날짜 + 인사" not in text:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True

def sub(label, pattern, repl):
    global text, ok
    new, n = re.subn(pattern, repl, text, count=1, flags=re.S)
    if n == 1:
        text = new
        print(f"✔ {label}")
    else:
        print(f"❌ {label} 못 찾음")
        ok = False

sub("날짜·인사 카드 빼기",
    r"    // ④ 날짜 \+ 인사 \(마지막 카드라 ✕ 없음\)\n.*?\n    \);\n  \}\n\n  /// 메인 홈 카드 모양",
    "    // 다 닫으면 오늘은 카드 없음 (내일 다시 처음부터)\n    return const SizedBox.shrink();\n  }\n\n  /// 메인 홈 카드 모양")
sub("하늘 그림 빼기",
    r"/// 날짜·인사: 시간대 하늘 \(아침·낮·저녁·밤\)\nclass _SkyBadge .*?\n}\n\n(/// 지금 방송 중)",
    r"\1")
sub("설명 글 고치기 1",
    r"// ───── 메인 홈 카드: 나만의 색 → 지금 방송 → 오늘의 팁 → 날짜·인사 \(마지막, 안 닫힘\) ─────",
    "// ───── 메인 홈 카드: 나만의 색 → 지금 방송 → 오늘의 팁 (✕ 누르면 다음 카드, 내일 다시 처음부터) ─────")
sub("설명 글 고치기 2",
    r"_buildHomeCard\(isDarkMode\), // 나만의 색 → 지금 방송 → 오늘의 팁 → 날짜·인사",
    "_buildHomeCard(isDarkMode), // 나만의 색 → 지금 방송 → 오늘의 팁")

if "_SkyBadge" in text:
    print("❌ 하늘 그림이 아직 남아 있어요")
    ok = False
if text.count("(") != text.count(")") or text.count("{") != text.count("}") or text.count("[") != text.count("]"):
    print("❌ 괄호 짝이 안 맞아요")
    ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)

if crlf:
    text = text.replace("\n", "\r\n")
open(PATH, "wb").write(text.encode("utf-8"))
print("완료")
