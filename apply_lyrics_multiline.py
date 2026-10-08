# -*- coding: utf-8 -*-
# 가사 카드 1단계: 여러 줄 고르기 (꾹 누르고 → 다른 줄 누르면 거기까지, 최대 5줄)
import os, sys

def load(p):
    if not os.path.exists(p):
        sys.exit(f'❌ {p} 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
    raw = open(p, encoding='utf-8').read()
    return raw.replace('\r\n', '\n'), '\r\n' in raw

def save(p, s, crlf):
    open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)

def rep(s, old, new, name):
    n = s.count(old)
    if n != 1:
        sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
    print(f'✔ {name}')
    return s.replace(old, new)

LS = os.path.join('lib', 'screens', 'lyrics_screen.dart')
CS = os.path.join('lib', 'widgets', 'lyrics_card_sheet.dart')
s, crlf1 = load(LS)
c, crlf2 = load(CS)
if '_selAnchor' in s:
    sys.exit('이미 적용돼 있어요.')

# ── lyrics_screen.dart ──
s = rep(s, "  DateTime _userScrolledAt = DateTime(2000); // 손으로 움직이면 잠깐 자동 멈춤\n",
"  DateTime _userScrolledAt = DateTime(2000); // 손으로 움직이면 잠깐 자동 멈춤\n"
"\n"
"  // ── 여러 줄 고르기 (가사 카드) ──\n"
"  int? _selAnchor; // 처음 꾹 누른 줄\n"
"  int? _selOther; // 마지막으로 누른 줄 (여기까지)\n"
"  List<String> _visibleLines = const []; // 지금 화면에 그린 가사 줄들\n"
"  int get _selLo => _selAnchor! < _selOther! ? _selAnchor! : _selOther!;\n"
"  int get _selHi => _selAnchor! > _selOther! ? _selAnchor! : _selOther!;\n"
"  bool _isSel(int i) => _selAnchor != null && i >= _selLo && i <= _selHi;\n"
"  List<String> get _selTexts => _selAnchor == null\n"
"      ? const []\n"
"      : [\n"
"          for (var i = _selLo; i <= _selHi && i < _visibleLines.length; i++)\n"
"            if (_visibleLines[i].trim().isNotEmpty) _visibleLines[i].trim()\n"
"        ];\n"
"\n"
"  /// 꾹 → 이 줄부터 고르기 시작\n"
"  void _startSel(int i) {\n"
"    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
"    setState(() {\n"
"      _selAnchor = i;\n"
"      _selOther = i;\n"
"    });\n"
"  }\n"
"\n"
"  /// 고르는 중 다른 줄 누르기 → 거기까지 (최대 5줄)\n"
"  void _extendSel(int i) {\n"
"    HapticFeedback.selectionClick();\n"
"    var o = i;\n"
"    if ((o - _selAnchor!).abs() > 4) o = _selAnchor! + (o > _selAnchor! ? 4 : -4);\n"
"    setState(() => _selOther = o);\n"
"  }\n"
"\n"
"  void _cancelSel() => setState(() {\n"
"        _selAnchor = null;\n"
"        _selOther = null;\n"
"      });\n",
"고르기 상태")

s = rep(s, "      if (DateTime.now().difference(_userScrolledAt).inSeconds < 4) return;\n",
"      if (DateTime.now().difference(_userScrolledAt).inSeconds < 4) return;\n"
"      if (_selAnchor != null) return; // 줄 고르는 중엔 자동으로 안 움직이기\n",
"고르는 중 자동 스크롤 멈춤")

