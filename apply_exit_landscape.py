# -*- coding: utf-8 -*-
# 가로 화면에서 종료 창(+ 리뷰·업데이트 창)이 넘쳐서 종료 버튼이 안 보이던 것
#  1) 창 폭 최대 420 (가로에서 창이 화면만큼 넓어져 그림도 같이 커졌음)
#  2) 위 그림 높이는 화면 높이의 22%까지만 (세로 화면에서는 지금과 같음)
#  3) 그래도 모자라면 창 안이 스크롤
import os, sys

PD = os.path.join('lib', 'widgets', 'photo_dialog.dart')
EX = os.path.join('lib', 'widgets', 'exit_confirm_dialog.dart')

OPEN_PD = (
"""        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParanBanner(image: image, bg: bg, isDark: isDark),""",
"""        // 가로 화면: 창이 너무 넓어지지 않게 + 그래도 모자라면 스크롤 (버튼이 밀려나지 않게)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParanBanner(image: image, bg: bg, isDark: isDark),""",
)
OPEN_EX = (
"""        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그림 + 경계 가운데 Paransori""",
"""        // 가로 화면: 창이 너무 넓어지지 않게 + 그래도 모자라면 스크롤 (종료 버튼이 밀려나지 않게)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그림 + 경계 가운데 Paransori""",
)
CLOSE = (
"""          ],
        ),
      );
    },
  );
  return ok == true;""",
"""          ],
        ),
          ),
        ),
      );
    },
  );
  return ok == true;""",
)

EDITS = {
    PD: [
        OPEN_PD,
        CLOSE,
        (
"""AspectRatio(
aspectRatio: 2.2,
child: Stack(""",
"""// 그림 높이: 폭에 맞춘 높이(2.2:1) — 단 가로 화면처럼 낮은 화면에서는 화면 높이의 22%까지만
LayoutBuilder(
builder: (context, c) => SizedBox(
width: double.infinity,
height: (c.maxWidth / 2.2).clamp(0.0, MediaQuery.of(context).size.height * 0.22).toDouble(),
child: Stack(""",
        ),
        (
"""],
),
),
// 경계 가운데 Paransori""",
"""],
),
),
),
// 경계 가운데 Paransori""",
        ),
    ],
    EX: [
        OPEN_EX,
        CLOSE,
    ],
}

MARK = (EX, 'maxWidth: 420')


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    if os.path.exists(MARK[0]):
        with open(MARK[0], 'rb') as f:
            if MARK[1].encode() in f.read():
                print('이미 적용돼 있어요')
                return
    out = {}
    ok = True
    for rel, pairs in EDITS.items():
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(rel, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[rel] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for rel, text in out.items():
        with open(rel, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
