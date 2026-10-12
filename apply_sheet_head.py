# -*- coding: utf-8 -*-
# 색 고르는 창 머리 B안: 작은 '강조 색상'(강조 색) + 도현체 큰 질문 '오늘 기분에 어울리는 색은?'
# + 아래 안내 문구를 두 줄로 깔끔하게
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

if '// 창 머리 B안' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

rep('창 머리: 작은 강조 색상 + 큰 질문',
    "      title: '강조 색상',\n"
    "      builder: (ctx, setSheet) {\n",
    "      title: '강조 색상',\n"
    "      // 창 머리 B안: 작은 '강조 색상'(지금 강조 색) + 도현체 큰 질문\n"
    "      header: Builder(builder: (c) {\n"
    "        final p = c.watch<ThemeProvider>().primaryColor;\n"
    "        final label = p.value == 0xFF2589E8 ? (dark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8)) : p;\n"
    "        return Padding(\n"
    "          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),\n"
    "          child: Column(\n"
    "            crossAxisAlignment: CrossAxisAlignment.start,\n"
    "            children: [\n"
    "              Text('강조 색상',\n"
    "                  style: TextStyle(color: label, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),\n"
    "              const SizedBox(height: 3),\n"
    "              Text('오늘 기분에 어울리는 색은?',\n"
    "                  textScaler: TextScaler.noScaling,\n"
    "                  style: GoogleFonts.doHyeon(color: ink, fontSize: 21)),\n"
    "            ],\n"
    "          ),\n"
    "        );\n"
    "      }),\n"
    "      builder: (ctx, setSheet) {\n")

# 예전 작은 설명 줄 빼기 (문구가 무엇이든)
m = re.search(r"            Padding\(\n              padding: const EdgeInsets\.fromLTRB\(4, 0, 4, 16\),\n              child: Text\('[^']*',\n                  style: TextStyle\(color: sub, fontSize: 12\.5\)\),\n            \),\n", s)
if m:
    s = s[:m.start()] + s[m.end():]
    print('✔ 예전 작은 설명 줄 빼기')
else:
    print('❌ 예전 작은 설명 줄 — 코드를 못 찾았어요')
    ok = False

# 아래 안내 문구 두 줄로
n_before = s.count("'설정 → 꾸미기 → 강조 색상에서 다시 변경할 수 있습니다.'")
if n_before == 1:
    s = s.replace("'설정 → 꾸미기 → 강조 색상에서 다시 변경할 수 있습니다.'",
                  "'설정 → 꾸미기 → 강조 색상에서\\n다시 변경할 수 있습니다.'")
    print('✔ 안내 문구 두 줄로')
else:
    print('❌ 안내 문구 — 코드를 못 찾았어요')
    ok = False

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
