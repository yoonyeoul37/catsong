import '../l10n/locale_holder.dart';

class Video {
  final int id;
  final String title;
  final String uri;
  final int duration;
  List<int>? thumbnail;

  Video({
    required this.id,
    required this.title,
    required this.uri,
    this.duration = 0,
    this.thumbnail,
  });

  String get titleDisplay => title.isEmpty ? tr.noTitle : title;

  String get durationFormatted {
    if (duration <= 0) return '0:00';
    final totalSeconds = duration ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}