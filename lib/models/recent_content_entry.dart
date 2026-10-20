enum RecentContentType { music, radio, nature, sleep, podcast }

class RecentContentEntry {
  final RecentContentType type;
  final String key; // 중복 제거용 고유 키 (곡 uri / 방송국 uuid / 자연소리 asset 경로)
  final String title;
  final String subtitle;
  final DateTime playedAt;

  // 재생 재개에 필요한 부가 정보
  final String? songUri;
  final Map<String, dynamic>? stationData;
  final String? natureAssetPath;
  final Map<String, dynamic>? podcastData; // 팟캐스트: {show, ep} (홈에서만 씀)

  RecentContentEntry({
    required this.type,
    required this.key,
    required this.title,
    required this.subtitle,
    required this.playedAt,
    this.songUri,
    this.stationData,
    this.natureAssetPath,
    this.podcastData,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'key': key,
    'title': title,
    'subtitle': subtitle,
    'playedAt': playedAt.toIso8601String(),
    'songUri': songUri,
    'stationData': stationData,
    'natureAssetPath': natureAssetPath,
    'podcastData': podcastData,
  };

  factory RecentContentEntry.fromJson(Map<String, dynamic> json) {
    return RecentContentEntry(
      type: RecentContentType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => RecentContentType.music,
      ),
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      playedAt: DateTime.tryParse(json['playedAt']?.toString() ?? '') ?? DateTime.now(),
      songUri: json['songUri']?.toString(),
      stationData: json['stationData'] != null
          ? Map<String, dynamic>.from(json['stationData'])
          : null,
      natureAssetPath: json['natureAssetPath']?.toString(),
      podcastData: json['podcastData'] != null ? Map<String, dynamic>.from(json['podcastData']) : null,
    );
  }
}