# -*- coding: utf-8 -*-
# 5단계: 다크 모드를 한 단계 밝고 따뜻하게 (숲 SOOP 느낌)
# - 거의 검정(#17140F) 바탕 → 따뜻한 진회색(#1C1A17)
# - 카드·창·칩·선도 같이 한 단계 밝게, 회색 글씨도 조금 밝게
# - 다크 모드일 때 쓰는 자리만 바꿈 (라이트 모드 먹색 버튼·글자는 그대로)
# - 가사 화면 사진 자리, 녹음기(늘 어두운 화면)는 그대로
import os, re, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

# 옛 색 → 새 색
NEW = {
    '17140F': '1C1A17',  # 바탕
    '1F1B15': '23211D',  # 아래에서 올라오는 창
    '1F1B16': '23211D',
    '1F1C18': '23211D',
    '26221C': '2A2723',  # 창·카드
    '26221A': '2A2723',
    '2A251D': '2D2A26',  # 카드
    '2A251E': '2D2A26',
    '332E26': '36322D',  # 칩·안쪽 카드
    '35302A': '38342F',
    '3A342B': '403C36',  # 선
    'A29A8B': 'AFA798',  # 회색 글씨
}
# 이 색들은 다크에서만 쓰여서, 라이트 쪽 자리만 빼고 바꿈
FAMILY = set(NEW) - {'17140F'}
SKIP_FILES = {'voice_recorder_screen.dart', 'lyrics_card_sheet.dart'}

COLOR = re.compile(r'Color\(0x[Ff]{2}([0-9A-Fa-f]{6})\)')
DARK_COND = r'(?:\b(?:widget\.)?_?(?:isDark\w*|dark\w*|d|tvDark)|==\s*Colors\.white)'
DARK_TRUE = re.compile(DARK_COND + r'\s*\?\s*(?:const\s+)?$')
DARK_ELSE = re.compile(DARK_COND + r'\s*\?[^?;]*?:\s*(?:const\s+)?$')


def classify(text, start, hexv, in_light_pal):
    before = text[max(0, start - 160):start]
    before = re.split(r'[;{]', before)[-1]  # 같은 문장 안만 보기
    if DARK_TRUE.search(before):
        return True
    if DARK_ELSE.search(before):
        return False  # 라이트 쪽
    if in_light_pal:
        return False
    line_start = text.rfind('\n', 0, start) + 1
    line = text[line_start:text.find('\n', start)]
    if '? const _Pal(' in line or '_EqPal(true' in line:
        return True
    if hexv == '17140F':
        return 'systemNavigationBarColor' in line
    return hexv in FAMILY


def light_pal_ranges(text):
    out = []
    for m in re.finditer(r'static const light = _Pal\(', text):
        out.append((m.start(), text.find(');', m.start())))
    return out


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    tp = os.path.join(LIB, 'providers', 'theme_provider.dart')
    if not os.path.exists(tp):
        print('❌ lib 폴더를 못 찾았어요. 프로젝트 폴더(mp3_player_new)에 두고 실행해 주세요')
        sys.exit(1)
    if '0xFF1C1A17' in open(tp, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    total = 0
    for dp, _, fs in os.walk(LIB):
        for f in sorted(fs):
            if not f.endswith('.dart') or f in SKIP_FILES:
                continue
            path = os.path.join(dp, f)
            raw = open(path, 'rb').read().decode('utf-8')
            crlf = '\r\n' in raw
            text = raw.replace('\r\n', '\n')
            ranges = light_pal_ranges(text)
            n = 0
            parts = []
            last = 0
            for m in COLOR.finditer(text):
                hexv = m.group(1).upper()
                if hexv not in NEW:
                    continue
                in_light = any(a <= m.start() <= b for a, b in ranges)
                if f == 'lyrics_screen.dart' and hexv == '17140F':
                    continue  # 가사 화면은 사진 따라 정해져서 그대로
                if not classify(text, m.start(), hexv, in_light):
                    continue
                parts.append(text[last:m.start()])
                parts.append('Color(0xFF%s)' % NEW[hexv])
                last = m.end()
                n += 1
            if n == 0:
                continue
            parts.append(text[last:])
            new = ''.join(parts)
            if balanced(text) and not balanced(new):
                print('❌ 괄호가 안 맞아요:', f)
                ok = False
            print('✔ %s (%d곳)' % (f, n))
            total += n
            out.append((path, new.replace('\n', '\r\n') if crlf else new))
    if not ok or not out:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요 (모두 %d곳). flutter run 으로 확인해 보세요.' % total)


if __name__ == '__main__':
    main()
