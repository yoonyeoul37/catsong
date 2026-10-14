# 사진 바꾸는 방식: 작은 스위치 + 옆에 '랜덤' / '고정' 글자와 설명 (음악 재생화면 · 가사 배경 똑같이)
#  - 스위치 켜짐 → 랜덤 : 노래가 바뀔 때마다 사진이 바뀌어요
#  - 스위치 꺼짐 → 고정 : 고른 사진 한 장만 계속 보여요
#  (전에 받은 apply_photo_switch.py · 예전 apply_random_fixed.py 를 실행했어도, 안 했어도 괜찮아요)
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")


def one(name):
    hits = []
    for d, dirs, files in os.walk(os.path.join(ROOT, "lib")):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        if name in files:
            hits.append(os.path.normpath(os.path.join(d, name)))
    if len(hits) != 1:
        print(f"❌ {name} 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
        sys.exit(1)
    return hits[0]


def read(p):
    raw = open(p, "rb").read().decode("utf-8")
    return raw.replace("\r\n", "\n"), "\r\n" in raw


ps, ly = one("player_screen.dart"), one("lyrics_screen.dart")
ps_s, ps_c = read(ps)
ly_s, ly_c = read(ly)
MARK = "// 랜덤 · 고정 스위치 (음악 재생화면 · 가사 배경 같은 모양)"
if MARK in ps_s and MARK in ly_s:
    print("이미 적용돼 있어요")
    sys.exit(0)
ok = True

CARD = """            // 랜덤 · 고정 스위치 (음악 재생화면 · 가사 배경 같은 모양)
            ParanCard(
              children: [
                InkWell(
                  onTap: () {
                    __SET_TOGGLE__
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 22,
                            child: Icon(__ON__ ? Icons.shuffle_rounded : Icons.push_pin_outlined,
                                color: sub, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(__ON__ ? '랜덤' : '고정',
                                  style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(__ON__ ? '노래가 바뀔 때마다 사진이 바뀌어요' : '고른 사진 한 장만 계속 보여요',
                                  style: TextStyle(color: sub, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Switch(
                          value: __ON__,
                          onChanged: (v) {
                            __SET_V__
                          },
                          activeColor: Theme.of(ctx).colorScheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
"""


def cut(src, starts, end, name):
    """starts 중 하나에서 end 바로 앞까지를 찾기"""
    global ok
    st = [x for x in starts if src.count(x) == 1]
    if len(st) != 1 or src.count(end) != 1 or src.index(end) < src.index(st[0]):
        print(f"❌ {name}: 사진 바꾸기 버튼 자리를 못 찾았어요")
        ok = False
        return None
    return src.index(st[0]), src.index(end)


# ───────── player_screen.dart ─────────
if MARK in ps_s:
    print("✔ player_screen.dart: 이미 되어 있어요")
else:
    r = cut(ps_s,
            ["            // 🔀 노래마다 바꾸기 (가사 배경 창과 같은 스위치)\n",
             "            // 랜덤 | 고정 (음악 재생화면 · 가사 배경 같은 모양)\n",
             "            // 자동 · 랜덤 · 고정 (한 덩어리 칸, 고른 칸만 하얗게)\n"],
            "            const SizedBox(height: 14),\n            // 카테고리: 작은 사진 + 이름 (옆으로 넘기기)\n",
            "player_screen.dart")
    if r:
        new = (CARD.replace("__ON__", "(_photoMode == 1)")
                   .replace("__SET_TOGGLE__", """tick();
                    _setPhotoMode(_photoMode == 1 ? 2 : 1).then((_) {
                      if (ctx.mounted) setSheet(() {});
                    });
                    setSheet(() {});""")
                   .replace("__SET_V__", """tick();
                            _setPhotoMode(v ? 1 : 2).then((_) {
                              if (ctx.mounted) setSheet(() {});
                            });
                            setSheet(() {});"""))
        ps_s = ps_s[:r[0]] + new + ps_s[r[1]:]
        print("✔ player_screen.dart: 스위치 + '랜덤' / '고정' 설명으로")
        # 안 쓰게 된 값 정리 (노란 경고 안 나게)
        mh_a = ps_s.find("        final modeHint = _photoMode == 0\n")
        mh_end = "                : '고른 사진 한 장만 계속 보여요';\n"
        if mh_a >= 0:
            mh_b = ps_s.find(mh_end, mh_a)
            if mh_b < 0:
                print("❌ player_screen.dart: 예전 설명 줄을 못 지웠어요")
                ok = False
            else:
                ps_s = ps_s[:mh_a] + ps_s[mh_b + len(mh_end):]
        for old in ("        // 모드 설명 한 줄\n        final tc = _timeCategory();\n"
                    "        final hasTime = (_nightCategoryPhotos[tc] ?? const <String>[]).isNotEmpty;\n"
                    "        final rangeName = _photoRange.isEmpty ? (_catOf(_nightBgPath) ?? '같은 카테고리') : _photoRange;\n",
                    "        final segBg = dark ? const Color(0xFF2E2C28) : const Color(0xFFEDE6D8);\n"):
            if ps_s.count(old) == 1:
                ps_s = ps_s.replace(old, "")
        if "modeHint" in ps_s:
            print("❌ player_screen.dart: 예전 설명 줄이 남아 있어요")
            ok = False

# ───────── lyrics_screen.dart ─────────
if MARK in ly_s:
    print("✔ lyrics_screen.dart: 이미 되어 있어요")
else:
    r = cut(ly_s,
            ["            // 🔀 노래마다 바꾸기 (스위치 — 설정 화면 스위치와 같은 모양)\n",
             "            // 랜덤 | 고정 (음악 재생화면 · 가사 배경 같은 모양)\n"],
            "            // ── 내 사진 ──\n",
            "lyrics_screen.dart")
    if r:
        new = (CARD.replace("__ON__", "_random")
                   .replace("__SET_TOGGLE__", "_setRandom(!_random, setSheet);")
                   .replace("__SET_V__", "_setRandom(v, setSheet);"))
        ly_s = ly_s[:r[0]] + new + ly_s[r[1]:]
        print("✔ lyrics_screen.dart: '노래마다 바꾸기' → 스위치 + '랜덤' / '고정' 설명으로")

for nm, src in (("player_screen.dart", ps_s), ("lyrics_screen.dart", ly_s)):
    for x, y in (("{", "}"), ("(", ")"), ("[", "]")):
        if src.count(x) != src.count(y):
            print(f"❌ {nm}: 괄호 {x}{y} 짝이 안 맞아요")
            ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)
for p, s, c in ((ps, ps_s, ps_c), (ly, ly_s, ly_c)):
    if c:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
