class RadioStation {
  final String stationUuid;
  final String name;
  final String streamUrl;
  final String? urlResolved;
  final String? logoUrl;
  final String? country;
  final String? countryCode;
  final String? broadcaster;
  final int? bitrate;
  final String? frequency;
  final int votes;
  bool isFavorite;
  DateTime? lastListened;

  RadioStation({
    required this.stationUuid,
    required this.name,
    required this.streamUrl,
    this.urlResolved,
    this.logoUrl,
    this.country,
    this.countryCode,
    this.broadcaster,
    this.bitrate,
    this.frequency,
    this.votes = 0,
    this.isFavorite = false,
    this.lastListened,
  });

  String get playableUrl {
    if (urlResolved != null && urlResolved!.isNotEmpty) {
      return urlResolved!;
    }
    return streamUrl;
  }

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    final urlResolved = json['url_resolved']?.toString() ?? '';
    final url = json['url']?.toString() ?? '';

    return RadioStation(
      stationUuid: json['stationuuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      streamUrl: url,
      urlResolved: urlResolved.isNotEmpty ? urlResolved : null,
      logoUrl: (json['favicon']?.toString().isNotEmpty ?? false)
          ? json['favicon'].toString()
          : null,
      country: json['country']?.toString(),
      countryCode: json['countrycode']?.toString(),
      broadcaster: _extractBroadcaster(json['name']?.toString() ?? ''),
      bitrate: json['bitrate'] is int
          ? json['bitrate'] as int
          : int.tryParse(json['bitrate']?.toString() ?? ''),
      frequency: json['frequency']?.toString(),
      votes: json['votes'] is int
          ? json['votes'] as int
          : int.tryParse(json['votes']?.toString() ?? '') ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastListened: json['lastListened'] != null
          ? DateTime.tryParse(json['lastListened'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'stationuuid': stationUuid,
    'name': name,
    'url': streamUrl,
    'url_resolved': urlResolved,
    'favicon': logoUrl,
    'country': country,
    'countrycode': countryCode,
    'bitrate': bitrate,
    'frequency': frequency,
    'votes': votes,
    'isFavorite': isFavorite,
    'lastListened': lastListened?.toIso8601String(),
  };

  RadioStation copyWith({bool? isFavorite, DateTime? lastListened}) {
    return RadioStation(
      stationUuid: stationUuid,
      name: name,
      streamUrl: streamUrl,
      urlResolved: urlResolved,
      logoUrl: logoUrl,
      country: country,
      countryCode: countryCode,
      broadcaster: broadcaster,
      bitrate: bitrate,
      frequency: frequency,
      votes: votes,
      isFavorite: isFavorite ?? this.isFavorite,
      lastListened: lastListened ?? this.lastListened,
    );
  }

  static String? _extractBroadcaster(String name) {
    for (final b in [
      'KBS', 'MBC', 'SBS', 'CBS', 'EBS', 'TBS', 'YTN',
      'NPR', 'NHK', 'RTHK', 'RTI', 'ICRT', 'BCC'
    ]) {
      if (name.toUpperCase().contains(b)) return b;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RadioStation && stationUuid == other.stationUuid;

  @override
  int get hashCode => stationUuid.hashCode;
}