# -*- coding: utf-8 -*-
# 음악 화면 위쪽: 파란소리 로고 → '내 음악' + 작은 소리 막대 / MY MUSIC (A안: 왼쪽 정렬, 오른쪽 버튼 5개 그대로)
# 메인 홈은 파란소리 로고 그대로 (로고 누르면 소개도 메인에서 그대로) — 16개 언어
import os, re, sys, json
sys.stdout.reconfigure(encoding='utf-8')
H = os.path.join('lib', 'screens', 'home_screen.dart')
W = os.path.join('lib', 'widgets', 'logo_shine.dart')
D = os.path.join('lib', 'l10n')
T = {'ko': '내 음악', 'en': 'My Music', 'ja': 'マイミュージック', 'zh': '我的音乐', 'zh_Hant': '我的音樂',
     'de': 'Meine Musik', 'es': 'Mi música', 'fr': 'Ma musique', 'it': 'La mia musica', 'pt': 'Minhas músicas',
     'pl': 'Moja muzyka', 'ru': 'Моя музыка', 'tr': 'Müziğim', 'id': 'Musikku', 'vi': 'Nhạc của tôi', 'th': 'เพลงของฉัน'}

def load(p):
    if not os.path.exists(p):
        print('❌ 파일을 못 찾았어요:', p); sys.exit(1)
    r = open(p, 'rb').read().decode('utf-8')
    return r.replace('\r\n', '\n'), '\r\n' in r

h, hcr = load(H)
w, wcr = load(W)
if 'tr.menuHeadMusic' in h:
    print('이미 적용돼 있어요'); sys.exit(0)
if "fontFamily: 'PretendardTitle'" not in w:
    print('❌ apply_menu_header.py를 먼저 실행해 주세요. 아무것도 저장 안 했어요.'); sys.exit(1)

def rep(s, name, old, new):
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    print('✔', name)
    return s.replace(old, new)

# 1) 공용 제목(MenuTitle): 영문 부제 직접 넣기 + 왼쪽 정렬 고르기
w = rep(w, '제목 부품: 영문 부제·왼쪽 정렬 칸',
"""  final VoidCallback? onTap; // 누르면 (나라별 라디오: 나라 고르기)
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark, this.subWidget, this.onTap});""",
"""  final VoidCallback? onTap; // 누르면 (나라별 라디오: 나라 고르기)
  final String? caps; // 영문 부제를 직접 (내 음악: MY MUSIC)
  final bool alignStart; // 왼쪽 정렬 (음악 화면: 오른쪽 버튼이 많아서)
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark, this.subWidget, this.onTap, this.caps, this.alignStart = false});""")
w = rep(w, '제목 부품: 영문 부제 직접',
"""    String? c;
    if (title == tr.catRadio) c = 'RADIO';""",
"""    String? c = caps;
    if (title == tr.catRadio) c = 'RADIO';""")
w = rep(w, '제목 부품: 정렬',
"""    final col = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,""",
"""    final col = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,""")

# 2) 홈: 음악 화면일 때만 새 제목
if "import '../widgets/logo_shine.dart';" not in h:
    h = rep(h, '홈: 제목 부품 불러오기', "import '../l10n/locale_holder.dart';\n",
            "import '../l10n/locale_holder.dart';\nimport '../widgets/logo_shine.dart';\n")
h = rep(h, '홈: 음악 화면 제목',
"""          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openIntro,""",
"""          // 음악 화면: 다른 메뉴와 같은 제목 (내 음악 + 소리 막대 / MY MUSIC), 버튼이 많아서 왼쪽 정렬
          : _showMusicLibrary
              ? MenuTitle(title: tr.menuHeadMusic, sub: '', isDark: isDarkMode, caps: 'MY MUSIC', alignStart: true)
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openIntro,""")

# 3) 번역 (menuHeadRest 줄 다음에)
arbs = {}
for lang, v in T.items():
    p = os.path.join(D, f'app_{lang}.arb')
    if not os.path.exists(p):
        print(f'❌ {p} 파일이 없어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    t = open(p, 'rb').read().decode('utf-8')
    if '"menuHeadMusic"' in t:
        continue
    nl = '\r\n' if '\r\n' in t else '\n'
    m = re.search(r'^([ \t]*)"menuHeadRest"\s*:\s*"(?:[^"\\]|\\.)*",[ \t]*\r?\n', t, re.M)
    if not m:
        print(f'❌ {lang}: menuHeadRest 줄을 못 찾았어요. apply_menu_header.py를 먼저 실행해 주세요.'); sys.exit(1)
    t2 = t[:m.end()] + f'{m.group(1)}"menuHeadMusic": {json.dumps(v, ensure_ascii=False)},{nl}' + t[m.end():]
    assert json.loads(t2)['menuHeadMusic'] == v
    arbs[p] = t2
print(f'✔ 번역 {len(arbs)}개 언어')

def save(p, s, cr):
    if cr: s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))
save(H, h, hcr); save(W, w, wcr)
for p, t2 in arbs.items():
    open(p, 'wb').write(t2.encode('utf-8'))
print('저장했어요.')
