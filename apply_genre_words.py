# -*- coding: utf-8 -*-
# 장르: '팝 발라드' · '팝 댄스' 처럼 한글 여러 낱말로 된 장르가 외국어 화면에서 한글 그대로 나오던 것
#  → 뒤 낱말부터 아는 장르를 찾아서 그 장르로 (팝 발라드 → 발라드 · 팝 댄스 → 댄스 · 해외 팝 → 팝)
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'models', 'song.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
if '// 한글 여러 낱말 장르' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
old = """    final alias = _genreAlias[low];
    if (alias != null) return '@$alias'; // 많이 쓰는 장르 → 폰 언어로 보여 줌
"""
new = """    final alias = _genreAlias[low];
    if (alias != null) return '@$alias'; // 많이 쓰는 장르 → 폰 언어로 보여 줌
    // 한글 여러 낱말 장르 (팝 발라드 · 팝 댄스 · 국내 록) → 뒤 낱말부터 아는 장르 찾기
    // (안 그러면 외국어 화면에서 한글 그대로 나옴)
    if (RegExp(r'[가-힣]').hasMatch(g)) {
      final words = g.toLowerCase().split(RegExp(r'[\\s/]+')).where((w) => w.isNotEmpty).toList();
      for (final w in words.reversed) {
        final a = _genreAlias[w.replaceAll(RegExp(r'[\\-_.]'), '')];
        if (a != null) return '@$a';
      }
    }
"""
if s.count(old) != 1:
    print('❌ 찾을 코드를 못 찾았어요. 아무것도 저장 안 했어요.'); sys.exit(1)
s = s.replace(old, new); print('✔ song.dart · 한글 여러 낱말 장르')
for a, b in ['()', '[]', '{}']:
    if s.count(a) - s.count(b) != o.count(a) - o.count(b):
        print('❌ 괄호 짝이 안 맞아요. 아무것도 저장 안 했어요.'); sys.exit(1)
open(P, 'wb').write((s.replace('\n', '\r\n') if crlf else s).encode('utf-8'))
print('저장했어요.')
