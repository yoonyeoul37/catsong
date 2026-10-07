import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/theme_provider.dart';
import 'paran_dialog.dart';
import 'paran_toast.dart';

/// 카드 배경 사진 하나 (가사 화면과 같은 사진들)
class LyricsCardPhoto {
  final String url;
  final bool light; // 밝은 사진 → 글자를 먹색으로
  const LyricsCardPhoto(this.url, {this.light = false});
}

/// 🎴 가사 한 줄 카드 공유 창 (가사 꾹 누르면)
void showLyricsCardSheet(
    BuildContext context, {
      required String line,
      required String title,
      required String artist,
      required List<LyricsCardPhoto> photos,
      int startPhoto = 0,
    }) {
  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LyricsCardSheet(
      line: line,
      title: title,
      artist: artist,
      photos: photos,
      startPhoto: startPhoto.clamp(0, photos.isEmpty ? 0 : photos.length - 1),
    ),
  );
}

enum _BgKind { photo, color, mine }

/// 색 배경 (이름, 색, 밝은 색인지)
const _kCardColors = <(String, Color, bool)>[
  ('먹색', Color(0xFF17140F), false),
  ('크림', Color(0xFFF4EFE5), true),
  ('파란소리', Color(0xFF2589E8), false),
  ('숲', Color(0xFF3E8E6A), false),
  ('노을', Color(0xFFE07A4F), false),
  ('라벤더', Color(0xFF8A6FD1), false),
];

class _LyricsCardSheet extends StatefulWidget {
  final String line;
  final String title;
  final String artist;
  final List<LyricsCardPhoto> photos;
  final int startPhoto;
  const _LyricsCardSheet({
    required this.line,
    required this.title,
    required this.artist,
    required this.photos,
    required this.startPhoto,
  });

  @override
  State<_LyricsCardSheet> createState() => _LyricsCardSheetState();
}

class _LyricsCardSheetState extends State<_LyricsCardSheet> {
final _cardKey = GlobalKey();
late _BgKind _kind = widget.photos.isEmpty ? _BgKind.color : _BgKind.photo;
late int _photo = widget.startPhoto;
int _color = 0;
String? _mine; // 내 사진 경로
bool _busy = false;

static void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

/// 지금 배경이 밝은지 (밝으면 글자 먹색)
bool get _light {
switch (_kind) {
case _BgKind.photo:
return widget.photos.isNotEmpty && widget.photos[_photo].light;
case _BgKind.color:
return _kCardColors[_color].$3;
case _BgKind.mine:
return false; // 내 사진은 어둡게 막을 깔고 흰 글자
}
}

Color get _ink => _light ? const Color(0xFF17140F) : Colors.white;

// ───────── 카드 (이 모양 그대로 사진으로 만들어 공유) ─────────
Widget _card() {
final ink = _ink;
final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 10)];
final len = widget.line.length;
final size = len <= 14 ? 25.0 : (len <= 28 ? 22.0 : 19.0); // 긴 줄은 조금 작게

Widget bg;
switch (_kind) {
case _BgKind.photo:
bg = CachedNetworkImage(
imageUrl: widget.photos[_photo].url,
fit: BoxFit.cover,
memCacheWidth: 1080,
placeholder: (_, __) => Container(color: const Color(0xFF14110C)),
errorWidget: (_, __, ___) => Container(color: const Color(0xFF14110C)),
);
break;
case _BgKind.color:
bg = Container(color: _kCardColors[_color].$2);
break;
case _BgKind.mine:
bg = _mine == null
? Container(color: const Color(0xFF14110C))
: Image.file(File(_mine!), fit: BoxFit.cover, cacheWidth: 1080);
break;
}

// 사진 위에 얇은 막 (글자가 잘 보이게) — 색 배경은 막 없이
final veil = _kind == _BgKind.color
? null
: (_light ? const Color(0xFFF4EFE5).withOpacity(0.55) : Colors.black.withOpacity(0.38));

