# -*- coding: utf-8 -*-
# 5번: 곡 목록 ⋮ 메뉴에 "자연소리 섞기" (곡이 재생 중일 때만)
# 7번: 앨범 사진 없는 곡 → 곡마다 차분한 색 + 제목 첫 글자
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PLAYER = os.path.join(ROOT, 'lib', 'screens', 'player_screen.dart')
TILE = os.path.join(ROOT, 'lib', 'widgets', 'song_list_tile.dart')
HELPER = os.path.join(ROOT, 'lib', 'utils', 'no_album_helper.dart')

HELPER_ADD = r'''

// ───── 앨범 사진 없는 곡: 곡마다 차분한 색 + 제목 첫 글자 (같은 곡은 항상 같은 색) ─────

/// (라이트 바탕, 라이트 글자, 다크 바탕, 다크 글자)
const _noArtPalette = <(Color, Color, Color, Color)>[
  (Color(0xFFC9B79C), Color(0xFF4A3B26), Color(0xFF4A4236), Color(0xFFDCCBB0)), // 베이지
  (Color(0xFFA9B8A8), Color(0xFF2E3D2E), Color(0xFF3C473C), Color(0xFFC6D4C5)), // 세이지
  (Color(0xFFB7A9B8), Color(0xFF3D2E3E), Color(0xFF473C48), Color(0xFFD5C7D6)), // 모브
  (Color(0xFFA7B6C2), Color(0xFF26384A), Color(0xFF3A4650), Color(0xFFC4D3DF)), // 더스티 블루
  (Color(0xFFC7A99A), Color(0xFF4A2E24), Color(0xFF4E3D35), Color(0xFFE0C5B7)), // 클레이
  (Color(0xFFB8B691), Color(0xFF3D3C22), Color(0xFF47462F), Color(0xFFD5D3AF)), // 올리브
];

int _stableHash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// 제목 첫 글자 (앞의 괄호·기호·공백은 건너뜀)
String noArtLetter(String title) {
  for (final r in title.trim().runes) {
    final ch = String.fromCharCode(r);
    if (RegExp(r'[0-9A-Za-z가-힣぀-ヿ一-鿿]').hasMatch(ch)) {
      return ch.toUpperCase();
    }
  }
  return '♪';
}

/// 사진 없는 곡 칸 (곡 목록 등 작은 자리)
class NoArtTile extends StatelessWidget {
  final String title; // 첫 글자용
  final String colorKey; // 색 고르기용 (곡 경로 등)
  final double size;
  final double radius;
  final bool isDark;

  const NoArtTile({
    super.key,
    required this.title,
    required this.colorKey,
    required this.size,
    required this.isDark,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final c = _noArtPalette[_stableHash(colorKey) % _noArtPalette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? c.$3 : c.$1,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        noArtLetter(title),
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: isDark ? c.$4 : c.$2,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}
'''

PLAYER_EDITS = [
    ('곡 목록 ⋮ 메뉴에 자연소리 섞기',
     "    _PlayerScreenState._playerSheetItem(\n"
     "      context, Icons.speed, '배속', accent, textColor,\n"
     "      () { showPlayerSpeedMenu(context); },\n"
     "      trailing: _PlayerScreenState._sheetValue(_PlayerScreenState._sheetSpeedLabel(p.playbackSpeed)),\n"
     "      arrow: true,\n"
     "    ),\n"
     "  ];\n",
     "    _PlayerScreenState._playerSheetItem(\n"
     "      context, Icons.speed, '배속', accent, textColor,\n"
     "      () { showPlayerSpeedMenu(context); },\n"
     "      trailing: _PlayerScreenState._sheetValue(_PlayerScreenState._sheetSpeedLabel(p.playbackSpeed)),\n"
     "      arrow: true,\n"
     "    ),\n"
     "    // 자연소리 섞기 (재생화면 메뉴와 같은 줄, 곡이 재생 중일 때만)\n"
     "    if (p.currentSong != null)\n"
     "      AnimatedBuilder(\n"
     "        animation: NatureOverlay.instance,\n"
     "        builder: (_, __) => _PlayerScreenState._playerSheetItem(\n"
     "          context, Icons.forest_outlined, '자연소리 섞기', accent, textColor,\n"
     "          () { showNatureOverlaySheet(context); },\n"
     "          trailing: _PlayerScreenState._sheetValue(NatureOverlay.instance.summary),\n"
     "          arrow: true,\n"
     "        ),\n"
     "      ),\n"
     "  ];\n"),
]

TILE_EDITS = [
    ('곡 목록: 색 칸 파일 연결',
     "import '../providers/theme_provider.dart';\n",
     "import '../providers/theme_provider.dart';\n"
     "import '../utils/no_album_helper.dart';\n"),
    ('곡 목록: 사진 없는 곡 → 색 + 첫 글자',
     "              : Container(\n"
     "            width: 52,\n"
     "            height: 52,\n"
     "            decoration: BoxDecoration(\n"
     "              color: baseColor.withOpacity(0.15),\n"
     "              borderRadius: BorderRadius.circular(4),\n"
     "            ),\n"
     "            child: Center(\n"
     "              child: SvgPicture.asset(\n"
     "                'assets/no_album.svg',\n"
     "                width: 32,\n"
     "                height: 32,\n"
     "                fit: BoxFit.contain,\n"
     "              ),\n"
     "            ),\n"
     "          ),\n",
     "              : NoArtTile(\n"
     "            title: song.titleDisplay,\n"
     "            colorKey: song.uri ?? song.titleDisplay,\n"
     "            size: 52,\n"
     "            isDark: baseColor == Colors.white,\n"
     "          ),\n"),
]

MARK = 'class NoArtTile'


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


def load(path):
    raw = open(path, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def main():
    for p in (PLAYER, TILE, HELPER):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(HELPER, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return

    out = []
    ok = True
    for path, edits in ((PLAYER, PLAYER_EDITS), (TILE, TILE_EDITS)):
        text, crlf = load(path)
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text, crlf))

    text, crlf = load(HELPER)
    if "import 'package:flutter/material.dart';" not in text:
        text = "import 'package:flutter/material.dart';\n\n" + text
    text = text.rstrip('\n') + '\n' + HELPER_ADD
    if not balanced(text):
        print('❌ 괄호가 안 맞아요: no_album_helper.dart')
        ok = False
    else:
        print('✔ 색 칸 부품 추가 (no_album_helper.dart)')
    out.append((HELPER, text, crlf))

    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
