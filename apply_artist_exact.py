# -*- coding: utf-8 -*-
# 가수 정보: 이름이 정확히 같은 가수만 (쿨 → 쿨케이 X) + 모음집·라이브·리마스터 빼기
import os, re, sys

PATH = os.path.join('lib', 'widgets', 'artist_info_sheet.dart')
if not os.path.exists(PATH):
    print('❌ lib/widgets/artist_info_sheet.dart 가 없어요'); sys.exit(1)

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '_nameForms(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
('가수 이름: 정확히 같을 때만',
"""  static bool _sameArtist(String a, String b) {
    final x = _norm(a), y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.contains(y) || y.contains(x);
  }
""",
r"""  /// 이름 모양들: "쿨 (COOL)" → 쿨 · cool / "아이유, 성시경" → 아이유 · 성시경
  static Set<String> _nameForms(String s) {
    final out = <String>{};
    void add(String v) {
      final n = _norm(v);
      if (n.isNotEmpty) out.add(n);
      final m = RegExp(r'^(.*?)\s*[\(\[](.*?)[\)\]]\s*$').firstMatch(v.trim());
      if (m != null) {
        final a = _norm(m.group(1)!), b = _norm(m.group(2)!);
        if (a.isNotEmpty) out.add(a);
        if (b.isNotEmpty) out.add(b);
      }
    }
    add(s);
    for (final part in s.split(RegExp(r'\s*(?:,|&|/|\bx\b|\bfeat\.?|\bft\.?|featuring)\s*', caseSensitive: false))) {
      add(part);
    }
    return out;
  }

  /// 가수가 같은지: 이름이 정확히 같을 때만 (쿨 ≠ 쿨케이)
  static bool _sameArtist(String a, String b) {
    final x = _nameForms(a), y = _nameForms(b);
    return x.any(y.contains);
  }

  /// 곡 제목은 조금 느슨하게 (뒤에 (Feat.) 같은 게 붙어도 같게)
  static bool _sameTitle(String a, String b) {
    final x = _norm(a), y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.contains(y) || y.contains(x);
  }
"""),

('Genius: 제목은 느슨하게',
"""      if (_sameArtist(an, artist) && _sameArtist(tn, title)) {""",
"""      if (_sameArtist(an, artist) && _sameTitle(tn, title)) {"""),

('리마스터·디럭스도 같은 앨범으로',
"""  static String _normAlbum(String s) => _norm(s
      .replaceAll(RegExp(r'\\s*[\\(\\[].*?[\\)\\]]'), '')
      .replaceAll(RegExp(r'\\s+-\\s+(single|ep)$', caseSensitive: false), ''));""",
"""  static String _normAlbum(String s) => _norm(s
      .replaceAll(RegExp(r'\\s*[\\(\\[].*?[\\)\\]]'), '')
      .replaceAll(RegExp(r'\\s+-\\s+(single|ep)$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\\b(deluxe|remaster(ed)?|special|expanded|anniversary|edition|version|reissue)\\b|리마스터|스페셜|디럭스',
          caseSensitive: false), ''));

  /// 빼는 앨범: 모음집 · 라이브 · 베스트 · 리믹스
  static final _skipAlbum = RegExp(r'\\b(live|best|greatest hits|collection|remix(es)?|karaoke|instrumental)\\b|라이브|베스트|히트곡 모음',
      caseSensitive: false);
  static bool _keepAlbum(_Album a) =>
      a.kind != '모음집' && a.kind != '라이브' && !_skipAlbum.hasMatch(a.title);"""),

('뮤직브레인즈: 모음집·라이브·리믹스 빼기',
"""      final kind = st.contains('Compilation')""",
"""      if (st.contains('Compilation') || st.contains('Live') || st.contains('Remix') || st.contains('DJ-mix')) continue;
      final kind = st.contains('Compilation')"""),

('합칠 때 빼는 앨범 걸러내기',
"""  static void mergeAlbums(_Info info, List<_Album> extra) {
    final seen = info.albums.map((a) => _normAlbum(a.title)).toSet();
    final more = <_Album>[];
    for (final a in extra) {
      final t = a.title.replaceAll(RegExp(r'\\s+-\\s+(Single|EP)$'), '').trim();
      final k = _normAlbum(t);
      if (t.isEmpty || k.isEmpty || !seen.add(k)) continue;
      more.add(_Album(t, a.cover, a.year, a.kind));
    }
    if (more.isEmpty) return;
    final all = [...info.albums, ...more]..sort((a, b) => b.year.compareTo(a.year));
    info.albums = all.take(40).toList();
    if ((info.albumCount ?? 0) < info.albums.length) info.albumCount = info.albums.length;
  }""",
"""  static void mergeAlbums(_Info info, List<_Album> extra) {
    final seen = <String>{};
    final all = <_Album>[];
    for (final a in [...info.albums, ...extra]) {
      final t = a.title.replaceAll(RegExp(r'\\s+-\\s+(Single|EP)$'), '').trim();
      final b = _Album(t, a.cover, a.year, a.kind);
      final k = _normAlbum(t);
      if (t.isEmpty || k.isEmpty || !_keepAlbum(b) || !seen.add(k)) continue;
      all.add(b);
    }
    all.sort((a, b) => b.year.compareTo(a.year)); // 최신부터
    info.albums = all.take(40).toList();
    info.albumCount = info.albums.isEmpty ? null : info.albums.length;
  }"""),
]

ok = True
for name, old, new in edits:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

src2, n = re.subn(r"'artistInfo\d+:", "'artistInfo5:", src)
if n == 1:
    src = src2; print('✔ 예전에 저장한 정보는 새로 찾기')
else:
    ok = False; print('❌ 저장 이름을 못 찾음')

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
