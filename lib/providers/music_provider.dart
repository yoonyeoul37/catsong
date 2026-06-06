import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/folder.dart';

class MusicProvider extends ChangeNotifier {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  Set<int> _favoriteIds = {};
  List<Song> _recentSongs = [];
  List<MusicFolder> _folders = [];
  static const _channel = MethodChannel('com.example.mp3_player/media');
  bool _isLoading = false;
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

  Future<void> addToRecent(Song song) async {
      _recentSongs.removeWhere((s) => s.id == song.id);
      _recentSongs.insert(0, song);
      if (_recentSongs.length > 50) {
        _recentSongs = _recentSongs.sublist(0, 50);
      }
      notifyListeners();
    }
Future<void> updateSongInfo(Song song, {String? title, String? artist, String? album}) async {
    if (title != null) song.title = title;
    if (artist != null) song.artist = artist;
    if (album != null) song.album = album;

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
              final ext = entity.path.toLowerCase();
              if (ext.endsWith('.mp3') ||
                  ext.endsWith('.m4a') ||
                  ext.endsWith('.flac') ||
                  ext.endsWith('.wav')) {
                foundSongs.add(Song(
                  id: idCounter++,
                  title: _getFileName(entity.path),
                  artist: '알 수 없는 아티스트',
                  album: '알 수 없는 앨범',
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
        _isLoading = false;
        notifyListeners();

        // 2단계: 백그라운드에서 메타데이터 읽기
              int updateCount = 0;
              for (final song in _songs) {
                if (song.uri == null) continue;
                try {
                  final metadata = await _channel.invokeMethod(
                      'getSongMetadata', {'path': song.uri});
                  if (metadata != null) {
                    song.title = metadata['title'] ?? song.title;
                    song.artist = metadata['artist'] ?? song.artist;
                    song.album = metadata['album'] ?? song.album;
                    song.duration = (metadata['duration'] as int?) ?? song.duration;
                    song.albumArt = metadata['albumArt'] != null
                        ? List<int>.from(metadata['albumArt'])
                        : null;
                  }
                } catch (e) {
                  // 메타데이터 읽기 실패시 무시
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

        debugPrint('스캔 완료: ${_songs.length}개 곡 발견');
      } catch (e) {
        _errorMessage = '음악 스캔 오류: $e';
      } finally {
        _isLoading = false;
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