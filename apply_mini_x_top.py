# 미니플레이어 4개 (음악·라디오·자연소리·믹스): ✕를 오른쪽 위로 작게 + 재생·이전·다음 버튼을 오른쪽으로
# (apply_mini_x_right.py 를 돌렸든 안 돌렸든 둘 다 됨)
import re, sys

FILES = [
    "lib/widgets/mini_player.dart",
    "lib/widgets/radio_mini_player.dart",
    "lib/widgets/nature_mini_player.dart",
    "lib/widgets/sound_mix_mini_player.dart",
]
PADS_OLD = [
    "padding: const EdgeInsets.symmetric(horizontal: 12),",
    "padding: const EdgeInsets.fromLTRB(12, 0, 2, 0), // ✕를 오른쪽 끝 가까이",
]
PAD_NEW = "padding: const EdgeInsets.fromLTRB(12, 0, 22, 0), // 버튼은 오른쪽으로 · ✕는 오른쪽 위 작게"

X_IN_ROW = re.compile(
    r"\n[ \t]*(?:const SizedBox\(width: 10\), // 다음 버튼과 ✕ 사이 띄우기\n[ \t]*)?"
    r"// × \(닫기\): 재생 중에도 누르면 바로 멈추고 닫힘\n"
    r"[ \t]*IconButton\(\n.*?constraints: const BoxConstraints\(minWidth: 32, minHeight: 32\),\n[ \t]*\),\n",
    re.S)

TOP_OLD = "      child: ClipRRect(\n        borderRadius: const BorderRadius.only(\n          topLeft: Radius.zero,\n          topRight: Radius.zero,\n        ),\n"
TOP_NEW = "      child: Stack(\n        children: [\n      ClipRRect(\n        borderRadius: const BorderRadius.only(\n          topLeft: Radius.zero,\n          topRight: Radius.zero,\n        ),\n"
END_OLD = "        ),\n      ),\n    );\n  }\n\n  /// 미니플레이어 닫기"
END_NEW = ("        ),\n      ),\n"
           "          // × (닫기): 오른쪽 위 작게 · 재생 중에도 누르면 바로 멈추고 닫힘\n"
           "          Positioned(top: 4, right: 2, child: _MiniCloseX(onTap: () => _close(context))),\n"
           "        ],\n      ),\n    );\n  }\n\n  /// 미니플레이어 닫기")
CLOSE_CLASS = """
/// 미니플레이어 오른쪽 위 작은 ✕ (보이는 건 작게, 누르는 자리는 넉넉하게)
class _MiniCloseX extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniCloseX({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(Icons.close_rounded, size: 14, color: const Color(0xFFF4EFE5).withOpacity(0.45)),
        ),
      );
}
"""

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
    if "class _MiniCloseX" in t:
        print(f"· {name} 이미 적용돼 있어요")
        continue
    pad = [o for o in PADS_OLD if t.count(o) == 1]
    if len(pad) != 1 or t.count(TOP_OLD) != 1 or t.count(END_OLD) != 1:
        print(f"❌ {name} 자리 못 찾음")
        ok = False
        continue
    t2, n = X_IN_ROW.subn("\n", t, count=1)
    if n != 1:
        print(f"❌ {name} 줄 끝의 ✕ 못 찾음")
        ok = False
        continue
    t2 = t2.replace(pad[0], PAD_NEW).replace(TOP_OLD, TOP_NEW).replace(END_OLD, END_NEW)
    t2 = t2.rstrip("\n") + "\n" + CLOSE_CLASS
    files[p][0] = t2
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
