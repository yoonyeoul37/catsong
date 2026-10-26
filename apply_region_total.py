# -*- coding: utf-8 -*-
# 한국어 '수도권' → '서울/경기/인천' · 방송사별 화면 맨 아래 '● 전체 채널 수'
import os, sys

def find(name):
    for r, _, fs in os.walk('lib'):
        if name in fs: return os.path.join(r, name)
    return None

KOR = find('radio_korea_screen2.dart')
ARB = find('app_ko.arb')
GEN = find('app_localizations_ko.dart')
for n, p in [('radio_korea_screen2.dart', KOR), ('app_ko.arb', ARB), ('app_localizations_ko.dart', GEN)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

ks, KNL = load(KOR)
ar, ANL = load(ARB)
gn, GNL = load(GEN)
if 'class _TotalChannels' in ks:
    print('이미 적용돼 있어요'); sys.exit(0)

kor_steps = [
 ('[radio_korea_screen2] 방송사별 칸을 맨 아래 줄과 함께 (위쪽)',
  "    return GridView.builder(\n"
  "      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n"
  "      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(\n"
  "        crossAxisCount: 2,\n"
  "        crossAxisSpacing: 10,\n"
  "        mainAxisSpacing: 10,\n"
  "        childAspectRatio: 1.5,\n"
  "      ),\n"
  "      itemCount: keys.length,\n",
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
  "      itemCount: keys.length,\n"),
 ('[radio_korea_screen2] 맨 아래 ● 전체 채널 수 (아래쪽)',
  "        );\n"
  "      },\n"
  "    );\n"
  "  }\n"
  "}\n"
  "\n"
  "// ══════════════════════════════════════════\n"
  "// 방송사 하나의 전국 채널 리스트 화면\n",
  "        );\n"
  "      },\n"
  "          ),\n"
  "        ),\n"
  "        // 맨 아래: ● 전체 채널 수 (라디오 목록 위 사진의 표시와 같은 모양 · 바탕이 밝아서 먹색 글자)\n"
  "        SliverToBoxAdapter(\n"
  "          child: Padding(\n"
  "            padding: EdgeInsets.fromLTRB(24, 22, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n"
  "            child: _TotalChannels(isDarkMode: isDarkMode),\n"
  "          ),\n"
  "        ),\n"
  "      ],\n"
  "    );\n"
  "  }\n"
  "}\n"
  "\n"
  "// ══════════════════════════════════════════\n"
  "// 방송사 하나의 전국 채널 리스트 화면\n"),
 ('[radio_korea_screen2] ● 전체 채널 수 모양',
  "class _LiveDot extends StatefulWidget {\n",
  "/// 방송사별 맨 아래: ● 163 채널 (라디오 목록 위 사진과 같은 빨간 점 · 숫자 글꼴)\n"
  "class _TotalChannels extends StatelessWidget {\n"
  "  final bool isDarkMode;\n"
  "  const _TotalChannels({required this.isDarkMode});\n"
  "\n"
  "  @override\n"
  "  Widget build(BuildContext context) {\n"
  "    final lang = Localizations.localeOf(context).languageCode;\n"
  "    final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n"
  "    return Row(\n"
  "      mainAxisAlignment: MainAxisAlignment.center,\n"
  "      children: [\n"
  "        const _LiveDot(size: 7),\n"
  "        const SizedBox(width: 6),\n"
  "        Text('${koreanStations.length}',\n"
  "            textScaler: TextScaler.noScaling,\n"
  "            style: GoogleFonts.quicksand(color: ink, fontSize: 14, fontWeight: FontWeight.w700)),\n"
  "        // 단위는 위쪽 사진과 같게: 한국어 '채널' · 일본어 '局', 나머지는 숫자만\n"
  "        if (lang == 'ko' || lang == 'ja') ...[\n"
  "          const SizedBox(width: 2),\n"
  "          Text(lang == 'ja' ? '局' : '채널',\n"
  "              textScaler: TextScaler.noScaling,\n"
  "              style: TextStyle(color: ink.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w700)),\n"
  "        ],\n"
  "      ],\n"
  "    );\n"
  "  }\n"
  "}\n"
  "\n"
  "class _LiveDot extends StatefulWidget {\n"),
]

def apply(s, nl, steps):
    ok = True
    for name, old, new in steps:
        o = old.replace('\n', nl); n = new.replace('\n', nl)
        c = s.count(o)
        if c == 1:
            s = s.replace(o, n); print('✔', name)
        else:
            ok = False; print('❌', name, '(찾은 개수: %d)' % c)
    return s, ok

ks, ok1 = apply(ks, KNL, kor_steps)
ar, ok2 = apply(ar, ANL, [('[app_ko.arb] 수도권 → 서울/경기/인천', '"regionCapital": "수도권",', '"regionCapital": "서울/경기/인천",')])
gn, ok3 = apply(gn, GNL, [('[app_localizations_ko.dart] 수도권 → 서울/경기/인천', "String get regionCapital => '수도권';", "String get regionCapital => '서울/경기/인천';")])
if not (ok1 and ok2 and ok3):
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(KOR, 'wb').write(ks.encode('utf-8'))
open(ARB, 'wb').write(ar.encode('utf-8'))
open(GEN, 'wb').write(gn.encode('utf-8'))
print('저장했어요')
