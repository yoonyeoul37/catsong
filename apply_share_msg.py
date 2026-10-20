# -*- coding: utf-8 -*-
# 공유하기: 문구를 "파란소리로 같이 들어요 🎧"(23개 언어)로 + 주소를 앱 언어에 맞는 ssing.kr/app/○○/ 로
import json, os, re, sys

L10N = os.path.join('lib', 'l10n')
MENU = os.path.join('lib', 'widgets', 'more_menu_sheet.dart')

MSG = {
    'ko': '파란소리로 같이 들어요 🎧',
    'en': "Let's listen together on Paransori 🎧",
    'ja': 'Paransoriで一緒に聴こう 🎧',
    'zh': '一起用Paransori听吧 🎧',
    'zh_Hant': '一起用Paransori聽吧 🎧',
    'de': 'Lass uns zusammen mit Paransori hören 🎧',
    'es': 'Escuchemos juntos en Paransori 🎧',
    'fr': 'Écoutons ensemble sur Paransori 🎧',
    'it': 'Ascoltiamo insieme su Paransori 🎧',
    'pt': 'Vamos ouvir juntos no Paransori 🎧',
    'pl': 'Posłuchajmy razem w Paransori 🎧',
    'ru': 'Давай слушать вместе в Paransori 🎧',
    'tr': "Paransori'de birlikte dinleyelim 🎧",
    'id': 'Yuk dengarkan bareng di Paransori 🎧',
    'vi': 'Cùng nghe trên Paransori nhé 🎧',
    'th': 'มาฟังด้วยกันบน Paransori 🎧',
    'uk': 'Слухаймо разом у Paransori 🎧',
    'hi': 'चलो Paransori पर साथ सुनें 🎧',
    'ro': 'Hai să ascultăm împreună pe Paransori 🎧',
    'cs': 'Poslouchejme spolu v Paransori 🎧',
    'hu': 'Hallgassuk együtt a Paransorin 🎧',
    'ar': 'لنستمع معًا على Paransori 🎧',
    'ur': 'آئیں Paransori پر مل کر سنیں 🎧',
}

SHARE_NEW = "        Share.share('${shareText ?? tr.shareAppMessage}\\nhttps://ssing.kr/app/${_shareLangDir(tr.localeName)}'); // 앱 언어에 맞는 카톡 미리보기 주소 (누르면 플레이 스토어로)"
SHARE_OLDS = [
    "        Share.share('${shareText ?? tr.shareAppMessage}\\n$_kStoreUrl');",
    "        Share.share('${shareText ?? tr.shareAppMessage}\\nhttps://ssing.kr/app/'); // 카톡 미리보기가 나오는 주소 (누르면 플레이 스토어로)",
]
FUNC = '''
/// 공유 주소의 언어 폴더 (한국어는 app/ 바로, 그 밖은 app/en/ 처럼 · 없는 언어는 영어)
String _shareLangDir(String localeName) {
  const dirs = {'en', 'ja', 'zh', 'zh-Hant', 'de', 'es', 'fr', 'it', 'pt', 'pl', 'ru', 'tr', 'id', 'vi', 'th', 'uk', 'hi', 'ro', 'cs', 'hu', 'ar', 'ur'};
  final l = localeName.replaceAll('_', '-');
  if (l == 'ko') return '';
  return dirs.contains(l) ? '$l/' : 'en/';
}
'''


def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def save(p, s, crlf):
    if crlf:
        s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


out = {}
changed = 0
pat = re.compile(r'^(\s*"shareAppMessage"\s*:\s*)"(?:[^"\\]|\\.)*"', re.M)
for code, msg in MSG.items():
    p = os.path.join(L10N, f'app_{code}.arb')
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    s, crlf = load(p)
    if len(pat.findall(s)) != 1:
        fail(p + ' 에서 shareAppMessage 를 못 찾았어요')
    new = pat.sub(lambda m: m.group(1) + json.dumps(msg, ensure_ascii=False), s)
    json.loads(new)  # 파일이 깨지지 않았는지 확인
    if new == s:
        print('✔', code, '(이미 돼 있음)')
    else:
        print('✔', code, '→', msg)
        changed += 1
        out[p] = (new, crlf)

if not os.path.exists(MENU):
    fail('파일이 없어요: ' + MENU)
m, mcrlf = load(MENU)
before = m
if SHARE_NEW in m:
    print('✔ 공유 주소 (이미 돼 있음)')
else:
    for old in SHARE_OLDS:
        if m.count(old) == 1:
            m = m.replace(old, SHARE_NEW)
            print('✔ 공유 주소 → ssing.kr/app/언어/')
            break
    else:
        fail('more_menu_sheet.dart 공유 줄을 못 찾았어요')
if 'String _shareLangDir(' in m:
    print('✔ 언어 폴더 함수 (이미 돼 있음)')
else:
    m = m.rstrip('\n') + '\n' + FUNC
    print('✔ 언어 폴더 함수 넣기')
if m != before:
    out[MENU] = (m, mcrlf)

if not out:
    print('이미 적용돼 있어요')
    sys.exit(0)
for p, (s, crlf) in out.items():
    save(p, s, crlf)
print('저장했어요:', len(out), '개 파일')
