import 'dart:math' as math;
import '../utils/no_album_helper.dart';
import '../utils/paran_photo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/greeting_images.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'edit_song_screen.dart';
import 'lyrics_screen.dart';
import 'ringtone_screen.dart';
import 'equalizer_screen.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/exit_confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/menu_parts.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';
import '../services/cast_service.dart';
import '../services/nature_overlay.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import '../main.dart' show globalAudioHandler;
import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

/// 재생바 동그라미: 흰색 + 아주 은은한 빛
class _GlowThumbShape extends SliderComponentShape {
  final double radius;
  const _GlowThumbShape({this.radius = 6});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center,
      radius + 3,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
  }
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  bool _isSeeking = false; // 재생바를 손으로 잡고 있는 중인지
  late AnimationController _rotationController;
  late AnimationController _equalizerController;
  late List<AnimationController> _eqControllers;
  late List<Animation<double>> _eqAnimations;
  int _albumArtStyle = 1;
  bool _showNightPicker = true;
  String? _nightSelectedCategory;
  String _nightBgPath = 'assets/music_night_bg.png';
  // 파란포토 자동 변경용: 마지막 곡을 화면이 닫혀도 기억 (뒤로 갔다 다른 곡 골라도 바뀌게)
  static String? _lastBgSongUri;
  bool _styleLoaded = false; // 저장된 스타일·사진을 다 불러왔는지
  Set<String> _nightFavPaths = {};
  bool _nightBgIsFile = false;
  int _bgFilter = 0; // 0 컬러, 1 흑백, 2 세피아, 3 필름, 4 인화
  final GlobalKey _paranKey = GlobalKey(); // 파란포토 화면을 사진으로 찍어 TV에 보내기
  final GlobalKey _cardKey = GlobalKey(); // 앨범 카드(인화 모양)를 찍어 TV에 보내기
  String? _tvArtKey; // 마지막으로 찍은 사진 (같으면 다시 안 찍음)
  Timer? _tvArtTimer;
  int _printStyle = 0; // 앨범 스타일 인화 모양: 0 기본, 1 폴라로이드, 2 테이프, 3 겹친 사진, 4 둥근 테두리
  int _autoBgMin = 0; // 0 끄기, 10, 30 (분)
  Timer? _autoBgTimer;

  static const Map<String, String> _nightCategoryCover = {
    '봄': 'assets/spring_photo1.png',
    '여름': 'assets/summer_photo1.png',
    '가을': 'assets/autumn_photo1.png',
    '겨울': 'assets/winter_photo1.png',
    '감성': 'assets/mood_photo1.png',
    '동물': 'assets/animal_photo1.png',
    '사랑': 'assets/love_photo1.png',
    '기타': 'assets/etc_photo1.png',
  };

  static const Map<String, List<String>> _nightCategoryPhotos = {
    '봄': [
      'assets/spring_photo1.png',
      'assets/spring_photo2.png',
      'assets/spring_photo3.png',
      'assets/spring_photo4.png',
      'assets/spring_photo5.png',
      'assets/spring_photo6.png',
    ],
    '여름': [
      'assets/summer_photo1.png',
      'assets/summer_photo2.png',
      'assets/summer_photo3.png',
      'assets/summer_photo4.png',
      'assets/summer_photo5.png',
      'assets/summer_photo6.png',
    ],
    '가을': [
      'assets/autumn_photo1.png',
      'assets/autumn_photo2.png',
      'assets/autumn_photo3.png',
      'assets/autumn_photo4.png',
      'assets/autumn_photo5.png',
      'assets/autumn_photo6.png',
    ],
    '겨울': [
      'assets/winter_photo1.png',
      'assets/winter_photo2.png',
      'assets/winter_photo3.png',
      'assets/winter_photo4.png',
      'assets/winter_photo5.png',
      'assets/winter_photo6.png',
    ],
    '감성': [
      'assets/mood_photo1.png',
      'assets/mood_photo2.png',
      'assets/mood_photo3.png',
      'assets/mood_photo4.png',
      'assets/mood_photo5.png',
      'assets/mood_photo6.png',
    ],
    '동물': [
      'assets/animal_photo1.png',
      'assets/animal_photo2.png',
      'assets/animal_photo3.png',
      'assets/animal_photo4.png',
      'assets/animal_photo5.png',
      'assets/animal_photo6.png',
    ],
    '사랑': [
      'assets/love_photo1.png',
      'assets/love_photo2.png',
      'assets/love_photo3.png',
      'assets/love_photo4.png',
      'assets/love_photo5.png',
      'assets/love_photo6.png',
      'assets/love_photo7.png',
      'assets/love_photo8.png',
      'assets/love_photo9.png',
      'assets/love_photo10.png',
    ],
    '기타': [
      'assets/etc_photo1.png',
      'assets/etc_photo2.png',
      'assets/etc_photo3.png',
      'assets/etc_photo4.png',
      'assets/etc_photo5.png',
      'assets/etc_photo6.png',
    ],
  };
  Color _dominantColor = const Color(0xFF1A1A1A);
  bool _showSwipeHint = false;
  bool _hasSeenParanPhoto = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startEqAnimations();

    _loadStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      final currentSong = playerProvider.currentSong;
      if (currentSong != null) {
        context.read<LyricsProvider>().fetchLyrics(
          currentSong.titleDisplay,
          currentSong.artistDisplay,
          filePath: currentSong.uri,
        );
        _extractColor(currentSong);
      }
      playerProvider.onSongChanged = (song) {
        _extractColor(song);
        _countCdPlay(); // 시디롬·앨범으로 10곡 들으면 파란포토 권하기 (한 번만)
      };
    });
  }

  // ───── 파란포토 권하기 (시디롬·앨범 쓰는 사람에게 한 번만) ─────
  bool _showParanSuggest = false;
  Timer? _suggestTimer;

  Future<void> _countCdPlay() async {
    if (_albumArtStyle == 6) return; // 이미 파란포토
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('paranSuggestDone') ?? false) return; // 이미 한 번 보여줌
    final n = (prefs.getInt('cdPlayCount') ?? 0) + 1;
    await prefs.setInt('cdPlayCount', n);
    if (n >= 10 && mounted) {
      await prefs.setBool('paranSuggestDone', true);
      setState(() => _showParanSuggest = true); // 괜찮아요 / 구경하기 누를 때까지 그대로
    }
  }

  /// 구경하기: 파란포토로 바꾸고, 잠깐 "시디롬으로 되돌리기" 버튼
  void _tryParanPhoto() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final prev = _albumArtStyle;
    _suggestTimer?.cancel();
    setState(() {
      _showParanSuggest = false;
      _albumArtStyle = 6;
      _hasSeenParanPhoto = true;
    });
    _saveStyle(6);
    SharedPreferences.getInstance().then((p) => p.setBool('hasSeenParanPhoto', true));
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2589E8), size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('파란포토로 바꿨어요',
                  style: TextStyle(color: Color(0xFF17140F), fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                if (!mounted) return;
                setState(() => _albumArtStyle = prev);
                _saveStyle(prev);
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2589E8)),
              child: Text(prev == 3 ? '앨범으로 되돌리기' : '시디롬으로 되돌리기',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ));
  }

  /// 시디·앨범 아래쪽에 잠깐 떠오르는 권하기 카드
  Widget _withParanSuggest(Widget child) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !_showParanSuggest,
            child: AnimatedSlide(
              offset: _showParanSuggest ? Offset.zero : const Offset(0, 0.2),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showParanSuggest ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: paranPhoto(_nightBgPath, thumb: true, width: 56, height: 56, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('파란포토로 들어볼까요?',
                                    style: TextStyle(
                                        color: Color(0xFF17140F), fontSize: 15.5, fontWeight: FontWeight.w800)),
                                SizedBox(height: 4),
                                Text('예쁜 사진 위로 음악이 흘러요',
                                    style: TextStyle(color: Color(0xFF8A857B), fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _suggestTimer?.cancel();
                              setState(() => _showParanSuggest = false);
                            },
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF8A857B)),
                            child: const Text('괜찮아요', style: TextStyle(fontSize: 13.5)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: _tryParanPhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2589E8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('구경하기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = false;
    setState(() {
      _albumArtStyle = prefs.getInt('albumArtStyle') ?? 6; // 처음엔 파란포토로 시작
      _nightBgPath = prefs.getString('nightBgPath') ?? 'assets/spring_photo1.png';
      _nightFavPaths = (prefs.getStringList('nightFavPaths') ?? []).toSet();
      _nightBgIsFile = prefs.getBool('nightBgIsFile') ?? false;
      _showNightPicker = prefs.getBool('showNightPicker') ?? true;
      _hasSeenParanPhoto = prefs.getBool('hasSeenParanPhoto') ?? false;
      _showSwipeHint = !shown;
      _bgFilter = prefs.getInt('bgFilter') ?? 0;
      if (_bgFilter == 4) _bgFilter = 0; // 예전 인화 설정 → 컬러로
      _printStyle = prefs.getInt('printStyle') ?? 0;
      _autoBgMin = prefs.getInt('autoBgMin') ?? 0;
      _styleLoaded = true;
    });
    _restartAutoBgTimer();
    if (!shown) {
      await prefs.setBool('swipe_hint_shown', true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSwipeHint = false);
      });
    }
  }

  // ===== 파란포토 색감 / 자동 변경 =====
  Future<void> _setBgFilter(int v) async {
    setState(() => _bgFilter = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bgFilter', v);
  }

  Future<void> _setPrintStyle(int v) async {
    setState(() => _printStyle = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('printStyle', v);
  }

  /// 인화 사진 카드 (모양 4가지)
  /// TV에 보낼 사진 정하기 (스타일·사진·색감·인화 모양이 바뀔 때만)
  /// - 파란포토: 보이는 사진(색감 포함) 그대로
  /// - 앨범 + 인화 모양: 곡마다 꾸민 카드 그대로
  /// - 그 밖: 곡 앨범 사진
  void _syncTvArt() {
    final cast = CastService.instance;
    final isCard = _albumArtStyle == 3 && _printStyle != 0;
    final key = _albumArtStyle == 6
        ? 'paran-$_nightBgPath-$_bgFilter'
        : (isCard ? 'card-$_printStyle' : 'album');
    if (key == _tvArtKey) return;
    final first = _tvArtKey == null;
    _tvArtKey = key;
    _tvArtTimer?.cancel();
    // 앨범 카드면 곡마다 찍어줄 함수를 넘겨둠
    cast.cardArt = isCard ? _makeCardArt : null;
    if (_albumArtStyle == 6) {
      // 사진 바뀌는 애니메이션(1.2초)이 끝난 뒤에 찍기
      _tvArtTimer = Timer(const Duration(milliseconds: 1600), () async {
        if (!mounted) return;
        final bytes = await _captureKey(_paranKey);
        if (bytes != null) cast.setParanArt(bytes);
      });
    } else if (!first) {
      // 스타일·인화 모양을 바꿨으면 TV 사진도 바로 바꾸기
      cast.setParanArt(null);
    } else {
      cast.setParanArt(null);
    }
  }

  /// 이 곡의 앨범 카드가 화면에 그려지면 찍기
  Future<Uint8List?> _makeCardArt(Song song) async {
    for (var i = 0; i < 12; i++) {
      if (!mounted) return null;
      if (context.read<PlayerProvider>().currentSong?.uri == song.uri) break;
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await Future.delayed(const Duration(milliseconds: 250)); // 새 앨범 사진이 그려질 시간
    if (!mounted) return null;
    return _captureKey(_cardKey);
  }

  Future<Uint8List?> _captureKey(GlobalKey key) async {
    try {
      final b = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) return null;
      final img = await b.toImage(pixelRatio: 2.0);
      final data = await img.toByteData(format: ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _captureParan() async {
    try {
      final b = _paranKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) return null;
      final img = await b.toImage(pixelRatio: 2.0);
      final data = await img.toByteData(format: ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Widget _printCard(Widget photo) {
    const paperColor = Color(0xFFF6F1E6); // 인화지 색
    final shadow = [
      BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
    ];
    Widget paper(Widget c, EdgeInsets pad, {Color color = paperColor}) => Container(
          padding: pad,
          decoration: BoxDecoration(color: color, boxShadow: shadow),
          child: c,
        );
    Widget square(Widget c) => AspectRatio(aspectRatio: 1, child: c);

    switch (_printStyle) {
      case 2: // 테이프 붙인 사진
        Widget tape(double angle) => Transform.rotate(
              angle: angle,
              child: Container(width: 62, height: 20, color: const Color(0xD9ECE0C4)),
            );
        return Transform.rotate(
          angle: 0.035,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              paper(square(photo), const EdgeInsets.all(9)),
              Positioned(left: -18, top: -6, child: tape(-0.55)),
              Positioned(right: -18, top: -6, child: tape(0.55)),
            ],
          ),
        );
      case 3: // 겹쳐 놓은 사진
        Widget washed() => Stack(
              fit: StackFit.passthrough,
              children: [photo, Container(color: const Color(0x66F6F1E6))],
            );
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-16, 8),
              child: Transform.rotate(
                angle: -0.14,
                child: paper(square(washed()), const EdgeInsets.all(8), color: const Color(0xFFEFE8DA)),
              ),
            ),
            Transform.translate(
              offset: const Offset(14, -6),
              child: Transform.rotate(
                angle: 0.1,
                child: paper(square(washed()), const EdgeInsets.all(8), color: const Color(0xFFF2ECDF)),
              ),
            ),
            Transform.rotate(
              angle: -0.02,
              child: paper(square(photo), const EdgeInsets.fromLTRB(9, 9, 9, 26)),
            ),
          ],
        );
      case 4: // 둥근 모서리 + 얇은 테두리
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: shadow,
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(13), child: square(photo)),
        );
      default: // 폴라로이드
        return Transform.rotate(
          angle: -0.05,
          child: paper(square(photo), const EdgeInsets.fromLTRB(10, 10, 10, 34)),
        );
    }
  }

  Future<void> _setAutoBg(int minutes) async {
    setState(() => _autoBgMin = minutes);
    _restartAutoBgTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autoBgMin', minutes);
  }

  void _restartAutoBgTimer() {
    _autoBgTimer?.cancel();
    _autoBgTimer = null;
    if (_autoBgMin <= 0) return;
    _autoBgTimer = Timer.periodic(Duration(minutes: _autoBgMin), (_) => _autoChangeBg());
  }

  void _autoChangeBg() {
    if (!mounted || _albumArtStyle != 6) return;
    if (!context.read<PlayerProvider>().isPlaying) return;
    // 하트한 사진이 2장 이상이면 그중에서, 아니면 지금 사진과 같은 카테고리에서
    final List<String> pool = _nightFavPaths.length >= 2
        ? _nightFavPaths.toList()
        : _nightCategoryPhotos.values
            .firstWhere((l) => l.contains(_nightBgPath), orElse: () => const [])
            .toList();
    pool.remove(_nightBgPath);
    if (pool.isEmpty) return;
    final next = pool[math.Random().nextInt(pool.length)];
    final nextIsFile = !next.startsWith('assets/');
    if (!nextIsFile) precacheParanPhoto(next, context); // 미리 받아두기
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _nightBgPath = next;
        _nightBgIsFile = nextIsFile;
      });
      _saveNightBg(next, isFile: nextIsFile);
    });
  }

  Widget _bgFiltered(Widget child) {
    if (_bgFilter == 1) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    if (_bgFilter == 2) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }

    if (_bgFilter == 3) {
      // 필름: 바랜 따뜻한 색 + 가장자리 어둡게 + 필름 입자
      return Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.7016, 0.1803, 0.0182, 0, 19,
              0.0524, 0.8099, 0.0178, 0, 17,
              0.0464, 0.1562, 0.5774, 0, 19,
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0,
                  colors: [Colors.transparent, Color(0x73000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _FilmGrainPainter()),
            ),
          ),
        ],
      );
    }
    return child;
  }

  Widget _buildPhotoOptions() {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2F7DE8) : Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.white.withOpacity(0.25),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    Widget optionRow(String title, List<Widget> chips) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            for (final c in chips) ...[c, const SizedBox(width: 6)],
          ],
        ),
      );
    }

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Center(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
    SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          label('색감'),
          chip('컬러', _bgFilter == 0, () => _setBgFilter(0)),
          const SizedBox(width: 6),
          chip('흑백', _bgFilter == 1, () => _setBgFilter(1)),
          const SizedBox(width: 6),
          chip('세피아', _bgFilter == 2, () => _setBgFilter(2)),
          const SizedBox(width: 6),
          chip('필름', _bgFilter == 3, () => _setBgFilter(3)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Container(width: 1, color: Colors.white.withOpacity(0.3)),
          ),
          label('자동'),
          chip('끄기', _autoBgMin == 0, () => _setAutoBg(0)),
          const SizedBox(width: 6),
          chip('10분', _autoBgMin == 10, () => _setAutoBg(10)),
          const SizedBox(width: 6),
          chip('30분', _autoBgMin == 30, () => _setAutoBg(30)),
        ],
      ),
    ),

      ],
    );
  }

  Future<void> _saveStyle(int style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('albumArtStyle', style);
  }

  Future<void> _saveNightBg(String path, {bool isFile = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nightBgPath', path);
    await prefs.setBool('nightBgIsFile', isFile);
    await prefs.setBool('showNightPicker', false);
  }

  void _toggleNightFav(String path) {
    setState(() {
      if (_nightFavPaths.contains(path)) {
        _nightFavPaths.remove(path);
      } else {
        _nightFavPaths.add(path);
      }
    });
    SharedPreferences.getInstance()
        .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
  }

  void _showGalleryFavManager(BuildContext context) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final myPhotos = _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A251D),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('내 사진 관리',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 20, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (myPhotos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('아직 등록한 내 사진이 없어요',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: myPhotos.map((path) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(File(path), width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                        setState(() {
                                          _nightFavPaths.remove(path);
                                          // 지금 배경으로 쓰는 사진을 지웠으면 바로 다른 사진으로 바꾼다
                                          if (_nightBgPath == path) {
                                            final next = _nightFavPaths.isNotEmpty
                                                ? _nightFavPaths.first
                                                : 'assets/spring_photo1.png';
                                            _nightBgPath = next;
                                            _nightBgIsFile = !next.startsWith('assets/');
                                            _saveNightBg(next, isFile: _nightBgIsFile);
                                          }
                                        });
                                        setSheetState(() {});
                                        SharedPreferences.getInstance().then(
                                                (p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 13, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _pickFromGallery() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !mounted) return;
    for (final file in picked) {
      _nightFavPaths.add(file.path);
    }
    SharedPreferences.getInstance()
        .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
    final first = picked.first.path;
    setState(() {
      _nightBgPath = first;
      _nightBgIsFile = true;
      _showNightPicker = false;
      _nightSelectedCategory = null;
    });
    _saveNightBg(first, isFile: true);
  }

  Future<void> _extractColor(Song song) async {
    if (!mounted) return; // 화면이 닫혔으면 안 함
    if (song.albumArt == null) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      setState(() => _dominantColor = Color.fromRGBO(
        (primaryColor.red * 0.7).toInt().clamp(60, 255),
        (primaryColor.green * 0.7).toInt().clamp(60, 255),
        (primaryColor.blue * 0.7).toInt().clamp(60, 255),
        1,
      ));
      return;
    }
    try {
      final codec = await instantiateImageCodec(
        Uint8List.fromList(song.albumArt!),
        targetWidth: 20,
        targetHeight: 20,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData();
      if (!mounted) return; // 계산하는 동안 화면이 닫혔으면 그만
      if (byteData != null) {
        int totalR = 0, totalG = 0, totalB = 0;
        int pixelCount = 0;
        for (int i = 0; i < byteData.lengthInBytes; i += 4) {
          totalR += byteData.getUint8(i);
          totalG += byteData.getUint8(i + 1);
          totalB += byteData.getUint8(i + 2);
          pixelCount++;
        }
        if (pixelCount > 0) {
          final r = (totalR / pixelCount).toInt();
          final g = (totalG / pixelCount).toInt();
          final b = (totalB / pixelCount).toInt();
          final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
          if (brightness < 30) {
            setState(() => _dominantColor = const Color(0xFF3D3D5C));
          } else {
            setState(() {
              _dominantColor = Color.fromRGBO(
                (r * 0.5).toInt(),
                (g * 0.5).toInt(),
                (b * 0.5).toInt(),
                1,
              );
            });
          }
        }
      }
    } catch (e) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      setState(() => _dominantColor = Color.fromRGBO(
        (primaryColor.red * 0.4).toInt(),
        (primaryColor.green * 0.4).toInt(),
        (primaryColor.blue * 0.4).toInt(),
        1,
      ));
    }
  }

  void _startEqAnimations() {
    final durations = [1400, 1200, 1600, 1250, 1750, 1150, 1700, 1350, 1550, 1220, 1480];
    final delays = [0, 150, 300, 80, 220, 0, 260, 120, 340, 60, 180];
    _eqControllers = List.generate(11, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[i]),
      );
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
    _eqAnimations = List.generate(11, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _eqControllers[i], curve: Curves.easeInOutSine),
      );
    });
  }

  @override
  void dispose() {
    _autoBgTimer?.cancel();
    _tvArtTimer?.cancel();
    _suggestTimer?.cancel();
    CastService.instance.cardArt = null; // 재생화면이 없으면 카드를 못 찍으니 앨범 사진으로
    _rotationController.dispose();
    _equalizerController.dispose();
    for (final c in _eqControllers) c.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final song = playerProvider.currentSong;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (song == null) {
      final baseColorEmpty = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('No song is playing',
              style: TextStyle(color: baseColorEmpty.withOpacity(0.6))),
        ),
      );
    }

    // (TV로 보내기·TV 재생/일시정지는 player_provider가 알아서 처리)
    _syncTvArt(); // 파란포토면 보이는 사진 그대로 TV에

    final lyricsProvider = context.read<LyricsProvider>();
    final currentKey = '${song.titleDisplay}-${song.artistDisplay}';
    if (lyricsProvider.currentSongKey != currentKey) {
      lyricsProvider.clearLyrics();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lyricsProvider.fetchLyrics(
          song.titleDisplay,
          song.artistDisplay,
          filePath: song.uri,
        );
      });
    }

    // 파란포토는 "진짜 다른 곡"일 때만 바꿈 (곡 정보 편집으로는 안 바뀜)
    // 설정을 다 불러온 뒤에만 "곡이 바뀌었나" 검사 (먼저 하면 파란포토인 줄 모르고 넘어감)
    if (_styleLoaded && _lastBgSongUri != song.uri) {
      final isFirst = _lastBgSongUri == null;
      _lastBgSongUri = song.uri;
      if (!isFirst && _albumArtStyle == 6) {
        // 하트한 사진이 2장 이상이면 그중에서, 아니면 지금 사진과 같은 카테고리에서
        final List<String> options = (_nightFavPaths.length >= 2
                ? _nightFavPaths.toList()
                : _nightCategoryPhotos.values
                    .firstWhere((l) => l.contains(_nightBgPath), orElse: () => const [])
                    .toList())
          ..remove(_nightBgPath);
        if (options.isNotEmpty) {
          final next = options[math.Random().nextInt(options.length)];
          final nextIsFile = !next.startsWith('assets/');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _nightBgPath = next;
              _nightBgIsFile = nextIsFile;
            });
            _saveNightBg(next, isFile: nextIsFile);
          });
        }
      }
    }

    if (playerProvider.isPlaying) {
      _rotationController.repeat();
      _equalizerController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _equalizerController.stop();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -300) {
          playerProvider.playNext();
        } else if (details.primaryVelocity! > 300) {
          playerProvider.playPrevious();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.45),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomBarItem(
                          context,
                          icon: null,
                          customIcon: '<path d="M18 4L22 8L18 12" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 6H5.5C7 6 8 6.7 9 8L11 11" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 20L22 16L18 12" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 18H5.5C7 18 8 17.3 9 16L15 8C16 6.7 17 6 18.5 6H22" stroke-linecap="round" stroke-linejoin="round"/>',
                          label: AppLocalizations.of(context)!.shuffle,
                          isActive: playerProvider.isShuffled,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.toggleShuffle();
                          },
                        ),
                        _buildBottomBarItem(
                          context,
                          icon: playerProvider.loopMode == LoopMode.one
                              ? null
                              : null,
                          customIcon: playerProvider.loopMode == LoopMode.one
                              ? '<path d="M17 2L21 6L17 10" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11V9C3 7.3 4.3 6 6 6H21" stroke-linecap="round" stroke-linejoin="round"/><path d="M7 22L3 18L7 14" stroke-linecap="round" stroke-linejoin="round"/><path d="M21 13V15C21 16.7 19.7 18 18 18H3" stroke-linecap="round" stroke-linejoin="round"/><path d="M11 10V14M13 10L11 10V14L13 14" stroke-linecap="round" stroke-linejoin="round"/>'
                              : '<path d="M17 2L21 6L17 10" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11V9C3 7.3 4.3 6 6 6H21" stroke-linecap="round" stroke-linejoin="round"/><path d="M7 22L3 18L7 14" stroke-linecap="round" stroke-linejoin="round"/><path d="M21 13V15C21 16.7 19.7 18 18 18H3" stroke-linecap="round" stroke-linejoin="round"/>',
                          label: '반복',
                          isActive: playerProvider.loopMode != LoopMode.off,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.toggleLoopMode();
                          },
                        ),
                        _buildBottomBarItem(
                          context,
                          icon: Icons.nightlight_round,
                          label: '수면',
                          isActive: playerProvider.isSleepTimerActive,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            if (playerProvider.isSleepTimerActive) {
                              _showSleepTimerDialog(context, playerProvider, primaryColor);
                            } else {
                              _showSleepWheelPickerDirect(context, playerProvider, primaryColor);
                            }
                          },
                        ),
                        ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.white.withOpacity(0.12),
                  ),
                  GestureDetector(
                    onTap: () => _showExitConfirmDialog(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.power_settings_new, color: Color(0xFFE8877E), size: 22),
                          const SizedBox(height: 4),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // 앨범아트 블러 배경
            SizedBox.expand(
              child: _albumArtStyle == 6
                  ? RepaintBoundary(key: _paranKey, child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1200),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('$_nightBgPath-$_bgFilter-$_printStyle'),
                        child: _bgFiltered(_nightBgIsFile
                            ? Image.file(File(_nightBgPath), fit: BoxFit.cover)
                            : paranPhoto(_nightBgPath, fit: BoxFit.cover)),
                      ),
                    ))
                  : ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: song.albumArt != null
                    ? Image.memory(
                  Uint8List.fromList(song.albumArt!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
                    : Image.asset(
                  noAlbumImagePath(song.uri ?? song.title),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox.expand(
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            // 상단 페이드
            Positioned(
              top: 0, left: 0, right: 0, height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 하단 페이드
            Positioned(
              bottom: 0, left: 0, right: 0, height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            // 왼쪽 페이드
            Positioned(
              top: 0, bottom: 0, left: 0, width: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 오른쪽 페이드
            Positioned(
              top: 0, bottom: 0, right: 0, width: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 62),
                child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: constraints.maxHeight < 600
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildTopBar(context, playerProvider, primaryColor),
                            constraints.maxHeight < 600
                                ? SizedBox(
                              height: constraints.maxHeight * 0.35,
                              child: _buildAlbumArt(song, primaryColor),
                            )
                                : Expanded(
                              flex: 5,
                              child: _buildAlbumArt(song, primaryColor),
                            ),
                            _buildEqualizer(playerProvider, primaryColor),
                            _buildCurrentLyrics(playerProvider, primaryColor),
                            constraints.maxHeight < 600
                                ? _buildControls(
                                context, playerProvider, musicProvider, song, primaryColor)
                                : Expanded(
                              flex: 4,
                              child: _buildControls(
                                  context, playerProvider, musicProvider, song, primaryColor),
                            ),

                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 재생 버튼 아래: TV로 듣기 / OO에서 재생 중
  Widget _buildCastBar(Song song, PlayerProvider playerProvider) {
    return AnimatedBuilder(
      animation: CastService.instance,
      builder: (context, _) {
        final cast = CastService.instance;
        final label = cast.isConnected ? '${cast.device!.name}에서 재생 중' : 'TV로 듣기';
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              if (cast.isConnected) {
                _showCastControl();
              } else {
                _showCastPicker(song, playerProvider);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cast.isConnected ? const Color(0xFF2589E8).withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cast.isConnected ? Icons.cast_connected : Icons.cast,
                      color: Colors.white.withOpacity(0.85), size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 같은 와이파이의 TV 찾아서 고르기
  void _showCastPicker(Song song, PlayerProvider playerProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Future<List<CastDevice>> search = CastService.instance.discover();
        return StatefulBuilder(builder: (ctx, setSheet) {
          return SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: FutureBuilder<List<CastDevice>>(
                future: search,
                builder: (ctx, snap) {
                  final title = Row(
                    children: [
                      const Icon(Icons.cast, color: Color(0xFF2589E8), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('TV로 듣기',
                            style: TextStyle(color: Color(0xFF17140F), fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.black45),
                      ),
                    ],
                  );
                  if (snap.connectionState != ConnectionState.done) {
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      title,
                      const SizedBox(height: 18),
                      const CircularProgressIndicator(color: Color(0xFF2589E8)),
                      const SizedBox(height: 12),
                      const Text('같은 와이파이에 있는 TV를 찾고 있어요',
                          style: TextStyle(color: Color(0xFF8A857B), fontSize: 13)),
                      const SizedBox(height: 18),
                    ]);
                  }
                  final devices = snap.data ?? [];
                  if (devices.isEmpty) {
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      title,
                      const SizedBox(height: 14),
                      const Text('TV를 못 찾았어요.\nTV가 켜져 있고 폰과 같은 와이파이인지 확인해 주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF5A5348), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setSheet(() => search = CastService.instance.discover()),
                        child: const Text('다시 찾기', style: TextStyle(color: Color(0xFF2589E8))),
                      ),
                    ]);
                  }
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    title,
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Column(children: [
                        for (final d in devices)
                          ListTile(
                            leading: const Icon(Icons.tv, color: Color(0xFF2589E8)),
                            title: Text(d.name, style: const TextStyle(color: Color(0xFF17140F))),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final cast = CastService.instance;
                              cast.onTrackEnded = () => playerProvider.playNext(); // TV에서 곡 끝나면 다음 곡
                              final ok = await cast.connect(d, song);
                              if (ok) {
                                playerProvider.player.pause();
                              } else if (mounted) {
                                showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);
                              }
                            },
                          ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                  ]);
                },
              ),
            ),
          );
        });
      },
    );
  }

  /// TV로 듣는 중: 일시정지 / 연결 끊기
  void _showCastControl() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: CastService.instance,
        builder: (ctx, _) {
          final cast = CastService.instance;
          return SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cast_connected, color: Color(0xFF2589E8), size: 30),
                  const SizedBox(height: 8),
                  Text(cast.device?.name ?? 'TV',
                      style: const TextStyle(color: Color(0xFF17140F), fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지',
                      style: const TextStyle(color: Color(0xFF8A857B), fontSize: 12.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => cast.tvPlaying ? cast.pause() : cast.play(),
                          icon: Icon(cast.tvPlaying ? Icons.pause : Icons.play_arrow),
                          label: Text(cast.tvPlaying ? '일시정지' : '재생'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2589E8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await cast.disconnect();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5A5348),
                            side: const BorderSide(color: Color(0xFFE2DACB)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('연결 끊기'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    final song = playerProvider.currentSong;
    const baseColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.pop(context);
            },
            icon: Icon(Icons.keyboard_arrow_down,
                color: baseColor, size: 30),
          ),
          const SizedBox(width: 40), // 오른쪽 TV 버튼 폭만큼 비워서 가운데 워터마크 정렬 유지
          Expanded(
            child: Center(
              // "재생 중" 대신 파란소리 워터마크 (홈 로고 스타일, 이퀄라이저 없이)
              child: Builder(builder: (context) {
                final isKo = Localizations.localeOf(context).languageCode == 'ko';
                const sky = Color(0xFF7FB8F0); // 사진 위에서 잘 보이는 밝은 파란색
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "파란"만 숨쉬기 (재생 중일 때만)
                        _BreathingText(
                          text: 'Paran',
                          style: GoogleFonts.quicksand(
    color: sky.withOpacity(0.8), fontSize: 21, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.3),
                          moving: playerProvider.isPlaying,
                        ),
                        Text(
                          isKo ? 'sori' : 'Sori', // 한국은 Paransori, 해외는 발음 때문에 ParanSori
                          style: GoogleFonts.quicksand(
                              color: baseColor.withOpacity(0.42), fontSize: 21, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                    if (false) ...[ // 아래 작은 영문 줄은 이제 안 씀 (위에 영어로 나와서)
                      const SizedBox(height: 4),
                      Text(
                        'Paransori',
                        style: TextStyle(
                          color: baseColor.withOpacity(0.45),
                          fontSize: 9.5,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ),
          // TV로 듣기 (연결되면 하늘색 아이콘)
          AnimatedBuilder(
            animation: CastService.instance,
            builder: (context, _) {
              final cast = CastService.instance;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  if (song == null) return;
                  if (cast.isConnected) {
                    _showCastControl();
                  } else {
                    _showCastPicker(song, playerProvider);
                  }
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    cast.isConnected ? Icons.cast_connected : Icons.cast,
                    color: cast.isConnected ? const Color(0xFF7FB8F0) : baseColor,
                    size: 22,
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => _showPlayerOptionsSheet(context, song, primaryColor),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              // 왼쪽 ⌄ 버튼과 폭을 똑같이(48) 맞춰서 가운데 워터마크가 화면 정중앙에 오게
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.more_vert, color: baseColor),
                  if (!_hasSeenParanPhoto)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerOptionsSheet(BuildContext context, Song? song, Color primaryColor) {
    if (song == null) return;
    final playerProvider = context.read<PlayerProvider>();
    // 다크 모드면 메뉴도 어둡게 (음악 목록 메뉴와 같은 색)
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final sheetColor = isDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
    final baseColor = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF1A1A1A);
    final descColor = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    const accent = Color(0xFF2589E8); // 파란소리 포인트 블루 (메뉴 아이콘 통일)

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        // 메뉴를 안 닫고 여러 개 바꿀 수 있게: 값이 바뀌면 메뉴가 바로 다시 그려짐
        return StatefulBuilder(builder: (ctx, setSheet) {
        final playerProvider = ctx.watch<PlayerProvider>();
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close, size: 24, color: baseColor.withOpacity(0.45)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 곡 정보 + 빠른 버튼 (즐겨찾기 · 재생목록 · 공유 · 편집)
                  Builder(builder: (_) {
                    final music = ctx.watch<MusicProvider>();
                    final fav = music.isFavorite(song.id);
                    return MenuSongCard(
                      isDark: isDark,
                      song: song,
                      actions: [
                        MenuQuickAction(fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, '즐겨찾기', () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          music.toggleFavorite(song);
                        }),
                        MenuQuickAction(Icons.playlist_add, '재생목록', () {
                          _showAddToPlaylistDialog(context, song, primaryColor);
                        }),
                        // 공유·편집: 메뉴는 그대로 두고 위에 띄움 → 돌아오면 메뉴가 그대로
                        MenuQuickAction(Icons.share, '공유', () async {
                          if (song.uri != null) {
                            await Share.shareXFiles([XFile(song.uri!)], text: song.titleDisplay);
                          }
                        }),
                        MenuQuickAction(Icons.edit, '편집', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditSongScreen(song: song)));
                        }),
                      ],
                    );
                  }),
                  MenuCard(isDark: isDark, children: [
                  _playerSheetItem(
                    ctx,
                    Icons.shuffle_rounded,
                    AppLocalizations.of(context)!.shuffle,
                    accent,
                    baseColor,
                        () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      playerProvider.toggleShuffle();
                    },
                    trailing: _sheetMiniSwitch(playerProvider.isShuffled),
                  ),
                  _playerSheetItem(
                    ctx,
                    Icons.repeat_rounded,
                    '반복',
                    accent,
                    baseColor,
                        () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      playerProvider.toggleLoopMode();
                    },
                    trailing: _sheetRepeatChips(playerProvider),
                    trailingTappable: true,
                  ),
                  _playerSheetItem(
                    ctx,
                    Icons.nightlight_round,
                    '수면',
                    accent,
                    baseColor,
                        () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (playerProvider.isSleepTimerActive) {
                        _showSleepTimerDialog(context, playerProvider, primaryColor);
                      } else {
                        _showSleepWheelPickerDirect(context, playerProvider, primaryColor);
                      }
                    },
                    trailing: _sheetValue(_sheetSleepLabel(playerProvider)),
                    arrow: true,
                  ),
                  ]),
                  MenuCard(isDark: isDark, children: [
                  _playerSheetItem(ctx, Icons.style, AppLocalizations.of(context)!.playerStyle, accent, baseColor, () async {
                    if (!_hasSeenParanPhoto) {
                      setState(() => _hasSeenParanPhoto = true);
                      SharedPreferences.getInstance().then((p) => p.setBool('hasSeenParanPhoto', true));
                    }
                    await _showStyleDialog(context, primaryColor);
                    // 고르고 돌아오면 메뉴의 스타일 썸네일도 바로 바뀌게
                    if (ctx.mounted) setSheet(() {});
                  }, trailing: _sheetStyleThumbs(song)),
                  _playerSheetItem(ctx, Icons.speed, '배속', accent, baseColor, () {
                    _showSpeedDialog(context, context.read<PlayerProvider>(), primaryColor);
                  }, trailing: _sheetValue(_sheetSpeedLabel(playerProvider.playbackSpeed)), arrow: true),
                  _playerSheetItem(ctx, Icons.lyrics_outlined, AppLocalizations.of(context)!.lyrics, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LyricsScreen()));
                  }, arrow: true),
                  // 🌿 자연소리 섞기 (음악 위에 빗소리·파도 등을 깔기)
                  AnimatedBuilder(
                    animation: NatureOverlay.instance,
                    builder: (_, __) => _playerSheetItem(
                      ctx,
                      Icons.forest_outlined,
                      '자연소리 섞기',
                      accent,
                      baseColor,
                      () {
                        showNatureOverlaySheet(context);
                      },
                      trailing: _sheetValue(NatureOverlay.instance.summary),
                      arrow: true,
                    ),
                  ),
                  ]),
                  MenuCard(isDark: isDark, children: [
                  // 들어갔다 나오면 메뉴가 그대로 있게 (메뉴를 닫지 않고 위에 띄움)
                  _playerSheetItem(ctx, Icons.music_note, AppLocalizations.of(context)!.setRingtone, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RingtoneScreen(initialSong: song)));
                  }, arrow: true),
                  _playerSheetItem(ctx, Icons.content_cut, '자르기', accent, baseColor, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => RingtoneScreen(initialSong: song, trimMode: true)));
                  }, arrow: true),
                  _playerSheetItem(ctx, Icons.info_outline, AppLocalizations.of(context)!.songInfo, accent, baseColor, () {
                    SongListTile.showInfo(context, song);
                  }, arrow: true),
                  _playerSheetItem(ctx, Icons.equalizer, AppLocalizations.of(context)!.equalizer, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EqualizerScreen()));
                  }, arrow: true),
                  ]),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
        });
      },
    );
  }

  static Widget _playerSheetItem(BuildContext context, IconData icon, String label, Color iconColor, Color textColor, VoidCallback onTap,
      {bool showNew = false, Widget? trailing, bool arrow = false, bool trailingTappable = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        child: Row(
          children: [
            // 카드 안 줄: 아이콘 배경 없이 파란 아이콘만
            SizedBox(width: 24, child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                  if (showNew) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 오른쪽: 지금 상태 표시 (보여주기만, 누르면 줄 전체 동작 그대로)
            if (trailing != null) trailingTappable ? trailing : IgnorePointer(child: trailing),
            if (arrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 20, color: textColor.withOpacity(0.3)),
            ],
          ],
        ),
      ),
    );
  }

  // ── 더보기 메뉴 오른쪽 상태 표시용 ──
  static const _sheetBlue = Color(0xFF2589E8);
  static const _sheetSub = Color(0xFF8A8378);

  static Widget _sheetValue(String text) => Text(text,
      style: const TextStyle(color: _sheetSub, fontSize: 12.5, fontWeight: FontWeight.w500));

  static String _sheetSleepLabel(PlayerProvider p) {
    final end = p.sleepTimerEnd;
    if (!p.isSleepTimerActive || end == null) return '꺼짐';
    final secs = end.difference(DateTime.now()).inSeconds;
    final m = (secs / 60).ceil().clamp(1, 100000);
    if (m < 60) return '$m분 후 중지';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h시간 후 중지' : '$h시간 $r분 후 중지';
  }

  static String _sheetSpeedLabel(double speed) {
    var t = speed.toStringAsFixed(2);
    if (t.endsWith('0')) t = t.substring(0, t.length - 1); // 1.00 → 1.0, 1.50 → 1.5
    return '$t×';
  }

  static Widget _sheetMiniSwitch(bool on) {
    return Container(
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(2),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? _sheetBlue : Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  static Widget _sheetRepeatChips(PlayerProvider p) {
    final mode = p.loopMode;
    // 원하는 상태가 될 때까지 기존 반복 기능을 그대로 넘김 (로직 그대로)
    void setTo(LoopMode target) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      for (var i = 0; i < 3 && p.loopMode != target; i++) {
        p.toggleLoopMode();
      }
    }

    Widget chip(String label, LoopMode m) {
      final sel = mode == m;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setTo(m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: sel ? _sheetBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: TextStyle(
                color: sel ? Colors.white : _sheetSub,
                fontSize: 11.5,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('꺼짐', LoopMode.off),
          chip('한 곡', LoopMode.one),
          chip('전체', LoopMode.all),
        ],
      ),
    );
  }

  Widget _sheetStyleThumbs(Song song) =>
      _styleThumbs(song, _albumArtStyle, _nightBgPath, _nightBgIsFile,
          showNew: !_hasSeenParanPhoto);

  /// 재생화면 스타일 썸네일 3개 (재생화면 메뉴 · 곡 목록 메뉴 같이 씀)
  static Widget _styleThumbs(Song song, int style, String bgPath, bool bgIsFile,
      {bool showNew = false}) {
    Widget box(int id, String label, Widget img, {bool isNew = false}) {
      final sel = style == id;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: sel ? _sheetBlue : Colors.transparent, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: img,
                  ),
                ),
                if (isNew)
                  Positioned(
                    left: -4,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Text('NEW',
                          style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (sel)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _sheetBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: sel ? _sheetBlue : _sheetSub,
                  fontSize: 9.5,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      );
    }

    // 시디롬: 작은 CD 그림
    final cd = Container(
      color: const Color(0xFFEDF4F8),
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [
            Color(0xFFD5DAE1), Colors.white, Color(0xFFC6CCD5), Colors.white, Color(0xFFD5DAE1),
          ]),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF4F8),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFB8BEC8)),
          ),
        ),
      ),
    );
    // 파란포토: 지금 고른 사진
    final photo = bgIsFile
        ? Image.file(File(bgPath), fit: BoxFit.cover)
        : paranPhoto(bgPath, thumb: true, fit: BoxFit.cover);
    // 앨범: 지금 곡 앨범아트
    final album = song.albumArt != null
        ? Image.memory(Uint8List.fromList(song.albumArt!), fit: BoxFit.cover, gaplessPlayback: true)
        : Image.asset(noAlbumImagePath(song.uri ?? song.title), fit: BoxFit.cover);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        box(1, '시디롬', cd),
        box(6, '파란포토', photo, isNew: showNew),
        box(3, '앨범', album),
      ],
    );
  }
  Widget _buildAlbumArt(Song song, Color primaryColor) {
    switch (_albumArtStyle) {
      case 3: return _withParanSuggest(_buildCardStyle(song, primaryColor));
      case 6: return _buildNightPhotoArea(song);
      default: return _withParanSuggest(_buildCDStyle(song, primaryColor));
    }
  }

  /// "잔잔한 파도와 함께" (누르면 자연소리 섞기 창, 안 켜져 있으면 안 보임)
  /// withLine: 파란포토 박스 안처럼 위에 가는 선으로 나누기
  Widget _natureBadge(EdgeInsets padding, {bool withLine = false}) {
    return AnimatedBuilder(
      animation: NatureOverlay.instance,
      builder: (_, __) {
        final o = NatureOverlay.instance;
        if (!o.anyOn) return const SizedBox.shrink();
        return Padding(
          padding: padding,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              showNatureOverlaySheet(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (withLine)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.fromLTRB(30, 10, 30, 8),
                    color: Colors.white.withOpacity(0.12),
                  ),
                Text(o.withLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 11.5, letterSpacing: 0.3)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNightPhotoArea(Song song) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
          Container(
            width: MediaQuery.of(context).size.width - 90,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  song.titleDisplay,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artistDisplay,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
                // 자연소리 같이 듣는 중이면 가는 선 아래에 표시
                _natureBadge(const EdgeInsets.only(top: 0), withLine: true),
              ],
            ),
          ),
            ],
          ),
        ),
        // 사진 고르기를 제일 위에 (제목 박스에 가려서 안 눌리는 것 방지)
        _buildNightBgPicker(),
      ],
    );
  }
  Widget _buildNightBgPicker() {

    if (!_showNightPicker) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() => _showNightPicker = true);
              SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', true));
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Icon(Icons.photo_outlined, color: Colors.white, size: 18),
            ),
          ),
        ),
      );
    }

    // 2단계: 카테고리를 아직 안 골랐으면 카테고리 목록을 보여준다.
    if (_nightSelectedCategory == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _nightCategoryCover.length + 4,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      setState(() => _nightSelectedCategory = '전체');
                    },
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('전체보기', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == _nightCategoryCover.length + 1) {
                  return GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('내 사진', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == _nightCategoryCover.length + 2) {
                  return GestureDetector(
                    onTap: () => _showGalleryFavManager(context),
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('관리', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == _nightCategoryCover.length + 3) {
                  return GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      setState(() => _showNightPicker = false);
                      SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', false));
                    },
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('닫기', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                final category = _nightCategoryCover.keys.elementAt(index - 1);
                final cover = _nightCategoryCover[category]!;
                return GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    setState(() => _nightSelectedCategory = category);
                  },
                  child: Container(
                    width: 60,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: paranPhoto(
                            cover,
                            thumb: true,
                            width: 60,
                            height: 74,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(11),
                                bottomRight: Radius.circular(11),
                              ),
                            ),
                            child: Text(
                              category,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // 3단계: 고른 카테고리 안의 사진들을 보여준다.
    final photos = _nightSelectedCategory == '전체'
        ? _nightCategoryPhotos.values.expand((e) => e).toList()
        : (_nightCategoryPhotos[_nightSelectedCategory] ?? []);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        SizedBox(
          height: 64,
          child: photos.isEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        setState(() => _nightSelectedCategory = null);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.35),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '준비중입니다',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20, right: 10),
                  itemCount: _nightSelectedCategory == '전체' ? photos.length + 4 : photos.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() => _nightSelectedCategory = null);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                        ),
                      );
                    }
                    if (_nightSelectedCategory == '전체' && index == 1) {
                      final allSelected = photos.every((p) => _nightFavPaths.contains(p));
                      return GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() {
                            if (allSelected) {
                              _nightFavPaths.removeAll(photos);
                            } else {
                              _nightFavPaths.addAll(photos);
                            }
                          });
                          SharedPreferences.getInstance()
                              .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: allSelected ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: allSelected ? Colors.black : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '전체 선택',
                                style: TextStyle(
                                  color: allSelected ? Colors.black : Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // 전체보기에서도 "내 사진" 추가 · "관리" (전체 선택 버튼과 같은 모양)
                    if (_nightSelectedCategory == '전체' && (index == 2 || index == 3)) {
                      final isAdd = index == 2;
                      return GestureDetector(
                        onTap: isAdd ? _pickFromGallery : () => _showGalleryFavManager(context),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isAdd ? Icons.add_photo_alternate_outlined : Icons.tune_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(height: 4),
                              Text(isAdd ? '내 사진' : '관리',
                                  style: const TextStyle(color: Colors.white, fontSize: 9)),
                            ],
                          ),
                        ),
                      );
                    }
                    final photoIndex = _nightSelectedCategory == '전체' ? index - 4 : index - 1;

                    final path = photos[photoIndex];
                    final isFav = _nightFavPaths.contains(path);
                    return GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        _toggleNightFav(path);
                        setState(() {
                          _nightBgPath = path;
                          _nightBgIsFile = false;
                        });
                        _saveNightBg(path);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFav ? Colors.white : Colors.white.withOpacity(0.25),
                            width: isFav ? 2.5 : 1,
                          ),
                          boxShadow: isFav
                              ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: paranPhoto(path, fit: BoxFit.cover, thumb: true),
                        ),
                      ),
                    );
                  },
                ),
                    ),
                    GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        setState(() {
                          _showNightPicker = false;
                          _nightSelectedCategory = null;
                        });
                        SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', false));
                      },
                      child: Container(
                        width: 56,
                        height: 56, // 옆 버튼들과 같은 크기
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.35),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 20),
                            SizedBox(height: 4),
                            Text('닫기', style: TextStyle(color: Colors.white, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
        ),
            const SizedBox(height: 10),
            _buildPhotoOptions(),
          ],
        ),
      ),
    );
  }
  Widget _buildCDStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _dominantColor.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: song.albumArt != null
                        ? SizedBox.expand(
                      child: Image.memory(
                        Uint8List.fromList(song.albumArt!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                        : SizedBox.expand(
                      child: Image.asset(
                        noAlbumImagePath(song.title),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // 중앙 구멍
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.2, -0.2),
                        colors: [
                          Colors.grey.shade400.withOpacity(0.5),
                          Colors.grey.shade600.withOpacity(0.4),
                          Colors.grey.shade800.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.grey.shade500.withOpacity(0.15),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAlbumGradient(Song song) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hash = (song.title + song.artist).codeUnits.fold(0, (a, b) => a + b);
    // 곡마다 조금씩 다른 각도와 밝기
    final angles = [
      [Alignment.topLeft, Alignment.bottomRight],
      [Alignment.topRight, Alignment.bottomLeft],
      [Alignment.topCenter, Alignment.bottomCenter],
      [Alignment.centerLeft, Alignment.centerRight],
    ];
    final brightFactors = [0.9, 0.75, 0.6, 0.8, 0.7];
    final darkFactors = [0.3, 0.2, 0.4, 0.25, 0.35];
    final ai = hash % angles.length;
    final bi = hash % brightFactors.length;
    final di = (hash ~/ 3) % darkFactors.length;

    final bright = Color.fromRGBO(
      (primaryColor.red + (255 - primaryColor.red) * brightFactors[bi]).toInt().clamp(0, 255),
      (primaryColor.green + (255 - primaryColor.green) * brightFactors[bi]).toInt().clamp(0, 255),
      (primaryColor.blue + (255 - primaryColor.blue) * brightFactors[bi]).toInt().clamp(0, 255),
      1,
    );
    final dark = Color.fromRGBO(
      (primaryColor.red * darkFactors[di]).toInt().clamp(0, 255),
      (primaryColor.green * darkFactors[di]).toInt().clamp(0, 255),
      (primaryColor.blue * darkFactors[di]).toInt().clamp(0, 255),
      1,
    );

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: angles[ai][0],
          end: angles[ai][1],
          colors: [bright, primaryColor, dark],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildCassetteStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 릴 2개
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGlassReel(song: song),
                    const SizedBox(width: 48),
                    _buildGlassReel(song: song),
                  ],
                ),
                const SizedBox(height: 12),
                // 테이프 라인
                Container(
                  width: 100,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 곡명
                Text(
                  song.titleDisplay,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassReel({Song? song}) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 앨범아트 배경
                  if (song?.albumArt != null)
                    Image.memory(
                      Uint8List.fromList(song!.albumArt!),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    Container(
                      color: Colors.white.withOpacity(0.04),
                    ),
                  // 어둡게 오버레이
                  Container(
                    color: Colors.black.withOpacity(0.35),
                  ),
                  // 중앙 구멍
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141414),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReel(Color primaryColor, Song song) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A2A),
              border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(6, (i) {
                  return Transform.rotate(
                    angle: i * 3.14159 / 3,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: primaryColor.withOpacity(0.4),
                    ),
                  );
                }),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardStyle(Song song, Color primaryColor) {
    final albumPhoto = song.albumArt != null
        ? Image.memory(Uint8List.fromList(song.albumArt!), fit: BoxFit.cover, gaplessPlayback: true)
        : Image.asset(noAlbumImagePath(song.uri ?? song.title), fit: BoxFit.cover);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            final scale = _rotationController.isAnimating ? 1.03 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          // 인화 모양을 골랐으면 인화 사진 카드, 아니면 기본 카드
          child: _printStyle != 0
              ? RepaintBoundary(
                  key: _cardKey,
                  child: FractionallySizedBox(widthFactor: 0.88, child: _printCard(albumPhoto)),
                )
              : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: song.albumArt != null
                    ? Image.memory(
                  Uint8List.fromList(song.albumArt!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
                    : Image.asset(
                  noAlbumImagePath(song.uri ?? song.title),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizerStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _equalizerController,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadialVisualizerPainter(
                  progress: _equalizerController.value,
                  isPlaying: _rotationController.isAnimating,
                ),
                child: child,
              );
            },
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1a1a1a),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: song.albumArt != null
                    ? ClipOval(
                  child: Image.memory(
                    Uint8List.fromList(song.albumArt!),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                )
                    : const Center(
                  child: Text('♪',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 28)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.8),
                      primaryColor.withOpacity(0.3),
                      AppTheme.background,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (song.albumArt != null)
                        Opacity(
                          opacity: 0.3,
                          child: Image.memory(
                            Uint8List.fromList(song.albumArt!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            gaplessPlayback: true,
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (song.albumArt != null)
                            ClipOval(
                              child: Image.memory(
                                Uint8List.fromList(song.albumArt!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            )
                          else
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.3),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white, size: 60),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            song.titleDisplay,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizer(PlayerProvider playerProvider, Color primaryColor) {
    final isPlaying = playerProvider.isPlaying;
    // 가운데가 제일 높고 양옆으로 낮아지는 산 모양
    final minHeights = [4.0, 4.0, 5.0, 7.0, 9.0, 11.0, 9.0, 7.0, 5.0, 4.0, 4.0];
    final maxHeights = [5.0, 9.0, 14.0, 20.0, 26.0, 32.0, 26.0, 20.0, 14.0, 9.0, 5.0];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(11, (i) {
            return AnimatedBuilder(
              animation: _eqAnimations[i],
              builder: (context, child) {
                // 정지 중이면 움직이지 않고 가장 낮은 모양으로 멈춰 있음
                final value = isPlaying ? _eqAnimations[i].value : 0.0;
                final height = minHeights[i] +
                    (maxHeights[i] - minHeights[i]) * value;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentLyrics(PlayerProvider playerProvider, Color primaryColor) {
    final lyricsProvider = context.watch<LyricsProvider>();
    if (!lyricsProvider.hasLyrics || lyricsProvider.lyrics.isEmpty) {
      return const SizedBox(height: 36);
    }
    lyricsProvider.updateCurrentLine(playerProvider.position);
    final currentLine = lyricsProvider.lyrics[lyricsProvider.currentLineIndex];
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          currentLine.text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerProvider playerProvider,
      MusicProvider musicProvider, Song song, Color primaryColor) {
    final isFav = musicProvider.isFavorite(song.id);
    const baseColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.titleDisplay,
                        style: TextStyle(
                            color: baseColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 0),
                    Text(song.artistDisplay,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.7), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    // 🌿 자연소리 섞는 중 (파란포토는 가운데 박스에 나오니까 여기선 빼기)
                    if (_albumArtStyle != 6) _natureBadge(const EdgeInsets.only(top: 6)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  musicProvider.toggleFavorite(song);
                  // (하트가 바로 바뀌어서 따로 알림 없음)
                },
                icon: Icon(
                  isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isFav ? Colors.redAccent : baseColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            // 잡고 있을 때만 1.4배 (6 → 8.4), 놓으면 부드럽게 돌아옴
            tween: Tween(end: _isSeeking ? 8.4 : 6.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, thumbRadius, _) => SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: Colors.white.withOpacity(0.85),
              inactiveTrackColor: Colors.white.withOpacity(0.28),
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
              thumbShape: _GlowThumbShape(radius: thumbRadius),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: playerProvider.progress,
              onChangeStart: (_) => setState(() => _isSeeking = true),
              onChangeEnd: (_) => setState(() => _isSeeking = false),
              onChanged: (value) {
                final position = Duration(
                  milliseconds:
                  (value * playerProvider.duration.inMilliseconds).toInt(),
                );
                playerProvider.seekTo(position);
              },
            ),
          ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(playerProvider.formatDuration(playerProvider.position),
                  style: TextStyle(
                      color: baseColor.withOpacity(0.7), fontSize: 12)),
              Text(playerProvider.formatDuration(playerProvider.duration),
                  style: TextStyle(
                      color: baseColor.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  playerProvider.playPrevious();
                },
                icon: const Icon(Icons.skip_previous),
                color: baseColor,
                iconSize: 36,
              ),
              GestureDetector(
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  playerProvider.togglePlayPause();
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: playerProvider.isLoading
                      ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: baseColor),
                  )
                      : Icon(
                    playerProvider.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: baseColor,
                    size: 36,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  playerProvider.playNext();
                },
                icon: const Icon(Icons.skip_next),
                color: baseColor,
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song, Color primaryColor) {
    final playlistProvider = context.read<PlaylistProvider>();
    const accent = AppTheme.fixedAccent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.addToPlaylist,
            style: const TextStyle(color: Colors.black)),
        content: playlistProvider.playlists.isEmpty
            ? Text(AppLocalizations.of(context)!.noPlaylists,
            style: const TextStyle(color: Colors.black54))
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play, color: accent),
                title: Text(playlist.name,
                    style: const TextStyle(color: Colors.black)),
                subtitle: Text('${playlist.songCount} songs',
                    style: const TextStyle(color: Colors.black54)),
                onTap: () {
                  playlistProvider.addSongToPlaylist(playlist.id, song);
                  Navigator.pop(ctx);
                  showActionFeedback(context, type: ActionFeedbackType.added, message: '재생목록에 추가했어요');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  static void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SleepTimerDialog(playerProvider: playerProvider, primaryColor: AppTheme.fixedAccent),
    );
  }

  static void _showSleepWheelPickerDirect(BuildContext context, PlayerProvider playerProvider, Color _unusedColor) {
    final primaryColor = AppTheme.fixedAccent;
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    Duration picked = const Duration(minutes: 30);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('몇 시간 몇 분 후 정지할까요?',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: textColor, fontSize: 20),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (picked.inMinutes > 0) {
                          playerProvider.setSleepTimer(picked);
                          final timeLabel =
                              '${picked.inHours > 0 ? '${picked.inHours}${AppLocalizations.of(context)!.hourWord} ' : ''}${picked.inMinutes % 60}${AppLocalizations.of(context)!.minuteShort}';
                          showParanToast(context, AppLocalizations.of(context)!.autoStopFormat(timeLabel));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.set,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SpeedDialog(playerProvider: playerProvider, primaryColor: AppTheme.fixedAccent),
    );
  }

  void _showFarewellAndExit(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    late final String smallText;
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        smallText = '파란소리와 함께한 시간,\n즐거우셨나요?\n\n언제든 다시 찾아오시면,\n좋은 소리로 맞아드릴게요.\n안녕히 가세요!';
        farewellAsset = 'assets/farewell_ko_v4.mp3';
        break;
      case 'ja':
        smallText = 'Paransoriと過ごした時間、\n楽しんでいただけましたか?\n\nいつでもまた遊びに来てください、\n素敵な音でお迎えします。\nまた会いましょう!';
        farewellAsset = 'assets/farewell_ja.mp3';
        break;
      case 'zh':
        smallText = '与Paransori相伴的时光，\n您开心吗?\n\n欢迎随时回来，\n我们会用美好的声音迎接您。\n再见啦!';
        farewellAsset = 'assets/farewell_zh.mp3';
        break;
      default:
        smallText = 'Did you enjoy your time\nwith Paransori?\n\nCome back anytime — we\'ll\nwelcome you with great sounds again.\nGoodbye, and see you soon!';
        farewellAsset = 'assets/farewell_en.mp3';
    }
    context.read<PlayerProvider>().player.setVolume(0.12);
    if (context.read<ThemeProvider>().voiceGreetingEnabled) {
      final farewellPlayer = AudioPlayer();
      farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
    }
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.05, end: 0.85),
            duration: const Duration(milliseconds: 11000),
            curve: Curves.easeIn,
            builder: (_, darkValue, __) => Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(farewellImageUrl(context)),
                  onError: (_, __) {},
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(darkValue),
                    BlendMode.darken,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 8000), () async {
      late OverlayEntry fadeOutEntry;
      fadeOutEntry = OverlayEntry(
        builder: (_) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      );
      overlay.insert(fadeOutEntry);

      final pp = context.read<PlayerProvider>();
      if (pp.isPlaying) {
        await pp.togglePlayPause();
      }
      final handler = globalAudioHandler;
      if (handler is SimpleAudioHandler) {
        handler.playbackState.add(PlaybackState());
        handler.mediaItem.add(null);
        await handler.stop();
      }

      await Future.delayed(const Duration(milliseconds: 900));
      entry.remove();
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('closeApp');
    });
  }

  void _showExitConfirmDialog(BuildContext context) async {
    // 새 종료창 (사진 + 큰 질문) — 홈·음악·라디오·자연소리 공통
    if (await showExitConfirm(context) && context.mounted) _showFarewellAndExit(context);
  }

  // (예전 종료창 — 코드 정리할 때 지우기)
  void _oldExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.musicExitConfirmTitle,
                style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.musicExitConfirmMessage,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.radioExitKeepListening),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                        _showFarewellAndExit(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.radioExitConfirmButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarItem(
      BuildContext context, {
        IconData? icon,
        String? customIcon,
        required String label,
        required bool isActive,
        required VoidCallback onTap,
      }) {
    const baseColor = Colors.white;
    final iconColor = isActive ? baseColor : baseColor.withOpacity(0.55);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon != null
                ? SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2.2">$customIcon</svg>',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  )
                : Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(height: 4),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.fixedAccent : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStyleDialog(BuildContext context, Color primaryColor) {
    return _styleDialog(context, _albumArtStyle, (id) {
      if (mounted) setState(() => _albumArtStyle = id);
      _saveStyle(id);
    }, printStyle: _printStyle, onPrintPick: (v) {
      if (mounted) _setPrintStyle(v);
    });
  }

  /// 재생화면 스타일 선택 창 (재생화면 메뉴 · 곡 목록 메뉴 같이 씀)
  static Future<void> _styleDialog(BuildContext context, int current, ValueChanged<int> onPick,
      {int printStyle = 0, ValueChanged<int>? onPrintPick}) {
    const accent = AppTheme.fixedAccent;
    final styles = [
      {'id': 1, 'name': AppLocalizations.of(context)!.styleCD, 'icon': Icons.album, 'desc': AppLocalizations.of(context)!.styleCDDesc},
      {'id': 6, 'name': '파란포토', 'icon': Icons.photo_outlined, 'desc': '좋아하는 사진을 배경으로 골라보세요'},
      {'id': 3, 'name': AppLocalizations.of(context)!.styleCard, 'icon': Icons.image, 'desc': AppLocalizations.of(context)!.styleCardDesc},
    ];

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.style, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playerStyle,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = current == style['id'];
                return InkWell(
                  onTap: () {
                    current = style['id'] as int;
                    onPick(current);
                    setDialogState(() {});
                    // 앨범은 바로 닫지 않고 아래에서 인화 모양을 고르게
                    if (current != 3 || onPrintPick == null) Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withOpacity(0.10) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                      children: [
                        Icon(style['icon'] as IconData,
                            color: isSelected ? accent : Colors.black38, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(style['name'] as String,
                                      style: TextStyle(
                                          color: isSelected ? accent : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  if (style['id'] == 6) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2589E8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '추천',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(style['desc'] as String,
                                  style: const TextStyle(color: Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: accent, size: 20),
                      ],
                    ),
                        // 앨범을 골랐을 때: 인화 모양 고르기
                        if (style['id'] == 3 && isSelected && onPrintPick != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10, left: 36),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final e in const ['기본', '폴라로이드', '테이프', '겹친 사진', '둥근 테두리'].asMap().entries)
                                  GestureDetector(
                                    onTap: () {
                                      printStyle = e.key;
                                      onPrintPick(e.key);
                                      Navigator.pop(ctx);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: printStyle == e.key ? accent : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: printStyle == e.key ? accent : Colors.black12),
                                      ),
                                      child: Text(e.value,
                                          style: TextStyle(
                                            color: printStyle == e.key ? Colors.white : Colors.black87,
                                            fontSize: 12,
                                          )),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: accent)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 곡 목록 점 3개 메뉴에서도 재생화면 메뉴와 똑같은 줄을 쓰기 위한 공용 함수 ──

/// 셔플 · 반복 · 수면 · 재생화면 스타일 · 배속 줄 묶음
List<Widget> playerSettingRows(
  BuildContext context, {
  required Song song,
  required int style,
  required String bgPath,
  required bool bgIsFile,
  required Color textColor,
  required VoidCallback onStyleChanged,
  bool showNew = false,
}) {
  final p = context.watch<PlayerProvider>();
  const accent = Color(0xFF2589E8);
  void vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
  return [
    _PlayerScreenState._playerSheetItem(
      context, Icons.shuffle_rounded, AppLocalizations.of(context)!.shuffle, accent, textColor,
      () { vib(); p.toggleShuffle(); },
      trailing: _PlayerScreenState._sheetMiniSwitch(p.isShuffled),
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.repeat_rounded, '반복', accent, textColor,
      () { vib(); p.toggleLoopMode(); },
      trailing: _PlayerScreenState._sheetRepeatChips(p),
      trailingTappable: true,
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.nightlight_round, '수면', accent, textColor,
      () { vib(); showPlayerSleepMenu(context); },
      trailing: _PlayerScreenState._sheetValue(_PlayerScreenState._sheetSleepLabel(p)),
      arrow: true,
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.style, AppLocalizations.of(context)!.playerStyle, accent, textColor,
      () async { await showPlayerStyleMenu(context); onStyleChanged(); },
      trailing: _PlayerScreenState._styleThumbs(song, style, bgPath, bgIsFile, showNew: showNew),
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.speed, '배속', accent, textColor,
      () { showPlayerSpeedMenu(context); },
      trailing: _PlayerScreenState._sheetValue(_PlayerScreenState._sheetSpeedLabel(p.playbackSpeed)),
      arrow: true,
    ),
  ];
}

void showPlayerSleepMenu(BuildContext context) {
  final p = context.read<PlayerProvider>();
  if (p.isSleepTimerActive) {
    _PlayerScreenState._showSleepTimerDialog(context, p, AppTheme.fixedAccent);
  } else {
    _PlayerScreenState._showSleepWheelPickerDirect(context, p, AppTheme.fixedAccent);
  }
}

void showPlayerSpeedMenu(BuildContext context) =>
    _PlayerScreenState._showSpeedDialog(context, context.read<PlayerProvider>(), AppTheme.fixedAccent);

Future<void> showPlayerStyleMenu(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  final current = prefs.getInt('albumArtStyle') ?? 6; // 처음엔 파란포토
  await prefs.setBool('hasSeenParanPhoto', true);
  await _PlayerScreenState._styleDialog(context, current, (id) => prefs.setInt('albumArtStyle', id),
      printStyle: prefs.getInt('printStyle') ?? 0,
      onPrintPick: (v) => prefs.setInt('printStyle', v));
}

/// 꼬리가 살랑살랑 흔들리는 고양이 (재생 중일 때만)
class _SwayingCat extends StatefulWidget {
  final Color color;
  final Size size;
  final bool moving;
  const _SwayingCat({required this.color, required this.size, required this.moving});

  @override
  State<_SwayingCat> createState() => _SwayingCatState();
}

class _SwayingCatState extends State<_SwayingCat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800), // 숫자가 클수록 천천히
    value: 0.5,
  );

  @override
  void initState() {
    super.initState();
    if (widget.moving) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SwayingCat old) {
    super.didUpdateWidget(old);
    if (widget.moving && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.moving && old.moving) {
      // 멈추면 꼬리를 가운데로 천천히 돌려놓기
      _c.animateTo(0.5, duration: const Duration(milliseconds: 600));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final sway = Curves.easeInOut.transform(_c.value) * 2 - 1; // -1 ~ 1
        return CustomPaint(
          size: widget.size,
          painter: _CatSilhouettePainter(widget.color, sway: sway),
        );
      },
    );
  }
}

/// 앉아 있는 고양이 실루엣 (파란포토 제목 박스)
class _CatSilhouettePainter extends CustomPainter {
  final Color color;
  final double sway; // 꼬리 흔들림 -1 ~ 1
  _CatSilhouettePainter(this.color, {this.sway = 0});

  @override
  void paint(Canvas canvas, Size size) {
    // 엎드린 고양이: 46 x 26 칸 기준으로 그린 뒤 크기에 맞춰 줄임
    canvas.save();
    canvas.scale(size.width / 46, size.height / 26);
    final fill = Paint()..color = color;
    final body = Path()
      ..addOval(const Rect.fromLTRB(10, 11, 36, 23.5)) // 몸 (길게 엎드림)
      ..addOval(const Rect.fromLTRB(3, 5, 15, 16.5)) // 머리
      ..moveTo(3.8, 9) // 왼쪽 귀
      ..lineTo(4.4, 2.4)
      ..lineTo(8.4, 6)
      ..close()
      ..moveTo(9.4, 5.6) // 오른쪽 귀
      ..lineTo(13, 2.4)
      ..lineTo(13.8, 9)
      ..close()
      ..addRRect(RRect.fromLTRBR(1.5, 19.5, 13, 23.5, const Radius.circular(2))); // 앞발
    canvas.drawPath(body, fill);
    // 꼬리 (끝이 위아래로 살랑)
    final tail = Path()
      ..moveTo(34.5, 19.5)
      ..cubicTo(40, 20, 43, 15 + 3 * sway, 41 + 0.8 * sway, 9.5 + 3 * sway);
    canvas.drawPath(
      tail,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CatSilhouettePainter old) =>
      old.color != color || old.sway != sway;
}

/// 필름 입자: 화면 위에 아주 옅은 점들을 한 번만 그림 (매번 같은 무늬)
class _FilmGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final count = (size.width * size.height / 160).round();
    final light = Paint();
    final dark = Paint();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = 0.04 + rnd.nextDouble() * 0.07;
      final p = rnd.nextBool()
          ? (light..color = Colors.white.withOpacity(a))
          : (dark..color = Colors.black.withOpacity(a));
      canvas.drawRect(Rect.fromLTWH(x, y, 1.3, 1.3), p);
    }
  }

  @override
  bool shouldRepaint(_FilmGrainPainter old) => false;
}

/// 찢어진 인화 사진 모양: 위·왼쪽은 반듯, 오른쪽·아래는 찢어짐 (곡마다 찢어진 모양이 조금씩 다름)
Path _tornPhotoPath(Size s, int seed) {
  final rnd = math.Random(seed);
  double jitter() => (rnd.nextDouble() - 0.5) * 4.4;
  const depth = 12.0;
  final p = Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0);
  double off = 0;
  for (double y = 0; y <= s.height; y += 6) {
    off = (off + jitter()).clamp(-depth, 0.0).toDouble();
    p.lineTo(s.width + off - rnd.nextDouble() * 1.5, y);
  }
  off = 0;
  final tearStart = s.width * 0.62; // 오른쪽 아래 모서리가 더 크게 찢어짐
  for (double x = s.width; x >= 0; x -= 6) {
    off = (off + jitter()).clamp(-depth, 0.0).toDouble();
    final cut = math.max(0.0, x - tearStart) * 0.38;
    p.lineTo(x, s.height + off - cut - rnd.nextDouble() * 1.5);
  }
  p
    ..lineTo(0, s.height)
    ..close();
  return p;
}

class _TornClipper extends CustomClipper<Path> {
  final int seed;
  _TornClipper(this.seed);
  @override
  Path getClip(Size size) => _tornPhotoPath(size, seed);
  @override
  bool shouldReclip(_TornClipper old) => old.seed != seed;
}

/// 뒤: 그림자 / 앞: 찢어진 가장자리 하얀 종이 결
class _TornEdgePainter extends CustomPainter {
  final int seed;
  final bool shadow;
  _TornEdgePainter({required this.seed, required this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _tornPhotoPath(size, seed);
    if (shadow) {
      canvas.drawShadow(path.shift(const Offset(0, 4)), Colors.black, 12, false);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withOpacity(0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_TornEdgePainter old) => old.seed != seed || old.shadow != shadow;
}

/// 파란 글자가 천천히 밝아졌다 어두워지는 숨쉬기 (재생 중일 때만)
class _BreathingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool moving;
  const _BreathingText({required this.text, required this.style, required this.moving});

  @override
  State<_BreathingText> createState() => _BreathingTextState();
}

class _BreathingTextState extends State<_BreathingText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600), // 반 번 숨쉬는 시간 (클수록 천천히)
  );

  static const _dim = Color(0xB35C9FE0); // 어두울 때 (반투명 70%)
  static const _bright = Color(0xCCA9D2FA); // 밝을 때 (반투명 80%)

  @override
  void initState() {
    super.initState();
    if (widget.moving) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BreathingText old) {
    super.didUpdateWidget(old);
    if (widget.moving && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.moving && _c.isAnimating) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && !widget.moving) _c.stop();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style.color ?? _dim;
    return TweenAnimationBuilder<double>(
      // 재생 중 1 → 일시정지 0 (원래 색으로 부드럽게)
      tween: Tween(end: widget.moving ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, f, _) => AnimatedBuilder(
        animation: _c,
        builder: (context, __) {
          final t = Curves.easeInOut.transform(_c.value);
          final breath = Color.lerp(_dim, _bright, t)!;
          return Text(
            widget.text,
            style: widget.style.copyWith(
              color: Color.lerp(base, breath, f),
              shadows: [
                Shadow(
                  color: const Color(0xFF7FB8F0).withOpacity(0.25 * t * f),
                  blurRadius: 10,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 글자가 하나씩 번갈아 살짝 위아래로 움직이는 물결 (재생 중일 때만)
class _WavyText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool moving;
  const _WavyText({required this.text, required this.style, required this.moving});

  @override
  State<_WavyText> createState() => _WavyTextState();
}

class _WavyTextState extends State<_WavyText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800), // 숫자가 클수록 천천히
  );

  @override
  void initState() {
    super.initState();
    if (widget.moving) _c.repeat();
  }

  @override
  void didUpdateWidget(_WavyText old) {
    super.didUpdateWidget(old);
    if (widget.moving && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.moving && _c.isAnimating) {
      // 제자리로 내려오는 동안은 조금 더 움직이다가 멈춤
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && !widget.moving) _c.stop();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.text.characters.toList();
    return TweenAnimationBuilder<double>(
      // 재생 중 1 → 일시정지 0 으로 부드럽게 (움직임 크기)
      tween: Tween(end: widget.moving ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, f, _) => AnimatedBuilder(
        animation: _c,
        builder: (context, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chars.length; i++)
              Transform.translate(
                // 글자마다 조금씩 늦게 → 물결처럼 번갈아 올라감 (최대 4px)
                offset: Offset(0, -4 * f * (0.5 - 0.5 * math.cos(2 * math.pi * (_c.value - i * 0.14)))),
                child: Text(chars[i], style: widget.style),
              ),
          ],
        ),
      ),
    );
  }
}

void _showLoopModeDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
  const accent = AppTheme.fixedAccent;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.repeatMode,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildLoopOption(ctx,
              icon: Icons.arrow_forward,
              title: AppLocalizations.of(context)!.noRepeat,
              subtitle: AppLocalizations.of(context)!.noRepeat,
              isSelected: playerProvider.loopMode == LoopMode.off,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.off);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            _buildLoopOption(ctx,
              icon: Icons.repeat_one,
              title: AppLocalizations.of(context)!.repeatOne,
              subtitle: AppLocalizations.of(context)!.repeatOne,
              isSelected: playerProvider.loopMode == LoopMode.one,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.one);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            _buildLoopOption(ctx,
              icon: Icons.repeat,
              title: AppLocalizations.of(context)!.repeatAll,
              subtitle: AppLocalizations.of(context)!.repeatAll,
              isSelected: playerProvider.loopMode == LoopMode.all,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.all);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLoopOption(
    BuildContext ctx, {
      required IconData icon,
      required String title,
      required String subtitle,
      required bool isSelected,
      required Color primaryColor,
      required VoidCallback onTap,
    }) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.12) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isSelected ? primaryColor : Colors.black38, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isSelected ? primaryColor : Colors.black87,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: primaryColor, size: 20),
        ],
      ),
    ),
  );
}

