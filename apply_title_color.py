# -*- coding: utf-8 -*-
# 자연 · 수면 · 나만의 소리 제목: 홈 로고와 같은 규칙
#  - 포인트 색이 기본(파란소리)이면 앞 글자만 파랗게 (지금 그대로)
#  - 다른 포인트 색이면 제목 전체를 먹색(다크는 흰색), 옆 이퀄라이저만 포인트 색
# + 자연 목록 '듣는 중' 막대도 포인트 색 따라가기 (기본이면 지금 파랑 그대로)
import os, sys

BLUE_OR_INK = "context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : baseColor"

EDITS = [
    ("lib/screens/nature_sounds_screen.dart",
"""                        text: '자연',
                        style: GoogleFonts.doHyeon(
                            color: const Color(0xFF2F7DE8), fontSize: 20),""",
f"""                        text: '자연',
                        style: GoogleFonts.doHyeon(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: {BLUE_OR_INK}, fontSize: 20),"""),
    ("lib/screens/nature_sounds_screen.dart",
"""                          _NatureEqBars(
                            color: isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8),
                          )""",
"""                          _NatureEqBars(
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                                ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
                                : context.watch<ThemeProvider>().primaryColor,
                          )"""),
    ("lib/screens/sleep_focus_screen.dart",
"""                        text: '수면',
                        style: GoogleFonts.doHyeon(
                            color: const Color(0xFF2F7DE8), fontSize: 19),""",
f"""                        text: '수면',
                        style: GoogleFonts.doHyeon(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: {BLUE_OR_INK}, fontSize: 19),"""),
    ("lib/screens/sound_mix_screen.dart",
"""                    text: '나만의',
                    style: GoogleFonts.doHyeon(
                        color: const Color(0xFF2F7DE8), fontSize: 20, letterSpacing: -0.5),""",
f"""                    text: '나만의',
                    style: GoogleFonts.doHyeon(
                        // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                        color: {BLUE_OR_INK}, fontSize: 20, letterSpacing: -0.5),"""),
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
    if new in t:
        print(f"✔ {name} - 이미 적용돼 있어요")
    elif t.count(old) == 1:
        texts[path] = t.replace(old, new)
        print(f"✔ {name}")
        done += 1
    else:
        print(f"❌ {name} - 고칠 곳을 못 찾았어요 ({t.count(old)}곳)")
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
