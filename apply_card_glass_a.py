# -*- coding: utf-8 -*-
# 가사 카드: 유리 띠를 카드 끝까지 닿는 "유리 바닥/천장"으로 (알약 모양 없애기)
import os, re, sys
P = os.path.join('lib', 'widgets', 'lyrics_card_sheet.dart')
if not os.path.exists(P):
    sys.exit('❌ lyrics_card_sheet.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_glassPlate' in s:
    sys.exit('이미 적용돼 있어요.')

def rep(pattern, new, name, regex=False):
    global s
    if regex:
        m = list(re.finditer(pattern, s, re.S))
        if len(m) != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({len(m)}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s[:m[0].start()] + new + s[m[0].end():]
    else:
        n = s.count(pattern)
        if n != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s.replace(pattern, new)
    print(f'✔ {name}')

# 1) 위쪽: 따옴표만 (유리판은 카드 맨 위에 따로)
rep(r"// 제목 '위'면 유리 띠가 맨 위로, 아니면 따옴표\n\s*if \(_titlePos == 0\)\n\s*_glassBar\(ink, shadow, withTitle: true\)\n\s*else\n",
    "", '위쪽 정리', regex=True)

# 2) 아래쪽 띠 줄 빼기 (유리판은 카드 맨 아래에 따로)
rep(r"// 맨 아래 유리 띠 \(제목 '위'면 위로 올라가서 여기선 없음\)\n\s*if \(_titlePos != 0\) _glassBar\(ink, shadow, withTitle: _titlePos == 1\),\n",
    "", '아래쪽 정리', regex=True)

# 3) 글자 자리: 유리판 높이만큼 비우기
rep("padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),\n",
    "padding: EdgeInsets.fromLTRB(28, _titlePos == 0 ? 58 : 26, 28, _titlePos == 1 ? 54 : 34),\n",
    '글자 자리')

# 4) 카드 끝까지 닿는 유리판 (위·아래) + 숨기기면 오른쪽 아래 글씨만
rep("if (veil != null) ColoredBox(color: veil),\n",
    "if (veil != null) ColoredBox(color: veil),\n"
    "// 유리판: 제목 '위'면 맨 위, '아래'면 맨 아래 (카드 끝까지)\n"
    "if (_titlePos == 0) Positioned(left: 0, right: 0, top: 0, child: _glassPlate(ink, shadow, top: true)),\n"
    "if (_titlePos == 1) Positioned(left: 0, right: 0, bottom: 0, child: _glassPlate(ink, shadow, top: false)),\n"
    "// 숨기기: 오른쪽 아래 Paransori 글씨만\n"
    "if (_titlePos == 2) Positioned(right: 18, bottom: 14, child: _watermark(ink, shadow)),\n",
    '유리판 넣기')

# 5) 유리 띠 함수 → 유리판 함수
rep(r"/// 유리 띠: \(제목 · 가수\) \+ Paransori.*?(?=/// 오른쪽 아래 작은 워터마크)",
"/// 유리판: 카드 끝까지 닿는 서리 낀 유리 (제목 · 가수 + Paransori)\n"
"Widget _glassPlate(Color ink, List<Shadow> shadow, {required bool top}) {\n"
"  final edge = BorderSide(color: _light ? Colors.black.withOpacity(0.10) : Colors.white.withOpacity(0.28));\n"
"  return Container(\n"
"    padding: const EdgeInsets.fromLTRB(20, 12, 20, 13),\n"
"    decoration: BoxDecoration(\n"
"      color: _light ? Colors.white.withOpacity(0.38) : Colors.white.withOpacity(0.14),\n"
"      border: top ? Border(bottom: edge) : Border(top: edge),\n"
"    ),\n"
"    child: Row(\n"
"      children: [\n"
"        Expanded(\n"
"          child: Text.rich(\n"
"            TextSpan(children: [\n"
"              TextSpan(text: widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),\n"
"              TextSpan(text: ' · ${widget.artist}', style: TextStyle(color: ink.withOpacity(0.75))),\n"
"            ]),\n"
"            maxLines: 1,\n"
"            overflow: TextOverflow.ellipsis,\n"
"            style: TextStyle(color: ink, fontSize: 11.5, shadows: shadow),\n"
"          ),\n"
"        ),\n"
"        const SizedBox(width: 10),\n"
"        _watermark(ink, shadow),\n"
"      ],\n"
"    ),\n"
"  );\n"
"}\n\n",
'유리판 모양', regex=True)

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)
print('\n✅ 끝! 알약 대신 카드 끝까지 닿는 유리판이 됐어요.')
