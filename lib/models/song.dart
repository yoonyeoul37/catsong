import '../l10n/locale_holder.dart';

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
  String genre = ''; // 노래 파일에 적힌 장르 (그대로)

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

  String get artistDisplay {
    if (artist.isNotEmpty && artist != '<unknown>') return artist;
    return AppLocale.current?.unknownArtist ?? '알 수 없는 아티스트';
  }

  String get albumDisplay {
    if (album.isNotEmpty && album != '<unknown>') return album;
    return AppLocale.current?.unknownAlbum ?? '알 수 없는 앨범';
  }

  String get titleDisplay {
    if (title.isNotEmpty) return title;
    return AppLocale.current?.noTitle ?? '제목 없음';
  }

  // ───── 장르 ─────
  String? _genreFrom;
  String _genreKeyCache = '';

  /// 묶을 때 쓰는 장르 ('' = 장르 없음 → 기타)
  /// 많이 쓰는 장르는 '@ballad'처럼 공통 이름으로 → 발라드·Ballad·バラード가 하나로 묶임
  String get genreKey {
    if (_genreFrom != genre) {
      _genreFrom = genre;
      _genreKeyCache = _cleanGenre(genre);
    }
    return _genreKeyCache;
  }

  /// 화면에 보이는 장르 이름: 많이 쓰는 장르는 폰 언어로, 나머지는 파일에 적힌 그대로, 없으면 '기타'
  String get genreDisplay {
    final k = genreKey;
    if (k.isEmpty) return AppLocale.current?.categoryEtc ?? '기타';
    if (!k.startsWith('@')) return k;
    return _genreName(k.substring(1)) ?? k.substring(1);
  }

  /// 장르 글자(파일에 적힌 것·고른 것) → 화면에 보일 이름 ('' = 장르 없음)
  static String genreNameOf(String raw) {
    final k = _cleanGenre(raw);
    if (k.isEmpty || !k.startsWith('@')) return k;
    return _genreName(k.substring(1)) ?? k.substring(1);
  }

  /// 고르는 창에 보여 줄 많이 쓰는 장르 ('@ballad' …)
  static List<String> get commonGenres => [for (final k in _genreKeys) '@$k'];


  // 많이 쓰는 장르: 공통 이름 → 화면 이름은 번역 파일 (songGenre…)
  static const _genreKeys = [
    'ballad',
    'dance',
    'pop',
    'kpop',
    'jpop',
    'cpop',
    'rock',
    'metal',
    'hiphop',
    'rnb',
    'jazz',
    'classical',
    'ost',
    'trot',
    'enka',
    'indie',
    'electronic',
    'folk',
    'blues',
    'country',
    'reggae',
    'newage',
    'anime',
    'kids',
  ];

  static String? _genreName(String k) => switch (k) {
        'ballad' => tr.songGenreBallad,
        'dance' => tr.songGenreDance,
        'pop' => tr.songGenrePop,
        'kpop' => tr.songGenreKpop,
        'jpop' => tr.songGenreJpop,
        'cpop' => tr.songGenreCpop,
        'rock' => tr.songGenreRock,
        'metal' => tr.songGenreMetal,
        'hiphop' => tr.songGenreHiphop,
        'rnb' => tr.songGenreRnb,
        'jazz' => tr.songGenreJazz,
        'classical' => tr.songGenreClassical,
        'ost' => tr.songGenreOst,
        'trot' => tr.songGenreTrot,
        'enka' => tr.songGenreEnka,
        'indie' => tr.songGenreIndie,
        'electronic' => tr.songGenreElectronic,
        'folk' => tr.songGenreFolk,
        'blues' => tr.songGenreBlues,
        'country' => tr.songGenreCountry,
        'reggae' => tr.songGenreReggae,
        'newage' => tr.songGenreNewage,
        'anime' => tr.songGenreAnime,
        'kids' => tr.songGenreKids,
        _ => null,
      };

  // 파일에 적힌 말(공백·-·_·. 빼고 소문자) → 공통 장르
  static const _genreAlias = <String, String>{
    // 발라드
    '발라드': 'ballad', '국내발라드': 'ballad', '해외발라드': 'ballad', 'ballad': 'ballad', 'ballads': 'ballad',
    'バラード': 'ballad', '抒情': 'ballad', '抒情歌': 'ballad',
    // 댄스
    '댄스': 'dance', '국내댄스': 'dance', '해외댄스': 'dance', 'dance': 'dance', 'ダンス': 'dance', '舞曲': 'dance',
    '댄스/일렉': 'dance',
    // 팝
    'pop': 'pop', '팝': 'pop', '해외팝': 'pop', 'pops': 'pop', 'ポップ': 'pop', 'ポップス': 'pop',
    '流行': 'pop', '流行音樂': 'pop', '流行音乐': 'pop',
    // K-Pop · J-Pop · C-Pop
    'kpop': 'kpop', 'koreanpop': 'kpop', '가요': 'kpop', '국내가요': 'kpop', '케이팝': 'kpop', 'kポップ': 'kpop',
    'jpop': 'jpop', 'japanesepop': 'jpop', 'jポップ': 'jpop', '제이팝': 'jpop',
    'cpop': 'cpop', 'mandopop': 'cpop', 'chinesepop': 'cpop', '華語流行': 'cpop', '华语流行': 'cpop',
    '國語流行': 'cpop', '国语流行': 'cpop', '華語': 'cpop', '华语': 'cpop',
    // 록 · 메탈
    'rock': 'rock', '록': 'rock', '락': 'rock', '록/메탈': 'rock', 'ロック': 'rock', '搖滾': 'rock', '摇滚': 'rock',
    'metal': 'metal', 'heavymetal': 'metal', '메탈': 'metal', 'メタル': 'metal', '金屬': 'metal', '金属': 'metal',
    // 힙합
    'hiphop': 'hiphop', 'rap': 'hiphop', 'rap/hiphop': 'hiphop', 'hiphop/rap': 'hiphop', '힙합': 'hiphop',
    '랩': 'hiphop', '랩/힙합': 'hiphop', 'ヒップホップ': 'hiphop', 'ラップ': 'hiphop', '嘻哈': 'hiphop',
    '說唱': 'hiphop', '说唱': 'hiphop',
    // R&B
    'rnb': 'rnb', 'r&b': 'rnb', 'randb': 'rnb', 'r&b/soul': 'rnb', 'rnb/soul': 'rnb', 'soul': 'rnb',
    '알앤비': 'rnb', '알앤비/소울': 'rnb', '소울': 'rnb', 'r&b/소울': 'rnb', 'ソウル': 'rnb',
    // 재즈 · 클래식
    'jazz': 'jazz', '재즈': 'jazz', 'ジャズ': 'jazz', '爵士': 'jazz', '爵士樂': 'jazz', '爵士乐': 'jazz',
    'classical': 'classical', 'classic': 'classical', '클래식': 'classical', 'クラシック': 'classical',
    '古典': 'classical', '古典音樂': 'classical', '古典音乐': 'classical',
    // OST
    'ost': 'ost', 'soundtrack': 'ost', 'soundtracks': 'ost', '영화음악': 'ost', '드라마음악': 'ost',
    '국내드라마': 'ost', 'サウンドトラック': 'ost', 'サントラ': 'ost', '原聲帶': 'ost', '原声带': 'ost',
    // 트로트 · 엔카
    '트로트': 'trot', 'trot': 'trot', '성인가요': 'trot', '성인가요/트로트': 'trot', 'トロット': 'trot',
    'enka': 'enka', '演歌': 'enka', '엔카': 'enka',
    // 인디 · 일렉트로닉
    'indie': 'indie', '인디': 'indie', '인디음악': 'indie', 'インディーズ': 'indie', '獨立': 'indie',
    '独立': 'indie', '獨立音樂': 'indie', '独立音乐': 'indie',
    'electronic': 'electronic', 'electronica': 'electronic', 'edm': 'electronic', '일렉트로닉': 'electronic',
    '일렉트로니카': 'electronic', '일렉': 'electronic', 'エレクトロニカ': 'electronic', 'エレクトロ': 'electronic',
    '電子': 'electronic', '电子': 'electronic', '電子音樂': 'electronic', '电子音乐': 'electronic',
    // 포크 · 블루스 · 컨트리 · 레게
    'folk': 'folk', '포크': 'folk', '포크/블루스': 'folk', 'フォーク': 'folk', '民謠': 'folk', '民谣': 'folk',
    'blues': 'blues', '블루스': 'blues', 'ブルース': 'blues', '藍調': 'blues', '蓝调': 'blues',
    'country': 'country', '컨트리': 'country', 'カントリー': 'country', '鄉村': 'country', '乡村': 'country',
    'reggae': 'reggae', '레게': 'reggae', 'レゲエ': 'reggae', '雷鬼': 'reggae',
    // 뉴에이지 · 애니 · 동요
    'newage': 'newage', '뉴에이지': 'newage', 'ニューエイジ': 'newage', '新世紀': 'newage', '新世纪': 'newage',
    'anime': 'anime', '애니메이션': 'anime', '애니': 'anime', 'アニメ': 'anime', 'アニソン': 'anime',
    '動漫': 'anime', '动漫': 'anime',
    'kids': 'kids', 'children': 'kids', "children's": 'kids', '동요': 'kids', '童謡': 'kids', '童謠': 'kids',
    '童谣': 'kids',
    // 새 언어 7개 (독일어·프랑스어·스페인어·포르투갈어·인도네시아어·베트남어·태국어)
    'ballade': 'ballad', 'balladen': 'ballad', 'balada': 'ballad', 'baladas': 'ballad', 'baladaromántica': 'ballad', 'trữtình': 'ballad', 'nhạctrữtình': 'ballad', 'เพลงช้า': 'ballad',
    'tanz': 'dance', 'tanzmusik': 'dance', 'danse': 'dance', 'baile': 'dance', 'dança': 'dance', 'dansa': 'dance', 'nhạcdance': 'dance', 'แดนซ์': 'dance',
    'popmusik': 'pop', 'musiquepop': 'pop', 'músicapop': 'pop', 'nhạcpop': 'pop', 'vpop': 'pop', 'ป๊อป': 'pop', 'เพลงป๊อป': 'pop', 'ป็อป': 'pop', 'tpop': 'pop', 'thaipop': 'pop', 'opm': 'pop', 'popindonesia': 'pop', 'mpb': 'pop',
    'rockmusik': 'rock', 'nhạcrock': 'rock', 'ร็อก': 'rock', 'ร็อค': 'rock',
    'เมทัล': 'metal',
    'raplatino': 'hiphop', 'rapfrançais': 'hiphop', 'raplatinoamericano': 'hiphop', 'ฮิปฮอป': 'hiphop', 'แร็พ': 'hiphop',
    'อาร์แอนด์บี': 'rnb',
    'แจ๊ส': 'jazz', 'nhạcjazz': 'jazz',
    'klassik': 'classical', 'klassischemusik': 'classical', 'klassisch': 'classical', 'classique': 'classical', 'musiqueclassique': 'classical', 'clásica': 'classical', 'clasica': 'classical', 'músicaclásica': 'classical', 'clássica': 'classical', 'classica': 'classical', 'músicaclássica': 'classical', 'erudita': 'classical', 'klasik': 'classical', 'musikklasik': 'classical', 'cổđiển': 'classical', 'nhạccổđiển': 'classical', 'คลาสสิก': 'classical', 'คลาสสิค': 'classical', 'เพลงคลาสสิก': 'classical',
    'filmmusik': 'ost', 'bandeoriginale': 'ost', 'musiquedefilm': 'ost', 'bandasonora': 'ost', 'trilhasonora': 'ost', 'nhạcphim': 'ost', 'เพลงประกอบภาพยนตร์': 'ost', 'เพลงประกอบละคร': 'ost',
    'elektronisch': 'electronic', 'elektronischemusik': 'electronic', 'électronique': 'electronic', 'electronique': 'electronic', 'electrónica': 'electronic', 'eletrônica': 'electronic', 'eletronica': 'electronic', 'elektronik': 'electronic', 'nhạcđiệntử': 'electronic', 'điệntử': 'electronic', 'อิเล็กทรอนิกส์': 'electronic',
    'volksmusik': 'folk', 'musiquefolk': 'folk', 'folclore': 'folk', 'folklore': 'folk', 'dângca': 'folk', 'nhạcdângca': 'folk', 'ลูกทุ่ง': 'folk', 'ลูกกรุง': 'folk', 'หมอลำ': 'folk',
    'บลูส์': 'blues',
    'sertanejo': 'country', 'คันทรี': 'country',
    'เร็กเก้': 'reggae',
    'อินดี้': 'indie',
    'kinderlieder': 'kids', 'kindermusik': 'kids', 'kinder': 'kids', 'enfants': 'kids', 'musiquepourenfants': 'kids', 'infantil': 'kids', 'músicainfantil': 'kids', 'anak': 'kids', 'laguanak': 'kids', 'thiếunhi': 'kids', 'nhạcthiếunhi': 'kids', 'เพลงเด็ก': 'kids',
    // 새 언어 4개 (러시아어·이탈리아어·튀르키예어·폴란드어)
    'поп': 'pop', 'попмузыка': 'pop', 'эстрада': 'pop', 'рок': 'rock', 'хардрок': 'rock', 'метал': 'metal', 'хипхоп': 'hiphop', 'рэп': 'hiphop',
    'джаз': 'jazz', 'блюз': 'blues', 'классика': 'classical', 'классическаямузыка': 'classical', 'саундтрек': 'ost', 'музыкакфильму': 'ost', 'электроника': 'electronic', 'электронная': 'electronic',
    'электроннаямузыка': 'electronic', 'фолк': 'folk', 'народная': 'folk', 'народнаямузыка': 'folk', 'кантри': 'country', 'регги': 'reggae', 'инди': 'indie', 'ньюэйдж': 'newage',
    'аниме': 'anime', 'детские': 'kids', 'детскиепесни': 'kids', 'детская': 'kids', 'баллада': 'ballad', 'танцевальная': 'dance', 'musicaclassica': 'classical', 'musicasinfonica': 'classical',
    'lirica': 'classical', 'colonnasonora': 'ost', 'colonnesonore': 'ost', 'musicadafilm': 'ost', 'elettronica': 'electronic', 'musicaelettronica': 'electronic', 'cantautori': 'folk', 'cantautore': 'folk',
    'musicapopolare': 'folk', 'musicatradizionale': 'folk', 'canzoniperbambini': 'kids', 'musicaperbambini': 'kids', 'bambini': 'kids', 'cartonianimati': 'anime', 'ballata': 'ballad', 'ballate': 'ballad',
    'danza': 'dance', 'rockitaliano': 'rock', 'popitaliano': 'pop', 'musicaleggera': 'pop', 'rapitaliano': 'hiphop', 'musicaindipendente': 'indie', 'indipendente': 'indie', 'türkpop': 'pop',
    'türkçepop': 'pop', 'türkçerock': 'rock', 'anadolurock': 'rock', 'türkçerap': 'hiphop', 'arabesk': 'folk', 'türkü': 'folk', 'türküler': 'folk', 'halkmüziği': 'folk',
    'türkhalkmüziği': 'folk', 'klasikmüzik': 'classical', 'elektronikmüzik': 'electronic', 'filmmüziği': 'ost', 'dizimüziği': 'ost', 'çocuk': 'kids', 'çocukşarkıları': 'kids', 'çocukşarkilari': 'kids',
    'caz': 'jazz', 'dans': 'dance', 'muzykaklasyczna': 'classical', 'klasyczna': 'classical', 'klasyka': 'classical', 'muzykapoważna': 'classical', 'muzykaelektroniczna': 'electronic', 'elektroniczna': 'electronic',
    'elektronika': 'electronic', 'ścieżkadźwiękowa': 'ost', 'muzykafilmowa': 'ost', 'discopolo': 'dance', 'taneczna': 'dance', 'muzykataneczna': 'dance', 'piosenkidladzieci': 'kids', 'muzykadladzieci': 'kids',
    'dladzieci': 'kids', 'ludowa': 'folk', 'muzykaludowa': 'folk', 'poezjaśpiewana': 'folk', 'szanty': 'folk', 'ballada': 'ballad', 'ballady': 'ballad',
    // 인터넷 검색(디저)에서 오는 이름
    'films/games': 'ost', 'filmscores': 'ost', 'electro': 'electronic',
  };

  // ID3 번호 장르 (예: '(13)' → Pop)
  static const _id3 = {
    0: 'Blues', 1: 'Classic Rock', 2: 'Country', 3: 'Dance', 4: 'Disco', 5: 'Funk',
    7: 'Hip-Hop', 8: 'Jazz', 9: 'Metal', 10: 'New Age', 11: 'Oldies', 13: 'Pop',
    14: 'R&B', 15: 'Rap', 16: 'Reggae', 17: 'Rock', 18: 'Techno', 20: 'Alternative',
    24: 'Soundtrack', 26: 'Ambient', 28: 'Vocal', 32: 'Classical', 33: 'Instrumental',
    35: 'House', 52: 'Electronic', 98: 'Easy Listening',
  };
  static const _none = {
    '', 'unknown', '<unknown>', 'other', 'others', 'genre', 'none', 'unknowngenre', '기타',
    'music', 'musica', 'misc', 'miscellaneous', 'various', 'etc',
    '음악', '音楽', '音樂', '音乐', 'その他', '其他',
    'sonstige', 'sonstiges', 'andere', 'divers', 'autre', 'autres', 'otros', 'otro', 'outros', 'outro', 'lainnya', 'khác', 'อื่นๆ', 'musik', 'musique', 'música', 'nhạc', 'เพลง',
    'другое', 'прочее', 'разное', 'музыка', 'неизвестно', 'неизвестный', 'безжанра', 'altro', 'altri', 'altre', 'sconosciuto', 'sconosciuta', 'generesconosciuto', 'varie', 'vari', 'nessuno', 'senzagenere', 'diğer', 'bilinmiyor', 'bilinmeyen', 'müzik', 'tanımsız', 'belirsiz', 'inne', 'inny', 'nieznany', 'nieznane', 'nieznana', 'muzyka', 'brak', 'różne',
  };

  static String _cleanGenre(String raw) {
    var g = raw.trim();
    if (g.isEmpty) return '';
    // 고르는 창에서 고른 장르 ('@ballad')는 그대로
    if (g.startsWith('@') && _genreKeys.contains(g.substring(1))) return g;
    // 여러 장르가 같이 적혀 있으면 첫 번째만 (Pop; Dance)
    // ('/'로는 안 나눔: 랩/힙합 · 록/메탈 · R&B/Soul 같은 장르 이름이 많아서)
    g = g.split(RegExp(r'[;,|]')).first.trim();
    // ID3 번호: (13) 또는 13
    final m = RegExp(r'^\((\d+)\)(.*)$').firstMatch(g);
    if (m != null) {
      final rest = m.group(2)!.trim();
      g = rest.isNotEmpty ? rest : (_id3[int.parse(m.group(1)!)] ?? '');
    } else if (RegExp(r'^\d+$').hasMatch(g)) {
      g = _id3[int.parse(g)] ?? '';
    }
    final low = g.toLowerCase().replaceAll(RegExp(r'[\s\-_.]'), '');
    if (_none.contains(low)) return '';
    final alias = _genreAlias[low];
    if (alias != null) return '@$alias'; // 많이 쓰는 장르 → 폰 언어로 보여 줌
    // 목록에 없는 영어 장르는 대소문자만 다른 것도 같게 (POP, pop → Pop)
    if (RegExp(r'^[A-Za-z ]+$').hasMatch(g)) {
      return g
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }
    return g;
  }

  @override
  bool operator ==(Object other) => other is Song && id == other.id;

  @override
  int get hashCode => id.hashCode;
}