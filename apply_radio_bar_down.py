# 라디오 재생 화면: 하단 메뉴 높이는 그대로, 아이콘만 살짝 아래로 (위 진행 막대와 간격 띄우기)
import sys

PATH = "lib/screens/radio_player_screen.dart"
OLD_ITEM = "EdgeInsets.symmetric(horizontal: 12, vertical: 1)"
NEW_ITEM = "EdgeInsets.fromLTRB(12, 4, 12, 0)"
OLD_BAR = "EdgeInsets.fromLTRB(0, 2, 0, 4)"
NEW_BAR = "EdgeInsets.fromLTRB(0, 2, 0, 2)"

try:
    text = open(PATH, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({PATH})")
    sys.exit(1)

if text.count(NEW_ITEM) == 2 and NEW_BAR in text and OLD_ITEM not in text:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
if text.count(OLD_ITEM) == 2:
    text = text.replace(OLD_ITEM, NEW_ITEM)
    print("✔ 아이콘 칸: 위 여백 1 → 4, 아래 여백 1 → 0 (편성표·수면·예약·즐겨찾기 + 종료)")
else:
    print(f"❌ 아이콘 칸 여백 줄을 2개 찾아야 하는데 {text.count(OLD_ITEM)}개 있어요")
    ok = False

if text.count(OLD_BAR) == 1:
    text = text.replace(OLD_BAR, NEW_BAR)
    print("✔ 하단 메뉴 맨 아래 여백 4 → 2 (전체 높이 그대로)")
else:
    print("❌ 하단 메뉴 바깥 여백 줄을 못 찾았어요")
    ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)

open(PATH, "wb").write(text.encode("utf-8"))
print("완료")
