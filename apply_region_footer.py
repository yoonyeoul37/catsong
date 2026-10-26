# -*- coding: utf-8 -*-
# 지역별 화면 맨 아래에도 '● 전체 채널 수' (방송사별과 같게)
import os, sys
P = None
for r, _, fs in os.walk('lib'):
    if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not P:
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
NL = '\r\n' if '\r\n' in s else '\n'
if '// 지역별 맨 아래: ● 전체 채널 수' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'class _TotalChannels' not in s:
    print('❌ apply_region_total.py 를 먼저 돌려 주세요'); sys.exit(1)

steps = [
 ('지역별 칸을 맨 아래 줄과 함께 (위쪽)',
  "    return GridView.builder(\n"
  "      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n"
  "      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(\n"
  "        crossAxisCount: 2,\n"
  "        crossAxisSpacing: 10,\n"
  "        mainAxisSpacing: 10,\n"
  "        childAspectRatio: 1.5,\n"
  "      ),\n"
  "      itemCount: regionList.length + 1,",
  "    return CustomScrollView(\n"
  "      slivers: [\n"
  "        SliverPadding(\n"
  "          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),\n"
  "          sliver: SliverGrid.builder(\n"
  "      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(\n"
  "        crossAxisCount: 2,\n"
  "        crossAxisSpacing: 10,\n"
  "        mainAxisSpacing: 10,\n"
  "        childAspectRatio: 1.5,\n"
  "      ),\n"
  "      itemCount: regionList.length + 1,"),
 ('지역별 맨 아래 ● 전체 채널 수 (아래쪽)',
  "        );\n"
  "      },\n"
  "    );\n"
  "  }\n"
  "\n"
  "  @override\n"
  "  Widget build(BuildContext context) {\n"
  "    final radioProvider = context.watch<RadioProvider>();\n",
  "        );\n"
  "      },\n"
  "          ),\n"
  "        ),\n"
  "        // 지역별 맨 아래: ● 전체 채널 수 (방송사별과 같은 모양)\n"
  "        SliverToBoxAdapter(\n"
  "          child: Padding(\n"
  "            padding: EdgeInsets.fromLTRB(24, 22, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n"
  "            child: _TotalChannels(isDarkMode: isDarkMode),\n"
  "          ),\n"
  "        ),\n"
  "      ],\n"
  "    );\n"
  "  }\n"
  "\n"
  "  @override\n"
  "  Widget build(BuildContext context) {\n"
  "    final radioProvider = context.watch<RadioProvider>();\n"),
]
ok = True
for name, old, new in steps:
    o = old.replace('\n', NL); n = new.replace('\n', NL)
    c = s.count(o)
    if c == 1:
        s = s.replace(o, n); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % c)
if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요:', P)
