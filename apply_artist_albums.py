# -*- coding: utf-8 -*-
# 가수 앨범: 동명이인 섞이지 않게
import os, sys, json
KEYS = json.loads('{}')
EDITS = json.loads('[["widgets/artist_info_sheet.dart", "      if (_sameArtist(an, artist)) {\\n        hit = t;", "      if (_sameArtist(an, artist) && _sameTitle(\'${t[\'title\'] ?? \'\'}\', title)) {\\n        hit = t;", 1], ["widgets/artist_info_sheet.dart", "      // 곡은 못 찾아도 가수는 찾아보기\\n      final a = await _get(\'https://api.deezer.com/search/artist?limit=5&q=${Uri.encodeQueryComponent(artist)}\');\\n      for (final x in (a?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n        if (_sameArtist(\'${x[\'name\'] ?? \'\'}\', artist)) {\\n          artistId = (x[\'id\'] as num?)?.toInt();\\n          break;\\n        }\\n      }", "      // 곡은 못 찾아도 가수는 찾아보기 — 이름이 같은 가수가 여럿일 수 있어서 대표곡에 지금 노래가 있는 가수만\\n      final a = await _get(\'https://api.deezer.com/search/artist?limit=5&q=${Uri.encodeQueryComponent(artist)}\');\\n      for (final x in (a?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n        if (!_sameArtist(\'${x[\'name\'] ?? \'\'}\', artist)) continue;\\n        final id = (x[\'id\'] as num?)?.toInt();\\n        if (id == null) continue;\\n        final top = await _get(\'https://api.deezer.com/artist/$id/top?limit=50\');\\n        final has = ((top?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[])\\n            .any((t) => _sameTitle(\'${t[\'title\'] ?? \'\'}\', title));\\n        if (has) {\\n          artistId = id;\\n          break;\\n        }\\n      }", 1], ["widgets/artist_info_sheet.dart", "  static Future<List<_Album>> appleAlbums(String artist) async {\\n    final out = <_Album>[];\\n    final s = await _get(\'https://itunes.apple.com/search?entity=musicArtist&country=KR&limit=5\'\\n        \'&term=${Uri.encodeQueryComponent(artist)}\');\\n    int? appleId;\\n    for (final a in (s?[\'results\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n      if (_sameArtist(\'${a[\'artistName\'] ?? \'\'}\', artist)) {", "  /// (이름이 같은 다른 가수가 섞이지 않게 \'지금 듣는 노래\'를 부른 가수로 찾기)\\n  static Future<List<_Album>> appleAlbums(String title, String artist) async {\\n    final out = <_Album>[];\\n    final s = await _get(\'https://itunes.apple.com/search?entity=song&country=KR&limit=25\'\\n        \'&term=${Uri.encodeQueryComponent(\'$artist $title\')}\');\\n    int? appleId;\\n    for (final a in (s?[\'results\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n      if (_sameArtist(\'${a[\'artistName\'] ?? \'\'}\', artist) && _sameTitle(\'${a[\'trackName\'] ?? \'\'}\', title)) {", 1], ["widgets/artist_info_sheet.dart", "  static Future<List<_Album>> mbAlbums(String artist) async {\\n    final out = <_Album>[];\\n    await Future.delayed(const Duration(milliseconds: 1100));\\n    final q = Uri.encodeQueryComponent(\'artist:\\"$artist\\"\');", "  /// (이름이 같은 다른 가수가 섞이지 않게 \'지금 듣는 노래\'를 부른 가수의 고유번호로 찾기)\\n  static Future<List<_Album>> mbAlbums(String title, String artist) async {\\n    final out = <_Album>[];\\n    await Future.delayed(const Duration(milliseconds: 1100));\\n    final rq = Uri.encodeQueryComponent(\'recording:\\"$title\\" AND artist:\\"$artist\\"\');\\n    final rs = await _get(\'https://musicbrainz.org/ws/2/recording/?query=$rq&fmt=json&limit=5\');\\n    String? arid;\\n    for (final r in (rs?[\'recordings\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n      if (((r[\'score\'] as num?) ?? 0) < 90 || !_sameTitle(\'${r[\'title\'] ?? \'\'}\', title)) continue;\\n      for (final c in (r[\'artist-credit\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n        final ar = c[\'artist\'] as Map?;\\n        if (ar?[\'id\'] != null && _sameArtist(\'${c[\'name\'] ?? ar?[\'name\'] ?? \'\'}\', artist)) {\\n          arid = \'${ar![\'id\']}\';\\n          break;\\n        }\\n      }\\n      if (arid != null) break;\\n    }\\n    if (arid == null) return out;\\n    await Future.delayed(const Duration(milliseconds: 1100)); // 뮤직브레인즈: 1초에 한 번만\\n    final q = Uri.encodeQueryComponent(\'arid:$arid\');", 1], ["widgets/artist_info_sheet.dart", "      _ArtistApi.appleAlbums(_artist).then((l) => apple = l),", "      _ArtistApi.appleAlbums(_title, _artist).then((l) => apple = l),", 1], ["widgets/artist_info_sheet.dart", "    _ArtistApi.mergeAlbums(info, await _ArtistApi.mbAlbums(_artist));", "    _ArtistApi.mergeAlbums(info, await _ArtistApi.mbAlbums(_title, _artist));", 1], ["widgets/artist_info_sheet.dart", "  String get _key => \'artistInfo5:", "  String get _key => \'artistInfo6:", 1]]')
LANGS = ['ko', 'en', 'ja', 'zh', 'zh_Hant']
ROOT = 'lib'
def rd(p):
    with open(p, 'r', encoding='utf-8', newline='') as f: return f.read()
