# -*- coding: utf-8 -*-
# 라디오 제목 아래 나라 표시 한 단계 크게 (A안) — 국내 · 해외 둘 다
#  국기 12→14.5 · 나라 이름 11.5→13.5 진한 먹색 · ▾ 15→17 · 긴 나라 이름은 … 로
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

KR_OLD = """                    const Text('🇰🇷', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 12, height: 1.2)),
                    const SizedBox(width: 4),
                    Text(tr.countryKR,
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.6), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: baseColor.withOpacity(0.5)),
"""
KR_NEW = """                    // 나라 표시 한 단계 크게 (A안: 국기 14.5 · 이름 13.5 진하게 · ▾ 17)
                    const Text('🇰🇷', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 14.5, height: 1.2)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(tr.countryKR,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                              color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.2)),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: baseColor.withOpacity(0.5)),
"""
W_OLD = """                    Text(widget.country.flag,
                        textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 12, height: 1.2)),
                    const SizedBox(width: 4),
                    Text(widget.country.displayName,
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.6), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: baseColor.withOpacity(0.5)),
"""
W_NEW = """                    // 나라 표시 한 단계 크게 (A안: 국기 14.5 · 이름 13.5 진하게 · ▾ 17 · 긴 이름은 …)
                    Text(widget.country.flag,
                        textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 14.5, height: 1.2)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(widget.country.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                              color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.2)),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: baseColor.withOpacity(0.5)),
"""
JOBS = [('radio_korea_screen2.dart', KR_OLD, KR_NEW), ('radio_country_stations_screen.dart', W_OLD, W_NEW)]

def find(name):
    for root, dirs, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

ok = True
out = []
done = 0
for name, old, new in JOBS:
    p = find(name)
    if not p:
        print('❌', name, '못 찾음 (프로젝트 폴더에서 실행해 주세요)'); ok = False; continue
    raw = open(p, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if s.count(new) == 1:
        print('✔', name, '이미 적용돼 있어요'); done += 1; continue
    if s.count(old) != 1:
        print('❌', name, '나라 표시 부분을 못 찾음 (찾은 개수 %d)' % s.count(old)); ok = False; continue
    s = s.replace(old, new)
    t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", s)
    t = re.sub(r'//[^\n]*', '', t)
    for a, b in ('()', '[]', '{}'):
        if t.count(a) != t.count(b):
            print('❌ 괄호 안 맞음', name, a); ok = False
    print('✔', name, '나라 표시 크게')
    out.append((p, s, crlf))

if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)
if done == len(JOBS):
    print('✔ 이미 적용돼 있어요'); sys.exit(0)
for p, s, crlf in out:
    if crlf: s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))
    print('✔ 저장:', os.path.basename(p))