// 둥근 모서리는 미리보기에만 (공유하는 사진은 네모 그대로 → 모서리가 검게 안 나오게)
return ClipRRect(
borderRadius: BorderRadius.circular(18),
child: RepaintBoundary(
key: _cardKey,
child: AspectRatio(
aspectRatio: 4 / 5, // 인스타·카톡에 잘 맞는 크기
child: Stack(
fit: StackFit.expand,
children: [
bg,
if (veil != null) ColoredBox(color: veil),
Padding(
padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(Icons.format_quote_rounded, color: ink.withOpacity(0.55), size: 30),
const Spacer(),
// 가사 한 줄 (가운데 크게)
SizedBox(
width: double.infinity,
child: Text(
widget.line,
textAlign: TextAlign.center,
maxLines: 5,
overflow: TextOverflow.ellipsis,
style: TextStyle(
color: ink,
fontSize: size,
height: 1.45,
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
shadows: shadow,
),
),
),
const SizedBox(height: 16),
// 노래 제목 · 가수
SizedBox(
width: double.infinity,
child: Text(
'${widget.title} · ${widget.artist}',
textAlign: TextAlign.center,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
color: ink.withOpacity(0.75),
fontSize: 12.5,
fontWeight: FontWeight.w600,
shadows: shadow,
),
),
),
const Spacer(),
Align(alignment: Alignment.bottomRight, child: _watermark(ink, shadow)),
],
),
),
],
),
),
),
);
}

/// 오른쪽 아래 작은 워터마크 (가사 화면과 같은 모양)
Widget _watermark(Color ink, List<Shadow> shadow) {
final ko = Localizations.localeOf(context).languageCode == 'ko';
final c = ink.withOpacity(_light ? 0.7 : 0.85);
final en = Text(ko ? 'Paransori' : 'ParanSori',
style: GoogleFonts.quicksand(
color: c, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.6, shadows: shadow));
if (!ko) return en;
return Row(
mainAxisSize: MainAxisSize.min,
children: [
Text('파란소리',
style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, shadows: shadow)),
Container(width: 1, height: 10, margin: const EdgeInsets.symmetric(horizontal: 7), color: c),
en,
],
);
}

// ───────── 공유 ─────────
Future<void> _share() async {
if (_busy) return;
_vib();
setState(() => _busy = true);
try {
final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
final ratio = 1080 / boundary.size.width; // 가로 1080으로 선명하게
final image = await boundary.toImage(pixelRatio: ratio);
final data = await image.toByteData(format: ui.ImageByteFormat.png);
image.dispose();
if (data == null) throw Exception('카드를 만들지 못했어요');
final file = File('${Directory.systemTemp.path}/paransori_lyrics_card.png');
await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
} catch (e) {
debugPrint('가사 카드 공유 오류: $e');
if (mounted) showParanToast(context, '카드를 만들지 못했어요. 다시 해주세요.', error: true);
} finally {
if (mounted) setState(() => _busy = false);
}
}

/// 내 사진 고르기
Future<void> _pickMine() async {
_vib();
try {
final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);
if (x == null || !mounted) return;
setState(() {
_mine = x.path;
_kind = _BgKind.mine;
});
} catch (e) {
debugPrint('사진 고르기 오류: $e');
if (mounted) showParanToast(context, '사진을 불러오지 못했어요', error: true);
}
}

@override
Widget build(BuildContext context) {
final dark = context.watch<ThemeProvider>().isDarkMode;
final bg = dark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
final card = dark ? const Color(0xFF332E26) : Colors.white;
final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
final sub = dark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
final line = dark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);
final maxCardW = (MediaQuery.sizeOf(context).height * 0.42) * 4 / 5; // 작은 폰에서도 아래 버튼이 보이게

// 고르는 칸 (사진 · 색 · 내 사진) — 고르면 먹색으로 채움 (이퀄라이저 칸과 같은 모양)
Widget chip(String label, _BgKind k, VoidCallback onTap) {
final selected = _kind == k;
return GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
onTap();
},
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(color: selected ? ink : card, borderRadius: BorderRadius.circular(12)),
child: Text(label,
style: TextStyle(
color: selected ? bg : sub,
fontSize: 13,
fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
)),
),
);
}

// 고른 것 테두리
BoxDecoration pickBorder(bool selected, {bool circle = false}) => BoxDecoration(
shape: circle ? BoxShape.circle : BoxShape.rectangle,
borderRadius: circle ? null : BorderRadius.circular(12),
border: Border.all(color: selected ? ink : Colors.transparent, width: 2.5),
);

