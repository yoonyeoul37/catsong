import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sleep_timer_sheet.dart';
import '../widgets/schedule_sheet.dart';

class RadioPlayerScreen extends StatefulWidget {
  final RadioStation station;
  final List<RadioStation>? stationList;
  final int? currentIndex;
  const RadioPlayerScreen({
    super.key,
    required this.station,
    this.stationList,
    this.currentIndex,
  });

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _dialCtrl;   // 다이얼 포인터 진입 애니메이션
  late AnimationController _pulseCtrl;  // ON AIR 펄스
  late AnimationController _rotCtrl;   // 안쪽 원 회전
  late int _currentIdx;

  @override
  void initState() {
    super.initState();
    _dialCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _currentIdx = widget.currentIndex ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final radio = context.read<RadioProvider>();
      if (widget.stationList != null && widget.currentIndex != null) {
        radio.setQueue(widget.stationList!, widget.currentIndex!);
      }
      if (radio.currentStation?.name != widget.station.name ||
          (!radio.isPlaying && !radio.isLoading)) {
        radio.playStation(widget.station);
      }
      final streamUrl = widget.station.streamUrl;
      final stationName = widget.station.name;
      if (streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
        radio.fetchScheduleByUrl(stationName, streamUrl);
      } else if (stationName == 'MBC 표준FM' || stationName == 'MBC FM4U') {
        radio.fetchMbcSchedule(stationName);
      } else if (stationName == 'SBS 파워FM' || stationName == 'SBS 러브FM') {
        radio.fetchSbsSchedule(stationName);
      } else {
        radio.fetchSchedule(stationName);
      }
    });
  }

  @override
  void dispose() {
    _dialCtrl.dispose();
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  // KBS/MBC/SBS 한국 방송만 편성표 지원
  bool _isKoreanBroadcast(String name) {
    final lower = name.toLowerCase();
    return lower.contains('kbs') ||
        name.contains('MBC') ||
        name.contains('SBS');
  }

  String _getBroadcaster(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kbs')) return 'KBS';
    if (lower.contains('mbc')) return 'MBC';
    if (lower.contains('sbs')) return 'SBS';
    if (lower.contains('cbs')) return 'CBS';
    if (lower.contains('ebs')) return 'EBS';
    if (lower.contains('ytn')) return 'YTN';
    if (lower.contains('tbs')) return 'TBS';
    if (lower.contains('tbn')) return 'TBN';
    if (lower.contains('obs')) return 'OBS';
    if (lower.contains('cpbc')) return 'CPBC';
    if (lower.contains('befm')) return 'BeFM';
    if (lower.contains('jtv')) return 'JTV';
    if (lower.contains('arirang')) return 'Arirang';
    if (lower.contains('gugak') || lower.contains('국악')) return '국악FM';
    if (lower.contains('국방')) return '국방FM';
    return '';
  }

  Color _brandColor(String bc) {
    const colors = {
      'KBS': Color(0xFF1565C0),
      'MBC': Color(0xFF6A1B9A),
      'SBS': Color(0xFFB71C1C),
      'CBS': Color(0xFF1B5E20),
      'EBS': Color(0xFF0277BD),
      'YTN': Color(0xFF880E4F),
      'TBS': Color(0xFF004D40),
      'TBN': Color(0xFF2E7D32),
      'OBS': Color(0xFF0D47A1),
      'CPBC': Color(0xFF6D4C41),
      'BeFM': Color(0xFFE65100),
      'JTV': Color(0xFF00695C),
    };
    return colors[bc] ?? const Color(0xFF37474F);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final state = radioProvider.playerState;
    final current = (widget.stationList != null && _currentIdx < widget.stationList!.length)
        ? widget.stationList![_currentIdx]
        : (radioProvider.currentStation ?? widget.station);
    final isPlaying = state == RadioPlayerState.playing;
    final isLoading = state == RadioPlayerState.loading;
    final isError = state == RadioPlayerState.error;
    final sleep = radioProvider.sleepRemaining;

    // 재생 중이면 안쪽 원 회전
    if (isPlaying) {
      _rotCtrl.repeat();
    } else {
      _rotCtrl.stop();
    }
    final broadcaster = _getBroadcaster(current.name);
    final bcColor = _brandColor(broadcaster);
    final freq = current.frequency ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0e0e0e),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_isKoreanBroadcast(current.name))
                  _BottomBarItem(
                    icon: Icons.format_list_bulleted,
                    label: '편성표',
                    hasIndicator: radioProvider.scheduleList.isNotEmpty,
                    primaryColor: primaryColor,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _ScheduleListSheet(stationName: current.name),
                    ),
                  ),
                _BottomBarItem(
                  icon: Icons.bedtime_outlined,
                  label: '수면',
                  hasIndicator: radioProvider.isSleepTimerActive,
                  primaryColor: primaryColor,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SleepTimerSheet(),
                  ),
                ),
                _BottomBarItem(
                  icon: Icons.schedule,
                  label: '예약',
                  hasIndicator: radioProvider.schedules.isNotEmpty,
                  primaryColor: primaryColor,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const ScheduleSheet(),
                  ),
                ),
                _BottomBarItem(
                  icon: Icons.favorite_border,
                  label: '즐겨찾기',
                  hasIndicator: false,
                  primaryColor: primaryColor,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => _FavoritesSheet(primaryColor: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 90),

                  // ── 다이얼 ──
                  _DialWidget(
                    broadcaster: broadcaster.isNotEmpty
                        ? broadcaster
                        : current.name.substring(0, current.name.length.clamp(0, 4)).toUpperCase(),
                    bcColor: bcColor,
                    freq: freq,
                    isPlaying: isPlaying,
                    pulseCtrl: _pulseCtrl,
                    dialCtrl: _dialCtrl,
                    rotCtrl: _rotCtrl,
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 12),

                  // ── 채널명 ──
                  Text(
                    current.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),


                  const SizedBox(height: 16),

                  // ── 편성표 ──
                  if (radioProvider.currentProgram != null && _isKoreanBroadcast(current.name))
                    _ProgramCard(
                      program: radioProvider.currentProgram!,
                      primaryColor: primaryColor,
                      radioProvider: radioProvider,
                      freq: freq,
                    ),

                  const SizedBox(height: 12),

                  // ── 상태 뱃지 ──
                  _StatusBadge(state: state),

                  if (isError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        radioProvider.errorMessage ?? '재생에 실패했습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── 컨트롤 ──
                  _Controls(
                    isLoading: isLoading,
                    isError: isError,
                    isPlaying: isPlaying,
                    primaryColor: primaryColor,
                    currentIdx: _currentIdx,
                    stationList: widget.stationList,
                    radioProvider: radioProvider,
                    current: current,
                    onIndexChanged: (idx) => setState(() => _currentIdx = idx),
                  ),

                  const SizedBox(height: 16),

                  if (sleep != null) _SleepTimerBadge(remaining: sleep),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── 플로팅 상단: 뒤로가기 + 즐겨찾기 ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 뒤로가기
                  _FloatButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.expand_more, color: Colors.white, size: 24),
                  ),
                  // 즐겨찾기
                  _FloatButton(
                    onTap: () {
                      final wasFav = radioProvider.isFavorite(current.stationUuid);
                      radioProvider.toggleFavorite(current);
                      final overlay = Overlay.of(context);
                      final entry = OverlayEntry(
                        builder: (_) => Positioned(
                          bottom: 120, left: 0, right: 0,
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              builder: (_, value, child) => Opacity(
                                opacity: value,
                                child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      wasFav ? Icons.favorite_border : Icons.favorite,
                                      color: wasFav ? Colors.white54 : Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      wasFav ? '즐겨찾기에서 제거했습니다' : '즐겨찾기에 추가했습니다',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, decoration: TextDecoration.none),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                      overlay.insert(entry);
                      Future.delayed(const Duration(seconds: 2), () => entry.remove());
                    },
                    child: Icon(
                      radioProvider.isFavorite(current.stationUuid) ? Icons.favorite : Icons.favorite_border,
                      color: radioProvider.isFavorite(current.stationUuid) ? primaryColor : Colors.white,
                      size: 22,
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
}

// ══════════════════════════════════════════
// 다이얼 위젯
// ══════════════════════════════════════════
class _DialWidget extends StatelessWidget {
  final String broadcaster;
  final Color bcColor;
  final String freq;
  final bool isPlaying;
  final AnimationController pulseCtrl;
  final AnimationController dialCtrl;
  final AnimationController rotCtrl;
  final Color primaryColor;

  const _DialWidget({
    required this.broadcaster,
    required this.bcColor,
    required this.freq,
    required this.isPlaying,
    required this.pulseCtrl,
    required this.dialCtrl,
    required this.rotCtrl,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _DialPainter(bcColor: bcColor, primaryColor: primaryColor),
        child: Center(
          child: AnimatedBuilder(
            animation: rotCtrl,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 회전하는 원 테두리
                  Transform.rotate(
                    angle: rotCtrl.value * 2 * 3.14159,
                    child: CustomPaint(
                      size: const Size(150, 150),
                      painter: _InnerDialPainter(
                        bcColor: bcColor,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                  // 고정 텍스트 (역방향 회전으로 상쇄)
                  child!,
                ],
              );
            },
            child: Container(
              width: 150,
              height: 150,
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 브랜드명
                  Text(
                    broadcaster,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: broadcaster.length > 4 ? 18 : 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 재생 상태 점
                  AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (context, _) {
                      return Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? Color.lerp(primaryColor, primaryColor.withOpacity(0.3), pulseCtrl.value)!
                              : Colors.grey.shade800,
                          boxShadow: isPlaying
                              ? [BoxShadow(
                            color: primaryColor.withOpacity(0.5 * (1 - pulseCtrl.value)),
                            blurRadius: 8, spreadRadius: 2,
                          )]
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 다이얼 배경 CustomPainter (눈금 + 외곽 링 + 황금 포인터)
// 안쪽 원 회전 Painter (눈금 + 그라디언트 링)
class _InnerDialPainter extends CustomPainter {
  final Color bcColor;
  final Color primaryColor;
  const _InnerDialPainter({required this.bcColor, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // 배경 원 (그라디언트)
    final bgRect = Rect.fromCircle(center: center, radius: r);
    final bgGrad = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 1.0,
      colors: [
        Color.lerp(bcColor, const Color(0xFF2a2a2a), 0.7)!,
        const Color(0xFF1a1a1a),
        const Color(0xFF0d0d0d),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(center, r, Paint()..shader = bgGrad.createShader(bgRect));

    // 안쪽 원 그림자
    final shadowD = Paint()
      ..color = const Color(0xFF050505)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(4, 4), r, shadowD);
    final shadowL = Paint()
      ..color = const Color(0xFF252525)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center - const Offset(4, 4), r, shadowL);
    canvas.drawCircle(center, r, Paint()..shader = bgGrad.createShader(bgRect));

    // 테두리
    canvas.drawCircle(center, r - 1,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // 작은 장식 눈금 (안쪽 원 테두리)
    const tickCount = 16;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * 3.14159;
      final isMajor = i % 4 == 0;
      final tickLen = isMajor ? 7.0 : 4.0;
      final brightness = (cos(angle) * 0.5 + 0.5);
      final tickColor = Color.lerp(
        const Color(0xFF151515),
        const Color(0xFF353535),
        brightness,
      )!;
      final start = Offset(
        center.dx + (r - 2) * cos(angle),
        center.dy + (r - 2) * sin(angle),
      );
      final end = Offset(
        center.dx + (r - 2 - tickLen) * cos(angle),
        center.dy + (r - 2 - tickLen) * sin(angle),
      );
      canvas.drawLine(start, end,
          Paint()
            ..color = tickColor
            ..strokeWidth = isMajor ? 1.5 : 1.0
            ..strokeCap = StrokeCap.round);
    }

    // 브랜드 컬러 얇은 링 강조
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          bcColor.withOpacity(0.0),
          bcColor.withOpacity(0.4),
          bcColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bgRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, r - 3, ringPaint);
  }

  @override
  bool shouldRepaint(_InnerDialPainter old) => false;
}

class _DialPainter extends CustomPainter {
  final Color bcColor;
  final Color primaryColor;
  const _DialPainter({required this.bcColor, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR - 12;

    // ── 외곽 글로우 (브랜드 컬러)
    final glowPaint = Paint()
      ..color = bcColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, outerR - 2, glowPaint);

    // ── 어두운 그림자 (우하단)
    final shadowDark = Paint()
      ..color = const Color(0xFF050505)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center + const Offset(8, 8), outerR, shadowDark);

    // ── 밝은 그림자 (좌상단)
    final shadowLight = Paint()
      ..color = const Color(0xFF252525)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center - const Offset(8, 8), outerR, shadowLight);

    // ── 배경 원 (방사형 그라디언트로 입체감)
    final bgRect = Rect.fromCircle(center: center, radius: outerR);
    final bgGrad = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      radius: 1.0,
      colors: [
        const Color(0xFF242424), // 좌상단 밝게
        const Color(0xFF161616),
        const Color(0xFF0e0e0e), // 우하단 어둡게
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(center, outerR,
        Paint()..shader = bgGrad.createShader(bgRect));

    // ── 테두리 링 (상단 밝고 하단 어두운 그라디언트)
    final rimRect = Rect.fromCircle(center: center, radius: outerR);
    final rimGrad = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: [
        const Color(0xFF3a3a3a),
        const Color(0xFF1a1a1a),
        const Color(0xFF0a0a0a),
        const Color(0xFF1a1a1a),
        const Color(0xFF3a3a3a),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    canvas.drawCircle(
      center, outerR,
      Paint()
        ..shader = rimGrad.createShader(rimRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── 눈금
    const tickCount = 24;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * pi - pi / 2;
      final isMajor = i % 6 == 0;
      final tickLen = isMajor ? 11.0 : 5.0;
      // 상단 쪽 눈금은 좀 더 밝게
      final brightness = (cos(angle + pi / 2) * 0.5 + 0.5);
      final tickColor = Color.lerp(
        const Color(0xFF1a1a1a),
        const Color(0xFF444444),
        brightness,
      )!;
      final start = Offset(
        center.dx + (outerR - 5) * cos(angle),
        center.dy + (outerR - 5) * sin(angle),
      );
      final end = Offset(
        center.dx + (outerR - 5 - tickLen) * cos(angle),
        center.dy + (outerR - 5 - tickLen) * sin(angle),
      );
      canvas.drawLine(start, end,
          Paint()
            ..color = tickColor
            ..strokeWidth = isMajor ? 2.0 : 1.0
            ..strokeCap = StrokeCap.round);
    }

    // 황금 포인터 (상단에서 살짝 오른쪽)
    const pointerAngle = -pi / 2 + 0.4; // 약 23도 오른쪽
    final pointerTip = Offset(
      center.dx + (outerR - 6) * cos(pointerAngle),
      center.dy + (outerR - 6) * sin(pointerAngle),
    );
    final pointerBase = Offset(
      center.dx + (innerR - 30) * cos(pointerAngle),
      center.dy + (innerR - 30) * sin(pointerAngle),
    );
    final pointerPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pointerBase, pointerTip, pointerPaint);

    // 포인터 글로우
    final pointerGlowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(pointerBase, pointerTip, pointerGlowPaint);

    // 포인터 끝 원
    canvas.drawCircle(pointerTip, 4,
        Paint()..color = primaryColor..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DialPainter old) => false;
}

// ══════════════════════════════════════════
// 편성표 카드
// ══════════════════════════════════════════
class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final Color primaryColor;
  final RadioProvider radioProvider;
  final String freq;

  const _ProgramCard({
    required this.program,
    required this.primaryColor,
    required this.radioProvider,
    required this.freq,
  });

  @override
  Widget build(BuildContext context) {
    final title = program['program_title'] as String? ??
        program['Title'] as String? ??
        program['title'] as String? ?? '';
    final kbsStart = program['program_planned_start_time'] as String? ?? '';
    final kbsEnd = program['program_planned_end_time'] as String? ?? '';
    final mbcStart = program['StartTime'] as String? ?? '';
    final mbcEnd = program['EndTime'] as String? ?? '';
    final sbsStart = program['start_time'] as String? ?? '';
    final sbsEnd = program['end_time'] as String? ?? '';

    String timeStr = '';
    if (kbsStart.isNotEmpty && kbsEnd.isNotEmpty) {
      timeStr = '${radioProvider.formatScheduleTime(kbsStart)} ~ ${radioProvider.formatScheduleTime(kbsEnd)}';
    } else if (mbcStart.isNotEmpty && mbcEnd.isNotEmpty) {
      String fmt(String t) {
        if (t.length < 4) return t;
        int h = int.tryParse(t.substring(0, 2)) ?? 0;
        if (h >= 24) h -= 24;
        return '$h:${t.substring(2, 4)}';
      }
      timeStr = '${fmt(mbcStart)} ~ ${fmt(mbcEnd)}';
    } else if (sbsStart.isNotEmpty && sbsEnd.isNotEmpty) {
      timeStr = '$sbsStart ~ $sbsEnd';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFF080808), blurRadius: 10, offset: Offset(4, 4)),
          BoxShadow(color: Color(0xFF1e1e1e), blurRadius: 10, offset: Offset(-4, -4)),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.12),
              border: Border.all(color: primaryColor.withOpacity(0.25)),
            ),
            child: Icon(Icons.mic, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀 + LIVE 한 줄
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : '',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        '● LIVE',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // 시간 + MHz 한 줄
                Row(
                  children: [
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    const Spacer(),
                    if (freq.isNotEmpty)
                      Text(
                        freq,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// 상태 뱃지
// ══════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final RadioPlayerState state;
  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    String label;
    Color color;
    switch (state) {
      case RadioPlayerState.playing:
        return const SizedBox.shrink(); // 편성표 카드 안에 LIVE 표시
      case RadioPlayerState.loading:
        label = '접속 중...';
        color = primaryColor;
        break;
      case RadioPlayerState.error:
        label = '연결 실패';
        color = Colors.redAccent;
        break;
      case RadioPlayerState.paused:
        label = '일시정지';
        color = AppTheme.textHint;
        break;
      default:
        return const SizedBox(height: 28);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }
}

// ══════════════════════════════════════════
// 컨트롤
// ══════════════════════════════════════════
class _Controls extends StatelessWidget {
  final bool isLoading;
  final bool isError;
  final bool isPlaying;
  final Color primaryColor;
  final int currentIdx;
  final List<RadioStation>? stationList;
  final RadioProvider radioProvider;
  final RadioStation current;
  final ValueChanged<int> onIndexChanged;

  const _Controls({
    required this.isLoading,
    required this.isError,
    required this.isPlaying,
    required this.primaryColor,
    required this.currentIdx,
    required this.stationList,
    required this.radioProvider,
    required this.current,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이전
        _NeuButton(
          size: 56,
          onTap: () {
            final list = stationList;
            if (list != null) {
              final newIdx = currentIdx > 0 ? currentIdx - 1 : list.length - 1;
              onIndexChanged(newIdx);
              radioProvider.setQueue(list, newIdx);
              radioProvider.playStation(list[newIdx]);
            }
          },
          child: const Icon(Icons.skip_previous, color: Colors.white70, size: 26),
        ),
        const SizedBox(width: 28),
        // 재생/정지 (골드 링)
        GestureDetector(
          onTap: isLoading
              ? null
              : () {
            if (isError) {
              radioProvider.playStation(current);
            } else {
              radioProvider.togglePlayPause();
            }
          },
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF131313),
              boxShadow: [
                const BoxShadow(color: Color(0xFF080808), blurRadius: 14, offset: Offset(5, 5)),
                const BoxShadow(color: Color(0xFF1e1e1e), blurRadius: 14, offset: Offset(-5, -5)),
              ],
              border: Border.all(color: primaryColor, width: 2.5),
            ),
            child: isLoading
                ? Padding(
              padding: const EdgeInsets.all(22),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
            )
                : Icon(
              isError ? Icons.refresh : (isPlaying ? Icons.pause : Icons.play_arrow),
              color: primaryColor,
              size: 38,
            ),
          ),
        ),
        const SizedBox(width: 28),
        // 다음
        _NeuButton(
          size: 56,
          onTap: () {
            final list = stationList;
            if (list != null) {
              final newIdx = currentIdx < list.length - 1 ? currentIdx + 1 : 0;
              onIndexChanged(newIdx);
              radioProvider.setQueue(list, newIdx);
              radioProvider.playStation(list[newIdx]);
            }
          },
          child: const Icon(Icons.skip_next, color: Colors.white70, size: 26),
        ),
      ],
    );
  }
}

// 뉴모피즘 버튼
// ── 플로팅 버튼 ──
class _FloatButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _FloatButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── 하단 바 아이템 ──
class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasIndicator;
  final Color primaryColor;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.hasIndicator,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppTheme.textHint,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (hasIndicator)
            Positioned(
              right: -4, top: -2,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NeuButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;
  const _NeuButton({required this.size, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF131313),
          boxShadow: [
            BoxShadow(color: Color(0xFF080808), blurRadius: 10, offset: Offset(4, 4)),
            BoxShadow(color: Color(0xFF1e1e1e), blurRadius: 10, offset: Offset(-4, -4)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ══════════════════════════════════════════
// 수면 타이머 뱃지
// ══════════════════════════════════════════
// ══════════════════════════════════════════
// 즐겨찾기 바텀시트
// ══════════════════════════════════════════
class _FavoritesSheet extends StatelessWidget {
  final Color primaryColor;
  const _FavoritesSheet({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final favorites = radioProvider.favorites;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // 타이틀
          Row(
            children: [
              Icon(Icons.favorite, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '즐겨찾기 (${favorites.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 목록
          if (favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.favorite_border,
                      size: 48, color: primaryColor.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text(
                    '즐겨찾기한 방송이 없습니다',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '하트 버튼을 눌러 추가해보세요',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const Divider(
                  color: Color(0xFF252525), height: 1,
                ),
                itemBuilder: (context, index) {
                  final station = favorites[index];
                  final isCurrent = radioProvider.currentStation?.stationUuid == station.stationUuid;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? primaryColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isCurrent
                              ? primaryColor.withOpacity(0.4)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Icon(Icons.radio,
                          color: isCurrent ? primaryColor : AppTheme.textHint,
                          size: 20),
                    ),
                    title: Text(
                      station.name,
                      style: TextStyle(
                        color: isCurrent ? primaryColor : Colors.white,
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Builder(builder: (ctx) {
                      final nowPlaying = radioProvider.nowPlayingFor(station.name);
                      if (nowPlaying != null && nowPlaying.isNotEmpty) {
                        return Text(
                          nowPlaying,
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    trailing: isCurrent
                        ? Icon(Icons.graphic_eq, color: primaryColor, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      radioProvider.playStation(station);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SleepTimerBadge extends StatelessWidget {
  final Duration remaining;
  const _SleepTimerBadge({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final timeText = h > 0 ? '${h}시간 ${m}분 ${s}초' : m > 0 ? '${m}분 ${s}초' : '${s}초';

    return GestureDetector(
      onTap: () => context.read<RadioProvider>().cancelSleepTimer(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime, color: primaryColor, size: 16),
            const SizedBox(width: 8),
            Text(timeText, style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text('후 종료', style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13)),
            const SizedBox(width: 8),
            Icon(Icons.close, color: primaryColor.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// 편성표 시트 (기존 유지)
// ══════════════════════════════════════════
class _ScheduleListSheet extends StatelessWidget {
  final String stationName;
  const _ScheduleListSheet({required this.stationName});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final schedules = radioProvider.scheduleList;
    final currentProgram = radioProvider.currentProgram;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.format_list_bulleted, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('$stationName 편성표',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: schedules.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('편성표를 불러오는 중...', style: TextStyle(color: Colors.white54)),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final s = schedules[index];
                String title = s['program_title'] as String? ?? '';
                String start = s['program_planned_start_time'] as String? ?? '';
                String end = s['program_planned_end_time'] as String? ?? '';
                if (title.isEmpty) title = s['Title'] as String? ?? '';
                if (start.isEmpty) start = s['StartTime'] as String? ?? '';
                if (end.isEmpty) end = s['EndTime'] as String? ?? '';
                if (title.isEmpty) title = s['title'] as String? ?? '';
                if (start.isEmpty) {
                  start = s['start_time'] as String? ?? '';
                  end = s['end_time'] as String? ?? '';
                }

                String fmt(String t) {
                  if (t.contains(':')) {
                    final parts = t.split(':');
                    int h = int.tryParse(parts[0]) ?? 0;
                    if (h >= 24) h -= 24;
                    return '$h:${parts[1]}';
                  }
                  if (t.length < 4) return t;
                  int h = int.tryParse(t.substring(0, 2)) ?? 0;
                  final m = t.substring(2, 4);
                  if (h >= 24) h -= 24;
                  return '$h:$m';
                }

                final isCurrent = currentProgram != null &&
                    (currentProgram['program_planned_start_time'] == start ||
                        currentProgram['StartTime'] == start ||
                        currentProgram['start_time'] == start) &&
                    (currentProgram['program_title'] == title ||
                        currentProgram['Title'] == title ||
                        currentProgram['title'] == title);

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrent ? primaryColor.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isCurrent ? Border.all(color: primaryColor.withOpacity(0.4)) : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(fmt(start),
                            style: TextStyle(
                              color: isCurrent ? primaryColor : Colors.white54,
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            )),
                      ),
                      if (isCurrent)
                        Container(
                          width: 6, height: 6,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        )
                      else
                        const SizedBox(width: 14),
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}