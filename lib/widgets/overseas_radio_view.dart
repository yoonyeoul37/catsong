import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import 'station_logo.dart';
import 'sleep_timer_sheet.dart';
import 'more_menu_sheet.dart';
import '../screens/radio_country_stations_screen.dart';
import '../screens/radio_home_screen.dart';
import '../services/cast_service.dart';

/// 해외 라디오 상세화면 (애플뮤직 스타일)
/// 큰 로고 + 이름 + 장르·국가 + LIVE + 흰색 이퀄라이저 + 조작 버튼
class OverseasRadioView extends StatelessWidget {
  final RadioStation station;
  final bool openedFromList;
  final VoidCallback? onExit; // 전원 버튼 (종료)
  final VoidCallback? onCast; // TV로 듣기
  const OverseasRadioView({
    super.key,
    required this.station,
    this.openedFromList = true,
    this.onExit,
    this.onCast,
  });

  /// 뒤로가기: 목록에서 들어왔으면 그냥 닫고, 아니면(미니플레이어 등) 목록 화면으로
  void _close(BuildContext context) {
    _vibrate();
    if (openedFromList) {
      Navigator.pop(context);
      return;
    }
    final country = context.read<RadioProvider>().selectedCountry;
    final Widget listScreen = country == null
        ? const RadioHomeScreen()
        : RadioCountryStationsScreen(country: country);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => listScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _vibrate() =>
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  /// 목록 순서대로 이전(-1) / 다음(+1) 방송국
  void _move(BuildContext context, int step) {
    final radio = context.read<RadioProvider>();
    final queue = radio.currentQueue;
    if (queue.isEmpty) return;
    final idx = radio.currentQueueIndex < 0 ? 0 : radio.currentQueueIndex;
    final newIdx = (idx + step) % queue.length;
    _vibrate();
    radio.setQueue(queue, newIdx);
    radio.playStation(queue[newIdx]);
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    // TV로 듣는 중이면 TV 상태를 따름
    final isPlaying = CastService.instance.isConnected ? CastService.instance.tvPlaying : radio.isPlaying;
    final isLoading = radio.isLoading;
    final isFav = radio.isFavorite(station.stationUuid);
    final sub = [
      if (station.genre.isNotEmpty) station.genre,
      if (station.country != null && station.country!.isNotEmpty) station.country!,
    ].join(' · ');

    final screen = MediaQuery.of(context).size;
    final logoSize = math.min(screen.width * 0.62, 260.0);

    return PopScope(
      canPop: openedFromList,
      onPopInvoked: (didPop) {
        if (!didPop) _close(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 배경: 로고를 크게 흐리게 깔기 (로고 없으면 로고 색으로)
            Transform.scale(
              scale: 1.4,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: StationLogo(
                  logoUrl: station.logoUrl,
                  name: station.name,
                  size: screen.longestSide,
                ),
              ),
            ),
            Container(color: Colors.black.withOpacity(0.45)),
            GestureDetector(
              // 화면을 옆으로 밀면 이전/다음 방송국
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -300) {
                  _move(context, 1);
                } else if (v > 300) {
                  _move(context, -1);
                }
              },
              child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 위: 닫기 / 즐겨찾기
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _close(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const Spacer(),
                        // 전원: 종료 확인창
                        if (onExit != null)
                          IconButton(
                            onPressed: onExit,
                            icon: const Icon(Icons.power_settings_new_rounded,
                                color: Color(0xFFE8877E), size: 24),
                          ),
                        // 홈: 처음 화면까지 한 번에
                        IconButton(
                          onPressed: () {
                            _vibrate();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home_rounded,
                              color: Colors.white, size: 24),
                        ),
                        // TV로 듣기 (연결되면 하늘색)
                        if (onCast != null)
                          AnimatedBuilder(
                            animation: CastService.instance,
                            builder: (context, _) => IconButton(
                              onPressed: onCast,
                              icon: Icon(
                                CastService.instance.isConnected ? Icons.cast_connected : Icons.cast,
                                color: CastService.instance.isConnected ? const Color(0xFF7FB8F0) : Colors.white,
                                size: 23,
                              ),
                            ),
                          ),
                        // 더보기: 공유 / 앱 평가 / 설정 / 방송국 홈페이지
                        IconButton(
                          onPressed: () {
                            _vibrate();
                            showMoreMenuSheet(
                              context,
                              shareText: '지금 ${station.name} 듣고 있어요! 파란소리에서 같이 들어요 🎧',
                              shareSubtitle: '지금 듣는 방송을 소개해보세요.',
                              stationHomepage: station.homepage,
                            );
                          },
                          icon: const Icon(Icons.more_vert_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 큰 로고
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(logoSize * 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: StationLogo(
                        logoUrl: station.logoUrl,
                        name: station.name,
                        size: logoSize,
                        fontSize: logoSize * 0.22,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 이름
                    Text(
                      station.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65), fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // LIVE 표시 (접속 중이면 작은 로딩)
                    SizedBox(
                      height: 16,
                      child: isLoading
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: Colors.white70),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPlaying
                                  ? const Color(0xFFE8877E)
                                  : Colors.white38,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: isPlaying
                                  ? const Color(0xFFF2B8B2)
                                  : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    MountainEqBars(isPlaying: isPlaying),
                    const Spacer(),
                    // 아래 조작 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            _vibrate();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black.withOpacity(0.7),
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => const SleepTimerSheet(),
                            );
                          },
                          icon: Icon(
                            Icons.bedtime_outlined,
                            color: radio.isSleepTimerActive
                                ? const Color(0xFF2F7DE8)
                                : Colors.white70,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _move(context, -1),
                          icon: const Icon(Icons.skip_previous_rounded,
                              color: Colors.white, size: 40),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                            _vibrate();
                            final cast = CastService.instance;
                            if (cast.isConnected) {
                              cast.tvPlaying ? cast.pause() : cast.play(); // TV를 멈추고/재생
                            } else {
                              context.read<RadioProvider>().togglePlayPause();
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: isLoading
                                ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black54),
                            )
                                : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 38,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _move(context, 1),
                          icon: const Icon(Icons.skip_next_rounded,
                              color: Colors.white, size: 40),
                        ),
                        IconButton(
                          onPressed: () {
                            _vibrate();
                            context.read<RadioProvider>().toggleFavorite(station);
                          },
                          icon: Icon(
                            isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                            color: isFav ? const Color(0xFFE8877E) : Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
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

/// 음악 재생화면과 같은 흰색 산 모양 이퀄라이저 (정지 중엔 낮게 멈춤)
class MountainEqBars extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  const MountainEqBars({
    super.key,
    required this.isPlaying,
    this.color = Colors.white,
  });

  @override
  State<MountainEqBars> createState() => _WhiteEqBarsState();
}

class _WhiteEqBarsState extends State<MountainEqBars>
    with TickerProviderStateMixin {
  static const _durations = [1400, 1200, 1600, 1250, 1750, 1150, 1700, 1350, 1550, 1220, 1480];
  static const _minHeights = [4.0, 4.0, 5.0, 7.0, 9.0, 11.0, 9.0, 7.0, 5.0, 4.0, 4.0];
  static const _maxHeights = [5.0, 9.0, 14.0, 20.0, 26.0, 32.0, 26.0, 20.0, 14.0, 9.0, 5.0];
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      11,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      )..repeat(reverse: true),
    );
    _anims = _ctrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOutSine))
        .toList();
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
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(11, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) {
              final v = widget.isPlaying ? _anims[i].value : 0.0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: _minHeights[i] + (_maxHeights[i] - _minHeights[i]) * v,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}