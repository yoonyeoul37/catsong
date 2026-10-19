# -*- coding: utf-8 -*-
# 번역 1차: 우크라이나어(uk)·힌디어(hi)·루마니아어(ro)·체코어(cs)·헝가리어(hu) 넣기 → 21개 언어
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_lang_round1.py
# (lang_round1 폴더가 이 파일 옆에 있어야 해요)
import os, sys, re, json, shutil
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, 'lang_round1')
NEW = ['uk', 'hi', 'ro', 'cs', 'hu']
L10N = os.path.join('lib', 'l10n')
RES = os.path.join('android', 'app', 'src', 'main', 'res')

def fail(msg):
    print('❌', msg, '— 아무것도 저장 안 했어요.'); sys.exit(1)

if not os.path.isdir(DATA): fail('lang_round1 폴더를 못 찾았어요 (압축을 프로젝트 폴더에 풀어 주세요)')
for p in [L10N, RES, os.path.join('lib', 'main.dart')]:
    if not os.path.exists(p): fail('프로젝트 폴더에서 실행해 주세요. 못 찾음: ' + p)
if os.path.exists(os.path.join(L10N, 'app_uk.arb')):
    print('이미 적용돼 있어요'); sys.exit(0)

writes = {}  # 경로 → 새 내용(str)
def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)
def put(p, s, crlf):
    writes[p] = (s.replace('\n', '\r\n') if crlf else s)

def edit(path, name_edits):
    if path in pending: s, crlf = pending[path]
    else:
        s, crlf = load(path); orig[path] = s
    for name, old, new in name_edits:
        n = s.count(old)
        if n != 1: fail(f'{path} · {name} — 찾을 코드를 못 찾았어요 ({n}곳)')
        s = s.replace(old, new); print('✔', path, '·', name)
    pending[path] = (s, crlf)
pending = {}
orig = {}

LIST_OLD = "const ['ko', 'en', 'ja', 'de', 'es', 'fr', 'id', 'pt', 'th', 'vi', 'ru', 'it', 'tr', 'pl']"
LIST_NEW = "const ['ko', 'en', 'ja', 'de', 'es', 'fr', 'id', 'pt', 'th', 'vi', 'ru', 'it', 'tr', 'pl', 'uk', 'hi', 'ro', 'cs', 'hu']"
FONT_OLD = "const ['vi', 'ru', 'tr', 'pl']"
FONT_NEW = "const ['vi', 'ru', 'tr', 'pl', 'uk', 'ro', 'cs', 'hu', 'hi']"

