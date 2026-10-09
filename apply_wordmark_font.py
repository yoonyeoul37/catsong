# -*- coding: utf-8 -*-
# 작은 영문 이름(Paransori)을 Quicksand로 통일 (기울임 빼고 바로 세움)
# 홈 로고 밑 · 재생화면 맨 위 · 가사 화면 워터마크
import os, sys

EDITS = [
    ("lib/screens/home_screen.dart",
"""                          'Paransori',
                          style: TextStyle(
                              color: baseColor.withOpacity(0.55),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.3),""",
"""                          'Paransori',
                          style: GoogleFonts.quicksand(
                              color: baseColor.withOpacity(0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6),"""),
    ("lib/screens/player_screen.dart",
"""                          style: GoogleFonts.playfairDisplay(
    color: sky.withOpacity(0.8), fontSize: 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, height: 1.0, letterSpacing: 0.4),""",
"""                          style: GoogleFonts.quicksand(
    color: sky.withOpacity(0.8), fontSize: 22, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.6),"""),
    ("lib/screens/player_screen.dart",
"""                          style: GoogleFonts.playfairDisplay(
                              color: baseColor.withOpacity(0.42), fontSize: 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, height: 1.0, letterSpacing: 0.4),""",
"""                          style: GoogleFonts.quicksand(
                              color: baseColor.withOpacity(0.42), fontSize: 22, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.6),"""),
    ("lib/screens/lyrics_screen.dart",
"""    // 영어만, 우아한 기울임 세리프체 (로고처럼)
    return Text(
      'Paransori',
      style: GoogleFonts.playfairDisplay(
          color: c,
          fontSize: 17 * scale,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6 * scale,
          shadows: shadow),""",
"""    // 영어 이름은 앱 전체 Quicksand로 통일 (바로 세움)
    return Text(
      'Paransori',
      style: GoogleFonts.quicksand(
          color: c,
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8 * scale,
          shadows: shadow),"""),
]

texts, crlf = {}, {}
ok, done = True, 0
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
print(f"\n✔ 모두 저장했어요 ({done}곳)")
