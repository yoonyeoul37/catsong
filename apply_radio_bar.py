# 라디오 재생 화면: 하단 메뉴 높이 조금 더 줄이기 (가운데 배치는 그대로)
import sys

PATH = "lib/screens/radio_player_screen.dart"
OLD_PAD = "EdgeInsets.symmetric(horizontal: 12, vertical: 4)"
NEW_PAD = "EdgeInsets.symmetric(horizontal: 12, vertical: 1)"
OLD_H = "final h = constraints.maxHeight - 8; // 하단바 줄인 만큼 빼서 가운데 배치는 그대로"
NEW_H = "final h = constraints.maxHeight - 14; // 하단바 줄인 만큼 빼서 가운데 배치는 그대로"

try:
    text = open(PATH, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({PATH})")
    sys.exit(1)

if text.count(NEW_PAD) == 2 and NEW_H in text:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
if text.count(OLD_PAD) == 2:
    text = text.replace(OLD_PAD, NEW_PAD)
    print("✔ 하단 메뉴 칸 위아래 여백 4 → 1 (편성표·수면·예약·즐겨찾기 + 종료)")
else:
    print(f"❌ 하단 메뉴 여백 줄을 2개 찾아야 하는데 {text.count(OLD_PAD)}개 있어요")
    ok = False

if text.count(OLD_H) == 1:
    text = text.replace(OLD_H, NEW_H)
    print("✔ 가운데 화면 계산 높이 -8 → -14")
else:
    print("❌ final h = constraints.maxHeight - 8; 줄을 못 찾았어요")
    ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)

open(PATH, "wb").write(text.encode("utf-8"))
print("완료")
