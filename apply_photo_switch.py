# 음악 재생화면 파란포토 창: 랜덤·고정 버튼 → 가사 배경 창과 똑같은 '노래마다 바꾸기' 스위치
#  - 켜기 = 랜덤(노래마다 다른 사진, 고른 사진이 있으면 그 사진들만)
#  - 끄기 = 고정(사진을 누르면 그 한 장으로)
#  - 모양·글자·설명 문구 모두 가사 배경 창과 같게
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


p = one("player_screen.dart")
raw = open(p, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")

if "// 🔀 노래마다 바꾸기 (가사 배경 창과 같은 스위치)" in s:
    print("이미 적용돼 있어요")
    sys.exit(0)

start = "            // 자동 · 랜덤 · 고정 (한 덩어리 칸, 고른 칸만 하얗게)\n"
end = """            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(modeHint, style: TextStyle(color: sub, fontSize: 11.5)),
            ),
"""
ok = True
if s.count(start) != 1 or s.count(end) != 1 or s.index(end) < s.index(start):
    print(f"❌ player_screen.dart: 랜덤·고정 버튼 자리를 못 찾았어요 (시작 {s.count(start)}곳, 끝 {s.count(end)}곳)")
    ok = False
else:
    a = s.index(start)
    b = s.index(end) + len(end)
    block = s[a:b]
    if "for (final m in const [" not in block:
        print("❌ player_screen.dart: 버튼 모양이 예상과 달라요")
        ok = False
    else:
        new = """            // 🔀 노래마다 바꾸기 (가사 배경 창과 같은 스위치)
            //  켜기 = 노래마다 다른 사진 (고른 사진이 있으면 그 사진들만) / 끄기 = 누른 사진 한 장으로
            ParanCard(
              children: [
                InkWell(
                  onTap: () {
                    tick();
                    _setPhotoMode(_photoMode == 1 ? 2 : 1).then((_) {
                      if (ctx.mounted) setSheet(() {});
                    });
                    setSheet(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        SizedBox(width: 22, child: Icon(Icons.shuffle_rounded, color: sub, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('노래마다 바꾸기',
                                  style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                  _photoMode != 1
                                      ? '노래가 바뀔 때마다 다른 사진'
                                      : picksNow.isEmpty
                                          ? '원하는 사진을 선택해 보세요'
                                          : '고른 사진 ${picksNow.length}장 중에서 · 다시 누르면 빠져요',
                                  style: TextStyle(color: sub, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _photoMode == 1,
                          onChanged: (v) {
                            tick();
                            _setPhotoMode(v ? 1 : 2).then((_) {
                              if (ctx.mounted) setSheet(() {});
                            });
                            setSheet(() {});
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
        s = s[:a] + new + s[b:]
        print("✔ player_screen.dart: 랜덤·고정 버튼 → '노래마다 바꾸기' 스위치")

# 설명 줄은 스위치 안으로 옮겼으니 계산만 남은 것 지우기 (경고 안 나게)
mh_a = s.find("        final modeHint = _photoMode == 0\n")
mh_b = s.find("                : '고른 사진 한 장만 계속 보여요';\n")
if ok:
    if mh_a < 0 or mh_b < 0 or mh_b < mh_a or "modeHint" in s[mh_b:]:
        print("❌ player_screen.dart: 예전 설명 줄 계산을 못 찾았어요")
        ok = False
    else:
        s = s[:mh_a] + s[mh_b + len("                : '고른 사진 한 장만 계속 보여요';\n"):]
        print("✔ player_screen.dart: 예전 설명 줄 정리")

# 안 쓰게 된 값도 정리 (노란 경고 안 나게)
if ok:
    for old in ("        // 모드 설명 한 줄\n        final tc = _timeCategory();\n"
                "        final hasTime = (_nightCategoryPhotos[tc] ?? const <String>[]).isNotEmpty;\n"
                "        final rangeName = _photoRange.isEmpty ? (_catOf(_nightBgPath) ?? '같은 카테고리') : _photoRange;\n",
                "        final segBg = dark ? const Color(0xFF2E2C28) : const Color(0xFFEDE6D8);\n"):
        if s.count(old) == 1:
            s = s.replace(old, "")
            print("✔ player_screen.dart: 안 쓰는 값 정리")
        else:
            print("❌ player_screen.dart: 안 쓰는 값을 못 찾았어요")
            ok = False

for nm, x, y in (("{}", "{", "}"), ("()", "(", ")"), ("[]", "[", "]")):
    if s.count(x) != s.count(y):
        print(f"❌ player_screen.dart: 괄호 {nm} 짝이 안 맞아요")
        ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)
if crlf:
    s = s.replace("\n", "\r\n")
open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
