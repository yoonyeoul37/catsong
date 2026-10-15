# 앨범·아티스트·재생목록·폴더: 재생·셔플 아이콘을 홈과 같게 (아이폰 모양, 재생 20 / 셔플 17, 연하게 0.5)
import os, sys

MAT = "import 'package:flutter/material.dart';"
CUP = "import 'package:flutter/cupertino.dart';"
W5 = "Color(0x80FFFFFF)"  # 흰색 0.5 (const 그대로 쓸 수 있게)

JOBS = {
    "lib/screens/album_screen.dart": [
        ("재생", "icon: const Icon(Icons.play_arrow, color: Colors.white60, size: 26),",
                 f"icon: const Icon(CupertinoIcons.play_fill, color: {W5}, size: 20),"),
        ("셔플", "icon: const Icon(Icons.shuffle, color: Colors.white60, size: 20),",
                 f"icon: const Icon(CupertinoIcons.shuffle, color: {W5}, size: 17),"),
    ],
    "lib/screens/artist_screen.dart": [
        ("재생", "icon: const Icon(Icons.play_arrow, color: Colors.white60, size: 26),",
                 f"icon: const Icon(CupertinoIcons.play_fill, color: {W5}, size: 20),"),
        ("셔플", "icon: const Icon(Icons.shuffle, color: Colors.white60, size: 20),",
                 f"icon: const Icon(CupertinoIcons.shuffle, color: {W5}, size: 17),"),
    ],
    "lib/screens/playlist_screen.dart": [
        ("재생", "icon: Icon(Icons.play_arrow, color: baseColor.withOpacity(0.6), size: 26),",
                 "icon: Icon(CupertinoIcons.play_fill, color: baseColor.withOpacity(0.5), size: 20),"),
        ("셔플", "icon: Icon(Icons.shuffle, color: baseColor.withOpacity(0.6), size: 20),",
                 "icon: Icon(CupertinoIcons.shuffle, color: baseColor.withOpacity(0.5), size: 17),"),
    ],
    "lib/screens/folder_screen.dart": [
        ("재생", "icon: Icon(Icons.play_arrow, color: baseColor.withOpacity(0.6), size: 26),",
                 "icon: Icon(CupertinoIcons.play_fill, color: baseColor.withOpacity(0.5), size: 20),"),
        ("셔플", "icon: Icon(Icons.shuffle, color: baseColor.withOpacity(0.6), size: 20),",
                 "icon: Icon(CupertinoIcons.shuffle, color: baseColor.withOpacity(0.5), size: 17),"),
    ],
}

results = {}
ok = True
done_all = True
for path, edits in JOBS.items():
    name = os.path.basename(path)
    if not os.path.exists(path):
        print(f"❌ {name} 파일이 없어요 ({path})")
        ok = False
        continue
    text = open(path, "rb").read().decode("utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    already = all(text.count(new) == 1 and old not in text for _, old, new in edits)
    if already:
        print(f"· {name} 이미 적용돼 있어요")
        continue
    done_all = False
    for label, old, new in edits:
        if text.count(old) == 1:
            text = text.replace(old, new)
            print(f"✔ {name} {label}")
        else:
            print(f"❌ {name} {label} 못 찾음")
            ok = False
    if CUP not in text:
        if text.count(MAT) == 1:
            text = text.replace(MAT, MAT + nl + CUP)
            print(f"✔ {name} 아이폰 아이콘 불러오기 줄 추가")
        else:
            print(f"❌ {name} import 자리 못 찾음")
            ok = False
    results[path] = text

if done_all and ok:
    print("이미 적용돼 있어요")
    sys.exit(0)
if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
for path, text in results.items():
    open(path, "wb").write(text.encode("utf-8"))
print("완료")
