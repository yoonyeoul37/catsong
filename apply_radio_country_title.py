# -*- coding: utf-8 -*-
# 국내 라디오: 나라(🇰🇷 한국 ▾)를 제목 아래로 (해외와 같게) · 탭 위 국가 줄 빼기
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

PAIRS = [
    ('제목 아래에 나라 넣기', '            Flexible(child: MenuTitle(title: tr.catRadio, sub: tr.catRadioSub, isDark: isDarkMode)),\n', "            // 해외 라디오와 같게: 제목 아래 설명 대신 '지금 보는 나라' — 누르면 나라 고르기\n            Flexible(\n              child: MenuTitle(\n                title: tr.catRadio,\n                sub: tr.catRadioSub,\n                isDark: isDarkMode,\n                subWidget: Row(\n                  mainAxisSize: MainAxisSize.min,\n                  children: [\n                    const Text('🇰🇷', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 12, height: 1.2)),\n                    const SizedBox(width: 4),\n                    Text(tr.countryKR,\n                        maxLines: 1,\n                        textScaler: TextScaler.noScaling,\n                        style: TextStyle(\n                            color: baseColor.withOpacity(0.6), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2)),\n                    Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: baseColor.withOpacity(0.5)),\n                  ],\n                ),\n                onTap: () {\n                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                  Navigator.push(\n                    context,\n                    MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n                  );\n                },\n              ),\n            ),\n"),
    ('탭 위 국가 줄 빼기', "          preferredSize: const Size.fromHeight(86),\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),\n            child: Column(\n              children: [\n                // B2: 국가 선택을 위로 (가끔 바꾸는 것) → 아래 탭 → 목록\n                GestureDetector(\n                  behavior: HitTestBehavior.opaque, // 줄 어디를 눌러도 나라 고르기\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    Navigator.push(\n                      context,\n                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n                    );\n                  },\n                  child: SizedBox(\n                    height: 30,\n                    child: Row(\n                      children: [\n                        const SizedBox(width: 2),\n                        // '국가 선택' 글자 없이 국기 · 나라 이름 · ▾만 왼쪽에\n                        const Text('🇰🇷', style: TextStyle(fontSize: 13.5)),\n                        const SizedBox(width: 6),\n                        Text(tr.countryKR,\n                            maxLines: 1,\n                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,\n                                color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w700)),\n                        const SizedBox(width: 2),\n                        Icon(Icons.keyboard_arrow_down_rounded,\n                            size: 18, color: baseColor.withOpacity(0.45)),\n                        const Spacer(), // 줄 나머지도 눌리게 (나라 고르기)\n                      ],\n                    ),\n                  ),\n                ),\n                const SizedBox(height: 4),\n", '          preferredSize: const Size.fromHeight(48), // 나라는 위 제목 아래로 옮겨서 탭 한 줄만\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),\n            child: Column(\n              children: [\n'),
]

p = None
for root, dirs, files in os.walk('lib'):
    if 'radio_korea_screen2.dart' in files:
        p = os.path.join(root, 'radio_korea_screen2.dart')
if not p:
    print('❌ radio_korea_screen2.dart 못 찾음 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if all(s.count(n) == 1 for _, _, n in PAIRS):
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

ok = True
for label, old, new in PAIRS:
    n = s.count(old)
    if n != 1:
        print('❌', label, '(찾은 개수 %d)' % n); ok = False; continue
    s = s.replace(old, new)
    print('✔', label)

t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", s)
t = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', t)
t = re.sub(r'//[^\n]*', '', t)
for a, b in ('()', '[]', '{}'):
    if t.count(a) != t.count(b):
        print('❌ 괄호 안 맞음', a, t.count(a), t.count(b)); ok = False
if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)
if crlf: s = s.replace('\n', '\r\n')
open(p, 'wb').write(s.encode('utf-8'))
print('✔ 저장: radio_korea_screen2.dart')
