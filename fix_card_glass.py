# -*- coding: utf-8 -*-
# 가사 카드: 유리 띠 자리에 남은 예전 코드 지우기
import os, sys
P = os.path.join('lib', 'widgets', 'lyrics_card_sheet.dart')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
start = "if (_titlePos != 0) _glassBar(ink, shadow, withTitle: _titlePos == 1),\n"
i = s.find(start)
if i < 0:
    sys.exit('❌ 유리 띠 줄을 못 찾았어요. 아무것도 안 바꿨어요.')
i += len(start)
end = "_watermark(ink, shadow),\n],\n),\n),\n"
j = s.find(end, i)
left = s[i:j]
if j < 0 or not left.startswith('padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),') or 'Widget ' in left:
    sys.exit('❌ 남은 코드 모양이 예상과 달라요. 아무것도 안 바꿨어요.')
s = s[:i] + s[j + len(end):]
open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)
print('✅ 남은 코드를 지웠어요.')