# 시간 있는 가사
s = rep(s, "    if (lyricsProvider.lyrics.isNotEmpty) {\n      // 모든 줄을 같은 간격으로",
"    if (lyricsProvider.lyrics.isNotEmpty) {\n      _visibleLines = [for (final l in lyricsProvider.lyrics) l.text];\n      // 모든 줄을 같은 간격으로",
"시간 있는 가사 줄 기억")
s = rep(s,
"                onTap: () {\n                  playerProvider.seekTo(lyricsProvider.lyrics[index].time);\n                },\n                onLongPress: () => _openCard(lyricsProvider.lyrics[index].text, playerProvider),\n                child: Padding(\n                  padding: const EdgeInsets.symmetric(vertical: 8),\n",
"                onTap: () {\n"
"                  if (_selAnchor != null) {\n"
"                    _extendSel(index); // 고르는 중이면 여기까지 고르기\n"
"                    return;\n"
"                  }\n"
"                  playerProvider.seekTo(lyricsProvider.lyrics[index].time);\n"
"                },\n"
"                onLongPress: () => _startSel(index),\n"
"                child: AnimatedContainer(\n"
"                  duration: const Duration(milliseconds: 150),\n"
"                  decoration: BoxDecoration(\n"
"                    color: _isSel(index) ? ink.withOpacity(0.14) : Colors.transparent,\n"
"                    borderRadius: BorderRadius.circular(10),\n"
"                  ),\n"
"                  child: Padding(\n"
"                  padding: const EdgeInsets.symmetric(vertical: 8),\n",
"시간 있는 가사 꾹·누르기")
s = rep(s,
"                        color: index == lyricsProvider.currentLineIndex ? ink : ink.withOpacity(0.5),\n",
"                        color: (index == lyricsProvider.currentLineIndex || _isSel(index)) ? ink : ink.withOpacity(0.5),\n",
"고른 줄 진하게")
s = rep(s,
"                      child: Text(lyricsProvider.lyrics[index].text.trim(), textAlign: TextAlign.center),\n                    ),\n                  ),\n                ),\n              ),\n",
"                      child: Text(lyricsProvider.lyrics[index].text.trim(), textAlign: TextAlign.center),\n                    ),\n                  ),\n                ),\n                ),\n              ),\n",
"괄호 맞추기")

# 시간 없는 가사
s = rep(s,
"          for (final l in plain.split('\\n'))\n            GestureDetector(\n              behavior: HitTestBehavior.opaque,\n              onLongPress: l.trim().isEmpty ? null : () => _openCard(l, playerProvider),\n              child: SizedBox(\n                width: double.infinity,\n                child: Text(\n                  l,\n                  style: TextStyle(color: ink, fontSize: 15.5, height: 1.8, shadows: shadow),\n",
"          for (var i = 0; i < _visibleLines.length; i++)\n"
"            GestureDetector(\n"
"              behavior: HitTestBehavior.opaque,\n"
"              onTap: _selAnchor != null ? () => _extendSel(i) : null,\n"
"              onLongPress: _visibleLines[i].trim().isEmpty ? null : () => _startSel(i),\n"
"              child: AnimatedContainer(\n"
"                duration: const Duration(milliseconds: 150),\n"
"                width: double.infinity,\n"
"                decoration: BoxDecoration(\n"
"                  color: _isSel(i) ? ink.withOpacity(0.14) : Colors.transparent,\n"
"                  borderRadius: BorderRadius.circular(10),\n"
"                ),\n"
"                child: Text(\n"
"                  _visibleLines[i],\n"
"                  style: TextStyle(\n"
"                      color: ink,\n"
"                      fontSize: 15.5,\n"
"                      height: 1.8,\n"
"                      fontWeight: _isSel(i) ? FontWeight.w700 : FontWeight.w400,\n"
"                      shadows: shadow),\n",
"시간 없는 가사 꾹·누르기")
s = rep(s,
"    final plain = lyricsProvider.plainLyrics.replaceAll('\\r', '').replaceAll(RegExp(r'\\n\\s*\\n\\s*\\n+'), '\\n\\n').trim();\n",
"    final plain = lyricsProvider.plainLyrics.replaceAll('\\r', '').replaceAll(RegExp(r'\\n\\s*\\n\\s*\\n+'), '\\n\\n').trim();\n"
"    _visibleLines = plain.split('\\n');\n",
"시간 없는 가사 줄 기억")

