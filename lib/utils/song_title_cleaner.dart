/// 유튜브 등에서 받은 노래의 뒤죽박죽 제목·가수를 깨끗하게 정리
/// 예) "아이유(IU) - 좋은 날 [MV]" · "1theK (원더케이)"  →  "좋은 날" · "아이유(IU)"
class SongClean {
  final String title;
  final String artist;
  const SongClean(this.title, this.artist);
}

class SongTitleCleaner {
  // 괄호 안에 있으면 지울 군더더기 (뮤비·가사·화질 등)
  static final _junk = RegExp(
    r'(\b(official|m/?v|music\s*video|video|audio|lyrics?|visuali[sz]er|teaser|performance|dance\s*practice|full\s*album|hd|hq|4k|\d{3,4}p|color\s*coded|eng\s*sub|kor\s*sub|sub)\b|가사|자막|듣기|고음질|음원|공식)',
    caseSensitive: false,
  );

  // 괄호 안에 있어도 남길 것 (다른 버전이라 의미 있음)
  static final _keep = RegExp(
    r'(\b(feat|ft|with|live|remix|ver|version|acoustic|inst|instrumental|cover|prod|sped\s*up|slowed)\b|피처링|라이브|리믹스|버전)',
    caseSensitive: false,
  );

  // 진짜 가수가 아니라 유튜브 채널 이름인 것들
  static final _channel = RegExp(
    r'(\b(1thek|smtown|hybe|jyp|yg\s*entertainment|stone\s*music|mnet|kbs\s*kpop|mbckpop|mbc\s*kpop|genie\s*music|kakao\s*entertainment|dingo|bangtantv|big\s*hit|starship|warner\s*music|sony\s*music|universal\s*music|vevo|m2|entertainment|records|label|labels)\b|원더케이|딩고|지니뮤직)',
    caseSensitive: false,
  );

  static bool _looksUnknown(String a) {
    final l = a.toLowerCase().trim();
    return a.isEmpty ||
        l.contains('unknown') ||
        a == '알 수 없는 아티스트' ||
        a == '알 수 없음' ||
        // 여러 가수 모음 앨범 표시 → 진짜 가수가 아님
        l.contains('various') ||
        l == 'va' ||
        l == 'v.a.' ||
        l == 'v.a' ||
        a.contains('여러 아티스트') ||
        a.contains('다양한 아티스트') ||
        a.contains('옴니버스');
  }

