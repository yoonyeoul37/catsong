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
import 'package:shared_preferences/shared_preferences.dart';
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

/// 그라데이션 배경 (요즘 인기 있는 스타일)
const _kCardGradients = <(String, List<Color>)>[
  ('밤하늘', [Color(0xFF232A4D), Color(0xFF5B4A7A)]),
  ('노을', [Color(0xFF6B4A3A), Color(0xFFE0915F)]),
  ('바다', [Color(0xFF1F4E6B), Color(0xFF6FB3C9)]),
  ('라벤더', [Color(0xFF4A3F7A), Color(0xFFC79ACF)]),
  ('숲', [Color(0xFF233D32), Color(0xFF7FA77A)]),
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

// ── 3단계 ──
String? _text; // 고친 가사 (없으면 처음 고른 그대로)
String get _line => _text ?? widget.line;
List<String> _myList = []; // 내 사진 목록 (가사 배경 '내 사진'과 같이 씀)
bool _mineLight = false; // 내 사진이 밝은지

@override
void initState() {
  super.initState();
  SharedPreferences.getInstance().then((p) {
    final l = (p.getStringList('lyricsMyPhotos') ?? []).where((f) => File(f).existsSync()).toList();
    if (mounted) setState(() => _myList = l);
  });
}

/// 사진 위쪽 60%가 밝은지 재보기 → 글자색 자동
Future<bool> _isBright(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 40);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return false;
    final w = img.width, rows = (img.height * 0.6).round();
    var sum = 0.0;
    var n = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        sum += 0.299 * data.getUint8(i) + 0.587 * data.getUint8(i + 1) + 0.114 * data.getUint8(i + 2);
        n++;
      }
    }
    img.dispose();
    return n > 0 && sum / n > 150;
  } catch (_) {
    return false;
  }
}

/// 내 사진 하나로 배경 바꾸기
Future<void> _useMine(String path) async {
  final light = await _isBright(path);
  if (!mounted) return;
  setState(() {
    _mine = path;
    _mineLight = light;
    _kind = _BgKind.mine;
  });
}

/// ✏️ 글자 고치기 (엔터로 줄 바꾸기 · 오타 고치기)
Future<void> _editText() async {
  _vib();
  final dark = context.read<ThemeProvider>().isDarkMode;
  final bg = dark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
  final card = dark ? const Color(0xFF332E26) : Colors.white;
  final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
  final sub = dark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
  final line = dark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);
  final ctrl = TextEditingController(text: _line);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('글자 고치기',
                      style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ),
                ParanCloseX(onTap: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 4),
            Text('엔터로 줄을 바꿀 수 있어요', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textAlign: TextAlign.center,
                style: TextStyle(color: ink, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, widget.line), // 처음 고른 가사로
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('원래대로', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: bg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('적용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  // 창이 다 사라진 뒤에 치우기 (바로 치우면 오류)
  Future.delayed(const Duration(milliseconds: 400), ctrl.dispose);
  if (result == null || !mounted) return;
  // 앞뒤 빈 줄 정리 (비우면 처음 가사로)
  final t = result.split('\n').map((l) => l.trimRight()).join('\n').trim();
  setState(() => _text = (t.isEmpty || t == widget.line) ? null : t);
}

// ── 꾸미기 (2단계) ──
int _tab = 0; // 0 배경 · 1 글꼴 · 2 비율 · 3 제목
int _font = 0; // 글꼴
bool _left = false; // 왼쪽 정렬
double _scale = 1.0; // 글자 크기 (작게 0.85 · 보통 1 · 크게 1.15)
int _ratio = 2; // 비율 (기본 4:5)
int _titlePos = 1; // 제목·가수: 0 위 · 1 아래 · 2 숨기기

static const _fonts = ['깔끔', '편지', '손글씨', '귀여움'];
static const _ratios = <(String, double)>[('스토리 9:16', 9 / 16), ('피드 1:1', 1.0), ('4:5', 4 / 5)];

/// 고른 글꼴로 바꾸기 (f를 주면 그 글꼴로 — 글꼴 고르는 칸 미리보기용)
TextStyle _fontStyle(TextStyle s, [int? f]) {
  switch (f ?? _font) {
    case 1:
      return GoogleFonts.gowunBatang(textStyle: s.copyWith(fontWeight: FontWeight.w700));
    case 2:
      return GoogleFonts.nanumPenScript(
          textStyle: s.copyWith(fontSize: (s.fontSize ?? 20) * 1.3, fontWeight: FontWeight.w400, height: 1.25));
    case 3:
      return GoogleFonts.gaegu(textStyle: s.copyWith(fontWeight: FontWeight.w700));
    default:
      return s;
  }
}

static void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

/// 지금 배경이 밝은지 (밝으면 글자 먹색)
bool get _light {
switch (_kind) {
case _BgKind.photo:
return widget.photos.isNotEmpty && widget.photos[_photo].light;
case _BgKind.color:
return _color < _kCardColors.length && _kCardColors[_color].$3; // 그라데이션은 어두운 색이라 흰 글자
case _BgKind.mine:
return _mineLight; // 내 사진은 밝기 재서 자동
}
}

Color get _ink => _light ? const Color(0xFF17140F) : Colors.white;

// ───────── 카드 (이 모양 그대로 사진으로 만들어 공유) ─────────
Widget _card() {
final ink = _ink;
final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 10)];
// 여러 줄이면 줄 수·가장 긴 줄에 맞춰 글자 크기
final lines = _line.split('\n');
var longest = 0;
for (final l in lines) {
  if (l.length > longest) longest = l.length;
}
final n = lines.length;
final size = (n >= 4 ? 17.0 : (n == 3 ? 19.0 : (longest <= 14 ? 25.0 : (longest <= 28 ? 22.0 : 19.0)))) * _scale;
final align = _left ? TextAlign.left : TextAlign.center;
// 노래 제목 · 가수 (위·아래·숨기기)
final titleText = SizedBox(
  width: double.infinity,
  child: Text(
    '${widget.title} · ${widget.artist}',
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: ink.withOpacity(0.75), fontSize: 12.5, fontWeight: FontWeight.w600, shadows: shadow),
  ),
);

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
bg = _color < _kCardColors.length
    ? Container(color: _kCardColors[_color].$2)
    : DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _kCardGradients[_color - _kCardColors.length].$2,
          ),
        ),
      );
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
aspectRatio: _ratios[_ratio].$2, // 스토리 9:16 · 피드 1:1 · 4:5
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
// 제목 '위'면 유리 띠가 맨 위로, 아니면 따옴표
if (_titlePos == 0)
_glassBar(ink, shadow, withTitle: true)
else
Icon(Icons.format_quote_rounded, color: ink.withOpacity(0.55), size: 30),
const Spacer(),

