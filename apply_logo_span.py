# -*- coding: utf-8 -*-
# 홈 로고(한국어): 영어 Paransori를 '파란소리' 왼쪽 끝부터 소리 막대(이퀄라이저) 끝까지 늘려서 깔끔하게
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

if "for (final ch in 'Paransori'.split(''))" in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True

# 1) 한국어 로고 묶음 새로 짜기
a_key = "            isKorean\n                ? Column(\n"
b_key = "                : Column(\n                    // 해외"
a = s.find(a_key)
b = s.find(b_key)
k1 = s.find('                          // "파란"만 숨쉬듯 은은하게\n', a)
k2_key = "                                  letterSpacing: -0.5)),\n                        ],\n                      ),\n"
k2 = s.find(k2_key, k1 if k1 >= 0 else 0)
if a >= 0 and b > a and a < k1 < b and a < k2 < b and s.count(a_key) == 1:
    letters = s[k1:k2] + "                                  letterSpacing: -0.5)),\n"
    # 두 칸 더 들여쓰기 (IntrinsicWidth 안으로 들어가서)
    letters = '\n'.join(('  ' + l) if l.strip() else l for l in letters.split('\n'))
    new_ko = (
        "            isKorean\n"
        "                // 한국어: 위 '파란소리 + 소리 막대', 아래 Paransori를 같은 폭으로 늘려 맞춤\n"
        "                ? IntrinsicWidth(\n"
        "                    child: Column(\n"
        "                      mainAxisSize: MainAxisSize.min,\n"
        "                      crossAxisAlignment: CrossAxisAlignment.stretch,\n"
        "                      children: [\n"
        "                        Row(\n"
        "                          mainAxisSize: MainAxisSize.min,\n"
        "                          crossAxisAlignment: CrossAxisAlignment.start,\n"
        "                          children: [\n"
        + letters.rstrip(' ') +
        "                            const SizedBox(width: 6),\n"
        "                            Padding(\n"
        "                              padding: const EdgeInsets.only(top: 8, bottom: 4),\n"
        "                              child: _LogoEqBars(color: logoBarColor),\n"
        "                            ),\n"
        "                          ],\n"
        "                        ),\n"
        "                        // Paransori: 글자를 고르게 벌려서 '파' 왼쪽 끝 ~ 막대 오른쪽 끝까지\n"
        "                        Transform.translate(\n"
        "                          offset: const Offset(0, -6),\n"
        "                          child: Padding(\n"
        "                            padding: const EdgeInsets.symmetric(horizontal: 1),\n"
        "                            child: Row(\n"
        "                              mainAxisAlignment: MainAxisAlignment.spaceBetween,\n"
        "                              children: [\n"
        "                                for (final ch in 'Paransori'.split(''))\n"
        "                                  Text(ch,\n"
        "                                      textScaler: TextScaler.noScaling,\n"
        "                                      style: GoogleFonts.quicksand(\n"
        "                                          color: logoInk.withOpacity(0.55),\n"
        "                                          fontSize: 12,\n"
        "                                          height: 1.0,\n"
        "                                          fontWeight: FontWeight.w600)),\n"
        "                              ],\n"
        "                            ),\n"
        "                          ),\n"
        "                        ),\n"
        "                      ],\n"
        "                    ),\n"
        "                  )\n"
    )
    s = s[:a] + new_ko + s[b:]
    print('✔ 한국어 로고: Paransori를 막대 끝까지 늘리기')
else:
    print('❌ 한국어 로고 — 코드를 못 찾았어요')
    ok = False

# 2) 소리 막대는 이제 한국어 묶음 안에 있으니, 바깥 막대는 해외에서만
old = ("            const SizedBox(width: 6),\n"
       "            Padding(\n"
       "              // 해외는 아래 Sori 옆에 붙게 (파란 Paran과 안 겹치게)\n"
       "              padding: EdgeInsets.only(top: isKorean ? 8 : 23, bottom: 4),\n"
       "              child: _LogoEqBars(color: logoBarColor),\n"
       "            ),\n")
new = ("            if (!isKorean) ...[\n"
       "              const SizedBox(width: 6),\n"
       "              Padding(\n"
       "                // 해외는 아래 Sori 옆에 붙게 (파란 Paran과 안 겹치게)\n"
       "                padding: const EdgeInsets.only(top: 23, bottom: 4),\n"
       "                child: _LogoEqBars(color: logoBarColor),\n"
       "              ),\n"
       "            ],\n")
if s.count(old) == 1:
    s = s.replace(old, new)
    print('✔ 소리 막대: 해외 로고에서만 바깥에')
else:
    print('❌ 소리 막대 — 코드를 못 찾았어요')
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
