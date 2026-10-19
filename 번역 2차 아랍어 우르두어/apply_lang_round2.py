# -*- coding: utf-8 -*-
# 번역 2차: 아랍어(ar)·우르두어(ur) 넣기 → 23개 언어 (오른쪽→왼쪽 글)
# 프로젝트 폴더에서: python apply_lang_round2.py   (lang_round2 폴더가 이 파일 옆에 있어야 해요)
import os, sys, re, json, shutil
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, 'lang_round2')
NEW = ['ar', 'ur']
L10N = os.path.join('lib', 'l10n')
RES = os.path.join('android', 'app', 'src', 'main', 'res')
def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)
if not os.path.isdir(DATA): fail('lang_round2 폴더를 못 찾았어요')
for p in [L10N, RES, os.path.join('lib', 'main.dart')]:
    if not os.path.exists(p): fail('프로젝트 폴더에서 실행해 주세요. 못 찾음: ' + p)
if os.path.exists(os.path.join(L10N, 'app_ar.arb')):
    print('이미 적용돼 있어요'); sys.exit(0)
pending, orig = {}, {}
def load(p):
    raw = open(p, 'rb').read().decode('utf-8'); return raw.replace('\r\n', '\n'), ('\r\n' in raw)
def edit(path, eds):
    if path in pending: s, crlf = pending[path]
    else:
        s, crlf = load(path); orig[path] = s
    for name, old, new in eds:
        n = s.count(old)
        if n != 1: fail(f'{path} · {name} — 찾을 코드를 못 찾았어요 ({n}곳)')
        s = s.replace(old, new); print('✔', path, '·', name)
    pending[path] = (s, crlf)

L_OLD = "'uk', 'hi', 'ro', 'cs', 'hu']"
L_NEW = "'uk', 'hi', 'ro', 'cs', 'hu', 'ar', 'ur']"
F_OLD = "const ['vi', 'ru', 'tr', 'pl', 'uk', 'ro', 'cs', 'hu', 'hi']"
F_NEW = "const ['vi', 'ru', 'tr', 'pl', 'uk', 'ro', 'cs', 'hu', 'hi', 'ar', 'ur']"
edit(os.path.join('lib', 'main.dart'), [
  ('언어 목록', "              Locale('hu'), // 헝가리어\n",
   "              Locale('hu'), // 헝가리어\n              Locale('ar'), // 아랍어 (오른쪽→왼쪽 화면은 Flutter가 알아서 뒤집음)\n              Locale('ur'), // 우르두어\n"),
  ('폰 언어 고르기', "'pl', " + L_OLD + ".contains(l.languageCode)", "'pl', " + L_NEW + ".contains(l.languageCode)"),
  ('기본 글꼴 쓰는 언어', F_OLD + '.contains(', F_NEW + '.contains('),
])
edit(os.path.join(L10N, 'locale_holder.dart'), [('폰 언어 고르기', "'pl', " + L_OLD, "'pl', " + L_NEW)])
edit(os.path.join('lib', 'providers', 'theme_provider.dart'), [
  ('설정 → 언어 목록', "    ('hi', 'हिन्दी'),\n", "    ('hi', 'हिन्दी'),\n    ('ar', 'العربية'),\n    ('ur', 'اردو'),\n")])
