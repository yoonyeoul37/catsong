# -*- coding: utf-8 -*-
# 파란포토 창: 색감을 아래에 고정 + 지금 사진으로 미리보기 · 내 사진을 두 번째 칸으로
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

FILES = {
'lib/widgets/paran_dialog.dart': ('footer(ctx, setSheet)', [
('아래 고정 칸 받기',
"""  Widget? header, // 제목 대신 넣을 머리 (곡 정보처럼 사진+제목)
  String closeLabel = '닫기',
}) {""",
"""  Widget? header, // 제목 대신 넣을 머리 (곡 정보처럼 사진+제목)
  Widget Function(BuildContext ctx, StateSetter setSheet)? footer, // 아래에 고정 (내용을 밀어도 늘 보임)
  String closeLabel = '닫기',
}) {"""),
('아래 고정 칸 그리기',
"""              Flexible(child: SingleChildScrollView(child: builder(ctx, setSheet))),
              const SizedBox(height: 10),""",
"""              Flexible(child: SingleChildScrollView(child: builder(ctx, setSheet))),
              if (footer != null) ...[
                Container(height: 0.5, margin: const EdgeInsets.only(top: 4), color: p.line),
                const SizedBox(height: 10),
                footer(ctx, setSheet),
              ],
              const SizedBox(height: 10),"""),
]),
'lib/screens/player_screen.dart': ('Widget _toneBar(', [
('색감 미리보기용 (색감 골라서 입히기)',
"""  Widget _bgFiltered(Widget child) {
    if (_bgFilter == 1) {""",
"""  Widget _bgFiltered(Widget child, [int? only]) {
    final f = only ?? _bgFilter; // only: 미리보기용 (그 색감으로)
    if (f == 1) {"""),
('세피아',
"""    if (_bgFilter == 2) {
      return ColorFiltered(""",
"""    if (f == 2) {
      return ColorFiltered("""),
('필름',
"""    if (_bgFilter == 3) {
      // 필름""",
"""    if (f == 3) {
      // 필름"""),
('안 쓰는 칩·줄 지우기',
'        // 작은 칩 (고른 것은 먹색, 다크 모드는 크림색)\n        Widget chip(String label, bool on, VoidCallback onTap) => GestureDetector(\n              onTap: () {\n                tick();\n                onTap();\n                setSheet(() {});\n              },\n              child: Container(\n                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),\n                decoration: BoxDecoration(\n                  color: on ? ink : chipBg,\n                  borderRadius: BorderRadius.circular(16),\n                  border: Border.all(color: on ? ink : chipLine),\n                ),\n                child: Text(label,\n                    style: TextStyle(\n                        color: on ? (dark ? const Color(0xFF17140F) : Colors.white) : sub,\n                        fontSize: 12,\n                        fontWeight: FontWeight.w600)),\n              ),\n            );\n\n        // 카드 안 한 줄 (아이콘 · 이름 · 오른쪽 칩들)\n        Widget optionRow(IconData icon, String title, List<Widget> chips) => Padding(\n              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),\n              child: Row(\n                children: [\n                  SizedBox(width: 22, child: Icon(icon, color: sub, size: 20)),\n                  const SizedBox(width: 10),\n                  Text(title, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500)),\n                  const Spacer(),\n                  for (var i = 0; i < chips.length; i++) ...[\n                    if (i > 0) const SizedBox(width: 6),\n                    chips[i],\n                  ],\n                ],\n              ),\n            );\n\n',
''),
('내 사진을 두 번째 칸으로',
"""        final cats = <String>['전체', ..._nightCategoryPhotos.keys, if (favAssets.isNotEmpty) '하트', '내 사진'];""",
"""        final cats = <String>['전체', '내 사진', ..._nightCategoryPhotos.keys, if (favAssets.isNotEmpty) '하트'];"""),
('색감을 아래 고정으로',
"""            const SizedBox(height: 14),
            // 색감은 맨 아래로
            ParanCard(
              children: [
                optionRow(Icons.palette_outlined, '색감', [
                  chip('컬러', _bgFilter == 0, () => _setBgFilter(0)),
                  chip('흑백', _bgFilter == 1, () => _setBgFilter(1)),
                  chip('세피아', _bgFilter == 2, () => _setBgFilter(2)),
                  chip('필름', _bgFilter == 3, () => _setBgFilter(3)),
                ]),
              ],
            ),
          ],
        );
      },
    );
  }
""",
"""            const SizedBox(height: 6),
          ],
        );
      },
      // 색감: 아래에 고정 (사진을 밀어도 늘 보이게)
      footer: (ctx, setSheet) => _toneBar(setSheet),
    );
  }

  /// 색감 고르기: 지금 사진을 컬러 · 흑백 · 세피아 · 필름으로 작게 미리보기
  Widget _toneBar(StateSetter setSheet) {
    final dark = context.read<ThemeProvider>().isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    Widget photo() => _nightBgIsFile
        ? Image.file(File(_nightBgPath),
            fit: BoxFit.cover,
            cacheWidth: 200,
            errorBuilder: (_, __, ___) => Container(color: const Color(0x22000000)))
        : paranPhoto(_nightBgPath, thumb: true, fit: BoxFit.cover);
    return Row(
      children: [
        for (final t in const [(0, '컬러'), (1, '흑백'), (2, '세피아'), (3, '필름')]) ...[
          if (t.$1 > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                _setBgFilter(t.$1);
                setSheet(() {});
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 46,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _bgFilter == t.$1 ? ink : Colors.transparent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox.expand(child: _bgFiltered(photo(), t.$1)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(t.$2,
                      style: TextStyle(
                          color: _bgFilter == t.$1 ? ink : sub,
                          fontSize: 11.5,
                          fontWeight: _bgFilter == t.$1 ? FontWeight.w800 : FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
"""),
]),
}

def main():
    out = {}
    ok = True
    for path, (mark, edits) in FILES.items():
        print(f'── {path.split("/")[-1]}')
        try:
            raw = open(path, 'rb').read().decode('utf-8')
        except FileNotFoundError:
            print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
        crlf = '\r\n' in raw
        s = raw.replace('\r\n', '\n')
        if mark in s:
            print('이미 적용돼 있어요'); continue
        b = (s.count('{') - s.count('}'), s.count('(') - s.count(')'), s.count('[') - s.count(']'))
        for name, old, new in edits:
            n = s.count(old)
            if n != 1:
                print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
            s = s.replace(old, new); print(f'✔ {name}')
        if (s.count('{') - s.count('}'), s.count('(') - s.count(')'), s.count('[') - s.count(']')) != b:
            print('❌ 괄호가 안 맞아요'); ok = False
        out[path] = s.replace('\n', '\r\n') if crlf else s
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    for path, s in out.items():
        open(path, 'wb').write(s.encode('utf-8'))
    if out: print('저장했어요 ✔')

main()
