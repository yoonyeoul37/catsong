import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../providers/radio_provider.dart';
import 'podcast.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_holder.dart';
import '../widgets/sleep_timer_sheet.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart' show AudioPlayer;
import 'package:audio_service/audio_service.dart' show PlaybackState;
import '../main.dart' show globalAudioHandler;
import '../providers/player_provider.dart' show SimpleAudioHandler, PlayerProvider;
import '../utils/point_color.dart';
import '../utils/greeting_images.dart';
import '../widgets/farewell_title.dart';
import '../widgets/exit_confirm_dialog.dart';
import '../widgets/more_menu_sheet.dart';
import '../widgets/paran_dialog.dart' show ParanCloseX;

// 색: 파란소리 공통 (라이트 베이지·흰 카드·먹색 / 다크 갈색·진한 카드·크림색)
const _ink = Color(0xFF17140F);
const _cream = Color(0xFFF4EFE5);
Color _card(bool dark) => dark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);
Color _bg(bool dark) => dark ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);
Color _text(bool dark) => dark ? const Color(0xFFF3EFE7) : _ink;
Color _sub(bool dark) => dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
Color _line(bool dark) => dark ? const Color(0x14FFFFFF) : const Color(0x123C2D14);

void _buzz() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

/// 상단·하단 시스템 바: 화면 바탕과 같은 색 + 아이콘 색 (라이트는 어두운 아이콘, 다크는 밝은 아이콘)
SystemUiOverlayStyle _bars(bool dark) => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: _bg(dark),
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

