# -*- coding: utf-8 -*-
# 작사·작곡 더 찾기: 뮤직브레인즈에 없으면 Genius에서 한 번 더
import os, sys

PATH = os.path.join('lib', 'widgets', 'artist_info_sheet.dart')
if not os.path.exists(PATH):
    print('❌ lib/widgets/artist_info_sheet.dart 가 없어요'); sys.exit(1)

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '_geniusCredits(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

OLD = """  static Future<void> credits(_Info info, String title, String artist) async {
"""
NEW = r"""  /// 작사·작곡: ① 뮤직브레인즈 → ② 없으면 Genius
  static Future<void> credits(_Info info, String title, String artist) async {
    await _mbCredits(info, title, artist);
    if (info.credits.isEmpty) await _geniusCredits(info, title, artist);
  }

  // ── Genius: 작사 · 작곡 · 편곡 · 프로듀서 ──
  static const _geniusToken = 'BE8Wt-esSV5yI_7Dxs8aYrvanspIVI_YLO56H9alyGtvUYBJ0We5DqytX0xXpBNw';

  static Future<Map?> _genius(String path) async {
    try {
      final r = await http.get(Uri.parse('https://api.genius.com$path'), headers: {
        'Authorization': 'Bearer $_geniusToken',
        'User-Agent': 'Paransori/1.0 (info@knexm.com)',
      }).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      return d is Map ? d['response'] as Map? : null;
    } catch (_) {
      return null;
    }
  }

  /// "Kim Hyung-seok (김형석)" → 한국어 이름이 괄호 안에 있으면 그걸로
  static String _cleanName(String n) {
    final m = RegExp(r'^(.*?)\s*\(([^)]*)\)\s*$').firstMatch(n.trim());
    if (m != null && RegExp(r'[가-힣]').hasMatch(m.group(2)!)) return m.group(2)!.trim();
    return n.trim();
  }

  static void _addNames(_Info info, String role, List? artists) {
    for (final a in artists?.whereType<Map>() ?? const <Map>[]) {
      final name = _cleanName('${a['name'] ?? ''}');
      if (name.isEmpty) continue;
      final l = info.credits.putIfAbsent(role, () => []);
      if (!l.contains(name)) l.add(name);
    }
  }

  static Future<void> _geniusCredits(_Info info, String title, String artist) async {
    final s = await _genius('/search?q=${Uri.encodeQueryComponent('$artist $title')}');
    int? id;
    for (final h in (s?['hits'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      final r = h['result'] as Map?;
      if (r == null) continue;
      final an = '${(r['primary_artist'] as Map?)?['name'] ?? ''}';
      final tn = '${r['title'] ?? ''}';
      if (_sameArtist(an, artist) && _sameArtist(tn, title)) {
        id = (r['id'] as num?)?.toInt();
        break;
      }
    }
    if (id == null) return;
    final song = (await _genius('/songs/$id?text_format=plain'))?['song'] as Map?;
    if (song == null) return;
    // 작사 · 작곡 · 편곡 (Genius "Credits")
    for (final c in (song['custom_performances'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      final label = '${c['label'] ?? ''}'.toLowerCase();
      final role = label.contains('lyric')
          ? '작사'
          : label.contains('compos')
              ? '작곡'
              : label.contains('arrang')
                  ? '편곡'
                  : null;
      if (role != null) _addNames(info, role, c['artists'] as List?);
    }
    // 작사·작곡 따로 없으면 "Written By" → 작사·작곡
    if (info.credits['작사'] == null && info.credits['작곡'] == null) {
      _addNames(info, '작사·작곡', song['writer_artists'] as List?);
    }
    _addNames(info, '프로듀서', song['producer_artists'] as List?);
  }

  static Future<void> _mbCredits(_Info info, String title, String artist) async {
"""

ok = True
if src.count(OLD) == 1:
    src = src.replace(OLD, NEW); print('✔ Genius 에서 작사·작곡 찾기')
else:
    ok = False; print('❌ 작사·작곡 찾는 부분을 못 찾음')

# 예전에 저장한 (작사·작곡 없는) 정보는 새로 찾기
import re
src2, n = re.subn(r"'artistInfo\d+:", "'artistInfo4:", src)
if n == 1:
    src = src2; print('✔ 예전에 저장한 정보는 새로 찾기')
else:
    ok = False; print('❌ 저장 이름을 못 찾음')

src = src.replace("Text('정보: Deezer · MusicBrainz · Wikipedia',", "Text('정보: Deezer · Apple · MusicBrainz · Genius · Wikipedia',")

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