// 고른 가사 (가운데 크게)
SizedBox(
width: double.infinity,
child: Text(
_line,
textAlign: align,
maxLines: 10,
overflow: TextOverflow.ellipsis,
style: _fontStyle(TextStyle(
color: ink,
fontSize: size,
height: 1.45,
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
shadows: shadow,
)),
),
),
// (제목 '아래'는 맨 아래 유리 띠 안으로)
const Spacer(),
// 맨 아래 유리 띠 (제목 '위'면 위로 올라가서 여기선 없음)
if (_titlePos != 0) _glassBar(ink, shadow, withTitle: _titlePos == 1),
],
),
),
],
),
),
),
);
}

/// 유리 띠: (제목 · 가수) + Paransori — 위·아래 어디든 같은 모양
Widget _glassBar(Color ink, List<Shadow> shadow, {required bool withTitle}) {
  // 제목이 없으면 긴 띠 대신 오른쪽 작은 알약
  final bar = Container(
    padding: withTitle
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: _light ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: _light ? Colors.black.withOpacity(0.10) : Colors.white.withOpacity(0.32),
      ),
    ),
    child: Row(
      mainAxisSize: withTitle ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (withTitle)
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' · ${widget.artist}', style: TextStyle(color: ink.withOpacity(0.75))),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink, fontSize: 11.5, shadows: shadow),
            ),
          ),
        if (withTitle) const SizedBox(width: 10),
        _watermark(ink, shadow),
      ],
    ),
  );
  return withTitle ? bar : Align(alignment: Alignment.centerRight, child: bar);
}