# 아래 바
s = rep(s,
"              ),\n\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildBody(",
"              ),\n"
"            // 여러 줄 고르는 중: 아래 바 (✕ · N줄 골랐어요 · 카드 만들기)\n"
"            if (_selAnchor != null)\n"
"              Positioned(\n"
"                left: 12,\n"
"                right: 12,\n"
"                bottom: MediaQuery.of(context).padding.bottom + 12,\n"
"                child: Material(\n"
"                  color: Colors.transparent,\n"
"                  child: Container(\n"
"                    padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),\n"
"                    decoration: BoxDecoration(\n"
"                      color: const Color(0xFFF4EFE5),\n"
"                      borderRadius: BorderRadius.circular(18),\n"
"                      boxShadow: [\n"
"                        BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 6)),\n"
"                      ],\n"
"                    ),\n"
"                    child: Row(\n"
"                      children: [\n"
"                        IconButton(\n"
"                          onPressed: _cancelSel,\n"
"                          visualDensity: VisualDensity.compact,\n"
"                          icon: const Icon(Icons.close_rounded, color: Color(0xFF8A8378), size: 22),\n"
"                        ),\n"
"                        Expanded(\n"
"                          child: Column(\n"
"                            crossAxisAlignment: CrossAxisAlignment.start,\n"
"                            mainAxisSize: MainAxisSize.min,\n"
"                            children: [\n"
"                              Text('${_selTexts.length}줄 골랐어요',\n"
"                                  style: const TextStyle(\n"
"                                      color: Color(0xFF17140F), fontSize: 14, fontWeight: FontWeight.w700)),\n"
"                              const SizedBox(height: 2),\n"
"                              const Text('다른 줄을 누르면 거기까지 · 최대 5줄',\n"
"                                  maxLines: 1,\n"
"                                  overflow: TextOverflow.ellipsis,\n"
"                                  style: TextStyle(color: Color(0xFF8A8378), fontSize: 11)),\n"
"                            ],\n"
"                          ),\n"
"                        ),\n"
"                        ElevatedButton(\n"
"                          onPressed: _selTexts.isEmpty\n"
"                              ? null\n"
"                              : () {\n"
"                                  final text = _selTexts.join('\\n');\n"
"                                  _cancelSel();\n"
"                                  _openCard(text, playerProvider);\n"
"                                },\n"
"                          style: ElevatedButton.styleFrom(\n"
"                            backgroundColor: const Color(0xFF17140F),\n"
"                            foregroundColor: const Color(0xFFF4EFE5),\n"
"                            elevation: 0,\n"
"                            padding: const EdgeInsets.symmetric(horizontal: 14),\n"
"                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n"
"                          ),\n"
"                          child: const Text('카드 만들기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),\n"
"                        ),\n"
"                      ],\n"
"                    ),\n"
"                  ),\n"
"                ),\n"
"              ),\n"
"\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildBody(",
"아래 바")

# ── lyrics_card_sheet.dart ──
c = rep(c,
"final len = widget.line.length;\nfinal size = len <= 14 ? 25.0 : (len <= 28 ? 22.0 : 19.0); // 긴 줄은 조금 작게\n",
"// 여러 줄이면 줄 수·가장 긴 줄에 맞춰 글자 크기\n"
"final lines = widget.line.split('\\n');\n"
"var longest = 0;\n"
"for (final l in lines) {\n"
"  if (l.length > longest) longest = l.length;\n"
"}\n"
"final n = lines.length;\n"
"final size = n >= 4 ? 17.0 : (n == 3 ? 19.0 : (longest <= 14 ? 25.0 : (longest <= 28 ? 22.0 : 19.0)));\n",
"카드 글자 크기")
c = rep(c, "maxLines: 5,\noverflow: TextOverflow.ellipsis,\nstyle: TextStyle(\ncolor: ink,\nfontSize: size,",
"maxLines: 10,\noverflow: TextOverflow.ellipsis,\nstyle: TextStyle(\ncolor: ink,\nfontSize: size,",
"카드 줄 수")
c = rep(c, "Text('다른 줄은 가사를 꾹 눌러 고를 수 있어요'",
"Text('가사를 꾹 누르고 다른 줄을 누르면 여러 줄을 고를 수 있어요'",
"안내 문구")

save(LS, s, crlf1)
save(CS, c, crlf2)
print('\n✅ 끝! 가사를 꾹 누르고 다른 줄을 누르면 여러 줄이 골라져요.')
