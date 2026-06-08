import 'song.dart';

class Playlist {
  final String id;
  String name;
  List<Song> songs;
  final DateTime createdAt;
  List<String> songUris;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
    List<String>? songUris,
  }) : songUris = songUris ?? [];

  int get songCount => songs.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songs.map((s) => s.id).toList(),
      'songUris': songs.map((s) => s.uri ?? '').where((u) => u.isNotEmpty).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}