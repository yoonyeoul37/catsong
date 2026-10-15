# '수면 · 명상' → '휴식 · 집중' (홈 메뉴 + 상세 화면 + 즐겨찾기 탭)
import sys

JOBS = [
    ("lib/screens/home_screen.dart", [
        ("홈 메뉴 이름·설명",
         "_DashboardCategory('수면 · 명상', '백색소음 · 명상음 (준비중)',",
         "_DashboardCategory('휴식 · 집중', '백색소음 · 집중 소리 (준비중)',"),
    ]),
    ("lib/screens/sleep_focus_screen.dart", [
        ("상세 위쪽 탭",
         "final categories = ['전체', '수면', '명상', '백색소음', '기타'];",
         "final categories = ['전체', '휴식', '집중', '백색소음', '기타'];"),
        ("상세 제목 앞 글자",
         "text: '수면',",
         "text: '휴식',"),
        ("상세 제목 뒤 글자",
         "text: ' · 명상',",
         "text: ' · 집중',"),
        ("상세 제목 아래 설명",
         "'편안한 소리로 잠들고, 마음을 가다듬어보세요',",
         "'편안한 소리로 쉬고, 마음을 모아 집중해 보세요',"),
    ]),
    ("lib/screens/all_favorites_screen.dart", [
        ("즐겨찾기 탭 이름",
         "const Tab(text: '수면 · 집중(0)'),",
         "const Tab(text: '휴식 · 집중(0)'),"),
        ("즐겨찾기 빈 화면 문구",
         "'수면 · 집중 기능은 준비중이에요'",
         "'휴식 · 집중 기능은 준비중이에요'"),
    ]),
]

texts = {}
ok = True
todo = 0
for path, edits in JOBS:
    try:
        t = open(path, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({path})")
        ok = False
        continue
    name = path.split("/")[-1]
    for label, old, new in edits:
        if t.count(new) == 1 and old not in t:
            print(f"· {name} {label} 이미 적용돼 있어요")
        elif t.count(old) == 1:
            t = t.replace(old, new)
            print(f"✔ {name} {label}")
            todo += 1
        else:
            print(f"❌ {name} {label} 못 찾음")
            ok = False
    texts[path] = t

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if todo == 0:
    print("이미 적용돼 있어요")
    sys.exit(0)
for path, t in texts.items():
    open(path, "wb").write(t.encode("utf-8"))
print("완료")
