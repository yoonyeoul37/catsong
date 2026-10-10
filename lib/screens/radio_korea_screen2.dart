import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/heart_pop.dart';
import 'radio_player_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'radio_home_screen.dart';
enum _ViewMode { all, broadcaster, region, recent }

class RadioKoreaScreen extends StatefulWidget {
  const RadioKoreaScreen({super.key});

  @override
  State<RadioKoreaScreen> createState() => _RadioKoreaScreenState();
}

class _RadioKoreaScreenState extends State<RadioKoreaScreen> {
  final Map<String, GlobalKey> _stationItemKeys = {};
  String? _lastScrolledStationName;
  _ViewMode _mode = _ViewMode.all;

  static const Map<String, Color> _regionColors = {
    '수도권': Color(0xFF14356B),
    '부산/경남': Color(0xFF0D4C6E),
    '대구/경북': Color(0xFF7A1F1F),
    '광주/전남': Color(0xFF1E4A2E),
    '전북': Color(0xFF4A1E5C),
    '대전/충남': Color(0xFF6B4A1E),
    '충북': Color(0xFF2E5C5C),
    '강원': Color(0xFF3A2E5C),
    '제주': Color(0xFF1E5C4A),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final radio = context.read<RadioProvider>();
      for (final station in koreanStations) {
        if (station.broadcaster == 'KBS' &&
            station.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
          radio.fetchScheduleByUrl(station.name, station.streamUrl);
        }
      }
      radio.fetchMbcSchedule('MBC 표준FM');
      radio.fetchMbcSchedule('MBC FM4U');
      radio.fetchSbsSchedule('SBS 파워FM');
      radio.fetchSbsSchedule('SBS 러브FM');
      radio.fetchJsonSchedule('CBS 음악FM');
      radio.fetchJsonSchedule('CBS 표준FM');
      radio.fetchKfnSchedule();
      radio.fetchEbsBandiSchedule();
    });
  }

  static RadioStation _toRadioStation(_KStation ks) {
    return RadioStation.fromJson({
      'stationuuid': 'kr_${ks.name.hashCode.abs()}',
      'name': ks.name,
      'url': ks.streamUrl,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': ks.frequency,
      'country': 'South Korea',
      'countrycode': 'KR',
      'codec': '',
      'bitrate': 0,
      'hls': 1,
      'votes': 0,
      'lastcheckok': 1,
    });
  }

  Widget _toggleButton(String label, _ViewMode mode, bool isDarkMode) {
    final selected = _mode == mode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? (isDarkMode ? Colors.white : const Color(0xFF17140F)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (isDarkMode ? const Color(0xFF24221F) : Colors.white)
                  : baseColor.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllList(BuildContext context, RadioProvider radioProvider) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final radioStations = koreanStations.map((ks) => _toRadioStation(ks)).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentName = radioProvider.currentStation?.name;
      if (currentName != null && currentName != _lastScrolledStationName) {
        _lastScrolledStationName = currentName;
        final key = _stationItemKeys[currentName];
        final targetContext = key?.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      }
    });

    return _DialHost(
      tickColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),
      child: ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: koreanStations.length,
      separatorBuilder: (_, __) => _DialEffect(
          child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),
      itemBuilder: (context, i) {
        final ks = koreanStations[i];
        final current = radioProvider.currentStation;
        final isPlaying = current?.name == ks.name && radioProvider.isPlaying;
        _stationItemKeys.putIfAbsent(ks.name, () => GlobalKey());
        return Container(
          key: _stationItemKeys[ks.name],
          child: _DialItem(
            child: _StationTile(
              station: ks,
              isPlaying: isPlaying,
              radioStation: radioStations[i],
              stationList: radioStations,
              stationIndex: i,
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildBroadcasterGrid(BuildContext context, RadioProvider radioProvider) {
    return _BroadcasterGridScreen(radioProvider: radioProvider);
  }

  Widget _buildRecentList(BuildContext context, RadioProvider radioProvider) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final recent = radioProvider.recentlyListened;
    if (recent.isEmpty) {
      return Center(
        child: Text(
          '최근 들은 방송이 없어요',
          style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: recent.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: baseColor.withOpacity(0.1)),
      itemBuilder: (context, i) {
        final station = recent[i];
        final lastListened = station.lastListened;
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final timeStr = lastListened != null
            ? '${lastListened.year}.${lastListened.month.toString().padLeft(2, '0')}.${lastListened.day.toString().padLeft(2, '0')}(${weekdays[lastListened.weekday - 1]}) ${lastListened.hour.toString().padLeft(2, '0')}:${lastListened.minute.toString().padLeft(2, '0')}'
            : '';
        final isPlaying = radioProvider.currentStation?.stationUuid == station.stationUuid && radioProvider.isPlaying;
        return InkWell(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(station: station),
                transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 250),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPlaying ? primaryColorOf(context) : baseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: TextStyle(color: baseColor, fontSize: 15.5, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color primaryColorOf(BuildContext context) => Theme.of(context).colorScheme.primary;

  Widget _buildRegionGrid(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    const regionList = [
      '수도권', '부산/경남', '대구/경북', '광주/전남',
      '전북', '대전/충남', '충북', '강원', '제주',
    ];
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: regionList.length,
      itemBuilder: (context, index) {
        final region = regionList[index];
        final count = koreanStations.where((s) => s.region == region).length;
        return GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            final stations = koreanStations.where((s) => s.region == region).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _BroadcasterStationList(broadcaster: region, stations: stations),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: _regionColors[region] ?? baseColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  region,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('$count개 채널',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF24221F),
          systemNavigationBarIconBrightness: Brightness.light,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFEDE7DA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios,
              color: baseColor, size: 20),
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Radio',
              style: GoogleFonts.doHyeon(
                color: baseColor,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            // 라디오를 틀면(미니플레이어가 뜨면) 막대는 미니플레이어 하나만 → 여기선 숨기기
            if (radioProvider.currentStation == null) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _LogoEqBars(),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(102),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Column(
              children: [
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _toggleButton('전체', _ViewMode.all, isDarkMode),
                      _toggleButton('방송사별', _ViewMode.broadcaster, isDarkMode),
                      _toggleButton('지역별', _ViewMode.region, isDarkMode),
                      _toggleButton('최근청취', _ViewMode.recent, isDarkMode),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RadioHomeScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? const Color(0x14FFFFFF)
                                : Colors.white.withOpacity(0.8),
                          ),
                          child: Icon(
                            Icons.public,
                            size: 16,
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                                ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
                                : context.watch<ThemeProvider>().primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('국가선택',
                            style: TextStyle(
                                color: baseColor, fontSize: 13, fontWeight: FontWeight.w700)),
                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: baseColor.withOpacity(0.18),
                        ),
                        const Text('🇰🇷', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('한국',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: baseColor.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: baseColor.withOpacity(0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: switch (_mode) {
          _ViewMode.all => _buildAllList(context, radioProvider),
          _ViewMode.broadcaster => _buildBroadcasterGrid(context, radioProvider),
          _ViewMode.region => _buildRegionGrid(context),
          _ViewMode.recent => _buildRecentList(context, radioProvider),
        },
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    );
  }
}

class _StationTile extends StatelessWidget {
  final _KStation station;
  final bool isPlaying;
  final RadioStation radioStation;
  final List<RadioStation> stationList;
  final int stationIndex;

  const _StationTile({
    required this.station,
    required this.isPlaying,
    required this.radioStation,
    required this.stationList,
    required this.stationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final dial = _DialScope.of(context);
    if (dial == null) return _tile(context, false, false);
    return AnimatedBuilder(
      animation: Listenable.merge([dial.tuned, dial.scrolling]),
      builder: (ctx, _) => _tile(ctx, dial.tuned.value && dial.scrolling.value, dial.scrolling.value),
    );
  }

  Widget _tile(BuildContext context, bool tuned, bool scrolling) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      // 스크롤 중 가운데 방송은 살짝 밝은 칸
      color: isPlaying
          ? primaryColor.withOpacity(0.08)
          : tuned
              ? baseColor.withOpacity(0.06)
              : Colors.transparent,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(
                station: radioStation,
                stationList: stationList,
                currentIndex: stationIndex,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        },
        splashColor: baseColor.withOpacity(0.04),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying ? primaryColor : baseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  station.broadcaster,
                  style: TextStyle(
                    color: isPlaying ? Colors.black : baseColor.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        color: isPlaying ? primaryColor : baseColor,
                        fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (ctx) {
                        final isKbs = station.broadcaster == 'KBS';
                        const mbcNames = ['MBC 표준FM', 'MBC FM4U'];
                        const sbsNames = ['SBS 파워FM', 'SBS 러브FM'];
                        final isMbc = mbcNames.contains(station.name);
                        final isSbs = sbsNames.contains(station.name);
                        final radio = ctx.watch<RadioProvider>();
                        final hasJsonSchedule = radio.nowPlayingFor(station.name) != null && !isKbs && !isMbc && !isSbs;
                        if (!isKbs && !isMbc && !isSbs && !hasJsonSchedule) {
                          return Text(
                            station.frequency.isNotEmpty
                                ? station.frequency
                                : '',
                            style: TextStyle(
                              color: baseColor.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          );
                        }
                        final nowPlaying = radio.nowPlayingFor(station.name);
                        final program = radio.currentProgramFor(station.name);
                        final start = program?['program_planned_start_time'] as String? ?? '';
                        final end = program?['program_planned_end_time'] as String? ?? '';
                        final sbsTitle = program?['title'] as String?;
                        final displayNowPlaying = nowPlaying ?? sbsTitle;
                        String _fmt(String t) {
                          final cleaned = t.replaceAll(':', '');
                          if (cleaned.length >= 12) {
                            final hhmm = cleaned.substring(8, 12);
                            int h = int.tryParse(hhmm.substring(0, 2)) ?? 0;
                            final m = hhmm.substring(2, 4);
                            if (h >= 24) h -= 24;
                            return '${h.toString().padLeft(2, '0')}:$m';
                          }
                          if (cleaned.length < 4) return t;
                          int h = int.tryParse(cleaned.substring(0, 2)) ?? 0;
                          final m = cleaned.substring(2, 4);
                          if (h >= 24) h -= 24;
                          return '${h.toString().padLeft(2, '0')}:$m';
                        }
                        final isMbcStation = mbcNames.contains(station.name);
                        final isSbsStation = sbsNames.contains(station.name);
                        String? rawStart;
                        String? rawEnd;
                        if (isMbcStation) {
                          final mbcS = program?['StartTime'];
                          final mbcE = program?['EndTime'];
                          rawStart = mbcS?.toString();
                          rawEnd = mbcE?.toString();
                        } else if (isSbsStation) {
                          rawStart = program?['start_time'] as String?;
                          rawEnd = program?['end_time'] as String?;
                        } else if (hasJsonSchedule) {
                          rawStart = program?['start_time'] as String?;
                          rawEnd = program?['end_time'] as String?;
                        } else {
                          rawStart = start.isEmpty ? null : start;
                          rawEnd = end.isEmpty ? null : end;
                        }
                        String _fmtSbs(String t) {
                          if (t.length >= 5) {
                            final h = int.tryParse(t.split(':')[0]) ?? 0;
                            final m = t.split(':')[1];
                            return '${h >= 24 ? h - 24 : h}:$m';
                          }
                          return t;
                        }
                        final timeStr = rawStart != null && rawEnd != null
                            ? isSbsStation
                            ? '${_fmtSbs(rawStart)}~${_fmtSbs(rawEnd)}'
                            : isMbcStation
                            ? '${_fmt(rawStart)}~${_fmt(rawEnd)}'
                            : hasJsonSchedule
                            ? '$rawStart~$rawEnd'
                            : '${_fmt(rawStart)}~${_fmt(rawEnd)}'
                            : '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayNowPlaying != null && displayNowPlaying.isNotEmpty)
                              Text(
                                displayNowPlaying,
                                style: TextStyle(
                                  color: baseColor.withOpacity(0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              [
                                if (station.frequency.isNotEmpty) station.frequency,
                                if (timeStr.isNotEmpty) timeStr,
                              ].join(' · '),
                              style: TextStyle(
                                color: baseColor.withOpacity(0.55),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 76,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (cur, prev) => Stack(
                    alignment: Alignment.centerRight,
                    children: [...prev, if (cur != null) cur],
                  ),
                  child: isPlaying
                      ? KeyedSubtree(key: const ValueKey('bars'), child: _PlayingBars(color: primaryColor))
                      : scrolling
                          ? Text.rich(
                              TextSpan(children: [
                                TextSpan(text: station.frequency.replaceAll(' MHz', '').trim()),
                                if (station.frequency.trim().isNotEmpty)
                                  TextSpan(
                                    text: ' MHz',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: (tuned ? primaryColor : baseColor).withOpacity(tuned ? 0.75 : 0.35),
                                    ),
                                  ),
                              ]),
                              key: const ValueKey('freq'),
                              maxLines: 1,
                              style: GoogleFonts.quicksand(
                                color: tuned ? primaryColor : baseColor.withOpacity(0.45),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : GestureDetector(
                  key: const ValueKey('heart'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    final radioProvider = context.read<RadioProvider>();
                    final wasFav = radioProvider.isFavorite(radioStation.stationUuid);
                    // (하트가 바로 바뀌어서 따로 알림 없음)
                    Future.microtask(() => radioProvider.toggleFavorite(radioStation));
                  },
                  // 하트 둘레 넓게 (옆을 눌러도 재생 안 되게) + 켤 때 통통
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: HeartPop(
                        on: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid),
                        child: Icon(
                          context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                              ? const Color(0xFFE05A4F)
                              : baseColor.withOpacity(0.35),
                          size: 22,
                        ),
                      ),
                    ),
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

class _KStation {
  final String name;
  final String region;
  final String broadcaster;
  final String subLabel;
  final String frequency;
  final String streamUrl;

  const _KStation({
    required this.name,
    required this.region,
    required this.broadcaster,
    this.subLabel = '',
    this.frequency = '',
    required this.streamUrl,
  });
}

const koreanStations = <_KStation>[
  _KStation(name: 'KBS Classic FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '93.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/24'),
  _KStation(name: 'KBS Cool FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '89.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/25'),
  _KStation(name: 'KBS 제1라디오', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '97.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/21'),
  _KStation(name: 'KBS 해피FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '106.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/22'),
  _KStation(name: 'KBS 3라디오', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '104.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/23'),
  _KStation(name: 'MBC 표준FM', region: '수도권', broadcaster: 'MBC', subLabel: '서울', frequency: '95.9 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/mbcsfm.pls'),
  _KStation(name: 'MBC FM4U', region: '수도권', broadcaster: 'MBC', subLabel: '서울', frequency: '91.9 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/mbcfm.pls'),
  _KStation(name: 'MBC 올댓뮤직', region: '수도권', broadcaster: 'MBC', subLabel: '서울', frequency: '', streamUrl: 'http://serpent0.duckdns.org:8088/mbcatm.pls'),
  _KStation(name: 'SBS 파워FM', region: '수도권', broadcaster: 'SBS', subLabel: '서울', frequency: '107.7 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/sbsfm.pls'),
  _KStation(name: 'SBS 러브FM', region: '수도권', broadcaster: 'SBS', subLabel: '서울', frequency: '103.5 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/sbs2fm.pls'),
  _KStation(name: 'CBS 음악FM', region: '수도권', broadcaster: 'CBS', subLabel: '서울', frequency: '93.9 MHz', streamUrl: 'https://m-aac.cbs.co.kr/mweb_cbs939/_definst_/cbs939.stream/playlist.m3u8'),
  _KStation(name: 'CBS 표준FM', region: '수도권', broadcaster: 'CBS', subLabel: '서울', frequency: '98.1 MHz', streamUrl: 'https://m-aac.cbs.co.kr/mweb_cbs981/_definst_/cbs981.stream/playlist.m3u8'),
  _KStation(name: 'YTN 라디오', region: '수도권', broadcaster: 'YTN', subLabel: '서울', frequency: '94.5 MHz', streamUrl: 'https://radiolive.ytn.co.kr/radio/_definst_/20211118_fmlive/playlist.m3u8'),
  _KStation(name: 'TBS FM', region: '수도권', broadcaster: 'TBS', subLabel: '서울', frequency: '95.1 MHz', streamUrl: 'https://cdnfm.tbs.seoul.kr/tbs/_definst_/tbs_fm_web_360.smil/chunklist.m3u8'),
  _KStation(name: 'TBS eFM', region: '수도권', broadcaster: 'TBS', subLabel: '서울', frequency: '101.3 MHz', streamUrl: 'https://cdnefm.tbs.seoul.kr/tbs/_definst_/tbs_efm_web_360.smil/chunklist.m3u8'),
  _KStation(name: 'EBS FM', region: '수도권', broadcaster: 'EBS', subLabel: '서울', frequency: '104.5 MHz', streamUrl: 'https://ebsonair.ebs.co.kr/fmradiofamilypc/familypc1m/playlist.m3u8'),
  _KStation(name: 'EBS 반디', region: '수도권', broadcaster: 'EBS', subLabel: '외국어', frequency: '', streamUrl: 'https://ebsonair.ebs.co.kr/cloud1/iradio/playlist.m3u8'),
  _KStation(name: 'OBS 라디오', region: '수도권', broadcaster: 'OBS', subLabel: '경기', frequency: '90.1 MHz', streamUrl: 'https://vod3.obs.co.kr:444/live/obsstream1/radio.stream/playlist.m3u8'),
  _KStation(name: '경인방송', region: '수도권', broadcaster: 'OBS', subLabel: '인천', frequency: '90.7 MHz', streamUrl: 'https://stream.ifm.kr/live/aod1/playlist.m3u8'),
  _KStation(name: 'CPBC 가톨릭', region: '수도권', broadcaster: 'CPBC', subLabel: '서울', frequency: '101.7 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/cpbc.pls'),
  _KStation(name: 'FEBC 극동방송', region: '수도권', broadcaster: 'FEBC', subLabel: '서울', frequency: '106.9 MHz', streamUrl: 'http://mlive2.febc.net:1935/live/seoulfm/playlist.m3u8'),
  _KStation(name: 'BBS 불교방송', region: '수도권', broadcaster: 'BBS', subLabel: '서울', frequency: '101.9 MHz', streamUrl: 'https://bbslive.clouducs.com/bbsradio-mlive/radio.stream/playlist.m3u8'),
  _KStation(name: '국악FM', region: '수도권', broadcaster: '국악방송', subLabel: '서울', frequency: '99.1 MHz', streamUrl: 'http://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8'),
  _KStation(name: '국방FM', region: '수도권', broadcaster: '국방FM', subLabel: '서울', frequency: '100.5 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/gbfm.pls'),
  _KStation(name: 'TBN 경인교통', region: '수도권', broadcaster: 'TBN', subLabel: '경기', frequency: '99.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gyeongin/myStream/playlist.m3u8'),
  _KStation(name: '부산MBC 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '부산', frequency: '95.9 MHz', streamUrl: 'https://stream.bsmbc.com/live/BusanMBC_AM_onairstream.sbhhqc/playlist.m3u8'),
  _KStation(name: '부산MBC FM4U', region: '부산/경남', broadcaster: 'MBC', subLabel: '부산', frequency: '88.9 MHz', streamUrl: 'https://stream.bsmbc.com/live/mp4:BusanMBC.Live-FM-0415/playlist.m3u8'),
  _KStation(name: '울산MBC 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '울산', frequency: '97.5 MHz', streamUrl: 'https://5ddfd163bd00d.streamlock.net/STDFM/STDFM/playlist.m3u8'),
  _KStation(name: 'MBC경남 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '창원', frequency: '97.9 MHz', streamUrl: 'https://624a79c87201d.streamlock.net/MBCFM/TV2.stream/playlist.m3u8'),
  _KStation(name: 'KBS 부산 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '103.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_21'),
  _KStation(name: 'KBS 부산 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_22'),
  _KStation(name: 'KBS 부산 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '92.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_24'),
  _KStation(name: 'KBS 창원 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_21'),
  _KStation(name: 'KBS 창원 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '106.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_22'),
  _KStation(name: 'KBS 창원 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '93.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_24'),
  _KStation(name: 'KBS 진주 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '진주', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/21_21'),
  _KStation(name: 'BeFM', region: '부산/경남', broadcaster: 'BeFM', subLabel: '부산', frequency: '90.5 MHz', streamUrl: 'http://befm905.live.smilecdn.com:1935/befm905_live/live/playlist.m3u8'),
  _KStation(name: 'TBN 울산교통', region: '부산/경남', broadcaster: 'TBN', subLabel: '울산', frequency: '98.7 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/ulsan/myStream/playlist.m3u8'),
  _KStation(name: 'KBS 대구 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '101.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_21'),
  _KStation(name: 'KBS 대구 해피FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '96.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_22'),
  _KStation(name: 'KBS 대구 1FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_24'),
  _KStation(name: 'KBS 안동 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '안동', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/31_21'),
  _KStation(name: 'KBS 포항 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '포항', frequency: '95.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/32_21'),
  _KStation(name: '안동MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '97.7 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/amlive/playlist.m3u8'),
  _KStation(name: '안동MBC FM4U', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '103.1 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/fmlive/playlist.m3u8'),
  _KStation(name: '대구MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '대구', frequency: '95.7 MHz', streamUrl: 'https://5ee1ec6f32118.streamlock.net/amradio/am/playlist.m3u8'),
  _KStation(name: '포항MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '포항', frequency: '104.3 MHz', streamUrl: 'http://stream.yubinet.com:1935/live/_definst_/Radio_Am/playlist.m3u8'),
  _KStation(name: '광주MBC 표준FM', region: '광주/전남', broadcaster: 'MBC', subLabel: '광주', frequency: '97.9 MHz', streamUrl: 'https://media.kjmbc.co.kr/hls/amlive/GWANGJU-MBC-AM/playlist.m3u8'),
  _KStation(name: '광주MBC FM4U', region: '광주/전남', broadcaster: 'MBC', subLabel: '광주', frequency: '89.5 MHz', streamUrl: 'https://media.kjmbc.co.kr/hls/fmlive/GWANGJU-MBC-FM/playlist.m3u8'),
  _KStation(name: '목포MBC 표준FM', region: '광주/전남', broadcaster: 'MBC', subLabel: '목포', frequency: '97.9 MHz', streamUrl: 'https://vod.mpmbc.co.kr/live/encoder-am/playlist.m3u8'),
  _KStation(name: 'KBS 광주 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_21'),
  _KStation(name: 'KBS 광주 해피FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '100.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_22'),
  _KStation(name: 'KBS 광주 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '93.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_24'),
  _KStation(name: 'KBS 목포 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '105.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_21'),
  _KStation(name: 'KBS 목포 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '101.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_24'),
  _KStation(name: 'KBS 순천 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '순천', frequency: '95.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/43_21'),
  _KStation(name: 'KBS 전주 1라디오', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '96.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_21'),
  _KStation(name: 'KBS 전주 해피FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_22'),
  _KStation(name: 'KBS 전주 1FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '93.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_24'),
  _KStation(name: 'JTV 매직FM', region: '전북', broadcaster: 'JTV', subLabel: '전주', frequency: '99.1 MHz', streamUrl: 'https://61ff3340258d2.streamlock.net/jtv_radio/myStream/chunklist_w111659793.m3u8'),
  _KStation(name: '대전MBC 표준FM', region: '대전/충남', broadcaster: 'MBC', subLabel: '대전', frequency: '99.5 MHz', streamUrl: 'https://ns1.tjmbc.co.kr/live_am/live_am.stream/playlist.m3u8'),
  _KStation(name: 'KBS 대전 1라디오', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '94.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_21'),
  _KStation(name: 'KBS 대전 해피FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_22'),
  _KStation(name: 'KBS 대전 1FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '99.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_24'),
  _KStation(name: 'KBS 청주 1라디오', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '89.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_21'),
  _KStation(name: 'KBS 청주 해피FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '99.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_22'),
  _KStation(name: 'KBS 청주 1FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_24'),
  _KStation(name: 'MBC충북 표준FM', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '93.3 MHz', streamUrl: 'http://211.33.246.4:32954/radio_stfm/myStream.sdp/chunklist_w392819215.m3u8'),
  _KStation(name: 'MBC충북 FM4U', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '96.7 MHz', streamUrl: 'http://211.33.246.4:32954/radio_fm/myStream.sdp/chunklist_w348337231.m3u8'),
  _KStation(name: '춘천MBC 표준FM', region: '강원', broadcaster: 'MBC', subLabel: '춘천', frequency: '92.3 MHz', streamUrl: 'https://stream.chmbc.co.kr/live_radio/fm2/playlist.m3u8'),
  _KStation(name: '춘천MBC FM4U', region: '강원', broadcaster: 'MBC', subLabel: '춘천', frequency: '97.9 MHz', streamUrl: 'https://stream.chmbc.co.kr/live_radio2/fm1/playlist.m3u8'),
  _KStation(name: 'KBS 춘천 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '99.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_21'),
  _KStation(name: 'KBS 춘천 해피FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_22'),
  _KStation(name: 'KBS 춘천 1FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_24'),
  _KStation(name: 'KBS 강릉 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '98.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_21'),
  _KStation(name: 'KBS 강릉 1FM', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_24'),
  _KStation(name: 'KBS 원주 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_21'),
  _KStation(name: 'KBS 원주 1FM', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_24'),
  _KStation(name: '제주MBC 표준FM', region: '제주', broadcaster: 'MBC', subLabel: '제주', frequency: '97.9 MHz', streamUrl: 'https://wowza.jejumbc.com/live/_definst_/mp3:radio1/playlist.m3u8'),
  _KStation(name: '제주MBC FM4U', region: '제주', broadcaster: 'MBC', subLabel: '제주', frequency: '89.9 MHz', streamUrl: 'https://wowza.jejumbc.com/live/_definst_/mp3:radio2/playlist.m3u8'),
  _KStation(name: 'KBS 제주 1라디오', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '93.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_21'),
  _KStation(name: 'KBS 제주 해피FM', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_22'),
  _KStation(name: 'KBS 제주 1FM', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '96.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_24'),
];

class _PlayingBars extends StatefulWidget {
  final Color color;
  const _PlayingBars({required this.color});

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000 + i * 300),
      )..repeat(reverse: true),
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
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════
// 방송사별 카드 격자 화면
// ══════════════════════════════════════════
class _BroadcasterGridScreen extends StatelessWidget {
  final RadioProvider radioProvider;
  const _BroadcasterGridScreen({required this.radioProvider});

  static const _order = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS', '기타'];

  static const Map<String, Color> _cardColors = {
    'KBS': Color(0xFF14356B),
    'MBC': Color(0xFF4A1E5C),
    'SBS': Color(0xFF7A1F1F),
    'EBS': Color(0xFF0D4C6E),
    'CBS': Color(0xFF1E4A2E),
  };

  Map<String, List<_KStation>> _grouped() {
    final Map<String, List<_KStation>> map = {};
    for (final s in koreanStations) {
      final key = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS'].contains(s.broadcaster)
          ? s.broadcaster
          : '기타';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final grouped = _grouped();
    final keys = _order.where((k) => grouped.containsKey(k)).toList();

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final stations = grouped[key]!;
        return GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _BroadcasterStationList(broadcaster: key, stations: stations),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: _cardColors[key] ?? const Color(0xFF3A342A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stations.length}개 채널',
                  style: TextStyle(
                    color: Colors.white.withOpacity(_cardColors.containsKey(key) ? 0.7 : 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════
// 방송사 하나의 전국 채널 리스트 화면
// ══════════════════════════════════════════
class _BroadcasterStationList extends StatelessWidget {
  final String broadcaster;
  final List<_KStation> stations;
  const _BroadcasterStationList({required this.broadcaster, required this.stations});

  static RadioStation _toRadioStation(_KStation ks) {
    return RadioStation.fromJson({
      'stationuuid': 'kr_${ks.name.hashCode.abs()}',
      'name': ks.name,
      'url': ks.streamUrl,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': ks.frequency,
      'country': 'South Korea',
      'countrycode': 'KR',
      'codec': '',
      'bitrate': 0,
      'hls': 1,
      'votes': 0,
      'lastcheckok': 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final radioStations = stations.map((ks) => _toRadioStation(ks)).toList();
    final radioProvider = context.watch<RadioProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
        ),
        title: Text(broadcaster,
            style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: _DialHost(
          tickColor: baseColor.withOpacity(0.35),
          child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
          itemCount: stations.length,
          separatorBuilder: (_, __) => _DialEffect(child: Divider(height: 1, color: baseColor.withOpacity(0.1))),
          itemBuilder: (context, i) {
            final ks = stations[i];
            final current = radioProvider.currentStation;
            final isPlaying = current?.name == ks.name && radioProvider.isPlaying;
            return _DialItem(
              child: _StationTile(
                station: ks,
                isPlaying: isPlaying,
                radioStation: radioStations[i],
                stationList: radioStations,
                stationIndex: i,
              ),
            );
          },
        ),
        ),
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    );
  }
}

// 상단바에 쓰는 작은 이퀄라이저 막대 (은은하게 움직임)
class _LogoEqBars extends StatefulWidget {
  const _LogoEqBars();

  @override
  State<_LogoEqBars> createState() => _LogoEqBarsState();
}

class _LogoEqBarsState extends State<_LogoEqBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = context.watch<ThemeProvider>().primaryColor;
    final eqColor = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final t = _c.value * 2 * math.pi + i * 1.3;
              final v = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t));
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: Container(
                  width: 3,
                  height: 14 * v,
                  decoration: BoxDecoration(
                    color: eqColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════
// 주파수 맞추기: 끝으로 갈수록 작아지고 흐려짐 + 가운데 방송 표시
// ══════════════════════════════════════════
class _DialScope extends InheritedWidget {
  final ValueNotifier<bool> tuned;
  final ValueNotifier<bool> scrolling;
  const _DialScope({required this.tuned, required this.scrolling, required super.child});

  static _DialScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_DialScope>();

  @override
  bool updateShouldNotify(_DialScope old) => old.tuned != tuned || old.scrolling != scrolling;
}

class _DialItem extends StatefulWidget {
  final Widget child;
  const _DialItem({required this.child});

  @override
  State<_DialItem> createState() => _DialItemState();
}

class _DialItemState extends State<_DialItem> {
  final ValueNotifier<bool> _tuned = ValueNotifier(false);

  @override
  void dispose() {
    _tuned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _DialHostScope.of(context);
    if (host == null) return widget.child;
    return _DialScope(
      tuned: _tuned,
      scrolling: host.scrolling,
      child: _DialEffect(
        onTuned: (v) {
          if (mounted && _tuned.value != v) _tuned.value = v;
        },
        child: widget.child,
      ),
    );
  }
}

class _DialEffect extends SingleChildRenderObjectWidget {
  final ValueChanged<bool>? onTuned;
  const _DialEffect({this.onTuned, required Widget child}) : super(child: child);

  @override
  _RenderDial createRenderObject(BuildContext context) =>
      _RenderDial(Scrollable.of(context), onTuned, _DialHostScope.of(context)?.strength);

  @override
  void updateRenderObject(BuildContext context, _RenderDial renderObject) {
    renderObject
      ..scrollable = Scrollable.of(context)
      ..onTuned = onTuned
      ..strength = _DialHostScope.of(context)?.strength;
  }
}

class _RenderDial extends RenderProxyBox {
  _RenderDial(this._scrollable, this.onTuned, this._strength);

  ScrollableState _scrollable;
  ValueChanged<bool>? onTuned;
  bool? _lastTuned;
  Animation<double>? _strength;

  set strength(Animation<double>? a) {
    if (identical(a, _strength)) return;
    if (attached) _strength?.removeListener(markNeedsPaint);
    _strength = a;
    if (attached) _strength?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set scrollable(ScrollableState s) {
    if (identical(s, _scrollable)) return;
    if (attached) _scrollable.position.removeListener(markNeedsPaint);
    _scrollable = s;
    if (attached) _scrollable.position.addListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollable.position.addListener(markNeedsPaint);
    _strength?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(markNeedsPaint);
    _strength?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    double k = 0;
    bool tuned = false;
    final vp = _scrollable.context.findRenderObject();
    if (vp is RenderBox && vp.hasSize) {
      final cy = localToGlobal(size.center(Offset.zero), ancestor: vp).dy;
      final half = vp.size.height / 2;
      if (half > 0) k = ((cy - half) / half).clamp(-1.0, 1.0).abs();
      tuned = (cy - half).abs() < size.height / 2;
    }
    // 가운데 방송인지 알려주기 (그리는 중엔 못 바꿔서 다음 화면에)
    if (onTuned != null && tuned != _lastTuned) {
      _lastTuned = tuned;
      final cb = onTuned!;
      SchedulerBinding.instance.addPostFrameCallback((_) => cb(tuned));
    }
    // 멈춰 있으면 0 → 깔끔한 목록, 스크롤하면 1 → 다이얼
    k = k * (_strength?.value ?? 1.0);
    final s = 1 - 0.12 * k * k; // 끝으로 갈수록 작게 (최대 12%)
    final alpha = (255 * (1 - 0.55 * k * k)).round().clamp(0, 255); // 끝으로 갈수록 흐리게
    final m = Matrix4.identity()
      ..setEntry(0, 0, s)
      ..setEntry(1, 1, s)
      ..setEntry(0, 3, size.width / 2 * (1 - s))
      ..setEntry(1, 3, size.height / 2 * (1 - s));
    context.pushOpacity(offset, alpha, (ctx, o) {
      ctx.pushTransform(needsCompositing, o, m, (ctx2, o2) => ctx2.paintChild(c, o2));
    });
  }
}

/// 오른쪽 끝 주파수 눈금 (스크롤 따라 움직임, 위아래 끝은 흐리게)
class _TickPainter extends CustomPainter {
  final ValueNotifier<double> px;
  final Color color;
  final Animation<double> strength;
  _TickPainter(this.px, this.color, this.strength) : super(repaint: Listenable.merge([px, strength]));

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 12.0;
    final off = -(px.value * 0.6) % (gap * 5);
    final half = size.height / 2;
    if (half <= 0) return;
    final paint = Paint()..strokeWidth = 1;
    for (int i = -5; i < 400; i++) {
      final y = off + i * gap;
      if (y > size.height) break;
      if (y < 0) continue;
      final d = ((y - half).abs() / half).clamp(0.0, 1.0);
      paint.color = color.withOpacity(color.opacity * (1 - d * d) * strength.value);
      final w = (i % 5 + 5) % 5 == 0 ? 18.0 : 9.0;
      canvas.drawLine(Offset(size.width - w, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color || old.px != px || old.strength != strength;
}


/// 목록 하나를 다이얼로 감싸요: 스크롤 감지, 효과 세기, 오른쪽 눈금
class _DialHost extends StatefulWidget {
  final Color tickColor;
  final Widget child;
  const _DialHost({required this.tickColor, required this.child});

  @override
  State<_DialHost> createState() => _DialHostState();
}

class _DialHostState extends State<_DialHost> with SingleTickerProviderStateMixin {
  // 스크롤 중이면 true (멈추고 1초 뒤 false → 하트)
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);
  final ValueNotifier<double> _px = ValueNotifier(0);
  late final AnimationController _strength = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 450),
  );
  Timer? _relaxTimer;
  Timer? _heartTimer;

  @override
  void dispose() {
    _relaxTimer?.cancel();
    _heartTimer?.cancel();
    _strength.dispose();
    _scrolling.dispose();
    _px.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    _px.value = n.metrics.pixels;
    if (n is ScrollStartNotification || (n is ScrollUpdateNotification && !_scrolling.value)) {
      _relaxTimer?.cancel();
      _heartTimer?.cancel();
      _scrolling.value = true;
      _strength.forward();
    } else if (n is ScrollEndNotification) {
      _relaxTimer?.cancel();
      _heartTimer?.cancel();
      // 멈추면 다이얼이 부드럽게 풀리고
      _relaxTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _strength.reverse();
      });
      // 1초 뒤에 하트
      _heartTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) _scrolling.value = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _DialHostScope(
      scrolling: _scrolling,
      strength: _strength,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
          // 오른쪽 끝 주파수 눈금 (스크롤 따라 움직임)
          Positioned(
            top: 0,
            bottom: 0,
            right: 3,
            width: 20,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TickPainter(_px, widget.tickColor, _strength),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialHostScope extends InheritedWidget {
  final ValueNotifier<bool> scrolling;
  final Animation<double> strength;
  const _DialHostScope({required this.scrolling, required this.strength, required super.child});

  static _DialHostScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_DialHostScope>();

  @override
  bool updateShouldNotify(_DialHostScope old) => old.scrolling != scrolling || old.strength != strength;
}
