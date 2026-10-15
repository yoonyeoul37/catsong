# 라디오 목록 글자 크기 버그: 어떤 길로 들어가도 같은 크기(1.25)로 보이게
import sys

S = "MediaQuery(data: MediaQuery.of({c}).copyWith(textScaler: const TextScaler.linear(1.25)), child: {w})"
NOTE = " // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)"

JOBS = [
    ("radio_player_screen.dart · 재생화면 뒤로가기", "lib/screens/radio_player_screen.dart",
     "pageBuilder: (context, animation, secondaryAnimation) => listScreen,",
     "pageBuilder: (context, animation, secondaryAnimation) => " + S.format(c="context", w="listScreen") + "," + NOTE),
    ("overseas_radio_view.dart · 해외 재생화면 뒤로가기", "lib/widgets/overseas_radio_view.dart",
     "pageBuilder: (_, __, ___) => listScreen,",
     "pageBuilder: (ctx, __, ___) => " + S.format(c="ctx", w="listScreen") + "," + NOTE),
    ("radio_home_screen.dart · 나라 고를 때", "lib/screens/radio_home_screen.dart",
     "pageBuilder: (context, animation, secondaryAnimation) => screen,",
     "pageBuilder: (context, animation, secondaryAnimation) => " + S.format(c="context", w="screen") + "," + NOTE),
    ("radio_korea_screen2.dart · 해외 라디오 버튼", "lib/screens/radio_korea_screen2.dart",
     "MaterialPageRoute(builder: (_) => const RadioHomeScreen()),",
     "MaterialPageRoute(builder: (ctx) => " + S.format(c="ctx", w="const RadioHomeScreen()") + ")," + NOTE),
    ("radio_country_stations_screen.dart · 나라 목록 버튼", "lib/screens/radio_country_stations_screen.dart",
     "MaterialPageRoute(builder: (_) => const RadioHomeScreen()),",
     "MaterialPageRoute(builder: (ctx) => " + S.format(c="ctx", w="const RadioHomeScreen()") + ")," + NOTE),
]

texts = {}
ok = True
todo = 0
for label, path, old, new in JOBS:
    if path not in texts:
        try:
            texts[path] = open(path, "rb").read().decode("utf-8")
        except FileNotFoundError:
            print(f"❌ 파일이 없어요 ({path})")
            ok = False
            continue
    t = texts[path]
    if t.count(new) == 1 and old not in t:
        print(f"· {label} 이미 적용돼 있어요")
        continue
    if t.count(old) == 1:
        texts[path] = t.replace(old, new)
        print(f"✔ {label}")
        todo += 1
    else:
        print(f"❌ {label} 못 찾음")
        ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if todo == 0:
    print("이미 적용돼 있어요")
    sys.exit(0)
for path, t in texts.items():
    open(path, "wb").write(t.encode("utf-8"))
print("완료")
