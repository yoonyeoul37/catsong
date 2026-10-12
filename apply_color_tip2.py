# -*- coding: utf-8 -*-
# 강조 색상 안내 카드 마무리 (한 번에)
#  1) [완료] 위에 "나중에 설정 → 꾸미기 → 강조 색상에서 다시 바꿀 수 있어요"
#  2) 색을 바꿔도 카드는 남고, ✕를 눌러야만 사라짐
#  3) 테스트용 줄이 있으면 지우기
import os, sys, shutil, re

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('home_screen.dart')
if not path:
    print('❌ lib 폴더에서 home_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s

if '_showColorTip' not in s:
    print('❌ 먼저 apply_color_tip.py를 적용해야 해요. 아무것도 저장 안 했어요.')
    sys.exit(1)

ok = True

# 3) 테스트용 줄 지우기
lines = s.split('\n')
kept = [l for l in lines if '★테스트용' not in l]
if len(kept) != len(lines):
    s = '\n'.join(kept)
    print('✔ 테스트용 줄 지우기')

# 1) 설정 안내 (이미 있으면 건너뜀)
if '설정 → 꾸미기 → 강조 색상' in s:
    print('✔ 설정 안내 (이미 들어가 있어요)')
else:
    s = s.replace("Text('누르면 바로 바뀌어요 · 설정에서 언제든 다시 바꿀 수 있어요',",
                  "Text('누르면 바로 바뀌어요',")
    old = ("                      if (i < n) dot(i) else const Expanded(child: SizedBox()),\n"
           "                  ],\n"
           "                ),\n"
           "              ),\n"
           "          ],\n"
           "        );\n")
    new = ("                      if (i < n) dot(i) else const Expanded(child: SizedBox()),\n"
           "                  ],\n"
           "                ),\n"
           "              ),\n"
           "            // 나중에 바꾸는 곳 알려주기\n"
           "            Container(\n"
           "              width: double.infinity,\n"
           "              margin: const EdgeInsets.only(top: 2, bottom: 4),\n"
           "              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),\n"
           "              decoration: BoxDecoration(\n"
           "                color: ink.withOpacity(0.06),\n"
           "                borderRadius: BorderRadius.circular(12),\n"
           "              ),\n"
           "              child: Row(\n"
           "                children: [\n"
           "                  Icon(Icons.info_outline_rounded, size: 16, color: sub),\n"
           "                  const SizedBox(width: 8),\n"
           "                  Expanded(\n"
           "                    child: Text.rich(\n"
           "                      TextSpan(children: [\n"
           "                        const TextSpan(text: '나중에 '),\n"
           "                        TextSpan(\n"
           "                            text: '설정 → 꾸미기 → 강조 색상',\n"
           "                            style: TextStyle(color: ink, fontWeight: FontWeight.w700)),\n"
           "                        const TextSpan(text: '에서\\n다시 바꿀 수 있어요'),\n"
           "                      ]),\n"
           "                      style: TextStyle(color: sub, fontSize: 12.5, height: 1.45),\n"
           "                    ),\n"
           "                  ),\n"
           "                ],\n"
           "              ),\n"
           "            ),\n"
           "          ],\n"
           "        );\n")
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔ [완료] 위에 설정 안내')
    else:
        print('❌ 설정 안내 — 코드를 못 찾았어요')
        ok = False

# 2) ✕를 눌러야만 사라지게 (이미 했으면 건너뜀)
if 'color_tip_shown' in s:
    print('✔ ✕로만 닫기 (이미 들어가 있어요)')
else:
    old1 = ("    // 이미 색을 바꾼 사람은 알고 있으니 안 보여줌\n"
            "    if (context.read<ThemeProvider>().primaryColor.value != 0xFF2589E8) {\n"
            "      await prefs.setBool('color_tip_done', true);\n"
            "      return;\n"
            "    }\n"
            "    if (n >= 3) setState(() => _showColorTip = true);\n")
    new1 = ("    // 카드가 나오기 전에 이미 색을 바꾼 사람은 알고 있으니 안 보여줌\n"
            "    final shown = prefs.getBool('color_tip_shown') ?? false;\n"
            "    if (!shown && context.read<ThemeProvider>().primaryColor.value != 0xFF2589E8) {\n"
            "      await prefs.setBool('color_tip_done', true);\n"
            "      return;\n"
            "    }\n"
            "    if (n >= 3) {\n"
            "      await prefs.setBool('color_tip_shown', true); // 한 번 나온 뒤로는 ✕ 누를 때까지 계속\n"
            "      if (mounted) setState(() => _showColorTip = true);\n"
            "    }\n")
    if s.count(old1) == 1:
        s = s.replace(old1, new1)
        print('✔ 색을 바꿔도 카드 남기기')
    else:
        print('❌ 색을 바꿔도 카드 남기기 — 코드를 못 찾았어요')
        ok = False
    old2 = "    );\n    _finishColorTip();\n  }\n"
    new2 = "    );\n    // 창을 닫아도 카드는 그대로 (✕를 눌러야 끝)\n  }\n"
    if s.count(old2) == 1:
        s = s.replace(old2, new2)
        print('✔ 창 닫아도 카드 그대로')
    else:
        print('❌ 창 닫아도 카드 그대로 — 코드를 못 찾았어요')
        ok = False

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
