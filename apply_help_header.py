# -*- coding: utf-8 -*-
# 설정 도움말 묶음 제목: "이렇게도 들을 수 있어요" → "다양하게 즐기기" (23개 언어)

import os, sys, json, re

L10N = os.path.join('lib', 'l10n')
NEW = json.loads('{"ko": "다양하게 즐기기", "en": "More ways to enjoy", "ja": "いろいろな楽しみ方", "zh": "多种方式畅享", "zh_Hant": "多種方式暢享", "vi": "Thưởng thức theo nhiều cách", "hi": "कई तरीकों से आनंद लें", "id": "Nikmati dengan berbagai cara", "th": "เพลิดเพลินได้หลายแบบ", "es": "Más formas de disfrutar", "pt": "Mais formas de curtir", "de": "Mehr Möglichkeiten zum Genießen", "fr": "Plus de façons d’en profiter", "ru": "Больше способов наслаждаться", "it": "Più modi per divertirti", "tr": "Farklı şekillerde keyfini çıkar", "pl": "Korzystaj na różne sposoby", "uk": "Більше способів насолоджуватися", "ro": "Mai multe moduri de a te bucura", "cs": "Další způsoby, jak si to užít", "hu": "Élvezd többféleképpen", "ar": "طرق متنوعة للاستمتاع", "ur": "لطف اٹھانے کے مختلف طریقے"}')
KEY = 'helpGuideHeader'


def dq(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def main():
    out = {}
    ok = True
    ko = os.path.join(L10N, 'app_ko.arb')
    if os.path.exists(ko) and json.load(open(ko, encoding='utf-8')).get(KEY) == NEW['ko']:
        print('이미 적용돼 있어요')
        return
    for lang, val in NEW.items():
        p = os.path.join(L10N, 'app_%s.arb' % lang)
        if not os.path.exists(p):
            print('❌ 파일이 없어요:', p); ok = False; continue
        raw = open(p, 'rb').read().decode('utf-8')
        lines = raw.split('\n')
        hit = [i for i, l in enumerate(lines) if l.lstrip().startswith('"%s"' % KEY)]
        if len(hit) != 1:
            print('❌ app_%s.arb 에서 못 찾았어요 (apply_help_guide.py 먼저)' % lang); ok = False; continue
        l = lines[hit[0]]
        comma = ',' if l.rstrip().rstrip('\r').endswith(',') else ''
        cr = '\r' if l.endswith('\r') else ''
        lines[hit[0]] = '  "%s": %s%s%s' % (KEY, json.dumps(val, ensure_ascii=False), comma, cr)
        t = '\n'.join(lines)
        try:
            assert json.loads(t)[KEY] == val
        except Exception as e:
            print('❌ app_%s.arb 확인 실패: %s' % (lang, e)); ok = False; continue
        out[p] = t
        print('✔ app_%s.arb' % lang)
    gen = {l: l for l in NEW if l != 'zh_Hant'}
    for lang, g in gen.items():
        p = os.path.join(L10N, 'app_localizations_%s.dart' % g)
        if not os.path.exists(p):
            print('❌ 파일이 없어요:', p); ok = False; continue
        raw = open(p, 'rb').read().decode('utf-8')
        lines = raw.split('\n')
        hit = [i for i, l in enumerate(lines) if l.startswith('  String get %s =>' % KEY)]
        langs = ['zh', 'zh_Hant'] if g == 'zh' else [lang]
        if len(hit) != len(langs):
            print('❌ app_localizations_%s.dart 에서 못 찾았어요' % g); ok = False; continue
        for i, L in zip(hit, langs):
            cr = '\r' if lines[i].endswith('\r') else ''
            lines[i] = '  String get %s => %s;%s' % (KEY, dq(NEW[L]), cr)
        out[p] = '\n'.join(lines)
        print('✔ app_localizations_%s.dart' % g)
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요'); sys.exit(1)
    for p, t in out.items():
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
