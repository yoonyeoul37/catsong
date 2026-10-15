# 미니플레이어 4개 (음악·라디오·자연소리·믹스): ✕를 오른쪽 끝 가까이 + 다음 버튼과 띄우기
import re, sys

FILES = [
    "lib/widgets/mini_player.dart",
    "lib/widgets/radio_mini_player.dart",
    "lib/widgets/nature_mini_player.dart",
    "lib/widgets/sound_mix_mini_player.dart",
]
PAD_OLD = "padding: const EdgeInsets.symmetric(horizontal: 12),"
PAD_NEW = "padding: const EdgeInsets.fromLTRB(12, 0, 2, 0), // ✕를 오른쪽 끝 가까이"
MARK = "// × (닫기): 재생 중에도 누르면 바로 멈추고 닫힘"
GAP = "const SizedBox(width: 10), // 다음 버튼과 ✕ 사이 띄우기"

files = {}
for p in FILES:
    try:
        raw = open(p, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({p})")
        print("❌ 아무것도 저장 안 했어요.")
        sys.exit(1)
    files[p] = [raw.replace("\r\n", "\n"), "\r\n" in raw]

ok = True
todo = 0
for p in FILES:
    t = files[p][0]
    name = p.split("/")[-1]
    if PAD_NEW in t and GAP in t:
        print(f"· {name} 이미 적용돼 있어요")
        continue
    if t.count(PAD_OLD) != 1 or t.count(MARK) != 1:
        print(f"❌ {name} 자리 못 찾음")
        ok = False
        continue
    t = t.replace(PAD_OLD, PAD_NEW)
    # ✕ 설명 줄 바로 위에, 같은 들여쓰기로 간격 한 줄
    t, n = re.subn(r"\n([ \t]*)" + re.escape(MARK), lambda m: "\n" + m.group(1) + GAP + "\n" + m.group(1) + MARK, t, count=1)
    if n != 1:
        print(f"❌ {name} 간격 넣을 자리 못 찾음")
        ok = False
        continue
    files[p][0] = t
    todo += 1
    print(f"✔ {name}")

for p, (t, _) in files.items():
    if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
        print(f"❌ {p} 괄호 짝이 안 맞아요")
        ok = False

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
