import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/greeting_images.dart';
import '../widgets/farewell_title.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart' show globalAudioHandler, SimpleAudioHandler;
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import '../providers/start_screen_provider.dart';
import '../providers/recent_content_provider.dart';
import 'all_favorites_screen.dart';
import '../models/recent_content_entry.dart';
import '../models/radio_station.dart';
import '../providers/video_provider.dart';
import '../widgets/nature_mini_player.dart';
import '../widgets/exit_confirm_dialog.dart';
import '../providers/sound_mix_provider.dart';
import '../widgets/sound_mix_mini_player.dart';
import 'video_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/music_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/song_title_cleaner.dart';
import 'bulk_clean_screen.dart';
import '../providers/playlist_provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/mini_player.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'playlist_screen.dart';
import 'favorites_screen.dart';
import 'recent_screen.dart';
import 'dart:io' show Platform;
import 'call_recordings_screen.dart';
import 'folder_screen.dart';
import 'settings_screen.dart';
import 'radio_home_screen.dart';
import '../widgets/radio_mini_player.dart';
import '../providers/radio_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import 'nature_sounds_screen.dart';
import 'nature_sound_detail_screen.dart';
import 'radio_player_screen.dart';
import 'radio_korea_screen2.dart' show niceKoreanStationNow;
import '../utils/nature_sound_catalog.dart';
import '../utils/paran_photo.dart';
import '../utils/no_album_helper.dart';
import '../utils/point_color.dart';
import '../utils/widget_go.dart';
import '../services/headset_resume.dart';
import '../utils/index_letter.dart';
import '../widgets/index_bar.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';
import '../widgets/paran_dialog.dart';
import '../services/alarm_service.dart';
import 'alarm_screen.dart';
import '../utils/home_card_pref.dart';
import 'sleep_focus_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/more_menu_sheet.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// 재생화면·가사 화면의 집 아이콘: 값을 바꾸면 메인 홈(음악·라디오·자연·수면)으로
  static final ValueNotifier<int> goHome = ValueNotifier(0);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScrollingUp = true;
  double _lastScrollOffset = 0;
  int _currentTabIndex = 0;
  bool _showFavorites = false;
  bool _showRecent = false;
  bool _showCalls = false; // 통화녹음 탭
  bool _showMusicLibrary = false;
  bool _pendingStartScreenNav = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  // 최근 검색어 (최근 것부터 8개)
  List<String> _recentSearches = [];
  Timer? _recentSaveTimer;
  final ScrollController _songListController = ScrollController();
  final ValueNotifier<String?> _indexBubble = ValueNotifier(null); // 가운데 큰 글자
  final ValueNotifier<String?> _currentGroup = ValueNotifier(null); // 지금 보고 있는 구간
  final ValueNotifier<bool> _indexShow = ValueNotifier(false); // 초성 막대: 스크롤하는 동안만
  int _indexHideToken = 0;
  double? _indexFrom; // 초성이 숨어 있을 때 밀기 시작한 위치
  DateTime _indexMovedAt = DateTime(0);

  // ── 빠른 이동 막대용: 묶음(A-Z → ㄱ~ㅎ → #) 순서로 정리한 목록 (곡이 바뀔 때만 다시 계산) ──
  List<(String?, int)> _indexEntries = const []; // (머리글, null이면 곡) / 곡 번호
  List<Song> _indexSongs = const [];
  Map<String, int> _indexCounts = const {}; // 초성별 곡 수
  int _indexFingerprint = -1;
  static const double _indexHeaderH = 34; // 위 여백 + 초성 글자
  int _newTopRows = 0; // 목록 맨 위 '새로 들어온 곡' 곡 수 (빠른 이동 위치 계산용)

  // 정렬: false = 제목, true = 가수 (가수일 땐 초성 바도 가수 이름 기준 + 가수 묶음 줄)
  bool _byArtist = false;
  Map<String, int> _artistCounts = const {}; // 가수별 곡 수
  static const double _artistHeaderH = 30; // 가수 이름 줄 높이

  // 목록 줄 종류: (머리글, -1) = 초성 머리글 / (가수, -2) = 가수 줄 / (null, 번호) = 곡
  void _buildIndexEntries(List<Song> songs) {
    var fp = songs.length * 2 + (_byArtist ? 1 : 0);
    for (final s in songs) {
      fp = (fp * 31 + s.titleDisplay.hashCode + (_byArtist ? s.artistDisplay.hashCode : 0)) & 0x3fffffff;
    }
    if (fp == _indexFingerprint) return;
    _indexFingerprint = fp;
    String keyOf(Song s) => _byArtist ? s.artistDisplay : s.titleDisplay;
    final byGroup = <String, List<Song>>{};
    final artistCounts = <String, int>{};
    for (final s in songs) {
      byGroup.putIfAbsent(indexGroupOf(keyOf(s)), () => []).add(s);
      artistCounts[s.artistDisplay] = (artistCounts[s.artistDisplay] ?? 0) + 1;
    }
    final ordered = <Song>[];
    final entries = <(String?, int)>[];
    for (final g in kIndexGroups) {
      final list = byGroup[g];
      if (list == null || list.isEmpty) continue;
      list.sort((a, b) {
        if (_byArtist) {
          final c = a.artistDisplay.toLowerCase().compareTo(b.artistDisplay.toLowerCase());
          if (c != 0) return c;
        }
        return a.titleDisplay.toLowerCase().compareTo(b.titleDisplay.toLowerCase());
      });
      entries.add((g, -1));
      String? lastArtist;
      for (final s in list) {
        if (_byArtist && s.artistDisplay != lastArtist) {
          lastArtist = s.artistDisplay;
          entries.add((lastArtist, -2)); // 가수 이름 줄
        }
        entries.add((null, ordered.length));
        ordered.add(s);
      }
    }
    _indexSongs = ordered;
    _indexCounts = {for (final e in byGroup.entries) e.key: e.value.length};
    _artistCounts = artistCounts;
    _indexEntries = entries;
  }

  /// 정렬 바꾸기 (제목 / 가수) — 기억해 둠
  Future<void> _setSortByArtist(bool v) async {
    if (v == _byArtist) return;
    setState(() {
      _byArtist = v;
      _indexFingerprint = -1;
    });
    if (_songListController.hasClients) _songListController.jumpTo(0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('song_sort_by_artist', v);
  }

  /// 가수 정렬일 때 가수 이름 줄: 가수 + 곡 수
  Widget _buildArtistHeader(String artist, bool isDark) {
    final count = _artistCounts[artist] ?? 0;
    return SizedBox(
      height: _artistHeaderH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF17140F),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(width: 6),
            Text('$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.7),
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }

  /// 지금 화면 맨 위에 보이는 구간(초성)을 찾아서 오른쪽 막대에 파랗게 표시
  void _updateCurrentGroup() {
    if (_indexEntries.isEmpty || !_songListController.hasClients) return;
    double rowH = 76;
    for (final k in _songItemKeys.values) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        rowH = box.size.height;
        break;
      }
    }
    final top = _songListController.offset + 1;
    double y = _newTopRows > 0 ? _indexHeaderH + _newTopRows * rowH : 0; // 맨 위 새 곡 칸
    String? cur;
    for (final e in _indexEntries) {
      if (y > top) break;
      if (e.$2 == -1) cur = e.$1;
      y += e.$2 == -1 ? _indexHeaderH : (e.$2 == -2 ? _artistHeaderH : rowH);
    }
    if (_currentGroup.value != cur) _currentGroup.value = cur;
  }

  /// 빠른 이동 막대: 그 묶음 머리글로 점프
  void _jumpToGroup(String group) {
    final hi = _indexEntries.indexWhere((e) => e.$2 == -1 && e.$1 == group);
    if (hi < 0 || !_songListController.hasClients) return;
    // 곡 한 줄 높이를 화면에 보이는 곡으로 재서 위치 계산
    double rowH = 76;
    for (final k in _songItemKeys.values) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        rowH = box.size.height;
        break;
      }
    }
    double offset = _newTopRows > 0 ? _indexHeaderH + _newTopRows * rowH : 0; // 맨 위 새 곡 칸
    for (var j = 0; j < hi; j++) {
      final t = _indexEntries[j].$2;
      offset += t == -1 ? _indexHeaderH : (t == -2 ? _artistHeaderH : rowH);
    }
    final max = _songListController.position.maxScrollExtent;
    _songListController.jumpTo(offset.clamp(0.0, max));
  }

  /// 목록 맨 위 '새로 들어온 곡' 머리글: 초성 머리글과 같은 모양 + 앞에 포인트 색 점
  Widget _buildNewHeader(int count, bool isDark) {
    return SizedBox(
      height: _indexHeaderH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 12, 2),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: pointColorOf(context), shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                '새로 들어온 곡',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF4A443B),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 목록 안 초성 머리글: 바·선 없이 회갈색 초성 + 연한 곡 수
  Widget _buildIndexHeader(String group, bool isDark) {
    final count = _indexCounts[group] ?? 0;
    return SizedBox(
      height: _indexHeaderH,
      child: Padding(
        // 글자 시작을 앨범 이미지 시작 위치에 맞춤, 위쪽 여백으로 구간 구분
        padding: const EdgeInsets.fromLTRB(22, 14, 12, 2),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                group,
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF4A443B),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  bool _showBanner = false;
  bool _isSelectionMode = false;
  final Map<int, GlobalKey> _songItemKeys = {};
  int? _lastScrolledSongId;
  Set<int> _selectedSongIds = {};
  bool _showThemeHint = false;

  // ───── 강조 색상 안내 카드: 앱을 3번째 켤 때부터 딱 한 번 ─────
  bool _showColorTip = false;
  static bool _launchCounted = false; // 앱 한 번 켤 때 한 번만 세기

  Future<void> _checkColorTip() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('color_tip_done') ?? false) return;
    // ✕로 닫았으면 7일 동안은 안 보여줌
    if (DateTime.now().millisecondsSinceEpoch < (prefs.getInt('color_tip_hide_until') ?? 0)) return;
    var n = prefs.getInt('app_launch_count') ?? 0;
    if (!_launchCounted) {
      _launchCounted = true;
      n++;
      await prefs.setInt('app_launch_count', n);
    }
    if (!mounted) return;
    // 색을 이미 바꾼 사람에게도 한 번은 보여줌 (✕ 누르면 끝)
    if (n >= 3) {
      await prefs.setBool('color_tip_shown', true); // 한 번 나온 뒤로는 ✕ 누를 때까지 계속
      if (mounted) setState(() => _showColorTip = true);
    }
  }

  /// ✕ 누르면 7일 뒤 다시 나옴 (3번 닫으면 그 뒤로는 안 나옴)
  Future<void> _finishColorTip() async {
    if (mounted) setState(() => _showColorTip = false);
    final prefs = await SharedPreferences.getInstance();
    final closed = (prefs.getInt('color_tip_closed') ?? 0) + 1;
    await prefs.setInt('color_tip_closed', closed);
    if (closed >= 3) {
      await prefs.setBool('color_tip_done', true);
    } else {
      await prefs.setInt('color_tip_hide_until',
          DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch);
    }
  }

  // ───── 메인 홈 카드: 나만의 색 → 지금 방송 → 오늘의 팁 (✕ 누르면 다음 카드, 내일 다시 처음부터) ─────
  Set<String> _homeClosed = {}; // 오늘 ✕로 닫은 카드 ('radio', 'tip')
  final Set<String> _programAsked = {}; // 방송마다 편성표는 한 번만 받기

  static String _homeDay(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadHomeClosed() async {
    final p = await SharedPreferences.getInstance();
    final today = p.getString('main_card_closed_day') == _homeDay(DateTime.now());
    final list = today ? (p.getStringList('main_card_closed') ?? const <String>[]) : const <String>[];
    if (mounted) setState(() => _homeClosed = list.toSet());
  }

  /// ✕ → 오늘은 닫고 바로 다음 카드 (내일 다시 처음부터)
  Future<void> _closeHomeCard(String key) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    setState(() => _homeClosed = {..._homeClosed, key});
    final p = await SharedPreferences.getInstance();
    await p.setString('main_card_closed_day', _homeDay(DateTime.now()));
    await p.setStringList('main_card_closed', _homeClosed.toList());
  }

  void _onMainCardPref() {
    if (mounted) setState(() {});
  }

  /// 설정에서 다시 켜면: 오늘 닫은 카드·나만의 색 카드 다시 불러오기
  void _onMainCardReopen() {
    _loadHomeClosed();
    _checkColorTip();
  }

  /// 홈 카드 방송의 지금 프로그램 받아 오기 (편성표 있는 국내 방송만)
  void _askProgram(RadioProvider radio, RadioStation s) {
    final n = s.name;
    if (!_programAsked.add(n)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (n == 'MBC 표준FM' || n == 'MBC FM4U') {
          radio.fetchMbcSchedule(n);
        } else if (n == 'SBS 파워FM' || n == 'SBS 러브FM') {
          radio.fetchSbsSchedule(n);
        } else if (n == 'CBS 음악FM' || n == 'CBS 표준FM') {
          radio.fetchJsonSchedule(n);
        } else if (s.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
          radio.fetchScheduleByUrl(n, s.streamUrl);
        }
      } catch (_) {}
    });
  }

  // 메인 홈 팁 (음악 탭 TIP과 안 겹치게 음악 말고 다른 기능만)
  static const _mainTips = <(String, String, String, String)>[
    ('바탕화면 위젯을 놓아 보세요', '바탕화면을 꾹 → 위젯 → 파란소리', 'Add the home screen widget', 'Long-press home screen → Widgets'),
    ('아침 알람으로 깨워 드려요', '음악·라디오·자연 소리로 일어나요', 'Wake up with Paransori', 'Music, radio or nature sounds'),
    ('원하는 시간에 라디오 켜기', '라디오 재생 화면 아래 [예약]', 'Schedule the radio', 'Tap Schedule under the radio player'),
    ('TV·스피커로 소리 보내기', '같은 Wi-Fi라면 재생 화면 ⋮ 메뉴에서', 'Play on your TV or speaker', 'Same Wi-Fi → player ⋮ menu'),
    ('잠들 땐 수면 타이머', '재생 화면 아래 [수면]을 눌러요', 'Sleep timer for bedtime', 'Tap Sleep under the player'),
  ];

  Widget _buildHomeCard(bool isDark) {
    if (!MainCardPref.on.value) return const SizedBox.shrink(); // 설정에서 끔
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024, 1, 1)).inDays;

    // 라디오 추천: 안 들어 본 방송 (아래 '최근에 들었어요'와 안 겹치게) — 국내 방송이라 한국어일 때만
    final radio = context.watch<RadioProvider>();
    final cur = radio.currentStation?.name;
    final pick = isKo
        ? niceKoreanStationNow(skip: {for (final r in radio.recentlyListened) r.name, if (cur != null) cur}, day: day)
        : null;

    // 오늘 카드 차례 (점 개수 = 오늘 카드 수 · 닫은 카드도 점 자리는 그대로)
    final deck = <String>[
      if (_showColorTip || _homeClosed.contains('color')) 'color',
      if (pick != null) 'radio',
      'tip',
    ];
    final open = deck.where((k) => k == 'color' ? _showColorTip : !_homeClosed.contains(k)).toList();
    // 다 닫았는지 설정 화면에 알려 주기 (그리는 중엔 못 바꿔서 그린 다음에)
    final allClosed = open.isEmpty;
    if (MainCardPref.allClosedToday.value != allClosed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => MainCardPref.allClosedToday.value = allClosed);
    }
    if (open.isEmpty) return const SizedBox.shrink(); // 다 닫으면 오늘은 카드 없음 (내일 다시 처음부터)
    final key = open.first;
    final dot = deck.indexOf(key);
    final dots = deck.length;

    // ① 나만의 색 (나오는 조건은 예전 그대로)
    if (key == 'color') return _buildColorTip(isDark, dot: dot, dots: dots);

    // ② 이런 방송은 어때요?
    if (key == 'radio' && pick != null) {
      final s = pick;
      _askProgram(radio, s);
      final p = radio.currentProgramFor(s.name);
      final prog = (radio.nowPlayingFor(s.name) ?? p?['program_title'] ?? p?['title'] ?? '').toString().trim();
      final h = now.hour;
      final mood = (h >= 5 && h < 11)
          ? '아침을 여는 방송이에요'
          : (h >= 11 && h < 17)
              ? '낮에 듣기 좋은 방송이에요'
              : (h >= 17 && h < 22)
                  ? '저녁에 듣기 좋은 방송이에요'
                  : '밤에 듣기 좋은 잔잔한 방송이에요';
      return _homeInfoCard(
        isDark: isDark,
        lead: _LiveBadge(hole: card),
        label: '이런 방송은 어때요?',
        title: s.name,
        sub: prog.isNotEmpty ? '지금 · $prog' : mood,
        action: '듣기',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RadioPlayerScreen(station: s, openedFromList: false)),
        ),
        onClose: () => _closeHomeCard('radio'),
        dot: dot,
        dots: dots,
      );
    }

    // ③ 오늘의 팁 (하루에 하나씩)
    final i = day % _mainTips.length;
    final t = _mainTips[i];
    return _homeInfoCard(
      isDark: isDark,
      lead: _TipBadge(hole: card),
      label: isKo ? '오늘의 팁' : 'TIP',
      title: isKo ? t.$1 : t.$3,
      sub: isKo ? t.$2 : t.$4,
      action: i == 1 ? (isKo ? '설정' : 'Set') : null,
      onAction: i == 1
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()))
          : null,
      onClose: () => _closeHomeCard('tip'),
      dot: dot,
      dots: dots,
    );
  }

  /// 카드 오른쪽 위 작은 ✕ (보이는 건 작게, 누르는 자리는 넉넉하게) — 알림 카드 모두 같은 모양
  Widget _cardCloseX(Color color, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.close_rounded, size: 15, color: color),
        ),
      );

  /// 카드 아래 작은 점 (지금 카드는 길쭉하게)
  Widget _cardDots(int index, int count, Color on, Color off) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var k = 0; k < count; k++) ...[
            if (k > 0) const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: k == index ? 12 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: k == index ? on : off,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      );

  /// 메인 홈 카드 모양 (✕는 오른쪽 위, 점은 가운데 아래)
  Widget _homeInfoCard({
    required bool isDark,
    required Widget lead,
    required String label,
    required String title,
    required String sub,
    String? action,
    VoidCallback? onAction,
    VoidCallback? onClose,
    int dot = 0,
    int dots = 1,
  }) {
    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);
    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
    final subC = isDark ? const Color(0xFFA29A8B) : const Color(0xFF746C60);
    final showDots = dots > 1; // 색은 왼쪽 동그라미 그림만 (이름표·점은 회색·먹색)
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17140F).withOpacity(isDark ? 0.4 : 0.10),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF17140F).withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      // ✕·점이 카드 안쪽에 있어야 눌려서: 여백은 글자 줄에만 주고 ✕·점은 카드 모서리 기준으로
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, onClose == null ? 14 : 34, showDots ? 18 : 14),
            child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: lead,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subC, fontSize: 10, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ink, fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subC, fontSize: 11.5, height: 1.15)),
                  ],
                ),
              ),
              if (action != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    onAction();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
                    child: Text(action, style: TextStyle(color: card, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
          ),
          // ✕ 오른쪽 위 모서리
          if (onClose != null)
            Positioned(top: 2, right: 2, child: _cardCloseX(subC, onClose)),
          // 점: 카드 아래 가운데
          if (showDots)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Center(child: _cardDots(dot, dots, ink, subC.withOpacity(0.3))),
            ),
        ],
      ),
    );
  }

  /// 나만의 색 카드 (메인 홈 카드와 같은 모양 · 색 고리 + [꾸미기])
  Widget _buildColorTip(bool isDark, {int dot = 0, int dots = 1}) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);
    return _homeInfoCard(
      isDark: isDark,
      lead: _SpinRing(hole: card),
      label: isKo ? '강조 색상' : 'Accent color',
      title: isKo ? '나만의 색으로 꾸며보세요' : 'Make it your color',
      sub: isKo ? '숲 · 노을 · 벚꽃 등 10가지 색' : '10 colors like Forest, Sunset, Blossom',
      action: isKo ? '꾸미기' : 'Try it',
      onAction: _openColorSheet,
      onClose: () {
        _finishColorTip();
        _closeHomeCard('color');
      },
      dot: dot,
      dots: dots,
    );
  }

  /// 홈에서 바로 색 고르기: 누르면 즉시 바뀌고 창은 열린 채로 (여러 색 비교) → [완료]
  Future<void> _openColorSheet() async {
    final t = context.read<ThemeProvider>();
    final dark = t.isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final sheetBg = dark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    await showParanSheet(
      context,
      title: isKo ? '강조 색상' : 'Accent color',
      // 창 머리 B안: 작은 '강조 색상'(지금 강조 색) + 도현체 큰 질문
      header: Builder(builder: (c) {
        final p = c.watch<ThemeProvider>().primaryColor;
        final label = p.value == 0xFF2589E8 ? (dark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8)) : p;
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isKo ? '강조 색상' : 'Accent color',
                  style: TextStyle(color: label, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(isKo ? '오늘 기분에 어울리는 색은?' : 'What color fits your mood today?',
                  textScaler: TextScaler.noScaling,
                  style: GoogleFonts.doHyeon(color: ink, fontSize: 21)),
            ],
          ),
        );
      }),
      builder: (ctx, setSheet) {
        Widget dot(int i) {
          final (name, c) = ThemeProvider.pointColors[i];
          final on = t.primaryColor.value == c.value;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                t.setPrimaryColor(c);
                setSheet(() {});
              },
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    padding: on ? const EdgeInsets.all(3) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? sheetBg : c,
                      border: on ? Border.all(color: ink, width: 2) : null,
                    ),
                    child: on ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c)) : null,
                  ),
                  const SizedBox(height: 6),
                  Text(isKo ? name : (_colorNameEn[name] ?? name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: on ? ink : sub,
                          fontSize: 11.5,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
          );
        }

        final n = ThemeProvider.pointColors.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var row = 0; row * 5 < n; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    for (var i = row * 5; i < row * 5 + 5; i++)
                      if (i < n) dot(i) else const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            // 나중에 바꾸는 곳 알려주기
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 2, bottom: 4),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: ink.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: sub),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(isKo ? '설정 → 꾸미기 → 강조 색상에서\n다시 변경할 수 있습니다.' : 'You can change it again\nanytime in Settings.',
                        style: TextStyle(color: sub, fontSize: 12.5, height: 1.45)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      footer: (ctx, setSheet) => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: sheetBg,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(isKo ? '완료' : 'Done', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        ),
      ),
    );
    // 창을 닫아도 카드는 그대로 (✕를 눌러야 끝)
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadHomeClosed(); // 메인 홈 카드: 오늘 닫은 것
    MainCardPref.load().then((_) => _onMainCardPref());
    MainCardPref.on.addListener(_onMainCardPref);
    MainCardPref.reopened.addListener(_onMainCardReopen);
    WidgetGo.target.addListener(_onWidgetGo); // 앱이 켜져 있을 때 위젯 바로가기
    HomeScreen.goHome.addListener(_onGoHome); // 집 아이콘 → 메인 홈
    _songListController.addListener(_updateCurrentGroup); // 스크롤하면 오른쪽 초성 파랗게 따라감
    _songListController.addListener(() {
      // 손으로 밀 때만 (정렬 바꿀 때 맨 위로 가는 건 빼고)
      if (_songListController.hasClients &&
          _songListController.position.userScrollDirection != ScrollDirection.idle) {
        _scrollPokeIndexBar();
        // 검색 중에 목록을 밀면 키보드만 내려가기
        if (_isSearching) FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    // 지난번 정렬(제목/가수) 불러오기
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool('song_sort_by_artist') ?? false;
      if (mounted && v != _byArtist) {
        setState(() {
          _byArtist = v;
          _indexFingerprint = -1;
        });
      }
    });
    final savedStart = context.read<StartScreenProvider>().startScreen;
    if (savedStart == StartScreenType.music) {
      _showMusicLibrary = true;
    } else if (savedStart == StartScreenType.radio || savedStart == StartScreenType.nature) {
      _pendingStartScreenNav = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final musicProvider = context.read<MusicProvider>();
      if (musicProvider.songs.isEmpty && !musicProvider.isLoading) {
        await musicProvider.initialize();
        context.read<PlaylistProvider>().restorePlaylistSongs(musicProvider.allSongs);
      }
      context.read<VideoProvider>().loadVideos();
      await _checkBanner();
      await _checkThemeHint();
      await _checkColorTip();
      // 위젯 바로가기로 켜졌으면 그 화면으로, 아니면 정해 둔 시작 화면으로
      if (WidgetGo.target.value != null) {
        await _handleWidgetGo();
      } else {
        await _navigateToSavedStartScreen();
      }
    });
  }

  /// 집 아이콘: 곡 목록·즐겨찾기·최근·검색을 다 닫고 메인 홈 화면으로
  void _onGoHome() {
    if (!mounted) return;
    if (_isSearching) {
      _searchController.clear();
      context.read<MusicProvider>().clearSearch();
    }
    setState(() {
      _isSearching = false;
      _showMusicLibrary = false;
      _showFavorites = false;
      _showRecent = false;
      _showCalls = false;
      _currentTabIndex = 0;
    });
  }

  void _onWidgetGo() {
    if (WidgetGo.target.value != null && mounted) _handleWidgetGo();
  }

  /// 홈 위젯 바로가기: 열려 있던 화면을 닫고 고른 화면으로
  Future<void> _handleWidgetGo() async {
    final t = WidgetGo.take();
    if (t == null || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _pendingStartScreenNav = false);
    PageRouteBuilder<void> instant(Widget page) => PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, __, ___, child) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
    switch (t) {
      case 'music':
        setState(() => _showMusicLibrary = true);
        break;
      case 'radio':
        await pushRadioEntry(context, instant: true);
        break;
      case 'nature':
        await Navigator.push(context, instant(NatureSoundsScreen()));
        break;
      case 'sleep':
        await Navigator.push(context, instant(const SleepFocusScreen()));
        break;
      case 'resume':
        // 위젯 재생: 마지막에 듣던 것 (재생이 끝날 때까지 기다리지 않게 그냥 시작만)
        HeadsetResume.widgetPlay();
        // 실제로 소리가 나기 시작하면 바탕화면으로 돌아가기 (음악은 계속)
        final pp = context.read<PlayerProvider>();
        final rp = context.read<RadioProvider>();
        for (var k = 0; k < 80 && !(pp.isPlaying || rp.isPlaying); k++) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (pp.isPlaying || rp.isPlaying) {
          await Future.delayed(const Duration(milliseconds: 300));
          try {
            await const MethodChannel('kr.ssing.catsong/media').invokeMethod('moveToBack');
          } catch (_) {}
        }
        break;
    }
  }

  Future<void> _navigateToSavedStartScreen() async {
    if (!mounted) return;
    final startScreen = context.read<StartScreenProvider>().startScreen;
    switch (startScreen) {
      case StartScreenType.music:
        setState(() => _showMusicLibrary = true);
        break;
      case StartScreenType.radio:
        await pushRadioEntry(context, instant: true);
        if (mounted) setState(() => _pendingStartScreenNav = false);
        break;
      case StartScreenType.nature:
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NatureSoundsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        if (mounted) setState(() => _pendingStartScreenNav = false);
        break;
      case StartScreenType.sleep:
      case null:
        break;
    }
  }

  Future<void> _checkThemeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('theme_hint_shown_count') ?? 0;
    if (count < 20) {
      await prefs.setInt('theme_hint_shown_count', count + 1);
      if (mounted) setState(() => _showThemeHint = true);
      Future.delayed(const Duration(seconds: 20), () {
        if (mounted) setState(() => _showThemeHint = false);
      });
    }
  }

  Future<void> _checkBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final isUnlocked = prefs.getBool('promo_unlocked') ?? false;
    if (isUnlocked) return;
    final now = DateTime.now();
    final start = DateTime(2026, 6, 7);
    final end = DateTime(2026, 7, 7);
    if (now.isBefore(start) || now.isAfter(end)) return;
    final lastShown = prefs.getString('banner_last_shown');
    final today = '${now.year}-${now.month}-${now.day}';
    if (lastShown == today) return;
    await prefs.setString('banner_last_shown', today);
  }

  @override
  void dispose() {
    WidgetGo.target.removeListener(_onWidgetGo);
    HomeScreen.goHome.removeListener(_onGoHome);
    MainCardPref.on.removeListener(_onMainCardPref);
    MainCardPref.reopened.removeListener(_onMainCardReopen);
    _searchController.dispose();
    _recentSaveTimer?.cancel();
    _songListController.dispose();
    _indexBubble.dispose();
    _currentGroup.dispose();
    _speech.stop();
    super.dispose();
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    _speech.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        _searchController.text = result.recognizedWords;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        context.read<MusicProvider>().search(result.recognizedWords);
        setState(() {});
      },
    );
  }

  void _handleStartScreenStarTap(BuildContext context, StartScreenType type, String label) {
    final provider = context.read<StartScreenProvider>();
    if (provider.startScreen == type) {
      provider.setStartScreen(null);
      showActionFeedback(context, type: ActionFeedbackType.canceled); // 취소했어요 (저장했어요처럼 슝)
      return;
    }
    _showSetStartScreenDialog(context, type, label);
  }

  void _showSetStartScreenDialog(BuildContext context, StartScreenType type, String label) async {
    final ok = await showParanConfirm(
      context,
      title: '앱 시작 화면으로 설정할까요?',
      message: '파란소리를 실행할 때 이 화면을 가장 먼저 보여드려요.',
      confirmLabel: '설정하기',
    );
    if (!ok || !context.mounted) return;
    context.read<StartScreenProvider>().setStartScreen(type);
    showActionFeedback(context, type: ActionFeedbackType.saved);
  }

  void _showExitConfirmDialog(BuildContext context) async {
    // 새 종료창 (사진 + 큰 질문) — 홈·음악·라디오·자연소리 공통
    if (await showExitConfirm(context) && context.mounted) _showFarewellAndExit(context);
  }

  // (예전 종료창 — 코드 정리할 때 지우기)
  void _oldExitConfirmDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '파란소리를 종료하시겠어요?',
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '다음에 또 좋은 소리로 만나요.',
                style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.white60 : Colors.black54,
                        side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('계속 듣기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                        _showFarewellAndExit(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('종료', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFarewellAndExit(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    late final String smallText;
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        smallText = '파란소리와 함께한 시간,\n즐거우셨나요?\n\n언제든 다시 찾아오시면,\n좋은 소리로 맞아드릴게요.\n안녕히 가세요!';
        farewellAsset = 'assets/farewell_ko_v4.mp3';
        break;
      case 'ja':
        smallText = 'Paransoriと過ごした時間、\n楽しんでいただけましたか?\n\nいつでもまた遊びに来てください、\n素敵な音でお迎えします。\nまた会いましょう!';
        farewellAsset = 'assets/farewell_ja.mp3';
        break;
      case 'zh':
        smallText = '与Paransori相伴的时光，\n您开心吗?\n\n欢迎随时回来，\n我们会用美好的声音迎接您。\n再见啦!';
        farewellAsset = 'assets/farewell_zh.mp3';
        break;
      default:
        smallText = 'Did you enjoy your time\nwith Paransori?\n\nCome back anytime — we\'ll\nwelcome you with great sounds again.\nGoodbye, and see you soon!';
        farewellAsset = 'assets/farewell_en.mp3';
    }
    if (langCode == 'ko' && context.read<ThemeProvider>().voiceGreetingEnabled) {
      final farewellPlayer = AudioPlayer();
      farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
    }

    // 끝인사 동안 음악·라디오 소리를 1.5초에 걸쳐 천천히 작게 (목소리가 잘 들리게)
    final fadePlayer = context.read<PlayerProvider>().player;
    final fadeRadio = context.read<RadioProvider>();
    final fadeStart = DateTime.now();
    Timer.periodic(const Duration(milliseconds: 50), (t) {
      final p = (DateTime.now().difference(fadeStart).inMilliseconds / 1500).clamp(0.0, 1.0);
      final v = 1 - 0.88 * Curves.easeOut.transform(p);
      fadePlayer.setVolume(v);
      fadeRadio.setAlarmVolume(v);
      if (p >= 1) t.cancel();
    });
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

      try {
        await context.read<PlayerProvider>().stopNatureSound();
      } catch (_) {}
      try {
        await context.read<RadioProvider>().stopRadio();
        await context.read<RadioProvider>().setAlarmVolume(1.0); // 다음에 켤 때는 원래 크기
      } catch (_) {}
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

  void _showMultiDeleteDialog(BuildContext context, MusicProvider musicProvider) async {
    final ok = await showParanConfirm(
      context,
      title: '${_selectedSongIds.length}곡을 삭제할까요?',
      message: '선택한 곡이 폰에서 지워져요',
      confirmLabel: '삭제',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    const platform = MethodChannel('kr.ssing.catsong/media');
    final selectedSongs = musicProvider.songs.where((s) => _selectedSongIds.contains(s.id)).toList();
    final paths = selectedSongs.where((s) => s.uri != null).map((s) => s.uri!).toList();
    int successCount = 0;
    try {
      final result = await platform.invokeMethod('deleteSongs', {'paths': paths});
      if (result == true) successCount = paths.length;
    } catch (e) {
      debugPrint('일괄 삭제 실패: $e');
    }
    setState(() {
      _isSelectionMode = false;
      _selectedSongIds.clear();
    });
    musicProvider.loadSongs();
    if (context.mounted) {
      if (successCount > 0) {
        showActionFeedback(context, type: ActionFeedbackType.deleted, message: '$successCount곡을 삭제했어요');
      } else {
        showParanToast(context, '삭제하지 못했어요', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSong = context.read<PlayerProvider>().currentSong;
      if (currentSong != null && currentSong.id != _lastScrolledSongId) {
        _lastScrolledSongId = currentSong.id;
        final key = _songItemKeys[currentSong.id];
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_isSearching) {
          setState(() => _isSearching = false);
          _searchController.clear();
          context.read<MusicProvider>().clearSearch();
        } else if (_currentTabIndex != 0) {
          // 앨범·아티스트·재생목록·폴더·동영상 탭 → 곡 탭으로
          setState(() => _currentTabIndex = 0);
        } else {
          const platform = MethodChannel('kr.ssing.catsong/media');
          platform.invokeMethod('moveToBackground');
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
        appBar: _buildAppBar(primaryColor),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
              ),
              child: Consumer2<RadioProvider, PlayerProvider>(
                builder: (context, radioProvider, playerProvider, _) {
                  if (playerProvider.currentSong != null) {
                    return const MiniPlayer();
                  }
                  if (radioProvider.currentStation != null) {
                    return const RadioMiniPlayer();
                  }
                  if (playerProvider.natureSoundName != null) {
                    return const NatureMiniPlayer();
                  }
                  if (context.watch<SoundMixProvider>().hasSession) {
                    return const SoundMixMiniPlayer();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _showMusicLibrary
            ? _buildBottomNavBar(primaryColor)
            : const SafeArea(top: false, child: SizedBox.shrink()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    // 로고: 기본 색(파란소리)일 땐 "파란"만 파랑, 다른 포인트 색이면 글씨는 전부 먹색 + 막대만 포인트 색
    final pointColor = context.watch<ThemeProvider>().primaryColor;
    final isBluePoint = pointColor.value == 0xFF2589E8;
    final logoBarColor = isBluePoint ? const Color(0xFF2F7DE8) : pointColor;
    // 로고 글자: 순검정·순흰색 대신 먹색 / 크림색 (화면 톤과 맞게)
    final logoInk = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      elevation: 0,
      titleSpacing: 20,
      title: _isSearching
          ? _buildSearchField()
          : Builder(builder: (ctx) {
        final isKorean = Localizations.localeOf(context).languageCode == 'ko';
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isKorean
                // 한국어: 위 '파란소리 + 소리 막대', 아래 Paransori를 같은 폭으로 늘려 맞춤
                ? Padding(
                    // 로고 전체를 살짝 아래로 (오른쪽 아이콘들과 높이 맞춤)
                    padding: const EdgeInsets.only(top: 4),
                    child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "파란"만 숨쉬듯 은은하게
                            if (isBluePoint)
                              _LogoBreathe(
                                child: Text('파란',
                                    textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                                    style: GoogleFonts.doHyeon(
                                        color: const Color(0xFF2F7DE8),
                                        fontSize: 22,
                                        letterSpacing: -0.5)),
                              )
                            else
                              _LogoBreathe(
                                base: logoInk,
                                glow: pointColor,
                                child: Text('파란',
                                    textScaler: TextScaler.noScaling,
                                    style: GoogleFonts.doHyeon(
                                        color: logoInk,
                                        fontSize: 22,
                                        letterSpacing: -0.5)),
                              ),
                            Text('소리',
                                textScaler: TextScaler.noScaling,
                                style: GoogleFonts.doHyeon(
                                    color: logoInk,
                                    fontSize: 22,
                                    letterSpacing: -0.5)),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: _LogoEqBars(color: logoBarColor),
                            ),
                          ],
                        ),
                        // Paransori: 글자를 고르게 벌려서 '파' 왼쪽 끝 ~ 막대 오른쪽 끝까지
                        Transform.translate(
                          offset: const Offset(0, -6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final ch in 'Paransori'.split(''))
                                  Text(ch,
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.quicksand(
                                          color: logoInk.withOpacity(0.75),
                                          fontSize: 12,
                                          height: 1.0,
                                          fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  )
                : Column(
                    // 해외: Paran(파란색) / 밑에 Sori (가운데 정렬)
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isBluePoint)
                        _LogoBreathe(
                          child: Text('Paran',
                              style: GoogleFonts.quicksand(
                                  color: const Color(0xFF2F7DE8),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: 0.2)),
                        )
                      else
                        _LogoBreathe(
                          base: logoInk,
                          glow: pointColor,
                          child: Text('Paran',
                              style: GoogleFonts.quicksand(
                                  color: logoInk,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: 0.2)),
                        ),
                      Text('sori',
                          style: GoogleFonts.quicksand(
                              color: logoInk,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                              letterSpacing: 0.2)),
                    ],
                  ),
            if (!isKorean) ...[
              const SizedBox(width: 6),
              Padding(
                // 해외는 아래 Sori 옆에 붙게 (파란 Paran과 안 겹치게)
                padding: const EdgeInsets.only(top: 23, bottom: 4),
                child: _LogoEqBars(color: logoBarColor),
              ),
            ],
          ],
        );
      }),
      actions: [
        if (!_isSearching) ...[
          if (_showMusicLibrary) ...[
            _AppBarCircleButton(
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                setState(() => _isSearching = true);
              },
              icon: Icons.search,
              baseColor: baseColor,
            ),
            const SizedBox(width: 8),
          ],
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllFavoritesScreen()),
              );
            },
            icon: CupertinoIcons.heart,
            baseColor: baseColor,
          ),
          const SizedBox(width: 8),
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              context.read<ThemeProvider>().setDarkMode(!isDarkMode);
            },
            icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            baseColor: baseColor,
          ),
          const SizedBox(width: 8),
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              _showExitConfirmDialog(context);
            },
            icon: Icons.power_settings_new_rounded,
            baseColor: baseColor,
          ),
          const SizedBox(width: 8),
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              showMoreMenuSheet(context);
              return;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withOpacity(0.45),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) {
                  final sheetBg = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAFCFE);
                  final cardBg = isDarkMode
                      ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF22303F), Color(0xFF1A2632)])
                      : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFEAF3FC)]);
                  final cardBorder = isDarkMode ? Colors.white12 : const Color(0xFFE1EDF7);
                  const navy = Color(0xFF15304D);
                  final subColor = isDarkMode ? Colors.white60 : const Color(0xFF7891A8);

                  Widget menuCard({
                    required IconData icon,
                    required String title,
                    required String subtitle,
                    required VoidCallback onTap,
                  }) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: cardBg,
                            border: Border.all(color: cardBorder),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.45)
                                    : const Color(0xFF2C6BB3).withOpacity(0.16),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF4A90D9), Color(0xFF2C6BB3)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2C6BB3).withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: Colors.white, size: 21),
                              ),
                              const SizedBox(height: 14),
                              Text(title,
                                  style: TextStyle(
                                      color: isDarkMode ? Colors.white : navy,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(subtitle,
                                  maxLines: 2,
                                  style: TextStyle(color: subColor, fontSize: 11, height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetBg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white24 : const Color(0xFFCBD9EC),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : const Color(0xFFF0F5FA),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close,
                                    size: 16, color: isDarkMode ? Colors.white70 : subColor),
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                menuCard(
                                  icon: Icons.share_outlined,
                                  title: '친구에게 공유하기',
                                  subtitle: '파란소리를 친구에게\n소개해보세요.',
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Share.share('파란소리 앱으로 음악 들어요! 🎧\nhttps://play.google.com/store/apps/details?id=kr.ssing.catsong');
                                  },
                                ),
                                const SizedBox(width: 12),
                                menuCard(
                                  icon: Icons.star_border_rounded,
                                  title: '앱 평가하기',
                                  subtitle: '좋은 평가가\n큰 힘이 됩니다.',
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final uri = Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                menuCard(
                                  icon: Icons.settings_outlined,
                                  title: '설정',
                                  subtitle: '앱 환경을\n설정할 수 있어요.',
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                        transitionDuration: const Duration(milliseconds: 250),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                menuCard(
                                  icon: Icons.settings_input_antenna_rounded,
                                  title: '방송국 바로가기',
                                  subtitle: '다양한 라디오 방송을\n바로 들어보세요.',
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    pushRadioEntry(context);
                                  },
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
            },
            icon: Icons.more_vert,
            baseColor: baseColor,
          ),
          const SizedBox(width: 12),
        ] else
          Transform.translate(
            offset: const Offset(-12, 0),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() => _isSearching = false);
                _searchController.clear();
                context.read<MusicProvider>().clearSearch();
              },
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: baseColor, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    // 크림 상자 · 회갈색 아이콘 (⋮ 메뉴 카드·아이콘과 같은 색)
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    const iconColor = Color(0xFF8A8378);
    final hasText = _searchController.text.isNotEmpty;
    return TextField(
      controller: _searchController,
      autofocus: true,
      // 키보드 [검색] 누르면 키보드만 내려가서 결과가 다 보이게
      textInputAction: TextInputAction.search,
      onSubmitted: (v) {
        FocusManager.instance.primaryFocus?.unfocus();
        _addRecentSearch(v);
      },
      cursorColor: ink,
      style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchHint,
        hintStyle: TextStyle(color: ink.withOpacity(0.38), fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: dark ? const Color(0xFF34312C) : const Color(0xFFFBF8F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        prefixIcon: const Icon(Icons.search, color: iconColor, size: 20),
        // 글자가 있으면 ✕(글자만 지우기), 없으면 마이크
        suffixIcon: hasText
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  context.read<MusicProvider>().search('');
                  setState(() {});
                },
                icon: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: ink.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, size: 12, color: dark ? const Color(0xFF24221F) : Colors.white),
                ),
              )
            : IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.redAccent : iconColor,
                  size: 20,
                ),
                onPressed: _toggleListening,
              ),
        isDense: true,
      ),
      onChanged: (value) {
        context.read<MusicProvider>().search(value);
        setState(() {});
        // 1.5초 동안 더 안 치면 최근 검색어로 저장
        _recentSaveTimer?.cancel();
        _recentSaveTimer = Timer(const Duration(milliseconds: 1500), () => _addRecentSearch(value));
      },
    );
  }

  // ── 최근 검색어 ──
  Future<void> _loadRecentSearches() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _recentSearches = p.getStringList('recent_searches') ?? []);
  }

  Future<void> _saveRecentSearches() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('recent_searches', _recentSearches);
  }

  void _addRecentSearch(String q) {
    final t = q.trim();
    if (t.isEmpty || !mounted) return;
    setState(() {
      _recentSearches.remove(t);
      _recentSearches.insert(0, t);
      if (_recentSearches.length > 8) _recentSearches = _recentSearches.sublist(0, 8);
    });
    _saveRecentSearches();
  }

  void _useRecentSearch(String q) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    _searchController.text = q;
    _searchController.selection = TextSelection.collapsed(offset: q.length);
    context.read<MusicProvider>().search(q);
    FocusManager.instance.primaryFocus?.unfocus();
    _addRecentSearch(q);
  }

  Widget _buildRecentSearches() {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final base = dark ? Colors.white : Colors.black;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('최근 검색',
                  style: TextStyle(color: base.withOpacity(0.45), fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                setState(() => _recentSearches = []);
                _saveRecentSearches();
              },
              child: Text('전체 지우기', style: TextStyle(color: base.withOpacity(0.4), fontSize: 12)),
            ),
          ],
        ),
        for (final q in _recentSearches)
          InkWell(
            onTap: () => _useRecentSearch(q),
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: base.withOpacity(0.32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: base.withOpacity(0.85), fontSize: 14.5)),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _recentSearches.remove(q));
                      _saveRecentSearches();
                    },
                    icon: Icon(Icons.close_rounded, size: 16, color: base.withOpacity(0.32)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    // 검색칸이 비어 있으면 최근 검색어
    if (_isSearching && _searchController.text.trim().isEmpty && _recentSearches.isNotEmpty) {
      return _buildRecentSearches();
    }
    switch (_currentTabIndex) {
      case 0:
        if (_showCalls) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showCalls = false);
              return false;
            },
            child: const CallRecordingsScreen(),
          );
        }
        if (_showFavorites) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showFavorites = false);
              return false;
            },
            child: const FavoritesScreen(),
          );
        }
        if (_showRecent) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showRecent = false);
              return false;
            },
            child: const RecentScreen(key: ValueKey('recent')),
          );
        }
        if (_showMusicLibrary) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showMusicLibrary = false);
              return false;
            },
            child: _buildSongsTab(),
          );
        }
        if (_pendingStartScreenNav) {
          return const SizedBox.shrink();
        }
        return _buildDashboard();
      case 1:
        return AlbumScreen(searchQuery: _isSearching ? _searchController.text : '');
      case 2:
        return ArtistScreen(searchQuery: _isSearching ? _searchController.text : '');
      case 3:
        return const PlaylistScreen();
      case 4:
        return const FolderScreen();
      case 5:
        return const VideoScreen();
      default:
        return _buildSongsTab();
    }
  }

  Widget _buildDashboard() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = Theme.of(context).colorScheme.primary;
    // 7일 안에 들은 것만 · 같은 것은 가장 최근 한 번만 · 최대 20개
    // 지운 곡은 빼기: 곡 목록을 다 불러온 뒤에만 (불러오는 중엔 그대로 두기)
    final songsReady = context.select<MusicProvider, int>(
        (m) => m.isLoading || m.allSongs.isEmpty ? -1 : m.allSongs.length);
    final songUris = songsReady < 0
        ? null
        : {for (final s in context.read<MusicProvider>().allSongs) s.uri};
    final recentContent = () {
      final cut = DateTime.now().subtract(const Duration(days: 7));
      final seen = <String>{};
      final out = <RecentContentEntry>[];
      for (final e in context.watch<RecentContentProvider>().entries) {
        if (e.playedAt.isBefore(cut)) continue;
        if (songUris != null && e.type == RecentContentType.music && !songUris.contains(e.songUri)) continue;
        if (!seen.add('${e.type.name}|${e.key}')) continue;
        out.add(e);
        if (out.length >= 20) break;
      }
      return out;
    }();

    final startScreen = context.watch<StartScreenProvider>().startScreen;

    final categories = [
      _DashboardCategory('음악', '내 음악 · MP3 플레이어', 'assets/music_bg.jpg', StartScreenType.music, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        setState(() => _showMusicLibrary = true);
      }),
      _DashboardCategory('라디오', '국내외 라디오 · 즐겨찾기', 'assets/radio_bg.jpg', StartScreenType.radio, () {
        pushRadioEntry(context);
      }),
      _DashboardCategory('자연', '비 · 바람 · 숲 · 파도', 'assets/nature_bg.jpg', StartScreenType.nature, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NatureSoundsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }),
      _DashboardCategory('휴식 · 집중', '백색소음 · 집중 소리 (준비중)', 'assets/sleep_bg.jpg', StartScreenType.sleep, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SleepFocusScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }),
    ];

    // ── 잠시 쉬어가요: 하루에 한 번 바뀌는 추천 (자연소리 2개 + 편안한 라디오 1개) ──
    final now = DateTime.now();
    final daySeed = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 86400000;

    // 자연소리: 서로 다른 종류로 2개
    final naturePool = natureSoundCatalog.where((s) => s.isReady).toList()
      ..shuffle(math.Random(daySeed));
    final naturePicks = <NatureSound>[];
    for (final s in naturePool) {
      if (naturePicks.any((p) => p.category == s.category)) continue;
      naturePicks.add(s);
      if (naturePicks.length == 2) break;
    }

    const restColors = <String, Color>{
      '파도소리': Color(0xFF4A7BA6),
      '빗소리': Color(0xFF3E5A78),
      '새소리': Color(0xFF5C7A5E),
      '모닥불': Color(0xFFC97B4A),
      '시냇물': Color(0xFF2C6BB3),
    };

    String natureImage(NatureSound s) {
      // 잠시 쉬어가요 전용 작은 사진 (재생 화면 배경은 그대로)
      switch (s.category) {
        case '파도소리':
          return 'assets/rest_wave.jpg';
        case '빗소리':
          return 'assets/rest_rain.jpg';
        case '새소리':
          return 'assets/rest_bird.jpg';
        case '모닥불':
          return 'assets/rest_fire.jpg';
        case '시냇물':
          return 'assets/rest_stream.jpg';
        default:
          return 'assets/rest_wave.jpg';
      }
    }

    // 편안한 라디오: 하루에 하나씩 돌아가며 (보이는 이름, 방송국 이름, 주파수, 주소)
    const restRadios = [
      ('KBS 클래식FM', 'KBS Classic FM', '93.1 MHz',
          'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/24'),
      ('국악FM', '국악FM', '99.1 MHz',
          'http://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8'),
      ('CBS 음악FM', 'CBS 음악FM', '93.9 MHz',
          'https://m-aac.cbs.co.kr/mweb_cbs939/_definst_/cbs939.stream/playlist.m3u8'),
    ];
    final todayRadio = restRadios[daySeed % restRadios.length];
    final restStation = RadioStation.fromJson({
      'stationuuid': 'kr_${todayRadio.$2.hashCode.abs()}',
      'name': todayRadio.$2,
      'url': todayRadio.$4,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': todayRadio.$3,
      'country': 'South Korea',
      'countrycode': 'KR',
      'bitrate': 0,
      'votes': 0,
    });

    // (카드 글자, 사진, 눌렀을 때)
    final recommended = <(String, String, VoidCallback)>[
      for (final s in naturePicks)
        (
          s.name,
          natureImage(s),
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NatureSoundDetailScreen(
                    name: s.name,
                    icon: s.icon,
                    description: s.description,
                    assetPath: s.assetPath,
                    color: restColors[s.category] ?? const Color(0xFF2F7DE8),
                    openedFromList: false, // 뒤로가기 → 자연소리 목록
                  ),
                ),
              ),
        ),
      (
        todayRadio.$1,
        'assets/rest_radio.jpg',
        () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadioPlayerScreen(
                  station: restStation,
                  openedFromList: false, // 뒤로가기 → 라디오 목록
                ),
              ),
            ),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHomeCard(isDarkMode), // 나만의 색 → 지금 방송 → 오늘의 팁
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: baseColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('이런 소리는 어때요?',
                  style: GoogleFonts.doHyeon( // 로고와 같은 글꼴
                      color: baseColor, fontSize: 16.5, fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: categories.map((c) {
              return GestureDetector(
                onTap: c.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      // 살짝 떠 있는 느낌: 넓고 연한 그림자 + 바로 밑 얇은 그림자
                      BoxShadow(
                        color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.45 : 0.13),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.3 : 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          c.imageAsset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.4), // 물건·사람이 위쪽에 있어서
                          cacheWidth: 600, // 화면 크기만큼만 불러오기 (램 아끼기)
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: baseColor.withOpacity(0.08),
                          ),
                        ),
                        // 밝은 사진: 먹색 글자 (어두운 칸 없음)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            child: RepaintBoundary( // 흐림 효과 빼기 (폰이 버벅이고 사진이 회색으로 나오던 원인)
                              
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                                // 유리 띠: 반투명 흰색 + 위쪽 얇은 흰 선 (흐림 효과 없이, 속도 그대로)
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.42),
                                  border: Border(
                                    top: BorderSide(color: Colors.white.withOpacity(0.6)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text.rich(
                                        TextSpan(children: [
                                          // 제목 앞 작은 아이콘 (둥근 모양)
                                          WidgetSpan(
                                            alignment: PlaceholderAlignment.middle,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 5),
                                              child: Icon(
                                                c.type == StartScreenType.music
                                                    ? Icons.music_note_rounded
                                                    : c.type == StartScreenType.radio
                                                        ? Icons.radio_rounded
                                                        : c.type == StartScreenType.nature
                                                            ? Icons.eco_rounded
                                                            : Icons.bedtime_rounded,
                                                size: 15,
                                                color: const Color(0xFF17140F).withOpacity(0.75),
                                              ),
                                            ),
                                          ),
                                          TextSpan(text: c.title),
                                        ]),
                                        style: GoogleFonts.doHyeon(
                                            color: const Color(0xFF17140F),
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -0.3,
                                            // 붕 뜬 느낌: 아래로 살짝 내린 옅은 그림자 + 위쪽 흰 빛
                                            shadows: [
                                              Shadow(
                                                color: const Color(0xFF17140F).withOpacity(0.13),
                                                offset: const Offset(0, 1.5),
                                                blurRadius: 3,
                                              ),
                                              Shadow(
                                                color: Colors.white.withOpacity(0.6),
                                                offset: const Offset(0, -0.5),
                                                blurRadius: 1,
                                              ),
                                            ])),
                                    const SizedBox(height: 2),
                                    Text(c.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: const Color(0xFF17140F).withOpacity(0.6),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              _handleStartScreenStarTap(context, c.type, c.title);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                startScreen == c.type
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                size: 13,
                                color: startScreen == c.type
                                    ? (context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                                        ? const Color(0xFF2F7DE8) // 기본이면 로고 파랑
                                        : context.watch<ThemeProvider>().primaryColor)
                                    : const Color(0xFF17140F).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.volume_up_rounded, size: 18, color: baseColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('잠시 쉬어가요',
                  style: GoogleFonts.doHyeon( // 로고와 같은 글꼴
                      color: baseColor, fontSize: 16.5, fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: Row(
              children: List.generate(recommended.length * 2 - 1, (i) {
                if (i.isOdd) return const SizedBox(width: 12);
                final item = recommended[i ~/ 2];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      item.$3();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.45 : 0.13),
                            blurRadius: 20,
                            spreadRadius: -4,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.3 : 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            paranPhoto(
                              item.$2,
                              thumb: true,
                              fit: BoxFit.cover,
                              fallback: Container(color: baseColor.withOpacity(0.08)),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ClipRRect(
                                child: RepaintBoundary( // 흐림 효과 빼기 (폰이 버벅이고 사진이 회색으로 나오던 원인)
                                  
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
                                    // 유리 띠 (위 카드와 같은 모양, 어두운 사진에서도 읽히게 조금 더 진하게)
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBF8F2).withOpacity(0.78),
                                      border: Border(
                                        top: BorderSide(color: Colors.white.withOpacity(0.6)),
                                      ),
                                    ),
                                    child: Text(item.$1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.doHyeon( // 로고와 같은 글꼴
                                            color: const Color(0xFF17140F),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w400)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.headphones_rounded, size: 18, color: baseColor.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('최근에 들었어요',
                    style: GoogleFonts.doHyeon( // 로고와 같은 글꼴
                        color: baseColor, fontSize: 16.5, fontWeight: FontWeight.w400)),
              ],
            ),
            const SizedBox(height: 12),
            if (recentContent.isEmpty)
              Container(
                width: double.infinity,
                height: 124,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [const Color(0xFF1A2632), const Color(0xFF22303F)]
                        : [const Color(0xFFEAF3FC), const Color(0xFFD9E9F8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2C6BB3).withOpacity(isDarkMode ? 0.22 : 0.12),
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF2C6BB3), size: 19),
                    ),
                    const SizedBox(height: 10),
                    Text('최근 들은 곡이 없어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : const Color(0xFF15304D),
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('30초 이상 들은 곡·라디오·자연이 여기에 모여요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white60 : const Color(0xFF7891A8),
                            fontSize: 11)),
                  ],
                ),
              )
            else
              Builder(builder: (context) {
                // 다음곡/이전곡이 "최근 재생 기록" 안의 음악끼리만 넘어가도록,
                // 여기 보이는 것 중 음악 항목만 모아서 재생목록으로 쓴다.
                final musicProviderForQueue = context.read<MusicProvider>();
                final recentMusicSongs = <Song>[];
                for (final e in recentContent) {
                  if (e.type == RecentContentType.music) {
                    for (final s in musicProviderForQueue.allSongs) {
                      if (s.uri == e.songUri) {
                        recentMusicSongs.add(s);
                        break;
                      }
                    }
                  }
                }
                return SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentContent.length,
                  // 날짜 묶음이 바뀌는 곳에만 얇은 세로선
                  separatorBuilder: (_, i) => _recentGroup(recentContent[i].playedAt) ==
                          _recentGroup(recentContent[i + 1].playedAt)
                      ? const SizedBox(width: 14)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 56),
                          child: Container(width: 1, color: baseColor.withOpacity(0.12)),
                        ),
                  itemBuilder: (context, index) {
                    final item = recentContent[index];
                    // 묶음 첫 카드 위에만 날짜 (오늘 · 어제 · 3일 안 · 일주일 안)
                    final group = _recentGroup(item.playedAt);
                    final showGroup = index == 0 || _recentGroup(recentContent[index - 1].playedAt) != group;

                    IconData typeIcon;
                    Color typeColor;
                    Widget thumbnail;
                    VoidCallback onTapAction;

                    switch (item.type) {
                      case RecentContentType.music:
                        typeIcon = Icons.music_note_rounded;
                        typeColor = const Color(0xFF3B82F6);
                        final musicProvider = context.read<MusicProvider>();
                        Song? matched;
                        for (final s in musicProvider.allSongs) {
                          if (s.uri == item.songUri) {
                            matched = s;
                            break;
                          }
                        }
                        thumbnail = matched?.albumArt != null
                            ? Image.memory(
                          Uint8List.fromList(matched!.albumArt!),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          cacheWidth: 216, // 화면 크기만큼만
                        )
                            : _recentAsset(noAlbumImagePath(matched?.uri ?? item.songUri ?? item.title));
                        onTapAction = () async {
                          final pp = context.read<PlayerProvider>();
                          var song = matched;
                          var queue = recentMusicSongs;
                          if (song == null) {
                            // 앱을 막 켜서 곡 목록을 아직 불러오는 중 → 다 불러올 때까지 잠깐 기다렸다가 틀기
                            for (var i = 0; i < 40 && musicProvider.allSongs.isEmpty; i++) {
                              await Future.delayed(const Duration(milliseconds: 250));
                            }
                            final all = musicProvider.allSongs;
                            for (final s in all) {
                              if (s.uri == item.songUri) {
                                song = s;
                                break;
                              }
                            }
                            if (song == null) return; // 지운 곡 등
                            // 다음·이전용: 최근에 들은 음악끼리 다시 묶기
                            queue = <Song>[];
                            for (final e in recentContent) {
                              if (e.type != RecentContentType.music) continue;
                              for (final s in all) {
                                if (s.uri == e.songUri) {
                                  queue.add(s);
                                  break;
                                }
                              }
                            }
                          }
                          final target = song;
                          final queueIndex = queue.indexWhere((s) => s.uri == target.uri);
                          pp.playFromList(queue, queueIndex >= 0 ? queueIndex : 0);
                        };
                        break;
                      case RecentContentType.radio:
                        typeIcon = Icons.radio_rounded;
                        typeColor = const Color(0xFF8B5CF6);
                        thumbnail = _recentAsset(_radioSlotImage(item.playedAt));
                        onTapAction = () {
                          if (item.stationData != null) {
                            final station = RadioStation.fromJson(item.stationData!);
                            context.read<RadioProvider>().playStation(station);
                          }
                        };
                        break;
                      case RecentContentType.nature:
                        typeIcon = Icons.waves_rounded;
                        typeColor = const Color(0xFF10B981);
                        thumbnail = _recentAsset(MediaArt.natureImage(item.title));
                        onTapAction = () {
                          if (item.natureAssetPath != null) {
                            context.read<PlayerProvider>().playNatureSound(item.natureAssetPath!, item.title);
                          }
                        };
                        break;
                      case RecentContentType.sleep:
                        typeIcon = Icons.bedtime_rounded;
                        typeColor = const Color(0xFF6366F1);
                        thumbnail = _recentTile(isDarkMode, const Color(0xFFDDD6E8), Icons.bedtime_rounded);
                        onTapAction = () {};
                        break;
                    }

                    return GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        onTapAction();
                      },
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 18,
                              child: showGroup
                                  ? Text(group,
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800))
                                  : null,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.45 : 0.13),
                                    blurRadius: 14,
                                    spreadRadius: -3,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.3 : 0.06),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: thumbnail,
                                  ),
                                  Positioned(
                                    left: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(typeIcon, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.45), fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
              }),
          ],
        ],
      ),
    );
  }

  // ───── 곡 목록 맨 위 "정리 알려주기" 카드 ─────
  int? _messyCount; // 정리할 곡 수 (한 번만 세기)
  String _messyFrom = '', _messyTo = ''; // 예시로 보여줄 곡 (바뀌기 전 → 후)
  bool _cleanHintHidden = false;
  bool _cleanHintLoaded = false;

  int _countMessy(MusicProvider music) {
    final known = music.artists
        .map((x) => x.name.toLowerCase().trim())
        .where((n) => n.isNotEmpty && !n.contains('unknown') && n != '알 수 없는 아티스트')
        .toSet();
    var n = 0;
    var bestCut = 0;
    _messyFrom = '';
    _messyTo = '';
    for (final s in music.allSongs) {
      if (music.isCallRecordingPath(s.uri)) continue;
      final c = SongTitleCleaner.clean(s.titleDisplay, s.artistDisplay, knownArtists: known);
      if (c.title != s.titleDisplay || c.artist != s.artistDisplay) {
        n++;
        // 제일 많이 깔끔해지는 곡을 예시로
        final cut = s.titleDisplay.length - c.title.length;
        if (_messyFrom.isEmpty || cut > bestCut) {
          bestCut = cut;
          _messyFrom = s.titleDisplay;
          _messyTo = c.artist != s.artistDisplay ? '${c.title} · ${c.artist}' : c.title;
        }
      }
    }
    return n;
  }

  Widget _buildCleanHint(MusicProvider music, bool isDark) {
    if (!_cleanHintLoaded) {
      _cleanHintLoaded = true;
      SharedPreferences.getInstance().then((p) {
        final until = p.getInt('cleanHintHideUntil') ?? 0;
        if (mounted && DateTime.now().millisecondsSinceEpoch < until) setState(() => _cleanHintHidden = true);
      });
    }
    if (_cleanHintHidden || music.metaLoading || _showFavorites || _showRecent || _isSelectionMode) {
      return const SizedBox.shrink();
    }
    _messyCount ??= _countMessy(music);
    final n = _messyCount!;
    if (n < 3) return const SizedBox.shrink(); // 몇 곡 안 되면 안 띄움
    // 오늘의 카드와 같은 띠: 바탕보다 한 톤 진한 베이지 (다크는 바탕보다 한 톤 밝게)
    final card = isDark ? const Color(0xFF302D29) : const Color(0xFFDDD4C3);
    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF746C60);
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5); // [정리하기] 버튼 글자색
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = _readable(
        point.value == 0xFF2589E8
            ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
            : point,
        isDark);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      decoration: BoxDecoration(color: card),
      child: Row(
        children: [
          // 왼쪽 그림 (오늘의 카드와 같은 크기의 흰 칸)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3631) : const Color(0x8CFFFFFF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.auto_fix_high_rounded, size: 19, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('곡 정리',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 1),
                Text('곡 제목 $n개를 깔끔하게',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                if (_messyFrom.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  // 내 곡 하나로 예시: 01밤편지 (Through the Night) → 밤편지
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '$_messyFrom → '),
                      TextSpan(
                          text: _messyTo,
                          style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: sub, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          // 나중에 → 일주일 동안 안 띄움
          TextButton(
            onPressed: () async {
              setState(() => _cleanHintHidden = true);
              final p = await SharedPreferences.getInstance();
              await p.setInt('cleanHintHideUntil',
                  DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch);
            },
            style: TextButton.styleFrom(
              foregroundColor: sub,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('나중에', style: TextStyle(fontSize: 12.5)),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () async {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCleanScreen()));
              if (mounted) setState(() => _messyCount = null); // 돌아오면 다시 세기
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
              child: Text('정리하기', style: TextStyle(color: bg, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ───── 정리할 곡이 없을 때: 하루에 하나씩 바뀌는 "오늘의 카드" ─────
  Widget _buildTopCard(MusicProvider music, bool isDark) {
    final clean = _buildCleanHint(music, isDark);
    if (clean is! SizedBox) return clean; // 정리할 곡이 있으면 정리 카드가 먼저
    if (_showFavorites || _showRecent || _isSelectionMode) return clean; // 곡 정보를 다 안 읽어도 바로
    HomeCardPref.load();
    return ValueListenableBuilder<bool>(
      valueListenable: HomeCardPref.on,
      builder: (context, on, _) => !on
          ? const SizedBox.shrink()
          : ValueListenableBuilder<bool>(
              valueListenable: HomeCardPref.hiddenToday,
              builder: (context, hidden, _) =>
                  hidden ? const SizedBox.shrink() : _buildDailyCard(music, isDark),
            ),
    );
  }

  Widget _buildDailyCard(MusicProvider music, bool isDark) {
    // 양옆 끝까지 꽉 찬 띠: 바탕보다 한 톤 진한 베이지 (다크는 바탕보다 한 톤 밝게)
    final card = isDark ? const Color(0xFF302D29) : const Color(0xFFDDD4C3);
    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF746C60);
    final circle = isDark ? const Color(0xFF3A3631) : const Color(0x80FFFFFF);

    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024, 1, 1)).inDays;
    final songs = music.songs.where((s) => !music.isCallRecordingPath(s.uri)).toList();
    var kind = day % 5; // 날짜 따라 순서대로 (같은 날은 같은 카드)
    final notPlayed = kind == 1 ? music.songsNotPlayedFor(const Duration(days: 30)) : const <Song>[];
    final weekCount = kind == 2 ? music.weekPlayCount : 0;
    final weekTop = kind == 2 ? music.weekTopSong : null;
    final cardSongs = <Song>[]; // 카드에 나오는 곡 (이 곡 정보부터 먼저 읽기)
    // 보여줄 게 없으면 시간대 추천으로
    if (kind == 0 && songs.isEmpty) kind = 3;
    if (kind == 1 && notPlayed.length < 3) kind = 3;
    if (kind == 2 && (weekCount == 0 || weekTop == null)) kind = 3;
    // 아침 알람이 켜져 있으면 저녁 7시부터는 내일 알람 알려주기
    final alarm = AlarmService.alarm.value;
    final alarmNext = alarm != null && alarm.enabled && now.hour >= 19 ? AlarmService.nextLabel(alarm) : '';
    if (alarmNext.isNotEmpty) kind = 5;

    late IconData icon;
    late String title;
    late Widget subLine;
    String? action;
    VoidCallback? onAction;
    late String label; // 제목 위 작은 이름표
    late Widget lead; // 왼쪽 그림
    // 이름표·막대 강조 색 (기본 파랑이면 로고와 같은 파랑)
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = _readable(
        point.value == 0xFF2589E8
            ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
            : point,
        isDark);
    final softBox = isDark ? const Color(0xFF3A3631) : const Color(0x8CFFFFFF);

    if (kind == 0) {
      // ① 오늘의 한 곡: 듣기 기록으로 고르기
      //    이 시간대에 자주 듣던 곡 / 예전에 즐겨 듣다 한 달 넘게 안 들은 곡을 날마다 번갈아
      //    (기록이 없으면 예전처럼 날짜로 하나, 같은 날·같은 시간대엔 같은 곡)
      final slot = MusicProvider.slotOf(now);
      final often = music.songsOftenAt(slot).take(5).toList();
      final missed = music.songsMissed(const Duration(days: 30)).take(10).toList();
      final preferOften = (day + slot) % 2 == 0;
      final Song s;
      if (often.isNotEmpty && (preferOften || missed.isEmpty)) {
        s = often[math.Random(day * 4 + slot).nextInt(often.length)];
        label = '${const ['아침에', '낮에', '저녁에', '밤에'][slot]} 자주 듣던 곡';
      } else if (missed.isNotEmpty) {
        s = missed[math.Random(day).nextInt(missed.length)];
        label = '오랜만에 듣는 곡';
      } else {
        s = songs[math.Random(day).nextInt(songs.length)];
        label = '오늘의 곡';
      }
      final i = songs.indexWhere((x) => x.uri == s.uri);
      cardSongs.add(s);
      icon = Icons.album_outlined;
      lead = _cardArt(s, 40, isDark);
      title = '오늘은 이 곡 어때요';
      subLine = Text.rich(
        TextSpan(children: [
          TextSpan(text: s.titleDisplay, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
          TextSpan(text: '  ·  ${s.artistDisplay}'),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: sub, fontSize: 11.5),
      );
      action = '듣기';
      onAction = () => context.read<PlayerProvider>().playFromList(i >= 0 ? songs : [s], i >= 0 ? i : 0);
    } else if (kind == 1) {
      // ② 한 달 동안 안 들은 곡 (섞어서 틀기)
      cardSongs.addAll(notPlayed.take(3));
      icon = Icons.history_rounded;
      label = '다시 듣기';
      lead = SizedBox(
        width: 50,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var k = 0; k < math.min(3, notPlayed.length); k++)
              Positioned(
                left: k * 7.0,
                top: 4,
                child: Transform.rotate(
                  angle: const [-8.0, -2.0, 5.0][k] * math.pi / 180,
                  child: _cardArt(notPlayed[k], 32, isDark),
                ),
              ),
          ],
        ),
      );
      title = '한 달 동안 안 들은 곡 ${notPlayed.length}개';
      subLine = Text('오랜만에 다시 들어볼까요',
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
      action = '틀기';
      onAction = () {
        final list = List<Song>.from(notPlayed)..shuffle();
        context.read<PlayerProvider>().playFromList(list, 0);
      };
    } else if (kind == 2) {
      // ③ 최근 7일 듣기 기록 + 가장 많이 들은 곡
      final top = weekTop!;
      cardSongs.add(top);
      icon = Icons.bar_chart_rounded;
      label = '내 기록';
      lead = Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(color: softBox, borderRadius: BorderRadius.circular(9)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (k, hgt) in const [(0, 9.0), (1, 15.0), (2, 11.0), (3, 20.0), (4, 13.0)]) ...[
              if (k > 0) const SizedBox(width: 3),
              Container(
                width: 4,
                height: hgt,
                decoration: BoxDecoration(
                  color: k == 3 ? accent : ink.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      );
      title = '최근 7일 동안 $weekCount번 들었어요';
      subLine = Text.rich(
        TextSpan(children: [
          const TextSpan(text: '가장 많이 들은 곡  '),
          TextSpan(text: top.titleDisplay, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: sub, fontSize: 11.5),
      );
      action = '듣기';
      onAction = () {
        final i = songs.indexWhere((s) => s.uri == top.uri);
        context.read<PlayerProvider>().playFromList(i >= 0 ? songs : [top], i >= 0 ? i : 0);
      };
    } else if (kind == 3) {
      // ④ 시간대 추천 (자연소리)
      final h = now.hour;
      final (IconData ic, String t, String sound, String line) = h >= 5 && h < 11
          ? (Icons.wb_sunny_outlined, '상쾌한 아침이에요', '새소리', '새소리로 하루를 시작해요')
          : h >= 11 && h < 17
              ? (Icons.local_cafe_outlined, '잠깐 쉬어가요', '시냇물', '시냇물 소리 들으며 한숨 돌려요')
              : h >= 17 && h < 21
                  ? (Icons.waves_rounded, '오늘도 수고했어요', '파도소리', '파도소리 틀어놓고 쉬어요')
                  : (Icons.bedtime_outlined, '늦은 밤엔 잔잔하게', '빗소리', '빗소리 틀어놓고 쉬어요');
      icon = ic;
      label = '지금 이 시간';
      const natureImg = {
        '새소리': 'assets/nature_bird_bg.png',
        '시냇물': 'assets/nature_stream_bg.png',
        '파도소리': 'assets/nature_wave_bg.png',
        '빗소리': 'assets/nature_rain_bg.png',
      };
      lead = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipOval(
          child: paranPhoto(
            natureImg[sound] ?? 'assets/nature_wave_bg.png',
            thumb: true,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            fallback: Container(color: softBox, child: Icon(ic, size: 18, color: ink)),
          ),
        ),
      );
      title = t;
      subLine = Text(line,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
      final found = PlayerProvider.natureSoundOrder.where((e) => e['name'] == sound);
      if (found.isNotEmpty) {
        action = '듣기';
        final url = found.first['assetPath']!;
        onAction = () => context.read<PlayerProvider>().playNatureSound(url, sound);
      }
    } else if (kind == 5) {
      // ⑥ 내일 아침 알람
      icon = Icons.alarm_rounded;
      label = '내일 알람';
      final hm = RegExp(r'\d{1,2}:\d{2}').firstMatch(alarmNext)?.group(0);
      lead = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: softBox, borderRadius: BorderRadius.circular(9)),
        child: hm == null
            ? Icon(Icons.alarm_rounded, size: 18, color: ink)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Text(hm,
                        style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800, height: 1.0)),
                  ),
                  const SizedBox(height: 2),
                  Text(alarmNext.contains('내일') ? '내일' : '오늘',
                      style: TextStyle(color: sub, fontSize: 8.5, height: 1.0)),
                ],
              ),
      );
      title = '$alarmNext에 깨워 드릴게요';
      subLine = Text(alarm!.label,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
      action = '바꾸기';
      onAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()));
    } else {
      // ③ 기능 알려주기 (돌아올 때마다 다른 팁)
      const tips = <(IconData, String, String)>[
        (Icons.battery_charging_full_rounded, '화면 꺼도 계속 들어요', "배터리를 '제한 없음'으로 바꿔 주세요"),
        (Icons.notifications_active_outlined, '노래로 벨소리 만들기', '곡 ⋮ 메뉴에서 바로 만들어요'),
        (Icons.movie_outlined, '동영상 노래만 저장', "동영상 ⋮ 메뉴에서 '음악으로 저장'"),
        (Icons.water_drop_outlined, '음악에 빗소리 더하기', '재생 화면 ⋮ 메뉴 → 자연 소리 믹스'),
        (Icons.format_quote_rounded, '가사 한 줄 공유', '가사를 꾹 누르면 카드로 보내요'),
      ];
      final tip = tips[(day ~/ 5) % tips.length];
      icon = tip.$1;
      label = 'TIP';
      lead = CustomPaint(
        painter: _DashedBoxPainter(ink.withOpacity(0.28)),
        child: SizedBox(width: 40, height: 40, child: Icon(tip.$1, size: 18, color: ink)),
      );
      title = tip.$2;
      subLine = Text(tip.$3,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
      // 배터리 팁만: [설정] 누르면 파란소리 앱 설정이 바로 열림
      if (tip.$1 == Icons.battery_charging_full_rounded) {
        action = '설정';
        onAction = () => openAppSettings();
      }
    }

    // 카드에 나올 곡 정보를 아직 못 읽었으면: 그 곡부터 먼저 읽고, 그동안 띠만 (다 읽으면 글자가 스르르)
    final ready = cardSongs.every(music.metaReady);
    if (!ready) music.readFirst(cardSongs);
    return Container(
      // 모서리·그림자 없이 양옆 끝까지
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: card),
      // ✕가 카드 안쪽에 있어야 눌려서: 여백은 글자 줄에만
      child: Stack(
        children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 34, 10),
        child: AnimatedOpacity(
        opacity: ready ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Row(
        children: [
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 1),
                if (title == '오늘은 이 곡 어때요')
                  // 큰 물음표가 통통 튀기
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 2),
                      _BounceQ(color: accent),
                    ],
                  )
                else
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                subLine,
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                onAction?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
                child: Text(action, style: TextStyle(color: card, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
      ),
      ),
          // ✕ = 오늘만 숨기기 (오른쪽 위 모서리 · 메인 홈 카드와 같은 모양)
          Positioned(top: 0, right: 2, child: _cardCloseX(sub, _closeDailyCard)),
        ],
      ),
    );
  }

  /// 오늘의 카드 왼쪽: 곡 앨범 사진 (없으면 글자 타일)
  Widget _cardArt(Song s, double size, bool isDark) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.18),
          child: s.albumArt != null
              ? Image.memory(Uint8List.fromList(s.albumArt!),
                  width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (size * 3).round())
              : NoArtTile(title: s.titleDisplay, colorKey: s.uri ?? s.titleDisplay, size: size, isDark: isDark),
        ),
      );

  Future<void> _closeDailyCard() async {
    final ask = await HomeCardPref.closeToday();
    if (!ask || !mounted) return;
    final off = await showParanConfirm(
      context,
      title: '오늘의 카드를 끌까요?',
      message: '설정 → 홈 추천 카드에서 언제든 다시 켤 수 있어요',
      confirmLabel: '끄기',
      cancelLabel: '계속 볼래요',
    );
    if (off) HomeCardPref.setOn(false);
  }

  Widget _buildSongsTab() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        if (musicProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.scanningMusic,
                    style: TextStyle(color: baseColor.withOpacity(0.7))),
              ],
            ),
          );
        }

        if (!musicProvider.hasPermission) return _buildPermissionDeniedView(musicProvider);
        if (musicProvider.errorMessage.isNotEmpty) return _buildErrorView(musicProvider);
        if (musicProvider.songs.isEmpty) return _buildEmptySongsView();

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                color: baseColor.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: baseColor),
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedSongIds.clear();
                      }),
                    ),
                    Text(
                      AppLocalizations.of(context)!.selectedCount(_selectedSongIds.length),
                      style: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          final allIds = musicProvider.songs.map((s) => s.id).toSet();
                          if (_selectedSongIds.length == allIds.length) {
                            _selectedSongIds.clear();
                          } else {
                            _selectedSongIds = allIds;
                          }
                        });
                      },
                      child: Text(
                          _selectedSongIds.length == musicProvider.songs.length
                              ? AppLocalizations.of(context)!.deselectAll
                              : AppLocalizations.of(context)!.selectAll,
                          style: const TextStyle(color: AppTheme.fixedAccent)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _selectedSongIds.isEmpty
                          ? null
                          : () => _showMultiDeleteDialog(context, musicProvider),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildFilterTab(
                    AppLocalizations.of(context)!.all,
                    !_showFavorites && !_showRecent,
                        () => setState(() {
                      _showFavorites = false;
                      _showRecent = false;
                    }),
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildFilterTab(
                    AppLocalizations.of(context)!.favorites,
                    _showFavorites,
                        () => setState(() {
                      _showFavorites = true;
                      _showRecent = false;
                    }),
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildFilterTab(
                    AppLocalizations.of(context)!.recent,
                    _showRecent,
                        () => setState(() {
                      _showFavorites = false;
                      _showRecent = true;
                    }),
                    Theme.of(context).colorScheme.primary,
                  ),
                  // 녹음 (일반 음악과 따로) — 아이폰은 다른 앱 파일을 못 읽어서 안드로이드만
                  if (Platform.isAndroid) const Spacer(), // 통화녹음은 오른쪽 끝으로
                  // 통화녹음: 탭이 아니라 "다른 곳으로 가는" 작은 버튼 (안드로이드만)
                  if (Platform.isAndroid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() {
                            _showFavorites = false;
                            _showRecent = false;
                            _showCalls = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: baseColor.withOpacity(0.18), width: 0.8),
                          ),
                          child: Text('통화녹음 ›',
                              style: TextStyle(color: baseColor.withOpacity(0.65), fontSize: 12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 0),
              height: 1,
              color: baseColor.withOpacity(0.06),
            ),
            _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 3, 12, 3),
              child: Row(
                children: [
                  Text('${musicProvider.songCount} ${AppLocalizations.of(context)!.songCount}',
                      style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),
                  const Spacer(),
                  // 정렬: 제목 / 가수
                  // 누를 때마다 제목 ↔ 가수
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      final next = !_byArtist;
                      _setSortByArtist(next);
                      showParanToast(context, next ? '가수 이름순으로 정렬했어요' : '제목순으로 정렬했어요',
                          duration: const Duration(milliseconds: 1500));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert, size: 17, color: baseColor.withOpacity(0.55)),
                          const SizedBox(width: 2),
                          Text(_byArtist ? '가수' : '제목',
                              style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (musicProvider.songs.isNotEmpty) {
                        context.read<PlayerProvider>().playFromList(musicProvider.songs, 0);
                      }
                    },
                    icon: Icon(CupertinoIcons.play_fill,
                        color: baseColor.withOpacity(0.5), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (musicProvider.songs.isNotEmpty) {
                        final songs = List<Song>.from(musicProvider.songs)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                      }
                    },
                    icon: Icon(CupertinoIcons.shuffle, color: baseColor.withOpacity(0.5), size: 17),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(builder: (context) {
              // 빠른 이동 막대: 30곡 이상이고 검색 중이 아닐 때만
              // 새로 들어온 곡은 목록 맨 위로 (원래 자리에서는 빼기) — 전체 보기에서만, 검색 중엔 원래대로
              final newOnes = (!_isSearching && !_showFavorites && !_showRecent)
                  ? musicProvider.newSongs
                  : const <Song>[];
              final newIds = {for (final s in newOnes) s.id};
              final allListSongs = musicProvider.songs;
              final listSongs = newOnes.isEmpty
                  ? allListSongs
                  : allListSongs.where((s) => !newIds.contains(s.id)).toList();
              _newTopRows = newOnes.length; // 빠른 이동 위치 계산용
              final showIndexBar = listSongs.length >= 30 && !_isSearching;
              // 가수 정렬이면 곡이 적어도 가수별로 묶어서 보여줌
              final grouped = showIndexBar || (_byArtist && !_isSearching);
              if (grouped) _buildIndexEntries(listSongs);
              final available = showIndexBar
                  ? _indexEntries.where((e) => e.$2 == -1).map((e) => e.$1!).toSet()
                  : <String>{};
              // 막대가 있을 땐 묶음 순서(A-Z → ㄱ~ㅎ → #) + 머리글, 아니면 원래 목록 그대로
              final baseSongs = grouped ? _indexSongs : listSongs;
              final List<(String?, int)> baseEntries = grouped
                  ? _indexEntries
                  : [for (var k = 0; k < listSongs.length; k++) (null, k)];
              // 맨 위: '새로 들어온 곡' 머리글(-3) + 새 곡들 → 그 아래 원래 목록
              final viewSongs = newOnes.isEmpty ? baseSongs : [...newOnes, ...baseSongs];
              final List<(String?, int)> entries = newOnes.isEmpty
                  ? baseEntries
                  : [
                      ('새로 들어온 곡', -3),
                      for (var k = 0; k < newOnes.length; k++) (null, k),
                      for (final e in baseEntries) e.$2 >= 0 ? (e.$1, e.$2 + newOnes.length) : e,
                    ];
              final isDarkList = baseColor == Colors.white;
              return Stack(
              children: [
              RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () => musicProvider.loadSongs(),
                child: ListView.builder(
                  controller: _songListController,
                  // 인덱스 띠와 곡 줄(선택 배경 포함) 사이에 틈 두기
                  padding: const EdgeInsets.only(bottom: 8), // 막대는 오른쪽 끝 위에 겹쳐 떠요 (목록 폭 그대로)
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    if (entry.$2 == -3) {
                      return _buildNewHeader(newOnes.length, isDarkList); // 새로 들어온 곡 머리글
                    }
                    if (entry.$2 == -2) {
                      return _buildArtistHeader(entry.$1!, isDarkList); // 가수 이름 줄
                    }
                    if (entry.$1 != null) {
                      return _buildIndexHeader(entry.$1!, isDarkList);
                    }
                    final index = entry.$2;
                    final songs = viewSongs;
                    final song = songs[index];
                    final isSelected = _selectedSongIds.contains(song.id);
                    _songItemKeys.putIfAbsent(song.id, () => GlobalKey());
                    return TweenAnimationBuilder<double>(
                      key: _songItemKeys[song.id],
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset((1 - value) * 24, 0.0),
                          child: Transform.scale(
                            scale: 0.95 + (0.05 * value),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedSongIds.add(song.id);
                          });
                        },
                        onTap: _isSelectionMode
                            ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedSongIds.remove(song.id);
                              if (_selectedSongIds.isEmpty) {
                                _isSelectionMode = false;
                              }
                            } else {
                              _selectedSongIds.add(song.id);
                            }
                          });
                        }
                            : null,
                        child: Container(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : baseColor.withOpacity(0.38),
                                    size: 22,
                                  ),
                                ),
                              Expanded(
                                child: SongListTile(
                                  song: song,
                                  index: index,
                                  songList: songs,
                                  highlight: _isSearching ? _searchController.text : '',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (showIndexBar)
                Positioned(
                  right: 0,
                  top: 4,
                  bottom: 12,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _indexShow,
                    builder: (context, show, child) => IgnorePointer(
                      ignoring: !show,
                      child: AnimatedOpacity(
                        opacity: show ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: AnimatedSlide(
                          offset: show ? Offset.zero : const Offset(0.3, 0),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: child,
                        ),
                      ),
                    ),
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _currentGroup,
                      builder: (context, cur, _) => IndexBar(
                        available: available,
                        isDark: isDarkList,
                        onLetter: _jumpToGroup,
                        onActiveChanged: (l) {
                          _indexBubble.value = l;
                          _pokeIndexBar(); // 누르고 있는 동안은 안 사라지게
                        },
                        current: cur ?? (available.isNotEmpty ? kIndexGroups.firstWhere(available.contains) : null),
                      ),
                    ),
                  ),
                ),
              // 누르는 동안 가운데 큰 글자
              IgnorePointer(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _indexBubble,
                  builder: (context, letter, _) {
                    if (letter == null) return const SizedBox.shrink();
                    return Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kIndexBlue.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(letter,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: letter.length > 1 ? 28 : 40,
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
              ),
              ],
              );
              }),
            ),
          ],
        );
      },
    );
  }

  /// 손으로 밀 때: 이미 보이면 계속 보이게, 숨어 있으면 3줄쯤(250) 밀었을 때부터 나타나게
  void _scrollPokeIndexBar() {
    final px = _songListController.position.pixels;
    final now = DateTime.now();
    if (_indexShow.value) {
      _indexFrom = null;
      _indexMovedAt = now;
      _pokeIndexBar();
      return;
    }
    // 잠깐 멈췄다가 다시 밀면 처음부터 다시 셈
    if (_indexFrom == null || now.difference(_indexMovedAt).inMilliseconds > 800) _indexFrom = px;
    _indexMovedAt = now;
    if ((px - _indexFrom!).abs() >= 250) {
      _indexFrom = null;
      _pokeIndexBar();
    }
  }

  /// 초성 막대: 스크롤하는 동안 보이고, 멈추면 1.5초 뒤 사라짐 (막대를 누르고 있는 동안은 그대로)
  void _pokeIndexBar() {
    if (!_indexShow.value) _indexShow.value = true;
    final t = ++_indexHideToken;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && t == _indexHideToken && _indexBubble.value == null) _indexShow.value = false;
    });
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap, Color primaryColor,
      {IconData? icon, bool specialFont = false}) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(right: specialFont ? 0 : 20),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? baseColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘이 있으면 글자 앞에 작게 (예: 🎙 녹음)
            if (icon != null) ...[
              Icon(icon, size: 15, color: isSelected ? baseColor : baseColor.withOpacity(0.54)),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: specialFont
                  // 녹음 탭도 다른 탭과 같은 글꼴
                  ? TextStyle(
                      color: isSelected ? baseColor : baseColor.withOpacity(0.54),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    )
                  : TextStyle(
                      color: isSelected ? baseColor : baseColor.withOpacity(0.54),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView(MusicProvider musicProvider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 72, color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.permissionRequired,
                style: TextStyle(
                    color: baseColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.permissionMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: baseColor.withOpacity(0.7), fontSize: 14, height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => musicProvider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(AppLocalizations.of(context)!.allowPermission,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(MusicProvider musicProvider) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(musicProvider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: baseColor.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => musicProvider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySongsView() {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 72, color: baseColor.withOpacity(0.38)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noSongs,
              style: TextStyle(color: baseColor.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.addMusic,
              style: TextStyle(color: baseColor.withOpacity(0.54), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5);
    final l = AppLocalizations.of(context)!;
    final items = [
      {'icon': Icons.music_note, 'label': l.songs},
      {'icon': Icons.album, 'label': l.albums},
      {'icon': Icons.person, 'label': l.artists},
      {'icon': Icons.playlist_play, 'label': l.playlists},
      {'icon': Icons.folder, 'label': l.folders},
      {'icon': Icons.video_library, 'label': l.videos},
    ];
    return Container(
      color: bgColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = _currentTabIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    setState(() {
                      // "곡"을 누르면 즐겨찾기·최근·통화녹음에서 전체 곡 목록으로 바로 돌아오기
                      if (index == 0) {
                        _showFavorites = false;
                        _showRecent = false;
                        _showCalls = false;
                      }
                      _currentTabIndex = index;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isSelected
                            ? context.watch<ThemeProvider>().primaryColor // 지금 탭 = 포인트 색
                            : baseColor.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          color: isSelected ? baseColor : baseColor.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
class _AppBarCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color baseColor;
  const _AppBarCircleButton({
    required this.onTap,
    required this.icon,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withOpacity(0.07),
          border: Border.all(color: baseColor.withOpacity(0.08)),
        ),
        child: Icon(icon, color: baseColor, size: 13),
      ),
    );
  }
}

class _RoundedStar extends StatelessWidget {
  final bool filled;
  final Color color;
  final double size;
  const _RoundedStar({required this.filled, required this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundedStarPainter(filled: filled, color: color),
    );
  }
}

class _RoundedStarPainter extends CustomPainter {
  final bool filled;
  final Color color;
  _RoundedStarPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.58;
    final points = <Offset>[];
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? outerR : innerR;
      points.add(Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)));
    }
    const cornerFactor = 0.38;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final curr = points[i];
      final prev = points[(i - 1 + points.length) % points.length];
      final next = points[(i + 1) % points.length];
      final p1 = Offset.lerp(curr, prev, cornerFactor)!;
      final p2 = Offset.lerp(curr, next, cornerFactor)!;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundedStarPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.color != color;
}

class _DashboardCategory {
  final String title;
  final String subtitle;
  final String imageAsset;
  final StartScreenType type;
  final VoidCallback onTap;

  _DashboardCategory(this.title, this.subtitle, this.imageAsset, this.type, this.onTap);
}


// 홈 화면 로고 옆의 작은 이퀄라이저 막대 (은은하게 움직임)
/// 로고 "파란"이 숨쉬듯 은은하게 밝아졌다 연해졌다 (3.2초에 한 번)
class _LogoBreathe extends StatefulWidget {
  final Widget child;
  final Color? base; // 글자 색 (없으면 기본 파랑)
  final Color? glow; // 지나가는 빛 색 (없으면 기본 하늘색)
  const _LogoBreathe({required this.child, this.base, this.glow});

  @override
  State<_LogoBreathe> createState() => _LogoBreatheState();
}

class _LogoBreatheState extends State<_LogoBreathe> with SingleTickerProviderStateMixin {
  // 3.5초마다 빛이 쉬지 않고 계속 흘러감 (시안과 같게)
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final x = -0.5 + _c.value * 2.0; // 빛 위치: 왼쪽 밖 → 오른쪽 밖 (쉬지 않고)
        // 기본: 파랑 글자 + 하늘색 빛 / 포인트 색 바꾸면: 먹색 글자 + 포인트 색 빛
        final base = widget.base ?? const Color(0xFF2F7DE8);
        final glow = widget.glow ?? const Color(0xFFA9D3FF);
        final mid = widget.glow == null
            ? const Color(0xFF5FA6F2)
            : Color.lerp(base, glow, 0.55)!;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: const Alignment(-1, -0.4), // 시안처럼 살짝 비스듬히
            end: const Alignment(1, 0.4),
            // 가운데만 밝고 양옆으로 부드럽게 번지는 넓은 빛
            colors: [
              base,
              base,
              mid, // 번짐 시작
              glow, // 가장 밝은 곳
              mid, // 번짐 끝
              base,
              base,
            ],
            stops: [
              0,
              (x - 0.38).clamp(0.0, 1.0),
              (x - 0.16).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.16).clamp(0.0, 1.0),
              (x + 0.38).clamp(0.0, 1.0),
              1,
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class _LogoEqBars extends StatefulWidget {
  final Color color;
  const _LogoEqBars({required this.color});

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
                    color: widget.color,
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

/// 오늘의 카드 TIP 그림: 점선 네모
class _DashedBoxPainter extends CustomPainter {
  final Color color;
  _DashedBoxPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(9)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color;
}

/// 최근에 들었어요: 사진 없는 칸 (위 큰 카드와 같은 파스텔 색)
/// 카드 바탕 위에서 강조 색 글자가 잘 보이게: 다크는 너무 어두우면 밝게, 라이트는 너무 밝으면 진하게
Color _readable(Color c, bool isDark) {
  var out = c;
  for (var i = 0; i < 8; i++) {
    final l = out.computeLuminance();
    if (isDark ? l >= 0.22 : l <= 0.30) break;
    out = Color.lerp(out, isDark ? Colors.white : const Color(0xFF17140F), 0.18)!;
  }
  return out;
}

/// 최근에 들었어요 날짜 묶음 이름
String _recentGroup(DateTime t) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (days <= 0) return '오늘';
  if (days == 1) return '어제';
  if (days <= 3) return '3일 안';
  return '일주일 안';
}

/// 라디오: 들은 시간대 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
String _radioSlotImage(DateTime t) {
  final h = t.hour;
  final slot = h >= 5 && h < 11
      ? 'morning'
      : h >= 11 && h < 17
          ? 'day'
          : h >= 17 && h < 22
              ? 'evening'
              : 'night';
  return 'assets/radio_media_$slot.jpg';
}

/// 최근 카드 사진 (앱 안 사진)
Widget _recentAsset(String asset) {
  return Image.asset(
    asset,
    width: 72,
    height: 72,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    cacheWidth: 216,
  );
}

Widget _recentTile(bool isDarkMode, Color pastel, IconData icon) {
  return Container(
    width: 72,
    height: 72,
    color: isDarkMode ? const Color(0xFF3A3631) : pastel,
    child: Icon(
      icon,
      size: 26,
      color: isDarkMode
          ? const Color(0xFFF3EFE7).withOpacity(0.75)
          : const Color(0xFF17140F).withOpacity(0.55),
    ),
  );
}

/// 통통 튀는 큰 물음표: 두 번 톡톡 튀고 잠깐 쉬기를 반복
class _BounceQ extends StatefulWidget {
  final Color color;
  const _BounceQ({required this.color});

  @override
  State<_BounceQ> createState() => _BounceQState();
}

class _BounceQState extends State<_BounceQ> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 0~1 시간 → 위로 뜨는 높이(0~1)
  double _hop(double t) {
    if (t < 0.22) return math.sin(t / 0.22 * math.pi);              // 첫 번째 큰 톡
    if (t < 0.38) return 0.45 * math.sin((t - 0.22) / 0.16 * math.pi); // 두 번째 작은 톡
    return 0;                                                       // 쉬기
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final h = _hop(_c.value);
        // 바닥에 닿는 순간 살짝 납작하게
        final land = (h < 0.08 && _c.value < 0.4) ? 0.08 - h : 0.0;
        return Transform.translate(
          offset: Offset(0, -7 * h),
          child: Transform.scale(
            scaleX: 1 + land * 1.6,
            scaleY: 1 - land * 1.6,
            alignment: Alignment.bottomCenter,
            child: Text('?',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 19,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                )),
          ),
        );
      },
    );
  }
}

/// 강조 색상 이름 (영어 화면용)
const Map<String, String> _colorNameEn = {
  '파란소리': 'Paransori', '숲': 'Forest', '노을': 'Sunset', '라벤더': 'Lavender', '먹색': 'Ink',
  '벚꽃': 'Blossom', '바다': 'Ocean', '햇살': 'Sunlight', '와인': 'Wine', '밤하늘': 'Night sky',
};

/// 강조 색상 10가지를 한 바퀴로 (가운데는 카드 색 구멍)
class _ColorRingPainter extends CustomPainter {
  final Color hole;
  const _ColorRingPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [for (final c in ThemeProvider.pointColors) c.$2];
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: r);
    final sweep = 2 * math.pi / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * sweep, sweep + 0.01, true, Paint()..color = colors[i]);
    }
    canvas.drawCircle(center, r * 0.46, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(covariant _ColorRingPainter old) => old.hole != hole;
}

