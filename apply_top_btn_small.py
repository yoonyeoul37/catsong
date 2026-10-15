# 위쪽 동그란 버튼을 홈과 같게 (배경 29 · 아이콘 13): 라디오 재생 화면 · 자연소리 재생 화면 · 믹스 화면
import re, sys

R = "lib/screens/radio_player_screen.dart"
N = "lib/screens/nature_sound_detail_screen.dart"
M = "lib/screens/sound_mix_screen.dart"

def load(p):
    try:
        raw = open(p, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({p})")
        return None
    return [raw.replace("\r\n", "\n"), "\r\n" in raw]

files = {}
for p in (R, N, M):
    f = load(p)
    if f is None:
        print("❌ 아무것도 저장 안 했어요.")
        sys.exit(1)
    files[p] = f

ok = True
todo = 0

# ── 라디오: _FloatButton 하나만 바꾸면 위쪽 버튼 6개가 다 같이 (안 아이콘 16 → 13 크기로 줄여 보이기)
R_OLD = """      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withOpacity(0.07),
          border: Border.all(color: baseColor.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),"""
R_NEW = """      child: Container(
        width: 29, height: 29, // 홈 위쪽 버튼과 같게
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withOpacity(0.07),
          border: Border.all(color: baseColor.withOpacity(0.08)),
        ),
        child: Center(child: Transform.scale(scale: 13 / 16, child: child)), // 아이콘 16 → 13
      ),"""
t = files[R][0]
if R_NEW in t:
    print("· 라디오 재생 화면 이미 적용돼 있어요")
elif t.count(R_OLD) == 1:
    files[R][0] = t.replace(R_OLD, R_NEW); todo += 1
    print("✔ 라디오 재생 화면 위쪽 버튼 6개")
else:
    print("❌ 라디오 재생 화면 버튼 못 찾음"); ok = False

# ── 자연소리: 위쪽 줄 안의 버튼 6개만 (32 → 29, 아이콘 16 → 13)
t = files[N][0]
START = "                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),\n"
END = "                  Expanded(\n                    child: Center(\n"
if t.count(START) == 1 and t.count(END) == 1 and t.index(START) < t.index(END):
    a, b = t.index(START), t.index(END)
    part = t[a:b]
    n32 = part.count("width: 32,\n                            height: 32,")
    if n32 == 0 and part.count("width: 29,") == 6:
        print("· 자연소리 재생 화면 이미 적용돼 있어요")
    elif n32 == 6:
        part = part.replace("width: 32,\n                            height: 32,", "width: 29,\n                            height: 29,")
        part, k = re.subn(r"size: 16\)", "size: 13)", part)
        if k != 6:
            print(f"❌ 자연소리 아이콘 크기를 6개 찾아야 하는데 {k}개예요"); ok = False
        else:
            files[N][0] = t[:a] + part + t[b:]; todo += 1
            print("✔ 자연소리 재생 화면 위쪽 버튼 6개")
    else:
        print(f"❌ 자연소리 버튼을 6개 찾아야 하는데 {n32}개예요"); ok = False
else:
    print("❌ 자연소리 위쪽 줄 못 찾음"); ok = False

# ── 믹스: _iconBtn 하나 (34 → 29, 아이콘 17 → 13)
M_OLD = """        width: 34,
        height: 34,
        decoration: BoxDecoration(color: baseColor.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(icon, color: baseColor, size: 17),"""
M_NEW = """        width: 29, // 홈 위쪽 버튼과 같게
        height: 29,
        decoration: BoxDecoration(color: baseColor.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(icon, color: baseColor, size: 13),"""
t = files[M][0]
if M_NEW in t:
    print("· 믹스 화면 이미 적용돼 있어요")
elif t.count(M_OLD) == 1:
    files[M][0] = t.replace(M_OLD, M_NEW); todo += 1
    print("✔ 믹스 화면 위쪽 버튼 4개")
else:
    print("❌ 믹스 화면 버튼 못 찾음"); ok = False

for p, (t, _) in files.items():
    if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
        print(f"❌ {p} 괄호 짝이 안 맞아요"); ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if todo == 0:
    print("이미 적용돼 있어요")
    sys.exit(0)
for p, (t, crlf) in files.items():
    if crlf:
        t = t.replace("\n", "\r\n")
    open(p, "wb").write(t.encode("utf-8"))
print("완료")
