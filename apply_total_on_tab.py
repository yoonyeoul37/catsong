# -*- coding: utf-8 -*-
# '국가 선택 · 128개 나라' 줄을 빼고, 대륙 탭 '전체' 옆에 작고 연한 나라 수
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'screens', 'radio_home_screen.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '// 전체 옆에만 작고 연한 나라 수' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
if '_continentTabs(' not in s:
    print('❌ apply_continent_tabs.py를 먼저 실행해 주세요. 아무것도 저장 안 했어요.'); sys.exit(1)

edits = [
 ("'국가 선택 · 128개 나라' 줄 빼기",
  """                    // 국가 선택 · 128개 나라 (나라 수는 목록을 세서 → 나라를 늘리면 저절로 바뀜)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.radioSelectCountry,
                          style: TextStyle(
                            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${AppLocalizations.of(context)!.countryTotal(countries.length)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
""",
  """                    // (전체 나라 수는 위 대륙 탭 '전체' 옆에)
"""),
 ("'전체' 옆에 나라 수",
  """                    Text(
                      label(k),
""",
  """                    Text.rich(
                      TextSpan(text: label(k), children: [
                        // 전체 옆에만 작고 연한 나라 수 (나라를 늘리면 저절로 바뀜)
                        if (k == 'ALL')
                          TextSpan(
                            text: ' ${countries.length}',
                            style: TextStyle(
                              color: ink.withOpacity(0.35),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ]),
"""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)
if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
