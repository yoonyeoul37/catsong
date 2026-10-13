# -*- coding: utf-8 -*-
# 라디오 위쪽 '전체·방송사별·지역별·최근청취', '국가선택', '한국' 글자도 설정 글꼴을 따라가게
# (제목 줄 안에 있어서 앱 글꼴 설정이 안 닿던 곳)
import os, sys, re, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
p = find('radio_korea_screen2.dart', 'lib')
if not p:
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')
FF = 'fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily'
if src.count(FF) >= 3:
    print('이미 적용돼 있어요'); sys.exit(0)

def fix_after(anchor_re, label, window=600):
    """anchor 다음에 나오는 첫 TextStyle( 에 설정 글꼴 넣기 (예전에 넣은 fontFamily 는 바꿔치기)"""
    global src
    m = list(re.finditer(anchor_re, src))
    if len(m) != 1:
        print('❌ %s (찾은 개수 %d)' % (label, len(m))); return False
    start = m[0].end()
    seg = src[start:start + window]
    t = seg.find('TextStyle(')
    if t < 0:
        print('❌ %s (글자 모양을 못 찾음)' % label); return False
    # TextStyle( 의 짝이 맞는 ) 찾기
    depth, close = 0, -1
    for i in range(t + len('TextStyle'), len(seg)):
        if seg[i] == '(':
            depth += 1
        elif seg[i] == ')':
            depth -= 1
            if depth == 0:
                close = i
                break
    if close < 0:
        print('❌ %s (글자 모양 끝을 못 찾음)' % label); return False
    body = seg[t:close]
    if FF in body:
        print('✔ %s (이미 적용돼 있어요)' % label); return True
    pos = start + t + len('TextStyle(')
    # 예전에 넣은 고정 글꼴(fontFamily: 'SUIT' 등) 빼기
    body_new = re.sub(r"\n[ \t]*fontFamily: *'[A-Za-z]+',|fontFamily: *'[A-Za-z]+', *", '', body)
    src = src[:start + t] + body_new + src[start + close:]
    pos = start + t + len('TextStyle(')
    src = src[:pos] + FF + ', ' + src[pos:].lstrip(' ')
    print('✔ %s' % label)
    return True

ok = True
ok &= fix_after(r"Widget _toggleButton\(String label, _ViewMode mode, bool isDarkMode\) \{", '전체·방송사별·지역별·최근청취', 2500)
ok &= fix_after(r"Text\('국가선택',", '국가선택', 1500)
ok &= fix_after(r"child: Text\('한국',", '한국', 1500)
if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_radio_tab_font')
b = os.path.join(BK, p)
os.makedirs(os.path.dirname(b), exist_ok=True)
shutil.copyfile(p, b)
open(p, 'wb').write((src.replace('\n', '\r\n') if crlf else src).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_radio_tab_font)')
