import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import '../utils/title_font.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/logo_shine.dart';
import '../widgets/heart_pop.dart';
import 'radio_player_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'radio_home_screen.dart';
import '../widgets/radio_dice.dart';
import '../podcast/podcast.dart';
import '../podcast/podcast_screens.dart';
import '../widgets/more_menu_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_holder.dart';
import '../utils/point_color.dart';
import 'paran_intro_screen.dart';
enum _ViewMode { all, broadcaster, region, podcast, recent }

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
    '대구/경북': Color(0xFF4A1E5C), // 자주 (정치색 오해 없게 빨강·녹색 안 씀)
    '광주/전남': Color(0xFF5A4632), // 회갈
    '전북': Color(0xFF33405A), // 회청
    '대전/충남': Color(0xFF6B4A1E),
    '충북': Color(0xFF2E5C5C),
    '강원': Color(0xFF3A2E5C),
    '제주': Color(0xFF1E5C4A),
  };

  /// 지역마다 아이콘 (방송사별 칸과 같은 모양: 큰 아이콘을 은은하게)
  static const Map<String, IconData> _regionIcons = {
    '수도권': Icons.location_city_rounded,
    '강원': Icons.terrain_rounded,
    '대전/충남': Icons.science_rounded,
    '충북': Icons.water_rounded,
    '대구/경북': Icons.account_balance_rounded,
    '전북': Icons.eco_rounded,
    '광주/전남': Icons.local_florist_rounded,
    '부산/경남': Icons.waves_rounded,
    '제주': Icons.beach_access_rounded,
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
      // 편성표 파일(schedule.json)에 있는 방송은 전부 미리 (없는 방송은 알아서 건너뜀)
      for (final station in koreanStations) {
        radio.fetchJsonSchedule(station.name);
      }
      radio.fetchEbsFmSchedule();
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
          if (mode == _ViewMode.podcast) PodNewMark.seen(); // 색연필 동그라미 지우기
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // B2: 박스 없이 고른 탭 아래에만 진한 밑줄
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
          // 글자가 커도 한 줄 (넘치면 칸에 맞게 살짝 줄임) · 팟캐스트는 색연필 동그라미
          child: PodPencilCircle(
            enabled: mode == _ViewMode.podcast,
            child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textScaler: TextScaler.noScaling, // 탭은 라디오 글자 크기 설정과 상관없이 고정
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
      ),
    );
  }

  // 주사위: 수도권만 · 외국어·지방은 빼기 · 종교와 아래 방송은 가끔(0.3) · 지금 사진 있는 방송은 조금 더(×1.5)
  static const _diceOut = {'FEBC 극동방송 AM', '수원 SoneFM'}; // AM은 FM과 같은 방송 · SoneFM은 편성표 없음
  static const _diceLow = {'국악FM', '국방FM', 'EBS FM', 'CBS JOY4U', 'MBC 올댓뮤직', 'TBN 경인교통', '마포FM'};

  double? _diceWeight(_KStation ks, RadioProvider r) {
    if (ks.region != '수도권' || _diceOut.contains(ks.name)) return null;
    final c = stationCategory(ks);
    if (c == 2) return null; // 외국어
    var w = (c == 3 || _diceLow.contains(ks.name)) ? 0.3 : 1.0;
    final img = (r.currentProgramFor(ks.name)?['image'] ?? '').toString();
    if (img.isNotEmpty) w *= 1.5;
    return w;
  }

  // 주사위 판: 지금 방송 쉬는 채널 · 방금 주사위로 나온 방송은 빼기 (그러면 너무 적으면 그냥 전부)
  List<DiceStation> _dicePool() {
    final radio = context.read<RadioProvider>();
    final all = _dicePoolAll();
    final pool = all
        .where((d) => !radio.isOffAirNow(d.station.name) && d.station.name != _diceChoice)
        .toList();
    return pool.length >= 3 ? pool : all;
  }

  List<DiceStation> _dicePoolAll() {
    final r = context.read<RadioProvider>();
    return [
        for (final ks in koreanStations)
          if (_diceWeight(ks, r) != null)
            DiceStation(
              weight: _diceWeight(ks, r)!,
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
  }

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
      final list = koreanStationsSorted.map(_toRadioStation).toList();
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
      // 최근에 들었어도 지방·외국어·극동 AM·SoneFM은 건너뛰기 (주사위와 같은 규칙)
      if (i >= 0 &&
          koreanStations[i].region == '수도권' &&
          stationCategory(koreanStations[i]) <= 1 &&
          !_diceLow.contains(koreanStations[i].name)) return i;
    }
    const defaults = niceDefaults;
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
          borderRadius: BorderRadius.circular(10),
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
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 68, // 사진은 글자 띠 위에만 (라디오가 안 가려지게)
                // 다크 모드: 홈 사진과 같게 색 반쯤 빼고 살짝 어둡게
                child: ColorFiltered(
                  colorFilter: isDark
                      ? const ColorFilter.matrix(<double>[
                          0.4082, 0.2832, 0.0286, 0, 0,
                          0.0842, 0.6072, 0.0286, 0, 0,
                          0.0842, 0.2832, 0.3526, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Image.asset(
                    _heroImageNow(), // 아침·낮·저녁·밤 사진
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),
                  ),
                ),
              ),
              // 채널 수가 밝은 사진에서도 보이게: 오른쪽 위 모서리만 아주 살짝 어둡게 (칸처럼 안 보이게 번지듯)
              Positioned(
                top: 0,
                right: 0,
                width: 150,
                height: 70,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.0,
                        colors: [Colors.black.withOpacity(0.38), Colors.black.withOpacity(0)],
                      ),
                    ),
                  ),
                ),
              ),
              // 사진 오른쪽 위: ● 102 채널 (홈 라디오 카드와 같은 모양, 사진 위라 흰 글자 + 옅은 그림자)
              Positioned(
                top: 10,
                right: 12,
                child: Builder(builder: (context) {
                  final lang = Localizations.localeOf(context).languageCode;
                  const shadow = [Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1))];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LiveDot(size: 7), // 빨간 점: 천천히 깜빡임
                      const SizedBox(width: 6),
                      Text('${koreanStations.length}',
                          textScaler: TextScaler.noScaling,
                          style: GoogleFonts.quicksand(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, shadows: shadow)),
                      // 단위는 홈과 같게: 한국어 '채널' · 일본어 '局', 나머지는 숫자만
                      if (lang == 'ko' || lang == 'ja') ...[
                        const SizedBox(width: 2),
                        Text(lang == 'ja' ? '局' : '채널',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                shadows: shadow)),
                      ],
                    ],
                  );
                }),
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
                            Text(diceI >= 0 ? tr.heroDicePick : tr.niceNow,
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
                                          child: Text(tr.tryRolling,
                                              textScaler: TextScaler.noScaling,
                                              style: const TextStyle(
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
    final radioStations = koreanStationsSorted.map((ks) => _toRadioStation(ks)).toList(); // 화면 순서(카테고리별) 그대로

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

    // 카테고리별로 나눈 목록: 제목 줄(-1 - 카테고리) + 방송 줄(정렬된 목록 번호)
    final items = <int>[];
    var lastCat = -99;
    for (var j = 0; j < koreanStationsSorted.length; j++) {
      final c = stationCategory(koreanStationsSorted[j]);
      if (c != lastCat) {
        items.add(-1 - c);
        lastCat = c;
      }
      items.add(j);
    }
    final catCounts = <int, int>{};
    for (final s in koreanStationsSorted) {
      final c = stationCategory(s);
      catCounts[c] = (catCounts[c] ?? 0) + 1;
    }
    final baseC = isDarkMode ? Colors.white : Colors.black;

    return _DialHost(
      tickColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),
      child: ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: items.length + 1,
      separatorBuilder: (_, i) => i == 0
          ? const SizedBox(height: 6)
          : (items[i - 1] < 0 || (i < items.length && items[i] < 0)) // 카테고리 제목 앞뒤는 선 없이
              ? const SizedBox.shrink()
              : _DialEffect(
                  child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),
      itemBuilder: (context, n) {
        if (n > 0 && items[n - 1] < 0) {
          // 카테고리 제목: 이름 · 개수 뒤로 가는 선
          final c = -1 - items[n - 1];
          return _DialEffect(
            child: Padding(
              padding: EdgeInsets.only(top: n == 1 ? 6 : 22, bottom: 6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      stationCategoryLabel(context, c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: baseC.withOpacity(0.72), fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${catCounts[c] ?? 0}',
                      style: GoogleFonts.quicksand(color: baseC.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 1, color: baseC.withOpacity(0.18))),
                ],
              ),
            ),
          );
        }
        if (n == 0) return _nowNiceCard(context, radioProvider, radioStations); // 맨 위 사진 카드
        final i = items[n - 1];
        final ks = koreanStationsSorted[i];
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
          tr.noRecentStations,
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
        // 왼쪽 시간 배지: 위 '14:05' · 아래 '오늘/어제/10.14'
        final hmStr = lastListened != null
            ? '${lastListened.hour.toString().padLeft(2, '0')}:${lastListened.minute.toString().padLeft(2, '0')}'
            : '';
        String dayStr = '';
        if (lastListened != null) {
          final now = DateTime.now();
          final diff = DateTime(now.year, now.month, now.day)
              .difference(DateTime(lastListened.year, lastListened.month, lastListened.day))
              .inDays;
          dayStr = diff == 0
              ? AppLocalizations.of(context)!.today
              : diff == 1
                  ? AppLocalizations.of(context)!.yesterday
                  : '${lastListened.month.toString().padLeft(2, '0')}.${lastListened.day.toString().padLeft(2, '0')}';
        }
        // 아래 줄: 국내는 '지역 · 방송 성격', 해외는 나라 이름
        final descStr = koreanStationDesc(station.name) ?? (() {
          // 해외 방송은 나라 이름을 앱 언어로 (목록에 없는 나라는 원래 이름)
          final cc = station.countryCode?.toUpperCase();
          for (final c in RadioCountry.supported) {
            if (c.code == cc) return c.displayName;
          }
          return station.country ?? '';
        })();
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
                // 시간 배지 (듣는 중이면 강조 색)
                SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hmStr,
                        textScaler: TextScaler.noScaling,
                        maxLines: 1,
                        style: GoogleFonts.quicksand(
                          color: isPlaying ? primaryColorOf(context) : baseColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(fit: BoxFit.scaleDown, child: Text( // 긴 말(Aujourd'hui 등)은 칸에 맞게 줄임
                        dayStr,
                        textScaler: TextScaler.noScaling,
                        maxLines: 1,
                        style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 10.5),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2068${station.name}\u2069', // 'Dance Wave!' 느낌표가 앞으로 가지 않게
                        style: TextStyle(
                          color: isPlaying ? primaryColorOf(context) : baseColor,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (descStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          descStr,
                          style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  /// 지역 이름 (저장은 한국어 그대로, 화면엔 언어에 맞게)
  static String _regionLabel(String r) => switch (r) {
        '수도권' => tr.regionCapital,
        '부산/경남' => tr.regionBusanGyeongnam,
        '대구/경북' => tr.regionDaeguGyeongbuk,
        '광주/전남' => tr.regionGwangjuJeonnam,
        '전북' => tr.regionJeonbuk,
        '대전/충남' => tr.regionDaejeonChungnam,
        '충북' => tr.regionChungbuk,
        '강원' => tr.regionGangwon,
        '제주' => tr.regionJeju,
        _ => r,
      };

  /// 지역별 마지막 빈칸: Paransori 브랜드 카드 (⋮ 메뉴 아래 먹색 카드와 한 세트) → 누르면 파란소리 소개
  Widget _regionBrandCard(BuildContext context, bool isDarkMode) {
    // 라이트: 먹색 카드 · 크림 글자 / 다크: 크림 카드 · 먹색 글자 (바탕과 반대)
    final bg = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final blue = pointColorOf(context, onDark: !isDarkMode);
    final n = koreanStations.length;
    final line = AppLocalizations.of(context)!.regionBrandLine(n);
    return GestureDetector(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ParanIntroScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10), // 지역 칸과 같은 모서리·그림자
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Paran', style: TextStyle(color: blue)),
                    const TextSpan(text: 'sori'),
                  ]),
                  textScaler: TextScaler.noScaling,
                  style: GoogleFonts.quicksand(
                      color: fg, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.1),
                ),
                const SizedBox(width: 6),
                // 작은 소리 막대 (로고 느낌)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, h) in const [5.0, 9.0, 12.0, 7.0].indexed) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Container(
                          width: 2.5,
                          height: h,
                          decoration: BoxDecoration(
                              color: blue.withOpacity(0.85), borderRadius: BorderRadius.circular(2)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              line,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                  color: fg.withOpacity(0.72), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

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
      itemCount: regionList.length + 1, // 9개 지역 + 마지막 빈칸에 브랜드 카드
      itemBuilder: (context, index) {
        if (index == regionList.length) return _regionBrandCard(context, isDarkMode);
        final region = regionList[index];
        final count = koreanStations.where((s) => s.region == region).length;
        return GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            final stations = koreanStations.where((s) => s.region == region).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: _BroadcasterStationList(broadcaster: region, stations: stations, color: _regionColors[region] ?? const Color(0xFF3A342A), icon: _regionIcons[region] ?? Icons.place_rounded)), // 라디오 목록 글자 크기 맞추기 (전체 목록과 같게)
              ),
            );
          },
          // B안 (방송사별과 같은 모양): 지역 색 바탕(살짝 그라데이션) + 오른쪽 위 큰 아이콘(은은하게) + 왼쪽 위 작은 아이콘 + 왼쪽 아래 이름·채널 수
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _softDark(_regionColors[region] ?? const Color(0xFF3A342A), isDarkMode),
                  _softDark(_regionColors[region] ?? const Color(0xFF3A342A), isDarkMode).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10), // 홈 카드와 같은 둥글기
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 오른쪽 위 큰 아이콘 (배경 무늬처럼 은은하게, 칸 밖으로 살짝 잘리게)
                Positioned(
                  right: -6,
                  top: -2,
                  child: Icon(_regionIcons[region] ?? Icons.place_rounded,
                      size: 60, color: Colors.white.withOpacity(0.10)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 이름·채널 수: 남은 높이를 다 쓰고, 길거나 글자를 크게 해도 칸 안에 맞게 살짝 작게
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _regionLabel(region),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr.channelsCount(count),
                                maxLines: 1,
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11.5),
                              ),
                            ],
                          ),
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
          // ⋮ 메뉴 — 홈·라디오 재생 화면과 같은 메뉴
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              showMoreMenuSheet(context);
            },
            icon: Icon(Icons.more_vert, color: baseColor, size: 22),
          ),
          const SizedBox(width: 6),
        ],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 + 제목(회색 빛) / 아래 설명 — 홈 로고와 같은 짜임 (해외는 그 나라 말)
            Flexible(child: MenuTitle(title: tr.catRadio, sub: tr.catRadioSub, isDark: isDarkMode)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Column(
              children: [
                // B2: 국가 선택을 위로 (가끔 바꾸는 것) → 아래 탭 → 목록
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // 줄 어디를 눌러도 나라 고르기
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
                    );
                  },
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        const SizedBox(width: 2),
                        // '국가 선택' 글자 없이 국기 · 나라 이름 · ▾만 왼쪽에
                        const Text('🇰🇷', style: TextStyle(fontSize: 13.5)),
                        const SizedBox(width: 6),
                        Text(tr.countryKR,
                            maxLines: 1,
                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: baseColor.withOpacity(0.45)),
                        const Spacer(), // 줄 나머지도 눌리게 (나라 고르기)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // B2: 탭은 박스 없이 글자 + 아래 얇은 선 (고른 탭만 진한 밑줄)
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12), width: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _toggleButton(tr.all, _ViewMode.all, isDarkMode),
                      _toggleButton(tr.byBroadcaster, _ViewMode.broadcaster, isDarkMode),
                      _toggleButton(tr.byRegion, _ViewMode.region, isDarkMode),
                      _toggleButton(podText('팟캐스트', 'Podcasts'), _ViewMode.podcast, isDarkMode),
                      _toggleButton(tr.recentListened, _ViewMode.recent, isDarkMode),
                    ],
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
              _ViewMode.podcast => const PodcastTab(country: 'kr'),
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
          : (context.watch<PodcastPlayer>().active
              ? Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom), child: const PodcastMiniPlayer())
              : null),
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
                  color: _brandPastel(station.broadcaster, isDarkMode), // 방송사별 박스와 같은 색 계열
                  borderRadius: BorderRadius.circular(10),
                  // (듣는 중이어도 테두리 없이 파스텔 그대로)
                ),
                alignment: Alignment.center,
                child: Text(
                  station.broadcaster,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFFF3EFE7).withOpacity(0.85) : const Color(0xFF17140F).withOpacity(0.8),
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
                        fontWeight: FontWeight.w500,
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
                                TextSpan(text: station.frequency.replaceAll(' MHz', '').replaceAll(' kHz', '').trim()),
                                if (station.frequency.trim().isNotEmpty)
                                  TextSpan(
                                    text: station.frequency.contains('kHz') ? ' kHz' : ' MHz', // AM이면 kHz
                                    style: GoogleFonts.quicksand(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: (tuned ? primaryColor : baseColor).withOpacity(tuned ? 0.75 : 0.35),
                                    ),
                                  ),
                              ]),
                              key: const ValueKey('freq'),
                              textDirection: TextDirection.ltr, // 97.1 MHz 순서 그대로
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

