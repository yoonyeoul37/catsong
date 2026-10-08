# -*- coding: utf-8 -*-
# 가사 카드 3단계: 글자 고치기(줄바꿈) · 그라데이션 배경 · 내 사진 목록(가사 배경과 같이) + 밝기 자동
import os, re, sys

P = os.path.join('lib', 'widgets', 'lyrics_card_sheet.dart')
if not os.path.exists(P):
    sys.exit('❌ lyrics_card_sheet.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
c = raw.replace('\r\n', '\n')
if '_editText' in c:
    sys.exit('이미 적용돼 있어요.')
if '_titlePos' not in c:
    sys.exit('❌ 2단계(apply_lyrics_card2.py)를 먼저 해주세요.')

def rep(old, new, name, count=1):
    global c
    n = c.count(old)
    if n != count:
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

# 1) 불러오기
rep("import 'package:share_plus/share_plus.dart';\n",
    "import 'package:share_plus/share_plus.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n",
    '불러오기')

# 2) 그라데이션 목록 (색 목록 바로 아래)
m = re.search(r"const _kCardColors = <\(String, Color, bool\)>\[\n.*?\n\];\n", c, re.S)
if not m:
    sys.exit('❌ [색 목록] 을 못 찾았어요.')
c = c[:m.end()] + (
"\n"
"/// 그라데이션 배경 (요즘 인기 있는 스타일)\n"
"const _kCardGradients = <(String, List<Color>)>[\n"
"  ('밤하늘', [Color(0xFF232A4D), Color(0xFF5B4A7A)]),\n"
"  ('노을', [Color(0xFF6B4A3A), Color(0xFFE0915F)]),\n"
"  ('바다', [Color(0xFF1F4E6B), Color(0xFF6FB3C9)]),\n"
"  ('라벤더', [Color(0xFF4A3F7A), Color(0xFFC79ACF)]),\n"
"  ('숲', [Color(0xFF233D32), Color(0xFF7FA77A)]),\n"
"];\n") + c[m.end():]
print('✔ 그라데이션 목록')

# 3) 상태: 고친 글자 · 내 사진 목록 · 내 사진 밝기
rep("bool _busy = false;\n",
"bool _busy = false;\n"
"\n"
"// ── 3단계 ──\n"
"String? _text; // 고친 가사 (없으면 처음 고른 그대로)\n"
"String get _line => _text ?? widget.line;\n"
"List<String> _myList = []; // 내 사진 목록 (가사 배경 '내 사진'과 같이 씀)\n"
"bool _mineLight = false; // 내 사진이 밝은지\n"
"\n"
"@override\n"
"void initState() {\n"
"  super.initState();\n"
"  SharedPreferences.getInstance().then((p) {\n"
"    final l = (p.getStringList('lyricsMyPhotos') ?? []).where((f) => File(f).existsSync()).toList();\n"
"    if (mounted) setState(() => _myList = l);\n"
"  });\n"
"}\n"
"\n"
"/// 사진 위쪽 60%가 밝은지 재보기 → 글자색 자동\n"
"Future<bool> _isBright(String path) async {\n"
"  try {\n"
"    final bytes = await File(path).readAsBytes();\n"
"    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 40);\n"
"    final frame = await codec.getNextFrame();\n"
"    final img = frame.image;\n"
"    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);\n"
"    if (data == null) return false;\n"
"    final w = img.width, rows = (img.height * 0.6).round();\n"
"    var sum = 0.0;\n"
"    var n = 0;\n"
"    for (var y = 0; y < rows; y++) {\n"
"      for (var x = 0; x < w; x++) {\n"
"        final i = (y * w + x) * 4;\n"
"        sum += 0.299 * data.getUint8(i) + 0.587 * data.getUint8(i + 1) + 0.114 * data.getUint8(i + 2);\n"
"        n++;\n"
"      }\n"
"    }\n"
"    img.dispose();\n"
"    return n > 0 && sum / n > 150;\n"
"  } catch (_) {\n"
"    return false;\n"
"  }\n"
"}\n"
"\n"
"/// 내 사진 하나로 배경 바꾸기\n"
"Future<void> _useMine(String path) async {\n"
"  final light = await _isBright(path);\n"
"  if (!mounted) return;\n"
"  setState(() {\n"
"    _mine = path;\n"
"    _mineLight = light;\n"
"    _kind = _BgKind.mine;\n"
"  });\n"
"}\n"
"\n"
"/// ✏️ 글자 고치기 (엔터로 줄 바꾸기 · 오타 고치기)\n"
"Future<void> _editText() async {\n"
"  _vib();\n"
"  final dark = context.read<ThemeProvider>().isDarkMode;\n"
"  final bg = dark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);\n"
"  final card = dark ? const Color(0xFF332E26) : Colors.white;\n"
"  final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n"
"  final sub = dark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n"
"  final line = dark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);\n"
"  final ctrl = TextEditingController(text: _line);\n"
"  final result = await showDialog<String>(\n"
"    context: context,\n"
"    builder: (ctx) => Dialog(\n"
"      backgroundColor: bg,\n"
"      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),\n"
"      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),\n"
"      child: Padding(\n"
"        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),\n"
"        child: Column(\n"
"          mainAxisSize: MainAxisSize.min,\n"
"          crossAxisAlignment: CrossAxisAlignment.stretch,\n"
"          children: [\n"
"            Row(\n"
"              children: [\n"
"                Expanded(\n"
"                  child: Text('글자 고치기',\n"
"                      style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n"
"                ),\n"
"                ParanCloseX(onTap: () => Navigator.pop(ctx)),\n"
"              ],\n"
"            ),\n"
"            const SizedBox(height: 4),\n"
"            Text('엔터로 줄을 바꿀 수 있어요', style: TextStyle(color: sub, fontSize: 12)),\n"
"            const SizedBox(height: 12),\n"
"            Container(\n"
"              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),\n"
"              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),\n"
"              child: TextField(\n"
"                controller: ctrl,\n"
"                autofocus: true,\n"
"                minLines: 3,\n"
"                maxLines: 8,\n"
"                keyboardType: TextInputType.multiline,\n"
"                textAlign: TextAlign.center,\n"
"                style: TextStyle(color: ink, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),\n"
"                decoration: const InputDecoration(border: InputBorder.none),\n"
"              ),\n"
"            ),\n"
"            const SizedBox(height: 14),\n"
"            Row(\n"
"              children: [\n"
"                Expanded(\n"
"                  child: SizedBox(\n"
"                    height: 48,\n"
"                    child: OutlinedButton(\n"
"                      onPressed: () => Navigator.pop(ctx, widget.line), // 처음 고른 가사로\n"
"                      style: OutlinedButton.styleFrom(\n"
"                        foregroundColor: ink,\n"
"                        side: BorderSide(color: line),\n"
"                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n"
"                      ),\n"
"                      child: const Text('원래대로', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),\n"
"                    ),\n"
"                  ),\n"
"                ),\n"
"                const SizedBox(width: 8),\n"
"                Expanded(\n"
"                  child: SizedBox(\n"
"                    height: 48,\n"
"                    child: ElevatedButton(\n"
"                      onPressed: () => Navigator.pop(ctx, ctrl.text),\n"
"                      style: ElevatedButton.styleFrom(\n"
"                        backgroundColor: ink,\n"
"                        foregroundColor: bg,\n"
"                        elevation: 0,\n"
"                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n"
"                      ),\n"
"                      child: const Text('적용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),\n"
"                    ),\n"
"                  ),\n"
"                ),\n"
"              ],\n"
"            ),\n"
"          ],\n"
"        ),\n"
"      ),\n"
"    ),\n"
"  );\n"
"  ctrl.dispose();\n"
"  if (result == null || !mounted) return;\n"
"  // 앞뒤 빈 줄 정리 (비우면 처음 가사로)\n"
"  final t = result.split('\\n').map((l) => l.trimRight()).join('\\n').trim();\n"
"  setState(() => _text = (t.isEmpty || t == widget.line) ? null : t);\n"
"}\n",
'글자 고치기·내 사진 목록')

# 4) 밝기
rep("case _BgKind.color:\nreturn _kCardColors[_color].$3;\ncase _BgKind.mine:\nreturn false; // 내 사진은 어둡게 막을 깔고 흰 글자\n",
    "case _BgKind.color:\nreturn _color < _kCardColors.length && _kCardColors[_color].$3; // 그라데이션은 어두운 색이라 흰 글자\n"
    "case _BgKind.mine:\nreturn _mineLight; // 내 사진은 밝기 재서 자동\n",
    '밝기')

# 5) 고친 글자 쓰기
rep("final lines = widget.line.split('\\n');\n", "final lines = _line.split('\\n');\n", '줄 나누기')
rep("Text(\nwidget.line,\ntextAlign: align,\n", "Text(\n_line,\ntextAlign: align,\n", '카드 글자')

# 6) 배경 그리기: 그라데이션
rep("bg = Container(color: _kCardColors[_color].$2);\n",
    "bg = _color < _kCardColors.length\n"
    "    ? Container(color: _kCardColors[_color].$2)\n"
    "    : DecoratedBox(\n"
    "        decoration: BoxDecoration(\n"
    "          gradient: LinearGradient(\n"
    "            begin: Alignment.topLeft,\n"
    "            end: Alignment.bottomRight,\n"
    "            colors: _kCardGradients[_color - _kCardColors.length].$2,\n"
    "          ),\n"
    "        ),\n"
    "      );\n",
    '그라데이션 그리기')

# 7) 색 고르기 칸: 색 + 그라데이션
rep("itemCount: _kCardColors.length,\n", "itemCount: _kCardColors.length + _kCardGradients.length,\n", '색 칸 개수')
rep("child: Container(\ndecoration: BoxDecoration(\ncolor: _kCardColors[i].$2,\nshape: BoxShape.circle,\nborder: Border.all(color: line), // 크림색도 바탕과 구분되게\n),\n),\n",
    "child: Container(\n"
    "decoration: BoxDecoration(\n"
    "color: i < _kCardColors.length ? _kCardColors[i].$2 : null,\n"
    "gradient: i < _kCardColors.length\n"
    "    ? null\n"
    "    : LinearGradient(\n"
    "        begin: Alignment.topLeft,\n"
    "        end: Alignment.bottomRight,\n"
    "        colors: _kCardGradients[i - _kCardColors.length].$2,\n"
    "      ),\n"
    "shape: BoxShape.circle,\n"
    "border: Border.all(color: line), // 크림색도 바탕과 구분되게\n"
    "),\n"
    "),\n",
    '색 칸 그라데이션')

# 8) 내 사진 칸: 추가 + 목록
rex(r"case _BgKind\.mine:\noptions = Row\(\n.*?\n\);\nbreak;\n\}\n",
"case _BgKind.mine:\n"
"options = ListView(\n"
"scrollDirection: Axis.horizontal,\n"
"children: [\n"
"// + 추가\n"
"GestureDetector(\n"
"onTap: _pickMine,\n"
"child: Container(\n"
"width: 52,\n"
"decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),\n"
"child: Icon(Icons.add_rounded, color: sub, size: 24),\n"
"),\n"
"),\n"
"for (final f in _myList) ...[\n"
"const SizedBox(width: 8),\n"
"GestureDetector(\n"
"onTap: () {\n"
"HapticFeedback.selectionClick();\n"
"_useMine(f);\n"
"},\n"
"child: Container(\n"
"width: 52,\n"
"padding: const EdgeInsets.all(2),\n"
"decoration: pickBorder(_kind == _BgKind.mine && _mine == f),\n"
"child: ClipRRect(\n"
"borderRadius: BorderRadius.circular(9),\n"
"child: Image.file(File(f), fit: BoxFit.cover, cacheWidth: 160,\n"
"errorBuilder: (_, __, ___) => Container(color: line)),\n"
"),\n"
"),\n"
"),\n"
"],\n"
"],\n"
");\n"
"break;\n"
"}\n",
'내 사진 목록 칸')

# 9) 사진 추가 → 목록에도 넣기 (가사 배경 '내 사진'과 같이)
rex(r"/// 내 사진 고르기\nFuture<void> _pickMine\(\) async \{\n.*?\n\}\n\}\n\n@override\nWidget build",
"/// 내 사진 고르기 → 가사 배경 '내 사진' 목록에도 같이 넣기\n"
"Future<void> _pickMine() async {\n"
"_vib();\n"
"try {\n"
"final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);\n"
"if (x == null || !mounted) return;\n"
"if (!_myList.contains(x.path)) {\n"
"setState(() => _myList.insert(0, x.path));\n"
"final p = await SharedPreferences.getInstance();\n"
"await p.setStringList('lyricsMyPhotos', _myList);\n"
"}\n"
"await _useMine(x.path);\n"
"} catch (e) {\n"
"debugPrint('사진 고르기 오류: $e');\n"
"if (mounted) showParanToast(context, '사진을 불러오지 못했어요', error: true);\n"
"}\n"
"}\n"
"\n"
"@override\n"
"Widget build",
'사진 추가')

# 10) '내 사진' 칩: 목록 있으면 첫 장, 없으면 고르기
rep("chip('내 사진', _BgKind.mine, () {\n                            if (_mine == null) {\n                              _pickMine();\n                            } else {\n                              setState(() => _kind = _BgKind.mine);\n                            }\n                          }),\n",
    "chip('내 사진', _BgKind.mine, () {\n"
    "                            if (_mine != null) {\n"
    "                              setState(() => _kind = _BgKind.mine);\n"
    "                            } else if (_myList.isNotEmpty) {\n"
    "                              _useMine(_myList.first);\n"
    "                            } else {\n"
    "                              _pickMine();\n"
    "                            }\n"
    "                          }),\n",
    '내 사진 칩')

# 11) 탭에 '글자' 추가 (누르면 바로 고치는 창) + 카드 눌러도 고치기
rep("        (3, '제목', Icons.title_rounded),\n", "        (3, '제목', Icons.title_rounded),\n        (4, '글자', Icons.edit_rounded),\n", '글자 탭')
rep("            onTap: () {\n              HapticFeedback.selectionClick();\n              setState(() => _tab = i);\n            },\n",
    "            onTap: () {\n"
    "              HapticFeedback.selectionClick();\n"
    "              if (i == 4) {\n"
    "                _editText(); // 글자는 바로 고치는 창\n"
    "                return;\n"
    "              }\n"
    "              setState(() => _tab = i);\n"
    "            },\n",
    '글자 탭 누르기')
rep("      child: _card(),\n",
    "      // 카드 글자를 누르면 고치기\n"
    "      child: GestureDetector(onTap: _editText, child: _card()),\n",
    '카드 누르면 고치기')

out = c.replace('\n', '\r\n') if crlf else c
open(P, 'w', encoding='utf-8', newline='').write(out)
print('\n✅ 끝! 글자 고치기 · 그라데이션 · 내 사진 목록이 생겼어요.')