edit(os.path.join('lib', 'utils', 'device_country.dart'), [
  ('언어별 나라', "'cs': 'CZ', 'hu': 'HU',\n", "'cs': 'CZ', 'hu': 'HU',\n      'ar': 'SA', 'ur': 'PK',\n"),
  ('같은 말 쓰는 나라', "      'ro': ['RO', 'MD'],\n",
   "      'ro': ['RO', 'MD'],\n      'ar': ['SA', 'AE', 'EG', 'IQ', 'JO', 'LB', 'QA', 'BH', 'KW', 'OM', 'YE', 'PS', 'MA', 'TN', 'DZ', 'LY', 'SD'],\n      'ur': ['PK', 'IN'],\n"),
  ('앱 언어 목록', "'cs', 'hu'];", "'cs', 'hu', 'ar', 'ur'];"),
])
edit(os.path.join('lib', 'utils', 'title_font.dart'), [('기본 글꼴 쓰는 언어', F_OLD + '.any(', F_NEW + '.any(')])
edit(os.path.join('lib', 'utils', 'index_letter.dart'), [
  ('아랍 글자 막대 칸', "const _kIndexGroupsHi = [..._kHindiRows, 'A-Z', '#'];\n",
   "const _kIndexGroupsHi = [..._kHindiRows, 'A-Z', '#'];\n" + "// 아랍어·우르두어: 모양 비슷한 글자끼리 18칸 + A-Z + # (우르두어는 ک ہ ی 모양으로)\nconst _kArabicRows = ['ا', 'ب', 'ج', 'د', 'ر', 'س', 'ص', 'ط', 'ع', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];\nconst _kUrduRows = ['ا', 'ب', 'ج', 'د', 'ر', 'س', 'ص', 'ط', 'ع', 'ف', 'ق', 'ک', 'ل', 'م', 'ن', 'ہ', 'و', 'ی'];\nconst _kIndexGroupsAr = [..._kArabicRows, 'A-Z', '#'];\nconst _kIndexGroupsUr = [..._kUrduRows, 'A-Z', '#'];\n// 첫 글자 → 몇 번째 칸\nconst _arabicGroupOf = <String, int>{\n  'ا': 0, 'آ': 0, 'أ': 0, 'إ': 0, 'ٱ': 0, 'ء': 0,\n  'ب': 1, 'ت': 1, 'ث': 1, 'پ': 1, 'ٹ': 1,\n  'ج': 2, 'ح': 2, 'خ': 2, 'چ': 2,\n  'د': 3, 'ذ': 3, 'ڈ': 3,\n  'ر': 4, 'ز': 4, 'ڑ': 4, 'ژ': 4,\n  'س': 5, 'ش': 5,\n  'ص': 6, 'ض': 6,\n  'ط': 7, 'ظ': 7,\n  'ع': 8, 'غ': 8,\n  'ف': 9,\n  'ق': 10,\n  'ك': 11, 'ک': 11, 'گ': 11,\n  'ل': 12,\n  'م': 13,\n  'ن': 14, 'ں': 14,\n  'ه': 15, 'ہ': 15, 'ھ': 15, 'ة': 15,\n  'و': 16, 'ؤ': 16,\n  'ي': 17, 'ى': 17, 'ی': 17, 'ے': 17, 'ئ': 17,\n};\n\n/// 아랍 글자 첫 글자 → 막대 칸, 아니면 null\nString? _arabicRow(int c, bool urdu) {\n  final i = _arabicGroupOf[String.fromCharCode(c)];\n  if (i == null) return null;\n  return (urdu ? _kUrduRows : _kArabicRows)[i];\n}\n"),
  ('막대 고르기', "  if (lang == 'hi') return _kIndexGroupsHi;\n",
   "  if (lang == 'hi') return _kIndexGroupsHi;\n  if (lang == 'ar') return _kIndexGroupsAr;\n  if (lang == 'ur') return _kIndexGroupsUr;\n"),
  ('제목 → 칸', "  if (lang == 'hi') {\n",
   "  if (lang == 'ar' || lang == 'ur') {\n    final row = _arabicRow(c, lang == 'ur');\n    if (row != null) return row;\n    return latinLetterOf(c) != null ? 'A-Z' : '#';\n  }\n  if (lang == 'hi') {\n"),
])
edit(os.path.join('lib', 'screens', 'radio_country_stations_screen.dart'), [
  ('방송 언어 이름', "      'greek': 'Görög',\n    },\n  };\n", "      'greek': 'Görög',\n    },\n" + "    'ar': {\n      'english': 'الإنجليزية', 'spanish': 'الإسبانية', 'portuguese': 'البرتغالية', 'french': 'الفرنسية',\n      'german': 'الألمانية', 'italian': 'الإيطالية', 'hindi': 'الهندية', 'tamil': 'التاميلية',\n      'telugu': 'التيلوغوية', 'malayalam': 'المالايالامية', 'bengali': 'البنغالية', 'marathi': 'الماراثية',\n      'kannada': 'الكانادية', 'punjabi': 'البنجابية', 'gujarati': 'الغوجاراتية', 'urdu': 'الأردية',\n      'japanese': 'اليابانية', 'chinese': 'الصينية', 'mandarin': 'الماندرين', 'cantonese': 'الكانتونية',\n      'korean': 'الكورية', 'vietnamese': 'الفيتنامية', 'thai': 'التايلاندية', 'indonesian': 'الإندونيسية',\n      'malay': 'الملايوية', 'javanese': 'الجاوية', 'arabic': 'العربية', 'russian': 'الروسية',\n      'ukrainian': 'الأوكرانية', 'dutch': 'الهولندية', 'catalan': 'الكتالونية', 'basque': 'الباسكية',\n      'galician': 'الجاليكية', 'swiss german': 'الألمانية السويسرية', 'romansh': 'الرومانشية', 'turkish': 'التركية',\n      'polish': 'البولندية', 'swedish': 'السويدية', 'welsh': 'الويلزية', 'irish': 'الأيرلندية',\n      'filipino': 'الفلبينية', 'tagalog': 'التاغالوغية', 'persian': 'الفارسية', 'hebrew': 'العبرية',\n      'greek': 'اليونانية',\n    },\n    'ur': {\n      'english': 'انگریزی', 'spanish': 'ہسپانوی', 'portuguese': 'پرتگالی', 'french': 'فرانسیسی',\n      'german': 'جرمن', 'italian': 'اطالوی', 'hindi': 'ہندی', 'tamil': 'تمل',\n      'telugu': 'تیلگو', 'malayalam': 'ملیالم', 'bengali': 'بنگالی', 'marathi': 'مراٹھی',\n      'kannada': 'کنڑ', 'punjabi': 'پنجابی', 'gujarati': 'گجراتی', 'urdu': 'اردو',\n      'japanese': 'جاپانی', 'chinese': 'چینی', 'mandarin': 'مینڈارن', 'cantonese': 'کینٹونیز',\n      'korean': 'کوریائی', 'vietnamese': 'ویتنامی', 'thai': 'تھائی', 'indonesian': 'انڈونیشیائی',\n      'malay': 'مالے', 'javanese': 'جاوی', 'arabic': 'عربی', 'russian': 'روسی',\n      'ukrainian': 'یوکرینی', 'dutch': 'ڈچ', 'catalan': 'کاتالان', 'basque': 'باسک',\n      'galician': 'گالیشیائی', 'swiss german': 'سوئس جرمن', 'romansh': 'رومانش', 'turkish': 'ترکی',\n      'polish': 'پولش', 'swedish': 'سویڈش', 'welsh': 'ویلش', 'irish': 'آئرش',\n      'filipino': 'فلپائنی', 'tagalog': 'ٹیگالوگ', 'persian': 'فارسی', 'hebrew': 'عبرانی',\n      'greek': 'یونانی',\n    },\n" + "  };\n")])
