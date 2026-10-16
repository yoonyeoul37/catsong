# -*- coding: utf-8 -*-
# 메인 라디오 카드 채널 수: 사진 위 알약 → 아래 흰 띠 안 제목 오른쪽 (● 102 채널) — apply_radio_count.py 먼저 적용돼 있어야 해요
# 실행: python apply_radio_count2.py
import os, sys

EDITS = {
    'home_screen.dart': [('                        // 라디오 카드: 하트와 마주 보는 왼쪽 위에 채널 수 알약\n                        if (c.type == StartScreenType.radio)\n                          Positioned(\n                            top: 8,\n                            left: 8,\n                            right: 39, // 하트 칸(23) + 사이 8 비우기\n                            height: 23,\n                            child: Align(\n                              alignment: Alignment.centerLeft,\n                              child: FittedBox(\n                                fit: BoxFit.scaleDown,\n                                child: MediaQuery.withClampedTextScaling(\n                                  maxScaleFactor: 1.15,\n                                  child: _radioCountChip(context),\n                                ),\n                              ),\n                            ),\n                          ),\n', '                        // (라디오 채널 수는 아래 흰 띠 안 제목 오른쪽으로 옮김)\n'), ('                                  children: [\n                                    Text.rich(', '                                  children: [\n                                    // 제목 줄: 라디오 카드는 오른쪽 끝에 채널 수 (● 102 채널)\n                                    Row(children: [\n                                    Expanded(child: Text.rich('), ('                                            ])),\n                                    const SizedBox(height: 2),\n                                    Text(c.subtitle,', '                                            ]))),\n                                    if (c.type == StartScreenType.radio) _radioCountChip(context),\n                                    ]),\n                                    const SizedBox(height: 2),\n                                    Text(c.subtitle,'), ('    const ink = Color(0xFF17140F);\n    const red = Color(0xFFE5484D);\n    return Container(\n      height: 23,\n      padding: const EdgeInsets.symmetric(horizontal: 9),\n      decoration: BoxDecoration(color: Colors.white.withOpacity(0.62), borderRadius: BorderRadius.circular(999)),\n      child: Row(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n          Container(\n            width: 6,\n            height: 6,\n            decoration: BoxDecoration(\n              color: red,\n              shape: BoxShape.circle,\n              boxShadow: [BoxShadow(color: red.withOpacity(0.25), spreadRadius: 2.5)],\n            ),\n          ),\n          const SizedBox(width: 6),\n          Text(countText, style: GoogleFonts.quicksand(color: ink.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w700)),\n          const SizedBox(width: 3),\n          Text(unit, style: TextStyle(color: ink.withOpacity(0.78), fontSize: 10.5, fontWeight: FontWeight.w700)),\n        ],\n      ),\n    );\n  }\n\n', "    const ink = Color(0xFF17140F);\n    const red = Color(0xFFE5484D);\n    // 띠 안 제목 오른쪽: 배경 없이 ● 102 채널 (좁은 자리라 영어·중국어는 숫자만)\n    final showUnit = l.languageCode == 'ko' || l.languageCode == 'ja';\n    return Padding(\n      padding: const EdgeInsets.only(left: 6),\n      child: Row(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n          Container(\n            width: 6,\n            height: 6,\n            decoration: BoxDecoration(\n              color: red,\n              shape: BoxShape.circle,\n              boxShadow: [BoxShadow(color: red.withOpacity(0.22), spreadRadius: 2.5)],\n            ),\n          ),\n          const SizedBox(width: 6),\n          Text(countText, style: GoogleFonts.quicksand(color: ink.withOpacity(0.78), fontSize: 12, fontWeight: FontWeight.w700)),\n          if (showUnit) ...[\n            const SizedBox(width: 2),\n            Text(unit, style: TextStyle(color: ink.withOpacity(0.6), fontSize: 10.5, fontWeight: FontWeight.w700)),\n          ],\n        ],\n      ),\n    );\n  }\n\n")],
}


def find(name):
    for root, _, files in list(os.walk('tools')) + list(os.walk('lib')):
        if name in files:
            return os.path.join(root, name)
    return None


done = {}
total = 0
for name, edits in EDITS.items():
    p = find(name)
    if not p:
        print(f'❌ {name} 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(p, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    cnt = lambda x: [x.count(ch) - x.count(cl) for ch, cl in ('()', '{}', '[]')]
    before = cnt(t)
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if name.endswith('.py'):
        try:
            compile(t, p, 'exec')
        except SyntaxError as e:
            print(f'❌ {name} 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
    elif cnt(t) != before:  # 고치기 전과 괄호 짝이 같아야 함
        print(f'❌ {name} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    done[p] = (t, crlf, n)
    total += n

if total == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, (t, crlf, n) in done.items():
    if n:
        with open(p, 'w', encoding='utf-8', newline='') as f:
            f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