/// 색 고리: 카드가 나타나면 잠깐 있다가 스르륵 한 바퀴 돌고 멈춤
class _SpinRing extends StatefulWidget {
  final Color hole;
  const _SpinRing({required this.hole});

  @override
  State<_SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<_SpinRing> with SingleTickerProviderStateMixin {
  static bool _spun = false; // 앱 한 번 켤 때 한 번만 (음악 탭 갔다 와도 다시 안 돎)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 10000)); // 10초에 3바퀴 (천천히)

  @override
  void initState() {
    super.initState();
    if (_spun) return;
    _spun = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c.drive(CurveTween(curve: Curves.easeInOutSine)).drive(Tween(begin: 0.0, end: 3.0)),
      child: CustomPaint(painter: _ColorRingPainter(hole: widget.hole)),
    );
  }
}

// ───── 메인 홈 카드 왼쪽 동그라미 그림 ─────

/// 지금 방송 중: 색 고리 + 빨간 점에서 전파가 퍼짐
class _LiveBadge extends StatefulWidget {
  final Color hole;
  const _LiveBadge({required this.hole});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(painter: _LivePainter(hole: widget.hole, t: _c.value)),
    );
  }
}

class _LivePainter extends CustomPainter {
  final Color hole;
  final double t;
  const _LivePainter({required this.hole, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const SweepGradient(colors: [
            Color(0xFFE07A4F),
            Color(0xFFD46A8C),
            Color(0xFF8A6FD1),
            Color(0xFF3F51A3),
            Color(0xFF1F9AA0),
            Color(0xFFE07A4F),
          ]).createShader(rect));
    canvas.drawCircle(c, r - 4, Paint()..color = hole);
    const red = Color(0xFFFF6B5E);
    for (final d in [0.0, 0.5]) {
      final k = (t + d) % 1.0;
      canvas.drawCircle(
          c,
          4 + k * 9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = red.withOpacity((1 - k) * 0.8));
    }
    canvas.drawCircle(c, 4, Paint()..color = red);
  }

  @override
  bool shouldRepaint(covariant _LivePainter old) => old.t != t || old.hole != hole;
}

/// 오늘의 팁: 네 가지 색 고리 + 작은 네모 넷
class _TipBadge extends StatelessWidget {
  final Color hole;
  const _TipBadge({required this.hole});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _TipPainter(hole: hole));
}

class _TipPainter extends CustomPainter {
  final Color hole;
  const _TipPainter({required this.hole});

  static const _colors = [Color(0xFF3E8E6A), Color(0xFFC4962C), Color(0xFFE07A4F), Color(0xFF2589E8)];

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    const sweep = math.pi / 2;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * sweep, sweep + 0.01, true, Paint()..color = _colors[i]);
    }
    canvas.drawCircle(c, r - 4, Paint()..color = hole);
    const s = 7.0, g = 2.0;
    for (var i = 0; i < 4; i++) {
      final x = c.dx - s - g / 2 + (i % 2) * (s + g);
      final y = c.dy - s - g / 2 + (i ~/ 2) * (s + g);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, s, s), const Radius.circular(2)),
          Paint()..color = _colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _TipPainter old) => old.hole != hole;
}