/// 시간대별 '지금 듣기 좋은' 기본 방송 (아침·낮·저녁·밤) — 라디오 목록 맨 위 카드와 메인 홈 카드가 같이 씀
const niceDefaults = [
  ['KBS 제1라디오', 'MBC 표준FM', 'SBS 러브FM'], // 아침: 뉴스·아침 방송
  ['MBC FM4U', 'KBS Cool FM', 'SBS 파워FM'], // 낮: 가요
  ['SBS 파워FM', 'KBS 해피FM', 'MBC FM4U'], // 저녁: 퇴근길 음악
  ['KBS Classic FM', 'CBS 음악FM', 'MBC 올댓뮤직'], // 밤: 잔잔한 음악
];

/// 메인 홈 카드용: 안 들어 본 국내 방송 하나 (지금 시간대 추천 → 다른 시간대 추천 → 전체 목록 순서)
/// skip: 최근에 들은 방송·지금 듣는 방송 / 모두 들어 봤으면 null
/// 국내 라디오 전체 목록 (목록 화면 순서 그대로) — 홈 '최근에 들었어요'에서 이전·다음 쓰려고
List<RadioStation> koreanRadioStations() =>
    koreanStationsSorted.map(_RadioKoreaScreenState._toRadioStation).toList();

RadioStation? niceKoreanStationNow({Set<String> skip = const {}, int day = 0}) {
  final h = DateTime.now().hour;
  final s = (h >= 5 && h < 11) ? 0 : (h >= 11 && h < 17) ? 1 : (h >= 17 && h < 22) ? 2 : 3;
  final names = <String>[
    ...niceDefaults[s],
    for (var k = 1; k < 4; k++) ...niceDefaults[(s + k) % 4],
  ];
  for (final n in names) {
    if (skip.contains(n)) continue;
    final i = koreanStations.indexWhere((k) => k.name == n);
    if (i >= 0) return _RadioKoreaScreenState._toRadioStation(koreanStations[i]);
  }
  // 다 들어 봤으면: 주사위와 같은 규칙 (수도권만 · 외국어·극동 AM·SoneFM 빼기)
  final rest = koreanStations
      .where((k) =>
          !skip.contains(k.name) &&
          k.region == '수도권' &&
          stationCategory(k) != 2 &&
          !_RadioKoreaScreenState._diceOut.contains(k.name))
      .toList();
  if (rest.isEmpty) return null;
  return _RadioKoreaScreenState._toRadioStation(rest[day % rest.length]);
}

// ── 전체 목록 카테고리 · 정렬 ──
// 0 주요 방송 · 1 음악·시사 · 2 외국어 · 3 종교 방송 · 4 교통 방송 · 5 지역 방송 · 6 공동체 라디오
const _foreignNames = {'아리랑 라디오', 'TBS eFM', 'BeFM', 'EBS 반디'};

int stationCategory(_KStation s) {
  if (s.broadcaster == '공동체') return 6;
  if (s.broadcaster == 'TBN') return 4;
  if (_foreignNames.contains(s.name)) return 2;
  if (const {'CPBC', 'FEBC', 'BBS'}.contains(s.broadcaster)) return 3;
  if (s.region == '수도권') return const {'KBS', 'MBC', 'SBS'}.contains(s.broadcaster) ? 0 : 1;
  return 5;
}

String stationCategoryLabel(BuildContext context, int c) {
  final l = AppLocalizations.of(context)!;
  return [
    l.stationCatMajor,
    l.stationCatMusicNews,
    l.stationCatForeign,
    l.stationCatReligion,
    l.stationCatTraffic,
    l.stationCatRegional,
    l.stationCatCommunity,
  ][c];
}

const _regionOrder = ['수도권', '부산/경남', '대구/경북', '광주/전남', '전북', '대전/충남', '충북', '강원', '제주'];
const _brandOrder = ['KBS', 'MBC', 'SBS', 'TBC', 'JTV', 'EBS', 'CBS', 'YTN', 'TBS', 'OBS', 'CPBC', 'FEBC', 'BBS',
    '국악방송', '국방FM', 'Arirang', 'BeFM', 'TBN', '공동체'];
