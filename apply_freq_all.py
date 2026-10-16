# -*- coding: utf-8 -*-
# 주파수 비어 있던 국내 방송에 주파수 넣기(주파수 막대 나오게) + TBN 사진 위쪽 기준으로 보이기
# (apply_tbn_freq.py 를 이미 실행했어도 괜찮아요 — 이미 된 곳은 건너뛰어요)
# 실행: python apply_freq_all.py   (프로젝트 폴더에서)
import os, sys

FREQ = {  # 방송 이름 → 대표 주파수
    'TBN 경인교통': '100.5', 'TBN 울산교통': '104.1', 'TBN 부산교통': '94.9', 'TBN 경남교통': '95.5',
    'TBN 대구교통': '103.9', 'TBN 광주교통': '97.3', 'TBN 전북교통': '102.5', 'TBN 대전교통': '102.9',
    'TBN 충남교통': '103.9', 'TBN 충북교통': '103.3', 'TBN 강원교통': '105.9', 'TBN 제주교통': '105.5',
    '마포FM': '100.7', '수원 SoneFM': '96.3', '성서공동체FM': '89.1', 'TBC 드림FM': '99.3',
    '전주MBC 표준FM': '101.7', '전주MBC FM4U': '99.1', '전주FM': '93.5', 'FEBC 제주극동방송': '104.7',
}

FILES = {
    os.path.join('lib', 'screens', 'radio_korea_screen2.dart'): [
        (f"_KStation(name: '{r}', region: ", None, r) for r in FREQ
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
                print(f'❌ {region} 줄을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
            line = lines[0]
            want = f"frequency: '{FREQ[region]} MHz'"
            if want in line:
                continue
            i = line.find("frequency: '")
            j = line.find("'", i + len("frequency: '"))
            if i < 0 or j < 0:
                print(f'❌ {region} 주파수 칸을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
            t = t.replace(line, line[:i] + want + line[j + 1:])
            print(f'✔ {region} 주파수 {FREQ[region]}')
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