# 1) main.dart — 언어 목록 · 폰 언어 고르기 · 기본 글꼴 쓰는 언어
edit(os.path.join('lib', 'main.dart'), [
  ('언어 목록에 5개', "              Locale('pl'), // 폴란드어\n",
   "              Locale('pl'), // 폴란드어\n"
   "              Locale('uk'), // 우크라이나어\n"
   "              Locale('hi'), // 힌디어\n"
   "              Locale('ro'), // 루마니아어\n"
   "              Locale('cs'), // 체코어\n"
   "              Locale('hu'), // 헝가리어\n"),
  ('폰 언어 고르기', LIST_OLD, LIST_NEW),
  ('기본 글꼴 쓰는 언어', FONT_OLD + '.contains(themeProvider', FONT_NEW + '.contains(themeProvider'),
])
# 2) locale_holder.dart
edit(os.path.join(L10N, 'locale_holder.dart'), [('폰 언어 고르기', LIST_OLD, LIST_NEW)])
# 3) theme_provider.dart — 설정 → 언어 목록
edit(os.path.join('lib', 'providers', 'theme_provider.dart'), [
  ('체코어', "    ('id', 'Bahasa Indonesia'),\n", "    ('id', 'Bahasa Indonesia'),\n    ('cs', 'Čeština'),\n"),
  ('헝가리어', "    ('it', 'Italiano'),\n", "    ('it', 'Italiano'),\n    ('hu', 'Magyar'),\n"),
  ('루마니아어', "    ('pt', 'Português'),\n", "    ('pt', 'Português'),\n    ('ro', 'Română'),\n"),
  ('우크라이나어·힌디어', "    ('ru', 'Русский'),\n", "    ('ru', 'Русский'),\n    ('uk', 'Українська'),\n    ('hi', 'हिन्दी'),\n"),
])
# 4) device_country.dart — 라디오 '내 나라'
edit(os.path.join('lib', 'utils', 'device_country.dart'), [
  ('언어별 나라', "      'ru': 'RU', 'it': 'IT', 'tr': 'TR', 'pl': 'PL',\n",
   "      'ru': 'RU', 'it': 'IT', 'tr': 'TR', 'pl': 'PL',\n      'uk': 'UA', 'hi': 'IN', 'ro': 'RO', 'cs': 'CZ', 'hu': 'HU',\n"),
  ('루마니아어 몰도바', "      'it': ['IT', 'CH', 'SM'],\n", "      'it': ['IT', 'CH', 'SM'],\n      'ro': ['RO', 'MD'],\n"),
  ('앱 언어 목록', "'ru', 'it', 'tr', 'pl'];", "'ru', 'it', 'tr', 'pl', 'uk', 'hi', 'ro', 'cs', 'hu'];"),
])
# 5) title_font.dart — 도현에 없는 글자 (ă ș · č ř · ő ű · ї · हिन्दी)
edit(os.path.join('lib', 'utils', 'title_font.dart'), [('기본 글꼴 쓰는 언어', FONT_OLD + '.any(', FONT_NEW + '.any(')])
# 6) index_letter.dart — 우크라이나어도 А~Я 막대
edit(os.path.join('lib', 'utils', 'index_letter.dart'), [
  ('막대 칸', "  if (lang == 'ru') return _kIndexGroupsRu;", "  if (lang == 'ru' || lang == 'uk') return _kIndexGroupsRu;"),
  ('첫 글자 → 칸', "  if (lang == 'ru') {\n", "  if (lang == 'ru' || lang == 'uk') {\n"),
])
# 7) radio_country_stations_screen.dart — 방송 언어 이름
edit(os.path.join('lib', 'screens', 'radio_country_stations_screen.dart'), [
  ('방송 언어 이름 5개', "      'greek': 'Grecki',\n    },\n  };\n",
   "      'greek': 'Grecki',\n    },\n" + "    'uk': {\n      'english': 'Англійська', 'spanish': 'Іспанська', 'portuguese': 'Португальська', 'french': 'Французька',\n      'german': 'Німецька', 'italian': 'Італійська', 'hindi': 'Гінді', 'tamil': 'Тамільська',\n      'telugu': 'Телугу', 'malayalam': 'Малаялам', 'bengali': 'Бенгальська', 'marathi': 'Маратхі',\n      'kannada': 'Каннада', 'punjabi': 'Панджабі', 'gujarati': 'Гуджараті', 'urdu': 'Урду',\n      'japanese': 'Японська', 'chinese': 'Китайська', 'mandarin': 'Путунхуа', 'cantonese': 'Кантонська',\n      'korean': 'Корейська', 'vietnamese': 'В’єтнамська', 'thai': 'Тайська', 'indonesian': 'Індонезійська',\n      'malay': 'Малайська', 'javanese': 'Яванська', 'arabic': 'Арабська', 'russian': 'Російська',\n      'ukrainian': 'Українська', 'dutch': 'Нідерландська', 'catalan': 'Каталанська', 'basque': 'Баскська',\n      'galician': 'Галісійська', 'swiss german': 'Швейцарська німецька', 'romansh': 'Ретороманська', 'turkish': 'Турецька',\n      'polish': 'Польська', 'swedish': 'Шведська', 'welsh': 'Валлійська', 'irish': 'Ірландська',\n      'filipino': 'Філіппінська', 'tagalog': 'Тагальська', 'persian': 'Перська', 'hebrew': 'Іврит',\n      'greek': 'Грецька',\n    },\n    'hi': {\n      'english': 'अंग्रेज़ी', 'spanish': 'स्पेनिश', 'portuguese': 'पुर्तगाली', 'french': 'फ़्रेंच',\n      'german': 'जर्मन', 'italian': 'इतालवी', 'hindi': 'हिन्दी', 'tamil': 'तमिल',\n      'telugu': 'तेलुगु', 'malayalam': 'मलयालम', 'bengali': 'बांग्ला', 'marathi': 'मराठी',\n      'kannada': 'कन्नड़', 'punjabi': 'पंजाबी', 'gujarati': 'गुजराती', 'urdu': 'उर्दू',\n      'japanese': 'जापानी', 'chinese': 'चीनी', 'mandarin': 'मंदारिन', 'cantonese': 'कैंटोनीज़',\n      'korean': 'कोरियन', 'vietnamese': 'वियतनामी', 'thai': 'थाई', 'indonesian': 'इंडोनेशियाई',\n      'malay': 'मलय', 'javanese': 'जावानीज़', 'arabic': 'अरबी', 'russian': 'रूसी',\n      'ukrainian': 'यूक्रेनी', 'dutch': 'डच', 'catalan': 'कैटलन', 'basque': 'बास्क',\n      'galician': 'गैलिशियन', 'swiss german': 'स्विस जर्मन', 'romansh': 'रोमांश', 'turkish': 'तुर्की',\n      'polish': 'पोलिश', 'swedish': 'स्वीडिश', 'welsh': 'वेल्श', 'irish': 'आयरिश',\n      'filipino': 'फ़िलिपिनो', 'tagalog': 'तागालोग', 'persian': 'फ़ारसी', 'hebrew': 'हिब्रू',\n      'greek': 'ग्रीक',\n    },\n    'ro': {\n      'english': 'Engleză', 'spanish': 'Spaniolă', 'portuguese': 'Portugheză', 'french': 'Franceză',\n      'german': 'Germană', 'italian': 'Italiană', 'hindi': 'Hindi', 'tamil': 'Tamilă',\n      'telugu': 'Telugu', 'malayalam': 'Malayalam', 'bengali': 'Bengaleză', 'marathi': 'Marathi',\n      'kannada': 'Kannada', 'punjabi': 'Punjabi', 'gujarati': 'Gujarati', 'urdu': 'Urdu',\n      'japanese': 'Japoneză', 'chinese': 'Chineză', 'mandarin': 'Mandarină', 'cantonese': 'Cantoneză',\n      'korean': 'Coreeană', 'vietnamese': 'Vietnameză', 'thai': 'Thailandeză', 'indonesian': 'Indoneziană',\n      'malay': 'Malaeză', 'javanese': 'Javaneză', 'arabic': 'Arabă', 'russian': 'Rusă',\n      'ukrainian': 'Ucraineană', 'dutch': 'Neerlandeză', 'catalan': 'Catalană', 'basque': 'Bască',\n      'galician': 'Galiciană', 'swiss german': 'Germană elvețiană', 'romansh': 'Romanșă', 'turkish': 'Turcă',\n      'polish': 'Poloneză', 'swedish': 'Suedeză', 'welsh': 'Galeză', 'irish': 'Irlandeză',\n      'filipino': 'Filipineză', 'tagalog': 'Tagalog', 'persian': 'Persană', 'hebrew': 'Ebraică',\n      'greek': 'Greacă',\n    },\n    'cs': {\n      'english': 'Angličtina', 'spanish': 'Španělština', 'portuguese': 'Portugalština', 'french': 'Francouzština',\n      'german': 'Němčina', 'italian': 'Italština', 'hindi': 'Hindština', 'tamil': 'Tamilština',\n      'telugu': 'Telugština', 'malayalam': 'Malajálamština', 'bengali': 'Bengálština', 'marathi': 'Maráthština',\n      'kannada': 'Kannadština', 'punjabi': 'Paňdžábština', 'gujarati': 'Gudžarátština', 'urdu': 'Urdština',\n      'japanese': 'Japonština', 'chinese': 'Čínština', 'mandarin': 'Mandarínština', 'cantonese': 'Kantonština',\n      'korean': 'Korejština', 'vietnamese': 'Vietnamština', 'thai': 'Thajština', 'indonesian': 'Indonéština',\n      'malay': 'Malajština', 'javanese': 'Javánština', 'arabic': 'Arabština', 'russian': 'Ruština',\n      'ukrainian': 'Ukrajinština', 'dutch': 'Nizozemština', 'catalan': 'Katalánština', 'basque': 'Baskičtina',\n      'galician': 'Galicijština', 'swiss german': 'Švýcarská němčina', 'romansh': 'Rétorománština', 'turkish': 'Turečtina',\n      'polish': 'Polština', 'swedish': 'Švédština', 'welsh': 'Velština', 'irish': 'Irština',\n      'filipino': 'Filipínština', 'tagalog': 'Tagalština', 'persian': 'Perština', 'hebrew': 'Hebrejština',\n      'greek': 'Řečtina',\n    },\n    'hu': {\n      'english': 'Angol', 'spanish': 'Spanyol', 'portuguese': 'Portugál', 'french': 'Francia',\n      'german': 'Német', 'italian': 'Olasz', 'hindi': 'Hindi', 'tamil': 'Tamil',\n      'telugu': 'Telugu', 'malayalam': 'Malajálam', 'bengali': 'Bengáli', 'marathi': 'Maráthi',\n      'kannada': 'Kannada', 'punjabi': 'Pandzsábi', 'gujarati': 'Gudzsaráti', 'urdu': 'Urdu',\n      'japanese': 'Japán', 'chinese': 'Kínai', 'mandarin': 'Mandarin', 'cantonese': 'Kantoni',\n      'korean': 'Koreai', 'vietnamese': 'Vietnámi', 'thai': 'Thai', 'indonesian': 'Indonéz',\n      'malay': 'Maláj', 'javanese': 'Jávai', 'arabic': 'Arab', 'russian': 'Orosz',\n      'ukrainian': 'Ukrán', 'dutch': 'Holland', 'catalan': 'Katalán', 'basque': 'Baszk',\n      'galician': 'Galiciai', 'swiss german': 'Svájci német', 'romansh': 'Romans', 'turkish': 'Török',\n      'polish': 'Lengyel', 'swedish': 'Svéd', 'welsh': 'Walesi', 'irish': 'Ír',\n      'filipino': 'Filippínó', 'tagalog': 'Tagalog', 'persian': 'Perzsa', 'hebrew': 'Héber',\n      'greek': 'Görög',\n    },\n" + "  };\n"),
])
# 8) settings_screen.dart — 언어 이름
edit(os.path.join('lib', 'screens', 'settings_screen.dart'), [
  ('언어 이름', "      'pl' => l.langNamePl,\n",
   "      'pl' => l.langNamePl,\n      'uk' => l.langNameUk,\n      'hi' => l.langNameHi,\n"
   "      'ro' => l.langNameRo,\n      'cs' => l.langNameCs,\n      'hu' => l.langNameHu,\n"),
])
# 9) locales_config.xml — 폰 설정 → 앱 → 언어
edit(os.path.join(RES, 'xml', 'locales_config.xml'), [
  ('앱별 언어', '    <locale android:name="pl"/>\n',
   '    <locale android:name="pl"/>\n' + ''.join(f'    <locale android:name="{c}"/>\n' for c in NEW)),
])

