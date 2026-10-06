import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/folder.dart';
import '../models/call_recording.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class MusicProvider extends ChangeNotifier {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  Set<int> _favoriteIds = {};
  List<Song> _recentSongs = [];
  List<MusicFolder> _folders = [];
  static const _channel = MethodChannel('kr.ssing.catsong/media');
  bool _isLoading = true;
  bool _metaLoading = false; // 2단계: 곡 정보(제목·가수)를 뒤에서 읽는 중
  bool get metaLoading => _metaLoading;
  bool _hasPermission = false;
  String _errorMessage = '';

  List<Song> get songs => _filteredSongs;
  List<Song> get allSongs => _songs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Song> get favorites => _songs.where((s) => s.isFavorite).toList();
  List<Song> get recentSongs => _recentSongs;
  List<MusicFolder> get folders => _folders;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String get errorMessage => _errorMessage;
  int get songCount => _songs.length;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _loadFavorites();
      await _loadPlayCounts();
      await _loadEditedSongs();
      await _loadCustomArt();
      await _loadRecentSongsUris();
      final granted = await _requestPermissions();
      if (granted) {
        await loadSongs();
      } else {
        _errorMessage = '저장소 접근 권한이 필요합니다.\n설정에서 권한을 허용해 주세요.';
      }
    } catch (e) {
      _errorMessage = '음악을 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, Map<String, String>> _editedSongs = {};

  // 인터넷에서 찾아 넣은 앨범 사진 (곡 파일 경로 → 앱 폴더에 저장한 사진 이름)
  Map<String, String> _customArt = {};

  Future<void> _loadCustomArt() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('custom_art');
      if (raw != null) _customArt = Map<String, String>.from(jsonDecode(raw));
    } catch (_) {}
  }

  Future<List<int>?> _readCustomArt(String uri) async {
    final name = _customArt[uri];
    if (name == null) return null;
    try {
      final dir = await _channel.invokeMethod<String>('appFilesDir');
      if (dir == null) return null;
      final f = File('$dir/album_art/$name');
      return await f.exists() ? await f.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  /// 인터넷에서 받은 앨범 사진을 이 곡에 넣기 (앱 폴더에 저장 → 다음에 켜도 그대로)
  Future<void> setCustomArt(Song song, List<int> bytes) async {
    if (song.uri == null) return;
    try {
      final dir = await _channel.invokeMethod<String>('appFilesDir');
      if (dir == null) return;
      final folder = Directory('$dir/album_art');
      if (!await folder.exists()) await folder.create(recursive: true);
      final name = '${song.uri.hashCode.abs()}.jpg';
      await File('${folder.path}/$name').writeAsBytes(bytes);
      _customArt[song.uri!] = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_art', jsonEncode(_customArt));
      song.albumArt = bytes;
      notifyListeners();
    } catch (e) {
      debugPrint('앨범 사진 저장 오류: $e');
    }
  }

  Future<void> _loadEditedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('edited_song_'));
    for (final key in keys) {
      final uri = key.replaceFirst('edited_song_', '');
      final data = prefs.getStringList(key);
      if (data != null && data.length == 3) {
        _editedSongs[uri] = {
          'title': data[0],
          'artist': data[1],
          'album': data[2],
        };
      }
    }
  }

  Future<void> _saveEditedSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    if (song.uri != null) {
      await prefs.setStringList('edited_song_${song.uri}', [
        song.title,
        song.artist,
        song.album,
      ]);
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorites') ?? [];
    _favoriteIds = ids.map((id) => int.parse(id)).toSet();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'favorites', _favoriteIds.map((id) => id.toString()).toList());
  }

  // 곡별 재생 횟수 (곡 파일 경로 → 횟수)
  Map<String, int> _playCounts = {};

  int playCountOf(Song song) =>
      song.uri == null ? 0 : (_playCounts[song.uri!] ?? 0);

  Future<void> _loadPlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('play_counts');
    if (raw == null) return;
    try {
      final Map decoded = jsonDecode(raw);
      _playCounts = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } catch (_) {}
  }

  Future<void> _savePlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('play_counts', jsonEncode(_playCounts));
  }

  List<String> _recentSongUris = [];

  Future<void> _loadRecentSongsUris() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSongUris = prefs.getStringList('recent_songs') ?? [];
  }

  Future<void> _loadRecentSongs() async {
    _recentSongs = _recentSongUris
        .map((uri) => _songs.firstWhere(
          (s) => s.uri == uri,
      orElse: () => Song(id: -1, title: '', artist: '', album: '', uri: uri),
    ))
        .where((s) => s.id != -1)
        .toList();
  }

  Future<void> _saveRecentSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final uris = _recentSongs
        .where((s) => s.uri != null)
        .map((s) => s.uri!)
        .take(50)
        .toList();
    await prefs.setStringList('recent_songs', uris);
  }

  Future<void> removeFromRecent(Song song) async {
    _recentSongs.removeWhere((s) => s.id == song.id);
    await _saveRecentSongs();
    notifyListeners();
  }

  Future<void> clearRecent() async {
    _recentSongs.clear();
    await _saveRecentSongs();
    notifyListeners();
  }

  Future<void> addToRecent(Song song) async {
    // 통화 녹음은 사적인 내용이라 최근 목록·재생 횟수에 안 남김
    if (isCallRecordingPath(song.uri)) return;
    song.lastPlayedAt = DateTime.now();
    if (song.uri != null) {
      _playCounts[song.uri!] = (_playCounts[song.uri!] ?? 0) + 1;
      _savePlayCounts();
    }
    _recentSongs.removeWhere((s) => s.id == song.id);
    _recentSongs.insert(0, song);
    if (_recentSongs.length > 50) {
      _recentSongs = _recentSongs.sublist(0, 50);
    }
    await _saveRecentSongs();
    notifyListeners();
  }
  Future<void> updateSongInfo(Song song, {String? title, String? artist, String? album}) async {
    if (title != null) song.title = title;
    if (artist != null) song.artist = artist;
    if (album != null) song.album = album;
    song.isEdited = true;
    await _saveEditedSong(song);
    // 새로고침해도 방금 고친 내용이 유지되도록 바로 기억해둠
    if (song.uri != null) {
      _editedSongs[song.uri!] = {
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
      };
    }

    // 실제 파일 메타데이터 업데이트
    if (song.uri != null) {
      try {
        await _channel.invokeMethod('updateSongMetadata', {
          'path': song.uri,
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
        });
      } catch (e) {
        debugPrint('메타데이터 업데이트 오류: $e');
      }
    }

    _buildAlbums();
    _buildArtists();
    _buildFolders();
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    if (_favoriteIds.contains(song.id)) {
      _favoriteIds.remove(song.id);
      song.isFavorite = false;
    } else {
      _favoriteIds.add(song.id);
      song.isFavorite = true;
    }
    await _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(int songId) => _favoriteIds.contains(songId);

  // ───────── 통화 녹음 (일반 음악과 따로) ─────────
  static const _callDirs = [
    '/storage/emulated/0/Recordings/Call',
    '/storage/emulated/0/Call',
  ];
  // 음성 녹음 (삼성 녹음기 앱)
  static const _voiceDirs = [
    '/storage/emulated/0/Recordings/Voice Recorder',
    '/storage/emulated/0/Recordings/Paransori', // 파란소리에서 녹음한 것
    '/storage/emulated/0/Voice Recorder',
    '/storage/emulated/0/Podcasts/Paransori', // 안드로이드 11 이하에서 녹음한 것
  ];

  // 안드로이드 11 이하에서 예전에 Music/Paransori에 저장된 녹음 → 음악 목록에서 빼고 녹음 화면에 보이게
  static const _legacyRecDir = '/storage/emulated/0/Music/Paransori';
  static bool _isLegacyRecording(String path) {
    if (!path.startsWith('$_legacyRecDir/')) return false;
    final n = path.split('/').last;
    return n.startsWith('녹음 ') || n.startsWith('통화 녹음') || n.startsWith('음성 ');
  }
  List<CallRecording> _callRecordings = [];
  bool _callLoading = false;
  List<CallRecording> get callRecordings => _callRecordings;
  bool get callLoading => _callLoading;

  // 녹음: 내가 붙인 제목 / 잠금 (파일 경로 기준, 앱 안에만 저장 → 원래 파일 이름은 그대로)
  Map<String, String> _recTitles = {};
  Set<String> _recLocked = {};

  String recordingTitle(CallRecording r) => _recTitles[r.path] ?? r.name;
  bool isRecordingLocked(String path) => _recLocked.contains(path);

  Future<void> _loadRecMeta() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('rec_titles');
      if (raw != null) {
        _recTitles = Map<String, String>.from(jsonDecode(raw));
      }
    } catch (_) {}
    _recLocked = (prefs.getStringList('rec_locked') ?? []).toSet();
  }

  Future<void> setRecordingTitle(CallRecording r, String title) async {
    if (title.isEmpty || title == r.name) {
      _recTitles.remove(r.path); // 비우면 원래 이름으로
    } else {
      _recTitles[r.path] = title;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rec_titles', jsonEncode(_recTitles));
    notifyListeners();
  }

  Future<void> toggleRecordingLock(CallRecording r) async {
    if (!_recLocked.remove(r.path)) _recLocked.add(r.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rec_locked', _recLocked.toList());
    notifyListeners();
  }

  /// 녹음 삭제 → 휴지통으로 (잠근 건 빼고). 옮긴 개수, 취소·실패면 0
  Future<int> trashRecordings(List<CallRecording> list) async {
    final targets = list.where((r) => !_recLocked.contains(r.path)).toList();
    if (targets.isEmpty) return 0;
    try {
      final ok = await _channel.invokeMethod('trashFiles', {
        'paths': targets.map((r) => r.path).toList(),
      });
      if (ok == true) {
        final gone = targets.map((r) => r.path).toSet();
        _callRecordings.removeWhere((r) => gone.contains(r.path));
        notifyListeners();
        return targets.length;
      }
    } catch (e, st) {
      debugPrint('녹음 삭제 오류: $e');
      // 삭제 실패 이유를 Crashlytics에 남기기 (스토어 버전에서도 원인 확인용)
      FirebaseCrashlytics.instance.recordError(e, st, reason: '녹음 삭제 실패');
    }
    return 0;
  }

  /// 녹음 영구 삭제 (되살릴 수 없음, 잠근 건 빼고). 지운 개수, 취소·실패면 0
  Future<int> deleteRecordingsForever(List<CallRecording> list) async {
    final targets = list.where((r) => !_recLocked.contains(r.path)).toList();
    if (targets.isEmpty) return 0;
    try {
      final ok = await _channel.invokeMethod('deleteFilesForever', {
        'paths': targets.map((r) => r.path).toList(),
      });
      if (ok == true) {
        final gone = targets.map((r) => r.path).toSet();
        _callRecordings.removeWhere((r) => gone.contains(r.path));
        notifyListeners();
        return targets.length;
      }
    } catch (e, st) {
      debugPrint('녹음 영구 삭제 오류: $e');
      FirebaseCrashlytics.instance.recordError(e, st, reason: '녹음 영구 삭제 실패');
    }
    return 0;
  }

  /// 통화 녹음 폴더에 있는 파일인지
  bool isCallRecordingPath(String? path) =>
      path != null &&
          ([..._callDirs, ..._voiceDirs].any((d) => path.startsWith('$d/')) || _isLegacyRecording(path));

  /// 통화 녹음 불러오기 (최신순) → 통화 길이는 뒤에서 천천히 채움
  Future<void> loadCallRecordings() async {
    _callLoading = true;
    await _loadRecMeta(); // 내가 붙인 제목·잠금
    notifyListeners();
    final found = <CallRecording>[];
    for (final d in [..._callDirs, ..._voiceDirs, _legacyRecDir]) {
      final legacy = d == _legacyRecDir; // 예전에 음악 폴더에 들어간 녹음
      final isVoice = _voiceDirs.contains(d) || legacy;
      final dir = Directory(d);
      if (!await dir.exists()) continue;
      await for (final e in dir.list()) {
        if (e is! File) continue;
        if (e.path.split('/').last.startsWith('.')) continue; // 휴지통(.trashed-)·숨김 파일은 빼기
        if (legacy && !_isLegacyRecording(e.path)) continue; // 음악 폴더에선 녹음만 골라오기
        final lower = e.path.toLowerCase();
        if (!(lower.endsWith('.m4a') || lower.endsWith('.mp3') || lower.endsWith('.amr') || lower.endsWith('.3gp'))) {
          continue;
        }
        DateTime modified;
        try {
          modified = await e.lastModified();
        } catch (_) {
          modified = DateTime.now();
        }
        // 자른 통화 녹음("통화 녹음 …")은 음성 폴더에 있어도 통화 녹음 칸으로
        final fileVoice = isVoice && !e.path.split('/').last.startsWith('통화 녹음');
        found.add(CallRecording.fromPath(e.path, modified, isVoice: fileVoice));
      }
    }
    found.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    _callRecordings = found;
    _callLoading = false;
    notifyListeners();

    var n = 0;
    for (final r in found) {
      try {
        final meta = await _channel.invokeMethod('getSongMetadata', {'path': r.path});
        r.durationMs = (meta?['duration'] as int?) ?? 0;
      } catch (_) {}
      if (++n % 10 == 0) notifyListeners();
    }
    notifyListeners();
  }

  /// 자른 곡(파일 이름에 _자름)의 원본이 목록에 아직 있으면 true → 가위 표시
  /// 원본을 지우면 false가 돼서 가위도 사라짐
  bool isTrimmedWithOriginal(Song song) {
    final uri = song.uri ?? '';
    if (!uri.contains('_자름')) return false;
    return _songs.any((s) =>
    !identical(s, song) &&
        !(s.uri ?? '').contains('_자름') &&
        s.title == song.title &&
        s.artistDisplay == song.artistDisplay);
  }

  Future<bool> _requestPermissions() async {
    try {
      final statuses = await [
        Permission.audio,
        Permission.storage,
      ].request();
      _hasPermission = true;
      return true;
    } catch (e) {
      _hasPermission = true;
      return true;
    }
  }

  Future<void> loadSongs() async {
    try {
      _isLoading = true;
      notifyListeners();

      final List<Song> foundSongs = [];
      int idCounter = 0;

      final scanPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/melon',
        '/storage/emulated/0/KakaoTalkDownload',
        '/storage/emulated/0/Skai',
      ];

      // 1단계: 파일 목록만 빠르게 스캔
      for (final path in scanPaths) {
        final dir = Directory(path);
        if (!await dir.exists()) continue;

        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            if (entity.path.split('/').last.startsWith('.')) continue; // 휴지통(.trashed-)·숨김 파일은 빼기
            final ext = entity.path.toLowerCase();
            if ((ext.endsWith('.mp3') ||
                ext.endsWith('.m4a') ||
                ext.endsWith('.flac') ||
                ext.endsWith('.wav')) &&
                !_isLegacyRecording(entity.path)) { // 음악 폴더에 들어간 녹음은 음악 목록에서 빼기
              foundSongs.add(Song(
                id: idCounter++,
                title: _getFileName(entity.path),
                artist: '',
                album: '',
                uri: entity.path,
                duration: 0,
                isFavorite: _favoriteIds.contains(idCounter - 1),
              ));
            }
          }
        }
      }

      foundSongs.sort((a, b) => a.title.compareTo(b.title));
      _songs = foundSongs;
      _filteredSongs = List.from(_songs);
      _buildAlbums();
      _buildArtists();
      _buildFolders();
      await _loadRecentSongs();
      _isLoading = false;
      notifyListeners();

      // 2단계: 백그라운드에서 메타데이터 읽기
      _metaLoading = true;
      int updateCount = 0;
      for (final song in _songs) {
        if (song.uri == null) continue;
        try {
          final metadata = await _channel.invokeMethod(
              'getSongMetadata', {'path': song.uri});
          if (metadata != null) {
            final edited = song.uri != null ? _editedSongs[song.uri] : null;
            if (edited != null) {
              song.title = edited['title'] ?? song.title;
              song.artist = edited['artist'] ?? song.artist;
              song.album = edited['album'] ?? song.album;
              song.isEdited = true;
            } else {
              final metaTitle = metadata['title'] as String?;
              if (metaTitle != null && metaTitle.isNotEmpty && !_looksBroken(metaTitle)) {
                song.title = metaTitle;
              }
              song.artist = metadata['artist'] ?? song.artist;
              song.album = metadata['album'] ?? song.album;
            }
            song.duration = (metadata['duration'] as int?) ?? song.duration;
            song.albumArt = metadata['albumArt'] != null
                ? List<int>.from(metadata['albumArt'])
                : null;
          }
        } catch (e) {
          // 메타데이터 읽기 실패시 무시
        }
        // 고친 곡은 파일 정보를 못 읽어도 항상 고친 내용으로
        final edited = _editedSongs[song.uri];
        if (edited != null) {
          song.title = edited['title'] ?? song.title;
          song.artist = edited['artist'] ?? song.artist;
          song.album = edited['album'] ?? song.album;
          song.isEdited = true;
        }
        // 인터넷에서 찾아 넣은 앨범 사진이 있으면 그걸로
        if (song.uri != null && _customArt.containsKey(song.uri)) {
          final art = await _readCustomArt(song.uri!);
          if (art != null) song.albumArt = art;
        }
        updateCount++;
        // 10개마다 한 번씩 업데이트
        if (updateCount % 10 == 0) {
          notifyListeners();
        }
      }
      _buildAlbums();
      _buildArtists();
      _buildFolders();
      notifyListeners();

      await _loadRecentSongs();
      _metaLoading = false; // 곡 정보 다 읽음
      debugPrint('스캔 완료: ${_songs.length}개 곡 발견');
    } catch (e) {
      _errorMessage = '음악 스캔 오류: $e';
    } finally {
      _isLoading = false;
      _metaLoading = false;
      notifyListeners();
    }
  }
  void _buildAlbums() {
    final Map<String, List<Song>> albumMap = {};
    for (final song in _songs) {
      final key = song.albumDisplay;
      albumMap.putIfAbsent(key, () => []).add(song);
    }
    _albums = albumMap.entries.map((e) {
      return Album(
        name: e.key,
        artist: e.value.first.artistDisplay,
        songs: e.value,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _buildArtists() {
    final Map<String, List<Song>> artistMap = {};
    for (final song in _songs) {
      final key = song.artistDisplay;
      artistMap.putIfAbsent(key, () => []).add(song);
    }
    _artists = artistMap.entries.map((e) {
      return Artist(
        name: e.key,
        songs: e.value,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _buildFolders() {
    final Map<String, List<Song>> folderMap = {};
    for (final song in _songs) {
      if (song.uri == null) continue;
      final parts = song.uri!.split('/');
      parts.removeLast();
      final folderPath = parts.join('/');
      final folderName = parts.last;
      folderMap.putIfAbsent(folderPath, () => []).add(song);
    }
    _folders = folderMap.entries.map((e) {
      final folderName = e.key.split('/').last;
      return MusicFolder(
        path: e.key,
        name: folderName,
        songs: e.value,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  bool _looksBroken(String text) {
    // 깨진 인코딩(물음표, 대체문자 등)이 많이 섞여있으면 true
    int badCount = 0;
    for (final ch in text.runes) {
      if (ch == 0xFFFD || ch == 0x3F) badCount++; // U+FFFD(대체문자), '?'
    }
    return badCount > text.length * 0.3;
  }

  String _getFileName(String path) {
    final name = path.split('/').last;
    return name.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  void search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      _filteredSongs = List.from(_songs);
    } else {
      _filteredSongs = _songs.where((song) {
        return song.title.toLowerCase().contains(q) ||
            song.artistDisplay.toLowerCase().contains(q) ||
            song.albumDisplay.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _filteredSongs = List.from(_songs);
    notifyListeners();
  }

  List<Album> searchAlbums(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _albums;
    return _albums.where((album) {
      return album.name.toLowerCase().contains(q) ||
          album.artist.toLowerCase().contains(q);
    }).toList();
  }

  List<Artist> searchArtists(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _artists;
    return _artists.where((artist) {
      return artist.name.toLowerCase().contains(q);
    }).toList();
  }
}