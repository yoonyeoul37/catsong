# -*- coding: utf-8 -*-
# 가수 앨범 더 찾기: 디저 + 애플(한국 스토어) + 뮤직브레인즈 → 겹치는 건 빼고 합치기
import os, re, sys

PATH = os.path.join('lib', 'widgets', 'artist_info_sheet.dart')
if not os.path.exists(PATH):
    print('❌ lib/widgets/artist_info_sheet.dart 가 없어요 (apply_artist_info.py 먼저)'); sys.exit(1)

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if 'moreAlbums(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

MORE = r"""  static String _normAlbum(String s) => _norm(s
      .replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]'), '')
      .replaceAll(RegExp(r'\s+-\s+(single|ep)$', caseSensitive: false), ''));

  /// 앨범 더 찾기: 애플(한국 스토어) + 뮤직브레인즈 → 디저 목록에 없는 것만 더하기
  static Future<void> moreAlbums(_Info info, String artist) async {
    final seen = info.albums.map((a) => _normAlbum(a.title)).toSet();
    final more = <_Album>[];
    void add(String title, String cover, String date, String kind) {
      final t = title.replaceAll(RegExp(r'\s+-\s+(Single|EP)$'), '').trim();
      final k = _normAlbum(t);
      if (t.isEmpty || k.isEmpty || !seen.add(k)) return;
      more.add(_Album(t, cover, date.length >= 4 ? date.substring(0, 4) : '', kind));
    }

    // 애플 (한국 스토어: 옛날 한국 앨범이 많아요)
    final s = await _get('https://itunes.apple.com/search?entity=musicArtist&country=KR&limit=5'
        '&term=${Uri.encodeQueryComponent(artist)}');
    int? appleId;
    for (final a in (s?['results'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (_sameArtist('${a['artistName'] ?? ''}', artist)) {
        appleId = (a['artistId'] as num?)?.toInt();
        break;
      }
    }
    if (appleId != null) {
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
        add(name, '${c['artworkUrl100'] ?? ''}'.replaceAll('100x100bb', '300x300bb'), '${c['releaseDate'] ?? ''}',
            kind);
      }
    }

    // 뮤직브레인즈 (1초에 한 번만)
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
      add('${g['title'] ?? ''}', 'https://coverartarchive.org/release-group/${g['id']}/front-250',
          '${g['first-release-date'] ?? ''}', kind);
    }

    if (more.isEmpty) return;
    final all = [...info.albums, ...more]..sort((a, b) => b.year.compareTo(a.year)); // 최신부터
    info.albums = all.take(40).toList();
    if ((info.albumCount ?? 0) < info.albums.length) info.albumCount = info.albums.length;
  }

"""

ok = True
anchor = '  // ── Wikipedia: 짧은 소개'
if src.count(anchor) == 1:
    src = src.replace(anchor, MORE + anchor); print('✔ 앨범 더 찾기 기능')
else:
    ok = False; print('❌ 앨범 더 찾기 넣을 자리를 못 찾음')

old = """  Future<void> _loadCredits(_Info info, SharedPreferences p) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    await _ArtistApi.credits(info, _title, _artist);"""
new = """  Future<void> _loadCredits(_Info info, SharedPreferences p) async {
    // 앨범 더 찾기 (애플·뮤직브레인즈) → 화면에 바로 반영
    await _ArtistApi.moreAlbums(info, _artist);
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 1100));
    await _ArtistApi.credits(info, _title, _artist);"""
if src.count(old) == 1:
    src = src.replace(old, new); print('✔ 정보 띄운 뒤 앨범 더 찾기')
else:
    ok = False; print('❌ 정보 띄운 뒤 앨범 더 찾기 (못 찾음)')

src2, n = re.subn(r"'artistInfo\d+:", "'artistInfo3:", src)
if n == 1:
    src = src2; print('✔ 예전에 저장한 정보는 새로 찾기')
else:
    ok = False; print('❌ 저장 이름을 못 찾음')

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