/// 오른쪽 아래 작은 워터마크 (가사 화면과 같은 모양)
Widget _watermark(Color ink, List<Shadow> shadow) {
  return Text(
    'Paransori',
    style: GoogleFonts.quicksand(
      color: ink.withOpacity(_light ? 0.75 : 0.9),
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      shadows: shadow,
    ),
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

/// 내 사진 고르기 → 가사 배경 '내 사진' 목록에도 같이 넣기
Future<void> _pickMine() async {
_vib();
try {
final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);
if (x == null || !mounted) return;
if (!_myList.contains(x.path)) {
setState(() => _myList.insert(0, x.path));
final p = await SharedPreferences.getInstance();
await p.setStringList('lyricsMyPhotos', _myList);
}
await _useMine(x.path);
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
final maxCardW = (MediaQuery.sizeOf(context).height * 0.42) * _ratios[_ratio].$2; // 작은 폰에서도 아래 버튼이 보이게

// 작은 알약 버튼 (고르면 먹색)
Widget pill(String label, bool on, VoidCallback onTap) => GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(color: on ? ink : card, borderRadius: BorderRadius.circular(12)),
        child: Text(label,
            style: TextStyle(
                color: on ? bg : sub, fontSize: 13, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
      ),
    );

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
itemCount: _kCardColors.length + _kCardGradients.length,
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
color: i < _kCardColors.length ? _kCardColors[i].$2 : null,
gradient: i < _kCardColors.length
    ? null
    : LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _kCardGradients[i - _kCardColors.length].$2,
      ),
shape: BoxShape.circle,
border: Border.all(color: line), // 크림색도 바탕과 구분되게
),
),
),
),
);
break;
case _BgKind.mine:
options = ListView(
scrollDirection: Axis.horizontal,
children: [
// + 추가
GestureDetector(
onTap: _pickMine,
child: Container(
width: 52,
decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
child: Icon(Icons.add_rounded, color: sub, size: 24),
),
),
for (final f in _myList) ...[
const SizedBox(width: 8),
GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
_useMine(f);
},
child: Container(
width: 52,
padding: const EdgeInsets.all(2),
decoration: pickBorder(_kind == _BgKind.mine && _mine == f),
child: ClipRRect(
borderRadius: BorderRadius.circular(9),
child: Image.file(File(f), fit: BoxFit.cover, cacheWidth: 160,
errorBuilder: (_, __, ___) => Container(color: line)),
),
),
),
],
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
  child: Text('가사를 꾹 누르고 다른 줄을 누르면 여러 줄을 고를 수 있어요', style: TextStyle(color: sub, fontSize: 12)),
),
const SizedBox(height: 12),
  // 카드 미리보기
  Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxCardW),
      // 카드 글자를 누르면 고치기
      child: GestureDetector(onTap: _editText, child: _card()),
    ),
  ),
  const SizedBox(height: 16),
  // 탭: 배경 · 글꼴 · 비율 · 제목
  Row(
    children: [
      for (final (i, label, icon) in const [
        (0, '배경', Icons.photo_outlined),
        (1, '글꼴', Icons.text_fields_rounded),
        (2, '비율', Icons.crop_rounded),
        (3, '제목', Icons.title_rounded),
        (4, '글자', Icons.edit_rounded),
      ])
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              if (i == 4) {
                _editText(); // 글자는 바로 고치는 창
                return;
              }
              setState(() => _tab = i);
            },
            child: Column(
              children: [
                Icon(icon, size: 20, color: _tab == i ? ink : sub),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        color: _tab == i ? ink : sub,
                        fontSize: 11.5,
                        fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  height: 2.5,
                  width: 22,
                  decoration: BoxDecoration(
                      color: _tab == i ? ink : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
        ),
    ],
  ),
  const SizedBox(height: 12),
  SizedBox(
    height: 104,
    child: _tab == 1
        // 글꼴 4종 + 정렬 + 크기
        ? Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < _fonts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _font = i);
                        },
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _font == i ? ink : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('가나다',
                                  style: _fontStyle(
                                      TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700), i)),
                              const SizedBox(height: 2),
                              Text(_fonts[i], style: TextStyle(color: sub, fontSize: 10.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  pill('가운데', !_left, () => setState(() => _left = false)),
                  const SizedBox(width: 6),
                  pill('왼쪽', _left, () => setState(() => _left = true)),
                  const Spacer(),
                  pill('A-', _scale < 1, () => setState(() => _scale = 0.85)),
                  const SizedBox(width: 6),
                  pill('A', _scale == 1, () => setState(() => _scale = 1.0)),
                  const SizedBox(width: 6),
                  pill('A+', _scale > 1, () => setState(() => _scale = 1.15)),
                ],
              ),
            ],
          )
        : _tab == 2
            // 비율
            ? Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (var i = 0; i < _ratios.length; i++)
                      pill(_ratios[i].$1, _ratio == i, () => setState(() => _ratio = i)),
                  ],
                ),
              )
            : _tab == 3
                // 제목·가수 위치
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        pill('위', _titlePos == 0, () => setState(() => _titlePos = 0)),
                        pill('아래', _titlePos == 1, () => setState(() => _titlePos = 1)),
                        pill('숨기기', _titlePos == 2, () => setState(() => _titlePos = 2)),
                      ],
                    ),
                  )
                // 배경 (사진 · 색 · 내 사진)
                : Column(
                    children: [
                      Row(
                        children: [
                          if (widget.photos.isNotEmpty) ...[
                            chip('사진', _BgKind.photo, () => setState(() => _kind = _BgKind.photo)),
                            const SizedBox(width: 6),
                          ],
                          chip('색', _BgKind.color, () => setState(() => _kind = _BgKind.color)),
                          const SizedBox(width: 6),
                          chip('내 사진', _BgKind.mine, () {
                            if (_mine != null) {
                              setState(() => _kind = _BgKind.mine);
                            } else if (_myList.isNotEmpty) {
                              _useMine(_myList.first);
                            } else {
                              _pickMine();
                            }
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(height: 56, child: options),
                    ],
                  ),
  ),
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