# 10) 기존 16개 arb에 새 언어 이름 5개
pat = re.compile(r'"langNamePl"\s*:\s*"(?:[^"\\]|\\.)*"')
for code, vals in {"ko": ["우크라이나어", "힌디어", "루마니아어", "체코어", "헝가리어"], "en": ["Ukrainian", "Hindi", "Romanian", "Czech", "Hungarian"], "ja": ["ウクライナ語", "ヒンディー語", "ルーマニア語", "チェコ語", "ハンガリー語"], "zh": ["乌克兰语", "印地语", "罗马尼亚语", "捷克语", "匈牙利语"], "zh_Hant": ["烏克蘭文", "印地文", "羅馬尼亞文", "捷克文", "匈牙利文"], "de": ["Ukrainisch", "Hindi", "Rumänisch", "Tschechisch", "Ungarisch"], "es": ["Ucraniano", "Hindi", "Rumano", "Checo", "Húngaro"], "fr": ["Ukrainien", "Hindi", "Roumain", "Tchèque", "Hongrois"], "id": ["Ukraina", "Hindi", "Rumania", "Ceko", "Hungaria"], "it": ["Ucraino", "Hindi", "Rumeno", "Ceco", "Ungherese"], "pl": ["Ukraiński", "Hindi", "Rumuński", "Czeski", "Węgierski"], "pt": ["Ucraniano", "Hindi", "Romeno", "Tcheco", "Húngaro"], "ru": ["Украинский", "Хинди", "Румынский", "Чешский", "Венгерский"], "th": ["ยูเครน", "ฮินดี", "โรมาเนีย", "เช็ก", "ฮังการี"], "tr": ["Ukraynaca", "Hintçe", "Rumence", "Çekçe", "Macarca"], "vi": ["Tiếng Ukraina", "Tiếng Hindi", "Tiếng Romania", "Tiếng Séc", "Tiếng Hungary"]}.items():
    p = os.path.join(L10N, f'app_{code}.arb')
    if not os.path.exists(p): fail('못 찾음: ' + p)
    s, crlf = load(p)
    if '"langNameUk"' in s: fail(p + ' 에 이미 langNameUk가 있어요')
    m = list(pat.finditer(s))
    if len(m) != 1: fail(p + ' · langNamePl을 못 찾았어요')
    add = ''.join(f',\n  "{k}": {json.dumps(v, ensure_ascii=False)}' for k, v in zip(
        ['langNameUk', 'langNameHi', 'langNameRo', 'langNameCs', 'langNameHu'], vals))
    s = s[:m[0].end()] + add + s[m[0].end():]
    try: json.loads(s)
    except Exception as e: fail(f'{p} 고친 뒤 JSON 오류: {e}')
    pending[p] = (s, crlf); print('✔', p, '· 새 언어 이름 5개')

