# -*- coding: utf-8 -*-
# 가사 직접 넣기 창: 가사가 길거나 키보드가 올라오면 칸 밖으로 넘치던 것 고치기
# - 입력 칸 높이를 화면(키보드 뺀 자리)에 맞춰 정하고, 긴 가사는 칸 안에서 스크롤
# - 그래도 자리가 모자라는 작은 폰(엑스커버)은 창 전체가 살짝 스크롤
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SCREEN = os.path.join(ROOT, 'lib', 'screens', 'lyrics_screen.dart')

EDITS = [
    ('창 전체: 모자라면 스크롤',
     "              builder: (ctx, setSheet) => Column(\n"
     "                mainAxisSize: MainAxisSize.min,\n"
     "                crossAxisAlignment: CrossAxisAlignment.start,\n"
     "                children: [\n"
     "                  Center(\n"
     "                    child: Container(\n"
     "                      width: 36,\n"
     "                      height: 4,\n"
     "                      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),\n",
     "              builder: (ctx, setSheet) => SingleChildScrollView(\n"
     "               child: Column(\n"
     "                mainAxisSize: MainAxisSize.min,\n"
     "                crossAxisAlignment: CrossAxisAlignment.start,\n"
     "                children: [\n"
     "                  Center(\n"
     "                    child: Container(\n"
     "                      width: 36,\n"
     "                      height: 4,\n"
     "                      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),\n"),
    ('창 전체: 닫는 괄호',
     "                ],\n"
     "              ),\n"
     "            ),\n"
     "          ),\n"
     "        ),\n"
     "      ),\n"
     "    );\n"
     "    if (saved == true) {\n",
     "                ],\n"
     "               ),\n"
     "              ),\n"
     "            ),\n"
     "          ),\n"
     "        ),\n"
     "      ),\n"
     "    );\n"
     "    if (saved == true) {\n"),
    ('입력 칸: 화면에 맞는 높이 + 칸 안에서 스크롤',
     "                  TextField(\n"
     "                    controller: ctrl,\n"
     "                    minLines: 8,\n"
     "                    maxLines: 12,\n",
     "                  // 키보드를 뺀 남은 자리에 맞춰 높이 (긴 가사는 칸 안에서 스크롤)\n"
     "                  SizedBox(\n"
     "                   height: (MediaQuery.of(ctx).size.height -\n"
     "                           MediaQuery.of(ctx).viewInsets.bottom -\n"
     "                           MediaQuery.of(ctx).padding.top -\n"
     "                           290)\n"
     "                       .clamp(110.0, 300.0),\n"
     "                   child: TextField(\n"
     "                    controller: ctrl,\n"
     "                    expands: true,\n"
     "                    minLines: null,\n"
     "                    maxLines: null,\n"
     "                    textAlignVertical: TextAlignVertical.top,\n"),
    ('입력 칸: 닫는 괄호',
     "                        borderSide: BorderSide(color: ink, width: 1.5),\n"
     "                      ),\n"
     "                    ),\n"
     "                  ),\n"
     "                  const SizedBox(height: 6),\n",
     "                        borderSide: BorderSide(color: ink, width: 1.5),\n"
     "                      ),\n"
     "                    ),\n"
     "                   ),\n"
     "                  ),\n"
     "                  const SizedBox(height: 6),\n"),
]

MARK = 'expands: true,'


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
    if not os.path.exists(SCREEN):
        print('❌ 파일을 못 찾았어요:', SCREEN)
        sys.exit(1)
    raw = open(SCREEN, 'rb').read().decode('utf-8')
    if MARK in raw:
        print('이미 적용돼 있어요')
        return
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    before = balanced(text)
    ok = True
    for name, old, new in EDITS:
        if text.count(old) != 1:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    if before and not balanced(text):
        print('❌ 괄호가 안 맞아요')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    if crlf:
        text = text.replace('\n', '\r\n')
    open(SCREEN, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
