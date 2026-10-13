# -*- coding: utf-8 -*-
# 위젯 원인 찾기용 기록 줄(PARAN_W) 지우기 — 앱 동작은 하나도 안 바뀜
import os, sys, re, shutil

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)

targets = []
for top in ('lib', os.path.join('android', 'app', 'src', 'main')):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        for f in files:
            if f.endswith('.dart') or f.endswith('.kt'):
                p = os.path.join(root, f)
                if 'PARAN_W' in open(p, encoding='utf-8', errors='ignore').read():
                    targets.append(p)
if not targets:
    print('이미 적용돼 있어요'); sys.exit(0)

# 한 줄짜리 기록만 지움 (모양이 다르면 손대지 않고 ❌)
one_line = re.compile(r'^\s*(if \(!done\) )?(debugPrint\(\'PARAN_W.*\);|android\.util\.Log\.d\("PARAN_W".*\))\s*$')
# 기록 한 줄만 들어 있던 if 묶음 (통째로 지움)
block = re.compile(r"\n[ \t]*if \(call\.method\.startsWith\('widget'\) \|\| call\.method\.startsWith\('onAudio'\)\) \{\n[ \t]*debugPrint\('PARAN_W[^\n]*\);\n[ \t]*\}")

ok = True
writes = {}
for p in targets:
    raw = open(p, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    src = raw.replace('\r\n', '\n')
    src, nb = block.subn('', src)
    out, n = [], nb
    for ln in src.split('\n'):
        if 'PARAN_W' in ln:
            if one_line.match(ln):
                n += 1
                continue
            print('❌ %s: 모양이 달라서 못 지움 → %s' % (os.path.basename(p), ln.strip()[:80]))
            ok = False
        out.append(ln)
    writes[p] = ('\n'.join(out), crlf)
    print('✔ %s: 기록 %d줄 지움' % (os.path.basename(p), n))

if not ok:
    print('\n하나라도 못 지워서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_debug_logs')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_debug_logs)')
