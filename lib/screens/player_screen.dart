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
import 'home_screen.dart';
import '../utils/point_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/greeting_images.dart';
import '../widgets/farewell_title.dart';
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
import 'settings_screen.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/exit_confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/menu_parts.dart';
import '../widgets/action_feedback.dart';
import '../widgets/playlist_pick_sheet.dart';
import '../widgets/paran_toast.dart';
import '../widgets/paran_dialog.dart';
import '../services/cast_service.dart';
import '../widgets/cast_sheets.dart';
import '../widgets/artist_info_sheet.dart';
import '../services/nature_overlay.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_holder.dart';
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
  int _photoMode = 1; // 파란포토: 0 자동(시간대) · 1 랜덤 · 2 고정
  String _photoRange = ''; // 랜덤 범위: 카테고리 이름 · 전체 · 하트 · 내 사진 (비어 있으면 지금 사진의 카테고리)
  Set<String> _photoPicks = {}; // 랜덤일 때 고른 사진 (있으면 곡마다 이 사진들만)

  // ───── 파란포토 사진 (클라우드플레어 R2: app-images/paranphoto/001.jpg + 001_thumb.jpg) ─────
  //  · 이름은 'assets/paranphoto/번호.png'로 적으면 paran_photo.dart가 R2에서 받아와요
  //  · 사진 추가: R2에 큰 사진·작은 사진(_thumb)을 올리고 R2 paranphoto/list.json에 번호만 추가 (앱 업데이트 필요 없음)
  //    아래 묶음은 목록을 못 받았을 때 쓰는 기본 목록
  //  · 카테고리 나누기: '비 오는 날': [...] 처럼 묶음을 더 만들면 사진 고르기 창에 칩이 저절로 생겨요
  //    (묶음이 하나뿐이면 칩은 안 보이고 전체 · 내 사진 · 고른 사진만)
  static const String _paranDefault = 'assets/paranphoto/001.png'; // 처음 쓰는 사람 기본 사진
  static const Map<String, String> _nightCategoryCover = {}; // 카테고리 칩 사진 (비우면 그 묶음 첫 사진)

  static const Map<String, List<String>> _builtinPhotos = {
    '파란포토': [
      'assets/paranphoto/001.png',
      'assets/paranphoto/002.png',
      'assets/paranphoto/003.png',
      'assets/paranphoto/004.png',
      'assets/paranphoto/005.png',
      'assets/paranphoto/006.png',
      'assets/paranphoto/007.png',
      'assets/paranphoto/008.png',
      'assets/paranphoto/009.png',
      'assets/paranphoto/010.png',
    ],
  };
  // 지금 쓸 사진 목록: R2에서 받은 것 (없으면 위 기본 목록)
  static Map<String, List<String>> get _nightCategoryPhotos => ParanPhotoList.of(_builtinPhotos);
  Color _dominantColor = const Color(0xFF1A1A1A);
  bool _showSwipeHint = false;
  bool _hasSeenParanPhoto = true;
  bool _photoBtnSeen = true; // 아래 사진기를 한 번이라도 눌렀는지 (안 눌렀으면 NEW)
  Color? _lastPoint; // 포인트 색 바뀌면 시디롬 빛 번짐도 바로 다시

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final point = Theme.of(context).colorScheme.primary;
    if (_lastPoint != null && _lastPoint!.value != point.value) {
      final song = context.read<PlayerProvider>().currentSong;
      if (song != null && song.albumArt == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _extractColor(song);
        });
      }
    }
    _lastPoint = point;
  }

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
    // 새 사진 목록 받기 (앱 켜고 한 번만) — 바뀌었으면 화면 다시
    ParanPhotoList.refresh().then((changed) {
      if (changed && mounted) setState(() {});
    });
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
            Icon(Icons.check_circle_rounded, color: pointColorOf(context, onDark: false), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(tr.paranPhotoSwitched,
                  style: const TextStyle(color: Color(0xFF17140F), fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                if (!mounted) return;
                setState(() => _albumArtStyle = prev);
                _saveStyle(prev);
              },
              style: TextButton.styleFrom(foregroundColor: pointColorOf(context, onDark: false)),
              child: Text(prev == 3 ? tr.backToAlbum : tr.backToCd,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr.paranSuggestTitle,
                                    style: const TextStyle(
                                        color: Color(0xFF17140F), fontSize: 15.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(tr.paranSuggestSub,
                                    style: const TextStyle(color: Color(0xFF8A857B), fontSize: 12.5)),
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
                            child: Text(tr.noThanks, style: const TextStyle(fontSize: 13.5)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: _tryParanPhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pointColorOf(context, onDark: false),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(tr.takeALook, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
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
    ParanPhotoList.readCache(prefs); // 지난번에 받은 사진 목록 먼저 (새 사진 고른 사람 그대로)
    var fixedOld = false; // 예전 사진(봄·여름…)을 정리했는지
    setState(() {
      _albumArtStyle = prefs.getInt('albumArtStyle') ?? 6; // 처음엔 파란포토로 시작
      _nightBgPath = prefs.getString('nightBgPath') ?? _paranDefault;
      _nightFavPaths = (prefs.getStringList('nightFavPaths') ?? []).toSet();
      _nightBgIsFile = prefs.getBool('nightBgIsFile') ?? false;
      _showNightPicker = prefs.getBool('showNightPicker') ?? true;
      _hasSeenParanPhoto = prefs.getBool('hasSeenParanPhoto') ?? false;
      _photoBtnSeen = prefs.getBool('photoBtnSeen') ?? false;
      _showSwipeHint = !shown;
      _bgFilter = prefs.getInt('bgFilter') ?? 0;
      if (_bgFilter == 4) _bgFilter = 0; // 예전 인화 설정 → 컬러로
      _printStyle = prefs.getInt('printStyle') ?? 0;
      _autoBgMin = 0; // (예전 10분·30분마다 바꾸기 → 곡마다 바뀌는 자동·랜덤으로 대신)
      _photoMode = prefs.getInt('paranPhotoMode') ?? 1;
      if (_photoMode == 0) _photoMode = 1; // 자동은 뺐으니 랜덤으로
      _photoRange = prefs.getString('paranPhotoRange') ?? '';
      final picks = prefs.getStringList('paranPhotoPicks');
      // 처음엔 예전에 하트 누른 사진을 고른 사진으로
      _photoPicks = picks != null ? picks.toSet() : _nightFavPaths.where((p) => p.startsWith('assets/')).toSet();
      // 예전 사진은 없어졌으니 정리 (배경 → 새 기본 사진, 하트·고른 사진에서는 빼기 / 내 사진은 그대로)
      final all = _nightCategoryPhotos.values.expand((e) => e).toSet();
      bool gone(String p) => p.startsWith('assets/') && !all.contains(p) && p != 'assets/music_night_bg.png';
      if (!_nightBgIsFile && gone(_nightBgPath)) {
        _nightBgPath = _paranDefault;
        fixedOld = true;
      }
      final favBefore = _nightFavPaths.length, picksBefore = _photoPicks.length;
      _nightFavPaths.removeWhere(gone);
      _photoPicks.removeWhere(gone);
      if (_nightFavPaths.length != favBefore || _photoPicks.length != picksBefore) fixedOld = true;
      if (_photoRange.isNotEmpty &&
          !['전체', '하트', '내 사진', '고른 사진', ..._nightCategoryPhotos.keys].contains(_photoRange)) {
        _photoRange = '';
        fixedOld = true;
      }
      _styleLoaded = true;
    });
    if (fixedOld) {
      await prefs.setString('nightBgPath', _nightBgPath);
      await prefs.setStringList('nightFavPaths', _nightFavPaths.toList());
      await prefs.setStringList('paranPhotoPicks', _photoPicks.toList());
      await prefs.setString('paranPhotoRange', _photoRange);
    }
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

  void _restartAutoBgTimer() {
    _autoBgTimer?.cancel();
    _autoBgTimer = null;
    if (_autoBgMin <= 0) return;
    _autoBgTimer = Timer.periodic(Duration(minutes: _autoBgMin), (_) => _autoChangeBg());
  }

  void _autoChangeBg() {
    if (!mounted || _albumArtStyle != 6) return;
    if (!context.read<PlayerProvider>().isPlaying) return;
    final List<String> pool = _photoPool();
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

  Widget _bgFiltered(Widget child, [int? only]) {
    final f = only ?? _bgFilter; // only: 미리보기용 (그 색감으로)
    if (f == 1) {
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
    if (f == 2) {
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

    if (f == 3) {
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

  // ───── 파란포토: 자동(시간대) · 랜덤 · 고정 ─────

  /// 사진 묶음 이름 (저장은 한국어 그대로, 화면엔 언어에 맞게)
  static String _rangeLabel(String k) => switch (k) {
        '전체' => tr.all,
        '하트' => tr.photoHearts,
        '내 사진' => tr.myPhotos,
        '고른 사진' => tr.pickedPhotos,
        '파란포토' => tr.paranPhoto,
        _ => k,
      };

  /// 지금 시각의 시간대 (노을은 계절 따라: 여름 19시 · 겨울 17시 · 그 밖 18시부터 1시간 반)
  static String _timeCategory([DateTime? now]) {
    final t = now ?? DateTime.now();
    final h = t.hour + t.minute / 60;
    final dusk = (t.month >= 5 && t.month <= 8) ? 19.0 : ((t.month >= 11 || t.month <= 2) ? 17.0 : 18.0);
    if (h >= 4 && h < 7) return '새벽';
    if (h >= 7 && h < 12) return '아침';
    if (h >= 12 && h < dusk) return '오후';
    if (h >= dusk && h < dusk + 1.5) return '노을';
    if (h >= dusk + 1.5 && h < 23) return '밤';
    return '깊은 밤';
  }

  /// 사진이 들어 있는 카테고리 (없으면 null)
  String? _catOf(String path) {
    for (final e in _nightCategoryPhotos.entries) {
      if (e.value.contains(path)) return e.key;
    }
    return null;
  }

  /// 다음 곡에 보여 줄 사진 후보 (고정이면 빈 목록)
  List<String> _photoPool() {
    if (_photoMode == 2) return <String>[];
    if (_photoMode == 0) {
      final list = _nightCategoryPhotos[_timeCategory()];
      if (list != null && list.isNotEmpty) return List.of(list);
      // 시간대 사진이 아직 없으면 랜덤처럼
    }
    // 랜덤: 고른 사진이 있으면 그 사진들만
    final picks = _photoPicks.where((p) => p.startsWith('assets/') || File(p).existsSync()).toList();
    if (picks.isNotEmpty) return picks;
    final r = _photoRange;
    if (r == '전체') return _nightCategoryPhotos.values.expand((e) => e).toList();
    if (r == '하트') return _nightFavPaths.where((p) => p.startsWith('assets/')).toList();
    if (r == '내 사진') return _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
    final list = _nightCategoryPhotos[r] ?? _nightCategoryPhotos[_catOf(_nightBgPath) ?? ''];
    return List.of(list ?? const <String>[]);
  }

  Future<void> _setPhotoMode(int m) async {
    setState(() => _photoMode = m);
    final p = await SharedPreferences.getInstance();
    await p.setInt('paranPhotoMode', m);
    // 자동으로 바꾸면 바로 지금 시간대 사진으로
    if (m == 0) {
      final list = _nightCategoryPhotos[_timeCategory()];
      if (list != null && list.isNotEmpty && !list.contains(_nightBgPath)) {
        final next = list[math.Random().nextInt(list.length)];
        if (!mounted) return;
        setState(() {
          _nightBgPath = next;
          _nightBgIsFile = false;
        });
        _saveNightBg(next);
      }
    }
  }

  Future<void> _setPhotoRange(String r) async {
    _photoRange = r;
    final p = await SharedPreferences.getInstance();
    await p.setString('paranPhotoRange', r);
  }

  /// 파란포토 사진 고르기 창 (가사 배경 창과 같은 모양: 아래에서 올라오고, 사진은 3장씩 위아래로)
  void _openParanPhotoSheet() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    // 처음 열 때는 지금 배경 사진이 들어 있는 카테고리로
    String cat = '전체';
    if (_nightBgIsFile) {
      cat = '내 사진';
    } else {
      for (final e in _nightCategoryPhotos.entries) {
        if (e.value.contains(_nightBgPath)) {
          cat = e.key;
          break;
        }
      }
    }
    if (_photoMode == 0 && (_nightCategoryPhotos[_timeCategory()] ?? const []).isNotEmpty) {
      cat = _timeCategory();
    } else if (_photoMode == 1 && _photoRange.isNotEmpty) {
      cat = _photoRange;
    }
    bool manage = false; // 내 사진 관리(✕) 모드

    showParanSheet(
      context,
      title: tr.paranPhoto,
      // 제목 옆에 작게: 무엇을 하는 곳인지
      header: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Builder(builder: (_) {
          final dark = context.read<ThemeProvider>().isDarkMode;
          return Row(
            children: [
              // 왼쪽 카메라 아이콘 칸 (수면 타이머 창과 같은 모양)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF3E3B37) : Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.photo_camera_outlined, size: 20,
                    color: dark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.paranPhoto,
                        style: GoogleFonts.doHyeon( // 홈과 같은 글꼴
                          color: dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),
                          fontSize: 19,
                        )),
                    const SizedBox(height: 1),
                    Text(tr.paranPhotoSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378),
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
      builder: (ctx, setSheet) {
        final dark = context.read<ThemeProvider>().isDarkMode;
        final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
        final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
        final chipBg = dark ? const Color(0xFF32302C) : Colors.white;
        final chipLine = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
        void tick() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

        // 내 사진 지우기 (지금 배경이면 다른 사진으로)
        void removeMine(String path) {
          tick();
          setState(() {
            _nightFavPaths.remove(path);
            _photoPicks.remove(path);
            SharedPreferences.getInstance()
                .then((p) => p.setStringList('paranPhotoPicks', _photoPicks.toList()));
            if (_nightBgPath == path) {
              final next = _nightFavPaths.isNotEmpty ? _nightFavPaths.first : _paranDefault;
              _nightBgPath = next;
              _nightBgIsFile = !next.startsWith('assets/');
              _saveNightBg(next, isFile: _nightBgIsFile);
            }
          });
          SharedPreferences.getInstance()
              .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
          setSheet(() {});
        }

        // 사진 한 장
        //  · 랜덤: 누르면 "고른 사진"에 넣기 / 한 번 더 누르면 빼기 (창은 그대로) — 고른 사진이 있으면 곡마다 그 사진들만
        //  · 자동·고정: 누르면 배경으로 + 창 닫기
        Widget photoTile(String path, {bool isFile = false}) {
          final selected = _nightBgPath == path;
          final picked = _photoPicks.contains(path);
          final pickMode = _photoMode == 1 && !manage;
          final on = pickMode ? picked : selected;
          return GestureDetector(
            onTap: manage
                ? null
                : () {
                    tick();
                    if (pickMode) {
                      setState(() {
                        if (picked) {
                          _photoPicks.remove(path);
                        } else {
                          _photoPicks.add(path);
                          _nightBgPath = path; // 고르면 바로 배경으로 보이게
                          _nightBgIsFile = isFile;
                        }
                      });
                      if (!picked) _saveNightBg(path, isFile: isFile);
                      SharedPreferences.getInstance()
                          .then((p) => p.setStringList('paranPhotoPicks', _photoPicks.toList()));
                      setSheet(() {});
                      return;
                    }
                    setState(() {
                      _nightBgPath = path;
                      _nightBgIsFile = isFile;
                    });
                    _saveNightBg(path, isFile: isFile);
                    Navigator.pop(ctx);
                  },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: on && !manage ? ink : Colors.transparent, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    isFile
                        ? Image.file(File(path),
                            fit: BoxFit.cover,
                            cacheWidth: 270, // 작게 미리보기
                            errorBuilder: (_, __, ___) => Container(color: const Color(0x22000000)))
                        : paranPhoto(path, thumb: true, fit: BoxFit.cover),
                    if (on && !manage)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Icon(Icons.check_circle_rounded,
                            color: pickMode ? Theme.of(ctx).colorScheme.primary : Colors.white,
                            size: 22,
                            shadows: const [Shadow(color: Colors.black38, blurRadius: 4)]),
                      ),
                    if (manage)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => removeMine(path),
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

        // + 사진 추가 (가사 배경 창과 같은 모양)
        Widget addTile() => GestureDetector(
              onTap: () async {
                final before = _nightBgPath;
                await _pickFromGallery();
                if (!ctx.mounted) return;
                if (_nightBgPath != before) {
                  Navigator.pop(ctx);
                } else {
                  setSheet(() {});
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chipLine, width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: sub, size: 26),
                    const SizedBox(height: 4),
                    Text(tr.addPhoto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(tr.portraitBest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: sub.withOpacity(0.75), fontSize: 9.5)),
                  ],
                ),
              ),
            );

        final mine = _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
        final picksNow = _photoPicks.where((p) => p.startsWith('assets/') || File(p).existsSync()).toList();
        // 카테고리 묶음이 둘 이상일 때만 칩으로 (하나뿐이면 '전체'와 같아서 숨김)
        final cats = <String>['전체', '내 사진', if (picksNow.isNotEmpty) '고른 사진',
          if (_nightCategoryPhotos.length > 1) ..._nightCategoryPhotos.keys];
        if (!cats.contains(cat)) cat = '전체';

        // 카테고리 작은 사진
        Widget coverOf(String c) {
          if (c == '고른 사진' && picksNow.isNotEmpty && !picksNow.first.startsWith('assets/')) {
            return Image.file(File(picksNow.first),
                fit: BoxFit.cover, cacheWidth: 120, errorBuilder: (_, __, ___) => Container(color: chipBg));
          }
          if (c == '내 사진') {
            if (mine.isNotEmpty) {
              return Image.file(File(mine.first),
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  errorBuilder: (_, __, ___) => Container(color: chipBg));
            }
            return Container(color: chipBg, child: Icon(Icons.add_photo_alternate_outlined, color: sub, size: 22));
          }
          final String? p = c == '전체'
              ? (_nightCategoryPhotos.values.isNotEmpty ? _nightCategoryPhotos.values.first.first : null)
              : c == '고른 사진'
                  ? (picksNow.isNotEmpty ? picksNow.first : null)
                  : (_nightCategoryCover[c] ?? _nightCategoryPhotos[c]?.first);
          if (p == null) return Container(color: chipBg);
          return Stack(
            fit: StackFit.expand,
            children: [
              paranPhoto(p, thumb: true, fit: BoxFit.cover),
              if (c == '고른 사진')
                const Center(
                  child: Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                ),
            ],
          );
        }

        final List<Widget> tiles;
        if (cat == '내 사진') {
          tiles = [if (!manage) addTile(), for (final f in mine) photoTile(f, isFile: true)];
        } else {
          final photos = cat == '전체'
              ? _nightCategoryPhotos.values.expand((e) => e).toList()
              : cat == '고른 사진'
                  ? picksNow
                  : (_nightCategoryPhotos[cat] ?? const <String>[]);
          tiles = [for (final p in photos) photoTile(p, isFile: !p.startsWith('assets/'))];
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 랜덤 · 고정 스위치 (음악 재생화면 · 가사 배경 같은 모양)
            ParanCard(
              children: [
                InkWell(
                  onTap: () {
                    tick();
                    _setPhotoMode(_photoMode == 1 ? 2 : 1).then((_) {
                      if (ctx.mounted) setSheet(() {});
                    });
                    setSheet(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 22,
                            child: Icon((_photoMode == 1) ? Icons.shuffle_rounded : Icons.push_pin_outlined,
                                color: sub, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((_photoMode == 1) ? tr.photoRandom : tr.photoFixed,
                                  style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text((_photoMode == 1) ? tr.photoRandomSub : tr.photoFixedSub,
                                  style: TextStyle(color: sub, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Switch(
                          value: (_photoMode == 1),
                          onChanged: (v) {
                            tick();
                            _setPhotoMode(v ? 1 : 2).then((_) {
                              if (ctx.mounted) setSheet(() {});
                            });
                            setSheet(() {});
                          },
                          activeColor: Theme.of(ctx).colorScheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 카테고리: 작은 사진 + 이름 (옆으로 넘기기)
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final on = cat == c;
                  return GestureDetector(
                    onTap: () {
                      tick();
                      cat = c;
                      manage = false;
                      if (_photoMode == 1) _setPhotoRange(c); // 랜덤이면 이 카테고리 안에서
                      setSheet(() {});
                    },
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: on ? ink : Colors.transparent, width: 2),
                            ),
                            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: coverOf(c)),
                          ),
                          const SizedBox(height: 5),
                          Text(_rangeLabel(c),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: on ? ink : sub,
                                  fontSize: 11.5,
                                  fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 내 사진: 관리 / 완료
            if (cat == '내 사진' && mine.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setSheet(() => manage = !manage),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                    child: Text(manage ? tr.done : tr.manage,
                        style: TextStyle(
                            color: manage ? Theme.of(ctx).colorScheme.primary : sub,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (tiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(tr.comingSoon,
                    textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 13)),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 9 / 16,
                children: tiles,
              ),
            const SizedBox(height: 6),
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
        for (final t in [(0, tr.toneColor), (1, tr.toneBw), (2, tr.toneSepia), (3, tr.toneFilm)]) ...[
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
    _warnIfLandscape([for (final f in picked) f.path]);
  }

  /// 가로 사진을 골랐으면 한 번만 짧게 알려 주기 (사진은 그대로 들어가요)
  Future<void> _warnIfLandscape(List<String> paths) async {
    for (final path in paths) {
      try {
        final codec = await instantiateImageCodec(await File(path).readAsBytes(), targetWidth: 64);
        final frame = await codec.getNextFrame();
        final landscape = frame.image.width > frame.image.height * 1.05;
        frame.image.dispose();
        codec.dispose();
        if (landscape) {
          if (mounted) showParanToast(context, tr.landscapeHint);
          return;
        }
      } catch (_) {}
    }
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
        // 자동: 지금 시간대 · 랜덤: 고른 범위 · 고정: 안 바꿈
        final List<String> options = _photoPool()..remove(_nightBgPath);
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
      // 위로 밀면 가수·곡 정보 카드
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        final s = playerProvider.currentSong;
        if (v < -500 && s != null) showArtistInfo(context, s);
      },
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
                          icon: CupertinoIcons.shuffle,
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
                          label: tr.repeat,
                          isActive: playerProvider.loopMode != LoopMode.off,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.toggleLoopMode();
                          },
                        ),
                        _buildBottomBarItem(
                          context,
                          icon: Icons.nightlight_round,
                          label: tr.radioSleep,
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
                        // 가사 (왼쪽 글줄 + 오른쪽 음표)
                        _buildBottomBarItem(
                          context,
                          icon: null,
                          customIcon: '<path d="M4 7h11" stroke-linecap="round"/><path d="M4 12h8" stroke-linecap="round"/><path d="M4 17h6" stroke-linecap="round"/><path d="M18 6v10" stroke-linecap="round"/><circle cx="16.2" cy="16.3" r="1.9"/><path d="M18 6l2.6 1" stroke-linecap="round" stroke-linejoin="round"/>',
                          label: AppLocalizations.of(context)!.lyrics,
                          isActive: false,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LyricsScreen()));
                          },
                        ),
                        // 파란포토 사진 고르기 (파란포토 스타일일 때만)
                        if (_albumArtStyle == 6)
                          _buildBottomBarItem(
                            context,
                            icon: CupertinoIcons.camera,
                            label: tr.photo,
                            isActive: false,
                            showNew: !_photoBtnSeen,
                            onTap: () {
                              if (!_photoBtnSeen) {
                                setState(() => _photoBtnSeen = true);
                                SharedPreferences.getInstance().then((p) => p.setBool('photoBtnSeen', true));
                              }
                              _openParanPhotoSheet();
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

  Widget _buildTopBar(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    final song = playerProvider.currentSong;
    const baseColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            // 집 아이콘: 누르면 홈으로 (중간 화면 다 닫고 맨 처음 화면으로)
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.of(context).popUntil((r) => r.isFirst);
              HomeScreen.goHome.value++; // 곡 목록이 아니라 메인 홈으로
            },
            icon: const Icon(Icons.home_rounded, color: baseColor, size: 21),
          ),
          // 오른쪽 아이콘(36씩) 폭에 맞춰 비워서 가운데 워터마크가 화면 정중앙에 오게 (왼쪽 ⌄는 48)
          // 왼쪽 ←(48)와 오른쪽 ⋯(36 + 여백 12)의 폭이 같아서 로고가 화면 정가운데
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
                      textDirection: TextDirection.ltr, // 아랍어에서도 Paran + Sori 순서
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "파란"만 숨쉬기 (재생 중일 때만)
                        _BreathingText(
                          text: 'Paran',
                          style: GoogleFonts.quicksand(
    color: sky.withOpacity(0.8), fontSize: 19, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.2),
                          moving: playerProvider.isPlaying,
                        ),
                        Text(
                          isKo ? 'sori' : 'Sori', // 한국은 Paransori, 해외는 발음 때문에 ParanSori
                          style: GoogleFonts.quicksand(
                              color: baseColor.withOpacity(0.42), fontSize: 19, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.2),
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
          GestureDetector(
            onTap: () => _showPlayerOptionsSheet(context, song, primaryColor),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              // 사진·TV 아이콘과 같은 칸(36)
              width: 36,
              height: 40,
              child: Center(
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.more_vert_rounded, color: baseColor, size: 19),
                  // TV로 듣는 중이면 하늘색 점 (TV는 ⋯ 안에 있어서)
                  Positioned(
                    right: -3,
                    bottom: -2,
                    child: AnimatedBuilder(
                      animation: CastService.instance,
                      builder: (_, __) => CastService.instance.isConnected
                          ? Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: Color(0xFF7FB8F0), shape: BoxShape.circle),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
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
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _showPlayerOptionsSheet(BuildContext context, Song? song, Color primaryColor) {
    if (song == null) return;
    final playerProvider = context.read<PlayerProvider>();
    // 다크 모드면 메뉴도 어둡게 (음악 목록 메뉴와 같은 색)
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final sheetColor = isDark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final baseColor = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF1A1A1A);
    final descColor = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    const accent = Color(0xFF8A8378); // 메뉴 아이콘은 차분한 회색 (곡 목록 메뉴와 통일)

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        // 메뉴를 안 닫고 여러 개 바꿀 수 있게: 값이 바뀌면 메뉴가 바로 다시 그려짐
        return StatefulBuilder(builder: (ctx, setSheet) {
        final playerProvider = ctx.watch<PlayerProvider>();
        _sheetBlue = ctx.watch<ThemeProvider>().primaryColor; // 셔플·반복·스타일 표시 = 지금 포인트 색
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
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
                        MenuQuickAction(fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, tr.favorites, () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          music.toggleFavorite(song);
                        }),
                        MenuQuickAction(Icons.playlist_add, tr.playlistLabel, () {
                          _showAddToPlaylistDialog(context, song, primaryColor);
                        }),
                        // 공유·편집: 메뉴는 그대로 두고 위에 띄움 → 돌아오면 메뉴가 그대로
                        MenuQuickAction(Icons.share, tr.share, () async {
                          if (song.uri != null) {
                            await Share.shareXFiles([XFile(song.uri!)], text: song.titleDisplay);
                          }
                        }),
                        MenuQuickAction(Icons.edit, tr.editInfo, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditSongScreen(song: song)));
                        }),
                      ],
                    );
                  }),
                  MenuCard(isDark: isDark, children: [
                  castMenuRow(ctx, baseColor), // TV로 듣기
                  _playerSheetItem(
                    ctx,
                    Icons.shuffle_rounded,
                    tr.shufflePlay,
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
                    tr.repeatPlay,
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
                    tr.sleepTimer,
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
                  _playerSheetItem(ctx, Icons.style, tr.playerScreen, accent, baseColor, () async {
                    if (!_hasSeenParanPhoto) {
                      setState(() => _hasSeenParanPhoto = true);
                      SharedPreferences.getInstance().then((p) => p.setBool('hasSeenParanPhoto', true));
                    }
                    await _showStyleDialog(context, primaryColor);
                    // 고르고 돌아오면 메뉴의 스타일 썸네일도 바로 바뀌게
                    if (ctx.mounted) setSheet(() {});
                  }, trailing: _sheetStyleThumbs(song)),
                  _playerSheetItem(ctx, Icons.speed, tr.playbackSpeed, accent, baseColor, () {
                    _showSpeedDialog(context, context.read<PlayerProvider>(), primaryColor);
                  }, trailing: _sheetValue(_sheetSpeedLabel(playerProvider.playbackSpeed)), arrow: true),
                  _playerSheetItem(ctx, Icons.lyrics_outlined, tr.viewLyrics, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LyricsScreen()));
                  }, arrow: true),
                  // 🌿 자연소리 섞기 (음악 위에 빗소리·파도 등을 깔기)
                  AnimatedBuilder(
                    animation: NatureOverlay.instance,
                    builder: (_, __) => _playerSheetItem(
                      ctx,
                      Icons.forest_outlined,
                      tr.natureMix,
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
                  _playerSheetItem(ctx, Icons.music_note, tr.ringtone, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RingtoneScreen(initialSong: song)));
                  }, arrow: true),
                  _playerSheetItem(ctx, Icons.content_cut, tr.trimAudio, accent, baseColor, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => RingtoneScreen(initialSong: song, trimMode: true)));
                  }, arrow: true),
                  _playerSheetItem(ctx, Icons.info_outline, tr.fileInfo, accent, baseColor, () {
                    SongListTile.showInfo(context, song);
                  }, arrow: true),
                  _playerSheetItem(ctx, Icons.equalizer, AppLocalizations.of(context)!.equalizer, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EqualizerScreen()));
                  }, arrow: true),
                  // 설정 바로가기 (뒤로가기 한 번이면 메뉴로 돌아옴)
                  _playerSheetItem(ctx, Icons.settings_outlined, tr.settings, accent, baseColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
            if (trailing != null) const SizedBox(width: 10), // 줄 이름이 길어도 값과 붙지 않게
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
  static Color _sheetBlue = const Color(0xFF2589E8); // 포인트 색 (메뉴 열 때마다 설정 색으로)
  static const _sheetSub = Color(0xFF8A8378);

  static Widget _sheetValue(String text) => Text(text,
      style: const TextStyle(color: _sheetSub, fontSize: 12.5, fontWeight: FontWeight.w500));

  static String _sheetSleepLabel(PlayerProvider p) {
    final end = p.sleepTimerEnd;
    if (!p.isSleepTimerActive || end == null) return tr.off;
    final secs = end.difference(DateTime.now()).inSeconds;
    final m = (secs / 60).ceil().clamp(1, 100000);
    if (m < 60) return tr.sleepStopInMin(m);
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? tr.sleepStopInHour(h) : tr.sleepStopInHourMin(h, r);
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
          chip(tr.repeatOffChip, LoopMode.off),
          chip(tr.repeatOneChip, LoopMode.one),
          chip(tr.all, LoopMode.all),
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
            // 이름은 사진 폭(48) 안에서 한 줄로 · 길면 살짝 작게 (긴 언어·큰 글자에서 왼쪽 메뉴 글자가 안 밀리게)
            SizedBox(
              width: 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: TextStyle(
                      color: sel ? _sheetBlue : _sheetSub,
                      fontSize: 9.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ),
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
        box(1, 'CD', cd),
        box(6, tr.paranPhoto, photo, isNew: showNew),
        box(3, tr.albumArt, album),
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
          // 반투명 유리 카드 — 은은한 빛 + 바닥 그림자로 붕 떠 있게, 아주 천천히 둥실
          _CardFloat(
          child: Container(
            width: MediaQuery.of(context).size.width - 90,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                // 둘레에 번지는 아주 연한 빛 (포인트 색)
                BoxShadow(
                    color: pointColorOf(context, onDark: true).withOpacity(0.22),
                    blurRadius: 26,
                    spreadRadius: 1),
                // 바닥 그림자
                BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 18,
                    spreadRadius: -6,
                    offset: const Offset(0, 14)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: pointColorOf(context, onDark: true).withOpacity(0.30)),
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
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 5),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showArtistInfo(context, song),
                        child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 포인트색 점 (가사 화면·미니플레이어와 같은 색)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              song.artistDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          // 누를 수 있다는 표시
                          Icon(Icons.chevron_right_rounded, size: 17, color: Colors.white.withOpacity(0.55)),
                        ],
                      ),
                      ),
                      // 자연소리 같이 듣는 중이면 가는 선 아래에 표시
                      _natureBadge(const EdgeInsets.only(top: 0), withLine: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
            ],
          ),
        ),
      ],
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

    if (!lyricsProvider.hasLyrics) {
      return const SizedBox(height: 36);
    }
    // 시간 없는 가사: 지금 부르는 줄을 알 수 없어서 → "가사 보기 ›" (누르면 가사 화면)
    if (lyricsProvider.lyrics.isEmpty) {
      return SizedBox(
        height: 36,
        child: Center(
          child: GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LyricsScreen()));
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 누르기 쉽게 자리만 넓게
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr.viewLyrics,
                      style: TextStyle(
                          color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
                  SizedBox(width: 1),
                  Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 17),
                ],
              ),
            ),
          ),
        ),
      );
    }
    lyricsProvider.updateCurrentLine(playerProvider.position);
    if (lyricsProvider.currentLineIndex < 0) return const SizedBox(height: 36); // 전주
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
                            letterSpacing: -0.5,
                            shadows: const [Shadow(color: Color(0x59000000), blurRadius: 6)]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 0),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showArtistInfo(context, song),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(song.artistDisplay,
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.8),
                                    fontSize: 11,
                                    shadows: const [Shadow(color: Color(0x59000000), blurRadius: 6)]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          // 누를 수 있다는 표시
                          Icon(Icons.chevron_right_rounded, size: 15, color: baseColor.withOpacity(0.45)),
                        ],
                      ),
                    ),
                    // 🌿 자연소리 섞는 중 (파란포토는 가운데 박스에 나오니까 여기선 빼기)
                    if (_albumArtStyle != 6) _natureBadge(const EdgeInsets.only(top: 6)),
                  ],
                ),
              ),
              // 하트: 켤 때 통통 + 작은 하트 셋이 위로 떠올라요
              _HeartButton(
                isFav: isFav,
                offColor: baseColor.withOpacity(0.92),
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  musicProvider.toggleFavorite(song);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(textDirection: TextDirection.ltr, // 재생 막대는 아랍어에서도 왼쪽→오른쪽
          child: TweenAnimationBuilder<double>(
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
          ),
          Row(
            textDirection: TextDirection.ltr,
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
            textDirection: TextDirection.ltr, // ⏮ ▶ ⏭ 순서는 어느 언어나 같게
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
    showAddToPlaylistSheet(context, song); // 공통 고르는 창
  }

  static void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ParanSheetFrame(
        child: _SleepTimerDialog(playerProvider: playerProvider, primaryColor: context.read<ThemeProvider>().primaryColor),
      ),
    );
  }

  static void _showSleepWheelPickerDirect(BuildContext context, PlayerProvider playerProvider, Color _unusedColor) {
    final primaryColor = context.read<ThemeProvider>().primaryColor; // 포인트 색
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    Duration picked = const Duration(minutes: 30);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF32302C) : const Color(0xFFF4EFE5),
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
                // 제목 가운데 + 오른쪽 ✕
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          children: [
                            Text(tr.sleepAskDuration,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(tr.sleepFadeHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                      ParanCloseX(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: textColor, fontSize: 20),
                      ),
                    ),
                    child: Directionality(textDirection: TextDirection.ltr, // 아랍어에서 '분' 글자가 숫자와 겹쳐서 왼쪽→오른쪽으로
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    )),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ParanSheetFrame(
        child: _SpeedDialog(playerProvider: playerProvider, primaryColor: pointColorOf(context)),
      ),
    );
  }

  void _showFarewellAndExit(BuildContext context) {
    const farewellAsset = 'assets/greet_outro.mp3'; // 끝인사: 어느 언어나 멜로디 (한국어 목소리는 '파란소리 자료'에 보관)
    context.read<PlayerProvider>().player.setVolume(0.12);
    if (context.read<ThemeProvider>().voiceGreetingEnabled) { // 한국어는 목소리 · 해외는 멜로디
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
            duration: const Duration(milliseconds: 7000), // 끝인사: 서서히 어둡게
            curve: Curves.easeIn,
            builder: (_, darkValue, __) => Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: farewellImage(context),
                  onError: (_, __) {},
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(darkValue),
                    BlendMode.darken,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: const FarewellTitle(), // Paransori + 소리 막대 + 한 줄 인사
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 6500), () async {
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

  Widget _buildBottomBarItem(
      BuildContext context, {
        IconData? icon,
        String? customIcon,
        required String label,
        required bool isActive,
        required VoidCallback onTap,
        bool showNew = false, // 아이콘 오른쪽 위 작은 NEW
      }) {
    const baseColor = Colors.white;
    // 켜진 건 또렷한 흰색, 꺼진 건 흐리게 (사진 위라서 큰 건 흰색 유지)
    final iconColor = isActive ? baseColor : baseColor.withOpacity(0.45);
    final point = context.watch<ThemeProvider>().primaryColor; // 켜짐 점 = 포인트 색
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
        Column(
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
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? point : Colors.transparent,
              ),
            ),
          ],
        ),
            if (showNew)
              Positioned(
                top: -6,
                left: 11,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: point, borderRadius: BorderRadius.circular(5)),
                  child: const Text('NEW',
                      style: TextStyle(
                          color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 0.3, height: 1.2)),
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
    // 고른 칸은 먹색 (다크 모드는 크림색) — 포인트 색과 상관없이 늘 같게
    final dark = context.read<ThemeProvider>().isDarkMode;
    final blue = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final onBlue = dark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final l = AppLocalizations.of(context)!;
    final styles = [
      (1, l.styleCD, Icons.album_outlined),
      (6, tr.paranPhoto, Icons.photo_outlined),
      (3, l.styleCard, Icons.image_outlined),
    ];
    return showParanSheet(
      context,
      title: l.playerStyle,
      builder: (ctx, setSheet) => ParanCard(
        children: [
          for (final st in styles) ...[
            ParanRow(
              icon: st.$3,
              title: st.$2,
              trailingText: st.$1 == 6 ? tr.recommended : null,
              selected: current == st.$1,
              onTap: () {
                current = st.$1;
                onPick(current);
                setSheet(() {});
                // 앨범은 바로 닫지 않고 아래에서 인화 모양을 고르게
                if (current != 3 || onPrintPick == null) Navigator.pop(ctx);
              },
            ),
            if (st.$1 == 3 && current == 3 && onPrintPick != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(46, 8, 14, 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in [tr.printBasic, tr.printPolaroid, tr.printTape, tr.printStacked, tr.printRounded].asMap().entries)
                      GestureDetector(
                        onTap: () {
                          printStyle = e.key;
                          onPrintPick(e.key);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: printStyle == e.key ? blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: printStyle == e.key ? blue : const Color(0x33888888)),
                          ),
                          child: Text(e.value,
                              style: TextStyle(
                                  color: printStyle == e.key ? onBlue : const Color(0xFF8A8378),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
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
  _PlayerScreenState._sheetBlue = context.watch<ThemeProvider>().primaryColor; // 셔플·반복·스타일 표시 = 포인트 색
  const accent = Color(0xFF8A8378); // 메뉴 아이콘은 차분한 회색
  void vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
  return [
    // TV로 듣기 (곡이 재생 중일 때만)
    if (p.currentSong != null) castMenuRow(context, textColor),
    _PlayerScreenState._playerSheetItem(
      context, Icons.shuffle_rounded, tr.shufflePlay, accent, textColor,
      () { vib(); p.toggleShuffle(); },
      trailing: _PlayerScreenState._sheetMiniSwitch(p.isShuffled),
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.repeat_rounded, tr.repeatPlay, accent, textColor,
      () { vib(); p.toggleLoopMode(); },
      trailing: _PlayerScreenState._sheetRepeatChips(p),
      trailingTappable: true,
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.nightlight_round, tr.sleepTimer, accent, textColor,
      () { vib(); showPlayerSleepMenu(context); },
      trailing: _PlayerScreenState._sheetValue(_PlayerScreenState._sheetSleepLabel(p)),
      arrow: true,
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.style, tr.playerScreen, accent, textColor,
      () async { await showPlayerStyleMenu(context); onStyleChanged(); },
      trailing: _PlayerScreenState._styleThumbs(song, style, bgPath, bgIsFile, showNew: showNew),
    ),
    _PlayerScreenState._playerSheetItem(
      context, Icons.speed, tr.playbackSpeed, accent, textColor,
      () { showPlayerSpeedMenu(context); },
      trailing: _PlayerScreenState._sheetValue(_PlayerScreenState._sheetSpeedLabel(p.playbackSpeed)),
      arrow: true,
    ),
    // 자연소리 섞기 (재생화면 메뉴와 같은 줄, 곡이 재생 중일 때만)
    if (p.currentSong != null)
      AnimatedBuilder(
        animation: NatureOverlay.instance,
        builder: (_, __) => _PlayerScreenState._playerSheetItem(
          context, Icons.forest_outlined, tr.natureMix, accent, textColor,
          () { showNatureOverlaySheet(context); },
          trailing: _PlayerScreenState._sheetValue(NatureOverlay.instance.summary),
          arrow: true,
        ),
      ),
  ];
}

/// TV로 듣기 줄 (재생 화면 ⋯ · 곡 목록 ⋯ 같이 씀) — 지금 재생 중인 곡을 TV로
Widget castMenuRow(BuildContext context, Color textColor) {
  return AnimatedBuilder(
    animation: CastService.instance,
    builder: (_, __) {
      final cast = CastService.instance;
      final on = cast.isConnected;
      return _PlayerScreenState._playerSheetItem(
        context,
        Icons.sensors_rounded,
        tr.listenOnTv,
        on ? pointColorOf(context) : const Color(0xFF8A8378),
        textColor,
        () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          final p = context.read<PlayerProvider>();
          final song = p.currentSong;
          if (on) {
            showCastControlSheet(context,
                nowPlaying: song == null ? null : '${song.titleDisplay} · ${song.artistDisplay}');
          } else if (song != null) {
            showCastPickerSheet(context, onPick: (d) async {
              cast.onTrackEnded = () => p.playNext(); // TV에서 곡 끝나면 다음 곡
              final ok = await cast.connect(d, song);
              if (ok) p.player.pause();
              return ok;
            });
          }
        },
        trailing: on ? _PlayerScreenState._sheetValue(cast.device?.name ?? tr.connected) : null,
        arrow: true,
      );
    },
  );
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
/// 재생 화면 하트: 켤 때만 하트가 통통 튀고 작은 하트 셋이 흔들리며 위로 떠올라요 (끌 때는 조용히)
class _HeartButton extends StatefulWidget {
  final bool isFav;
  final Color offColor;
  final VoidCallback onTap;
  const _HeartButton({required this.isFav, required this.offColor, required this.onTap});

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton> with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE05A4F);
  static const _total = 1240.0; // ms (마지막 작은 하트가 끝날 때까지)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1240));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 하트 통통: 1 → 1.35 → 0.9 → 1 (처음 0.45초)
  double _pop(double ms) {
    if (!_c.isAnimating) return 1;
    final t = (ms / 450).clamp(0.0, 1.0);
    if (t < 0.35) return 1 + 0.35 * Curves.easeOut.transform(t / 0.35);
    if (t < 0.65) return 1.35 - 0.45 * ((t - 0.35) / 0.3);
    return 0.9 + 0.1 * ((t - 0.65) / 0.35);
  }

  /// 작은 하트 하나: 1초 동안 위로 74 올라가며 커졌다가 흐려짐
  Widget _mini(double ms, double startMs, double dx) {
    final t = (ms - startMs) / 1000;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final e = Curves.easeOut.transform(t);
    final op = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
    final wobble = math.sin(t * math.pi * 2) * 3; // 좌우로 살짝 흔들림
    return Transform.translate(
      offset: Offset(dx * e + wobble, -74 * e),
      child: Transform.scale(
        scale: 0.4 + 0.6 * e,
        child: Opacity(
          opacity: op.clamp(0.0, 1.0),
          child: const Icon(CupertinoIcons.heart_fill, color: _red, size: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!widget.isFav) _c.forward(from: 0); // 켤 때만
        widget.onTap();
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final ms = _c.value * _total;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_c.isAnimating) ...[
                  _mini(ms, 0, -14),
                  _mini(ms, 120, 4),
                  _mini(ms, 240, 16),
                ],
                Transform.scale(
                  scale: _pop(ms),
                  child: Icon(
                    widget.isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: widget.isFav ? _red : widget.offColor,
                    size: 20,
                    // 밝은 사진에서도 보이게 (어두운 사진에선 거의 티 안 남)
                    shadows: const [
                      Shadow(color: Color(0x73000000), blurRadius: 6),
                      Shadow(color: Color(0x40000000), blurRadius: 1.5, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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
    // 포인트 색 따라가기 (기본 파란소리 색이면 원래 하늘색 그대로)
    final point = context.watch<ThemeProvider>().primaryColor;
    final isDefault = point.value == 0xFF2589E8;
    final isInk = point.computeLuminance() < 0.08; // 먹색처럼 아주 어두운 색은 사진 위에서 안 보여서 흰빛으로
    final dim = isDefault
        ? _dim
        : isInk
            ? Colors.white.withOpacity(0.55)
            : point.withOpacity(0.7);
    final bright = isDefault
        ? _bright
        : isInk
            ? Colors.white.withOpacity(0.95)
            : Color.lerp(point, Colors.white, 0.45)!.withOpacity(0.8);
    final glow = isDefault ? const Color(0xFF7FB8F0) : bright.withOpacity(1);
    final base = isDefault
        ? (widget.style.color ?? _dim)
        : isInk
            ? Colors.white.withOpacity(0.7)
            : Color.lerp(point, Colors.white, 0.3)!.withOpacity(0.8);
    return TweenAnimationBuilder<double>(
      // 재생 중 1 → 일시정지 0 (원래 색으로 부드럽게)
      tween: Tween(end: widget.moving ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, f, _) => AnimatedBuilder(
        animation: _c,
        builder: (context, __) {
          final t = Curves.easeInOut.transform(_c.value);
          final breath = Color.lerp(dim, bright, t)!;
          return Text(
            widget.text,
            style: widget.style.copyWith(
              color: Color.lerp(base, breath, f),
              shadows: [
                Shadow(
                  color: glow.withOpacity(0.25 * t * f),
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
      backgroundColor: isDarkMode ? const Color(0xFF32302C) : const Color(0xFFF4EFE5),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목 가운데 + 오른쪽 ✕
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          children: [
                            Text(tr.sleepAskDuration,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(tr.sleepFadeHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                      ParanCloseX(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: textColor, fontSize: 20),
                      ),
                    ),
                    child: Directionality(textDirection: TextDirection.ltr, // 아랍어에서 '분' 글자가 숫자와 겹쳐서 왼쪽→오른쪽으로
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    )),
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
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(AppLocalizations.of(context)!.timerCancel, maxLines: 1),
                    ),
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = context.watch<ThemeProvider>().primaryColor; // 포인트 색 (설정에서 고름)
    final textColor = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.playbackSpeed,
                style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ),
          const SizedBox(height: 12),
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


/// 제목 카드가 아주 천천히 위아래로 둥실 (4초에 한 번 · 위아래 2.5)
/// 폰에서 '애니메이션 줄이기'를 켜 두면 움직이지 않음
class _CardFloat extends StatefulWidget {
  final Widget child;
  const _CardFloat({required this.child});

  @override
  State<_CardFloat> createState() => _CardFloatState();
}

class _CardFloatState extends State<_CardFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -2.5 + 5 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
