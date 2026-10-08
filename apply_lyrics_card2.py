# -*- coding: utf-8 -*-
# 가사 카드 2단계: 탭(배경·글꼴·비율·제목) + 글꼴 4종·정렬·크기 + 비율 3가지 + 제목 위치
import os, re, sys

P = os.path.join('lib', 'widgets', 'lyrics_card_sheet.dart')
if not os.path.exists(P):
    sys.exit('❌ lyrics_card_sheet.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
c = raw.replace('\r\n', '\n')
if '_titlePos' in c:
    sys.exit('이미 적용돼 있어요.')
if "final n = lines.length;" not in c:
    sys.exit('❌ 1단계(apply_lyrics_multiline.py)를 먼저 해주세요.')

def rep(old, new, name):
    global c
    n = c.count(old)
    if n != 1:
        sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
    c = c.replace(old, new)
    print(f'✔ {name}')

def rex(pattern, new, name):
    global c
    m = list(re.finditer(pattern, c, re.S))
    if len(m) != 1:
        sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({len(m)}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
    c = c[:m[0].start()] + new + c[m[0].end():]
    print(f'✔ {name}')

# 1) 고른 값들
rep("bool _busy = false;\n",
"bool _busy = false;\n"
"\n"
"// ── 꾸미기 (2단계) ──\n"
"int _tab = 0; // 0 배경 · 1 글꼴 · 2 비율 · 3 제목\n"
"int _font = 0; // 글꼴\n"
"bool _left = false; // 왼쪽 정렬\n"
"double _scale = 1.0; // 글자 크기 (작게 0.85 · 보통 1 · 크게 1.15)\n"
"int _ratio = 2; // 비율 (기본 4:5)\n"
"int _titlePos = 1; // 제목·가수: 0 위 · 1 아래 · 2 숨기기\n"
"\n"
"static const _fonts = ['깔끔', '편지', '손글씨', '귀여움'];\n"
"static const _ratios = <(String, double)>[('스토리 9:16', 9 / 16), ('피드 1:1', 1.0), ('4:5', 4 / 5)];\n"
"\n"
"/// 고른 글꼴로 바꾸기 (f를 주면 그 글꼴로 — 글꼴 고르는 칸 미리보기용)\n"
"TextStyle _fontStyle(TextStyle s, [int? f]) {\n"
"  switch (f ?? _font) {\n"
"    case 1:\n"
"      return GoogleFonts.gowunBatang(textStyle: s.copyWith(fontWeight: FontWeight.w700));\n"
"    case 2:\n"
"      return GoogleFonts.nanumPenScript(\n"
"          textStyle: s.copyWith(fontSize: (s.fontSize ?? 20) * 1.3, fontWeight: FontWeight.w400, height: 1.25));\n"
"    case 3:\n"
"      return GoogleFonts.gaegu(textStyle: s.copyWith(fontWeight: FontWeight.w700));\n"
"    default:\n"
"      return s;\n"
"  }\n"
"}\n",
"꾸미기 값")

# 2) 크기 배율
rex(r"final size = n >= 4 \? 17\.0 : \(n == 3 \? 19\.0 : \(longest <= 14 \? 25\.0 : \(longest <= 28 \? 22\.0 : 19\.0\)\)\);\n",
"final size = (n >= 4 ? 17.0 : (n == 3 ? 19.0 : (longest <= 14 ? 25.0 : (longest <= 28 ? 22.0 : 19.0)))) * _scale;\n"
"final align = _left ? TextAlign.left : TextAlign.center;\n"
"// 노래 제목 · 가수 (위·아래·숨기기)\n"
"final titleText = SizedBox(\n"
"  width: double.infinity,\n"
"  child: Text(\n"
"    '${widget.title} · ${widget.artist}',\n"
"    textAlign: align,\n"
"    maxLines: 1,\n"
"    overflow: TextOverflow.ellipsis,\n"
"    style: TextStyle(color: ink.withOpacity(0.75), fontSize: 12.5, fontWeight: FontWeight.w600, shadows: shadow),\n"
"  ),\n"
");\n",
"글자 크기·정렬·제목")

# 3) 비율
rep("aspectRatio: 4 / 5, // 인스타·카톡에 잘 맞는 크기\n",
    "aspectRatio: _ratios[_ratio].$2, // 스토리 9:16 · 피드 1:1 · 4:5\n",
    "비율")

# 4) 카드 안 글자 배치
rex(r"Padding\(\npadding: const EdgeInsets\.fromLTRB\(28, 26, 28, 22\),\n.*?Align\(alignment: Alignment\.bottomRight, child: _watermark\(ink, shadow\)\),\n\],\n\),\n\),\n",
"Padding(\n"
"padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),\n"
"child: Column(\n"
"crossAxisAlignment: CrossAxisAlignment.start,\n"
"children: [\n"
"Icon(Icons.format_quote_rounded, color: ink.withOpacity(0.55), size: 30),\n"
"const Spacer(),\n"
"if (_titlePos == 0) ...[titleText, const SizedBox(height: 14)],\n"
"// 고른 가사 (가운데 크게)\n"
"SizedBox(\n"
"width: double.infinity,\n"
"child: Text(\n"
"widget.line,\n"
"textAlign: align,\n"
"maxLines: 10,\n"
"overflow: TextOverflow.ellipsis,\n"
"style: _fontStyle(TextStyle(\n"
"color: ink,\n"
"fontSize: size,\n"
"height: 1.45,\n"
"fontWeight: FontWeight.w800,\n"
"letterSpacing: -0.3,\n"
"shadows: shadow,\n"
")),\n"
"),\n"
"),\n"
"if (_titlePos == 1) ...[const SizedBox(height: 16), titleText],\n"
"const Spacer(),\n"
"// 오른쪽 아래 Paransori (항상)\n"
"Align(alignment: Alignment.bottomRight, child: _watermark(ink, shadow)),\n"
"],\n"
"),\n"
"),\n",
"카드 안 배치")

# 5) 미리보기 크기 (비율 따라)
rep("final maxCardW = (MediaQuery.sizeOf(context).height * 0.42) * 4 / 5; // 작은 폰에서도 아래 버튼이 보이게\n",
"final maxCardW = (MediaQuery.sizeOf(context).height * 0.42) * _ratios[_ratio].$2; // 작은 폰에서도 아래 버튼이 보이게\n"
"\n"
"// 작은 알약 버튼 (고르면 먹색)\n"
"Widget pill(String label, bool on, VoidCallback onTap) => GestureDetector(\n"
"      onTap: () {\n"
"        HapticFeedback.selectionClick();\n"
"        onTap();\n"
"      },\n"
"      child: Container(\n"
"        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),\n"
"        decoration: BoxDecoration(color: on ? ink : card, borderRadius: BorderRadius.circular(12)),\n"
"        child: Text(label,\n"
"            style: TextStyle(\n"
"                color: on ? bg : sub, fontSize: 13, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),\n"
"      ),\n"
"    );\n",
"미리보기 크기·알약 버튼")

# 6) 아래: 탭 + 칸
rex(r"  // 배경 종류\n  Row\(\n.*?  SizedBox\(height: 56, child: options\),\n",
"  // 탭: 배경 · 글꼴 · 비율 · 제목\n"
"  Row(\n"
"    children: [\n"
"      for (final (i, label, icon) in const [\n"
"        (0, '배경', Icons.photo_outlined),\n"
"        (1, '글꼴', Icons.text_fields_rounded),\n"
"        (2, '비율', Icons.crop_rounded),\n"
"        (3, '제목', Icons.title_rounded),\n"
"      ])\n"
"        Expanded(\n"
"          child: GestureDetector(\n"
"            behavior: HitTestBehavior.opaque,\n"
"            onTap: () {\n"
"              HapticFeedback.selectionClick();\n"
"              setState(() => _tab = i);\n"
"            },\n"
"            child: Column(\n"
"              children: [\n"
"                Icon(icon, size: 20, color: _tab == i ? ink : sub),\n"
"                const SizedBox(height: 3),\n"
"                Text(label,\n"
"                    style: TextStyle(\n"
"                        color: _tab == i ? ink : sub,\n"
"                        fontSize: 11.5,\n"
"                        fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500)),\n"
"                const SizedBox(height: 6),\n"
"                Container(\n"
"                  height: 2.5,\n"
"                  width: 22,\n"
"                  decoration: BoxDecoration(\n"
"                      color: _tab == i ? ink : Colors.transparent, borderRadius: BorderRadius.circular(2)),\n"
"                ),\n"
"              ],\n"
"            ),\n"
"          ),\n"
"        ),\n"
"    ],\n"
"  ),\n"
"  const SizedBox(height: 12),\n"
"  SizedBox(\n"
"    height: 104,\n"
"    child: _tab == 1\n"
"        // 글꼴 4종 + 정렬 + 크기\n"
"        ? Column(\n"
"            children: [\n"
"              Row(\n"
"                children: [\n"
"                  for (var i = 0; i < _fonts.length; i++) ...[\n"
"                    if (i > 0) const SizedBox(width: 8),\n"
"                    Expanded(\n"
"                      child: GestureDetector(\n"
"                        onTap: () {\n"
"                          HapticFeedback.selectionClick();\n"
"                          setState(() => _font = i);\n"
"                        },\n"
"                        child: Container(\n"
"                          height: 54,\n"
"                          decoration: BoxDecoration(\n"
"                            color: card,\n"
"                            borderRadius: BorderRadius.circular(12),\n"
"                            border: Border.all(color: _font == i ? ink : Colors.transparent, width: 2),\n"
"                          ),\n"
"                          child: Column(\n"
"                            mainAxisAlignment: MainAxisAlignment.center,\n"
"                            children: [\n"
"                              Text('가나다',\n"
"                                  style: _fontStyle(\n"
"                                      TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700), i)),\n"
"                              const SizedBox(height: 2),\n"
"                              Text(_fonts[i], style: TextStyle(color: sub, fontSize: 10.5)),\n"
"                            ],\n"
"                          ),\n"
"                        ),\n"
"                      ),\n"
"                    ),\n"
"                  ],\n"
"                ],\n"
"              ),\n"
"              const SizedBox(height: 10),\n"
"              Row(\n"
"                children: [\n"
"                  pill('가운데', !_left, () => setState(() => _left = false)),\n"
"                  const SizedBox(width: 6),\n"
"                  pill('왼쪽', _left, () => setState(() => _left = true)),\n"
"                  const Spacer(),\n"
"                  pill('A-', _scale < 1, () => setState(() => _scale = 0.85)),\n"
"                  const SizedBox(width: 6),\n"
"                  pill('A', _scale == 1, () => setState(() => _scale = 1.0)),\n"
"                  const SizedBox(width: 6),\n"
"                  pill('A+', _scale > 1, () => setState(() => _scale = 1.15)),\n"
"                ],\n"
"              ),\n"
"            ],\n"
"          )\n"
"        : _tab == 2\n"
"            // 비율\n"
"            ? Align(\n"
"                alignment: Alignment.topLeft,\n"
"                child: Wrap(\n"
"                  spacing: 6,\n"
"                  children: [\n"
"                    for (var i = 0; i < _ratios.length; i++)\n"
"                      pill(_ratios[i].$1, _ratio == i, () => setState(() => _ratio = i)),\n"
"                  ],\n"
"                ),\n"
"              )\n"
"            : _tab == 3\n"
"                // 제목·가수 위치\n"
"                ? Align(\n"
"                    alignment: Alignment.topLeft,\n"
"                    child: Wrap(\n"
"                      spacing: 6,\n"
"                      children: [\n"
"                        pill('위', _titlePos == 0, () => setState(() => _titlePos = 0)),\n"
"                        pill('아래', _titlePos == 1, () => setState(() => _titlePos = 1)),\n"
"                        pill('숨기기', _titlePos == 2, () => setState(() => _titlePos = 2)),\n"
"                      ],\n"
"                    ),\n"
"                  )\n"
"                // 배경 (사진 · 색 · 내 사진)\n"
"                : Column(\n"
"                    children: [\n"
"                      Row(\n"
"                        children: [\n"
"                          if (widget.photos.isNotEmpty) ...[\n"
"                            chip('사진', _BgKind.photo, () => setState(() => _kind = _BgKind.photo)),\n"
"                            const SizedBox(width: 6),\n"
"                          ],\n"
"                          chip('색', _BgKind.color, () => setState(() => _kind = _BgKind.color)),\n"
"                          const SizedBox(width: 6),\n"
"                          chip('내 사진', _BgKind.mine, () {\n"
"                            if (_mine == null) {\n"
"                              _pickMine();\n"
"                            } else {\n"
"                              setState(() => _kind = _BgKind.mine);\n"
"                            }\n"
"                          }),\n"
"                        ],\n"
"                      ),\n"
"                      const SizedBox(height: 10),\n"
"                      SizedBox(height: 56, child: options),\n"
"                    ],\n"
"                  ),\n"
"  ),\n",
"탭과 칸")

out = c.replace('\n', '\r\n') if crlf else c
open(P, 'w', encoding='utf-8', newline='').write(out)
print('\n✅ 끝! 카드 아래에 배경 · 글꼴 · 비율 · 제목 탭이 생겼어요.')
