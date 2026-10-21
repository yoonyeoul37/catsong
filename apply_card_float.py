# -*- coding: utf-8 -*-
# 재생 화면(파란포토) 제목·가수 유리 카드: 은은한 빛 + 바닥 그림자 + 아주 천천히 둥실 (시안 C)
import os, sys

PATH = os.path.join('lib', 'screens', 'player_screen.dart')

EDITS = [
    ('카드에 빛·그림자 + 둥실 시작',
     "          // 반투명 유리 카드 (가사 화면과 같은 모양, 재생 막대는 아래에 있으니 빼기)\n"
     "          Container(\n"
     "            width: MediaQuery.of(context).size.width - 90,\n"
     "            margin: const EdgeInsets.symmetric(horizontal: 20),\n"
     "            child: ClipRRect(\n",
     "          // 반투명 유리 카드 — 은은한 빛 + 바닥 그림자로 붕 떠 있게, 아주 천천히 둥실\n"
     "          _CardFloat(\n"
     "          child: Container(\n"
     "            width: MediaQuery.of(context).size.width - 90,\n"
     "            margin: const EdgeInsets.symmetric(horizontal: 20),\n"
     "            decoration: BoxDecoration(\n"
     "              borderRadius: BorderRadius.circular(18),\n"
     "              boxShadow: [\n"
     "                // 둘레에 번지는 아주 연한 빛 (포인트 색)\n"
     "                BoxShadow(\n"
     "                    color: pointColorOf(context, onDark: true).withOpacity(0.22),\n"
     "                    blurRadius: 26,\n"
     "                    spreadRadius: 1),\n"
     "                // 바닥 그림자\n"
     "                BoxShadow(\n"
     "                    color: Colors.black.withOpacity(0.45),\n"
     "                    blurRadius: 18,\n"
     "                    spreadRadius: -6,\n"
     "                    offset: const Offset(0, 14)),\n"
     "              ],\n"
     "            ),\n"
     "            child: ClipRRect(\n"),
    ('카드 테두리를 연한 포인트 색으로',
     "                    border: Border.all(color: Colors.white.withOpacity(0.10)),\n",
     "                    border: Border.all(color: pointColorOf(context, onDark: true).withOpacity(0.30)),\n"),
    ('둥실 끝',
     "          ),\n            ],\n          ),\n        ),\n      ],\n    );\n  }\n  Widget _buildCDStyle(",
     "          ),\n          ),\n            ],\n          ),\n        ),\n      ],\n    );\n  }\n  Widget _buildCDStyle("),
]

FLOAT = '''

/// 제목 카드가 아주 천천히 위아래로 둥실 (4초에 한 번 · 위아래 2.5)
/// 폰에서 '애니메이션 줄이기'를 켜 두면 움직이지 않음
class _CardFloat extends StatefulWidget {
  final Widget child;
  const _CardFloat({required this.child});

  @override
  State<_CardFloat> createState() => _CardFloatState();
}

class _CardFloatState extends State<_CardFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -2.5 + 5 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
'''


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    if 'class _CardFloat' in text:
        print('이미 적용돼 있어요')
        return
    for name, old, new in EDITS:
        n = text.count(old)
        if n != 1:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        print('✔', name)
    text = text.rstrip('\n') + '\n' + FLOAT
    print('✔ 둥실 움직임 만들기')
    if crlf:
        text = text.replace('\n', '\r\n')
    with open(PATH, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요')


main()
