import 'package:flutter/material.dart';

/// 앨범아트가 없을 때 대신 보여줄 기본 이미지 3장 중 하나를
/// key(곡 제목/경로 등)를 기준으로 항상 같은 것을 골라준다.
/// 같은 곡은 언제 봐도 같은 이미지, 다른 곡은 서로 다른 이미지가 섞여 나온다.
String noAlbumImagePath(String key) {
  const images = [
    'assets/no_album2.jpg',
    'assets/no_album3.jpg',
    'assets/no_album4.jpg',
  ];
  final index = key.hashCode.abs() % images.length;
  return images[index];
}


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
