import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../utils/title_font.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';
import '../providers/sound_mix_provider.dart';
import '../widgets/logo_shine.dart';
import '../widgets/paran_dialog.dart';
import '../l10n/locale_holder.dart';
import '../utils/rest_music_catalog.dart';

class SleepFocusScreen extends StatefulWidget {
  const SleepFocusScreen({super.key});

  @override
  State<SleepFocusScreen> createState() => _SleepFocusScreenState();
}

class _SleepFocusScreenState extends State<SleepFocusScreen> {
  /// 칸 이름 (저장은 한국어 그대로, 화면엔 언어에 맞게)
  static String _catLabel(String c) => switch (c) {
        '전체' => tr.all,
        '잠들기' => tr.sleepTabLabel,
        '집중' => tr.focusLabel,
        '쉼' => tr.breakTabLabel,
        _ => c,
      };
  String _selectedCategory = '전체';

  /// 라디오·자연과 같은 탭: 박스 없이 글자 + 고른 탭만 아래 진한 밑줄
  Widget _restTab(String category, bool isDarkMode) {
    final selected = _selectedCategory == category;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          setState(() => _selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? (isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F)) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // 글자가 커도 한 줄 (넘치면 칸에 맞게 살짝 줄임)
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _catLabel(category),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                color: selected
                    ? (isDarkMode ? Colors.white : const Color(0xFF17140F))
                    : baseColor.withOpacity(0.55),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 곡 누르기: 듣는 곡이면 멈춤/다시, 아니면 이 탭 곡을 차례로 틀기
  Future<void> _tapTrack(List<RestTrack> list, int index, bool isThis, bool playing) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pp = context.read<PlayerProvider>();
    if (isThis) {
      playing ? await pp.pauseNatureSound() : await pp.resumeNatureSound();
      return;
    }
    final mix = context.read<SoundMixProvider>();
    if (mix.isPlaying) mix.stopAll(); // 믹스와 겹치지 않게
    await pp.playRest(list, index);
  }

  /// 수면 타이머: 아래에서 올라오는 창 (다른 창과 같은 색 + 오른쪽 위 ✕)
  void _showTimer(bool isDarkMode) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pp = context.read<PlayerProvider>();
    final textColor = isDarkMode ? Colors.white : const Color(0xFF17140F);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF323232) : const Color(0xFFF4EFE5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    for (final m in const [15, 30, 60, 90])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              pp.setSleepTimer(Duration(minutes: m));
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: textColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(tr.durM(m),
                                    maxLines: 1,
                                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (pp.isSleepTimerActive)
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: TextButton(
                    onPressed: () {
                      pp.cancelSleepTimer();
                      Navigator.pop(ctx);
                    },
                    child: Text(tr.timerOff, style: TextStyle(color: textColor.withOpacity(0.5))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 전체 탭 묶음 제목: 이름 · 개수 뒤로 가는 선 (자연과 같음)
  Widget _groupTitle(String category, int count, bool first, Color baseColor) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 6 : 22, bottom: 6),
      child: Row(
        children: [
          Flexible(
            child: Text(_catLabel(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: baseColor.withOpacity(0.72), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Text('$count',
              style: GoogleFonts.quicksand(color: baseColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: baseColor.withOpacity(0.18))),
        ],
      ),
    );
  }

  Widget _trackRow(RestTrack t, int i, List<RestTrack> list, String? playingFile, bool playing,
      Color baseColor, Color point) {
    final isThis = playingFile == t.file;
    final nowPlaying = isThis && playing;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapTrack(list, i, isThis, playing),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        // 듣는 중: 자연·라디오와 같은 연한 강조색 칸
        color: isThis ? point.withOpacity(0.08) : Colors.transparent,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/sleep_bg.jpg',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                // 같은 사진이라도 곡마다 보이는 자리를 조금씩 다르게
                alignment: Alignment(-0.9 + (restTracks.indexOf(t) % 4) * 0.6, 0),
                cacheWidth: 200,
                errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: const Color(0xFF3E4A66)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: baseColor,
                          fontSize: 14.5,
                          fontWeight: isThis ? FontWeight.w800 : FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${_catLabel(t.category)} · ${t.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 오른쪽 칸은 늘 같은 크기 (바뀌어도 줄이 안 움직이게)
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: nowPlaying
                    ? _RestEqBars(color: point)
                    : Icon(Icons.play_arrow_rounded,
                        color: baseColor.withOpacity(isThis ? 0.7 : 0.3), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF242424) : const Color(0xFFEDE7DA);
    final themePoint = context.watch<ThemeProvider>().primaryColor;
    final point = themePoint.value == 0xFF2589E8
        ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
        : themePoint;
    // 듣는 곡 · 재생 여부 · 타이머가 바뀔 때만 다시 그림
    final playingFile = context.select<PlayerProvider, String?>((p) => p.restTrack?.file);
    final playing = context.select<PlayerProvider, bool>((p) => p.isPlaying);
    final timerOn = context.select<PlayerProvider, bool>((p) => p.isSleepTimerActive);

    final categories = ['전체', '잠들기', '집중', '쉼'];
    final list = _selectedCategory == '전체'
        ? restTracks
        : restTracks.where((t) => t.category == _selectedCategory).toList();

    final rows = <Widget>[];
    String? lastCat;
    for (var i = 0; i < list.length; i++) {
      final t = list[i];
      if (_selectedCategory == '전체' && t.category != lastCat) {
        final count = list.where((x) => x.category == t.category).length;
        rows.add(_groupTitle(t.category, count, lastCat == null, baseColor));
      } else if (rows.isNotEmpty) {
        rows.add(Divider(height: 1, color: baseColor.withOpacity(0.1)));
      }
      lastCat = t.category;
      rows.add(_trackRow(t, i, list, playingFile, playing, baseColor, point));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: baseColor, size: 20),
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        // 라디오·자연·휴식 같은 위쪽: 앱 아이콘 + 제목 / 설명
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 + 제목(회색 빛) / 아래 설명 — 홈 로고와 같은 짜임 (해외는 그 나라 말)
            Flexible(child: MenuTitle(title: tr.catRest, sub: tr.catRestSub, isDark: isDarkMode)),
          ],
        ),
        actions: [
          // 수면 타이머 (켜져 있으면 포인트 색)
          IconButton(
            onPressed: () => _showTimer(isDarkMode),
            icon: Icon(timerOn ? Icons.bedtime : Icons.bedtime_outlined,
                color: timerOn ? point : baseColor.withOpacity(0.7), size: 22),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12), width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in categories) _restTab(c, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: list.isEmpty
            // 아직 곡이 없는 탭: 준비 중 안내
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.nightlight_round, size: 56, color: baseColor.withOpacity(0.25)),
                    const SizedBox(height: 16),
                    Text(
                      tr.comingSoonTitle,
                      style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.comingSoonCategory(_catLabel(_selectedCategory)),
                      style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 13),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(children: rows),
              ),
      ),
    );
  }
}

/// 듣는 중 막대 3개 (자연 목록과 같은 모양)
class _RestEqBars extends StatefulWidget {
  final Color color;
  const _RestEqBars({required this.color});

  @override
  State<_RestEqBars> createState() => _RestEqBarsState();
}

class _RestEqBarsState extends State<_RestEqBars> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(vsync: this, duration: Duration(milliseconds: 1400 + i * 400))
        ..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, __) => Container(
              width: 4,
              height: 6 + _ctrls[i].value * 14,
              decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
            ),
          );
        }),
      ),
    );
  }
}
