# -*- coding: utf-8 -*-
# 검색 더하기: 결과에서 검색어 강조 · 최근 검색어 목록 (검색칸이 비어 있을 때)
import sys, glob, os, shutil

def find(name):
    hits = [h for h in glob.glob(os.path.join('lib', '**', name), recursive=True) if os.path.basename(h) == name]
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

# ───────── song_list_tile.dart: 검색어 강조 ─────────
tile = [
('강조할 글자 받기',
"""  final bool forceWhiteText;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.songList,
    this.forceWhiteText = false,
  });
""",
"""  final bool forceWhiteText;
  final String highlight; // 검색 중이면 검색어 (제목·가수에서 강조 색으로)

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.songList,
    this.forceWhiteText = false,
    this.highlight = '',
  });

  /// 글자 안에서 검색어만 강조 색으로 (대소문자 상관없이, 여러 번 나와도 모두)
  static Widget hlText(String text, String query, TextStyle style, Color hl) {
    final q = query.trim();
    if (q.isEmpty) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    final low = text.toLowerCase(), ql = q.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (true) {
      final j = low.indexOf(ql, i);
      if (j < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (j > i) spans.add(TextSpan(text: text.substring(i, j)));
      spans.add(TextSpan(text: text.substring(j, j + q.length), style: TextStyle(color: hl, fontWeight: FontWeight.w700)));
      i = j + q.length;
    }
    return Text.rich(TextSpan(children: spans), style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
"""),
('제목에 강조',
"""                  Text(
                    song.titleDisplay,
                    style: TextStyle(
                      color: isCurrentSong ? primaryColor : baseColor,
                      fontSize: 15,
                      fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),""",
"""                  hlText(
                    song.titleDisplay,
                    highlight,
                    TextStyle(
                      color: isCurrentSong ? primaryColor : baseColor,
                      fontSize: 15,
                      fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                    ),
                    primaryColor,
                  ),"""),
('가수에 강조',
"""                  Text(
                    song.artistDisplay,
                    style: TextStyle(
                      color: isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.38),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),""",
"""                  hlText(
                    song.artistDisplay,
                    highlight,
                    TextStyle(
                      color: isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.38),
                      fontSize: 13,
                    ),
                    primaryColor,
                  ),"""),
]

# ───────── home_screen.dart: 강조 넘기기 · 최근 검색어 ─────────
home = [
('시간 기능 불러오기',
"import 'dart:math' as math;\nimport 'package:flutter/rendering.dart' show ScrollDirection;\n",
"import 'dart:async';\nimport 'dart:math' as math;\nimport 'package:flutter/rendering.dart' show ScrollDirection;\n"),
('최근 검색어 칸',
"  bool _isSearching = false;\n",
"""  bool _isSearching = false;
  // 최근 검색어 (최근 것부터 8개)
  List<String> _recentSearches = [];
  Timer? _recentSaveTimer;
"""),
('처음에 불러오기',
"    _songListController.addListener(_updateCurrentGroup);",
"    _loadRecentSearches();\n    _songListController.addListener(_updateCurrentGroup);"),
('끝날 때 정리',
"    _searchController.dispose();\n",
"    _searchController.dispose();\n    _recentSaveTimer?.cancel();\n"),
('[검색] 누르면 저장',
"      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),",
"""      onSubmitted: (v) {
        FocusManager.instance.primaryFocus?.unfocus();
        _addRecentSearch(v);
      },"""),
('치고 잠시 멈추면 저장',
"""        context.read<MusicProvider>().search(value);
        setState(() {});
      },""",
"""        context.read<MusicProvider>().search(value);
        setState(() {});
        // 1.5초 동안 더 안 치면 최근 검색어로 저장
        _recentSaveTimer?.cancel();
        _recentSaveTimer = Timer(const Duration(milliseconds: 1500), () => _addRecentSearch(value));
      },"""),
('검색칸 비면 최근 검색어 보여주기',
"""  Widget _buildBody() {
    switch (_currentTabIndex) {""",
"""  // ── 최근 검색어 ──
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
    switch (_currentTabIndex) {"""),
('곡 줄에 검색어 넘기기',
"""                                child: SongListTile(
                                  song: song,
                                  index: index,
                                  songList: songs,
                                ),""",
"""                                child: SongListTile(
                                  song: song,
                                  index: index,
                                  songList: songs,
                                  highlight: _isSearching ? _searchController.text : '',
                                ),"""),
]

jobs = [
    prepare(find('song_list_tile.dart'), tile, 'static Widget hlText('),
    prepare(find('home_screen.dart'), home, '_buildRecentSearches()'),
]
for r in jobs:   # 둘 다 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak_search2')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_search2)')
