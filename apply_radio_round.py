# 라디오 재생 화면: 위쪽 이미지·다음 방송 칸 둥근 정도를 홈 메뉴 그림(10)과 같게
import sys

PATH = "lib/screens/radio_player_screen.dart"
EDITS = [
    ("위쪽 이미지 20 → 10",
     "return ClipRRect(\n                          borderRadius: BorderRadius.circular(20),",
     "return ClipRRect(\n                          borderRadius: BorderRadius.circular(10), // 홈 메뉴 그림과 같게"),
    ("다음 방송 칸 배경 18 → 10",
     "padding: EdgeInsets.all(widget.compact ? 10 : 14),\n      decoration: BoxDecoration(\n        color: baseColor.withOpacity(0.05),\n        borderRadius: BorderRadius.circular(18),",
     "padding: EdgeInsets.all(widget.compact ? 10 : 14),\n      decoration: BoxDecoration(\n        color: baseColor.withOpacity(0.05),\n        borderRadius: BorderRadius.circular(10), // 홈 메뉴 그림과 같게"),
    ("다음 방송 칸 안 작은 사진 14 → 6",
     "borderRadius: BorderRadius.circular(widget.compact ? 10 : 14),",
     "borderRadius: BorderRadius.circular(6), // 바깥(10)보다 작게"),
]

try:
    raw = open(PATH, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({PATH})")
    sys.exit(1)

crlf = "\r\n" in raw
text = raw.replace("\r\n", "\n")

if all(text.count(new) == 1 and old not in text for _, old, new in EDITS):
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
for label, old, new in EDITS:
    if text.count(old) == 1:
        text = text.replace(old, new)
        print(f"✔ {label}")
    else:
        print(f"❌ {label} 못 찾음")
        ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)

if crlf:
    text = text.replace("\n", "\r\n")
open(PATH, "wb").write(text.encode("utf-8"))
print("완료")
