# -*- coding: utf-8 -*-
# 가수 소개 자동 번역 고치기 (artist_info_sheet.dart)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PATH = 'lib/widgets/artist_info_sheet.dart'
MARK = 'static bool needsTranslate('

EDITS = [
('번역 상태 저장 칸',
"""  bool bioTranslated = false; // 영어 소개를 자동 번역했는지
""",
"""  bool bioTranslated = false; // 영어 소개를 자동 번역했는지
  bool bioEn = false; // 번역 못 하고 영어 그대로인지 (다음에 열 때 다시 번역)
"""),
('저장할 때 넣기',
"""        'bioTranslated': bioTranslated,
""",
"""        'bioTranslated': bioTranslated,
        'bioEn': bioEn,
"""),
('불러올 때 읽기',
"""      ..bioTranslated = m['bioTranslated'] == true
""",
"""      ..bioTranslated = m['bioTranslated'] == true
      ..bioEn = m['bioEn'] == true
"""),
('영어 소개 번역 (다시 시도 가능하게)',
"""    _useWiki(info, en);
    final t = await _translate(info.bio!, 'en', lang);
    if (t != null && t.isNotEmpty) {
      info.bio = t;
      info.bioTranslated = true;
    }
  }
""",
"""    _useWiki(info, en);
    info.bioEn = true;
    await translateBio(info, lang);
  }

  static const _nonLatin = {'ko', 'ja', 'zh', 'th', 'hi', 'ru', 'ar', 'he', 'el', 'uk'};

  /// 소개가 아직 영어 그대로인지
  static bool needsTranslate(_Info info, String lang) {
    final b = info.bio;
    if (b == null || b.isEmpty || info.bioTranslated || lang == 'en') return false;
    if (info.bioEn) return true;
    if (!_nonLatin.contains(lang)) return false;
    // 예전에 저장된 정보: 글자 대부분이 영어면 번역 필요
    final all = RegExp(r'[A-Za-z\\u0080-\\uFFFF]').allMatches(b).length;
    final latin = RegExp(r'[A-Za-z]').allMatches(b).length;
    return all > 0 && latin / all > 0.7;
  }

  /// 영어 소개 → 폰 언어 (안 되면 영어 그대로 두고 다음에 다시)
  static Future<bool> translateBio(_Info info, String lang) async {
    if (!needsTranslate(info, lang)) return false;
    final t = await _translate(info.bio!, 'en', lang);
    if (t == null || t.isEmpty) return false;
    info.bio = t;
    info.bioTranslated = true;
    info.bioEn = false;
    return true;
  }

  static String _unescape(String s) => s
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
"""),
('번역 실패해도 한 번 더 · 된 만큼은 쓰기',
"""    for (final p in parts.take(4)) {
      final q = p.length > 480 ? p.substring(0, 480) : p;
      final d = await _get('https://api.mymemory.translated.net/get?langpair=$from%7C$to'
          '&de=info@knexm.com&q=${Uri.encodeQueryComponent(q)}');
      final status = d?['responseStatus'];
      final t = '${(d?['responseData'] as Map?)?['translatedText'] ?? ''}'.trim();
      if (t.isEmpty || (status is num && status != 200) || t.toUpperCase().contains('MYMEMORY')) return null;
      out.add(t);
    }
    return out.isEmpty ? null : out.join(' ');
""",
"""    for (final p in parts.take(4)) {
      final q = p.length > 480 ? p.substring(0, 480) : p;
      String? t;
      for (var k = 0; k < 2 && t == null; k++) {
        if (k > 0) await Future.delayed(const Duration(milliseconds: 700));
        final d = await _get('https://api.mymemory.translated.net/get?langpair=$from%7C$to'
            '&de=info@knexm.com&q=${Uri.encodeQueryComponent(q)}');
        final ok = '${d?['responseStatus'] ?? ''}' == '200';
        final x = _unescape('${(d?['responseData'] as Map?)?['translatedText'] ?? ''}'.trim());
        if (ok && x.isNotEmpty && x != q && !x.toUpperCase().contains('MYMEMORY')) t = x;
      }
      if (t == null) break; // 여기까지 번역된 것만 쓰기
      out.add(t);
    }
    return out.isEmpty ? null : out.join(' ');
"""),
('저장된 정보가 영어면 열 때 다시 번역',
"""            if (!i.creditsDone) _loadCredits(i, p);
            return;
""",
"""            if (!i.creditsDone) _loadCredits(i, p);
            if (_ArtistApi.needsTranslate(i, lang)) {
              _ArtistApi.translateBio(i, lang).then((ok) async {
                if (!ok) return;
                try {
                  await p.setString(_key, jsonEncode({'at': '${m['at']}', 'info': i.toJson()}));
                } catch (_) {}
                if (mounted) setState(() {});
              });
            }
            return;
"""),
]

def main():
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ 파일이 없어요:', PATH); print('   프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    before = s.count('{') - s.count('}'), s.count('(') - s.count(')')
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    after = s.count('{') - s.count('}'), s.count('(') - s.count(')')
    if ok and before != after:
        print('❌ 괄호가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요 ✔')

main()
