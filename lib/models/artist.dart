import 'song.dart';
import '../l10n/locale_holder.dart';

class Artist {
  final String name;
  final List<Song> songs;

  const Artist({
    required this.name,
    required this.songs,
  });

  String get displayName => name.isEmpty ? tr.unknownArtist : name;
  int get songCount => songs.length;
  int get albumCount => songs.map((s) => s.albumDisplay).toSet().length;
}