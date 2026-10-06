# 파란소리: 가사 배경 사진 + 위쪽 고른 간격 + 워터마크(한 줄) + 제목·가수
# 실행: C:\apps\mp3_player_new 에서  python apply_lyrics_bg4.py
# - 원래 가사 화면은 backup_lyrics_bg4 폴더에 저장돼요
import os, sys, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
ROOT = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(ROOT, "lib", "screens", "lyrics_screen.dart")
if not os.path.exists(P):
    print("[실패] lib/screens/lyrics_screen.dart 를 못 찾았어요. 이 파일을 mp3_player_new 폴더에 두고 실행해 주세요.")
    sys.exit(1)
with open(P, "r", encoding="utf-8", newline="") as f:
    old = f.read()
if "titleSpacing: 0," in old and "_watermark" in old:
    print("[참고] 이미 바뀌어 있어요. 그대로 둘게요.")
    sys.exit(0)
B = os.path.join(ROOT, "backup_lyrics_bg4", "screens")
os.makedirs(B, exist_ok=True)
shutil.copy2(P, os.path.join(B, "lyrics_screen.dart"))
NEW = r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/paran_dialog.dart';

/// 가사 배경 사진 (수파베이스 app-images/lyrics)
const _kLyricsBgBase =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images/lyrics';
const _kLyricsBgCount = 11;

/// 밝은 사진 → 가사를 먹색으로 (나머지는 흰색)
const _kLightBgs = {4, 6, 7, 8, 9, 10, 11};

/// 화려한 사진 → 위에 크림색 막을 조금 더
const _kBusyBgs = {8, 9, 10, 11};

String _bgUrl(int i) => '$_kLyricsBgBase/lyrics_bg_$i.jpg';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _bg = 1; // 0 = 사진 없이(기본), 1~11 = 사진
  final Map<int, GlobalKey> _lineKeys = {}; // 줄마다 위치 (지금 줄로 부드럽게 이동)
  int _lastLine = -1;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final v = p.getInt('lyricsBg');
      if (v != null && mounted) setState(() => _bg = v.clamp(0, _kLyricsBgCount));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _light => _bg != 0 && _kLightBgs.contains(_bg);

  /// 오른쪽 아래 워터마크 — 한국: 파란소리 | Paransori / 해외: ParanSori (한 줄, 은은하게)
  Widget _watermark(BuildContext context) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final c = _ink.withOpacity(_light ? 0.5 : 0.62);
    final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)];
    final en = Text(
      ko ? 'Paransori' : 'ParanSori',
      style: GoogleFonts.quicksand(
          color: c, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 2.4, shadows: shadow),
    );
    if (!ko) return en;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('파란소리',
            style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w500, letterSpacing: 1.6, shadows: shadow)),
        Container(width: 0.8, height: 10, margin: const EdgeInsets.symmetric(horizontal: 9), color: c),
        en,
      ],
    );
  }

  Color get _ink => _light ? const Color(0xFF17140F) : Colors.white;

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
              setSheet(() {});
              final p = await SharedPreferences.getInstance();
              await p.setInt('lyricsBg', i);
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
          children: [for (var i = 0; i <= _kLyricsBgCount; i++) tile(i)],
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
      final index = lyricsProvider.currentLineIndex;
      if (lyricsProvider.lyrics.isEmpty || index == _lastLine) return;
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
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: _light ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          // "가사" 대신 노래 제목 + 가수 (캡처해서 공유할 때 무슨 노래인지 보이게)
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(playerProvider.currentSong?.titleDisplay ?? AppLocalizations.of(context)!.lyrics,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: _light ? null : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)])),
              if (playerProvider.currentSong != null)
                Text(playerProvider.currentSong!.artistDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _ink.withOpacity(0.65), fontSize: 12.5)),
            ],
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: _ink),
          ),
          actions: [
            // 🖼 배경 사진 고르기
            IconButton(
              onPressed: _pickBackground,
              icon: Icon(Icons.wallpaper_rounded, color: _ink.withOpacity(0.85)),
            ),
            IconButton(
              onPressed: () {
                final song = playerProvider.currentSong;
                if (song != null) {
                  lyricsProvider.fetchLyrics(song.titleDisplay, song.artistDisplay);
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
              CachedNetworkImage(
                imageUrl: _bgUrl(_bg),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (_, __) => Container(color: AppTheme.background),
                errorWidget: (_, __, ___) => Container(color: AppTheme.background),
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
                    child: ShaderMask(
                      // 위·아래 끝은 살짝 흐려지게
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                        stops: [0.0, 0.08, 0.88, 1.0],
                      ).createShader(r),
                      blendMode: BlendMode.dstIn,
                      child: _buildBody(lyricsProvider, playerProvider, primaryColor),
                    ),
                  ),
                  const Spacer(flex: 38),
                ],
              ),
            ),
            // 워터마크 (캡처해서 공유할 때 파란소리가 보이게)
            if (_bg != 0)
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 18,
                child: IgnorePointer(child: _watermark(context)),
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
      return SingleChildScrollView(
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
      );
    }

    // 시간 없는 가사: 빈 줄이 여러 개 겹친 건 하나로 정리해서 고른 간격으로
    final plain = lyricsProvider.plainLyrics.replaceAll('\r', '').replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n').trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          plain,
          style: TextStyle(color: ink, fontSize: 15.5, height: 1.8, shadows: shadow),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
"""
nl = "\r\n" if "\r\n" in old else "\n"
with open(P, "w", encoding="utf-8", newline="") as f:
    f.write(NEW.replace("\n", nl) if nl == "\r\n" else NEW)
print("[완료] 바꿨어요: screens/lyrics_screen.dart")
print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
print("   문제가 있으면 backup_lyrics_bg4 폴더의 원본으로 되돌릴 수 있어요.")
