# -*- coding: utf-8 -*-
# 새 노래 저절로 목록에 (쓸어내리지 않아도) + 즐겨찾기를 곡 파일로 저장 (순서 번호가 밀려 하트가 옮겨 가던 오류)
import os, sys

def find(name, base):
    for r, _, fs in os.walk(base):
        if name in fs and 'build' not in r.split(os.sep):
            return os.path.join(r, name)
    return None

MP = find('music_provider.dart', 'lib')
PP = find('player_provider.dart', 'lib')
MAIN = os.path.join('lib', 'main.dart')
KT = find('MainActivity.kt', 'android')
for n, p in [('music_provider.dart', MP), ('player_provider.dart', PP), ('main.dart', MAIN if os.path.exists(MAIN) else None), ('MainActivity.kt', KT)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

mp, MNLp = load(MP)
pp, PNL = load(PP)
mn, MNL = load(MAIN)
kt, KNL = load(KT)
if 'refreshNewSongs' in mp:
    print('이미 적용돼 있어요'); sys.exit(0)

mp_steps = [
 ('[music_provider] 즐겨찾기 칸: 곡 파일 경로로',
  "  Set<int> _favoriteIds = {};\n",
  "  Set<String> _favUris = {}; // 즐겨찾기 (곡 파일 경로 — 곡이 늘거나 줄어도 하트가 그 곡에 그대로)\n"
  "  List<int>? _legacyFavIds; // 예전(곡 순서 번호)으로 저장된 즐겨찾기 → 처음 한 번 파일 경로로 옮기기\n"
  "  Map<int, String> _idUri = {}; // 곡 번호 → 파일 경로 (isFavorite(번호)로 물어볼 때)\n"),
 ('[music_provider] 즐겨찾기 불러오기 · 저장',
  "  Future<void> _loadFavorites() async {\n"
  "    final prefs = await SharedPreferences.getInstance();\n"
  "    final ids = prefs.getStringList('favorites') ?? [];\n"
  "    _favoriteIds = ids.map((id) => int.parse(id)).toSet();\n"
  "  }\n"
  "\n"
  "  Future<void> _saveFavorites() async {\n"
  "    final prefs = await SharedPreferences.getInstance();\n"
  "    await prefs.setStringList(\n"
  "        'favorites', _favoriteIds.map((id) => id.toString()).toList());\n"
  "  }\n",
  "  Future<void> _loadFavorites() async {\n"
  "    final prefs = await SharedPreferences.getInstance();\n"
  "    final uris = prefs.getStringList('favorite_uris');\n"
  "    if (uris != null) {\n"
  "      _favUris = uris.toSet();\n"
  "      _legacyFavIds = null;\n"
  "    } else {\n"
  "      // 예전 방식(곡 순서 번호) → 곡을 다 찾은 뒤 파일 경로로 옮김 (loadSongs)\n"
  "      _legacyFavIds = (prefs.getStringList('favorites') ?? []).map(int.tryParse).whereType<int>().toList();\n"
  "    }\n"
  "  }\n"
  "\n"
  "  Future<void> _saveFavorites() async {\n"
  "    final prefs = await SharedPreferences.getInstance();\n"
  "    await prefs.setStringList('favorite_uris', _favUris.toList());\n"
  "  }\n"
  "\n"
  "  void _rebuildIdUri() {\n"
  "    _idUri = {for (final s in _songs) if (s.uri != null) s.id: s.uri!};\n"
  "  }\n"),
 ('[music_provider] 하트 누르기 · 확인을 파일 경로로',
  "  Future<void> toggleFavorite(Song song) async {\n"
  "    if (_favoriteIds.contains(song.id)) {\n"
  "      _favoriteIds.remove(song.id);\n"
  "      song.isFavorite = false;\n"
  "    } else {\n"
  "      _favoriteIds.add(song.id);\n"
  "      song.isFavorite = true;\n"
  "    }\n"
  "    await _saveFavorites();\n"
  "    notifyListeners();\n"
  "  }\n"
  "\n"
  "  bool isFavorite(int songId) => _favoriteIds.contains(songId);\n",
  "  Future<void> toggleFavorite(Song song) async {\n"
  "    final u = song.uri;\n"
  "    if (u == null) return;\n"
  "    _idUri[song.id] = u;\n"
  "    if (_favUris.remove(u)) {\n"
  "      song.isFavorite = false;\n"
  "    } else {\n"
  "      _favUris.add(u);\n"
  "      song.isFavorite = true;\n"
  "    }\n"
  "    await _saveFavorites();\n"
  "    notifyListeners();\n"
  "  }\n"
  "\n"
  "  bool isFavorite(int songId) {\n"
  "    final u = _idUri[songId];\n"
  "    return u != null && _favUris.contains(u);\n"
  "  }\n"),
 ('[music_provider] 찾을 폴더를 한 곳에',
  "      final scanPaths = [\n"
  "        '/storage/emulated/0/Music',\n"
  "        '/storage/emulated/0/Download',\n"
  "        '/storage/emulated/0/melon',\n"
  "        '/storage/emulated/0/KakaoTalkDownload',\n"
  "        '/storage/emulated/0/Skai',\n"
  "      ];\n",
  "      final scanPaths = _scanDirs;\n"),
 ('[music_provider] 곡을 찾을 때 하트는 파일 경로로',
  "                isFavorite: _favoriteIds.contains(idCounter - 1),\n",
  "                isFavorite: _favUris.contains(entity.path),\n"),
 ('[music_provider] 예전 즐겨찾기 한 번 옮기기',
  "      foundSongs.sort((a, b) => a.title.compareTo(b.title));\n"
  "      _songs = foundSongs;\n",
  "      // 예전 즐겨찾기(곡 순서 번호) → 파일 경로로 한 번만 옮기기 (곡을 못 찾았으면 다음에)\n"
  "      final legacy = _legacyFavIds;\n"
  "      if (legacy != null && foundSongs.isNotEmpty) {\n"
  "        final ids = legacy.toSet();\n"
  "        for (final s in foundSongs) {\n"
  "          if (ids.contains(s.id) && s.uri != null) _favUris.add(s.uri!);\n"
  "        }\n"
  "        _legacyFavIds = null;\n"
  "        await _saveFavorites();\n"
  "        for (final s in foundSongs) {\n"
  "          s.isFavorite = _favUris.contains(s.uri);\n"
  "        }\n"
  "      }\n"
  "      foundSongs.sort((a, b) => a.title.compareTo(b.title));\n"
  "      _songs = foundSongs;\n"
  "      _rebuildIdUri();\n"),
 ('[music_provider] 새 곡 저절로 찾기',
  "  void _buildAlbums() {\n",
  "  // ───── 새 곡 저절로 찾기 (쓸어내리지 않아도) ─────\n"
  "  static const _scanDirs = [\n"
  "    '/storage/emulated/0/Music',\n"
  "    '/storage/emulated/0/Download',\n"
  "    '/storage/emulated/0/melon',\n"
  "    '/storage/emulated/0/KakaoTalkDownload',\n"
  "    '/storage/emulated/0/Skai',\n"
  "  ];\n"
  "  bool _refreshing = false;\n"
  "  bool _refreshAgain = false;\n"
  "  DateTime _lastRefresh = DateTime(2000);\n"
  "\n"
  "  /// 폴더를 다시 훑어서 새로 생긴 곡만 붙이고 없어진 곡만 빼기 (목록 순서·스크롤은 그대로)\n"
  "  /// 폰에 음악 파일이 생기거나 지워질 때(안드로이드가 알려 줌) · 앱 화면으로 돌아올 때\n"
  "  Future<void> refreshNewSongs() async {\n"
  "    if (_isLoading || !_hasPermission) return; // 처음 불러오는 중이면 그쪽이 다 찾음\n"
  "    if (_refreshing) {\n"
  "      _refreshAgain = true;\n"
  "      return;\n"
  "    }\n"
  "    if (DateTime.now().difference(_lastRefresh) < const Duration(seconds: 2)) return;\n"
  "    _refreshing = true;\n"
  "    try {\n"
  "      do {\n"
  "        _refreshAgain = false;\n"
  "        _lastRefresh = DateTime.now();\n"
  "        await _refreshOnce();\n"
  "      } while (_refreshAgain);\n"
  "    } catch (e) {\n"
  "      debugPrint('새 곡 찾기 오류: $e');\n"
  "    } finally {\n"
  "      _refreshing = false;\n"
  "    }\n"
  "  }\n"
  "\n"
  "  Future<List<String>> _listMusicFiles() async {\n"
  "    final out = <String>[];\n"
  "    for (final path in _scanDirs) {\n"
  "      final dir = Directory(path);\n"
  "      if (!await dir.exists()) continue;\n"
  "      try {\n"
  "        await for (final entity in dir.list(recursive: true)) {\n"
  "          if (entity is! File) continue;\n"
  "          if (entity.path.split('/').last.startsWith('.')) continue; // 휴지통·숨김 파일\n"
  "          final ext = entity.path.toLowerCase();\n"
  "          if ((ext.endsWith('.mp3') || ext.endsWith('.m4a') || ext.endsWith('.flac') || ext.endsWith('.wav')) &&\n"
  "              !_isLegacyRecording(entity.path)) {\n"
  "            out.add(entity.path);\n"
  "          }\n"
  "        }\n"
  "      } catch (_) {}\n"
  "    }\n"
  "    return out;\n"
  "  }\n"
  "\n"
  "  Future<void> _refreshOnce() async {\n"
  "    final found = await _listMusicFiles();\n"
  "    final now = found.toSet();\n"
  "    final have = {for (final s in _songs) if (s.uri != null) s.uri!};\n"
  "    final added = found.where((p) => !have.contains(p)).toList();\n"
  "    final gone = have.difference(now);\n"
  "    if (added.isEmpty && gone.isEmpty) return;\n"
  "    debugPrint('새 곡 ${added.length}개 · 없어진 곡 ${gone.length}개');\n"
  "\n"
  "    var nextId = _songs.fold<int>(-1, (m, s) => s.id > m ? s.id : m) + 1; // 있던 곡 번호는 그대로\n"
  "    final fresh = <Song>[\n"
  "      for (final p in added)\n"
  "        Song(\n"
  "          id: nextId++,\n"
  "          title: _editedSongs[p]?['title'] ?? _getFileName(p),\n"
  "          artist: _editedSongs[p]?['artist'] ?? '',\n"
  "          album: _editedSongs[p]?['album'] ?? '',\n"
  "          uri: p,\n"
  "          duration: 0,\n"
  "          isFavorite: _favUris.contains(p),\n"
  "        ),\n"
  "    ];\n"
  "    final wasAll = _filteredSongs.length == _songs.length; // 검색 중이 아니면 보이는 목록도 같이\n"
  "    final list = _songs.where((s) => !gone.contains(s.uri)).toList();\n"
  "    // 새 곡은 제목 순서 자리에 끼워 넣기 (있던 곡 순서는 안 바뀜)\n"
  "    for (final s in fresh) {\n"
  "      var i = list.indexWhere((x) => x.title.compareTo(s.title) > 0);\n"
  "      if (i < 0) i = list.length;\n"
  "      list.insert(i, s);\n"
  "    }\n"
  "    _songs = list;\n"
  "    if (wasAll) {\n"
  "      _filteredSongs = List.from(_songs);\n"
  "    } else {\n"
  "      _filteredSongs.removeWhere((s) => gone.contains(s.uri));\n"
  "    }\n"
  "    _recentSongs.removeWhere((s) => gone.contains(s.uri));\n"
  "    _rebuildIdUri();\n"
  "    _buildAlbums();\n"
  "    _buildArtists();\n"
  "    _buildFolders();\n"
  "    if (fresh.isNotEmpty) await _updateFirstSeen(fresh); // '새로 들어온 곡'에 뜨게\n"
  "    notifyListeners();\n"
  "\n"
  "    // 새 곡만 정보(제목·가수·사진) 읽기\n"
  "    for (final song in fresh) {\n"
  "      try {\n"
  "        final metadata = await _channel.invokeMethod('getSongMetadata', {'path': song.uri});\n"
  "        if (metadata != null) {\n"
  "          final metaTitle = metadata['title'] as String?;\n"
  "          if (metaTitle != null && metaTitle.isNotEmpty && !_looksBroken(metaTitle)) song.title = metaTitle;\n"
  "          song.artist = metadata['artist'] ?? song.artist;\n"
  "          song.album = metadata['album'] ?? song.album;\n"
  "          song.duration = (metadata['duration'] as int?) ?? song.duration;\n"
  "          song.genre = (metadata['genre'] as String?) ?? song.genre;\n"
  "          song.albumArt = metadata['albumArt'] != null ? List<int>.from(metadata['albumArt']) : null;\n"
  "        }\n"
  "      } catch (_) {}\n"
  "      final edited = _editedSongs[song.uri];\n"
  "      if (edited != null) {\n"
  "        song.title = edited['title'] ?? song.title;\n"
  "        song.artist = edited['artist'] ?? song.artist;\n"
  "        song.album = edited['album'] ?? song.album;\n"
  "        song.isEdited = true;\n"
  "        final eg = edited['genre'];\n"
  "        if (eg != null) song.genre = eg;\n"
  "      }\n"
  "      if (song.uri != null && _customArt.containsKey(song.uri)) {\n"
  "        final art = await _readCustomArt(song.uri!);\n"
  "        if (art != null) song.albumArt = art;\n"
  "      }\n"
  "      if (song.uri != null) _metaDone.add(song.uri!);\n"
  "    }\n"
  "    if (fresh.isNotEmpty) {\n"
  "      _buildAlbums();\n"
  "      _buildArtists();\n"
  "      _buildFolders();\n"
  "      notifyListeners();\n"
  "    }\n"
  "  }\n"
  "\n"
  "  void _buildAlbums() {\n"),
]

pp_steps = [
 ('[player_provider] 음악 파일 바뀜 신호 받을 곳',
  "  static Future<void> Function(MethodCall call)? extraHandler;\n",
  "  static Future<void> Function(MethodCall call)? extraHandler;\n"
  "  static VoidCallback? onMusicChanged; // 폰에 음악 파일이 생기거나 지워짐 → 새 곡 찾기 (main.dart가 채움)\n"),
 ('[player_provider] 음악 파일 바뀜 신호',
  "        case 'openAudio':\n",
  "        case 'musicChanged':\n"
  "          onMusicChanged?.call(); // 쓸어내리지 않아도 새 곡이 목록에\n"
  "          break;\n"
  "        case 'openAudio':\n"),
]

mn_steps = [
 ('[main] 음악 파일 바뀌면 새 곡 찾기',
  "  OpenAudio.init(playerProvider, musicProvider); // 다른 앱에서 '파란소리로 열기' → 바로 재생\n",
  "  OpenAudio.init(playerProvider, musicProvider); // 다른 앱에서 '파란소리로 열기' → 바로 재생\n"
  "  PlayerProvider.onMusicChanged = musicProvider.refreshNewSongs; // 폰에 새 노래가 생기면 목록에 바로\n"),
 ('[main] 앱 화면으로 돌아올 때도 새 곡 찾기',
  "    if (state == AppLifecycleState.resumed) {\n"
  "      _checkForUpdate();\n",
  "    if (state == AppLifecycleState.resumed) {\n"
  "      _checkForUpdate();\n"
  "      context.read<MusicProvider>().refreshNewSongs(); // 다른 앱에서 받은 노래가 있으면 목록에 바로\n"),
]

kt_steps = [
 ('[MainActivity] 음악 파일 지켜보기 준비',
  "    private var pendingOpenAudio: String? = null // 다른 앱에서 '파란소리로 열기'로 넘겨받은 노래 주소\n",
  "    private var pendingOpenAudio: String? = null // 다른 앱에서 '파란소리로 열기'로 넘겨받은 노래 주소\n"
  "    // 폰에 음악 파일이 생기거나 지워지면 → 2초 뒤 한 번만 앱에 알리기 (다운로드 중 여러 번 와도 한 번)\n"
  "    private var musicObserver: android.database.ContentObserver? = null\n"
  "    private val musicHandler = android.os.Handler(android.os.Looper.getMainLooper())\n"
  "    private val musicChangedRun = Runnable { flutterMethodChannel?.invokeMethod(\"musicChanged\", null) }\n"),
 ('[MainActivity] 음악 파일 지켜보기 시작',
  "        flutterMethodChannel = channel\n"
  "        mediaChannel = channel\n",
  "        flutterMethodChannel = channel\n"
  "        mediaChannel = channel\n"
  "        if (musicObserver == null) {\n"
  "            val ob = object : android.database.ContentObserver(musicHandler) {\n"
  "                override fun onChange(selfChange: Boolean) {\n"
  "                    musicHandler.removeCallbacks(musicChangedRun)\n"
  "                    musicHandler.postDelayed(musicChangedRun, 2000)\n"
  "                }\n"
  "            }\n"
  "            try {\n"
  "                contentResolver.registerContentObserver(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, true, ob)\n"
  "                musicObserver = ob\n"
  "            } catch (_: Exception) {}\n"
  "        }\n"),
 ('[MainActivity] 앱을 끄면 지켜보기 그만',
  "        activityAlive = false\n",
  "        activityAlive = false\n"
  "        musicObserver?.let { try { contentResolver.unregisterContentObserver(it) } catch (_: Exception) {} }\n"
  "        musicObserver = null\n"
  "        musicHandler.removeCallbacks(musicChangedRun)\n"),
]

def apply(s, nl, steps):
    ok = True
    for name, old, new in steps:
        o = old.replace('\n', nl); n = new.replace('\n', nl)
        c = s.count(o)
        if c == 1:
            s = s.replace(o, n); print('✔', name)
        else:
            ok = False; print('❌', name, '(찾은 개수: %d)' % c)
    return s, ok

mp, a = apply(mp, MNLp, mp_steps)
pp, b = apply(pp, PNL, pp_steps)
mn, c = apply(mn, MNL, mn_steps)
kt, d = apply(kt, KNL, kt_steps)
if '_favoriteIds' in mp:
    a = False; print('❌ [music_provider] 예전 즐겨찾기 코드가 남아 있어요')
if not (a and b and c and d):
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(MP, 'wb').write(mp.encode('utf-8'))
open(PP, 'wb').write(pp.encode('utf-8'))
open(MAIN, 'wb').write(mn.encode('utf-8'))
open(KT, 'wb').write(kt.encode('utf-8'))
print('저장했어요')
