# -*- coding: utf-8 -*-
# 가수 앨범: 못 찾는 것 줄이기
import os, sys, json
KEYS = json.loads('{}')
EDITS = json.loads('[["widgets/artist_info_sheet.dart", "      final a = await _get(\'https://api.deezer.com/search/artist?limit=5&q=${Uri.encodeQueryComponent(artist)}\');\\n      for (final x in (a?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n        if (!_sameArtist(\'${x[\'name\'] ?? \'\'}\', artist)) continue;\\n        final id = (x[\'id\'] as num?)?.toInt();\\n        if (id == null) continue;\\n        final top = await _get(\'https://api.deezer.com/artist/$id/top?limit=50\');\\n        final has = ((top?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[])\\n            .any((t) => _sameTitle(\'${t[\'title\'] ?? \'\'}\', title));\\n        if (has) {\\n          artistId = id;\\n          break;\\n        }\\n      }\\n    }", "      final a = await _get(\'https://api.deezer.com/search/artist?limit=5&q=${Uri.encodeQueryComponent(artist)}\');\\n      final same = <int>[];\\n      for (final x in (a?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n        final id = (x[\'id\'] as num?)?.toInt();\\n        if (id != null && _sameArtist(\'${x[\'name\'] ?? \'\'}\', artist)) same.add(id);\\n      }\\n      for (final id in same) {\\n        final top = await _get(\'https://api.deezer.com/artist/$id/top?limit=100\');\\n        final has = ((top?[\'data\'] as List?)?.whereType<Map>() ?? const <Map>[])\\n            .any((t) => _sameTitle(\'${t[\'title\'] ?? \'\'}\', title));\\n        if (has) {\\n          artistId = id;\\n          break;\\n        }\\n      }\\n      // 대표곡에 없어도 그 이름 가수가 딱 한 명이면 (헷갈릴 사람이 없으니) 그 가수로\\n      if (artistId == null && same.length == 1) artistId = same.first;\\n    }", 1], ["widgets/artist_info_sheet.dart", "      if (_sameArtist(\'${a[\'artistName\'] ?? \'\'}\', artist) && _sameTitle(\'${a[\'trackName\'] ?? \'\'}\', title)) {\\n        appleId = (a[\'artistId\'] as num?)?.toInt();\\n        break;\\n      }\\n    }\\n    if (appleId == null) return out;", "      if (_sameArtist(\'${a[\'artistName\'] ?? \'\'}\', artist) && _sameTitle(\'${a[\'trackName\'] ?? \'\'}\', title)) {\\n        appleId = (a[\'artistId\'] as num?)?.toInt();\\n        break;\\n      }\\n    }\\n    if (appleId == null) {\\n      final s2 = await _get(\'https://itunes.apple.com/search?entity=musicArtist&country=KR&limit=5\'\\n          \'&term=${Uri.encodeQueryComponent(artist)}\');\\n      final same = <int>[];\\n      for (final a in (s2?[\'results\'] as List?)?.whereType<Map>() ?? const <Map>[]) {\\n        final id = (a[\'artistId\'] as num?)?.toInt();\\n        if (id != null && _sameArtist(\'${a[\'artistName\'] ?? \'\'}\', artist)) same.add(id);\\n      }\\n      for (final id in same) {\\n        final sl = await _get(\'https://itunes.apple.com/lookup?id=$id&entity=song&country=KR&limit=200\');\\n        final has = ((sl?[\'results\'] as List?)?.whereType<Map>() ?? const <Map>[])\\n            .any((c) => c[\'wrapperType\'] == \'track\' && _sameTitle(\'${c[\'trackName\'] ?? \'\'}\', title));\\n        if (has) {\\n          appleId = id;\\n          break;\\n        }\\n      }\\n      // 곡 목록에 없어도 그 이름 가수가 딱 한 명이면 그 가수로\\n      if (appleId == null && same.length == 1) appleId = same.first;\\n    }\\n    if (appleId == null) return out;", 1], ["widgets/artist_info_sheet.dart", "      if (arid != null) break;\\n    }\\n    if (arid == null) return out;", "      if (arid != null) break;\\n    }\\n    if (arid == null) {\\n      await Future.delayed(const Duration(milliseconds: 1100));\\n      final aq = Uri.encodeQueryComponent(\'artist:\\"$artist\\"\');\\n      final al = await _get(\'https://musicbrainz.org/ws/2/artist/?query=$aq&fmt=json&limit=5\');\\n      final same = [\\n        for (final a in (al?[\'artists\'] as List?)?.whereType<Map>() ?? const <Map>[])\\n          if (((a[\'score\'] as num?) ?? 0) >= 90 && a[\'id\'] != null && _sameArtist(\'${a[\'name\'] ?? \'\'}\', artist)) \'${a[\'id\']}\'\\n      ];\\n      if (same.length == 1) arid = same.first; // 헷갈릴 사람이 없을 때만\\n    }\\n    if (arid == null) return out;", 1], ["widgets/artist_info_sheet.dart", "  String get _key => \'artistInfo6:", "  String get _key => \'artistInfo7:", 1]]')
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
