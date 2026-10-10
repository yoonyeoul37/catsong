# -*- coding: utf-8 -*-
# 가수 소개가 영어로 나올 때: 한국어 위키 문서 먼저 → 없으면 자동 번역 ("자동 번역" 표시)
import os, sys

PATH = os.path.join('lib', 'widgets', 'artist_info_sheet.dart')
if not os.path.exists(PATH):
    print('❌ lib/widgets/artist_info_sheet.dart 가 없어요 (apply_artist_info.py 먼저)'); sys.exit(1)

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '_translate(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
('번역 표시 자리',
"""  String? bio;
  String? bioUrl;
""",
"""  String? bio;
  String? bioUrl;
  bool bioTranslated = false; // 영어 소개를 자동 번역했는지
"""),

('저장할 때 번역 표시도',
"""        'bioUrl': bioUrl,
""",
"""        'bioUrl': bioUrl,
        'bioTranslated': bioTranslated,
"""),

('불러올 때 번역 표시도',
"""      ..bioUrl = m['bioUrl'] as String?
""",
"""      ..bioUrl = m['bioUrl'] as String?
      ..bioTranslated = m['bioTranslated'] == true
"""),

('소개 찾기: 폰 언어 문서 → 연결된 문서 → 자동 번역',
"""  // ── Wikipedia: 짧은 소개 (한국어 → 영어) ──
  static Future<void> wiki(_Info info, String artist) async {
    for (final lang in ['ko', 'en']) {
      final d = await _get('https://$lang.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(artist)}');
      if (d == null || d['type'] != 'standard') continue;
      final text = '${d['extract'] ?? ''}'.trim();
      final desc = '${d['description'] ?? ''}';
      if (text.isEmpty || !_music.hasMatch('$desc $text')) continue; // 가수 문서가 아니면 건너뛰기
      info.bio = text;
      info.bioUrl = ((d['content_urls'] as Map?)?['mobile'] as Map?)?['page'] as String?;
      info.picture ??= (d['thumbnail'] as Map?)?['source'] as String?;
      return;
    }
  }
""",
"""  // ── Wikipedia: 짧은 소개 ──
  static Future<Map?> _wikiSummary(String lang, String title, {bool check = true}) async {
    final d = await _get('https://$lang.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}');
    if (d == null || d['type'] != 'standard') return null;
    final text = '${d['extract'] ?? ''}'.trim();
    if (text.isEmpty) return null;
    if (check && !_music.hasMatch('${d['description'] ?? ''} $text')) return null; // 가수 문서가 아니면 건너뛰기
    return d;
  }

  static void _useWiki(_Info info, Map d) {
    info.bio = '${d['extract'] ?? ''}'.trim();
    info.bioUrl = ((d['content_urls'] as Map?)?['mobile'] as Map?)?['page'] as String?;
    info.picture ??= (d['thumbnail'] as Map?)?['source'] as String?;
  }

  /// 소개: ① 폰 언어 문서 → ② 영어 문서에 연결된 폰 언어 문서 → ③ 영어 소개를 자동 번역
  static Future<void> wiki(_Info info, String artist, String lang) async {
    final mine = await _wikiSummary(lang, artist);
    if (mine != null) {
      _useWiki(info, mine);
      return;
    }
    final en = await _wikiSummary('en', artist);
    if (en == null) return;
    if (lang == 'en') {
      _useWiki(info, en);
      return;
    }
    // 영어 문서에 연결된 한국어(폰 언어) 문서 찾기 (예: Coldplay → 콜드플레이)
    final enTitle = '${en['title'] ?? artist}';
    final ll = await _get('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=langlinks'
        '&lllang=$lang&redirects=1&titles=${Uri.encodeQueryComponent(enTitle)}');
    String? local;
    final pages = (ll?['query'] as Map?)?['pages'] as Map?;
    for (final p in pages?.values ?? const []) {
      final links = (p is Map) ? p['langlinks'] as List? : null;
      if (links != null && links.isNotEmpty && links.first is Map) {
        local = '${(links.first as Map)['*'] ?? ''}'.trim();
        break;
      }
    }
    if (local != null && local.isNotEmpty) {
      final d = await _wikiSummary(lang, local, check: false);
      if (d != null) {
        _useWiki(info, d);
        return;
      }
    }
    // 그래도 없으면 영어 소개를 번역 (안 되면 영어 그대로)
    _useWiki(info, en);
    final t = await _translate(info.bio!, 'en', lang);
    if (t != null && t.isNotEmpty) {
      info.bio = t;
      info.bioTranslated = true;
    }
  }

  /// 무료 번역 (MyMemory) — 한 번에 500자까지라 문장 단위로 나눠서
  static Future<String?> _translate(String text, String from, String to) async {
    final parts = <String>[];
    var cur = '';
    for (final s in text.split(RegExp(r'(?<=[.!?])\\s+'))) {
      if (cur.isNotEmpty && cur.length + s.length + 1 > 450) {
        parts.add(cur);
        cur = '';
      }
      cur = cur.isEmpty ? s : '$cur $s';
    }
    if (cur.isNotEmpty) parts.add(cur);
    final out = <String>[];
    for (final p in parts.take(4)) {
      final q = p.length > 480 ? p.substring(0, 480) : p;
      final d = await _get('https://api.mymemory.translated.net/get?langpair=$from%7C$to'
          '&de=info@knexm.com&q=${Uri.encodeQueryComponent(q)}');
      final status = d?['responseStatus'];
      final t = '${(d?['responseData'] as Map?)?['translatedText'] ?? ''}'.trim();
      if (t.isEmpty || (status is num && status != 200) || t.toUpperCase().contains('MYMEMORY')) return null;
      out.add(t);
    }
    return out.isEmpty ? null : out.join(' ');
  }
"""),

('폰 언어 넘겨주기 (1)',
"""  Future<void> _load({bool fresh = false}) async {
""",
"""  Future<void> _load({bool fresh = false}) async {
    final lang = Localizations.localeOf(context).languageCode;
"""),

('처음 그려진 뒤에 찾기 시작 (언어 읽으려고)',
"""    super.initState();
    _load();
  }""",
"""    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }"""),

('폰 언어 넘겨주기 (2)',
"""      _ArtistApi.wiki(info, _artist),
""",
"""      _ArtistApi.wiki(info, _artist, lang),
"""),

('예전에 저장한 영어 소개는 새로 찾기',
"""'artistInfo1:""",
"""'artistInfo2:"""),

('"자동 번역" 표시',
"""                const SizedBox(height: 4),
                Text(_bioOpen ? '접기' : '더 보기',
                    style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
""",
"""                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_bioOpen ? '접기' : '더 보기',
                        style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    if (info.bioTranslated) ...[
                      const Spacer(),
                      Text('자동 번역', style: TextStyle(color: hint, fontSize: 11.5)),
                    ],
                  ],
                ),
"""),
]

def bal(t):
    return tuple(t.count(a) - t.count(b) for a, b in ('()', '[]', '{}'))

ok = True
before = bal(src)
for name, old, new in edits:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')
if ok and bal(src) != before:
    ok = False; print('❌ 괄호 짝이 안 맞아요')

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
