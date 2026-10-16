# -*- coding: utf-8 -*-
# TBN: 주파수 넣기(주파수 막대 나오게) + 프로그램 사진 위쪽 기준으로 보이기
# 실행: python apply_tbn_freq.py   (프로젝트 폴더에서)
import os, sys

FREQ = {  # TBN 홈페이지 '주파수현황' 대표 주파수
    '경인': '100.5', '울산': '104.1', '부산': '94.9', '경남': '95.5', '대구': '103.9', '광주': '97.3',
    '전북': '102.5', '대전': '102.9', '충남': '103.9', '충북': '103.3', '강원': '105.9', '제주': '105.5',
}
OLD = {'경인': '99.9 MHz', '울산': '98.7 MHz'}

FILES = {
    os.path.join('lib', 'screens', 'radio_korea_screen2.dart'): [
        (f"_KStation(name: 'TBN {r}교통', region: ", None, r) for r in FREQ
    ],
    os.path.join('lib', 'screens', 'radio_player_screen.dart'): [
        ("""                                programImage,
                                width: double.infinity,
                                height: imgH,
                                fit: BoxFit.cover,
""", """                                programImage,
                                width: double.infinity,
                                height: imgH,
                                fit: BoxFit.cover,
                                // TBN 사진은 중요한 부분이 위쪽이라 위쪽 기준으로 자르기
                                alignment: current.name.startsWith('TBN ') ? Alignment.topCenter : Alignment.center,
""", None),
    ],
}


def find_path(p):
    if os.path.isfile(p):
        return p
    name = os.path.basename(p)
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None


results = {}
for p, edits in FILES.items():
    real = find_path(p)
    if not real:
        print(f'❌ {os.path.basename(p)} 를 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(real, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    changed = 0
    for o, n, region in edits:
        if region:  # TBN 한 줄: frequency: '...' 칸만 바꾸기
            lines = [l for l in t.split('\n') if o in l]
            if len(lines) != 1:
                print(f'❌ TBN {region}교통 줄을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
            line = lines[0]
            want = f"frequency: '{FREQ[region]} MHz'"
            if want in line:
                continue
            i = line.find("frequency: '")
            j = line.find("'", i + len("frequency: '"))
            if i < 0 or j < 0:
                print(f'❌ TBN {region}교통 주파수 칸을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
            t = t.replace(line, line[:i] + want + line[j + 1:])
            print(f'✔ TBN {region}교통 주파수 {FREQ[region]}')
            changed += 1
        else:
            if n in t:
                continue
            if t.count(o) != 1:
                print(f'❌ {os.path.basename(p)} 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
            t = t.replace(o, n)
            print(f'✔ {os.path.basename(p)} TBN 사진 위쪽 기준')
            changed += 1
    if t.count('(') != t.count(')') or t.count('{') != t.count('}') or t.count('[') != t.count(']'):
        print(f'❌ {os.path.basename(p)} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    results[real] = (t, crlf, changed)

if sum(c for _, _, c in results.values()) == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for real, (t, crlf, changed) in results.items():
    if changed:
        if crlf:
            t = t.replace('\n', '\r\n')
        with open(real, 'w', encoding='utf-8', newline='') as f:
            f.write(t)
print('완료!')
