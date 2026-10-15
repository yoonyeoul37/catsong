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
import '../widgets/radio_dice.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _diceNew = false; // 주사위를 한 번도 안 눌렀으면 NEW
  bool _diceIntro = false; // 처음 한 번만 가운데 큰 카드
  String? _diceChoice; // 주사위로 나온 방송 (카드에 그대로 보여줌)
  bool _diceTip = false; // 주사위 옆 말풍선 "던져보세요!"
  double _diceWiggle = 0; // 주사위 데굴 (돌린 정도)

  /// 주사위를 아직 안 눌렀으면, 들어올 때 5번까지 말풍선 + 데굴
  Future<void> _maybeShowDiceTip() async {
    final p = await SharedPreferences.getInstance();
    if ((p.getInt('radioDiceCount') ?? 0) > 0) return;
    final shown = p.getInt('radioDiceTipShown') ?? 0;
    if (shown >= 5) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _diceIntro || _mode != _ViewMode.all) return; // 처음 큰 카드가 떠 있으면 안 보여줌
    await p.setInt('radioDiceTipShown', shown + 1);
    setState(() {
      _diceTip = true;
      _diceWiggle = -0.06;
    });
    for (final (ms, w) in const [(170, 0.05), (340, -0.03), (500, 0.0)]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) setState(() => _diceWiggle = w);
      });
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _diceTip = false);
    });
  }

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
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        // NEW: 처음 본 날부터 7일 동안, 또는 주사위를 3번 던질 때까지
        final first = p.getInt('radioDiceNewFrom') ?? DateTime.now().millisecondsSinceEpoch;
        if (!p.containsKey('radioDiceNewFrom')) p.setInt('radioDiceNewFrom', first);
        final days = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(first)).inDays;
        _diceNew = (p.getInt('radioDiceCount') ?? 0) < 3 && days < 7;
        _diceIntro = !(p.getBool('radioDiceIntroSeen') ?? false);
      });
      _maybeShowDiceTip();
    });
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
            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, 
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

  // 주사위는 수도권 방송만 (지역 방송은 빼기) · 아래 방송은 덜 나오게
  static const _diceLow = ['국악FM', 'CPBC 가톨릭'];

  List<DiceStation> _dicePool() => [
        for (final ks in koreanStations)
          if (ks.region == '수도권')
            DiceStation(
              weight: _diceLow.contains(ks.name) ? 0.3 : 1.0,
              station: _toRadioStation(ks),
              badge: ks.broadcaster,
              image: (r) => (r.currentProgramFor(ks.name)?['image'] ?? '').toString(),
              frequency: ks.frequency,
              program: (r) {
                final p = r.currentProgramFor(ks.name);
                final t = r.nowPlayingFor(ks.name) ?? p?['title']?.toString() ?? '';
                return t.trim();
              },
            ),
      ];

  Future<void> _openDice() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (_diceTip) setState(() => _diceTip = false);
    // 던진 횟수 세기 (3번 던지면 NEW 사라짐)
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt('radioDiceCount') ?? 0) + 1;
    await p.setInt('radioDiceCount', count);
    if (_diceIntro) await p.setBool('radioDiceIntroSeen', true);
    if (!mounted) return;
    setState(() {
      _diceIntro = false;
      if (count >= 3) _diceNew = false;
    });
    if (!mounted) return;
    await showRadioDice(context, _dicePool(), onOpen: (st) {
      // 전체 목록 순서 그대로 넘겨서 상세 화면에서 이전/다음도 되게
      final list = koreanStations.map(_toRadioStation).toList();
      final i = list.indexWhere((s) => s.name == st.name);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(
            station: i >= 0 ? list[i] : st,
            stationList: list,
            currentIndex: i >= 0 ? i : 0,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    });
    // 판이 닫히면: 주사위로 나와서 듣고 있는 방송을 카드에 그대로
    if (!mounted) return;
    final cur = context.read<RadioProvider>().currentStation?.name;
    if (cur != null && koreanStations.any((k) => k.name == cur)) {
      setState(() => _diceChoice = cur);
    }
  }

  Future<void> _closeDiceIntro() async {
    setState(() => _diceIntro = false);
    final p = await SharedPreferences.getInstance();
    await p.setBool('radioDiceIntroSeen', true);
  }

  // ───── 맨 위 사진 카드: 지금 듣기 좋은 방송 ─────
  /// ① 이 시간대(아침·낮·저녁·밤)에 들었던 방송 (최근 것부터)  ② 없으면 시간대별 기본
  /// 지금 듣고 있는 방송은 빼기
  int _pickNiceIndex(RadioProvider radio) {
    int slot(DateTime t) {
      final h = t.hour;
      if (h >= 5 && h < 11) return 0;
      if (h >= 11 && h < 17) return 1;
      if (h >= 17 && h < 22) return 2;
      return 3;
    }

    final s = slot(DateTime.now());
    final cur = radio.currentStation?.name;
    for (final r in radio.recentlyListened) {
      final t = r.lastListened;
      if (t == null || slot(t) != s || r.name == cur) continue;
      final i = koreanStations.indexWhere((k) => k.name == r.name);
      if (i >= 0) return i;
    }
    const defaults = [
      ['KBS 제1라디오', 'MBC 표준FM', 'SBS 러브FM'], // 아침: 뉴스·아침 방송
      ['MBC FM4U', 'KBS Cool FM', 'SBS 파워FM'], // 낮: 가요
      ['SBS 파워FM', 'KBS 해피FM', 'MBC FM4U'], // 저녁: 퇴근길 음악
      ['KBS Classic FM', 'CBS 음악FM', 'MBC 올댓뮤직'], // 밤: 잔잔한 음악
    ];
    for (final n in defaults[s]) {
      if (n == cur) continue;
      final i = koreanStations.indexWhere((k) => k.name == n);
      if (i >= 0) return i;
    }
    return 0;
  }

  Widget _nowNiceCard(BuildContext context, RadioProvider radio, List<RadioStation> list) {
    final diceI = _diceChoice == null ? -1 : koreanStations.indexWhere((k) => k.name == _diceChoice);
    final i = diceI >= 0 ? diceI : _pickNiceIndex(radio);
    final ks = koreanStations[i];
    final prog = radio.nowPlayingFor(ks.name) ?? (radio.currentProgramFor(ks.name)?['title'] as String?) ?? '';
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    const ink = Color(0xFF17140F);
    void open() {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RadioPlayerScreen(station: list[i], stationList: list, currentIndex: i),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }

    return GestureDetector(
      onTap: open,
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ink.withOpacity(isDark ? 0.45 : 0.13),
              blurRadius: 20,
              spreadRadius: -3,
              offset: const Offset(0, 10),
            ),
            BoxShadow(color: ink.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 68, // 사진은 글자 띠 위에만 (라디오가 안 가려지게)
                child: Image.asset(
                _heroImageNow(), // 아침·낮·저녁·밤 사진
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.2),
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),
              ),
              ),
              // 사진 아래 크림 띠 (잠시 쉬어가요 카드와 같은 색)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBF8F2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(diceI >= 0 ? '주사위가 고른 방송' : '지금 듣기 좋은',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                            const SizedBox(height: 1),
                            Text(ks.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            if (prog.isNotEmpty)
                              Text(prog,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(color: ink.withOpacity(0.62), fontSize: 12)),
                          ],
                        ),
                      ),
                      // 🎲 주사위 (오른쪽 위 아이콘을 여기로)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _openDice,
                            child: AnimatedRotation(
                              turns: _diceWiggle,
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeInOut,
                              child: Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                // 크림 띠 위에서 또렷하게: 홈 바탕과 같은 베이지
                                decoration: const BoxDecoration(color: Color(0xFFEDE7DA), shape: BoxShape.circle),
                                child: const RollDiceIcon(size: 21, color: ink),
                              ),
                            ),
                          ),
                          // 주사위 왼쪽 말풍선 "던져보세요!" (사진을 안 가리게 띠 안에서 옆으로)
                          Positioned(
                            right: 46,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                opacity: _diceTip ? 1 : 0,
                                duration: const Duration(milliseconds: 280),
                                child: AnimatedSlide(
                                  offset: _diceTip ? Offset.zero : const Offset(0.08, 0),
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                          decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(11)),
                                          child: const Text('던져보세요!',
                                              textScaler: TextScaler.noScaling,
                                              style: TextStyle(
                                                  color: Color(0xFFF4EFE5), fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                        // 꼬리 (주사위 쪽)
                                        Transform.translate(
                                          offset: const Offset(-5, 0),
                                          child: Transform.rotate(
                                            angle: 0.785398,
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(2)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // ▶ 듣기
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFF4EFE5), size: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd, // 이미 보이면 안 움직임 → 맨 위 카드 그대로
          );
        }
      }
    });

    return _DialHost(
      tickColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),
      child: ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: koreanStations.length + 1,
      separatorBuilder: (_, i) => i == 0
          ? const SizedBox(height: 6)
          : _DialEffect(
              child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),
      itemBuilder: (context, n) {
        if (n == 0) return _nowNiceCard(context, radioProvider, radioStations); // 맨 위 사진 카드
        final i = n - 1;
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

        actions: [
          // 주사위는 맨 위 사진 카드 안으로 옮김
          const SizedBox(width: 6),
        ],
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
                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.25)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
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
                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, color: baseColor, fontSize: 13, fontWeight: FontWeight.w700)),
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
                              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, 
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
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: switch (_mode) {
              _ViewMode.all => _buildAllList(context, radioProvider),
              _ViewMode.broadcaster => _buildBroadcasterGrid(context, radioProvider),
              _ViewMode.region => _buildRegionGrid(context),
              _ViewMode.recent => _buildRecentList(context, radioProvider),
            },
          ),
          if (_diceIntro) Positioned.fill(child: RadioDiceIntro(onThrow: _openDice, onClose: _closeDiceIntro)),
        ],
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
                // 홈 '최근에 들었어요'와 같은 파스텔 (듣는 중이면 강조 색 테두리)
                decoration: BoxDecoration(
                  color: _brandPastel(station.broadcaster).withOpacity(isDarkMode ? 0.9 : 1),
                  borderRadius: BorderRadius.circular(10),
                  // (듣는 중이어도 테두리 없이 파스텔 그대로)
                ),
                alignment: Alignment.center,
                child: Text(
                  station.broadcaster,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: const Color(0xFF17140F).withOpacity(0.8),
                    fontSize: station.broadcaster.length > 3 ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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
                      // 라디오 목록 방송 이름 (설정 글꼴)
                      style: TextStyle(
                        color: isPlaying ? primaryColor : baseColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
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
                            _stationDesc(station), // 지역 · 방송 성격
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: baseColor.withOpacity(0.55),
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
                            if (displayNowPlaying == null || displayNowPlaying.isEmpty)
                            Text(
                              _stationDesc(station), // 지역 · 방송 성격
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: baseColor.withOpacity(0.55),
                                fontSize: 12,
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
                          size: 18,
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
    // 손가락으로 직접 끌 때만 (하트 눌러서 목록이 살짝 바뀌는 건 무시)
    final byFinger = (n is ScrollStartNotification && n.dragDetails != null) ||
        (n is ScrollUpdateNotification && n.dragDetails != null);
    if (byFinger) {
      // 끌 때마다 다시 켜기 (손 떼고 1초 안에 또 올려도 다이얼이 되게)
      _relaxTimer?.cancel();
      _heartTimer?.cancel();
      _scrolling.value = true;
      if (_strength.status != AnimationStatus.forward && _strength.status != AnimationStatus.completed) {
        _strength.forward();
      }
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

/// 지금 시간대 사진 (아침 5~11시 · 낮 11~17시 · 저녁 17~22시 · 밤)
String _heroImageNow() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 11) return 'assets/radio_hero_morning.jpg';
  if (h >= 11 && h < 17) return 'assets/radio_hero_day.jpg';
  if (h >= 17 && h < 22) return 'assets/radio_hero_evening.jpg';
  return 'assets/radio_hero_night.jpg';
}

/// 방송사 파스텔 (홈 '최근에 들었어요'와 같은 색)
Color _brandPastel(String b) {
  switch (b) {
    // 파스텔을 바탕(베이지)과 반쯤 섞어 은은하게
    case 'KBS':
      return const Color(0xFFE1E4E3); // 하늘
    case 'MBC':
      return const Color(0xFFF0E0D2); // 복숭아
    case 'SBS':
      return const Color(0xFFE4E6D6); // 연두
    case 'CBS':
      return const Color(0xFFE5DEE1); // 라벤더
    case 'EBS':
      return const Color(0xFFEEE5CE); // 노랑
    default:
      return const Color(0xFFEAE3D6); // 그 밖: 연한 베이지
  }
}

/// 미디어 출력용: 방송 이름 → 목록과 같은 설명 (없으면 null)
String? koreanStationDesc(String name) {
  for (final s in koreanStations) {
    if (s.name == name) return _stationDesc(s);
  }
  return null;
}

/// 방송 둘째 줄: '지역 · 방송 성격' (예: 서울 · 뉴스·시사)
String _stationDesc(_KStation s) {
  const exact = {
    'KBS Cool FM': '가요·팝',
    'KBS 3라디오': '사회·복지',
    'MBC 올댓뮤직': '음악',
    'SBS 파워FM': '가요·예능',
    'SBS 러브FM': '시사·생활',
    'CBS 음악FM': '음악',
    'CBS 표준FM': '시사·종교',
    'YTN 라디오': '뉴스·시사',
    'TBS FM': '교통·생활',
    'TBS eFM': '영어 방송',
    'EBS FM': '교육',
    'EBS 반디': '외국어 학습',
    'OBS 라디오': '음악·생활',
    '경인방송': '음악·생활',
    'CPBC 가톨릭': '종교·음악',
    'FEBC 극동방송': '종교·음악',
    'BBS 불교방송': '종교·음악',
    '국악FM': '국악',
    '국방FM': '국군 방송',
    'BeFM': '영어 방송',
    'JTV 매직FM': '음악·생활',
  };
  final n = s.name;
  String? g = exact[n];
  if (g == null) {
    if (n.startsWith('TBN')) {
      g = '교통 정보';
    } else if (n.contains('1라디오')) {
      g = '뉴스·시사';
    } else if (n.contains('해피FM')) {
      g = '가요·생활';
    } else if (n.contains('1FM') || n.contains('Classic')) {
      g = '클래식';
    } else if (n.contains('FM4U')) {
      g = '음악';
    } else if (n.contains('표준FM')) {
      g = '시사·교양';
    }
  }
  final loc = (s.subLabel.isEmpty || s.subLabel == '외국어') ? '서울' : s.subLabel;
  return g == null ? loc : '$loc · $g';
}
