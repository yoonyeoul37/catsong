# -*- coding: utf-8 -*-
# 파란소리 소개 화면: '이름 이야기' 제목만 → '파란소리에 담긴 의미' (16개 언어) — 본문·디자인은 그대로
import os, re, sys, json
sys.stdout.reconfigure(encoding='utf-8')
D = os.path.join('lib', 'l10n')
L = {
 'ko': '파란소리에 담긴 의미',
 'en': 'The Meaning Behind Paransori',
 'ja': 'Paransoriにこめた意味',
 'zh': 'Paransori 的含义',
 'zh_Hant': 'Paransori 的含義',
 'de': 'Was Paransori bedeutet',
 'es': 'El significado de Paransori',
 'fr': 'Le sens de Paransori',
 'it': 'Il significato di Paransori',
 'pt': 'O significado de Paransori',
 'pl': 'Znaczenie nazwy Paransori',
 'ru': 'Что значит Paransori',
 'tr': "Paransori'nin anlamı",
 'id': 'Makna di balik Paransori',
 'vi': 'Ý nghĩa của Paransori',
 'th': 'ความหมายของ Paransori',
}
pat = re.compile(r'("introNameLabel"\s*:\s*)"(?:[^"\\]|\\.)*"')
out = {}
for lang, text in L.items():
    p = os.path.join(D, f'app_{lang}.arb')
    if not os.path.exists(p):
        print(f'❌ {p} 파일이 없어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    if json.loads(raw).get('introNameLabel') == text:
        continue
    new, n = pat.subn(lambda m, t=text: m.group(1) + json.dumps(t, ensure_ascii=False), raw)
    if n != 1:
        print(f'❌ {lang}: introNameLabel을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    if json.loads(new)['introNameLabel'] != text:
        print(f'❌ {lang}: 바꾼 뒤 확인 실패. 아무것도 저장 안 했어요.'); sys.exit(1)
    out[p] = new
    print('✔', lang, '→', text)
if not out:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, new in out.items():
    open(p, 'wb').write(new.encode('utf-8'))
print(f'저장했어요. ({len(out)}개 언어)')