// 같은 방송사·도시 안 채널 순서 (1라디오 → 해피FM → 1FM …)
const _channelOrder = [('1라디오', 1), ('표준FM', 1), ('러브FM', 1), ('해피FM', 2), ('음악FM', 2), ('파워FM', 2),
    (' AM', 2), ('1FM', 3), ('Classic', 3), ('JOY4U', 3), ('Cool', 4), ('FM4U', 4), ('3라디오', 5), ('올댓뮤직', 6)];

int _channelRank(String name) {
  for (final (k, r) in _channelOrder) {
    if (name.contains(k)) return r;
  }
  return 0;
}

/// 전체 목록 화면 순서: 카테고리 → 지역 → 방송사 → 도시 → 채널
final List<_KStation> koreanStationsSorted = () {
  int idx(List<String> l, String v) {
    final i = l.indexOf(v);
    return i < 0 ? 99 : i;
  }

  int city(_KStation s) => koreanStations.indexWhere((k) => k.region == s.region && k.subLabel == s.subLabel);
  final l = [...koreanStations];
  final orig = {for (var i = 0; i < koreanStations.length; i++) koreanStations[i].name: i};
  l.sort((a, b) {
    for (final d in [
      stationCategory(a) - stationCategory(b),
      idx(_regionOrder, a.region) - idx(_regionOrder, b.region),
      idx(_brandOrder, a.broadcaster) - idx(_brandOrder, b.broadcaster),
      city(a) - city(b),
      _channelRank(a.name) - _channelRank(b.name),
      orig[a.name]! - orig[b.name]!,
    ]) {
      if (d != 0) return d;
    }
    return 0;
  });
  return l;
}();

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
  _KStation(name: 'TBN 경인교통', region: '수도권', broadcaster: 'TBN', subLabel: '경기', frequency: '100.5 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gyeongin/myStream/playlist.m3u8'),
  _KStation(name: 'CBS JOY4U', region: '수도권', broadcaster: 'CBS', subLabel: '서울', frequency: '', streamUrl: 'https://m-aac.cbs.co.kr/mweb_cbscmc/_definst_/cbscmc.stream/playlist.m3u8'),
  _KStation(name: 'FEBC 극동방송 AM', region: '수도권', broadcaster: 'FEBC', subLabel: '서울', frequency: '1188 kHz', streamUrl: 'http://mlive2.febc.net:1935/live/seoulam/playlist.m3u8'),
  _KStation(name: '아리랑 라디오', region: '수도권', broadcaster: 'Arirang', subLabel: '서울', frequency: '88.7 MHz', streamUrl: 'http://amdlive.ctnd.com.edgesuite.net/arirang_3ch/smil:arirang_3ch.smil/playlist.m3u8'),
  _KStation(name: '마포FM', region: '수도권', broadcaster: '공동체', subLabel: '마포', frequency: '100.7 MHz', streamUrl: 'http://onair.mapofm.net/mapofm'),
  _KStation(name: '수원 SoneFM', region: '수도권', broadcaster: '공동체', subLabel: '수원', frequency: '96.3 MHz', streamUrl: 'http://115.85.182.39/sonefm'),
  // 부산MBC: 방송 서버가 응답 없음 + 홈페이지 생방송은 로그인 필요 (2026-10-16) — 살아나면 // 지우기
  // _KStation(name: '부산MBC 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '부산', frequency: '95.9 MHz', streamUrl: 'https://stream.bsmbc.com/live/BusanMBC_AM_onairstream.sbhhqc/playlist.m3u8'),
  // _KStation(name: '부산MBC FM4U', region: '부산/경남', broadcaster: 'MBC', subLabel: '부산', frequency: '88.9 MHz', streamUrl: 'https://stream.bsmbc.com/live/mp4:BusanMBC.Live-FM-0415/playlist.m3u8'),
  _KStation(name: '울산MBC 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '울산', frequency: '97.5 MHz', streamUrl: 'https://5ddfd163bd00d.streamlock.net/STDFM/STDFM/playlist.m3u8'),
  _KStation(name: '울산MBC FM4U', region: '부산/경남', broadcaster: 'MBC', subLabel: '울산', frequency: '98.7 MHz', streamUrl: 'https://5ddfd163bd00d.streamlock.net/FM4U/FM4U/playlist.m3u8'),
  // MBC경남: 방송 서버 응답 없음 + 홈페이지 생방송 로그인 필요 (2026-10-16) — 살아나면 // 지우기
  // _KStation(name: 'MBC경남 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '창원', frequency: '97.9 MHz', streamUrl: 'https://624a79c87201d.streamlock.net/MBCFM/TV2.stream/playlist.m3u8'),
  _KStation(name: 'KBS 부산 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '103.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_21'),
  _KStation(name: 'KBS 부산 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_22'),
  _KStation(name: 'KBS 부산 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '92.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_24'),
  _KStation(name: 'KBS 창원 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_21'),
  _KStation(name: 'KBS 창원 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '106.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_22'),
  _KStation(name: 'KBS 창원 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '93.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_24'),
  _KStation(name: 'KBS 진주 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '진주', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/21_21'),
  _KStation(name: 'BeFM', region: '부산/경남', broadcaster: 'BeFM', subLabel: '부산', frequency: '90.5 MHz', streamUrl: 'http://befm905.live.smilecdn.com:1935/befm905_live/live/playlist.m3u8'),
  _KStation(name: 'TBN 울산교통', region: '부산/경남', broadcaster: 'TBN', subLabel: '울산', frequency: '104.1 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/ulsan/myStream/playlist.m3u8'),
  _KStation(name: 'TBN 부산교통', region: '부산/경남', broadcaster: 'TBN', subLabel: '부산', frequency: '94.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/busan/myStream/playlist.m3u8'),
  _KStation(name: 'TBN 경남교통', region: '부산/경남', broadcaster: 'TBN', subLabel: '경남', frequency: '95.5 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gyeongnam/myStream/playlist.m3u8'),
  _KStation(name: 'KBS 대구 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '101.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_21'),
  _KStation(name: 'KBS 대구 해피FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '96.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_22'),
  _KStation(name: 'KBS 대구 1FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_24'),
  _KStation(name: 'KBS 안동 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '안동', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/31_21'),
  _KStation(name: 'KBS 포항 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '포항', frequency: '95.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/32_21'),
  _KStation(name: '안동MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '97.7 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/amlive/playlist.m3u8'),
  _KStation(name: '안동MBC FM4U', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '103.1 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/fmlive/playlist.m3u8'),
  _KStation(name: '대구MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '대구', frequency: '95.7 MHz', streamUrl: 'https://5ee1ec6f32118.streamlock.net/amradio/am/playlist.m3u8'),
  _KStation(name: '포항MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '포항', frequency: '104.3 MHz', streamUrl: 'http://stream.yubinet.com:1935/live/_definst_/Radio_Am/playlist.m3u8'),
  _KStation(name: 'TBN 대구교통', region: '대구/경북', broadcaster: 'TBN', subLabel: '대구', frequency: '103.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/daegu/myStream/playlist.m3u8'),
  _KStation(name: '성서공동체FM', region: '대구/경북', broadcaster: '공동체', subLabel: '대구', frequency: '89.1 MHz', streamUrl: 'http://115.85.182.39/scnfm'),
  _KStation(name: 'TBC 드림FM', region: '대구/경북', broadcaster: 'TBC', subLabel: '대구', frequency: '99.3 MHz', streamUrl: 'http://203.251.91.122:1935/on-air-Backup/fm/playlist.m3u8'),
  _KStation(name: '광주MBC 표준FM', region: '광주/전남', broadcaster: 'MBC', subLabel: '광주', frequency: '97.9 MHz', streamUrl: 'https://media.kjmbc.co.kr/hls/amlive/GWANGJU-MBC-AM/playlist.m3u8'),
  _KStation(name: '광주MBC FM4U', region: '광주/전남', broadcaster: 'MBC', subLabel: '광주', frequency: '89.5 MHz', streamUrl: 'https://media.kjmbc.co.kr/hls/fmlive/GWANGJU-MBC-FM/playlist.m3u8'),
  _KStation(name: '목포MBC 표준FM', region: '광주/전남', broadcaster: 'MBC', subLabel: '목포', frequency: '97.9 MHz', streamUrl: 'https://vod.mpmbc.co.kr/live/encoder-am/playlist.m3u8'),
  _KStation(name: 'KBS 광주 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_21'),
  _KStation(name: 'KBS 광주 해피FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '100.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_22'),
  _KStation(name: 'KBS 광주 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '93.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_24'),
  _KStation(name: 'KBS 목포 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '105.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_21'),
  _KStation(name: 'KBS 목포 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '101.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_24'),
  _KStation(name: 'KBS 순천 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '순천', frequency: '95.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/43_21'),
  _KStation(name: 'TBN 광주교통', region: '광주/전남', broadcaster: 'TBN', subLabel: '광주', frequency: '97.3 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gwangju/myStream/playlist.m3u8'),
  _KStation(name: 'KBS 전주 1라디오', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '96.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_21'),
  _KStation(name: 'KBS 전주 해피FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_22'),
  _KStation(name: 'KBS 전주 1FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '93.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_24'),
  _KStation(name: 'JTV 매직FM', region: '전북', broadcaster: 'JTV', subLabel: '전주', frequency: '99.1 MHz', streamUrl: 'https://61ff3340258d2.streamlock.net/jtv_radio/myStream/chunklist_w111659793.m3u8'),
  _KStation(name: '전주MBC 표준FM', region: '전북', broadcaster: 'MBC', subLabel: '전주', frequency: '101.7 MHz', streamUrl: 'https://live.jmbc.co.kr/live/am_live.m3u8'),
  _KStation(name: '전주MBC FM4U', region: '전북', broadcaster: 'MBC', subLabel: '전주', frequency: '99.1 MHz', streamUrl: 'https://live.jmbc.co.kr/live/fm_live.m3u8'),
  _KStation(name: 'TBN 전북교통', region: '전북', broadcaster: 'TBN', subLabel: '전북', frequency: '102.5 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/jeonbuk/myStream/playlist.m3u8'),
  _KStation(name: '전주FM', region: '전북', broadcaster: '공동체', subLabel: '전주', frequency: '93.5 MHz', streamUrl: 'http://radiostream.communityradio.kr/jcfm1'),
  _KStation(name: '대전MBC 표준FM', region: '대전/충남', broadcaster: 'MBC', subLabel: '대전', frequency: '99.5 MHz', streamUrl: 'https://ns1.tjmbc.co.kr/live_am/live_am.stream/playlist.m3u8'),
  _KStation(name: 'KBS 대전 1라디오', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '94.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_21'),
  _KStation(name: 'KBS 대전 해피FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_22'),
  _KStation(name: 'KBS 대전 1FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '99.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_24'),
  _KStation(name: 'TBN 대전교통', region: '대전/충남', broadcaster: 'TBN', subLabel: '대전', frequency: '102.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/daejeon/myStream/playlist.m3u8'),
  _KStation(name: 'TBN 충남교통', region: '대전/충남', broadcaster: 'TBN', subLabel: '충남', frequency: '103.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/chungnam/myStream/playlist.m3u8'),
  _KStation(name: 'KBS 청주 1라디오', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '89.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_21'),
  _KStation(name: 'KBS 청주 해피FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '99.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_22'),
  _KStation(name: 'KBS 청주 1FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_24'),
  _KStation(name: 'MBC충북 표준FM', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '93.3 MHz', streamUrl: 'http://211.33.246.4:32954/radio_stfm/myStream.sdp/chunklist_w392819215.m3u8'),
  _KStation(name: 'MBC충북 FM4U', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '96.7 MHz', streamUrl: 'http://211.33.246.4:32954/radio_fm/myStream.sdp/chunklist_w348337231.m3u8'),
  _KStation(name: 'TBN 충북교통', region: '충북', broadcaster: 'TBN', subLabel: '충북', frequency: '103.3 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/chungbuk/myStream/playlist.m3u8'),
  _KStation(name: '춘천MBC 표준FM', region: '강원', broadcaster: 'MBC', subLabel: '춘천', frequency: '92.3 MHz', streamUrl: 'https://stream.chmbc.co.kr/radio1/fm1_aac/playlist.m3u8'),
  _KStation(name: '춘천MBC FM4U', region: '강원', broadcaster: 'MBC', subLabel: '춘천', frequency: '97.9 MHz', streamUrl: 'https://stream.chmbc.co.kr/live_radio2/fm1/playlist.m3u8'),
  _KStation(name: 'KBS 춘천 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '99.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_21'),
  _KStation(name: 'KBS 춘천 해피FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_22'),
  _KStation(name: 'KBS 춘천 1FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_24'),
  _KStation(name: 'KBS 강릉 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '98.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_21'),
  _KStation(name: 'KBS 강릉 1FM', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_24'),
  _KStation(name: 'KBS 원주 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_21'),
  _KStation(name: 'KBS 원주 1FM', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_24'),
  _KStation(name: 'TBN 강원교통', region: '강원', broadcaster: 'TBN', subLabel: '강원', frequency: '105.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gangwon/myStream/playlist.m3u8'),
  _KStation(name: '제주MBC 표준FM', region: '제주', broadcaster: 'MBC', subLabel: '제주', frequency: '97.9 MHz', streamUrl: 'https://onairfm.jejumbc.com/hls/onairfmjejumbc/index.m3u8'),
  _KStation(name: '제주MBC FM4U', region: '제주', broadcaster: 'MBC', subLabel: '제주', frequency: '89.9 MHz', streamUrl: 'https://onairsfm.jejumbc.com/hls/onairsfmjejumbc/index.m3u8'),
  _KStation(name: 'KBS 제주 1라디오', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '93.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_21'),
  _KStation(name: 'KBS 제주 해피FM', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_22'),
  _KStation(name: 'KBS 제주 1FM', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '96.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_24'),
  _KStation(name: 'TBN 제주교통', region: '제주', broadcaster: 'TBN', subLabel: '제주', frequency: '105.5 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/jeju/myStream/playlist.m3u8'),
  _KStation(name: 'FEBC 제주극동방송', region: '제주', broadcaster: 'FEBC', subLabel: '제주', frequency: '104.7 MHz', streamUrl: 'http://mlive2.febc.net:1935/live/jejufm/playlist.m3u8'),
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
/// 생방송 빨간 점 — 천천히 밝게·흐리게 (애니메이션 줄이기를 켜면 그대로)
class _LiveDot extends StatefulWidget {
  final double size;
  const _LiveDot({this.size = 7});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 1;
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
    const red = Color(0xFFE5484D);
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: red,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: red.withOpacity(0.22), spreadRadius: 2.5)],
        ),
      ),
    );
  }
}

/// 다크 모드에서 박스 색을 차분하게 (홈 카드처럼 색 반쯤 빼고 살짝 어둡게)
Color _softDark(Color c, bool dark) {
  if (!dark) return c;
  final h = HSLColor.fromColor(c);
  return h.withSaturation(h.saturation * 0.5).withLightness(h.lightness * 0.85).toColor();
}

class _BroadcasterGridScreen extends StatelessWidget {
  final RadioProvider radioProvider;
  const _BroadcasterGridScreen({required this.radioProvider});

  static const _order = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS', 'TBN', '종교', '지역민방', '공동체', '기타'];

  static const Map<String, Color> _cardColors = {
    'KBS': Color(0xFF14356B),
    'MBC': Color(0xFF4A1E5C),
    'SBS': Color(0xFF7A1F1F),
    'EBS': Color(0xFF0D4C6E),
    'CBS': Color(0xFF1E4A2E),
    'TBN': Color(0xFF6B4A12), // 황토
    '종교': Color(0xFF33405A), // 회청
    '지역민방': Color(0xFF6A3B22), // 적갈
    '공동체': Color(0xFF4A5320), // 올리브
  };

  /// 칸마다 아이콘 (A안: 사진 대신 큰 아이콘을 은은하게)
  static const Map<String, IconData> _cardIcons = {
    'KBS': Icons.mic_rounded,
    'MBC': Icons.headphones_rounded,
    'SBS': Icons.speaker_rounded,
    'EBS': Icons.menu_book_rounded,
    'CBS': Icons.church_rounded,
    'TBN': Icons.directions_car_rounded,
    '종교': Icons.spa_rounded,
    '지역민방': Icons.location_city_rounded,
    '공동체': Icons.park_rounded,
    '기타': Icons.radio_rounded,
  };

  /// 방송사 → 칸 (KBS·MBC·SBS·EBS·CBS는 그대로, 나머지는 묶음)
  static String _keyOf(String broadcaster) => switch (broadcaster) {
        'KBS' || 'MBC' || 'SBS' || 'EBS' || 'CBS' || 'TBN' => broadcaster,
        'FEBC' || 'BBS' || 'CPBC' => '종교',
        'TBC' || 'JTV' || 'OBS' => '지역민방', // OBS 칸에 경인방송도 같이 있음 (나중에 KNN·KBC·TJB 등도 여기로)
        '공동체' => '공동체',
        _ => '기타',
      };

  /// 칸 이름 (언어에 맞게) — 지역 칸에서 열 때는 지역 이름
  static String gridLabel(BuildContext context, String key) => switch (key) {
        '기타' => tr.categoryEtc,
        '종교' => stationCategoryLabel(context, 3),
        '공동체' => stationCategoryLabel(context, 6),
        '지역민방' => _privateLabel(context),
        _ => _RadioKoreaScreenState._regionLabel(key),
      };

  /// '지역 민방' (번역 파일)
  static String _privateLabel(BuildContext context) => AppLocalizations.of(context)!.stationCatPrivate;

  Map<String, List<_KStation>> _grouped() {
    final Map<String, List<_KStation>> map = {};
    for (final s in koreanStations) {
      final key = _keyOf(s.broadcaster);
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
                builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: _BroadcasterStationList(broadcaster: key, stations: stations, color: _cardColors[key] ?? const Color(0xFF3A342A), icon: _cardIcons[key] ?? Icons.radio_rounded)), // 라디오 목록 글자 크기 맞추기 (전체 목록과 같게)
              ),
            );
          },
          // A안: 방송사 색 바탕(살짝 그라데이션) + 오른쪽 위 큰 아이콘(은은하게) + 왼쪽 위 작은 아이콘 + 왼쪽 아래 이름·채널 수
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _softDark(_cardColors[key] ?? const Color(0xFF3A342A), isDarkMode),
                  _softDark(_cardColors[key] ?? const Color(0xFF3A342A), isDarkMode).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10), // 홈 카드와 같은 둥글기
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 오른쪽 위 큰 아이콘 (배경 무늬처럼 은은하게, 칸 밖으로 살짝 잘리게)
                Positioned(
                  right: -6,
                  top: -2,
                  child: Icon(_cardIcons[key] ?? Icons.radio_rounded,
                      size: 60, color: Colors.white.withOpacity(0.10)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 이름·채널 수: 남은 높이를 다 쓰고, 길거나 글자를 크게 해도 칸 안에 맞게 살짝 작게
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gridLabel(context, key),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              // TBN은 이름 밑에 작게 '(교통 방송)'
                              if (key == 'TBN')
                                Text(
                                  '(${stationCategoryLabel(context, 4)})',
                                  maxLines: 1,
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                tr.channelsCount(stations.length),
                                maxLines: 1,
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11.5),
                              ),
                            ],
                          ),
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
    );
  }
}

// ══════════════════════════════════════════
// 방송사 하나의 전국 채널 리스트 화면
// ══════════════════════════════════════════
class _BroadcasterStationList extends StatelessWidget {
  final String broadcaster;
  final List<_KStation> stations;
  final Color color; // 머리 색 (격자 칸과 같은 색)
  final IconData icon; // 머리 오른쪽 워터마크 (격자 칸과 같은 아이콘)
  const _BroadcasterStationList({
    required this.broadcaster,
    required this.stations,
    required this.color,
    required this.icon,
  });

  /// 위쪽 색 띠 머리: 뒤로가기 + 큰 이름 + 채널 수 + 은은한 큰 아이콘
  Widget _header(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final color = _softDark(this.color, context.watch<ThemeProvider>().isDarkMode);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // 격자 칸과 같은 그라데이션
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
      ),
      padding: EdgeInsets.only(top: top),
      child: Stack(
        children: [
          // 오른쪽 아래 큰 아이콘 (배경 무늬처럼 은은하게, 띠 밖으로 살짝 잘리게)
          Positioned(
            right: -14,
            bottom: -26,
            child: Icon(icon, size: 130, color: Colors.white.withOpacity(0.10)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _BroadcasterGridScreen.gridLabel(context, broadcaster),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr.channelsCount(stations.length),
                        maxLines: 1,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final radioStations = stations.map((ks) => _toRadioStation(ks)).toList();
    final radioProvider = context.watch<RadioProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    // 색 띠 위라서 상태바 아이콘은 흰색
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SafeArea(
        top: false,
        child: _DialHost(
          tickColor: baseColor.withOpacity(0.35),
          child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
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
          ),
        ],
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : (context.watch<PodcastPlayer>().active
              ? Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom), child: const PodcastMiniPlayer())
              : null),
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

/// 목록 왼쪽 방송사 칸 색 = 방송사별 박스 색을 바탕에 조금만 섞은 색
/// (박스 색을 바꾸면 여기도 저절로 따라감)
const double _brandTint = 0.16; // 라이트 모드 진하기 (0.16 → 더 진하게는 0.2·0.26)
Color _brandPastel(String b, bool dark) {
  final box = _BroadcasterGridScreen._cardColors[_BroadcasterGridScreen._keyOf(b)];
  if (dark) {
    // 다크: 어두운 바탕에 차분하게 줄인 박스 색을 섞기 (글자는 밝게)
    const bg = Color(0xFF24221F);
    if (box == null) return const Color(0xFF3A3732);
    return Color.lerp(bg, _softDark(box, true), 0.45)!;
  }
  const bg = Color(0xFFEDE7DA); // 라디오 화면 바탕 (베이지)
  if (box == null) return const Color(0xFFE3DCCD); // 그 밖: 연한 베이지
  return Color.lerp(bg, box, _brandTint)!;
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
    'CBS JOY4U': 'CCM 음악',
    'FEBC 극동방송 AM': '종교·음악',
    'FEBC 제주극동방송': '종교·음악',
    '아리랑 라디오': '영어 방송',
    '마포FM': '공동체 라디오',
    '수원 SoneFM': '공동체 라디오',
    '성서공동체FM': '공동체 라디오',
    '전주FM': '공동체 라디오',
    'TBC 드림FM': '음악·생활',
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
  return g == null ? kDescWord(loc) : '${kDescWord(loc)} · ${kDescWord(g)}';
}

/// 한국 방송 설명 낱말(서울, 뉴스·시사 …)을 앱 언어로 — 한국어면 그대로
String kDescWord(String w) {
  final lang = AppLocale.current?.localeName ?? 'ko';
  if (lang.startsWith('ko')) return w;
  final m = _kDescI18n[w];
  if (m == null) return w;
  return m[lang] ?? m[lang.split('_').first] ?? m['en'] ?? w;
}

const Map<String, Map<String, String>> _kDescI18n = {
  '강릉': {
    'en': 'Gangneung',
    'de': 'Gangneung',
    'es': 'Gangneung',
    'fr': 'Gangneung',
    'it': 'Gangneung',
    'pt': 'Gangneung',
    'pl': 'Gangneung',
    'ro': 'Gangneung',
    'cs': 'Kangnung',
    'hu': 'Gangneung',
    'tr': 'Gangneung',
    'id': 'Gangneung',
    'vi': 'Gangneung',
    'ru': 'Каннын',
    'uk': 'Каннин',
    'ja': '江陵',
    'zh': '江陵',
    'zh_Hant': '江陵',
    'th': 'คังนึง',
    'hi': 'गांगनेउंग',
    'ar': 'غانغنونغ',
    'ur': 'گانگنیونگ',
  },
  '강원': {
    'en': 'Gangwon',
    'de': 'Gangwon',
    'es': 'Gangwon',
    'fr': 'Gangwon',
    'it': 'Gangwon',
    'pt': 'Gangwon',
    'pl': 'Gangwon',
    'ro': 'Gangwon',
    'cs': 'Kangwon',
    'hu': 'Gangwon',
    'tr': 'Gangwon',
    'id': 'Gangwon',
    'vi': 'Gangwon',
    'ru': 'Канвондо',
    'uk': 'Канвон',
    'ja': '江原',
    'zh': '江原',
    'zh_Hant': '江原',
    'th': 'คังวอน',
    'hi': 'गांगवोन',
    'ar': 'غانغوون',
    'ur': 'گانگوون',
  },
  '경기': {
    'en': 'Gyeonggi',
    'de': 'Gyeonggi',
    'es': 'Gyeonggi',
    'fr': 'Gyeonggi',
    'it': 'Gyeonggi',
    'pt': 'Gyeonggi',
    'pl': 'Gyeonggi',
    'ro': 'Gyeonggi',
    'cs': 'Kjonggi',
    'hu': 'Gyeonggi',
    'tr': 'Gyeonggi',
    'id': 'Gyeonggi',
    'vi': 'Gyeonggi',
    'ru': 'Кёнгидо',
    'uk': 'Кьонгі',
    'ja': '京畿',
    'zh': '京畿',
    'zh_Hant': '京畿',
    'th': 'คย็องกี',
    'hi': 'ग्योंगी',
    'ar': 'غيونغي',
    'ur': 'گیونگی',
  },
  '경남': {
    'en': 'Gyeongnam',
    'de': 'Gyeongnam',
    'es': 'Gyeongnam',
    'fr': 'Gyeongnam',
    'it': 'Gyeongnam',
    'pt': 'Gyeongnam',
    'pl': 'Gyeongnam',
    'ro': 'Gyeongnam',
    'cs': 'Kjongnam',
    'hu': 'Gyeongnam',
    'tr': 'Gyeongnam',
    'id': 'Gyeongnam',
    'vi': 'Gyeongnam',
    'ru': 'Кённам',
    'uk': 'Кьоннам',
    'ja': '慶南',
    'zh': '庆南',
    'zh_Hant': '慶南',
    'th': 'คย็องนัม',
    'hi': 'ग्योंगनाम',
    'ar': 'غيونغنام',
    'ur': 'گیونگنام',
  },
  '광주': {
    'en': 'Gwangju',
    'de': 'Gwangju',
    'es': 'Gwangju',
    'fr': 'Gwangju',
    'it': 'Gwangju',
    'pt': 'Gwangju',
    'pl': 'Gwangju',
    'ro': 'Gwangju',
    'cs': 'Kwangdžu',
    'hu': 'Gwangju',
    'tr': 'Gwangju',
    'id': 'Gwangju',
    'vi': 'Gwangju',
    'ru': 'Кванджу',
    'uk': 'Кванджу',
    'ja': '光州',
    'zh': '光州',
    'zh_Hant': '光州',
    'th': 'ควังจู',
    'hi': 'ग्वांगजू',
    'ar': 'غوانغجو',
    'ur': 'گوانگجو',
  },
  '대구': {
    'en': 'Daegu',
    'de': 'Daegu',
    'es': 'Daegu',
    'fr': 'Daegu',
    'it': 'Daegu',
    'pt': 'Daegu',
    'pl': 'Daegu',
    'ro': 'Daegu',
    'cs': 'Tegu',
    'hu': 'Daegu',
    'tr': 'Daegu',
    'id': 'Daegu',
    'vi': 'Daegu',
    'ru': 'Тэгу',
    'uk': 'Тегу',
    'ja': '大邱',
    'zh': '大邱',
    'zh_Hant': '大邱',
    'th': 'แทกู',
    'hi': 'देगू',
    'ar': 'دايغو',
    'ur': 'دیگو',
  },
  '대전': {
    'en': 'Daejeon',
    'de': 'Daejeon',
    'es': 'Daejeon',
    'fr': 'Daejeon',
    'it': 'Daejeon',
    'pt': 'Daejeon',
    'pl': 'Daejeon',
    'ro': 'Daejeon',
    'cs': 'Tedžon',
    'hu': 'Daejeon',
    'tr': 'Daejeon',
    'id': 'Daejeon',
    'vi': 'Daejeon',
    'ru': 'Тэджон',
    'uk': 'Теджон',
    'ja': '大田',
    'zh': '大田',
    'zh_Hant': '大田',
    'th': 'แทจ็อน',
    'hi': 'देजॉन',
    'ar': 'دايجون',
    'ur': 'دیجون',
  },
  '마포': {
    'en': 'Mapo',
    'de': 'Mapo',
    'es': 'Mapo',
    'fr': 'Mapo',
    'it': 'Mapo',
    'pt': 'Mapo',
    'pl': 'Mapo',
    'ro': 'Mapo',
    'cs': 'Mapcho',
    'hu': 'Mapo',
    'tr': 'Mapo',
    'id': 'Mapo',
    'vi': 'Mapo',
    'ru': 'Мапхо',
    'uk': 'Мапхо',
    'ja': '麻浦',
    'zh': '麻浦',
    'zh_Hant': '麻浦',
    'th': 'มาโพ',
    'hi': 'मापो',
    'ar': 'مابو',
    'ur': 'ماپو',
  },
  '목포': {
    'en': 'Mokpo',
    'de': 'Mokpo',
    'es': 'Mokpo',
    'fr': 'Mokpo',
    'it': 'Mokpo',
    'pt': 'Mokpo',
    'pl': 'Mokpo',
    'ro': 'Mokpo',
    'cs': 'Mokpcho',
    'hu': 'Mokpo',
    'tr': 'Mokpo',
    'id': 'Mokpo',
    'vi': 'Mokpo',
    'ru': 'Мокпхо',
    'uk': 'Мокпхо',
    'ja': '木浦',
    'zh': '木浦',
    'zh_Hant': '木浦',
    'th': 'มกโพ',
    'hi': 'मोकपो',
    'ar': 'موكبو',
    'ur': 'موکپو',
  },
  '부산': {
    'en': 'Busan',
    'de': 'Busan',
    'es': 'Busan',
    'fr': 'Busan',
    'it': 'Busan',
    'pt': 'Busan',
    'pl': 'Busan',
    'ro': 'Busan',
    'cs': 'Pusan',
    'hu': 'Busan',
    'tr': 'Busan',
    'id': 'Busan',
    'vi': 'Busan',
    'ru': 'Пусан',
    'uk': 'Пусан',
    'ja': '釜山',
    'zh': '釜山',
    'zh_Hant': '釜山',
    'th': 'ปูซาน',
    'hi': 'बुसान',
    'ar': 'بوسان',
    'ur': 'بوسان',
  },
  '서울': {
    'en': 'Seoul',
    'de': 'Seoul',
    'es': 'Seúl',
    'fr': 'Séoul',
    'it': 'Seul',
    'pt': 'Seul',
    'pl': 'Seul',
    'ro': 'Seul',
    'cs': 'Soul',
    'hu': 'Szöul',
    'tr': 'Seul',
    'id': 'Seoul',
    'vi': 'Seoul',
    'ru': 'Сеул',
    'uk': 'Сеул',
    'ja': 'ソウル',
    'zh': '首尔',
    'zh_Hant': '首爾',
    'th': 'โซล',
    'hi': 'सियोल',
    'ar': 'سيول',
    'ur': 'سیول',
  },
  '수원': {
    'en': 'Suwon',
    'de': 'Suwon',
    'es': 'Suwon',
    'fr': 'Suwon',
    'it': 'Suwon',
    'pt': 'Suwon',
    'pl': 'Suwon',
    'ro': 'Suwon',
    'cs': 'Suwon',
    'hu': 'Suwon',
    'tr': 'Suwon',
    'id': 'Suwon',
    'vi': 'Suwon',
    'ru': 'Сувон',
    'uk': 'Сувон',
    'ja': '水原',
    'zh': '水原',
    'zh_Hant': '水原',
    'th': 'ซูวอน',
    'hi': 'सुवोन',
    'ar': 'سوون',
    'ur': 'سوون',
  },
  '순천': {
    'en': 'Suncheon',
    'de': 'Suncheon',
    'es': 'Suncheon',
    'fr': 'Suncheon',
    'it': 'Suncheon',
    'pt': 'Suncheon',
    'pl': 'Suncheon',
    'ro': 'Suncheon',
    'cs': 'Sunčchon',
    'hu': 'Suncheon',
    'tr': 'Suncheon',
    'id': 'Suncheon',
    'vi': 'Suncheon',
    'ru': 'Сунчхон',
    'uk': 'Сунчхон',
    'ja': '順天',
    'zh': '顺天',
    'zh_Hant': '順天',
    'th': 'ซุนช็อน',
    'hi': 'सुनचियोन',
    'ar': 'سونتشون',
    'ur': 'سونچون',
  },
  '안동': {
    'en': 'Andong',
    'de': 'Andong',
    'es': 'Andong',
    'fr': 'Andong',
    'it': 'Andong',
    'pt': 'Andong',
    'pl': 'Andong',
    'ro': 'Andong',
    'cs': 'Andong',
    'hu': 'Andong',
    'tr': 'Andong',
    'id': 'Andong',
    'vi': 'Andong',
    'ru': 'Андон',
    'uk': 'Андон',
    'ja': '安東',
    'zh': '安东',
    'zh_Hant': '安東',
    'th': 'อันดง',
    'hi': 'आनदोंग',
    'ar': 'أندونغ',
    'ur': 'اندونگ',
  },
  '울산': {
    'en': 'Ulsan',
    'de': 'Ulsan',
    'es': 'Ulsan',
    'fr': 'Ulsan',
    'it': 'Ulsan',
    'pt': 'Ulsan',
    'pl': 'Ulsan',
    'ro': 'Ulsan',
    'cs': 'Ulsan',
    'hu': 'Ulsan',
    'tr': 'Ulsan',
    'id': 'Ulsan',
    'vi': 'Ulsan',
    'ru': 'Ульсан',
    'uk': 'Ульсан',
    'ja': '蔚山',
    'zh': '蔚山',
    'zh_Hant': '蔚山',
    'th': 'อุลซาน',
    'hi': 'उल्सान',
    'ar': 'أولسان',
    'ur': 'السان',
  },
  '원주': {
    'en': 'Wonju',
    'de': 'Wonju',
    'es': 'Wonju',
    'fr': 'Wonju',
    'it': 'Wonju',
    'pt': 'Wonju',
    'pl': 'Wonju',
    'ro': 'Wonju',
    'cs': 'Wondžu',
    'hu': 'Wonju',
    'tr': 'Wonju',
    'id': 'Wonju',
    'vi': 'Wonju',
    'ru': 'Вонджу',
    'uk': 'Вонджу',
    'ja': '原州',
    'zh': '原州',
    'zh_Hant': '原州',
    'th': 'วอนจู',
    'hi': 'वोनजू',
    'ar': 'وونجو',
    'ur': 'وونجو',
  },
  '인천': {
    'en': 'Incheon',
    'de': 'Incheon',
    'es': 'Incheon',
    'fr': 'Incheon',
    'it': 'Incheon',
    'pt': 'Incheon',
    'pl': 'Incheon',
    'ro': 'Incheon',
    'cs': 'Inčchon',
    'hu': 'Incheon',
    'tr': 'Incheon',
    'id': 'Incheon',
    'vi': 'Incheon',
    'ru': 'Инчхон',
    'uk': 'Інчхон',
    'ja': '仁川',
    'zh': '仁川',
    'zh_Hant': '仁川',
    'th': 'อินช็อน',
    'hi': 'इंचियोन',
    'ar': 'إنتشون',
    'ur': 'انچیون',
  },
  '전북': {
    'en': 'Jeonbuk',
    'de': 'Jeonbuk',
    'es': 'Jeonbuk',
    'fr': 'Jeonbuk',
    'it': 'Jeonbuk',
    'pt': 'Jeonbuk',
    'pl': 'Jeonbuk',
    'ro': 'Jeonbuk',
    'cs': 'Čonbuk',
    'hu': 'Jeonbuk',
    'tr': 'Jeonbuk',
    'id': 'Jeonbuk',
    'vi': 'Jeonbuk',
    'ru': 'Чонбук',
    'uk': 'Чоллабук',
    'ja': '全北',
    'zh': '全北',
    'zh_Hant': '全北',
    'th': 'ช็อลลาบุก',
    'hi': 'जोल्लाबुक',
    'ar': 'جونبوك',
    'ur': 'جیونبک',
  },
  '전주': {
    'en': 'Jeonju',
    'de': 'Jeonju',
    'es': 'Jeonju',
    'fr': 'Jeonju',
    'it': 'Jeonju',
    'pt': 'Jeonju',
    'pl': 'Jeonju',
    'ro': 'Jeonju',
    'cs': 'Čondžu',
    'hu': 'Jeonju',
    'tr': 'Jeonju',
    'id': 'Jeonju',
    'vi': 'Jeonju',
    'ru': 'Чонджу',
    'uk': 'Чонджу',
    'ja': '全州',
    'zh': '全州',
    'zh_Hant': '全州',
    'th': 'ช็อนจู',
    'hi': 'जोंजू',
    'ar': 'جونجو',
    'ur': 'جیونجو',
  },
  '제주': {
    'en': 'Jeju',
    'de': 'Jeju',
    'es': 'Jeju',
    'fr': 'Jeju',
    'it': 'Jeju',
    'pt': 'Jeju',
    'pl': 'Jeju',
    'ro': 'Jeju',
    'cs': 'Čedžu',
    'hu': 'Jeju',
    'tr': 'Jeju',
    'id': 'Jeju',
    'vi': 'Jeju',
    'ru': 'Чеджу',
    'uk': 'Чеджу',
    'ja': '済州',
    'zh': '济州',
    'zh_Hant': '濟州',
    'th': 'เชจู',
    'hi': 'जेजू',
    'ar': 'جيجو',
    'ur': 'جیجو',
  },
  '진주': {
    'en': 'Jinju',
    'de': 'Jinju',
    'es': 'Jinju',
    'fr': 'Jinju',
    'it': 'Jinju',
    'pt': 'Jinju',
    'pl': 'Jinju',
    'ro': 'Jinju',
    'cs': 'Čindžu',
    'hu': 'Jinju',
    'tr': 'Jinju',
    'id': 'Jinju',
    'vi': 'Jinju',
    'ru': 'Чинджу',
    'uk': 'Чинджу',
    'ja': '晋州',
    'zh': '晋州',
    'zh_Hant': '晉州',
    'th': 'จินจู',
    'hi': 'जिंजू',
    'ar': 'جينجو',
    'ur': 'جنجو',
  },
  '창원': {
    'en': 'Changwon',
    'de': 'Changwon',
    'es': 'Changwon',
    'fr': 'Changwon',
    'it': 'Changwon',
    'pt': 'Changwon',
    'pl': 'Changwon',
    'ro': 'Changwon',
    'cs': 'Čchangwon',
    'hu': 'Changwon',
    'tr': 'Changwon',
    'id': 'Changwon',
    'vi': 'Changwon',
    'ru': 'Чханвон',
    'uk': 'Чханвон',
    'ja': '昌原',
    'zh': '昌原',
    'zh_Hant': '昌原',
    'th': 'ชังวอน',
    'hi': 'चांगवोन',
    'ar': 'تشانغوون',
    'ur': 'چانگوون',
  },
  '청주': {
    'en': 'Cheongju',
    'de': 'Cheongju',
    'es': 'Cheongju',
    'fr': 'Cheongju',
    'it': 'Cheongju',
    'pt': 'Cheongju',
    'pl': 'Cheongju',
    'ro': 'Cheongju',
    'cs': 'Čchongdžu',
    'hu': 'Cheongju',
    'tr': 'Cheongju',
    'id': 'Cheongju',
    'vi': 'Cheongju',
    'ru': 'Чхонджу',
    'uk': 'Чхонджу',
    'ja': '清州',
    'zh': '清州',
    'zh_Hant': '清州',
    'th': 'ช็องจู',
    'hi': 'चोंगजू',
    'ar': 'تشونغجو',
    'ur': 'چونگجو',
  },
  '춘천': {
    'en': 'Chuncheon',
    'de': 'Chuncheon',
    'es': 'Chuncheon',
    'fr': 'Chuncheon',
    'it': 'Chuncheon',
    'pt': 'Chuncheon',
    'pl': 'Chuncheon',
    'ro': 'Chuncheon',
    'cs': 'Čchunčchon',
    'hu': 'Chuncheon',
    'tr': 'Chuncheon',
    'id': 'Chuncheon',
    'vi': 'Chuncheon',
    'ru': 'Чхунчхон',
    'uk': 'Чхунчхон',
    'ja': '春川',
    'zh': '春川',
    'zh_Hant': '春川',
    'th': 'ชุนช็อน',
    'hi': 'चुनचियोन',
    'ar': 'تشونتشون',
    'ur': 'چنچون',
  },
  '충남': {
    'en': 'Chungnam',
    'de': 'Chungnam',
    'es': 'Chungnam',
    'fr': 'Chungnam',
    'it': 'Chungnam',
    'pt': 'Chungnam',
    'pl': 'Chungnam',
    'ro': 'Chungnam',
    'cs': 'Čchungnam',
    'hu': 'Chungnam',
    'tr': 'Chungnam',
    'id': 'Chungnam',
    'vi': 'Chungnam',
    'ru': 'Чхуннам',
    'uk': 'Чхунчхоннам',
    'ja': '忠南',
    'zh': '忠南',
    'zh_Hant': '忠南',
    'th': 'ชุงช็องนัม',
    'hi': 'चुंगनाम',
    'ar': 'تشونغنام',
    'ur': 'چنگنام',
  },
  '충북': {
    'en': 'Chungbuk',
    'de': 'Chungbuk',
    'es': 'Chungbuk',
    'fr': 'Chungbuk',
    'it': 'Chungbuk',
    'pt': 'Chungbuk',
    'pl': 'Chungbuk',
    'ro': 'Chungbuk',
    'cs': 'Čchungbuk',
    'hu': 'Chungbuk',
    'tr': 'Chungbuk',
    'id': 'Chungbuk',
    'vi': 'Chungbuk',
    'ru': 'Чхунбук',
    'uk': 'Чхунчхонбук',
    'ja': '忠北',
    'zh': '忠北',
    'zh_Hant': '忠北',
    'th': 'ชุงช็องบุก',
    'hi': 'चुंगबुक',
    'ar': 'تشونغبوك',
    'ur': 'چنگبک',
  },
  '포항': {
    'en': 'Pohang',
    'de': 'Pohang',
    'es': 'Pohang',
    'fr': 'Pohang',
    'it': 'Pohang',
    'pt': 'Pohang',
    'pl': 'Pohang',
    'ro': 'Pohang',
    'cs': 'Pchohang',
    'hu': 'Pohang',
    'tr': 'Pohang',
    'id': 'Pohang',
    'vi': 'Pohang',
    'ru': 'Пхохан',
    'uk': 'Пхохан',
    'ja': '浦項',
    'zh': '浦项',
    'zh_Hant': '浦項',
    'th': 'โพฮัง',
    'hi': 'पोहांग',
    'ar': 'بوهانغ',
    'ur': 'پوہانگ',
  },
  '가요·팝': {
    'en': 'K-pop·Pop',
    'de': 'K-Pop·Pop',
    'es': 'K-pop·Pop',
    'fr': 'K-pop·Pop',
    'it': 'K-pop·Pop',
    'pt': 'K-pop·Pop',
    'pl': 'K-pop·Pop',
    'ro': 'K-pop·Pop',
    'cs': 'K-pop·Pop',
    'hu': 'K-pop·Pop',
    'tr': 'K-pop·Pop',
    'id': 'K-pop·Pop',
    'vi': 'K-pop·Pop',
    'ru': 'K-pop·Поп',
    'uk': 'K-pop·Поп',
    'ja': 'K-POP·ポップス',
    'zh': '韩流·流行',
    'zh_Hant': '韓流·流行',
    'th': 'เคป็อป·ป็อป',
    'hi': 'के-पॉप·पॉप',
    'ar': 'كيبوب·بوب',
    'ur': 'کے پاپ·پاپ',
  },
  '가요·생활': {
    'en': 'K-pop·Lifestyle',
    'de': 'K-Pop·Alltag',
    'es': 'K-pop·Estilo de vida',
    'fr': 'K-pop·Société',
    'it': 'K-pop·Lifestyle',
    'pt': 'K-pop·Variedades',
    'pl': 'K-pop·Styl życia',
    'ro': 'K-pop·Stil de viață',
    'cs': 'K-pop·Životní styl',
    'hu': 'K-pop·Életmód',
    'tr': 'K-pop·Yaşam',
    'id': 'K-pop·Gaya hidup',
    'vi': 'K-pop·Đời sống',
    'ru': 'K-pop·Жизнь',
    'uk': 'K-pop·Життя',
    'ja': 'K-POP·暮らし',
    'zh': '韩流·生活',
    'zh_Hant': '韓流·生活',
    'th': 'เคป็อป·ไลฟ์สไตล์',
    'hi': 'के-पॉप·जीवनशैली',
    'ar': 'كيبوب·منوعات',
    'ur': 'کے پاپ·طرزِ زندگی',
  },
  '가요·예능': {
    'en': 'K-pop·Entertainment',
    'de': 'K-Pop·Unterhaltung',
    'es': 'K-pop·Entretenimiento',
    'fr': 'K-pop·Divertissement',
    'it': 'K-pop·Intrattenimento',
    'pt': 'K-pop·Entretenimento',
    'pl': 'K-pop·Rozrywka',
    'ro': 'K-pop·Divertisment',
    'cs': 'K-pop·Zábava',
    'hu': 'K-pop·Szórakozás',
    'tr': 'K-pop·Eğlence',
    'id': 'K-pop·Hiburan',
    'vi': 'K-pop·Giải trí',
    'ru': 'K-pop·Развлечения',
    'uk': 'K-pop·Розваги',
    'ja': 'K-POP·バラエティ',
    'zh': '韩流·综艺',
    'zh_Hant': '韓流·綜藝',
    'th': 'เคป็อป·บันเทิง',
    'hi': 'के-पॉप·मनोरंजन',
    'ar': 'كيبوب·ترفيه',
    'ur': 'کے پاپ·تفریح',
  },
  '뉴스·시사': {
    'en': 'News·Current affairs',
    'de': 'Nachrichten·Politik',
    'es': 'Noticias·Actualidad',
    'fr': 'Infos·Actualité',
    'it': 'Notizie·Attualità',
    'pt': 'Notícias·Atualidades',
    'pl': 'Wiadomości·Publicystyka',
    'ro': 'Știri·Actualitate',
    'cs': 'Zprávy·Publicistika',
    'hu': 'Hírek·Közélet',
    'tr': 'Haber·Gündem',
    'id': 'Berita·Aktual',
    'vi': 'Tin tức·Thời sự',
    'ru': 'Новости·Политика',
    'uk': 'Новини·Суспільство',
    'ja': 'ニュース·時事',
    'zh': '新闻·时事',
    'zh_Hant': '新聞·時事',
    'th': 'ข่าว·สถานการณ์',
    'hi': 'समाचार·करंट अफेयर्स',
    'ar': 'أخبار·شؤون جارية',
    'ur': 'خبریں·حالاتِ حاضرہ',
  },
  '시사·교양': {
    'en': 'Current affairs·Culture',
    'de': 'Politik·Kultur',
    'es': 'Actualidad·Cultura',
    'fr': 'Actualité·Culture',
    'it': 'Attualità·Cultura',
    'pt': 'Atualidades·Cultura',
    'pl': 'Publicystyka·Kultura',
    'ro': 'Actualitate·Cultură',
    'cs': 'Publicistika·Kultura',
    'hu': 'Közélet·Kultúra',
    'tr': 'Gündem·Kültür',
    'id': 'Aktual·Budaya',
    'vi': 'Thời sự·Văn hóa',
    'ru': 'Политика·Культура',
    'uk': 'Суспільство·Культура',
    'ja': '時事·教養',
    'zh': '时事·文化',
    'zh_Hant': '時事·文化',
    'th': 'สถานการณ์·สาระ',
    'hi': 'करंट अफेयर्स·संस्कृति',
    'ar': 'شؤون جارية·ثقافة',
    'ur': 'حالاتِ حاضرہ·ثقافت',
  },
  '시사·생활': {
    'en': 'Current affairs·Lifestyle',
    'de': 'Politik·Alltag',
    'es': 'Actualidad·Estilo de vida',
    'fr': 'Actualité·Société',
    'it': 'Attualità·Lifestyle',
    'pt': 'Atualidades·Variedades',
    'pl': 'Publicystyka·Styl życia',
    'ro': 'Actualitate·Stil de viață',
    'cs': 'Publicistika·Životní styl',
    'hu': 'Közélet·Életmód',
    'tr': 'Gündem·Yaşam',
    'id': 'Aktual·Gaya hidup',
    'vi': 'Thời sự·Đời sống',
    'ru': 'Политика·Жизнь',
    'uk': 'Суспільство·Життя',
    'ja': '時事·暮らし',
    'zh': '时事·生活',
    'zh_Hant': '時事·生活',
    'th': 'สถานการณ์·ไลฟ์สไตล์',
    'hi': 'करंट अफेयर्स·जीवनशैली',
    'ar': 'شؤون جارية·منوعات',
    'ur': 'حالاتِ حاضرہ·طرزِ زندگی',
  },
  '시사·종교': {
    'en': 'Current affairs·Religion',
    'de': 'Politik·Religion',
    'es': 'Actualidad·Religión',
    'fr': 'Actualité·Religion',
    'it': 'Attualità·Religione',
    'pt': 'Atualidades·Religião',
    'pl': 'Publicystyka·Religia',
    'ro': 'Actualitate·Religie',
    'cs': 'Publicistika·Náboženství',
    'hu': 'Közélet·Vallás',
    'tr': 'Gündem·Din',
    'id': 'Aktual·Religi',
    'vi': 'Thời sự·Tôn giáo',
    'ru': 'Политика·Религия',
    'uk': 'Суспільство·Релігія',
    'ja': '時事·宗教',
    'zh': '时事·宗教',
    'zh_Hant': '時事·宗教',
    'th': 'สถานการณ์·ศาสนา',
    'hi': 'करंट अफेयर्स·धर्म',
    'ar': 'شؤون جارية·دين',
    'ur': 'حالاتِ حاضرہ·مذہب',
  },
  '사회·복지': {
    'en': 'Society·Welfare',
    'de': 'Gesellschaft·Soziales',
    'es': 'Sociedad·Bienestar',
    'fr': 'Société·Solidarité',
    'it': 'Società·Welfare',
    'pt': 'Sociedade·Bem-estar',
    'pl': 'Społeczeństwo·Pomoc społeczna',
    'ro': 'Societate·Asistență socială',
    'cs': 'Společnost·Sociální péče',
    'hu': 'Társadalom·Jólét',
    'tr': 'Toplum·Sosyal yardım',
    'id': 'Sosial·Kesejahteraan',
    'vi': 'Xã hội·Phúc lợi',
    'ru': 'Общество·Соцзащита',
    'uk': 'Суспільство·Соцзахист',
    'ja': '社会·福祉',
    'zh': '社会·福利',
    'zh_Hant': '社會·福利',
    'th': 'สังคม·สวัสดิการ',
    'hi': 'समाज·कल्याण',
    'ar': 'مجتمع·رعاية اجتماعية',
    'ur': 'سماج·فلاح و بہبود',
  },
  '음악': {
    'en': 'Music',
    'de': 'Musik',
    'es': 'Música',
    'fr': 'Musique',
    'it': 'Musica',
    'pt': 'Música',
    'pl': 'Muzyka',
    'ro': 'Muzică',
    'cs': 'Hudba',
    'hu': 'Zene',
    'tr': 'Müzik',
    'id': 'Musik',
    'vi': 'Âm nhạc',
    'ru': 'Музыка',
    'uk': 'Музика',
    'ja': '音楽',
    'zh': '音乐',
    'zh_Hant': '音樂',
    'th': 'เพลง',
    'hi': 'संगीत',
    'ar': 'موسيقى',
    'ur': 'موسیقی',
  },
  '음악·생활': {
    'en': 'Music·Lifestyle',
    'de': 'Musik·Alltag',
    'es': 'Música·Estilo de vida',
    'fr': 'Musique·Société',
    'it': 'Musica·Lifestyle',
    'pt': 'Música·Variedades',
    'pl': 'Muzyka·Styl życia',
    'ro': 'Muzică·Stil de viață',
    'cs': 'Hudba·Životní styl',
    'hu': 'Zene·Életmód',
    'tr': 'Müzik·Yaşam',
    'id': 'Musik·Gaya hidup',
    'vi': 'Âm nhạc·Đời sống',
    'ru': 'Музыка·Жизнь',
    'uk': 'Музика·Життя',
    'ja': '音楽·暮らし',
    'zh': '音乐·生活',
    'zh_Hant': '音樂·生活',
    'th': 'เพลง·ไลฟ์สไตล์',
    'hi': 'संगीत·जीवनशैली',
    'ar': 'موسيقى·منوعات',
    'ur': 'موسیقی·طرزِ زندگی',
  },
  '종교·음악': {
    'en': 'Religion·Music',
    'de': 'Religion·Musik',
    'es': 'Religión·Música',
    'fr': 'Religion·Musique',
    'it': 'Religione·Musica',
    'pt': 'Religião·Música',
    'pl': 'Religia·Muzyka',
    'ro': 'Religie·Muzică',
    'cs': 'Náboženství·Hudba',
    'hu': 'Vallás·Zene',
    'tr': 'Din·Müzik',
    'id': 'Religi·Musik',
    'vi': 'Tôn giáo·Âm nhạc',
    'ru': 'Религия·Музыка',
    'uk': 'Релігія·Музика',
    'ja': '宗教·音楽',
    'zh': '宗教·音乐',
    'zh_Hant': '宗教·音樂',
    'th': 'ศาสนา·เพลง',
    'hi': 'धर्म·संगीत',
    'ar': 'دين·موسيقى',
    'ur': 'مذہب·موسیقی',
  },
  '클래식': {
    'en': 'Classical',
    'de': 'Klassik',
    'es': 'Clásica',
    'fr': 'Classique',
    'it': 'Classica',
    'pt': 'Clássica',
    'pl': 'Klasyka',
    'ro': 'Clasică',
    'cs': 'Klasika',
    'hu': 'Klasszikus',
    'tr': 'Klasik',
    'id': 'Klasik',
    'vi': 'Cổ điển',
    'ru': 'Классика',
    'uk': 'Класика',
    'ja': 'クラシック',
    'zh': '古典音乐',
    'zh_Hant': '古典音樂',
    'th': 'คลาสสิก',
    'hi': 'शास्त्रीय संगीत',
    'ar': 'كلاسيكية',
    'ur': 'کلاسیکی موسیقی',
  },
  '국악': {
    'en': 'Korean traditional music',
    'de': 'Traditionelle koreanische Musik',
    'es': 'Música tradicional coreana',
    'fr': 'Musique traditionnelle coréenne',
    'it': 'Musica tradizionale coreana',
    'pt': 'Música tradicional coreana',
    'pl': 'Tradycyjna muzyka koreańska',
    'ro': 'Muzică tradițională coreeană',
    'cs': 'Tradiční korejská hudba',
    'hu': 'Hagyományos koreai zene',
    'tr': 'Geleneksel Kore müziği',
    'id': 'Musik tradisional Korea',
    'vi': 'Nhạc truyền thống Hàn Quốc',
    'ru': 'Традиционная корейская музыка',
    'uk': 'Традиційна корейська музика',
    'ja': '韓国伝統音楽',
    'zh': '韩国传统音乐',
    'zh_Hant': '韓國傳統音樂',
    'th': 'ดนตรีพื้นเมืองเกาหลี',
    'hi': 'कोरियाई पारंपरिक संगीत',
    'ar': 'موسيقى كورية تقليدية',
    'ur': 'روایتی کوریائی موسیقی',
  },
  '교육': {
    'en': 'Education',
    'de': 'Bildung',
    'es': 'Educación',
    'fr': 'Éducation',
    'it': 'Istruzione',
    'pt': 'Educação',
    'pl': 'Edukacja',
    'ro': 'Educație',
    'cs': 'Vzdělávání',
    'hu': 'Oktatás',
    'tr': 'Eğitim',
    'id': 'Pendidikan',
    'vi': 'Giáo dục',
    'ru': 'Образование',
    'uk': 'Освіта',
    'ja': '教育',
    'zh': '教育',
    'zh_Hant': '教育',
    'th': 'การศึกษา',
    'hi': 'शिक्षा',
    'ar': 'تعليم',
    'ur': 'تعلیم',
  },
  '외국어 학습': {
    'en': 'Language learning',
    'de': 'Sprachen lernen',
    'es': 'Aprendizaje de idiomas',
    'fr': 'Apprentissage des langues',
    'it': 'Studio delle lingue',
    'pt': 'Aprendizado de idiomas',
    'pl': 'Nauka języków',
    'ro': 'Învățarea limbilor',
    'cs': 'Výuka jazyků',
    'hu': 'Nyelvtanulás',
    'tr': 'Dil öğrenimi',
    'id': 'Belajar bahasa',
    'vi': 'Học ngoại ngữ',
    'ru': 'Изучение языков',
    'uk': 'Вивчення мов',
    'ja': '語学',
    'zh': '外语学习',
    'zh_Hant': '外語學習',
    'th': 'เรียนภาษา',
    'hi': 'भाषा सीखना',
    'ar': 'تعلّم اللغات',
    'ur': 'زبانیں سیکھیں',
  },
  '영어 방송': {
    'en': 'English broadcasts',
    'de': 'Englischsprachig',
    'es': 'Emisión en inglés',
    'fr': 'Émissions en anglais',
    'it': 'Trasmissioni in inglese',
    'pt': 'Transmissão em inglês',
    'pl': 'Audycje po angielsku',
    'ro': 'Emisiuni în engleză',
    'cs': 'Vysílání v angličtině',
    'hu': 'Angol nyelvű adás',
    'tr': 'İngilizce yayın',
    'id': 'Siaran bahasa Inggris',
    'vi': 'Phát thanh tiếng Anh',
    'ru': 'Вещание на английском',
    'uk': 'Мовлення англійською',
    'ja': '英語放送',
    'zh': '英语广播',
    'zh_Hant': '英語廣播',
    'th': 'รายการภาษาอังกฤษ',
    'hi': 'अंग्रेज़ी प्रसारण',
    'ar': 'بث باللغة الإنجليزية',
    'ur': 'انگریزی نشریات',
  },
  '교통 정보': {
    'en': 'Traffic info',
    'de': 'Verkehrsinfo',
    'es': 'Información de tráfico',
    'fr': 'Info trafic',
    'it': 'Info traffico',
    'pt': 'Informação de trânsito',
    'pl': 'Informacje drogowe',
    'ro': 'Info trafic',
    'cs': 'Dopravní informace',
    'hu': 'Közlekedési hírek',
    'tr': 'Trafik bilgisi',
    'id': 'Info lalu lintas',
    'vi': 'Thông tin giao thông',
    'ru': 'Дорожная информация',
    'uk': 'Дорожня інформація',
    'ja': '交通情報',
    'zh': '交通信息',
    'zh_Hant': '交通資訊',
    'th': 'ข้อมูลจราจร',
    'hi': 'यातायात जानकारी',
    'ar': 'معلومات المرور',
    'ur': 'ٹریفک معلومات',
  },
  '교통·생활': {
    'en': 'Traffic·Lifestyle',
    'de': 'Verkehr·Alltag',
    'es': 'Tráfico·Estilo de vida',
    'fr': 'Trafic·Société',
    'it': 'Traffico·Lifestyle',
    'pt': 'Trânsito·Variedades',
    'pl': 'Ruch drogowy·Styl życia',
    'ro': 'Trafic·Stil de viață',
    'cs': 'Doprava·Životní styl',
    'hu': 'Közlekedés·Életmód',
    'tr': 'Trafik·Yaşam',
    'id': 'Lalu lintas·Gaya hidup',
    'vi': 'Giao thông·Đời sống',
    'ru': 'Дороги·Жизнь',
    'uk': 'Дороги·Життя',
    'ja': '交通·暮らし',
    'zh': '交通·生活',
    'zh_Hant': '交通·生活',
    'th': 'จราจร·ไลฟ์สไตล์',
    'hi': 'यातायात·जीवनशैली',
    'ar': 'مرور·منوعات',
    'ur': 'ٹریفک·طرزِ زندگی',
  },
  '국군 방송': {
    'en': 'Armed Forces radio',
    'de': 'Streitkräfte-Radio',
    'es': 'Radio de las Fuerzas Armadas',
    'fr': 'Radio des forces armées',
    'it': 'Radio delle Forze armate',
    'pt': 'Rádio das Forças Armadas',
    'pl': 'Radio wojskowe',
    'ro': 'Radioul armatei',
    'cs': 'Armádní rozhlas',
    'hu': 'Katonai rádió',
    'tr': 'Silahlı Kuvvetler radyosu',
    'id': 'Radio angkatan bersenjata',
    'vi': 'Đài quân đội',
    'ru': 'Армейское радио',
    'uk': 'Армійське радіо',
    'ja': '国軍放送',
    'zh': '国军广播',
    'zh_Hant': '國軍廣播',
    'th': 'วิทยุกองทัพ',
    'hi': 'सशस्त्र बल रेडियो',
    'ar': 'إذاعة القوات المسلحة',
    'ur': 'مسلح افواج ریڈیو',
  },
  '공동체 라디오': {
    'en': 'Community radio',
    'de': 'Bürgerradio',
    'es': 'Radio comunitaria',
    'fr': 'Radio associative',
    'it': 'Radio comunitaria',
    'pt': 'Rádio comunitária',
    'pl': 'Radio lokalne',
    'ro': 'Radio comunitar',
    'cs': 'Komunitní rádio',
    'hu': 'Közösségi rádió',
    'tr': 'Topluluk radyosu',
    'id': 'Radio komunitas',
    'vi': 'Đài cộng đồng',
    'ru': 'Местное радио',
    'uk': 'Громадське радіо',
    'ja': 'コミュニティFM',
    'zh': '社区电台',
    'zh_Hant': '社區電台',
    'th': 'วิทยุชุมชน',
    'hi': 'सामुदायिक रेडियो',
    'ar': 'راديو مجتمعي',
    'ur': 'کمیونٹی ریڈیو',
  },
  'CCM 음악': {
    'en': 'Christian music',
    'de': 'Christliche Musik',
    'es': 'Música cristiana',
    'fr': 'Musique chrétienne',
    'it': 'Musica cristiana',
    'pt': 'Música cristã',
    'pl': 'Muzyka chrześcijańska',
    'ro': 'Muzică creștină',
    'cs': 'Křesťanská hudba',
    'hu': 'Keresztény zene',
    'tr': 'Hristiyan müziği',
    'id': 'Musik Kristen',
    'vi': 'Nhạc Cơ Đốc',
    'ru': 'Христианская музыка',
    'uk': 'Християнська музика',
    'ja': 'CCM',
    'zh': '福音音乐',
    'zh_Hant': '福音音樂',
    'th': 'เพลงคริสเตียน',
    'hi': 'ईसाई संगीत',
    'ar': 'موسيقى مسيحية',
    'ur': 'مسیحی موسیقی',
  },
};
