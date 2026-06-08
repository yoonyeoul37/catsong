class Song {
  final int id;
   String title;
   String artist;
   String album;
  final String? uri;
  int duration;
  bool isFavorite;
  List<int>? albumArt;
  bool isEdited = false;
  DateTime? lastPlayedAt;

  Song({
      required this.id,
      required this.title,
      required this.artist,
      required this.album,
      this.uri,
      this.duration = 0,
      this.isFavorite = false,
      this.albumArt,
    });

 String get durationFormatted {
   if (duration <= 0) return '0:00';
   final totalSeconds = duration ~/ 1000;
   final hours = totalSeconds ~/ 3600;
   final minutes = (totalSeconds % 3600) ~/ 60;
   final seconds = totalSeconds % 60;
   if (hours > 0) {
     return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
   }
   return '$minutes:${seconds.toString().padLeft(2, '0')}';
 }

  String get artistDisplay =>
      (artist.isEmpty || artist == '<unknown>') ? '알 수 없는 아티스트' : artist;

  String get albumDisplay =>
      (album.isEmpty || album == '<unknown>') ? '알 수 없는 앨범' : album;

  String get titleDisplay => title.isEmpty ? '제목 없음' : title;

  

  @override
  bool operator ==(Object other) => other is Song && id == other.id;

  @override
  int get hashCode => id.hashCode;
}