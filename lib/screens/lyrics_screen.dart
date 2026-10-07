import 'dart:convert';
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
  final Map<int, GlobalKey> _lineKeys = {}; // 줄마다 위치 (지금 줄로 부드럽게 이동)
  int _lastLine = -1;
  final ScrollController _plainController = ScrollController(); // 시간 없는 가사용
  DateTime _userScrolledAt = DateTime(2000); // 손으로 움직이면 잠깐 자동 멈춤

  @override
  void initState() {
    super.initState();
    _loadBgList(); // 인터넷 목록 받기 (못 받으면 기본 목록)
    SharedPreferences.getInstance().then((p) {
      // 고른 사진은 파일 이름으로 기억 (예전 번호로 저장한 것도 알아보기)
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

  bool get _light => _bg != 0 && _kLightBgs.contains(_bg);

  /// 오른쪽 아래 워터마크 — 한국: 파란소리 | Paransori / 해외: ParanSori (한 줄, 은은하게)
  Widget _watermark(BuildContext context) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final c = _ink.withOpacity(_light ? 0.72 : 0.88); // 더 잘 보이게
    final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)];
    final en = Text(
      ko ? 'Paransori' : 'ParanSori',
      style: GoogleFonts.quicksand(
          color: c, fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: 2.2, shadows: shadow),
    );
    if (!ko) return en;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('파란소리',
            style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.6, shadows: shadow)),
        Container(width: 1, height: 13, margin: const EdgeInsets.symmetric(horizontal: 10), color: c),
        en,
      ],
    );
  }

  Color get _ink => _light ? const Color(0xFF17140F) : Colors.white;

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

  /// 🖼 배경 고르기 창
  void _pickBackground() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    showParanSheet(
      context,
      title: '가사 배경',
      builder: (ctx, setSheet) {
        Widget tile(int i) {
          final selected = _bg == i;
          return GestureDetector(
            onTap: () async {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() => _bg = i);
              _lastBg = i;
              setSheet(() {});
              final p = await SharedPreferences.getInstance();
              await p.setString('lyricsBgFile', _bgs[(i - 1).clamp(0, _bgs.length - 1)].file);
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

        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 9 / 16,
          children: [for (var i = 1; i <= _kLyricsBgCount; i++) tile(i)], // 사진만 (단색 칸 뺌)
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;


    lyricsProvider.updateCurrentLine(playerProvider.position);

    // 지금 부르는 줄이 바뀔 때만, 가사 칸의 위쪽 1/3 자리로 부드럽게 옮기기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 손으로 움직인 지 4초 안 됐으면 자동으로 안 움직이기
      if (DateTime.now().difference(_userScrolledAt).inSeconds < 4) return;
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
            // ⏱ 박자 맞추기 (시간 있는 가사일 때만)
            if (lyricsProvider.lyrics.isNotEmpty)
              IconButton(
                onPressed: () => _pickOffset(lyricsProvider),
                icon: Icon(Icons.timer_outlined, color: _ink.withOpacity(0.85)),
              ),
            // 🖼 배경 사진 고르기
            IconButton(
              onPressed: _pickBackground,
              icon: Icon(Icons.wallpaper_rounded, color: _ink.withOpacity(0.85)),
            ),
            IconButton(
              onPressed: () {
                final song = playerProvider.currentSong;
                if (song != null) {
                  lyricsProvider.fetchLyrics(song.titleDisplay, song.artistDisplay, force: true);
                }
              },
              icon: Icon(Icons.refresh, color: _ink.withOpacity(0.7)),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 사진
            if (_bg != 0)
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
            if (_bg != 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _light
                        ? [
                            const Color(0xFFF4EFE5).withOpacity(_kBusyBgs.contains(_bg) ? 0.72 : 0.55),
                            const Color(0xFFF4EFE5).withOpacity(_kBusyBgs.contains(_bg) ? 0.5 : 0.3),
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
            if (_bg != 0)
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
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 70,
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(song.titleDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                shadows: shadow)),
                        const SizedBox(height: 3),
                        Text(song.artistDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                // 밝은 사진: 더 진하고 살짝 굵게 + 흰 빛 테두리
                                color: _ink.withOpacity(_light ? 0.85 : 0.68),
                                fontSize: 13,
                                fontWeight: _light ? FontWeight.w600 : FontWeight.w400,
                                shadows: _light
                                    ? [Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 6)]
                                    : shadow)),
                        const SizedBox(height: 12),
                        // 노래가 어디쯤인지 (얇은 막대)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(height: 2.5, color: _ink.withOpacity(0.2)),
                              FractionallySizedBox(
                                widthFactor: f,
                                child: Container(height: 2.5, color: _ink.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            // 워터마크 (캡처해서 공유할 때 파란소리가 보이게)
            if (_bg != 0)
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 18,
                child: IgnorePointer(
                  // 알록달록한 사진 위에서도 보이게 연한 알약 배경
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _light ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _watermark(context),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lyrics_outlined, size: 64, color: ink.withOpacity(0.45)),
              const SizedBox(height: 16),
              Text(
                lyricsProvider.errorMessage.isEmpty
                    ? AppLocalizations.of(context)!.lyricsSearchPrompt
                    : lyricsProvider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: sub, fontSize: 15.5, shadows: shadow),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final song = playerProvider.currentSong;
                  if (song != null) {
                    lyricsProvider.fetchLyrics(song.titleDisplay, song.artistDisplay);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ink.withOpacity(_light ? 0.9 : 0.18),
                  foregroundColor: _light ? const Color(0xFFF4EFE5) : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(AppLocalizations.of(context)!.lyricsSearchButton,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (lyricsProvider.lyrics.isNotEmpty) {
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
                  playerProvider.seekTo(lyricsProvider.lyrics[index].time);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: index == lyricsProvider.currentLineIndex ? ink : ink.withOpacity(0.5),
                        fontSize: index == lyricsProvider.currentLineIndex ? 19 : 15.5,
                        height: 1.4,
                        fontWeight:
                            index == lyricsProvider.currentLineIndex ? FontWeight.w800 : FontWeight.w500,
                        shadows: shadow,
                      ),
                      child: Text(lyricsProvider.lyrics[index].text.trim(), textAlign: TextAlign.center),
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
    return NotificationListener<UserScrollNotification>(
      onNotification: (_) {
        _userScrolledAt = DateTime.now();
        return false;
      },
      child: SingleChildScrollView(
      controller: _plainController,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          plain,
          style: TextStyle(color: ink, fontSize: 15.5, height: 1.8, shadows: shadow),
          textAlign: TextAlign.center,
        ),
      ),
    ),
    );
  }
}