class _SleepTimerDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SleepTimerDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<_SleepTimerDialog> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    if (widget.playerProvider.isSleepTimerActive &&
        widget.playerProvider.sleepTimerEnd != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final end = widget.playerProvider.sleepTimerEnd;
    if (end != null) {
      _remaining = end.difference(DateTime.now());
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final end = widget.playerProvider.sleepTimerEnd;
      if (end == null) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = end.difference(DateTime.now());
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    final l = AppLocalizations.of(context)!;
    final timeStr = hours > 0
        ? '$hours${l.hourWord} $minutes${l.minuteShort} $seconds${l.secondShort}'
        : '$minutes${l.minuteShort} $seconds${l.secondShort}';
    return '$timeStr ${l.autoStopCountdownSuffix}';
  }

  // 자연소리와 똑같은, 시간·분을 휠로 돌려서 정하는 방식
  void _showWheelPicker(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    Duration picked = const Duration(minutes: 30);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('몇 시간 몇 분 후 정지할까요?',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: textColor, fontSize: 20),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (picked.inMinutes > 0) {
                          widget.playerProvider.setSleepTimer(picked);
                          if (!mounted) return;
                          _startCountdown();
                          setState(() {});
                          final timeLabel =
                              '${picked.inHours > 0 ? '${picked.inHours}${AppLocalizations.of(context)!.hourWord} ' : ''}${picked.inMinutes % 60}${AppLocalizations.of(context)!.minuteShort}';
                          showParanToast(context, AppLocalizations.of(context)!.autoStopFormat(timeLabel));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.set,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.playerProvider.isSleepTimerActive;
    final primaryColor = widget.primaryColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.sleepTimer,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.timer, color: primaryColor, size: 32),
                  const SizedBox(height: 8),
                  Text(_formatRemaining(_remaining),
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.playerProvider.cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.timerCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showWheelPicker(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.set,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeedDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SpeedDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends State<_SpeedDialog> {
  static const List<double> _speeds = [
    0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95,
    1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4, 1.45,
    1.5, 1.55, 1.6, 1.65, 1.7, 1.75, 1.8, 1.85, 1.9, 1.95, 2.0,
  ];

  late double _speed;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _speed = widget.playerProvider.playbackSpeed;
    final initialIndex = _speeds.indexWhere((s) => (s - _speed).abs() < 0.01);
    _scrollController = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 10,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    widget.playerProvider.setPlaybackSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.fixedAccent;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playbackSpeed,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                CupertinoPicker(
                  scrollController: _scrollController,
                  itemExtent: 44,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (index) => _setSpeed(_speeds[index]),
                  children: _speeds.map((speed) {
                    final isSelected = (_speed - speed).abs() < 0.01;
                    return Center(
                      child: Text(
                        '${speed.toStringAsFixed(2)}x',
                        style: TextStyle(
                          color: isSelected ? primaryColor : textColor.withOpacity(0.4),
                          fontSize: isSelected ? 22 : 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final index = _speeds.indexWhere((s) => (s - 1.0).abs() < 0.01);
                    _scrollController.animateToItem(
                      index >= 0 ? index : 10,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                    _setSpeed(1.0);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.defaultValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _RadialVisualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  static final List<double> _heights = List.filled(48, 0.5);
  static final List<double> _speeds = List.generate(
      48, (i) => 0.003 + (i * 0.0007) % 0.005);
  static final List<double> _dirs = List.filled(48, 1.0);
  static bool _initialized = false;

  _RadialVisualizerPainter({
    required this.progress,
    required this.isPlaying,
  }) {
    if (!_initialized) {
      for (int i = 0; i < 48; i++) {
        _heights[i] = 0.1 + (i * 0.019) % 0.9;
        _dirs[i] = i % 2 == 0 ? 1.0 : -1.0;
      }
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const innerR = 52.0;
    const maxBar = 55.0;
    const barCount = 48;

    for (int i = 0; i < barCount; i++) {
      if (isPlaying) {
        _heights[i] += _speeds[i] * _dirs[i];
        if (_heights[i] > 1.0 || _heights[i] < 0.1) _dirs[i] *= -1;
      }

      final angle = (i / barCount) * 2 * pi - pi / 2;
      final barH = isPlaying ? 8 + _heights[i] * maxBar : 6.0;
      final alpha = isPlaying ? 0.12 + _heights[i] * 0.5 : 0.1;

      final x1 = center.dx + innerR * cos(angle);
      final y1 = center.dy + innerR * sin(angle);
      final x2 = center.dx + (innerR + barH) * cos(angle);
      final y2 = center.dy + (innerR + barH) * sin(angle);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = Colors.white.withOpacity(alpha)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RadialVisualizerPainter old) => true;
}
class _FarewellTextPainter extends CustomPainter {
  final double opacity;
  final String smallText;
  _FarewellTextPainter({required this.opacity, required this.smallText});

  @override
  void paint(Canvas canvas, Size size) {
    final isMultiline = smallText.contains('\n');
    final smallPainter = TextPainter(
      text: TextSpan(
        text: smallText,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity * 0.85),
          fontSize: isMultiline ? 17 : 14,
          letterSpacing: isMultiline ? 0.2 : 5,
          fontWeight: FontWeight.w500,
          fontStyle: isMultiline ? FontStyle.normal : FontStyle.italic,
          height: 1.6,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    smallPainter.paint(canvas, Offset((size.width - smallPainter.width) / 2, 0));

    final bigPainter = TextPainter(
      text: TextSpan(
        text: 'Paransori',
        style: TextStyle(color: Colors.white.withOpacity(opacity), fontSize: 33, letterSpacing: 3, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bigPainter.paint(canvas, Offset((size.width - bigPainter.width) / 2, smallPainter.height + 12));
  }

  @override
  bool shouldRepaint(covariant _FarewellTextPainter oldDelegate) => oldDelegate.opacity != opacity;
}