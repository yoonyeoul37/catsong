# -*- coding: utf-8 -*-
# 주사위 정리: 수도권만 · 외국어/극동AM/SoneFM 빼기 · 종교 등은 가끔 · 사진 있으면 조금 더 · 방금 나온 방송 빼기
# (apply_radio_category.py 먼저 적용돼 있어야 해요)     실행: python apply_dice_pool.py
import os, sys

EDITS = {
    'radio_korea_screen2.dart': [("  // 주사위는 수도권 방송만 (지역 방송은 빼기) · 아래 방송은 덜 나오게\n  static const _diceLow = ['국악FM', 'CPBC 가톨릭'];\n\n  // 주사위 판: 지금 방송 쉬는 채널은 빼기 (다 쉬는 시간이면 그냥 전부)\n  List<DiceStation> _dicePool() {\n    final radio = context.read<RadioProvider>();\n    final pool = _dicePoolAll().where((d) => !radio.isOffAirNow(d.station.name)).toList();\n    return pool.isEmpty ? _dicePoolAll() : pool;\n  }\n\n  List<DiceStation> _dicePoolAll() => [\n        for (final ks in koreanStations)\n          if (ks.region == '수도권')\n            DiceStation(\n              weight: _diceLow.contains(ks.name) ? 0.3 : 1.0,", "  // 주사위: 수도권만 · 외국어·지방은 빼기 · 종교와 아래 방송은 가끔(0.3) · 지금 사진 있는 방송은 조금 더(×1.5)\n  static const _diceOut = {'FEBC 극동방송 AM', '수원 SoneFM'}; // AM은 FM과 같은 방송 · SoneFM은 편성표 없음\n  static const _diceLow = {'국악FM', '국방FM', 'EBS FM', 'CBS JOY4U', 'MBC 올댓뮤직', 'TBN 경인교통', '마포FM'};\n\n  double? _diceWeight(_KStation ks, RadioProvider r) {\n    if (ks.region != '수도권' || _diceOut.contains(ks.name)) return null;\n    final c = stationCategory(ks);\n    if (c == 2) return null; // 외국어\n    var w = (c == 3 || _diceLow.contains(ks.name)) ? 0.3 : 1.0;\n    final img = (r.currentProgramFor(ks.name)?['image'] ?? '').toString();\n    if (img.isNotEmpty) w *= 1.5;\n    return w;\n  }\n\n  // 주사위 판: 지금 방송 쉬는 채널 · 방금 주사위로 나온 방송은 빼기 (그러면 너무 적으면 그냥 전부)\n  List<DiceStation> _dicePool() {\n    final radio = context.read<RadioProvider>();\n    final all = _dicePoolAll();\n    final pool = all\n        .where((d) => !radio.isOffAirNow(d.station.name) && d.station.name != _diceChoice)\n        .toList();\n    return pool.length >= 3 ? pool : all;\n  }\n\n  List<DiceStation> _dicePoolAll() {\n    final r = context.read<RadioProvider>();\n    return [\n        for (final ks in koreanStations)\n          if (_diceWeight(ks, r) != null)\n            DiceStation(\n              weight: _diceWeight(ks, r)!,"), ("                final t = r.nowPlayingFor(ks.name) ?? p?['title']?.toString() ?? '';\n                return t.trim();\n              },\n            ),\n      ];\n\n  Future<void> _openDice() async {", "                final t = r.nowPlayingFor(ks.name) ?? p?['title']?.toString() ?? '';\n                return t.trim();\n              },\n            ),\n      ];\n  }\n\n  Future<void> _openDice() async {")],
}


def find(name):
    for root, _, files in list(os.walk('tools')) + list(os.walk('lib')):
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
    cnt = lambda x: [x.count(ch) - x.count(cl) for ch, cl in ('()', '{}', '[]')]
    before = cnt(t)
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if name.endswith('.py'):
        try:
            compile(t, p, 'exec')
        except SyntaxError as e:
            print(f'❌ {name} 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
    elif cnt(t) != before:  # 고치기 전과 괄호 짝이 같아야 함
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
