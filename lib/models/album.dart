import 'song.dart';
import '../l10n/locale_holder.dart';

class Album {
  final String name;
  final String artist;
  final List<Song> songs;

  const Album({
    required this.name,
    required this.artist,
    required this.songs,
  });

  String get displayName => name.isEmpty ? tr.unknownAlbum : name;
  String get displayArtist => artist.isEmpty ? tr.unknownArtist : artist;
  int get songCount => songs.length;
}