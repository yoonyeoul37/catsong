import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/paran_dialog.dart';
import '../providers/theme_provider.dart';
import '../widgets/paran_toast.dart';
import '../widgets/lyrics_card_sheet.dart';

/// 가사 배경 사진 (수파베이스 app-images/lyrics) — 목록은 list.json 으로 앱 업데이트 없이 바꿀 수 있어요
const _kLyricsBgBase =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images/lyrics';

class _LyricsBg {
  final String file;
  final bool light; // 밝은 사진 → 가사를 먹색으로
  final bool busy; // 화려한 사진 → 위에 크림색 막을 조금 더
  const _LyricsBg(this.file, {this.light = false, this.busy = false});
}

/// 기본 목록 (인터넷 목록을 아직 못 받았을 때)
const _kDefaultBgs = <_LyricsBg>[
  _LyricsBg('lyrics_bg_1.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_3.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_5.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_7.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_8.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_10.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_12.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_13.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_14.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_15.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_16.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_17.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_18.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_19.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_20.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_21.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_22.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_23.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_24.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_25.jpg', light: false, busy: false),
];

List<_LyricsBg> _bgs = _kDefaultBgs; // 지금 쓰는 목록 (list.json 받으면 바뀜)
int get _kLyricsBgCount => _bgs.length;
Set<int> get _kLightBgs => {for (var i = 0; i < _bgs.length; i++) if (_bgs[i].light) i + 1};
Set<int> get _kBusyBgs => {for (var i = 0; i < _bgs.length; i++) if (_bgs[i].busy) i + 1};
String _bgUrl(int i) => '$_kLyricsBgBase/${_bgs[(i - 1).clamp(0, _bgs.length - 1)].file}';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  static int? _lastBg; // 한 번 읽은 배경 번호 기억 (다음에 열 때 바로)
  int _bg = _lastBg ?? 1; // 1~11 = 사진
  static bool _random = false; // 🔀 랜덤: 노래가 바뀔 때마다 다른 사진
  static String _randomSongKey = ''; // 랜덤 사진을 고른 노래 (같은 노래 동안은 그대로)
  static String? _myBg; // 내 사진 배경 (파일 경로) — 있으면 이게 먼저
  static bool _myLight = false; // 내 사진이 밝은지 (밝으면 먹색 글자, 어두우면 흰 글자)
  List<String> _myPhotos = []; // 가사 배경용 내 사진 목록
  bool _manageMy = false; // 내 사진 관리(✕) 모드
  final Map<int, GlobalKey> _lineKeys = {}; // 줄마다 위치 (지금 줄로 부드럽게 이동)
  int _lastLine = -1;
  final ScrollController _plainController = ScrollController(); // 시간 없는 가사용
  DateTime _userScrolledAt = DateTime(2000); // 손으로 움직이면 잠깐 자동 멈춤

  // ── 여러 줄 고르기 (가사 카드) ──
  int? _selAnchor; // 처음 꾹 누른 줄
  int? _selOther; // 마지막으로 누른 줄 (여기까지)
  List<String> _visibleLines = const []; // 지금 화면에 그린 가사 줄들
  int get _selLo => _selAnchor! < _selOther! ? _selAnchor! : _selOther!;
  int get _selHi => _selAnchor! > _selOther! ? _selAnchor! : _selOther!;
  bool _isSel(int i) => _selAnchor != null && i >= _selLo && i <= _selHi;
  List<String> get _selTexts => _selAnchor == null
      ? const []
      : [
          for (var i = _selLo; i <= _selHi && i < _visibleLines.length; i++)
            if (_visibleLines[i].trim().isNotEmpty) _visibleLines[i].trim()
        ];

  /// 꾹 → 이 줄부터 고르기 시작
  void _startSel(int i) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    setState(() {
      _selAnchor = i;
      _selOther = i;
    });
  }

  /// 고르는 중 다른 줄 누르기 → 거기까지 (최대 5줄)
  void _extendSel(int i) {
    HapticFeedback.selectionClick();
    var o = i;
    if ((o - _selAnchor!).abs() > 4) o = _selAnchor! + (o > _selAnchor! ? 4 : -4);
    setState(() => _selOther = o);
  }

  void _cancelSel() => setState(() {
        _selAnchor = null;
        _selOther = null;
      });

  @override
  void initState() {
    super.initState();
    _loadBgList(); // 인터넷 목록 받기 (못 받으면 기본 목록)
    SharedPreferences.getInstance().then((p) {
      final s = (p.getInt('lyricsTextSize') ?? 1).clamp(0, 2);
      if (s != _sizeStep && mounted) setState(() => _sizeStep = s);
    });
    // 처음 한 번만: 가사를 꾹 누르면 카드로 공유된다고 알려주기
    SharedPreferences.getInstance().then((p) {
      if (p.getBool('lyricsCardHint') == true) return;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        p.setBool('lyricsCardHint', true);
        showParanToast(context, '가사를 꾹 누르면 카드로 만들어 공유할 수 있어요');
      });
    });
    SharedPreferences.getInstance().then((p) {
      // 고른 사진은 파일 이름으로 기억 (예전 번호로 저장한 것도 알아보기)
      // 🔀 랜덤을 골라뒀으면 사진 고정 대신 랜덤 (노래마다 바뀜)
      final random = p.getBool('lyricsBgRandom') ?? false;
      if (random != _random && mounted) setState(() => _random = random);
      // 내 사진 목록 (지워진 파일은 빼기)
      _myPhotos = (p.getStringList('lyricsMyPhotos') ?? []).where((f) => File(f).existsSync()).toList();
      final my = p.getString('lyricsBgMy');
      if (!random && my != null && File(my).existsSync()) {
        _myLight = p.getBool('lyricsBgMyLight') ?? false;
        if (mounted) setState(() => _myBg = my);
        return;
      }
      if (_myBg != null && mounted) setState(() => _myBg = null);
      if (random) return;
      final old = p.getInt('lyricsBg');
      final f = p.getString('lyricsBgFile') ?? (old != null ? 'lyrics_bg_$old.jpg' : null);
      if (f == null || !mounted) return;
      final i = _bgs.indexWhere((b) => b.file == f);
      if (i >= 0) {
        _lastBg = i + 1;
        if (_lastBg != _bg) setState(() => _bg = _lastBg!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _plainController.dispose();
    super.dispose();
  }

  bool get _light => _myBg != null ? _myLight : (_bg != 0 && _kLightBgs.contains(_bg));
  bool get _hasPhoto => _myBg != null || _bg != 0;
  bool get _busy => _myBg != null || _kBusyBgs.contains(_bg); // 내 사진은 글자가 잘 보이게 막을 조금 진하게

  /// 사진 위쪽 60%(가사 자리)가 밝은지 재보기 → 글자색 자동
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

  /// 내 사진으로 배경 바꾸기
  Future<void> _useMyPhoto(String path) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final light = await _isBright(path);
    if (!mounted) return;
    setState(() {
      _myBg = path;
      _myLight = light;
      _random = false;
    });
    final p = await SharedPreferences.getInstance();
    await p.setString('lyricsBgMy', path);
    await p.setBool('lyricsBgMyLight', light);
    await p.setBool('lyricsBgRandom', false);
  }

  /// + 사진 추가 (여러 장 한 번에, 넣자마자 첫 장으로)
  Future<void> _addMyPhotos(StateSetter setSheet) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final picked = await ImagePicker().pickMultiImage(imageQuality: 90, maxWidth: 1440);
    if (picked.isEmpty || !mounted) return;
    for (final f in picked.reversed) {
      if (!_myPhotos.contains(f.path)) _myPhotos.insert(0, f.path);
    }
    setSheet(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList('lyricsMyPhotos', _myPhotos);
    await _useMyPhoto(picked.first.path);
    setSheet(() {});
  }

  /// 관리 ✕: 목록에서 빼기 (지금 배경이면 파란소리 사진으로 돌아가기)
  Future<void> _removeMyPhoto(String path, StateSetter setSheet) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    _myPhotos.remove(path);
    final wasCurrent = _myBg == path;
    if (wasCurrent) setState(() => _myBg = null);
    if (_myPhotos.isEmpty) _manageMy = false;
    setSheet(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList('lyricsMyPhotos', _myPhotos);
    if (wasCurrent) await p.remove('lyricsBgMy');
  }

  /// 오른쪽 아래 워터마크 — 한국: 파란소리 | Paransori / 해외: ParanSori (한 줄, 은은하게)
  Widget _watermark(BuildContext context, {double scale = 1}) {
    final c = _ink.withOpacity(_light ? 0.72 : 0.88); // 더 잘 보이게
    final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)];
    // 영어 이름은 앱 전체 Quicksand로 통일 (바로 세움)
    return Text(
      'Paransori',
      style: GoogleFonts.quicksand(
          color: c,
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8 * scale,
          shadows: shadow),
    );
  }

  Color get _ink => _light ? const Color(0xFF17140F) : Colors.white;

  /// 🔀 지금 사진과 다른 사진 하나 고르기
  int _randomIndex() {
    final n = _kLyricsBgCount;
    if (n <= 1) return 1;
    var i = _bg;
    while (i == _bg) {
      i = 1 + math.Random().nextInt(n);
    }
    return i;
  }

  /// 🔀 노래마다 바꾸기 켜기·끄기 (창은 열어둔 채로)
  Future<void> _setRandom(bool on, StateSetter setSheet) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (on) {
      final song = context.read<PlayerProvider>().currentSong;
      final next = _randomIndex(); // 켜자마자 사진이 바뀌는 게 보이게
      setState(() {
        _random = true;
        _randomSongKey = song?.uri ?? song?.title ?? ''; // 지금 노래는 이 사진으로
        _bg = next;
        _myBg = null; // 랜덤은 파란소리 사진 중에서
      });
      _lastBg = next;
    } else {
      setState(() => _random = false); // 지금 보이는 사진으로 고정
    }
    setSheet(() {});
    final p = await SharedPreferences.getInstance();
    await p.setBool('lyricsBgRandom', on);
    if (!on) await p.setString('lyricsBgFile', _bgs[(_bg - 1).clamp(0, _bgs.length - 1)].file);
  }

  /// 📤 공유 버튼: 지금 부르는 줄로 카드 (전주라 아직 없으면 앞 줄 → 첫 줄)
  void _shareNow(LyricsProvider lp, PlayerProvider pp) {
    var line = '';
    if (lp.lyrics.isNotEmpty) {
      for (var j = lp.currentLineIndex; j >= 0 && j < lp.lyrics.length; j--) {
        line = lp.lyrics[j].text.trim();
        if (line.isNotEmpty) break;
      }
      if (line.isEmpty) {
        line = lp.lyrics.map((l) => l.text.trim()).firstWhere((t) => t.isNotEmpty, orElse: () => '');
      }
    } else {
      line = lp.plainLyrics.split('\n').map((l) => l.trim()).firstWhere((t) => t.isNotEmpty, orElse: () => '');
    }
    if (line.isEmpty) {
      showParanToast(context, '가사가 있어야 카드를 만들 수 있어요');
      return;
    }
    _openCard(line, pp);
  }

  /// 🎴 가사 한 줄 꾹 → 카드 공유 창
  void _openCard(String line, PlayerProvider playerProvider) {
    final text = line.trim();
    final song = playerProvider.currentSong;
    if (text.isEmpty || song == null) return;
    showLyricsCardSheet(
      context,
      line: text,
      title: song.titleDisplay,
      artist: song.artistDisplay,
      photos: [for (final b in _bgs) LyricsCardPhoto('$_kLyricsBgBase/${b.file}', light: b.light)],
      startPhoto: _bg > 0 ? _bg - 1 : 0, // 지금 가사 배경부터
    );
  }

  // ───── 가사 글자 크기 (0 작게 · 1 보통 · 2 크게, 모든 노래에 같이) ─────
  static int _sizeStep = 1;
  double get _curSize => const [15.0, 17.0, 19.5][_sizeStep]; // 지금 부르는 줄
  double get _lineSize => const [13.0, 14.5, 16.5][_sizeStep]; // 다른 줄·시간 없는 가사

  /// 가 가 가 고르기 창 (누르면 뒤 가사에 바로 보임, 창은 안 닫힘)
  void _pickTextSize() {
    showParanSheet(
      context,
      title: '가사 글자 크기',
      builder: (ctx, setSheet) {
        final dark = context.read<ThemeProvider>().isDarkMode;
        final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
        final onInk = dark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
        final card = dark ? const Color(0xFF32302C) : Colors.white;
        final line = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
        const labels = ['작게', '보통', '크게'];
        const sample = [15.0, 19.0, 23.0];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      setState(() => _sizeStep = i);
                      setSheet(() {});
                      final p = await SharedPreferences.getInstance();
                      await p.setInt('lyricsTextSize', i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 76,
                      decoration: BoxDecoration(
                        color: _sizeStep == i ? ink : card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _sizeStep == i ? ink : line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 28,
                            child: Center(
                              child: Text('가',
                                  style: TextStyle(
                                      color: _sizeStep == i ? onInk : ink,
                                      fontSize: sample[i],
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(labels[i],
                              style: TextStyle(
                                  color: _sizeStep == i ? onInk.withOpacity(0.8) : ink.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// ⏱ 박자 맞추기 창 (누를 때마다 바로 적용, 창은 안 닫힘)
  void _pickOffset(LyricsProvider lp) {
    showParanSheet(
      context,
      title: '가사 박자 맞추기',
      builder: (ctx, setSheet) {
        final ms = lp.offsetMs;
        final now = '${ms > 0 ? '+' : ''}${(ms / 1000).toStringAsFixed(1)}초';
        return ParanCard(
          children: [
            ParanInfoRow(label: '지금', value: ms == 0 ? '맞춘 적 없음' : now),
            ParanRow(
              icon: Icons.fast_forward_rounded,
              title: '가사를 빨리 (+0.5초)',
              onTap: () async {
                await lp.nudgeOffset(500);
                setSheet(() {});
              },
            ),
            ParanRow(
              icon: Icons.fast_rewind_rounded,
              title: '가사를 늦게 (−0.5초)',
              onTap: () async {
                await lp.nudgeOffset(-500);
                setSheet(() {});
              },
            ),
            ParanRow(
              icon: Icons.restart_alt_rounded,
              title: '원래대로',
              onTap: () async {
                await lp.resetOffset();
                setSheet(() {});
              },
            ),
          ],
        );
      },
    );
  }

  /// 수파베이스 list.json 받기 → 사진 빼기·넣기·순서를 앱 업데이트 없이
  Future<void> _loadBgList() async {
    final p = await SharedPreferences.getInstance();
    List<_LyricsBg>? parse(String? s) {
      if (s == null) return null;
      try {
        final list = (jsonDecode(s) as Map)['photos'] as List;
        return [
          for (final m in list.cast<Map>())
            if ((m['file'] ?? '').toString().isNotEmpty)
              _LyricsBg(m['file'].toString(), light: m['text'] == 'dark', busy: m['busy'] == true),
        ];
      } catch (_) {
        return null;
      }
    }

    final cached = parse(p.getString('lyricsBgList'));
    if (cached != null && cached.isNotEmpty) _applyBgList(cached);
    try {
      final r = await http.get(Uri.parse('$_kLyricsBgBase/list.json')).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final body = utf8.decode(r.bodyBytes);
        final l = parse(body);
        if (l != null && l.isNotEmpty) {
          await p.setString('lyricsBgList', body);
          _applyBgList(l);
        }
      }
    } catch (_) {}
  }

  /// 새 목록으로 바꾸기 (고른 사진은 그대로 유지, 목록에서 빠졌으면 첫 번째로)
  void _applyBgList(List<_LyricsBg> l) {
    final curFile = _bgs[(_bg - 1).clamp(0, _bgs.length - 1)].file;
    _bgs = l;
    final i = _bgs.indexWhere((b) => b.file == curFile);
    final n = i >= 0 ? i + 1 : 1;
    _lastBg = n;
    if (mounted) setState(() => _bg = n);
  }

  /// ✏ 가사 직접 넣기·고치기 창 (붙여넣기 → 저장, 노래마다 기억)
  Future<void> _editLyrics(LyricsProvider lp, PlayerProvider pp) async {
    final song = pp.currentSong;
    if (song == null) return;
    final ctrl = TextEditingController(text: lp.hasLyrics ? lp.editableText : '');
    final dark = context.read<ThemeProvider>().isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final onInk = dark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final card = dark ? const Color(0xFF32302C) : Colors.white;
    final line = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    final sheet = dark ? const Color(0xFF2B2926) : const Color(0xFFF4EFE5);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 키보드 위로
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(color: sheet, borderRadius: BorderRadius.circular(22)),
            child: StatefulBuilder(
              builder: (ctx, setSheet) => SingleChildScrollView(
               child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lp.hasManual ? '가사 직접 고치기' : '가사 직접 넣기',
                                  style: TextStyle(
                                      color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                              const SizedBox(height: 3),
                              Text('${song.titleDisplay} · ${song.artistDisplay}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: sub, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ),
                      ParanCloseX(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 키보드를 뺀 남은 자리에 맞춰 높이 (긴 가사는 칸 안에서 스크롤)
                  SizedBox(
                   height: (MediaQuery.of(ctx).size.height -
                           MediaQuery.of(ctx).viewInsets.bottom -
                           MediaQuery.of(ctx).padding.top -
                           290)
                       .clamp(110.0, 300.0),
                   child: TextField(
                    controller: ctrl,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) => setSheet(() {}),
                    style: TextStyle(color: ink, fontSize: 14.5, height: 1.5),
                    cursorColor: ink,
                    decoration: InputDecoration(
                      hintText: '가사를 붙여넣어 주세요\n[00:12.34] 처럼 시간이 있으면 노래에 맞춰 나와요',
                      hintMaxLines: 3,
                      hintStyle: TextStyle(color: sub, fontSize: 13.5, height: 1.5),
                      filled: true,
                      fillColor: card,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ink, width: 1.5),
                      ),
                    ),
                   ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final d = await Clipboard.getData('text/plain');
                          final t = d?.text ?? '';
                          if (t.trim().isEmpty) return;
                          ctrl.text = t;
                          setSheet(() {});
                        },
                        style: TextButton.styleFrom(foregroundColor: ink),
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: const Text('붙여넣기', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      if (ctrl.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ctrl.clear();
                            setSheet(() {});
                          },
                          style: TextButton.styleFrom(foregroundColor: sub),
                          child: const Text('비우기'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: ctrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: onInk,
                        disabledBackgroundColor: ink.withOpacity(0.15),
                        disabledForegroundColor: sub,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                    ),
                  ),
                ],
               ),
              ),
            ),
          ),
        ),
      ),
    );
    if (saved == true) {
      await lp.saveManualLyrics(song.titleDisplay, song.artistDisplay, ctrl.text);
      if (mounted) showParanToast(context, '이 노래 가사로 저장했어요');
    }
  }

  /// 직접 넣은 가사 지우기 (지우면 인터넷에서 다시 찾기)
  Future<void> _deleteManual(LyricsProvider lp, PlayerProvider pp) async {
    final song = pp.currentSong;
    if (song == null) return;
    final ok = await showParanConfirm(
      context,
      title: '직접 넣은 가사를 지울까요?',
      message: '지우면 인터넷에서 다시 찾아요',
      confirmLabel: '지우기',
      danger: true,
    );
    if (!ok) return;
    await lp.deleteManualLyrics(song.titleDisplay, song.artistDisplay, filePath: song.uri);
  }

  /// 🖼 배경 고르기 창
  void _pickBackground() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    _manageMy = false;
    showParanSheet(
      context,
      title: '가사 배경',
      builder: (ctx, setSheet) {
        Widget tile(int i) {
          final selected = !_random && _myBg == null && _bg == i;
          return GestureDetector(
            onTap: () async {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() {
                _bg = i;
                _myBg = null; // 파란소리 사진을 고르면 내 사진은 끄기
                _random = false; // 사진을 하나 고르면 랜덤은 끄고 이 사진으로 고정
              });
              _lastBg = i;
              setSheet(() {});
              final p = await SharedPreferences.getInstance();
              await p.setString('lyricsBgFile', _bgs[(i - 1).clamp(0, _bgs.length - 1)].file);
              await p.setBool('lyricsBgRandom', false);
              await p.remove('lyricsBgMy');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF17140F) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (i == 0)
                        Container(
                          color: AppTheme.background,
                          alignment: Alignment.center,
                          child: const Text('사진 없이',
                              style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: _bgUrl(i),
                          fit: BoxFit.cover,
                          memCacheWidth: 270, // 작게 미리보기
                          placeholder: (_, __) => Container(color: const Color(0x22000000)),
                          errorWidget: (_, __, ___) => Container(color: const Color(0x22000000)),
                        ),
                      if (selected)
                        const Positioned(
                          right: 6,
                          top: 6,
                          child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final dark = context.read<ThemeProvider>().isDarkMode;
        final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
        final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);

        // + 사진 추가
        Widget addTile() => GestureDetector(
              onTap: () => _addMyPhotos(setSheet),
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF32302C) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB), width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: sub, size: 26),
                    const SizedBox(height: 4),
                    Text('사진 추가', style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );

        // 내 사진 한 장 (관리 모드면 ✕)
        Widget myTile(String f) {
          final selected = !_random && _myBg == f;
          return GestureDetector(
            onTap: _manageMy
                ? null
                : () async {
                    await _useMyPhoto(f);
                    setSheet(() {});
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected && !_manageMy ? const Color(0xFF17140F) : Colors.transparent, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(f),
                        fit: BoxFit.cover,
                        cacheWidth: 270, // 작게 미리보기
                        errorBuilder: (_, __, ___) => Container(color: const Color(0x22000000))),
                    if (selected && !_manageMy)
                      const Positioned(
                        right: 6,
                        top: 6,
                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      ),
                    if (_manageMy)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => _removeMyPhoto(f, setSheet),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: Color(0xB317140F), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        // 칸 제목 (내 사진 · 파란소리 사진)
        Widget header(String t, {Widget? trailing}) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Text(t, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (trailing != null) trailing,
                ],
              ),
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔀 노래마다 바꾸기 (스위치 — 설정 화면 스위치와 같은 모양)
            ParanCard(
              children: [
                InkWell(
                  onTap: () => _setRandom(!_random, setSheet),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        SizedBox(width: 22, child: Icon(Icons.shuffle_rounded, color: sub, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('노래마다 바꾸기',
                                  style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text('노래가 바뀔 때마다 다른 사진', style: TextStyle(color: sub, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _random,
                          onChanged: (v) => _setRandom(v, setSheet),
                          activeColor: Theme.of(ctx).colorScheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ── 내 사진 ──
            header('내 사진',
                trailing: _myPhotos.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () => setSheet(() => _manageMy = !_manageMy),
                        child: Text(_manageMy ? '완료' : '관리',
                            style: TextStyle(
                                color: _manageMy ? Theme.of(ctx).colorScheme.primary : sub,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      )),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 9 / 16,
              children: [if (!_manageMy) addTile(), for (final f in _myPhotos) myTile(f)],
            ),
            // ── 파란소리 사진 ──
            header('파란소리 사진'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 9 / 16,
              children: [for (var i = 1; i <= _kLyricsBgCount; i++) tile(i)],
            ),
          ],
        );
      },
    );
  }

  // 오른쪽 위 버튼 묶음: 자주 쓰는 것만 밖에, 나머지는 ⋮ 안으로 (유리 알약 하나에)
  Widget _topButtons(LyricsProvider lp, PlayerProvider pp) {
    final c = _ink.withOpacity(0.85);
    Widget btn(IconData icon, VoidCallback onTap) => InkResponse(
          onTap: onTap,
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Icon(icon, size: 20, color: c),
          ),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _light ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ink.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lp.hasLyrics) btn(Icons.ios_share_rounded, () => _shareNow(lp, pp)),
              btn(Icons.wallpaper_rounded, _pickBackground),
              PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                offset: const Offset(0, 40),
                onSelected: (v) {
                  if (v == 'offset') _pickOffset(lp);
                  if (v == 'size') _pickTextSize();
                  if (v == 'edit') _editLyrics(lp, pp);
                  if (v == 'delete') _deleteManual(lp, pp);
                  if (v == 'refresh') {
                    final song = pp.currentSong;
                    if (song != null) {
                      lp.fetchLyrics(song.titleDisplay, song.artistDisplay, force: true);
                    }
                  }
                },
                itemBuilder: (_) => [
                  if (lp.hasLyrics) _menuItem(Icons.format_size_rounded, '가사 글자 크기', 'size'),
                  if (lp.lyrics.isNotEmpty) _menuItem(Icons.timer_outlined, '박자 맞추기', 'offset'),
                  // 직접 넣은 가사가 있으면 그게 먼저라서 "다시 찾기" 대신 "지우기"
                  if (!lp.hasManual) _menuItem(Icons.refresh, '가사 다시 찾기', 'refresh'),
                  _menuItem(Icons.edit_note_rounded, lp.hasManual ? '가사 직접 고치기' : '가사 직접 넣기', 'edit'),
                  if (lp.hasManual) _menuItem(Icons.delete_outline_rounded, '직접 넣은 가사 지우기', 'delete'),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  child: Icon(Icons.more_vert_rounded, size: 20, color: c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, String value) => PopupMenuItem(
        value: value,
        height: 44,
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.fixedAccent),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;


    // 🔀 랜덤: 노래가 바뀌면 다른 사진으로 (같은 노래 듣는 동안은 그대로)
    final songKey = playerProvider.currentSong?.uri ?? playerProvider.currentSong?.title ?? '';
    if (_random && songKey.isNotEmpty && songKey != _randomSongKey) {
      _randomSongKey = songKey;
      _bg = _randomIndex();
      _lastBg = _bg;
    }

    lyricsProvider.updateCurrentLine(playerProvider.position);

    // 지금 부르는 줄이 바뀔 때만, 가사 칸의 위쪽 1/3 자리로 부드럽게 옮기기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 손으로 움직인 지 4초 안 됐으면 자동으로 안 움직이기
      if (DateTime.now().difference(_userScrolledAt).inSeconds < 4) return;
      if (_selAnchor != null) return; // 줄 고르는 중엔 자동으로 안 움직이기
      // 시간 없는 가사: 노래 진행만큼 천천히 자동으로 내려가기
      if (lyricsProvider.hasLyrics && lyricsProvider.lyrics.isEmpty && _plainController.hasClients) {
        final dur = playerProvider.duration.inMilliseconds;
        if (dur > 0) {
          // 앞 10%(전주)·끝 8%는 가만히, 그 사이에서만 천천히 내려가기
          final raw = playerProvider.position.inMilliseconds / dur;
          final f = ((raw - 0.10) / 0.82).clamp(0.0, 1.0);
          final target = _plainController.position.maxScrollExtent * f;
          if ((_plainController.offset - target).abs() > 2) {
            _plainController.animateTo(target,
                duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
          }
        }
        return;
      }
      final index = lyricsProvider.currentLineIndex;
      if (lyricsProvider.lyrics.isEmpty || index == _lastLine) return;
      // 전주(첫 줄 전): 아무 줄도 안 올리고 맨 위에 그대로
      if (index < 0) {
        _lastLine = index;
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
        }
        return;
      }
      final ctx = _lineKeys[index]?.currentContext;
      if (ctx == null) return;
      _lastLine = index;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 사진 밝기에 맞춰 위·아래 시스템 아이콘 색
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _light ? Brightness.dark : Brightness.light,
        statusBarBrightness: _light ? Brightness.light : Brightness.dark,
        // 버튼 3개 폰(노트20·A9 프로)은 투명이면 흰 배경이 깔려서 → 사진에 맞는 색을 직접 칠함
        systemNavigationBarColor: _light ? const Color(0xFFF4EFE5) : const Color(0xFF14110C),
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false, // 안드로이드가 억지로 까는 흰 배경 끄기
        systemNavigationBarIconBrightness: _light ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF14110C), // 사진 뜨기 전 파랗게 보이지 않게
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          // 위 줄은 버튼만 (제목·가수는 아래 왼쪽으로)
          title: const SizedBox.shrink(),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _ink, size: 30),
          ),
          actions: [
            // 공유 · 배경 · ⋮(박자 맞추기 · 가사 다시 찾기)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: _topButtons(lyricsProvider, playerProvider)),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 사진
            if (_myBg != null)
              // 내 사진 배경 (화면 크기만큼만 풀기)
              RepaintBoundary(
                child: Image.file(File(_myBg!),
                    fit: BoxFit.cover,
                    cacheWidth: 1080,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF14110C))),
              )
            else if (_bg != 0)
              // 배경 사진은 한 번만 그리고 고정 (가사가 바뀔 때마다 다시 안 그리게)
              RepaintBoundary(
                child: CachedNetworkImage(
                  imageUrl: _bgUrl(_bg),
                  fit: BoxFit.cover,
                  memCacheWidth: 1080, // 화면 크기만큼만
                  useOldImageOnUrlChange: true,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (_, __) => Container(color: const Color(0xFF14110C)),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF14110C)),
                ),
              ),
            // 글자가 잘 보이게 얇은 막 (밝은 사진은 크림색, 어두운 사진은 검은색)
            if (_hasPhoto)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _light
                        ? [
                            const Color(0xFFF4EFE5).withOpacity(_busy ? 0.72 : 0.55),
                            const Color(0xFFF4EFE5).withOpacity(_busy ? 0.5 : 0.3),
                            const Color(0xFFF4EFE5).withOpacity(0.05),
                          ]
                        : [
                            Colors.black.withOpacity(0.45),
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.05),
                          ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            // 가사는 화면 위쪽 약 60%에만 (아래 사진 속 고양이·헤드폰을 가리지 않게)
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 62,
                    // 흐려지는 효과는 무거워서 빼고, 가사 칸만 따로 그리기
                    child: RepaintBoundary(
                      child: _buildBody(lyricsProvider, playerProvider, primaryColor),
                    ),
                  ),
                  const Spacer(flex: 38),
                ],
              ),
            ),
            // 맨 아래 시스템 아이콘 자리만 살짝 막 깔기 (사진마다 아래 밝기가 달라서)
            if (_hasPhoto)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).padding.bottom + 56,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _light
                            ? [const Color(0x00F4EFE5), const Color(0xB3F4EFE5)]
                            : [Colors.black.withOpacity(0), Colors.black.withOpacity(0.45)],
                      ),
                    ),
                  ),
                ),
              ),
            // 아래 왼쪽: 제목 · 가수 · 진행 막대 (워터마크 위에)
            if (playerProvider.currentSong != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: IgnorePointer(
                  child: Builder(builder: (_) {
                    final song = playerProvider.currentSong!;
                    final shadow = _light
                        ? const <Shadow>[]
                        : [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 8)];
                    final dur = playerProvider.duration.inMilliseconds;
                    final f = dur > 0
                        ? (playerProvider.position.inMilliseconds / dur).clamp(0.0, 1.0)
                        : 0.0;
                    // 반투명 유리 카드: 뒤 사진을 살짝 흐리게 → 어떤 사진이어도 글자가 또렷하게
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          decoration: BoxDecoration(
                            color: _light ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _ink.withOpacity(0.08)),
                          ),
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(song.titleDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _ink,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                shadows: shadow)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            // 포인트색 점 (미니플레이어 진행 바와 같은 색)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(song.artistDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: _ink.withOpacity(_light ? 0.85 : 0.72),
                                      fontSize: 14,
                                      fontWeight: _light ? FontWeight.w600 : FontWeight.w500,
                                      shadows: shadow)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 노래가 어디쯤인지 (얇은 막대)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(height: 2.5, color: _ink.withOpacity(0.2)),
                              FractionallySizedBox(
                                widthFactor: f,
                                child: Container(height: 2.5, color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                        // 파란소리 워터마크 (카드 안 오른쪽 아래, 캡처해서 공유할 때 보이게)
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Opacity(opacity: 0.85, child: _watermark(context, scale: 0.78)),
                        ),
                      ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            // 여러 줄 고르는 중: 아래 바 (✕ · N줄 골랐어요 · 카드 만들기)
            if (_selAnchor != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EFE5),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _cancelSel,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF8A8378), size: 22),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_selTexts.length}줄 골랐어요',
                                  style: const TextStyle(
                                      color: Color(0xFF17140F), fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              const Text('다른 줄을 누르면 거기까지 · 최대 5줄',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Color(0xFF8A8378), fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _selTexts.isEmpty
                              ? null
                              : () {
                                  final text = _selTexts.join('\n');
                                  _cancelSel();
                                  _openCard(text, playerProvider);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF17140F),
                            foregroundColor: const Color(0xFFF4EFE5),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('카드 만들기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildBody(LyricsProvider lyricsProvider, PlayerProvider playerProvider, Color primaryColor) {
    final ink = _ink;
    final sub = ink.withOpacity(0.6);
    final shadow = _light
        ? const <Shadow>[]
        : [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 8)];

    if (lyricsProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: sub),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.lyricsLoading, style: TextStyle(color: sub, shadows: shadow)),
          ],
        ),
      );
    }

    if (!lyricsProvider.hasLyrics) {
      // 가사 없을 때: 유리 카드 하나에 안내 + [다시 찾기] [직접 넣기]
      final noNet = lyricsProvider.errorMessage.isNotEmpty &&
          lyricsProvider.errorMessage == AppLocalizations.of(context)!.lyricsErrorNetwork;
      final fillBg = _light ? const Color(0xFF17140F) : const Color(0xFFF4EFE5); // 꽉 찬 버튼
      final fillFg = _light ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: _light ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ink.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withOpacity(0.08)),
                      child: Icon(Icons.music_note_rounded, size: 22, color: ink.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      noNet ? '인터넷 연결을 확인해 주세요' : '이 노래 가사를 아직 못 찾았어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: ink, fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.3, shadows: shadow),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      noNet ? '연결되면 다시 찾아볼 수 있어요' : '다시 찾거나, 가사를 직접 넣을 수 있어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: sub, fontSize: 13, height: 1.4, shadows: shadow),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                final song = playerProvider.currentSong;
                                if (song != null) {
                                  lyricsProvider.fetchLyrics(song.titleDisplay, song.artistDisplay,
                                      filePath: song.uri, force: true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fillBg,
                                foregroundColor: fillFg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('다시 찾기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => _editLyrics(lyricsProvider, playerProvider),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ink,
                                side: BorderSide(color: ink.withOpacity(0.35), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('직접 넣기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (lyricsProvider.lyrics.isNotEmpty) {
      _visibleLines = [for (final l in lyricsProvider.lyrics) l.text];
      // 모든 줄을 같은 간격으로 (긴 줄은 두 줄로 내려가도 간격은 일정하게)
      return NotificationListener<UserScrollNotification>(
        onNotification: (_) {
          _userScrolledAt = DateTime.now();
          return false;
        },
        child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
        child: Column(
          children: [
            for (var index = 0; index < lyricsProvider.lyrics.length; index++)
              GestureDetector(
                key: _lineKeys.putIfAbsent(index, () => GlobalKey()),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_selAnchor != null) {
                    _extendSel(index); // 고르는 중이면 여기까지 고르기
                    return;
                  }
                  playerProvider.seekTo(lyricsProvider.lyrics[index].time);
                },
                onLongPress: () => _startSel(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: _isSel(index) ? ink.withOpacity(0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (index == lyricsProvider.currentLineIndex || _isSel(index)) ? ink : ink.withOpacity(0.5),
                        fontSize: index == lyricsProvider.currentLineIndex ? _curSize : _lineSize,
                        height: 1.45,
                        letterSpacing: -0.2,
                        fontWeight:
                            index == lyricsProvider.currentLineIndex ? FontWeight.w700 : FontWeight.w500,
                        shadows: shadow,
                      ),
                      child: Text(lyricsProvider.lyrics[index].text.trim(), textAlign: TextAlign.center),
                    ),
                  ),
                ),
                ),
              ),
          ],
        ),
      ),
      );
    }

    // 시간 없는 가사: 빈 줄이 여러 개 겹친 건 하나로 정리해서 고른 간격으로
    final plain = lyricsProvider.plainLyrics.replaceAll('\r', '').replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n').trim();
    _visibleLines = plain.split('\n');
    return NotificationListener<UserScrollNotification>(
      onNotification: (_) {
        _userScrolledAt = DateTime.now();
        return false;
      },
      child: SingleChildScrollView(
      controller: _plainController,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
      child: Column(
        children: [
          // 한 줄씩 나눠서 그리기 → 꾹 누르면 그 줄로 카드 (보이는 모양은 그대로)
          for (var i = 0; i < _visibleLines.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _selAnchor != null ? () => _extendSel(i) : null,
              onLongPress: _visibleLines[i].trim().isEmpty ? null : () => _startSel(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isSel(i) ? ink.withOpacity(0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _visibleLines[i],
                  style: TextStyle(
                      color: ink,
                      fontSize: _lineSize,
                      height: 1.8,
                      letterSpacing: -0.2,
                      fontWeight: _isSel(i) ? FontWeight.w700 : FontWeight.w400,
                      shadows: shadow),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