def wr(p, t):
    with open(p, 'w', encoding='utf-8', newline='') as f: f.write(t)
import re
STR = re.compile(r"'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\"|//[^\n]*")
def diff(s):
    s = STR.sub('', s)
    return [s.count(a) - s.count(b) for a, b in ['()', '[]', '{}']]
if not os.path.isdir(ROOT):
    print('❌ lib 폴더가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
out = {}
ok = True
# 1) 번역 문구 넣기
arbs = {}
for i, lang in enumerate(LANGS):
    p = os.path.join(ROOT, 'l10n', 'app_%s.arb' % lang)
    if not os.path.exists(p):
        print('❌', 'app_%s.arb' % lang, '파일이 없어요'); sys.exit(1)
    arbs[lang] = (p, rd(p))
have = json.loads(arbs['ko'][1])
if not KEYS or all(k in have for k in KEYS):
    already_keys = True
else:
    already_keys = False
    for lang, (p, t) in arbs.items():
        d = json.loads(t)
        dup = [k for k in KEYS if k in d]
        if dup:
            print('❌', os.path.basename(p), '에 이미 있는 이름:', ', '.join(dup)); ok = False; continue
        nl = '\r\n' if '\r\n' in t else '\n'
        lines = []
        for k, v in KEYS.items():
            val = v[LANGS.index(lang)]
            lines.append('  %s: %s' % (json.dumps(k), json.dumps(val, ensure_ascii=False)))
            if lang in ('ko', 'en') and v[5]:
                ph = {name: {'type': typ} for name, typ in v[5].items()}
                lines.append('  %s: %s' % (json.dumps('@' + k), json.dumps({'placeholders': ph}, ensure_ascii=False)))
        end = t.rstrip()
        if not end.endswith('}'):
            print('❌', os.path.basename(p), '모양이 이상해요'); ok = False; continue
        body = end[:-1].rstrip()
        new = body + ',' + nl + (',' + nl).join(lines) + nl + '}' + (nl if t.endswith(('\n',)) else '')
        try:
            json.loads(new)
        except Exception as ex:
            print('❌', os.path.basename(p), '저장하면 깨져요', ex); ok = False; continue
        out[p] = new
        print('✔', os.path.basename(p), '문구 %d개' % len(KEYS))
# 2) 코드 고치기
done_edits = 0
for rel, old, new, cnt in EDITS:
    p = os.path.join(ROOT, rel)
    if p not in out:
        if not os.path.exists(p):
            print('❌', rel, '파일이 없어요'); ok = False; continue
        out[p] = rd(p)
    t = out[p]
    crlf = '\r\n' in t
    o = old.replace('\n', '\r\n') if crlf else old
    n = new.replace('\n', '\r\n') if crlf else new
    c = t.count(o)
    if (n and o in n and t.count(n) >= 1) or (c == 0 and (n == '' or t.count(n) >= 1)):
        done_edits += 1; continue
    if c != cnt:
        print('❌', rel, '고칠 곳을 못 찾았어요:', old.strip().splitlines()[0][:70]); ok = False; continue
    out[p] = t.replace(o, n)
if done_edits == len(EDITS) and already_keys:
    print('이미 적용돼 있어요'); sys.exit(0)
if done_edits and not ok:
    pass
if not ok:
    print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
for p, t in out.items():
    if p.endswith('.dart'):
        before = diff(rd(p)); after = diff(t)
        if before != after:
            print('❌', p, '괄호 개수가 안 맞아요'); print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
files = sorted(set(os.path.basename(r) for r, *_ in EDITS))
for p, t in out.items(): wr(p, t)
for f in files: print('✔', f)
print('다 됐어요 (코드 %d곳)' % (len(EDITS) - done_edits))
