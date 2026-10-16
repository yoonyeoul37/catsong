# -*- coding: utf-8 -*-
# AM 방송 주파수 막대(kHz) + FEBC 극동방송 AM 1188 kHz · 아리랑 라디오 88.7 MHz 넣기
# 실행: python apply_am_freq.py   (프로젝트 폴더에서)
import os, sys

EDITS = {
    'frequency_ruler.dart': [
        ("""            Text('${freq.toStringAsFixed(1)} MHz',""",
         """            Text(widget.maxFreq > 200 ? '${freq.toStringAsFixed(0)} kHz' : '${freq.toStringAsFixed(1)} MHz', // AM이면 kHz"""),
    ],
    'radio_player_screen.dart': [
        ("""                          child: FrequencyRuler(
                            frequency: _parseFrequency(freq),
                            primaryColor: primaryColor,
                          ),""",
         """                          child: FrequencyRuler(
                            frequency: _parseFrequency(freq),
                            primaryColor: primaryColor,
                            // AM 방송(kHz)이면 AM 눈금으로
                            minFreq: freq.contains('kHz') ? 531 : 88.0,
                            maxFreq: freq.contains('kHz') ? 1602 : 108.0,
                          ),"""),
    ],
    'radio_korea_screen2.dart': [
        ("""TextSpan(text: station.frequency.replaceAll(' MHz', '').trim()),""",
         """TextSpan(text: station.frequency.replaceAll(' MHz', '').replaceAll(' kHz', '').trim()),"""),
        ("""                                    text: ' MHz',""",
         """                                    text: station.frequency.contains('kHz') ? ' kHz' : ' MHz', // AM이면 kHz"""),
        ("""_KStation(name: 'FEBC 극동방송 AM', region: '수도권', broadcaster: 'FEBC', subLabel: '서울', frequency: '',""",
         """_KStation(name: 'FEBC 극동방송 AM', region: '수도권', broadcaster: 'FEBC', subLabel: '서울', frequency: '1188 kHz',"""),
        ("""_KStation(name: '아리랑 라디오', region: '수도권', broadcaster: 'Arirang', subLabel: '서울', frequency: '',""",
         """_KStation(name: '아리랑 라디오', region: '수도권', broadcaster: 'Arirang', subLabel: '서울', frequency: '88.7 MHz',"""),
    ],
}


def find(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None


done = {}
total = 0
for name, edits in EDITS.items():
    p = find(name)
    if not p:
        print(f'❌ {name} 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(p, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if t.count('(') != t.count(')') or t.count('{') != t.count('}') or t.count('[') != t.count(']'):
        print(f'❌ {name} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    done[p] = (t, crlf, n)
    total += n

if total == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, (t, crlf, n) in done.items():
    if n:
        with open(p, 'w', encoding='utf-8', newline='') as f:
            f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
