# -*- coding: utf-8 -*-
# 국내 라디오 위쪽: B2안 (국가 선택을 위로 · 탭은 박스 없이 글자 + 고른 탭만 밑줄)
#   되돌리기:  python apply_radio_tabs_b2.py 되돌리기
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

OLD_HDR = "                Container(\n                  height: 36,\n                  padding: const EdgeInsets.all(3),\n                  decoration: BoxDecoration(\n                    color: baseColor.withOpacity(0.07),\n                    borderRadius: BorderRadius.circular(10), // 아래 카드와 같은 둥글기\n                  ),\n                  child: Row(\n                    crossAxisAlignment: CrossAxisAlignment.stretch,\n                    children: [\n                      _toggleButton(tr.all, _ViewMode.all, isDarkMode),\n                      _toggleButton(tr.byBroadcaster, _ViewMode.broadcaster, isDarkMode),\n                      _toggleButton(tr.byRegion, _ViewMode.region, isDarkMode),\n                      _toggleButton(podText('팟캐스트', 'Podcasts'), _ViewMode.podcast, isDarkMode),\n                      _toggleButton(tr.recentListened, _ViewMode.recent, isDarkMode),\n                    ],\n                  ),\n                ),\n                const SizedBox(height: 6),\n                GestureDetector(\n                  behavior: HitTestBehavior.opaque, // 줄 어디를 눌러도 나라 고르기\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    Navigator.push(\n                      context,\n                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n                    );\n                  },\n                  child: SizedBox(\n                    height: 30,\n                    child: Row(\n                      children: [\n                        const SizedBox(width: 2),\n                        Expanded(\n                          child: Text(tr.selectCountryShort,\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,\n                                  color: baseColor.withOpacity(0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),\n                        ),\n                        const Text('🇰🇷', style: TextStyle(fontSize: 15)),\n                        const SizedBox(width: 6),\n                        Text(tr.countryKR,\n                            maxLines: 1,\n                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,\n                                color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w700)),\n                        const SizedBox(width: 2),\n                        Icon(Icons.keyboard_arrow_down_rounded,\n                            size: 20, color: baseColor.withOpacity(0.45)),\n                      ],\n                    ),\n                  ),\n                ),\n"
NEW_HDR = "                // B2: 국가 선택을 위로 (가끔 바꾸는 것) → 아래 탭 → 목록\n                GestureDetector(\n                  behavior: HitTestBehavior.opaque, // 줄 어디를 눌러도 나라 고르기\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    Navigator.push(\n                      context,\n                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n                    );\n                  },\n                  child: SizedBox(\n                    height: 30,\n                    child: Row(\n                      children: [\n                        const SizedBox(width: 2),\n                        Expanded(\n                          child: Text(tr.selectCountryShort,\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,\n                                  color: baseColor.withOpacity(0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),\n                        ),\n                        const Text('🇰🇷', style: TextStyle(fontSize: 15)),\n                        const SizedBox(width: 6),\n                        Text(tr.countryKR,\n                            maxLines: 1,\n                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,\n                                color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w700)),\n                        const SizedBox(width: 2),\n                        Icon(Icons.keyboard_arrow_down_rounded,\n                            size: 20, color: baseColor.withOpacity(0.45)),\n                      ],\n                    ),\n                  ),\n                ),\n                const SizedBox(height: 4),\n                // B2: 탭은 박스 없이 글자 + 아래 얇은 선 (고른 탭만 진한 밑줄)\n                Container(\n                  height: 36,\n                  decoration: BoxDecoration(\n                    border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12), width: 0.5)),\n                  ),\n                  child: Row(\n                    crossAxisAlignment: CrossAxisAlignment.stretch,\n                    children: [\n                      _toggleButton(tr.all, _ViewMode.all, isDarkMode),\n                      _toggleButton(tr.byBroadcaster, _ViewMode.broadcaster, isDarkMode),\n                      _toggleButton(tr.byRegion, _ViewMode.region, isDarkMode),\n                      _toggleButton(podText('팟캐스트', 'Podcasts'), _ViewMode.podcast, isDarkMode),\n                      _toggleButton(tr.recentListened, _ViewMode.recent, isDarkMode),\n                    ],\n                  ),\n                ),\n"
OLD_DEC = '          decoration: BoxDecoration(\n            color: selected ? (isDarkMode ? const Color(0xFF45413B) : const Color(0xFFFBF8F2)) : Colors.transparent,\n            borderRadius: BorderRadius.circular(10),\n            boxShadow: selected\n                ? [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.08), blurRadius: 3, offset: const Offset(0, 1))]\n                : null,\n          ),\n'
NEW_DEC = '          // B2: 박스 없이 고른 탭 아래에만 진한 밑줄\n          decoration: BoxDecoration(\n            border: Border(\n              bottom: BorderSide(\n                color: selected ? (isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F)) : Colors.transparent,\n                width: 2,\n              ),\n            ),\n          ),\n'

undo = len(sys.argv) > 1 and sys.argv[1] in ('되돌리기', 'undo')

p = None
for root, dirs, files in os.walk('lib'):
    if 'radio_korea_screen2.dart' in files:
        p = os.path.join(root, 'radio_korea_screen2.dart')
if not p:
    print('❌ radio_korea_screen2.dart 못 찾음 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

pairs = [('위쪽 순서 (국가 선택 → 탭)', OLD_HDR, NEW_HDR), ('탭 모양 (밑줄)', OLD_DEC, NEW_DEC)]
if undo:
    pairs = [(l + ' 되돌리기', n, o) for l, o, n in pairs]
    if all(s.count(o) == 1 for _, _, o in pairs):
        print('✔ 이미 예전 모양이에요'); sys.exit(0)
else:
    if all(s.count(n) == 1 for _, _, n in pairs):
        print('✔ 이미 적용돼 있어요'); sys.exit(0)

ok = True
for label, old, new in pairs:
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