/// 팟캐스트 그림 (못 받으면 이름 첫 글자)
class PodcastArt extends StatelessWidget {
  final String url;
  final String title;
  final double size;
  final double radius;
  const PodcastArt({super.key, required this.url, required this.title, required this.size, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final fallback = Container(
      width: size,
      height: size,
      color: dark ? const Color(0xFF45413B) : const Color(0xFFE2D9C8),
      alignment: Alignment.center,
      child: Text(
        title.isEmpty ? '·' : title.characters.first,
        style: TextStyle(color: _sub(dark), fontSize: size * 0.36, fontWeight: FontWeight.w700),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: (size * 3).round(),
              fadeInDuration: const Duration(milliseconds: 150), // 그림이 오래 연하게 보이지 않게
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }
}

// 다시 듣기 15초 · 앞으로 30초 아이콘
class _SkipIcon extends StatelessWidget {
  final bool back;
  final Color color;
  final double size;
  const _SkipIcon({required this.back, required this.color, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.flip(flipX: !back, child: Icon(Icons.replay_rounded, color: color, size: size)),
          Padding(
            padding: EdgeInsets.only(top: size * 0.1),
            child: Text(back ? '15' : '30',
                textScaler: TextScaler.noScaling,
                style: TextStyle(color: color, fontSize: size * 0.3, fontWeight: FontWeight.w800, height: 1)),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 라디오 안 '팟캐스트' 탭 ─────────────────────────

class PodcastTab extends StatefulWidget {
  final String country; // 'kr' · 'US' 등 (나라별 순위)
  const PodcastTab({super.key, required this.country});

  @override
  State<PodcastTab> createState() => _PodcastTabState();
}

class _PodcastTabState extends State<PodcastTab> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false; // 오른쪽 위 돋보기를 눌렀을 때만 검색칸
  String _query = '';
  String? _topic; // 고른 주제 타일
  bool _infoOpen = false; // '팟캐스트란? ⓘ' 설명 펼침
  bool _showAll = false; // 순위 10위까지 → 50위까지
  bool _latestLoading = false; // 1위 카드 '최신 회차' 누른 뒤 불러오는 중
  final String _tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이 화면에서 한 번만
  Future<List<PodcastShow>>? _chart;
  Future<List<PodcastShow>>? _results;

  // 주제 타일: (한국어, 영어, 한국어 설명, 영어 설명, 한국어 검색어, 영어 검색어, 라이트 색, 다크 색)
  static const _topics = [
    ('라디오 다시듣기', 'Radio shows', '컬투쇼 · 음악캠프', 'Shows on demand', '라디오', 'radio', Color(0xFFE4DCCD), Color(0xFF3A362F)),
    ('뉴스', 'News', '매일 아침 소식', 'Daily briefings', '뉴스', 'news', Color(0xFFDDE2E6), Color(0xFF30353A)),
    ('책', 'Books', '읽어주는 이야기', 'Stories read aloud', '오디오북', 'audiobook', Color(0xFFE6DFD3), Color(0xFF3A3530)),
    ('영어 공부', 'Learn English', '하루 6분', 'A few minutes a day', '영어', 'learn english', Color(0xFFDCE3DA), Color(0xFF2F3830)),
    ('웃음', 'Comedy', '가볍게 듣기', 'Easy listening', '코미디', 'comedy', Color(0xFFEADBD3), Color(0xFF3B302C)),
    ('잠들기 전', 'Sleep', '조용한 이야기', 'Calm stories', '수면', 'sleep', Color(0xFFDCDBE6), Color(0xFF302F3A)),
  ];

  String get _cc => widget.country.toLowerCase();

  @override
  void initState() {
    super.initState();
    _loadChart();
    PodcastPlayer.instance.checkNewOnce(); // 구독한 팟캐스트 새 회차
  }

  void _loadChart() {
    _chart = PodcastApi.top(_cc).catchError((_) => PodcastApi.top('us'));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    q = q.trim();
    setState(() {
      _query = q;
      _topic = null;
      _results = q.isEmpty ? null : PodcastApi.search(q, _cc);
    });
  }

  void _toggleSearch() {
    _buzz();
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
    } else {
      _search.clear();
      FocusScope.of(context).unfocus();
      _runSearch('');
    }
  }

  /// 주제 타일 누르기: 그 주제로 검색
  void _pickTopic(int i) {
    _buzz();
    final t = _topics[i];
    _search.clear();
    FocusScope.of(context).unfocus();
    _runSearch(podText(t.$5, t.$6));
    setState(() => _topic = podText(t.$1, t.$2));
  }

  /// 주제·검색 결과에서 순위로 돌아가기
  void _backToChart() {
    _buzz();
    _search.clear();
    FocusScope.of(context).unfocus();
    setState(() => _searchOpen = false);
    _runSearch('');
  }

  /// 1위 카드 '최신 회차': 회차 목록을 받아 맨 위 회차 바로 재생
  Future<void> _playLatest(PodcastShow s) async {
    _buzz();
    setState(() => _latestLoading = true);
    try {
      final full = await PodcastApi.withFeed(s, _cc);
      final eps = await PodcastApi.episodes(full);
      final info = PodcastApi.showInfo(full.id)?.copyWith(feedUrl: full.feedUrl) ?? full;
      if (eps.isNotEmpty) await PodcastPlayer.instance.play(info, eps.first);
    } catch (_) {}
    if (mounted) setState(() => _latestLoading = false);
  }

  void _openShow(PodcastShow s) {
    _buzz();
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PodcastShowScreen(show: s, country: _cc),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child), // 다른 화면과 같은 부드러운 페이드
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final pod = context.watch<PodcastPlayer>();
    final cont = pod.lastEpisode != null && pod.lastShow != null && !pod.isDone(pod.lastEpisode!.guid) && !pod.active
        ? (pod.lastShow!, pod.lastEpisode!)
        : null;
    final searching = _query.isNotEmpty;

    return FutureBuilder<List<PodcastShow>>(
      future: _results ?? _chart,
      builder: (context, snap) {
        final list = snap.data ?? const <PodcastShow>[];
        final waiting = snap.connectionState != ConnectionState.done;
        final failed = !waiting && (snap.hasError || list.isEmpty);
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(24, 12, 24, 90 + MediaQuery.of(context).padding.bottom),
          children: [
            // 검색칸: 돋보기를 눌렀을 때만
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _searchOpen
                  ? Padding(padding: const EdgeInsets.only(bottom: 16), child: _searchBox(dark))
                  : const SizedBox(width: double.infinity),
            ),
            if (cont != null && !searching) ...[
              _continueCard(cont.$1, cont.$2, pod, dark),
              const SizedBox(height: 22),
            ],
            if (pod.subs.isNotEmpty && !searching) ...[
              _subsRow(pod, dark),
              const SizedBox(height: 22),
            ],
            // 제목줄: 작은 영문 + 큰 제목 / 오른쪽 돋보기
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        searching ? podText('검색', 'SEARCH') : '${_cc.toUpperCase()} · TOP 50',
                        style: TextStyle(color: _sub(dark), fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _topic ??
                            (searching ? podFmt('\'{q}\' 검색 결과', 'Results for "{q}"', {'q': _query}) : podText('인기 팟캐스트', 'Top podcasts')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _text(dark), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      ),
                    ],
                  ),
                ),
                if (searching)
                  _roundButton(Icons.close_rounded, dark, _backToChart)
                else
                  _roundButton(_searchOpen ? Icons.close_rounded : Icons.search_rounded, dark, _toggleSearch),
              ],
            ),
            const SizedBox(height: 14),
            if (waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (failed)
              _emptyBox(
                  snap.hasError
                      ? podText('불러오지 못했어요. 인터넷 연결을 확인해 주세요.', "Couldn't load. Please check your connection.")
                      : podText('찾는 팟캐스트가 없어요.', 'No podcasts found.'),
                  dark,
                  retry: snap.hasError
                      ? () => setState(() {
                            if (_query.isEmpty) {
                              _loadChart();
                            } else {
                              _results = PodcastApi.search(_query, _cc);
                            }
                          })
                      : null)
            else if (searching)
              ..._listCard([for (final s in list) (s, null)], dark)
            else ...[
              // 1위: 먹색 큰 카드
              _topCard(list.first, dark),
              const SizedBox(height: 12),
              // 2위부터: 10위까지 (더 보기 → 50위까지)
              ..._listCard([
                for (var i = 1; i < list.length && (_showAll || i < 10); i++) (list[i], i + 1),
              ], dark),
              if (!_showAll && list.length > 10)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _buzz();
                      setState(() => _showAll = true);
                    },
                    child: Text(podFmt('{n}위까지 보기', 'Show top {n}', {'n': list.length}),
                        style: TextStyle(color: _sub(dark), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              const SizedBox(height: 18),
              // 주제로 찾기 + 팟캐스트란? ⓘ
              Row(
                children: [
                  Expanded(
                    child: Text(podText('주제로 찾기', 'Browse by topic'),
                        style: TextStyle(color: _text(dark), fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _buzz();
                      setState(() => _infoOpen = !_infoOpen);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(podText('팟캐스트란?', 'What is a podcast?'),
                              style: TextStyle(color: _sub(dark), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(_infoOpen ? Icons.info_rounded : Icons.info_outline_rounded, size: 15, color: _sub(dark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _infoOpen
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                            podText('뉴스부터 재미있는 이야기까지, 미리 녹음된 방송을 원하는 시간에 골라 들을 수 있어요. 듣고 싶은 순간, 편하게 즐겨보세요.',
                                'From news to fun stories, pick pre-recorded shows and listen whenever you like. Enjoy them at your own pace.'),
                            style: TextStyle(color: _sub(dark), fontSize: 12.5, height: 1.55)),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 10),
              _topicGrid(dark),
            ],
          ],
        );
      },
    );
  }

  // '구독 중': 동그란 모서리 그림이 옆으로 줄 서고, 새 회차가 있으면 빨간 점
  Widget _subsRow(PodcastPlayer pod, bool dark) {
    final list = pod.subs.values.toList().reversed.toList(); // 최근에 구독한 것부터
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(podText('구독 중', 'Subscribed'),
                style: TextStyle(color: _text(dark), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text('${list.length}', style: TextStyle(color: _sub(dark), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = list[i];
              final isNew = pod.newOnes.contains(s.id);
              return GestureDetector(
                onTap: () => _openShow(s),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PodcastArt(url: s.art, title: s.title, size: 72, radius: 14),
                          if (isNew)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD84A3A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _bg(dark), width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: isNew ? _text(dark) : _sub(dark),
                              fontSize: 11.5,
                              fontWeight: isNew ? FontWeight.w700 : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _roundButton(IconData icon, bool dark, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque, // 배경이 없어도 같은 크기로 눌리게
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 22, color: _text(dark)),
        ),
      );

  Widget _searchBox(bool dark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 20, color: _sub(dark)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              style: TextStyle(color: _text(dark), fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: podText('팟캐스트 검색 (예: 컬투쇼)', 'Search podcasts'),
                hintStyle: TextStyle(color: _sub(dark), fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _emptyBox(String msg, bool dark, {VoidCallback? retry}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Text(msg, textAlign: TextAlign.center, style: TextStyle(color: _sub(dark), fontSize: 14)),
            if (retry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: retry, child: Text(podText('다시 시도', 'Retry'))),
            ],
          ],
        ),
      );

  // 이어 듣기: 흰 카드 (1위 먹색 카드와 겹치지 않게 밝게)
  Widget _continueCard(PodcastShow s, PodcastEpisode e, PodcastPlayer pod, bool dark) {
    final ms = pod.savedMs(e.guid);
    final total = e.durationSec * 1000;
    final ratio = total > 0 ? (ms / total).clamp(0.0, 1.0).toDouble() : 0.0;
    final left = total > 0 ? ((total - ms) / 1000).round() : 0;
    return Material(
      color: _card(dark),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _buzz();
          PodcastPlayer.instance.play(s, e);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PodcastArt(url: e.art.isNotEmpty ? e.art : s.art, title: s.title, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(podText('이어 듣기', 'CONTINUE'),
                        style: TextStyle(color: _sub(dark), fontSize: 10.5, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _text(dark), fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 3,
                              backgroundColor: _text(dark).withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation(_text(dark)),
                            ),
                          ),
                        ),
                        if (left > 0) ...[
                          const SizedBox(width: 8),
                          Text(podFmt('{t} 남음', '{t} left', {'t': podDurText(left)}),
                              style: TextStyle(color: _sub(dark), fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: dark ? const Color(0xFFF3EFE7) : _ink, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: dark ? const Color(0xFF24221F) : _cream, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1위 큰 카드 (먹색, 다크는 크림색)
  Widget _topCard(PodcastShow s, bool dark) {
    final bg = dark ? const Color(0xFFF3EFE7) : _ink;
    final fg = dark ? const Color(0xFF24221F) : _cream;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openShow(s),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PodcastArt(url: s.art, title: s.title, size: 86, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NO. 1',
                        style: TextStyle(color: fg.withOpacity(0.55), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(s.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
                    const SizedBox(height: 2),
                    Text([s.author, s.genre].where((x) => x.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11.5)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _latestLoading ? null : () => _playLatest(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _latestLoading
                                ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: bg))
                                : Icon(Icons.play_arrow_rounded, size: 16, color: bg),
                            const SizedBox(width: 4),
                            Text(podText('최신 회차', 'Latest episode'),
                                style: TextStyle(color: bg, fontSize: 12, fontWeight: FontWeight.w700)),
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
      ),
    );
  }

  // 흰 카드 하나에 줄들 (순위 숫자는 1~3위만 진하게)
  // (줄마다 따로 그려서 화면에 들어올 때 나타나기 · 모양은 예전과 같은 흰 카드 하나)
  List<Widget> _listCard(List<(PodcastShow, int?)> rows, bool dark) => [
        for (var i = 0; i < rows.length; i++)
          _podPiece(
            dark,
            first: i == 0,
            last: i == rows.length - 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i > 0) Divider(height: 1, thickness: 0.6, color: _line(dark), indent: rows[i].$2 != null ? 90 : 62),
                _PodAppear(id: '$_tok:$_query:${rows[i].$1.id}', index: i, child: _showRow(rows[i].$1, rows[i].$2, dark)),
              ],
            ),
          ),
      ];

  Widget _showRow(PodcastShow s, int? rank, bool dark) {
    return InkWell(
      onTap: () => _openShow(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 22,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rank <= 3 ? _text(dark) : _sub(dark).withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ),
              const SizedBox(width: 8),
            ],
            PodcastArt(url: s.art, title: s.title, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _text(dark), fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text([s.author, s.genre].where((x) => x.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _sub(dark), fontSize: 11.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _sub(dark).withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  // 주제로 찾기: 2열 연한 색 타일
  Widget _topicGrid(bool dark) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _topics.length; i++)
            GestureDetector(
              onTap: () => _pickTopic(i),
              child: Container(
                width: w,
                height: 66,
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: dark ? _topics[i].$8 : _topics[i].$7,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(podText(_topics[i].$1, _topics[i].$2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _text(dark), fontSize: 13.5, fontWeight: FontWeight.w600)),
                    Text(podText(_topics[i].$3, _topics[i].$4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _sub(dark), fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ───────────────────────── 팟캐스트 하나: 회차 목록 ─────────────────────────

class PodcastShowScreen extends StatefulWidget {
  final PodcastShow show;
  final String country;
  const PodcastShowScreen({super.key, required this.show, required this.country});

  @override
  State<PodcastShowScreen> createState() => _PodcastShowScreenState();
}

class _PodcastShowScreenState extends State<PodcastShowScreen> {
  late PodcastShow _show = widget.show;
  late Future<List<PodcastEpisode>> _eps = _load();
  bool _descOpen = false;
  String? _latestGuid; // 하트 누를 때: 지금 회차까지는 본 걸로

  List<PodcastEpisode>? _fresh; // 저장된 목록을 먼저 보여 준 뒤 뒤에서 새로 받은 목록
  final String _tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이 화면에서 한 번만

  Future<List<PodcastEpisode>> _load() async {
    _show = await PodcastApi.withFeed(_show, widget.country);
    // 한 번 연 팟캐스트: 폰에 저장된 목록을 바로 보여 주고, 새 회차는 뒤에서 조용히 확인
    final saved = await PodcastApi.savedEpisodes(_show);
    if (saved != null) {
      _useInfo(saved);
      _refresh();
      return saved;
    }
    final eps = await PodcastApi.episodes(_show);
    _useInfo(eps);
    return eps;
  }

  void _useInfo(List<PodcastEpisode> eps) {
    final info = PodcastApi.showInfo(_show.id);
    if (info != null && mounted) setState(() => _show = info.copyWith(feedUrl: _show.feedUrl));
    _latestGuid = eps.isNotEmpty ? eps.first.guid : null;
    PodcastPlayer.instance.markSeen(_show, eps);
  }

  Future<void> _refresh() async {
    try {
      final eps = await PodcastApi.episodes(_show, refresh: true);
      if (!mounted) return;
      setState(() => _fresh = eps);
      _useInfo(eps);
    } catch (_) {} // 인터넷이 안 되면 저장된 목록 그대로
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final pod = context.watch<PodcastPlayer>();
    final radioOn = context.watch<RadioProvider>().currentStation != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _bars(dark),
      child: Scaffold(
      backgroundColor: _bg(dark),
      appBar: AppBar(
        backgroundColor: _bg(dark), // 목록이 위로 올라가도 상단 아이콘과 겹치지 않게
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: _bars(dark),
        leading: IconButton(
          onPressed: () {
            _buzz();
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: _text(dark), size: 20),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _buzz();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: Icon(Icons.home_rounded, color: _text(dark), size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false, // 목록이 아래 내비게이션 바 밑으로 들어가지 않게
        child: FutureBuilder<List<PodcastEpisode>>(
        future: _eps,
        builder: (context, snap) {
          final eps = _fresh ?? snap.data ?? const <PodcastEpisode>[];
          return ListView(
            padding: EdgeInsets.fromLTRB(24, 4, 24, 90 + MediaQuery.of(context).padding.bottom),
            children: [
              // 머리: 그림 + 이름 + 만든 곳 + 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PodcastArt(url: _show.art, title: _show.title, size: 108, radius: 14),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_show.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _text(dark), fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
                        const SizedBox(height: 4),
                        Text([_show.author, _show.genre].where((x) => x.isNotEmpty).join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _sub(dark), fontSize: 12.5)),
                        if (eps.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(podFmt('회차 {n}개', '{n} episodes', {'n': eps.length}),
                              style: TextStyle(color: _sub(dark), fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (eps.isNotEmpty)
                Row(
                  children: [
                Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _buzz();
                      PodcastPlayer.instance.play(_show, eps.first);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(podText('최신 회차 듣기', 'Play latest'),
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark ? const Color(0xFFF3EFE7) : _ink,
                      foregroundColor: dark ? const Color(0xFF24221F) : _cream,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                ),
                    const SizedBox(width: 10),
                    _heartButton(pod, dark), // 구독
                  ],
                ),
              if (eps.isNotEmpty && eps.first.desc.isNotEmpty) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _descOpen = !_descOpen),
                  child: Text(eps.first.desc,
                      maxLines: _descOpen ? 12 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _sub(dark), fontSize: 12.5, height: 1.5)),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                child: Text(podText('회차', 'Episodes'),
                    style: TextStyle(color: _sub(dark), fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
              if (_fresh == null && snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if ((_fresh == null && snap.hasError) || eps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Text(podText('회차를 불러오지 못했어요.', "Couldn't load episodes."),
                          style: TextStyle(color: _sub(dark), fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => setState(() {
                                _fresh = null;
                                _eps = _load();
                              }),
                          child: Text(podText('다시 시도', 'Retry'))),
                    ],
                  ),
                )
              else
                // 줄마다 따로 그려서 스크롤해 들어올 때 나타나기 (모양은 예전과 같은 흰 카드 하나)
                for (var i = 0; i < eps.length; i++)
                  _podPiece(
                    dark,
                    first: i == 0,
                    last: i == eps.length - 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0) Divider(height: 1, thickness: 0.6, color: _line(dark), indent: 46),
                        _PodAppear(id: '$_tok:${eps[i].guid}', index: i, child: _episodeRow(eps[i], pod, dark)),
                      ],
                    ),
                  ),
            ],
          );
        },
      )),
      bottomNavigationBar: !radioOn && pod.active
          ? Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
              child: const PodcastMiniPlayer(),
            )
          : null,
    ));
  }

  // 구독 하트: 최신 회차 듣기 버튼과 같은 높이의 둥근 네모
  Widget _heartButton(PodcastPlayer pod, bool dark) {
    final on = pod.isSub(_show.id);
    return _PodHeart(
      isFav: on,
      offColor: _text(dark).withOpacity(0.7),
      onTap: () {
        _buzz();
        pod.toggleSub(_show, latestGuid: _latestGuid);
      },
    );
  }

  Widget _episodeRow(PodcastEpisode e, PodcastPlayer pod, bool dark) {
    final now = pod.active && pod.episode?.guid == e.guid;
    final playing = now && pod.isPlaying;
    final point = Theme.of(context).colorScheme.primary;
    final ms = pod.savedMs(e.guid);
    final done = pod.isDone(e.guid);
    final total = e.durationSec * 1000;
    String state = '';
    if (done) {
      state = podText('다 들음', 'Played');
    } else if (ms >= 60000 && total > 0) { // 1분 넘게 들은 회차만 '남음'
      state = podFmt('{t} 남음', '{t} left', {'t': podDurText(((total - ms) / 1000).round())});
    }
    final meta = [podDateText(e.published), podDurText(e.durationSec), state].where((x) => x.isNotEmpty).join(' · ');
    return InkWell(
      onTap: () {
        _buzz();
        if (now) {
          pod.toggle();
        } else {
          pod.play(_show, e);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: now ? point : Colors.transparent,
                border: now ? null : Border.all(color: _sub(dark).withOpacity(0.45)),
              ),
              child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 18, color: now ? Colors.white : _text(dark)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done ? _sub(dark) : (now ? point : _text(dark)),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      )),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub(dark), fontSize: 11.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 미니플레이어 (라디오 미니플레이어와 같은 먹색 띠) ─────────────────────────

class PodcastMiniPlayer extends StatelessWidget {
  const PodcastMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
      valueListenable: PodcastPlayer.instance.tick, builder: (ctx, _, __) => _build(ctx));

  Widget _build(BuildContext context) {
    final pod = context.watch<PodcastPlayer>();
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final e = pod.episode, s = pod.show;
    if (!pod.active || e == null || s == null) return const SizedBox.shrink();
    final pos = pod.position, dur = pod.duration;
    final ratio = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0).toDouble() : 0.0;
    const fg = _cream;
    return GestureDetector(
      onTap: () => openPodcastPlayer(context),
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 300) pod.close();
      },
      child: Stack(
        children: [
          Container(
            height: 72,
            color: dark ? const Color(0xFF3A3631) : _ink,
            child: Column(
              children: [
                // 위 가는 줄 = 들은 만큼
                SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: fg.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(fg.withOpacity(0.7)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 22, 0),
                    child: Row(
                      children: [
                        PodcastArt(url: e.art.isNotEmpty ? e.art : s.art, title: s.title, size: 44, radius: 8),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 회차 이름이 길면 좌우로 흐르게
                              _PodMarquee(e.title, const TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  // 수면 타이머가 켜져 있으면: 작은 달 + 남은 분
                                  if (pod.isSleepTimerActive && pod.sleepRemaining != null) ...[
                                    Icon(Icons.bedtime_outlined, size: 11, color: fg.withOpacity(0.75)),
                                    const SizedBox(width: 3),
                                    Text(tr.durM(pod.sleepRemaining!.inMinutes + 1),
                                        style: TextStyle(color: fg.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w600)),
                                    Text('  ·  ', style: TextStyle(color: fg.withOpacity(0.4), fontSize: 11)),
                                  ],
                                  Expanded(
                                    child: Text(
                                        dur.inSeconds > 0 ? '${s.title} · \u2066${podClock(pos)} / ${podClock(dur)}\u2069' : s.title, // 시간은 늘 왼→오
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          textDirection: TextDirection.ltr, // ⟲ ▶ ⟳ 순서는 어느 언어나 같게
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                _buzz();
                                pod.seekBy(-15);
                              },
                              icon: _SkipIcon(back: true, color: fg.withOpacity(0.75), size: 24),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                            GestureDetector(
                              onTap: () {
                                _buzz();
                                pod.toggle();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: fg, shape: BoxShape.circle),
                                child: pod.isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                                      )
                                    : Icon(pod.isPlaying ? Icons.pause : Icons.play_arrow, color: _ink, size: 22),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _buzz();
                                pod.seekBy(30);
                              },
                              icon: _SkipIcon(back: false, color: fg.withOpacity(0.75), size: 24),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // × 닫기: 오른쪽 위 작게 (라디오 미니플레이어와 같게)
          Positioned(
            top: 4,
            right: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _buzz();
                pod.close();
              },
              child: SizedBox(
                width: 26,
                height: 26,
                child: Icon(Icons.close_rounded, size: 17, color: fg.withOpacity(0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 재생 화면 (미니플레이어를 누르면 아래에서 올라옴) ─────────────────────────

void openPodcastPlayer(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const PodcastPlayerScreen(),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

class PodcastPlayerScreen extends StatefulWidget {
  const PodcastPlayerScreen({super.key});

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  double? _drag; // 막대를 끄는 동안의 자리 (0~1)

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
      valueListenable: PodcastPlayer.instance.tick, builder: (ctx, _, __) => _build(ctx));

  Widget _build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final pod = context.watch<PodcastPlayer>();
    final e = pod.episode ?? pod.lastEpisode, s = pod.show ?? pod.lastShow;
    if (e == null || s == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return Scaffold(backgroundColor: _bg(dark));
    }
    final pos = pod.position, dur = pod.duration;
    final total = dur.inMilliseconds;
    final double v = _drag ?? (total > 0 ? (pos.inMilliseconds / total).clamp(0.0, 1.0).toDouble() : 0.0);
    final shown = _drag != null ? Duration(milliseconds: (total * _drag!).round()) : pos;
    final point = pointColorOf(context); // 재생 막대: 앱 포인트 색 (라디오와 같게)
    final w = MediaQuery.sizeOf(context).width;
    final double art = (w - 96).clamp(160.0, 320.0).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _bars(dark),
      child: Scaffold(
      backgroundColor: _bg(dark),
      body: SafeArea(
        child: Column(
          children: [
            // 위 버튼: 라디오 재생 화면과 같은 동그란 버튼 · 같은 자리
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PodFloat(
                    onTap: () {
                      _buzz();
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.expand_more, color: _baseOf(dark), size: 13),
                  ),
                  Row(
                    children: [
                      // 구독 하트 (회차 목록 화면 하트와 같음 · 켤 때 통통 + 작은 하트)
                      _PodFloat(
                        child: _PodHeart(
                          isFav: pod.isSub(s.id),
                          offColor: _baseOf(dark).withOpacity(0.6),
                          iconSize: 13,
                          box: 29,
                          rise: 44,
                          miniSize: 9,
                          onTap: () {
                            _buzz();
                            pod.toggleSub(s);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PodFloat(
                        onTap: () {
                          _buzz();
                          context.read<ThemeProvider>().setDarkMode(!dark);
                        },
                        child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            color: _baseOf(dark), size: 13),
                      ),
                      const SizedBox(width: 10),
                      _PodFloat(
                        onTap: () {
                          _buzz();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: Icon(Icons.home_rounded, color: _baseOf(dark), size: 13),
                      ),
                      const SizedBox(width: 10),
                      _PodFloat(
                        onTap: () {
                          _buzz();
                          showMoreMenuSheet(context);
                        },
                        child: Icon(Icons.more_vert, color: _baseOf(dark), size: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            PodcastArt(url: e.art.isNotEmpty ? e.art : s.art, title: s.title, size: art, radius: 10),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(e.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _text(dark), fontSize: 18, fontWeight: FontWeight.w700, height: 1.35)),
                  const SizedBox(height: 6),
                  Text(s.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _sub(dark), fontSize: 13.5)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: point,
                  inactiveTrackColor: _text(dark).withOpacity(0.12),
                  thumbColor: point,
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Slider(
                    value: v,
                    onChanged: total > 0 ? (x) => setState(() => _drag = x) : null,
                    onChangeEnd: total > 0
                        ? (x) {
                            pod.seekTo(Duration(milliseconds: (total * x).round()));
                            setState(() => _drag = null);
                          }
                        : null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Text(podClock(shown), style: TextStyle(color: _sub(dark), fontSize: 12)),
                  const Spacer(),
                  Text(total > 0 ? '-${podClock(dur > shown ? dur - shown : Duration.zero)}' : '',
                      textDirection: TextDirection.ltr, // 아랍어에서도 -1:16:56
                      style: TextStyle(color: _sub(dark), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    _buzz();
                    pod.seekBy(-15);
                  },
                  icon: _SkipIcon(back: true, color: _text(dark), size: 34),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    _buzz();
                    pod.toggle();
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: dark ? const Color(0xFFF3EFE7) : _ink, shape: BoxShape.circle),
                    child: pod.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(22),
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: dark ? _ink : _cream),
                          )
                        : Icon(pod.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: dark ? const Color(0xFF24221F) : _cream, size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () {
                    _buzz();
                    pod.seekBy(30);
                  },
                  icon: _SkipIcon(back: false, color: _text(dark), size: 34),
                ),
              ],
            ),
            // 수면 타이머 남은 시간 (라디오와 같은 줄 · 누르면 끄기)
            const SizedBox(height: 14),
            SizedBox(
              height: 20,
              child: ValueListenableBuilder<Duration?>(
                valueListenable: pod.sleepTick,
                builder: (_, d, __) => d == null ? const SizedBox.shrink() : _PodSleepBadge(remaining: d),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
      // 아래 줄: 라디오 재생 화면 아래 줄과 같은 모양 (얇은 선 위 · 아이콘 + 글자 · 세로줄 · 종료)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _bg(dark),
          border: Border(
              top: BorderSide(color: dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 재생 속도 (누를 때마다 1 → 1.25 → 1.5 → 2 → 0.8)
                      _PodBarItem(
                        dark: dark,
                        top: Text('${_speedText(pod.speed)}×',
                            textDirection: TextDirection.ltr, // 아랍어에서도 1×
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                                color: pod.speed != 1.0 ? _strongOf(dark) : _mutedOf(dark),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 22 / 15)),
                        label: podText('속도', 'Speed'),
                        on: pod.speed != 1.0,
                        onTap: () {
                          _buzz();
                          pod.nextSpeed();
                        },
                      ),
                      // 수면 타이머 (켜지면 남은 분)
                      _PodBarItem(
                        dark: dark,
                        icon: Icons.bedtime_outlined,
                        label: pod.isSleepTimerActive && pod.sleepRemaining != null
                            ? tr.durM(pod.sleepRemaining!.inMinutes + 1)
                            : AppLocalizations.of(context)!.radioSleep,
                        on: pod.isSleepTimerActive,
                        onTap: () {
                          _buzz();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            barrierColor: Colors.black.withOpacity(0.7),
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => const SleepTimerSheet(podcast: true),
                          );
                        },
                      ),
                      // 회차: 지금 듣는 팟캐스트의 회차 목록 (라디오 '편성표' 자리)
                      _PodBarItem(
                        dark: dark,
                        icon: Icons.format_list_bulleted,
                        label: podText('회차', 'Episodes'),
                        on: false,
                        onTap: () {
                          _buzz();
                          _openPodShow(context, s);
                        },
                      ),
                      // 구독: 구독한 팟캐스트 목록 (라디오 '즐겨찾기' 자리)
                      _PodBarItem(
                        dark: dark,
                        icon: CupertinoIcons.heart,
                        label: podText('구독', 'Subscribed'),
                        on: false,
                        onTap: () {
                          _buzz();
                          final tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이번에 연 창에서 한 번만
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => _PodSubsSheet(tok: tok),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: _baseOf(dark).withOpacity(0.12),
                ),
                // 종료: 확인창 → 작별 인사 → 종료 (라디오와 같음)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (await showExitConfirm(context) && context.mounted) _podFarewellAndExit(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.power_settings_new_rounded, color: _baseOf(dark).withOpacity(0.55), size: 22),
                        const SizedBox(height: 3),
                        Text(AppLocalizations.of(context)!.exit,
                            style: TextStyle(
                                color: _baseOf(dark).withOpacity(0.55), fontSize: 10.5, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  static String _speedText(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

/// 글자가 칸보다 길면 좌우로 천천히 흐르게 (짧으면 그냥 글자) — 라디오 미니플레이어와 같은 설정
class _PodMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _PodMarquee(this.text, this.style);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (tp.width <= c.maxWidth) {
        return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      }
      return SizedBox(
        width: c.maxWidth,
        height: tp.height,
        child: Marquee(
          key: ValueKey(text), // 회차가 바뀌면 처음부터
          text: text,
          style: style,
          velocity: 28, // 천천히
          blankSpace: 48,
          startAfter: const Duration(seconds: 2), // 2초 보여 주고 출발
          pauseAfterRound: const Duration(seconds: 2), // 한 바퀴 돌면 2초 쉬기
          fadingEdgeStartFraction: 0.06,
          fadingEdgeEndFraction: 0.06,
          showFadingOnlyWhenScrolling: true,
        ),
      );
    });
  }
}

/// 구독 하트 — 음악 재생 화면 하트와 같은 모양·움직임
/// 켤 때만 하트가 통통 튀고 작은 하트 셋이 흔들리며 위로 떠올라요 (끌 때는 조용히)
class _PodHeart extends StatefulWidget {
  final bool isFav;
  final Color offColor;
  final VoidCallback onTap;
  final double iconSize; // 하트 크기
  final double box; // 누르는 칸
  final double rise; // 작은 하트가 올라가는 높이
  final double miniSize; // 작은 하트 크기
  const _PodHeart({
    required this.isFav,
    required this.offColor,
    required this.onTap,
    this.iconSize = 24,
    this.box = 46,
    this.rise = 74,
    this.miniSize = 12,
  });

  @override
  State<_PodHeart> createState() => _PodHeartState();
}

class _PodHeartState extends State<_PodHeart> with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE05A4F);
  static const _total = 1240.0; // ms (마지막 작은 하트가 끝날 때까지)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1240));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 하트 통통: 1 → 1.35 → 0.9 → 1 (처음 0.45초)
  double _pop(double ms) {
    if (!_c.isAnimating) return 1;
    final t = (ms / 450).clamp(0.0, 1.0);
    if (t < 0.35) return 1 + 0.35 * Curves.easeOut.transform(t / 0.35);
    if (t < 0.65) return 1.35 - 0.45 * ((t - 0.35) / 0.3);
    return 0.9 + 0.1 * ((t - 0.65) / 0.35);
  }

  /// 작은 하트 하나: 1초 동안 위로 74 올라가며 커졌다가 흐려짐
  Widget _mini(double ms, double startMs, double dx) {
    final t = (ms - startMs) / 1000;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final e = Curves.easeOut.transform(t);
    final op = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
    final wobble = math.sin(t * math.pi * 2) * 3; // 좌우로 살짝 흔들림
    return Transform.translate(
      offset: Offset(dx * e * widget.box / 46 + wobble, -widget.rise * e),
      child: Transform.scale(
        scale: 0.4 + 0.6 * e,
        child: Opacity(
          opacity: op.clamp(0.0, 1.0).toDouble(),
          child: Icon(CupertinoIcons.heart_fill, color: _red, size: widget.miniSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!widget.isFav) _c.forward(from: 0); // 켤 때만
        widget.onTap();
      },
      child: SizedBox(
        width: widget.box,
        height: widget.box,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final ms = _c.value * _total;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_c.isAnimating) ...[
                  _mini(ms, 0, -14),
                  _mini(ms, 120, 4),
                  _mini(ms, 240, 16),
                ],
                Transform.scale(
                  scale: _pop(ms),
                  child: Icon(
                    widget.isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: widget.isFav ? _red : widget.offColor,
                    size: widget.iconSize,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 수면 타이머 남은 시간 줄 — 라디오 재생 화면과 같은 모양 ('12분 30초 후 종료 ×', 누르면 끄기)
class _PodSleepBadge extends StatelessWidget {
  final Duration remaining;
  const _PodSleepBadge({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final timeText = h > 0
        ? l.sleepCountdownHMS(h, m, s)
        : m > 0
            ? l.sleepCountdownMS(m, s)
            : l.sleepCountdownS(s);
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => PodcastPlayer.instance.cancelSleepTimer(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bedtime_outlined, color: baseColor.withOpacity(0.5), size: 13),
          const SizedBox(width: 6),
          Text(timeText, style: TextStyle(color: baseColor.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Text(l.radioAfterEnd, style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 11)),
          const SizedBox(width: 6),
          Icon(Icons.close, color: baseColor.withOpacity(0.35), size: 12),
        ],
      ),
    );
  }
}

// 라디오 재생 화면과 같은 색 (위 버튼 · 아래 줄)
Color _baseOf(bool dark) => dark ? Colors.white : Colors.black;
Color _strongOf(bool dark) => dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color _mutedOf(bool dark) => dark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);

/// 위 동그란 버튼 — 라디오 재생 화면 위 버튼과 같은 모양 (29 · 연한 바탕 · 아이콘 13)
class _PodFloat extends StatelessWidget {
  final VoidCallback? onTap; // 하트처럼 안에서 누르기를 받으면 비워 둠
  final Widget child;
  const _PodFloat({this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = _baseOf(context.watch<ThemeProvider>().isDarkMode);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: base.withOpacity(0.07),
          border: Border.all(color: base.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// 아래 줄 버튼 — 라디오 재생 화면 아래 버튼과 같은 모양 (아이콘 22 + 글자 10.5, 켜지면 진하게)
class _PodBarItem extends StatelessWidget {
  final bool dark;
  final IconData? icon;
  final Widget? top; // 아이콘 대신 글자 (속도 1×)
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _PodBarItem({required this.dark, this.icon, this.top, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = on ? _strongOf(dark) : _mutedOf(dark);
    // 칸을 똑같이 나눔 → 독일어·헝가리어처럼 글자가 길어도 안 넘침 (길면 그 칸 안에서 살짝 줄임)
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22, child: Center(child: top ?? Icon(icon, color: c, size: 22))),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: TextStyle(
                      color: c,
                      fontSize: 10.5,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 종료: 작별 인사 → 소리 천천히 작게 → 앱 닫기 (라디오 재생 화면과 같은 순서)
void _podFarewellAndExit(BuildContext context) {
  final langCode = Localizations.localeOf(context).languageCode;
  final farewellAsset = langCode == 'ko' ? 'assets/farewell_ko_v4.mp3' : 'assets/greet_outro.mp3';
  if (context.read<ThemeProvider>().voiceGreetingEnabled) { // 한국어는 목소리 · 해외는 멜로디
    final farewellPlayer = AudioPlayer();
    farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
  }
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
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(darkValue), BlendMode.darken),
              ),
            ),
            alignment: Alignment.center,
            child: const FarewellTitle(),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);

  // 끝인사 동안 팟캐스트 소리를 1.5초에 걸쳐 천천히 작게
  final pod = PodcastPlayer.instance;
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

  Future.delayed(const Duration(milliseconds: 6500), () async {
    final fadeOutEntry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Container(color: Colors.black, width: double.infinity, height: double.infinity),
        ),
      ),
    );
    overlay.insert(fadeOutEntry);

    pod.cancelSleepTimer();
    if (pod.isPlaying) await pod.toggle(); // 멈추면서 듣던 곳 기억
    await fadePlayer.stop();
    await fadeRadio.stopRadio();
    await fadeRadio.setAlarmVolume(1.0); // 다음에 켤 때는 원래 크기로
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

/// 팟캐스트 회차 목록 화면 열기 (다른 곳과 같은 부드러운 페이드)
void _openPodShow(BuildContext context, PodcastShow show) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          PodcastShowScreen(show: show, country: tr.localeName.startsWith('ko') ? 'kr' : 'us'),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

/// '구독' 목록 창 — 라디오 '즐겨찾기' 목록 창과 같은 모양
/// 위: 지금 듣는 팟캐스트(먹색 카드) / 아래: 흰 카드에 줄들 · 누르면 그 팟캐스트 회차 목록으로
class _PodSubsSheet extends StatelessWidget {
  final String tok;
  const _PodSubsSheet({this.tok = ''});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final pod = context.watch<PodcastPlayer>();
    final bg = dark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    final list = pod.subs.values.toList().reversed.toList(); // 최근에 구독한 것부터
    final curId = pod.show?.id;
    final current = list.where((x) => x.id == curId).toList();
    final others = list.where((x) => x.id != curId).toList();
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    void open(PodcastShow x) {
      _buzz();
      Navigator.pop(context);
      _openPodShow(context, x);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            // 위: 제목 · 개수 · 닫기
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(podText('구독 중', 'Subscribed'),
                        style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
                  Text(tr.countItems(list.length), style: TextStyle(color: sub, fontSize: 12.5)),
                  const SizedBox(width: 6),
                  ParanCloseX(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.heart, size: 40, color: sub.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(podText('구독한 팟캐스트가 없어요', 'No subscriptions yet'),
                          style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(podText('하트를 누르면 여기에 모여요', 'Tap the heart to keep a podcast here'),
                          textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 12.5)),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 지금 듣는 팟캐스트 (먹색 카드)
                      for (final x in current)
                        GestureDetector(
                          onTap: () => open(x),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                PodcastArt(url: x.art, title: x.title, size: 44, radius: 10),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: bg.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFFF6B5E), shape: BoxShape.circle)),
                                            const SizedBox(width: 5),
                                            Text(tr.listeningNow,
                                                style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(x.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: bg, fontSize: 15, fontWeight: FontWeight.w700)),
                                      if (pod.episode != null)
                                        Text(pod.episode!.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: bg.withOpacity(0.65), fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: bg.withOpacity(0.6), size: 22),
                              ],
                            ),
                          ),
                        ),
                      if (others.isNotEmpty)
                        Container(
                          // 박스 없이 바탕 위에 바로 (팟캐스트 목록과 같게)
                          child: Column(
                            children: [
                              for (var i = 0; i < others.length; i++) ...[
                                if (i > 0) Container(height: 0.5, margin: const EdgeInsets.only(left: 60), color: line),
                                _PodAppear(
                                  id: '$tok:${others[i].id}',
                                  index: i,
                                  child: InkWell(
                                  onTap: () => open(others[i]),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 10), // 위 제목 줄과 같은 왼쪽
                                    child: Row(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            PodcastArt(url: others[i].art, title: others[i].title, size: 44, radius: 10),
                                            // 새 회차가 있으면 빨간 점 (팟캐스트 탭 '구독 중'과 같게)
                                            if (pod.newOnes.contains(others[i].id))
                                              Positioned(
                                                top: -3,
                                                right: -3,
                                                child: Container(
                                                  width: 11,
                                                  height: 11,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFD84A3A),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: bg, width: 2),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(others[i].title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
                                              if (others[i].author.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(others[i].author,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: sub, fontSize: 11.5)),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: sub.withOpacity(0.6), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 목록 한 줄 (박스 없이 바탕 위에 바로 · 줄 사이는 연한 선만 — 애플 팟캐스트처럼)
Widget _podPiece(bool dark, {required bool first, required bool last, required Widget child}) => child;

/// 줄이 화면에 들어올 때 아래에서 살짝 떠오르며 나타나기 (0.38초)
/// 한 번 나타난 줄은 스크롤해서 다시 와도 안 움직임 · 처음 보이는 줄(8개까지)만 차례로
class _PodAppear extends StatefulWidget {
  final String id; // 이 줄 이름 (한 번만 움직이게)
  final int index;
  final Widget child;
  const _PodAppear({required this.id, required this.index, required this.child});

  @override
  State<_PodAppear> createState() => _PodAppearState();
}

class _PodAppearState extends State<_PodAppear> with SingleTickerProviderStateMixin {
  static final Set<String> _shown = {};
  static DateTime _firstAt = DateTime(2000);
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void initState() {
    super.initState();
    if (_shown.contains(widget.id)) {
      _c.value = 1;
      return;
    }
    if (_shown.length > 3000) _shown.clear();
    _shown.add(widget.id);
    // 화면을 처음 열 때 보이는 줄만 위에서부터 차례로 (0.04초씩) · 스크롤로 들어오는 줄은 바로
    final now = DateTime.now();
    if (widget.index == 0) _firstAt = now;
    final opening = now.difference(_firstAt) < const Duration(milliseconds: 500);
    final wait = opening && widget.index < 8 ? widget.index * 40 : 0;
    if (wait == 0) {
      _c.forward();
    } else {
      Future.delayed(Duration(milliseconds: wait), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child; // 애니메이션 줄이기
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
        );
      },
    );
  }
}