Widget options;
switch (_kind) {
case _BgKind.photo:
options = ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: widget.photos.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (_, i) => GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
setState(() => _photo = i);
},
child: Container(
width: 52,
padding: const EdgeInsets.all(2),
decoration: pickBorder(_photo == i),
child: ClipRRect(
borderRadius: BorderRadius.circular(9),
child: CachedNetworkImage(
imageUrl: widget.photos[i].url,
fit: BoxFit.cover,
memCacheWidth: 160, // 작게 미리보기
placeholder: (_, __) => Container(color: line),
errorWidget: (_, __, ___) => Container(color: line),
),
),
),
),
);
break;
case _BgKind.color:
options = ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _kCardColors.length,
separatorBuilder: (_, __) => const SizedBox(width: 10),
itemBuilder: (_, i) => GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
setState(() => _color = i);
},
child: Container(
width: 52,
padding: const EdgeInsets.all(3),
decoration: pickBorder(_color == i, circle: true),
child: Container(
decoration: BoxDecoration(
color: _kCardColors[i].$2,
shape: BoxShape.circle,
border: Border.all(color: line), // 크림색도 바탕과 구분되게
),
),
),
),
);
break;
case _BgKind.mine:
options = Row(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
if (_mine != null) ...[
Container(
width: 52,
padding: const EdgeInsets.all(2),
decoration: pickBorder(true),
child: ClipRRect(
borderRadius: BorderRadius.circular(9),
child: Image.file(File(_mine!), fit: BoxFit.cover, cacheWidth: 160),
),
),
const SizedBox(width: 10),
],
GestureDetector(
onTap: _pickMine,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16),
decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.add_photo_alternate_outlined, color: sub, size: 20),
const SizedBox(width: 8),
Text(_mine == null ? '사진 고르기' : '다른 사진',
style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
],
),
),
),
],
);
break;
}

return AnnotatedRegion<SystemUiOverlayStyle>(
value: SystemUiOverlayStyle(
systemNavigationBarColor: bg,
systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
),
child: SafeArea(
top: false,
child: Container(
margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 36,
height: 4,
decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
),
const SizedBox(height: 14),
// 제목 + ✕
Row(
children: [
Expanded(
child: Text('가사 카드',
style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
),
ParanCloseX(onTap: () => Navigator.pop(context)),
],
),
const SizedBox(height: 4),
// 안내: 다른 줄 고르는 법
Align(
  alignment: Alignment.centerLeft,
  child: Text('다른 줄은 가사를 꾹 눌러 고를 수 있어요', style: TextStyle(color: sub, fontSize: 12)),
),
const SizedBox(height: 12),
  // 카드 미리보기
  Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxCardW),
      child: _card(),
    ),
  ),
  const SizedBox(height: 16),
  // 배경 종류
  Row(
    children: [
      if (widget.photos.isNotEmpty) ...[
        chip('사진', _BgKind.photo, () => setState(() => _kind = _BgKind.photo)),
        const SizedBox(width: 6),
      ],
      chip('색', _BgKind.color, () => setState(() => _kind = _BgKind.color)),
      const SizedBox(width: 6),
      chip('내 사진', _BgKind.mine, () {
        if (_mine == null) {
          _pickMine();
        } else {
          setState(() => _kind = _BgKind.mine);
        }
      }),
    ],
  ),
  const SizedBox(height: 10),
  SizedBox(height: 56, child: options),
  const SizedBox(height: 16),
  // 큰 버튼: 먹색 (다크 모드는 크림색)
  SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: (_busy || (_kind == _BgKind.mine && _mine == null)) ? null : _share,
      style: ElevatedButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: bg,
        disabledBackgroundColor: ink.withOpacity(0.35),
        disabledForegroundColor: bg,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_busy)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: bg),
            )
          else
            const Icon(Icons.ios_share_rounded, size: 19),
          const SizedBox(width: 8),
          Text(_busy ? '카드 만드는 중…' : '공유하기',
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  ),
],
),
),
),
);
}
}