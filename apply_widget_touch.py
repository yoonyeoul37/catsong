# -*- coding: utf-8 -*-
# 위젯 이전 · 다음 버튼: 아이콘 크기는 그대로, 누르는 칸만 48dp로 넓히기
# (재생 버튼 옆 간격을 조금 줄여서 전체 폭은 거의 그대로)
import os, sys

RES = os.path.join('android', 'app', 'src', 'main', 'res', 'layout')

# 4×2 · 4×3 (두 파일 똑같음)
WIDE = [
    (
"""                android:id="@+id/widget_prev"
                android:layout_width="44dp"
                android:layout_height="44dp"
                android:padding="9dp\"""",
"""                android:id="@+id/widget_prev"
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:padding="11dp\"""",
    ),
    (
"""                android:layout_width="46dp"
                android:layout_height="46dp"
                android:layout_marginStart="4dp"
                android:layout_marginEnd="4dp\"""",
"""                android:layout_width="46dp"
                android:layout_height="46dp"
                android:layout_marginStart="2dp"
                android:layout_marginEnd="2dp\"""",
    ),
    (
"""                android:id="@+id/widget_next"
                android:layout_width="44dp"
                android:layout_height="44dp"
                android:padding="9dp\"""",
"""                android:id="@+id/widget_next"
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:padding="11dp\"""",
    ),
]

# 세로 2×3
TALL = [
    (
"""            android:orientation="horizontal"
            android:paddingStart="6dp"
            android:paddingEnd="6dp">

            <ImageView
                android:id="@+id/widget_prev"
                android:layout_width="40dp"
                android:layout_height="40dp"
                android:padding="9dp\"""",
"""            android:orientation="horizontal"
            android:paddingStart="2dp"
            android:paddingEnd="2dp">

            <ImageView
                android:id="@+id/widget_prev"
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:padding="13dp\"""",
    ),
    (
"""                android:layout_width="44dp"
                android:layout_height="44dp"
                android:layout_marginStart="8dp"
                android:layout_marginEnd="8dp\"""",
"""                android:layout_width="44dp"
                android:layout_height="44dp"
                android:layout_marginStart="4dp"
                android:layout_marginEnd="4dp\"""",
    ),
    (
"""                android:id="@+id/widget_next"
                android:layout_width="40dp"
                android:layout_height="40dp"
                android:padding="9dp\"""",
"""                android:id="@+id/widget_next"
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:padding="13dp\"""",
    ),
]

EDITS = {
    os.path.join(RES, 'widget_player.xml'): WIDE,
    os.path.join(RES, 'widget_player2.xml'): WIDE,
    os.path.join(RES, 'widget_player3.xml'): TALL,
}


def tags(s):
    return (s.count('<') - s.count('>'), s.count('"') % 2)


def main():
    out = {}
    ok = True
    done = 0
    for path, pairs in EDITS.items():
        name = os.path.basename(path)
        if not os.path.exists(path):
            print('❌ 파일이 없어요:', path)
            ok = False
            continue
        with open(path, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        if 'android:id="@+id/widget_prev"\n                android:layout_width="48dp"' in text:
            done += 1
            continue
        before = tags(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if tags(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[path] = text.replace('\n', '\r\n') if crlf else text
    if done == len(EDITS):
        print('이미 적용돼 있어요')
        return
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for path, text in out.items():
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
