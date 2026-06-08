import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    loadPlaylists();
  }

  List<String> _pendingPlaylistUris = [];

  Future<void> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('playlists');
      if (data != null) {
        final List decoded = jsonDecode(data);
        _playlists = decoded.map((e) => Playlist(
          id: e['id'],
          name: e['name'],
          songs: [],
          createdAt: DateTime.parse(e['createdAt']),
          songUris: List<String>.from(e['songUris'] ?? []),
        )).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('재생목록 불러오기 오류: $e');
    }
  }

  void restorePlaylistSongs(List<Song> allSongs) {
    for (final playlist in _playlists) {
      playlist.songs = playlist.songUris
          .map((uri) => allSongs.firstWhere(
                (s) => s.uri == uri,
                orElse: () => Song(id: -1, title: '', artist: '', album: '', uri: uri),
              ))
          .where((s) => s.id != -1)
          .toList();
    }
    notifyListeners();
  }

  Future<void> savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString('playlists', data);
    } catch (e) {
      debugPrint('재생목록 저장 오류: $e');
    }
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    notifyListeners();
    await savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await savePlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      notifyListeners();
      await savePlaylists();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, int songId) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.songs.removeWhere((s) => s.id == songId);
    notifyListeners();
    await savePlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final playlist = _playlists.firstWhere((p) => p.id == id);
    playlist.name = newName;
    notifyListeners();
    await savePlaylists();
  }
}