  static String _tidy(String s) => s
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'^[\s\-–—_|:·]+|[\s\-–—_|:·]+$'), '')
      .trim();

  /// knownArtists: 내 노래 목록에 있는 가수 이름들 (소문자) → "노래 - 가수" 순서도 알아봄
  static SongClean clean(String title, String artist, {Set<String> knownArtists = const {}}) {
    var t = title.trim();
    var a = artist.trim();
    bool known(String s) => knownArtists.contains(s.toLowerCase().trim());

    // 1) "제목 | 가수" 처럼 | 뒤에 붙은 것 떼어두기, 해시태그 지우기
    String? afterBar;
    final bar = RegExp(r'\s*[|｜]\s*').firstMatch(t);
    if (bar != null && bar.start > 0) {
      afterBar = t.substring(bar.end).trim();
      t = t.substring(0, bar.start);
    }
    t = t.replaceAll(RegExp(r'#\S+'), '');

    // 2) 괄호 중 군더더기만 지우기 (feat.·Live·Remix 등은 남김)
    t = t.replaceAllMapped(RegExp(r'[\[\(【（「]([^\]\)】）」]*)[\]\)】）」]'), (m) {
      final inside = m.group(1)!;
      if (_keep.hasMatch(inside)) return m.group(0)!;
      return _junk.hasMatch(inside) ? '' : m.group(0)!;
    });

    // 괄호 밖 맨 뒤에 붙은 "Official MV", "M/V", "Audio" 같은 것
    t = t.replaceAll(
        RegExp(r'\s*(official\s*)?(m/?v|music\s*video|lyric\s*video|audio|video)\s*$', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s*official\s*$', caseSensitive: false), '');

    // 3) 가수 이름 정리: "아이유 - Topic", "XXXVEVO"
    a = a.replaceAll(RegExp(r'\s*-\s*topic$', caseSensitive: false), '');
    a = a.replaceAll(RegExp(r'vevo$', caseSensitive: false), '').trim();
    final artistIsChannel = _looksUnknown(a) || _channel.hasMatch(a);

    // 4) 따옴표 제목: "BTS (방탄소년단) 'Dynamite'"
    final q = RegExp(r'''^(.*?)\s*['‘“"「](.+?)['’”"」]\s*(.*)$''').firstMatch(t);
    if (q != null && q.group(1)!.trim().isNotEmpty) {
      if (artistIsChannel) a = q.group(1)!.trim();
      t = q.group(2)!.trim();
    } else {
      // 5) "가수 - 노래" (1theK는 "가수 _ 노래")
      //    "Part. 09", "CD 2" 같은 묶음 표시는 빼고, 앞에 트랙 번호가 붙은 쪽이 제목
      var raw = t
          .split(RegExp(r'\s+[-–—_]\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      // "김종환_사랑을위하여", "김종환-사랑을위하여"처럼 띄어쓰기 없이 붙은 것 (가수를 모를 때만)
      if (raw.length < 2 && artistIsChannel) {
        final seps = RegExp(r'[_\-–—]').allMatches(t).length;
        if (seps == 1) {
          final m = RegExp(r'^(.+?)[_\-–—](.+)$').firstMatch(t.trim());
          if (m != null && m.group(1)!.trim().isNotEmpty && m.group(2)!.trim().isNotEmpty) {
            raw = [m.group(1)!.trim(), m.group(2)!.trim()];
          }
        } else if (seps >= 2 && t.contains('_')) {
          t = t.replaceAll('_', ' '); // 밑줄이 여러 개면 띄어쓰기로만 바꾸기
        }
      }
      final partRe = RegExp(r'^(part|cd|disc|disk|vol|volume|track|트랙|파트)\.?\s*\d+$', caseSensitive: false);
      final numOnly = RegExp(r'^\d{1,3}$');
      final numHead = RegExp(r'^\d{1,3}(\s*[.\-_)]\s*|\s+)');
      final parts = <String>[];
      var titleIdx = -1;
      var nextIsTitle = false;
      for (final s in raw) {
        if (partRe.hasMatch(s)) continue; // Part. 09, CD 2 → 빼기
        if (numOnly.hasMatch(s)) {
          nextIsTitle = true; // "03 - 노래"처럼 번호만 따로 있으면 다음 칸이 제목
          continue;
        }
        if (nextIsTitle || numHead.hasMatch(s)) {
          if (titleIdx < 0) titleIdx = parts.length;
          nextIsTitle = false;
        }
        parts.add(s);
      }
      if (parts.length == 2 && titleIdx >= 0) {
        // "19 하늘색 꿈 - 박지윤" → 번호 붙은 쪽이 제목, 나머지가 가수
        t = parts[titleIdx].replaceFirst(numHead, '').trim();
        if (artistIsChannel) a = parts[1 - titleIdx];
      } else if (parts.length >= 2) {
        final left = parts.first;
        final right = parts.sublist(1).join(' - ');
        final al = a.toLowerCase(), ll = left.toLowerCase();
        if (artistIsChannel) {
          // 한글 2~4글자 = 사람 이름(가수)일 가능성이 큼 (김종환, 아이유, 임영웅)
          bool nameLike(String s) => RegExp(r'^[가-힣]{2,4}$').hasMatch(s.replaceAll(' ', ''));
          final last = parts.last;
          final lastIsArtist = parts.length == 2 &&
              ((known(last) && !known(left)) || // 뒤쪽이 내 목록에 있는 가수
                  (!known(left) && nameLike(last) && !nameLike(left) &&
                      left.replaceAll(' ', '').length > last.replaceAll(' ', '').length)); // 뒤쪽이 짧은 이름
          if (lastIsArtist) {
            // "노래 - 가수" 순서
            a = last;
            t = left;
          } else {
            a = left;
            t = right;
          }
        } else if (ll == al || al.contains(ll) || ll.contains(al)) {
          t = right; // 앞쪽이 이미 아는 가수 이름이면 떼기
        } else if (right.toLowerCase() == al) {
          t = left; // "노래 - 가수" 순서
        }
      } else if (parts.length == 1 && raw.length > 1) {
        t = parts.first.replaceFirst(numHead, '').trim(); // "Part. 09 - 노래" → 노래
      } else if (afterBar != null && afterBar.isNotEmpty && afterBar.length < 40 && artistIsChannel) {
        a = afterBar; // "Hype Boy (Official Audio) | NewJeans"
      }
    }

    // 맨 앞 트랙 번호 "01. 노래", "03 - 노래" 떼기
    t = t.replaceFirst(RegExp(r'^\d{1,3}\s*[.\-_)]\s*'), '');

    t = _tidy(t);
    a = _tidy(a);
    if (t.isEmpty) t = title.trim();
    if (a.isEmpty) a = artist.trim();
    return SongClean(t, a);
  }
}