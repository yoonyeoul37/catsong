class RadioCountry {
  final String code;
  final String name;
  final String flag;
  final List<RadioBroadcaster> broadcasters;

  const RadioCountry({
    required this.code,
    required this.name,
    required this.flag,
    this.broadcasters = const [],
  });

  static const List<RadioCountry> supported = [
    RadioCountry(
      code: 'KR',
      name: '한국',
      flag: '🇰🇷',
      broadcasters: [
        // ── 전국 방송 ──
        RadioBroadcaster(id: 'KBS',     name: 'KBS',            keyword: 'KBS',         category: '전국'),
        RadioBroadcaster(id: 'MBC',     name: 'MBC',            keyword: 'MBC',         category: '전국'),
        RadioBroadcaster(id: 'SBS',     name: 'SBS',            keyword: 'SBS',         category: '전국'),
        RadioBroadcaster(id: 'CBS',     name: 'CBS',            keyword: 'CBS',         category: '전국'),
        RadioBroadcaster(id: 'EBS',     name: 'EBS',            keyword: 'EBS',         category: '전국'),
        RadioBroadcaster(id: 'YTN',     name: 'YTN',            keyword: 'YTN',         category: '전국'),
        // ── 서울/경기 ──
        RadioBroadcaster(id: 'TBS',     name: 'TBS 서울',        keyword: 'TBS',         category: '서울/경기'),
        RadioBroadcaster(id: 'OBS',     name: 'OBS 경인',        keyword: 'OBS',         category: '서울/경기'),
        RadioBroadcaster(id: 'IFM',     name: '경인방송',         keyword: '경인방송',      category: '서울/경기'),
        // ── 지역 MBC ──
        RadioBroadcaster(id: 'MBC_CB',  name: 'MBC충북',         keyword: 'MBC충북',      category: '지역 MBC'),
        RadioBroadcaster(id: 'MBC_AD',  name: '안동MBC',         keyword: '안동MBC',      category: '지역 MBC'),
        // ── 지역 민방 ──
        RadioBroadcaster(id: 'JTV',     name: 'JTV 전주',        keyword: 'JTV',         category: '지역 민방'),
        // ── 교통방송 ──
        RadioBroadcaster(id: 'TBN',     name: 'TBN 경인',        keyword: 'TBN 교통',     category: '교통방송'),
        RadioBroadcaster(id: 'TBN_UL',  name: 'TBN 울산',        keyword: 'TBN 울산',     category: '교통방송'),
        // ── 기타 ──
        RadioBroadcaster(id: 'GUGAK',   name: '국악FM',          keyword: 'gukak',       category: '기타'),
        RadioBroadcaster(id: 'GBFM',    name: '국방FM',          keyword: '국방FM',       category: '기타'),
        RadioBroadcaster(id: 'CPBC',    name: 'CPBC 가톨릭',      keyword: 'CPBC',        category: '기타'),
        RadioBroadcaster(id: 'BEFM',    name: 'BeFM 부산',       keyword: 'befm',        category: '기타'),
        RadioBroadcaster(id: 'ARIRANG', name: 'Arirang Radio',   keyword: 'Arirang',     category: '기타'),
        RadioBroadcaster(id: 'KPOP',    name: 'K-Pop Radio',     keyword: 'kpop',        category: '기타'),
        RadioBroadcaster(id: 'OLDPOP',  name: '올드팝카페',        keyword: 'oldpop',      category: '기타'),
        RadioBroadcaster(id: 'CLASSIC', name: 'Classic Odyssey',  keyword: 'Classic Odyssey', category: '기타'),
        RadioBroadcaster(id: 'MAPOFM',  name: '마포FM',          keyword: '마포FM',       category: '기타'),
        RadioBroadcaster(id: 'AFN',     name: 'AFN Korea',       keyword: 'AFN',         category: '기타'),
      ],
    ),
    RadioCountry(
      code: 'US',
      name: '미국',
      flag: '🇺🇸',
      broadcasters: [
        RadioBroadcaster(id: 'NPR',     name: 'NPR',            keyword: 'NPR'),
        RadioBroadcaster(id: 'ESPN',    name: 'ESPN Radio',     keyword: 'ESPN Radio'),
        RadioBroadcaster(id: 'BBC',     name: 'BBC',            keyword: 'BBC World Service'),
        RadioBroadcaster(id: 'VOA',     name: 'VOA',            keyword: 'Voice of America'),
        RadioBroadcaster(id: 'CNN',     name: 'CNN Radio',      keyword: 'CNN'),
        RadioBroadcaster(id: 'FOX',     name: 'Fox News',       keyword: 'Fox News'),
        RadioBroadcaster(id: 'JAZZ',    name: 'Jazz Radio',     keyword: 'Jazz'),
        RadioBroadcaster(id: 'CLASSI',  name: 'Classical',      keyword: 'Classical'),
      ],
    ),
    RadioCountry(
      code: 'JP',
      name: '일본',
      flag: '🇯🇵',
      broadcasters: [
        RadioBroadcaster(id: 'NHK',      name: 'NHK',           keyword: 'NHK'),
        RadioBroadcaster(id: 'JWAVE',    name: 'J-WAVE',        keyword: 'J-WAVE'),
        RadioBroadcaster(id: 'FM802',    name: 'FM802',         keyword: 'FM802'),
        RadioBroadcaster(id: 'TBSjp',    name: 'TBS Radio',     keyword: 'TBS Radio Japan'),
        RadioBroadcaster(id: 'TOKYOFM',  name: 'Tokyo FM',      keyword: 'Tokyo FM'),
        RadioBroadcaster(id: 'BAYFM',    name: 'Bay FM',        keyword: 'Bay FM'),
      ],
    ),
    RadioCountry(
      code: 'TW',
      name: '대만',
      flag: '🇹🇼',
      broadcasters: [
        RadioBroadcaster(id: 'RTI',     name: 'RTI',            keyword: 'RTI'),
        RadioBroadcaster(id: 'ICRT',    name: 'ICRT',           keyword: 'ICRT'),
        RadioBroadcaster(id: 'BCC',     name: 'BCC',            keyword: 'BCC Taiwan'),
      ],
    ),
    RadioCountry(
      code: 'HK',
      name: '홍콩',
      flag: '🇭🇰',
      broadcasters: [
        RadioBroadcaster(id: 'RTHK',    name: 'RTHK',               keyword: 'RTHK'),
        RadioBroadcaster(id: 'CRHK',    name: 'Commercial Radio',   keyword: 'Commercial Radio HK'),
      ],
    ),
  ];
}

class RadioBroadcaster {
  final String id;
  final String name;
  final String keyword;
  final String category;

  const RadioBroadcaster({
    required this.id,
    required this.name,
    required this.keyword,
    this.category = '',
  });
}