edit(os.path.join('lib', 'screens', 'settings_screen.dart'), [
  ('언어 이름', "      'hu' => l.langNameHu,\n", "      'hu' => l.langNameHu,\n      'ar' => l.langNameAr,\n      'ur' => l.langNameUr,\n"),
  ('약관 언어', "'uk', 'ro', 'cs', 'hu']", "'uk', 'ro', 'cs', 'hu', 'ar', 'ur']"),
])
edit(os.path.join('lib', 'widgets', 'artist_info_sheet.dart'), [
  ('라틴 글자 아닌 언어', "'ar', 'he', 'el', 'uk'};", "'ar', 'he', 'el', 'uk', 'ur'};")])
edit(os.path.join(RES, 'xml', 'locales_config.xml'), [
  ('앱별 언어', '    <locale android:name="hu"/>\n', '    <locale android:name="hu"/>\n    <locale android:name="ar"/>\n    <locale android:name="ur"/>\n')])

pat = re.compile(r'"langNameHu"\s*:\s*"(?:[^"\\]|\\.)*"')
for code, vals in {"ko": ["아랍어", "우르두어"], "en": ["Arabic", "Urdu"], "ja": ["アラビア語", "ウルドゥー語"], "zh": ["阿拉伯语", "乌尔都语"], "zh_Hant": ["阿拉伯文", "烏爾都文"], "de": ["Arabisch", "Urdu"], "es": ["Árabe", "Urdu"], "fr": ["Arabe", "Ourdou"], "id": ["Arab", "Urdu"], "it": ["Arabo", "Urdu"], "pl": ["Arabski", "Urdu"], "pt": ["Árabe", "Urdu"], "ru": ["Арабский", "Урду"], "th": ["อาหรับ", "อูรดู"], "tr": ["Arapça", "Urduca"], "vi": ["Tiếng Ả Rập", "Tiếng Urdu"], "uk": ["Арабська", "Урду"], "hi": ["अरबी", "उर्दू"], "ro": ["Arabă", "Urdu"], "cs": ["Arabština", "Urdština"], "hu": ["Arab", "Urdu"]}.items():
    p = os.path.join(L10N, f'app_{code}.arb')
    if not os.path.exists(p): fail('못 찾음: ' + p)
    s, crlf = load(p)
    if '"langNameAr"' in s: fail(p + ' 에 이미 langNameAr가 있어요')
    m = list(pat.finditer(s))
    if len(m) != 1: fail(p + ' · langNameHu를 못 찾았어요')
    add = ''.join(f',\n  "{k}": {json.dumps(v, ensure_ascii=False)}' for k, v in zip(['langNameAr', 'langNameUr'], vals))
    s = s[:m[0].end()] + add + s[m[0].end():]
    try: json.loads(s)
    except Exception as e: fail(f'{p} JSON 오류: {e}')
    pending[p] = (s, crlf); print('✔', p, '· 새 언어 이름 2개')

copies = []
for c in NEW:
    copies.append((os.path.join(DATA, 'l10n', f'app_{c}.arb'), os.path.join(L10N, f'app_{c}.arb')))
    copies.append((os.path.join(DATA, 'res', f'values-{c}', 'strings.xml'), os.path.join(RES, f'values-{c}', 'strings.xml')))
for src, dst in copies:
    if not os.path.exists(src): fail('lang_round2 안에 없음: ' + src)
    if os.path.exists(dst): fail('이미 있는 파일: ' + dst)
for p, (s, _) in pending.items():
    if p.endswith('.dart'):
        o = orig.get(p, '')
        for a, b in ['()', '[]', '{}']:
            if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 짝이 안 맞아요')
for p, (s, crlf) in pending.items():
    open(p, 'wb').write((s.replace('\n', '\r\n') if crlf else s).encode('utf-8'))
for src, dst in copies:
    os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copyfile(src, dst); print('✔ 새 파일', dst)
print('저장했어요. 이제: flutter gen-l10n → flutter run')