# 11) 새 파일 (arb 5개 + 위젯·알림 글자 5개)
copies = []
for c in NEW:
    copies.append((os.path.join(DATA, 'l10n', f'app_{c}.arb'), os.path.join(L10N, f'app_{c}.arb')))
    copies.append((os.path.join(DATA, 'res', f'values-{c}', 'strings.xml'), os.path.join(RES, f'values-{c}', 'strings.xml')))
for src, dst in copies:
    if not os.path.exists(src): fail('lang_round1 안에 없음: ' + src)
    if os.path.exists(dst): fail('이미 있는 파일: ' + dst)
    if src.endswith('.arb'):
        try: json.loads(open(src, 'rb').read().decode('utf-8'))
        except Exception as e: fail(f'{src} JSON 오류: {e}')

# 괄호 짝 확인 (dart)
for p, (s, _) in pending.items():
    if p.endswith('.dart'):
        for a, b in ['()', '[]', '{}']:
            o = orig.get(p, '')
            if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 {a}{b} 짝이 안 맞아요')

# ── 여기까지 다 통과해야 저장 ──
for p, (s, crlf) in pending.items():
    open(p, 'wb').write((s.replace('\n', '\r\n') if crlf else s).encode('utf-8'))
for src, dst in copies:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst); print('✔ 새 파일', dst)
print('저장했어요. 이제: flutter gen-l10n → flutter run')
