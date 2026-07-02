import '../l10n/locale_holder.dart';

class RadioCountry {
  final String code;
  final String name;
  final String flag;
  final String continent;
  final List<RadioBroadcaster> broadcasters;

  const RadioCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.continent,
    this.broadcasters = const [],
  });

  String get displayName {
    final l = AppLocale.current;
    if (l == null) return name;
    switch (code) {
      case 'KR': return l.countryKR;
      case 'US': return l.countryUS;
      case 'JP': return l.countryJP;
      case 'TW': return l.countryTW;
      case 'CN': return l.countryCN;
      case 'HK': return l.countryHK;
      case 'GB': return l.countryGB;
      case 'VN': return l.countryVN;
      case 'PH': return l.countryPH;
      case 'DE': return l.countryDE;
      case 'FR': return l.countryFR;
      case 'TH': return l.countryTH;
      case 'ID': return l.countryID;
      case 'IN': return l.countryIN;
      case 'ES': return l.countryES;
      case 'IT': return l.countryIT;
      case 'BR': return l.countryBR;
      case 'CA': return l.countryCA;
      case 'AU': return l.countryAU;
      case 'MX': return l.countryMX;
      case 'TR': return l.countryTR;
      case 'NL': return l.countryNL;
      case 'SE': return l.countrySE;
      case 'PL': return l.countryPL;
      case 'AR': return l.countryAR;
      case 'CO': return l.countryCO;
      case 'NZ': return l.countryNZ;
      case 'MY': return l.countryMY;
      case 'SG': return l.countrySG;
      case 'RU': return l.countryRU;
      case 'ZA': return l.countryZA;
      case 'PK': return l.countryPK;
      case 'BD': return l.countryBD;
      case 'LK': return l.countryLK;
      case 'NP': return l.countryNP;
      case 'MM': return l.countryMM;
      case 'KH': return l.countryKH;
      case 'AT': return l.countryAT;
      case 'CH': return l.countryCH;
      case 'BE': return l.countryBE;
      case 'PT': return l.countryPT;
      case 'GR': return l.countryGR;
      case 'IE': return l.countryIE;
      case 'NO': return l.countryNO;
      case 'DK': return l.countryDK;
      case 'FI': return l.countryFI;
      case 'CZ': return l.countryCZ;
      case 'RO': return l.countryRO;
      case 'UA': return l.countryUA;
      case 'EG': return l.countryEG;
      case 'SA': return l.countrySA;
      case 'AE': return l.countryAE;
      case 'NG': return l.countryNG;
      case 'KE': return l.countryKE;
      case 'CL': return l.countryCL;
      case 'PE': return l.countryPE;
      case 'VE': return l.countryVE;
      case 'CU': return l.countryCU;
      case 'JM': return l.countryJM;
      case 'IQ': return l.countryIQ;
      case 'IR': return l.countryIR;
      case 'IL': return l.countryIL;
      case 'MN': return l.countryMN;
      case 'UZ': return l.countryUZ;
      case 'KZ': return l.countryKZ;
      case 'LA': return l.countryLA;
      case 'HU': return l.countryHU;
      case 'HR': return l.countryHR;
      case 'RS': return l.countryRS;
      case 'BG': return l.countryBG;
      case 'SK': return l.countrySK;
      case 'LT': return l.countryLT;
      case 'LV': return l.countryLV;
      case 'EE': return l.countryEE;
      case 'IS': return l.countryIS;
      case 'GH': return l.countryGH;
      case 'TZ': return l.countryTZ;
      case 'MA': return l.countryMA;
      case 'TN': return l.countryTN;
      case 'ET': return l.countryET;
      case 'UG': return l.countryUG;
      case 'EC': return l.countryEC;
      case 'BO': return l.countryBO;
      case 'PY': return l.countryPY;
      case 'UY': return l.countryUY;
      case 'PA': return l.countryPA;
      case 'CR': return l.countryCR;
      case 'DO': return l.countryDO;
      case 'TT': return l.countryTT;
      case 'HT': return l.countryHT;
      case 'FJ': return l.countryFJ;
      case 'PG': return l.countryPG;
      case 'JO': return l.countryJO;
      case 'LB': return l.countryLB;
      case 'GE': return l.countryGE;
      case 'AM': return l.countryAM;
      case 'AZ': return l.countryAZ;
      case 'SI': return l.countrySI;
      case 'AL': return l.countryAL;
      case 'MK': return l.countryMK;
      case 'ME': return l.countryME;
      case 'BA': return l.countryBA;
      case 'MT': return l.countryMT;
      case 'LU': return l.countryLU;
      case 'CY': return l.countryCY;
      case 'CM': return l.countryCM;
      case 'SN': return l.countrySN;
      case 'ZW': return l.countryZW;
      case 'MZ': return l.countryMZ;
      case 'MG': return l.countryMG;
      case 'GT': return l.countryGT;
      case 'HN': return l.countryHN;
      case 'NI': return l.countryNI;
      case 'SV': return l.countrySV;
      case 'PR': return l.countryPR;
      default: return name;
    }
  }

  static const List<RadioCountry> supported = [
    // ── ASIA ──
    RadioCountry(code: 'KR', name: '한국', flag: '🇰🇷', continent: 'ASIA', broadcasters: [
      RadioBroadcaster(id: 'KBS', name: 'KBS', keyword: 'KBS', category: '전국'),
      RadioBroadcaster(id: 'MBC', name: 'MBC', keyword: 'MBC', category: '전국'),
      RadioBroadcaster(id: 'SBS', name: 'SBS', keyword: 'SBS', category: '전국'),
      RadioBroadcaster(id: 'CBS', name: 'CBS', keyword: 'CBS', category: '전국'),
      RadioBroadcaster(id: 'EBS', name: 'EBS', keyword: 'EBS', category: '전국'),
      RadioBroadcaster(id: 'YTN', name: 'YTN', keyword: 'YTN', category: '전국'),
      RadioBroadcaster(id: 'TBS', name: 'TBS 서울', keyword: 'TBS', category: '서울/경기'),
      RadioBroadcaster(id: 'OBS', name: 'OBS 경인', keyword: 'OBS', category: '서울/경기'),
      RadioBroadcaster(id: 'IFM', name: '경인방송', keyword: '경인방송', category: '서울/경기'),
      RadioBroadcaster(id: 'MBC_CB', name: 'MBC충북', keyword: 'MBC충북', category: '지역 MBC'),
      RadioBroadcaster(id: 'MBC_AD', name: '안동MBC', keyword: '안동MBC', category: '지역 MBC'),
      RadioBroadcaster(id: 'JTV', name: 'JTV 전주', keyword: 'JTV', category: '지역 민방'),
      RadioBroadcaster(id: 'TBN', name: 'TBN 경인', keyword: 'TBN 교통', category: '교통방송'),
      RadioBroadcaster(id: 'TBN_UL', name: 'TBN 울산', keyword: 'TBN 울산', category: '교통방송'),
      RadioBroadcaster(id: 'GUGAK', name: '국악FM', keyword: 'gukak', category: '기타'),
      RadioBroadcaster(id: 'GBFM', name: '국방FM', keyword: '국방FM', category: '기타'),
      RadioBroadcaster(id: 'CPBC', name: 'CPBC 가톨릭', keyword: 'CPBC', category: '기타'),
      RadioBroadcaster(id: 'BEFM', name: 'BeFM 부산', keyword: 'befm', category: '기타'),
      RadioBroadcaster(id: 'ARIRANG', name: 'Arirang Radio', keyword: 'Arirang', category: '기타'),
      RadioBroadcaster(id: 'KPOP', name: 'K-Pop Radio', keyword: 'kpop', category: '기타'),
      RadioBroadcaster(id: 'OLDPOP', name: '올드팝카페', keyword: 'oldpop', category: '기타'),
      RadioBroadcaster(id: 'CLASSIC', name: 'Classic Odyssey', keyword: 'Classic Odyssey', category: '기타'),
      RadioBroadcaster(id: 'MAPOFM', name: '마포FM', keyword: '마포FM', category: '기타'),
      RadioBroadcaster(id: 'AFN', name: 'AFN Korea', keyword: 'AFN', category: '기타'),
    ]),
    RadioCountry(code: 'JP', name: '일본', flag: '🇯🇵', continent: 'ASIA', broadcasters: [
      RadioBroadcaster(id: 'NHK', name: 'NHK', keyword: 'NHK'),
      RadioBroadcaster(id: 'JWAVE', name: 'J-WAVE', keyword: 'J-WAVE'),
      RadioBroadcaster(id: 'FM802', name: 'FM802', keyword: 'FM802'),
      RadioBroadcaster(id: 'TBSjp', name: 'TBS Radio', keyword: 'TBS Radio Japan'),
      RadioBroadcaster(id: 'TOKYOFM', name: 'Tokyo FM', keyword: 'Tokyo FM'),
      RadioBroadcaster(id: 'BAYFM', name: 'Bay FM', keyword: 'Bay FM'),
    ]),
    RadioCountry(code: 'TW', name: '대만', flag: '🇹🇼', continent: 'ASIA', broadcasters: [
      RadioBroadcaster(id: 'RTI', name: 'RTI', keyword: 'RTI'),
      RadioBroadcaster(id: 'ICRT', name: 'ICRT', keyword: 'ICRT'),
      RadioBroadcaster(id: 'BCC', name: 'BCC', keyword: 'BCC Taiwan'),
    ]),
    RadioCountry(code: 'CN', name: '중국', flag: '🇨🇳', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'HK', name: '홍콩', flag: '🇭🇰', continent: 'ASIA', broadcasters: [
      RadioBroadcaster(id: 'RTHK', name: 'RTHK', keyword: 'RTHK'),
      RadioBroadcaster(id: 'CRHK', name: 'Commercial Radio', keyword: 'Commercial Radio HK'),
    ]),
    RadioCountry(code: 'VN', name: '베트남', flag: '🇻🇳', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'PH', name: '필리핀', flag: '🇵🇭', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'TH', name: '태국', flag: '🇹🇭', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'ID', name: '인도네시아', flag: '🇮🇩', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'IN', name: '인도', flag: '🇮🇳', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'MY', name: '말레이시아', flag: '🇲🇾', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'SG', name: '싱가포르', flag: '🇸🇬', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'PK', name: '파키스탄', flag: '🇵🇰', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'BD', name: '방글라데시', flag: '🇧🇩', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'LK', name: '스리랑카', flag: '🇱🇰', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'NP', name: '네팔', flag: '🇳🇵', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'MM', name: '미얀마', flag: '🇲🇲', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'KH', name: '캄보디아', flag: '🇰🇭', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'MN', name: '몽골', flag: '🇲🇳', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'UZ', name: '우즈베키스탄', flag: '🇺🇿', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'KZ', name: '카자흐스탄', flag: '🇰🇿', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'LA', name: '라오스', flag: '🇱🇦', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'GE', name: '조지아', flag: '🇬🇪', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'AM', name: '아르메니아', flag: '🇦🇲', continent: 'ASIA', broadcasters: []),
    RadioCountry(code: 'AZ', name: '아제르바이잔', flag: '🇦🇿', continent: 'ASIA', broadcasters: []),
    // ── EUROPE ──
    RadioCountry(code: 'GB', name: '영국', flag: '🇬🇧', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'DE', name: '독일', flag: '🇩🇪', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'FR', name: '프랑스', flag: '🇫🇷', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'ES', name: '스페인', flag: '🇪🇸', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'IT', name: '이탈리아', flag: '🇮🇹', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'NL', name: '네덜란드', flag: '🇳🇱', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'SE', name: '스웨덴', flag: '🇸🇪', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'PL', name: '폴란드', flag: '🇵🇱', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'RU', name: '러시아', flag: '🇷🇺', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'AT', name: '오스트리아', flag: '🇦🇹', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'CH', name: '스위스', flag: '🇨🇭', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'BE', name: '벨기에', flag: '🇧🇪', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'PT', name: '포르투갈', flag: '🇵🇹', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'GR', name: '그리스', flag: '🇬🇷', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'IE', name: '아일랜드', flag: '🇮🇪', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'NO', name: '노르웨이', flag: '🇳🇴', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'DK', name: '덴마크', flag: '🇩🇰', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'FI', name: '핀란드', flag: '🇫🇮', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'CZ', name: '체코', flag: '🇨🇿', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'RO', name: '루마니아', flag: '🇷🇴', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'UA', name: '우크라이나', flag: '🇺🇦', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'HU', name: '헝가리', flag: '🇭🇺', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'HR', name: '크로아티아', flag: '🇭🇷', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'RS', name: '세르비아', flag: '🇷🇸', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'BG', name: '불가리아', flag: '🇧🇬', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'SK', name: '슬로바키아', flag: '🇸🇰', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'LT', name: '리투아니아', flag: '🇱🇹', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'LV', name: '라트비아', flag: '🇱🇻', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'EE', name: '에스토니아', flag: '🇪🇪', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'IS', name: '아이슬란드', flag: '🇮🇸', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'SI', name: '슬로베니아', flag: '🇸🇮', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'AL', name: '알바니아', flag: '🇦🇱', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'MK', name: '북마케도니아', flag: '🇲🇰', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'ME', name: '몬테네그로', flag: '🇲🇪', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'BA', name: '보스니아', flag: '🇧🇦', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'MT', name: '몰타', flag: '🇲🇹', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'LU', name: '룩셈부르크', flag: '🇱🇺', continent: 'EUROPE', broadcasters: []),
    RadioCountry(code: 'CY', name: '키프로스', flag: '🇨🇾', continent: 'EUROPE', broadcasters: []),
    // ── NORTH AMERICA ──
    RadioCountry(code: 'US', name: '미국', flag: '🇺🇸', continent: 'NORTH_AMERICA', broadcasters: [
      RadioBroadcaster(id: 'NPR', name: 'NPR', keyword: 'NPR'),
      RadioBroadcaster(id: 'ESPN', name: 'ESPN Radio', keyword: 'ESPN Radio'),
      RadioBroadcaster(id: 'BBC', name: 'BBC', keyword: 'BBC World Service'),
      RadioBroadcaster(id: 'VOA', name: 'VOA', keyword: 'Voice of America'),
      RadioBroadcaster(id: 'CNN', name: 'CNN Radio', keyword: 'CNN'),
      RadioBroadcaster(id: 'FOX', name: 'Fox News', keyword: 'Fox News'),
      RadioBroadcaster(id: 'JAZZ', name: 'Jazz Radio', keyword: 'Jazz'),
      RadioBroadcaster(id: 'CLASSI', name: 'Classical', keyword: 'Classical'),
    ]),
    RadioCountry(code: 'CA', name: '캐나다', flag: '🇨🇦', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'MX', name: '멕시코', flag: '🇲🇽', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'CU', name: '쿠바', flag: '🇨🇺', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'JM', name: '자메이카', flag: '🇯🇲', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'DO', name: '도미니카공화국', flag: '🇩🇴', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'TT', name: '트리니다드토바고', flag: '🇹🇹', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'HT', name: '아이티', flag: '🇭🇹', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'GT', name: '과테말라', flag: '🇬🇹', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'HN', name: '온두라스', flag: '🇭🇳', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'NI', name: '니카라과', flag: '🇳🇮', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'SV', name: '엘살바도르', flag: '🇸🇻', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'PA', name: '파나마', flag: '🇵🇦', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'CR', name: '코스타리카', flag: '🇨🇷', continent: 'NORTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'PR', name: '푸에르토리코', flag: '🇵🇷', continent: 'NORTH_AMERICA', broadcasters: []),
    // ── SOUTH AMERICA ──
    RadioCountry(code: 'BR', name: '브라질', flag: '🇧🇷', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'AR', name: '아르헨티나', flag: '🇦🇷', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'CO', name: '콜롬비아', flag: '🇨🇴', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'CL', name: '칠레', flag: '🇨🇱', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'PE', name: '페루', flag: '🇵🇪', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'VE', name: '베네수엘라', flag: '🇻🇪', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'EC', name: '에콰도르', flag: '🇪🇨', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'BO', name: '볼리비아', flag: '🇧🇴', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'PY', name: '파라과이', flag: '🇵🇾', continent: 'SOUTH_AMERICA', broadcasters: []),
    RadioCountry(code: 'UY', name: '우루과이', flag: '🇺🇾', continent: 'SOUTH_AMERICA', broadcasters: []),
    // ── MIDDLE EAST ──
    RadioCountry(code: 'TR', name: '터키', flag: '🇹🇷', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'SA', name: '사우디아라비아', flag: '🇸🇦', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'AE', name: 'UAE', flag: '🇦🇪', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'IQ', name: '이라크', flag: '🇮🇶', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'IR', name: '이란', flag: '🇮🇷', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'IL', name: '이스라엘', flag: '🇮🇱', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'EG', name: '이집트', flag: '🇪🇬', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'JO', name: '요르단', flag: '🇯🇴', continent: 'MIDDLE_EAST', broadcasters: []),
    RadioCountry(code: 'LB', name: '레바논', flag: '🇱🇧', continent: 'MIDDLE_EAST', broadcasters: []),
    // ── AFRICA ──
    RadioCountry(code: 'ZA', name: '남아프리카', flag: '🇿🇦', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'NG', name: '나이지리아', flag: '🇳🇬', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'KE', name: '케냐', flag: '🇰🇪', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'GH', name: '가나', flag: '🇬🇭', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'TZ', name: '탄자니아', flag: '🇹🇿', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'MA', name: '모로코', flag: '🇲🇦', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'TN', name: '튀니지', flag: '🇹🇳', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'ET', name: '에티오피아', flag: '🇪🇹', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'UG', name: '우간다', flag: '🇺🇬', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'CM', name: '카메룬', flag: '🇨🇲', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'SN', name: '세네갈', flag: '🇸🇳', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'ZW', name: '짐바브웨', flag: '🇿🇼', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'MZ', name: '모잠비크', flag: '🇲🇿', continent: 'AFRICA', broadcasters: []),
    RadioCountry(code: 'MG', name: '마다가스카르', flag: '🇲🇬', continent: 'AFRICA', broadcasters: []),
    // ── OCEANIA ──
    RadioCountry(code: 'AU', name: '호주', flag: '🇦🇺', continent: 'OCEANIA', broadcasters: []),
    RadioCountry(code: 'NZ', name: '뉴질랜드', flag: '🇳🇿', continent: 'OCEANIA', broadcasters: []),
    RadioCountry(code: 'FJ', name: '피지', flag: '🇫🇯', continent: 'OCEANIA', broadcasters: []),
    RadioCountry(code: 'PG', name: '파푸아뉴기니', flag: '🇵🇬', continent: 'OCEANIA', broadcasters: []),
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

  String get displayCategory {
    final l = AppLocale.current;
    if (l == null) return category;
    switch (category) {
      case '전국': return l.categoryNational;
      case '서울/경기': return l.categorySeoulGyeonggi;
      case '지역 MBC': return l.categoryRegionalMBC;
      case '지역 민방': return l.categoryRegionalPrivate;
      case '교통방송': return l.categoryTraffic;
      case '기타': return l.categoryEtc;
      default: return category;
    }
  }
}