# -*- coding: utf-8 -*-
# 앨범 빨리 띄우기: 애플 앨범을 카드 뜰 때 디저와 동시에 → 뮤직브레인즈만 나중에
import os, sys

PATH = os.path.join('lib', 'widgets', 'artist_info_sheet.dart')
if not os.path.exists(PATH):
    print('❌ lib/widgets/artist_info_sheet.dart 가 없어요'); sys.exit(1)

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if 'appleAlbums(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'moreAlbums(' not in src:
    print('❌ apply_artist_more_albums.py 를 먼저 돌려 주세요'); sys.exit(1)

NEW_BLOCK = r"""  static String _normAlbum(String s) => _norm(s
      .replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]'), '')
      .replaceAll(RegExp(r'\s+-\s+(single|ep)$', caseSensitive: false), ''));

  static String _year(String date) => date.length >= 4 ? date.substring(0, 4) : '';

  /// 애플(한국 스토어) 앨범 — 카드 뜰 때 디저와 동시에
  static Future<List<_Album>> appleAlbums(String artist) async {
    final out = <_Album>[];
    final s = await _get('https://itunes.apple.com/search?entity=musicArtist&country=KR&limit=5'
        '&term=${Uri.encodeQueryComponent(artist)}');
    int? appleId;
    for (final a in (s?['results'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (_sameArtist('${a['artistName'] ?? ''}', artist)) {
        appleId = (a['artistId'] as num?)?.toInt();
        break;
      }
    }
    if (appleId == null) return out;
    final l = await _get('https://itunes.apple.com/lookup?id=$appleId&entity=album&country=KR&limit=200');
    for (final c in (l?['results'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (c['wrapperType'] != 'collection') continue;
      final name = '${c['collectionName'] ?? ''}';
      final n = (c['trackCount'] as num?)?.toInt() ?? 0;
      final kind = name.endsWith(' - Single') || (n > 0 && n <= 3)
          ? '싱글'
          : name.endsWith(' - EP')
              ? 'EP'
              : '앨범';
      out.add(_Album(name, '${c['artworkUrl100'] ?? ''}'.replaceAll('100x100bb', '300x300bb'),
          _year('${c['releaseDate'] ?? ''}'), kind));
    }
    return out;
  }

  /// 뮤직브레인즈 앨범 — 조금 늦게 (1초에 한 번만 물어봐야 해서)
  static Future<List<_Album>> mbAlbums(String artist) async {
    final out = <_Album>[];
    await Future.delayed(const Duration(milliseconds: 1100));
    final q = Uri.encodeQueryComponent('artist:"$artist"');
    final m = await _get('https://musicbrainz.org/ws/2/release-group?query=$q&fmt=json&limit=60');
    for (final g in (m?['release-groups'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (((g['score'] as num?) ?? 0) < 80) continue;
      final credit = ((g['artist-credit'] as List?)?.whereType<Map>() ?? const <Map>[])
          .map((x) => '${x['name'] ?? (x['artist'] as Map?)?['name'] ?? ''}')
          .join(' ');
      if (!_sameArtist(credit, artist)) continue;
      final pt = '${g['primary-type'] ?? ''}';
      final st = ((g['secondary-types'] as List?) ?? const []).map((e) => '$e').toList();
      final kind = st.contains('Compilation')
          ? '모음집'
          : st.contains('Live')
              ? '라이브'
              : pt == 'Single'
                  ? '싱글'
                  : pt == 'EP'
                      ? 'EP'
                      : '앨범';
      out.add(_Album('${g['title'] ?? ''}', 'https://coverartarchive.org/release-group/${g['id']}/front-250',
          _year('${g['first-release-date'] ?? ''}'), kind));
    }
    return out;
  }

  /// 겹치는 앨범은 빼고 합치기 → 최신부터 40개까지
  static void mergeAlbums(_Info info, List<_Album> extra) {
    final seen = info.albums.map((a) => _normAlbum(a.title)).toSet();
    final more = <_Album>[];
    for (final a in extra) {
      final t = a.title.replaceAll(RegExp(r'\s+-\s+(Single|EP)$'), '').trim();
      final k = _normAlbum(t);
      if (t.isEmpty || k.isEmpty || !seen.add(k)) continue;
      more.add(_Album(t, a.cover, a.year, a.kind));
    }
    if (more.isEmpty) return;
    final all = [...info.albums, ...more]..sort((a, b) => b.year.compareTo(a.year));
    info.albums = all.take(40).toList();
    if ((info.albumCount ?? 0) < info.albums.length) info.albumCount = info.albums.length;
  }

"""

ok = True
i = src.find('  static String _normAlbum(String s)')
j = src.find('  // ── Wikipedia: 짧은 소개')
if i != -1 and j != -1 and i < j:
    src = src[:i] + NEW_BLOCK + src[j:]; print('✔ 앨범 찾기 나누기 (애플 / 뮤직브레인즈)')
else:
    ok = False; print('❌ 앨범 찾기 부분을 못 찾음')

edits = [
('카드 뜰 때 애플 앨범도 같이',
"""    await Future.wait([
      _ArtistApi.deezer(info, _title, _artist),""",
"""    var apple = <_Album>[];
    await Future.wait([
      _ArtistApi.appleAlbums(_artist).then((l) => apple = l),
      _ArtistApi.deezer(info, _title, _artist),"""),
('디저 + 애플 합치기',
"""    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
    if (!info.empty) _loadCredits(info, p);""",
"""    _ArtistApi.mergeAlbums(info, apple);
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
    if (!info.empty) _loadCredits(info, p);"""),
('뮤직브레인즈 앨범만 나중에',
"""    // 앨범 더 찾기 (애플·뮤직브레인즈) → 화면에 바로 반영
    await _ArtistApi.moreAlbums(info, _artist);""",
"""    // 뮤직브레인즈에만 있는 앨범 더하기 → 화면에 바로 반영
    _ArtistApi.mergeAlbums(info, await _ArtistApi.mbAlbums(_artist));"""),
]
for name, old, new in edits:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
