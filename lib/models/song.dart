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
    final names = _genreNames[k.substring(1)];
    if (names == null) return k.substring(1);
    return names[_genreLangIndex()];
  }

  /// 장르 글자(파일에 적힌 것·고른 것) → 화면에 보일 이름 ('' = 장르 없음)
  static String genreNameOf(String raw) {
    final k = _cleanGenre(raw);
    if (k.isEmpty || !k.startsWith('@')) return k;
    final names = _genreNames[k.substring(1)];
    return names == null ? k.substring(1) : names[_genreLangIndex()];
  }

  /// 고르는 창에 보여 줄 많이 쓰는 장르 ('@ballad' …)
  static List<String> get commonGenres => [for (final k in _genreNames.keys) '@$k'];

  /// 폰 언어 칸 번호 (다른 화면에서 5개 언어 글자 고를 때)
  static int langIndex() => _genreLangIndex();

  /// 폰 언어 → 이름 칸 번호 (0 한국어 · 1 영어 · 2 일본어 · 3 번체 · 4 간체)
  static int _genreLangIndex() {
    final n = AppLocale.current?.localeName ?? 'ko';
    if (n.startsWith('ko')) return 0;
    if (n.startsWith('ja')) return 2;
    if (n.startsWith('zh')) {
      return (n.contains('Hant') || n.contains('TW') || n.contains('HK')) ? 3 : 4;
    }
    return 1; // 영어 및 그 밖의 언어
  }

  // 많이 쓰는 장르: 이름 [한국어, 영어, 일본어, 번체, 간체]
  static const _genreNames = <String, List<String>>{
    'ballad': ['발라드', 'Ballad', 'バラード', '抒情', '抒情'],
    'dance': ['댄스', 'Dance', 'ダンス', '舞曲', '舞曲'],
    'pop': ['팝', 'Pop', 'ポップス', '流行', '流行'],
    'kpop': ['K-Pop', 'K-Pop', 'K-POP', 'K-Pop', 'K-Pop'],
    'jpop': ['J-Pop', 'J-Pop', 'J-POP', 'J-Pop', 'J-Pop'],
    'cpop': ['C-Pop', 'C-Pop', 'C-POP', '華語流行', '华语流行'],
    'rock': ['록', 'Rock', 'ロック', '搖滾', '摇滚'],
    'metal': ['메탈', 'Metal', 'メタル', '金屬', '金属'],
    'hiphop': ['힙합', 'Hip-Hop', 'ヒップホップ', '嘻哈', '嘻哈'],
    'rnb': ['R&B', 'R&B', 'R&B', 'R&B', 'R&B'],
    'jazz': ['재즈', 'Jazz', 'ジャズ', '爵士', '爵士'],
    'classical': ['클래식', 'Classical', 'クラシック', '古典', '古典'],
    'ost': ['OST', 'Soundtrack', 'サウンドトラック', '原聲帶', '原声带'],
    'trot': ['트로트', 'Trot', 'トロット', 'Trot', 'Trot'],
    'enka': ['엔카', 'Enka', '演歌', '演歌', '演歌'],
    'indie': ['인디', 'Indie', 'インディーズ', '獨立', '独立'],
    'electronic': ['일렉트로닉', 'Electronic', 'エレクトロニカ', '電子', '电子'],
    'folk': ['포크', 'Folk', 'フォーク', '民謠', '民谣'],
    'blues': ['블루스', 'Blues', 'ブルース', '藍調', '蓝调'],
    'country': ['컨트리', 'Country', 'カントリー', '鄉村', '乡村'],
    'reggae': ['레게', 'Reggae', 'レゲエ', '雷鬼', '雷鬼'],
    'newage': ['뉴에이지', 'New Age', 'ニューエイジ', '新世紀', '新世纪'],
    'anime': ['애니메이션', 'Anime', 'アニメ', '動漫', '动漫'],
    'kids': ['동요', 'Kids', '童謡', '童謠', '童谣'],
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
  };

  static String _cleanGenre(String raw) {
    var g = raw.trim();
    if (g.isEmpty) return '';
    // 고르는 창에서 고른 장르 ('@ballad')는 그대로
    if (g.startsWith('@') && _genreNames.containsKey(g.substring(1))) return g;
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