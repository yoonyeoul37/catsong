# -*- coding: utf-8 -*-
# 눌린 하트(꽉 찬 하트) 색을 앱 전체 #E05A4F 빨강 하나로 통일
import os, sys

R = "const Color(0xFFE05A4F)"
EDITS = [
    ("lib/screens/player_screen.dart",
     "color: isFav ? Colors.redAccent : baseColor.withOpacity(0.6),",
     f"color: isFav ? {R} : baseColor.withOpacity(0.6),"),
    ("lib/screens/radio_player_screen.dart",
     "color: radioProvider.isFavorite(current.stationUuid) ? baseColor : baseColor.withOpacity(0.6),",
     f"color: radioProvider.isFavorite(current.stationUuid) ? {R} : baseColor.withOpacity(0.6),"),
    ("lib/screens/all_favorites_screen.dart",
     "Icon(CupertinoIcons.heart_fill, color: primaryColor, size: 20),",
     f"Icon(CupertinoIcons.heart_fill, color: {R}, size: 20),"),
    ("lib/screens/nature_sounds_screen.dart",
     "Icon(CupertinoIcons.heart_fill, color: soundColor, size: 15),",
     f"Icon(CupertinoIcons.heart_fill, color: {R}, size: 15),"),
    ("lib/screens/radio_korea_screen2.dart",
     "? Colors.redAccent\n                        : baseColor.withOpacity(0.35),",
     f"? {R}\n                        : baseColor.withOpacity(0.35),"),
    ("lib/screens/radio_country_stations_screen.dart",
     "? Colors.redAccent\n                        : baseColor.withOpacity(0.25),",
     f"? {R}\n                        : baseColor.withOpacity(0.25),"),
    ("lib/screens/radio_channel_screen.dart",
     "color: isFav ? primaryColor : baseColor.withOpacity(0.4),",
     f"color: isFav ? {R} : baseColor.withOpacity(0.4),"),
    ("lib/widgets/station_tile.dart",
     "color: isFav ? accent : baseColor.withOpacity(0.3),",
     f"color: isFav ? {R} : baseColor.withOpacity(0.3),"),
    ("lib/widgets/overseas_radio_view.dart",
     "color: isFav ? const Color(0xFFE8877E) : Colors.white70,",
     f"color: isFav ? {R} : Colors.white70,"),
]

texts, crlf = {}, {}
ok, done, already = True, 0, 0
for path, old, new in EDITS:
    name = os.path.basename(path)
    if path not in texts:
        if not os.path.exists(path):
            print(f"❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)")
            ok = False
            texts[path] = None
            continue
        raw = open(path, "rb").read().decode("utf-8")
        crlf[path] = "\r\n" in raw
        texts[path] = raw.replace("\r\n", "\n")
    t = texts[path]
    if t is None:
        continue
    c = t.count(old)
    if c == 1:
        texts[path] = t.replace(old, new)
        print(f"✔ {name}")
        done += 1
    elif c == 0 and new in t:
        print(f"✔ {name} - 이미 적용돼 있어요")
        already += 1
    else:
        print(f"❌ {name} - 고칠 곳을 못 찾았어요 ({c}곳)")
        ok = False

if not ok:
    print("\n❌ 문제가 있어서 아무것도 저장하지 않았어요")
    sys.exit(1)
if done == 0:
    print("\n이미 적용돼 있어요")
    sys.exit(0)
for path, t in texts.items():
    out = t.replace("\n", "\r\n") if crlf[path] else t
    open(path, "wb").write(out.encode("utf-8"))
print(f"\n✔ 모두 저장했어요 (하트 {done}곳)")
