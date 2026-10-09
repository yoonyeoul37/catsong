# -*- coding: utf-8 -*-
# 다크 모드 한 단계 더 밝게 (apply_dark.py 를 먼저 실행한 뒤에)
# apply_dark.py 가 넣은 색만 골라서 바꿔요 (그 색들은 다크 자리에만 있어요)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

NEW = {
    '1C1A17': '24221F',  # 바탕
    '23211D': '2B2926',  # 아래에서 올라오는 창
    '2A2723': '32302C',  # 창·카드
    '2D2A26': '353330',  # 떠 있는 카드
    '36322D': '3E3B37',  # 칩·안쪽 카드
    '38342F': '403D39',  # 메뉴 카드
    '403C36': '4A4640',  # 선
    'AFA798': 'B8B0A2',  # 회색 글씨
}


def main():
    tp = os.path.join(LIB, 'providers', 'theme_provider.dart')
    if not os.path.exists(tp):
        print('❌ lib 폴더를 못 찾았어요. 프로젝트 폴더(mp3_player_new)에 두고 실행해 주세요')
        sys.exit(1)
    t = open(tp, 'rb').read().decode('utf-8')
    if '0xFF24221F' in t:
        print('이미 적용돼 있어요')
        return
    if '0xFF1C1A17' not in t:
        print('❌ apply_dark.py 를 먼저 실행해 주세요')
        sys.exit(1)
    out = []
    total = 0
    for dp, _, fs in os.walk(LIB):
        for f in sorted(fs):
            if not f.endswith('.dart'):
                continue
            path = os.path.join(dp, f)
            text = open(path, 'rb').read().decode('utf-8')
            new = text
            n = 0
            for old, nw in NEW.items():
                for o in ('0xFF' + old, '0xff' + old.lower()):
                    n += new.count(o)
                    new = new.replace(o, '0xFF' + nw)
            if n:
                print('✔ %s (%d곳)' % (f, n))
                total += n
                out.append((path, new))
    if not out:
        print('❌ 바꿀 곳을 못 찾았어요\n\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))  # 줄바꿈은 원래 그대로
    print('\n다 바꿨어요 (모두 %d곳). flutter run 으로 확인해 보세요.' % total)


if __name__ == '__main__':
    main()
