# 파란소리: 가사 배경 사진 고르기 (가사 화면 새로)
# 실행: C:\apps\mp3_player_new 에서  python apply_lyrics_bg.py
# - 원래 가사 화면은 backup_lyrics_bg 폴더에 저장돼요
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
if "_kLyricsBgBase" in old:
    print("[참고] 이미 바뀌어 있어요. 그대로 둘게요.")
    sys.exit(0)
B = os.path.join(ROOT, "backup_lyrics_bg", "screens")
os.makedirs(B, exist_ok=True)
shutil.copy2(P, os.path.join(B, "lyrics_screen.dart"))
NEW = r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (lyricsProvider.lyrics.isNotEmpty && _scrollController.hasClients) {
        final index = lyricsProvider.currentLineIndex;
        const itemHeight = 56.0;
        final offset = (index * itemHeight) -
            (_scrollController.position.viewportDimension / 2) +
            itemHeight / 2;
        _scrollController.animateTo(
          offset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
          title: Text(AppLocalizations.of(context)!.lyrics, style: TextStyle(color: _ink)),
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
            SafeArea(child: _buildBody(lyricsProvider, playerProvider, primaryColor)),
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
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        itemCount: lyricsProvider.lyrics.length,
        itemBuilder: (context, index) {
          final isCurrentLine = index == lyricsProvider.currentLineIndex;
          return GestureDetector(
            onTap: () {
              playerProvider.seekTo(lyricsProvider.lyrics[index].time);
            },
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCurrentLine ? ink : ink.withOpacity(0.5),
                  fontSize: isCurrentLine ? 19 : 15,
                  fontWeight: isCurrentLine ? FontWeight.w800 : FontWeight.w500,
                  shadows: shadow,
                ),
                child: Text(lyricsProvider.lyrics[index].text, textAlign: TextAlign.center),
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        lyricsProvider.plainLyrics,
        style: TextStyle(color: ink, fontSize: 16, height: 2, shadows: shadow),
        textAlign: TextAlign.center,
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
print("   문제가 있으면 backup_lyrics_bg 폴더의 원본으로 되돌릴 수 있어요.")
