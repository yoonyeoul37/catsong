import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_content_entry.dart';
import '../models/song.dart';
import '../models/radio_station.dart';

class RecentContentProvider extends ChangeNotifier {
  List<RecentContentEntry> _entries = [];
  List<RecentContentEntry> get entries => _entries;

  static const _prefsKey = 'recent_content_v1';
  static const _maxEntries = 20;

  RecentContentProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _entries = decoded
            .map((e) => RecentContentEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (_) {}
  }

  Future<void> _addEntry(RecentContentEntry entry) async {
    _entries.removeWhere((e) => e.type == entry.type && e.key == entry.key);
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    notifyListeners();
    await _save();
  }

  Future<void> addMusic(Song song) async {
    if (song.uri == null || song.uri!.isEmpty) return;
    await _addEntry(RecentContentEntry(
      type: RecentContentType.music,
      key: song.uri!,
      title: song.titleDisplay,
      subtitle: song.artistDisplay,
      playedAt: DateTime.now(),
      songUri: song.uri,
    ));
  }

  Future<void> addRadio(RadioStation station) async {
    await _addEntry(RecentContentEntry(
      type: RecentContentType.radio,
      key: station.stationUuid,
      title: station.name,
      subtitle: (station.country?.isNotEmpty ?? false) ? station.country! : '라디오',
      playedAt: DateTime.now(),
      stationData: station.toJson(),
    ));
  }

  Future<void> addNature(String assetPath, String name) async {
    await _addEntry(RecentContentEntry(
      type: RecentContentType.nature,
      key: assetPath,
      title: name,
      subtitle: '자연소리',
      playedAt: DateTime.now(),
      natureAssetPath: assetPath,
    ));
  }
}