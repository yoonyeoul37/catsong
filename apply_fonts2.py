# -*- coding: utf-8 -*-
# 글꼴 5개 + 글자 크기 3단계
#  - 글꼴: 기본(스포카, 그대로) · 프리텐다드 · 나눔스퀘어라운드 · 고운돋움 · 마루 부리
#    전부 앱 안에 넣어서 인터넷 없이 바로 바뀜 (paran_fonts.zip 안의 글꼴을 assets/fonts 에 풀어 넣음)
#    예전에 뺀 글꼴을 쓰던 사람은 자동으로 기본 글꼴로
#  - 글자 크기: 막대 대신 버튼 3개 (작게 1.0 · 보통 1.12 · 크게 1.28) — 보통은 지금 크기 그대로
#  (paran_fonts.zip 을 이 파일과 같은 곳(프로젝트 폴더)에 두고 실행)
import os, sys, shutil, zipfile

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)

ZIP = 'paran_fonts.zip'
tp = find('theme_provider.dart', os.path.join('lib', 'providers'))
ss = find('settings_screen.dart', os.path.join('lib', 'screens'))
pub = 'pubspec.yaml'
for n, p in (('theme_provider.dart', tp), ('settings_screen.dart', ss), ('pubspec.yaml', pub)):
    if not p or not os.path.isfile(p):
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

if 'textSteps' in open(tp, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)
# 다운로드하면 이름이 'paran_fonts (1).zip' 처럼 바뀌거나, 압축이 풀린 폴더로 받아질 수 있어서 여러 곳을 찾아봄
NEED = ['Pretendard-Regular.ttf', 'Pretendard-Bold.ttf', 'NanumSquareRound-Regular.ttf', 'NanumSquareRound-Bold.ttf',
        'GowunDodum-Regular.ttf', 'MaruBuri-Regular.ttf', 'MaruBuri-Bold.ttf']

def find_fonts():
    # 이미 assets/fonts 에 다 넣어 뒀으면 그대로
    if all(os.path.isfile(os.path.join('assets', 'fonts', f)) for f in NEED):
        return ('ok', os.path.join('assets', 'fonts'))
    # 압축을 풀어서 글꼴 파일만 프로젝트 폴더나 다운로드 폴더에 둔 경우
    for d in ['.', os.path.join(os.path.expanduser('~'), 'Downloads')]:
        if os.path.isdir(d) and all(os.path.isfile(os.path.join(d, f)) for f in NEED):
            return ('loose', d)
    places = ['.', os.path.join(os.path.expanduser('~'), 'Downloads')]
    for d in places:
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            full = os.path.join(d, f)
            low = f.lower()
            if low.startswith('paran_fonts') and low.endswith('.zip') and os.path.isfile(full):
                return ('zip', full)
            if low.startswith('paran_fonts') and os.path.isdir(full):
                inner = os.path.join(full, 'assets', 'fonts')
                if os.path.isdir(inner):
                    return ('dir', inner)
                if any(x.endswith('.ttf') for x in os.listdir(full)):
                    return ('dir', full)
    return (None, None)

FKIND, FPATH = find_fonts()
if FKIND is None:
    have = [f for f in NEED if os.path.isfile(os.path.join('assets', 'fonts', f))]
    print('❌ 글꼴 파일을 다 못 찾았어요 — assets/fonts 에 있는 것: %d/7' % len(have))
    for f in NEED:
        if f not in have:
            print('   없음: %s' % f)
    print('   글꼴 파일 7개를 assets/fonts 폴더(Spoqa 글꼴 있는 곳)에 넣어 주세요'); sys.exit(1)
print('글꼴 묶음: %s' % FPATH)

writes = {}
ok = True
def edit(path, pairs):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

# ───────── pubspec.yaml: 글꼴 4개 등록 ─────────
edit(pub, [
    ('pubspec: 글꼴 4개 등록',
     '        - asset: assets/fonts/SpoqaHanSansNeo-Bold.ttf\n'
     '          weight: 700\n',
     '        - asset: assets/fonts/SpoqaHanSansNeo-Bold.ttf\n'
     '          weight: 700\n'
     '    # 설정 → 글꼴 (자주 쓰는 한글 2,350자 + 영문만 남긴 가벼운 버전)\n'
     '    - family: Pretendard\n'
     '      fonts:\n'
     '        - asset: assets/fonts/Pretendard-Regular.ttf\n'
     '        - asset: assets/fonts/Pretendard-Bold.ttf\n'
     '          weight: 700\n'
     '    - family: NanumSquareRound\n'
     '      fonts:\n'
     '        - asset: assets/fonts/NanumSquareRound-Regular.ttf\n'
     '        - asset: assets/fonts/NanumSquareRound-Bold.ttf\n'
     '          weight: 700\n'
     '    - family: GowunDodum\n'
     '      fonts:\n'
     '        - asset: assets/fonts/GowunDodum-Regular.ttf\n'
     '    - family: MaruBuri\n'
     '      fonts:\n'
     '        - asset: assets/fonts/MaruBuri-Regular.ttf\n'
     '        - asset: assets/fonts/MaruBuri-Bold.ttf\n'
     '          weight: 700\n'),
])

# ───────── theme_provider.dart ─────────
tsrc, _ = load(tp)
a = tsrc.find('  static const List<Map<String, String>> availableFonts = [\n')
b = tsrc.find('  ];\n', a) if a >= 0 else -1
if a < 0 or b < 0:
    print('❌ 테마: 글꼴 목록 (못 찾음)'); ok = False
else:
    old_list = tsrc[a:b + len('  ];\n')]
    edit(tp, [
        ('테마: 글꼴 목록 5개로 + 글자 크기 3단계', old_list,
         '  /// 설정 → 글꼴 (전부 앱 안에 있어서 인터넷 없이 바로)\n'
         '  static const List<Map<String, String>> availableFonts = [\n'
         "    {'key': 'default', 'name': 'Spoqa Han Sans Neo'},\n"
         "    {'key': 'pretendard', 'name': 'Pretendard'},\n"
         "    {'key': 'nanum_square_round', 'name': 'NanumSquareRound'},\n"
         "    {'key': 'gowun_dodum', 'name': 'GowunDodum'},\n"
         "    {'key': 'maru_buri', 'name': 'MaruBuri'},\n"
         '  ];\n'
         '\n'
         '  /// 설정 → 글자 크기 3단계 (보통 = 예전 기본 크기 그대로)\n'
         "  static const textSteps = <(String, double)>[('작게', 1.0), ('보통', 1.12), ('크게', 1.28)];\n"
         '\n'
         '  /// 지금 크기와 가장 가까운 단계\n'
         '  int get textStepIndex {\n'
         '    var best = 1;\n'
         '    for (var i = 0; i < textSteps.length; i++) {\n'
         '      if ((textSteps[i].$2 - _textScale).abs() < (textSteps[best].$2 - _textScale).abs()) best = i;\n'
         '    }\n'
         '    return best;\n'
         '  }\n'),
    ])
edit(tp, [
    ('테마: 예전 크기는 가장 가까운 단계로',
     '    if (textScale != null) {\n'
     '      _textScale = textScale;\n'
     '    }\n',
     '    if (textScale != null) {\n'
     '      _textScale = textScale;\n'
     '      _textScale = textSteps[textStepIndex].$2; // 예전 막대로 고른 크기는 가장 가까운 단계로\n'
     '    }\n'),
    ('테마: 뺀 글꼴을 쓰던 사람은 기본으로',
     '    if (fontFamily != null) {\n'
     '      _fontFamily = fontFamily;\n'
     '    }\n',
     '    if (fontFamily != null) {\n'
     "      _fontFamily = availableFonts.any((f) => f['key'] == fontFamily) ? fontFamily : 'default';\n"
     '    }\n'),
    ('테마: 앱 안 글꼴 쓰기',
     '  TextTheme getTextTheme() {\n'
     '    switch (_fontFamily) {\n',
     '  TextTheme getTextTheme() {\n'
     '    // 앱 안에 넣은 글꼴 (pubspec.yaml 의 family 이름)\n'
     '    const bundled = {\n'
     "      'pretendard': 'Pretendard',\n"
     "      'nanum_square_round': 'NanumSquareRound',\n"
     "      'gowun_dodum': 'GowunDodum',\n"
     "      'maru_buri': 'MaruBuri',\n"
     '    };\n'
     '    final f = bundled[_fontFamily];\n'
     '    if (f != null) return TextTheme(bodyLarge: TextStyle(fontFamily: f));\n'
     '    switch (_fontFamily) {\n'),
])

# ───────── settings_screen.dart ─────────
edit(ss, [
    ('설정: 글꼴 이름 (한글)',
     '    switch (key) {\n'
     "      case 'default': return l.fontDefault;\n",
     '    const names = {\n'
     "      'pretendard': '프리텐다드',\n"
     "      'nanum_square_round': '나눔스퀘어라운드',\n"
     "      'gowun_dodum': '고운돋움',\n"
     "      'maru_buri': '마루 부리',\n"
     '    };\n'
     '    if (names.containsKey(key)) return names[key]!;\n'
     '    switch (key) {\n'
     "      case 'default': return l.fontDefault;\n"),
])
ssrc, _ = writes[ss] if ss in writes else load(ss)
s0 = ssrc.find('  void _showTextSizeDialog(BuildContext context) {\n')
s1 = ssrc.find('\n}\n\n\n/// 넓은 먹색 설명', s0) if s0 >= 0 else -1
if s0 < 0 or s1 < 0 or ssrc.count('  void _showTextSizeDialog(BuildContext context) {\n') != 1:
    print('❌ 설정: 글자 크기 창 (못 찾음)'); ok = False
else:
    old_fn = ssrc[s0:s1 + 1]
    new_fn = (
        '  /// 글자 크기: 작게 · 보통 · 크게 (누르면 앱 전체가 바로 바뀜)\n'
        '  void _showTextSizeDialog(BuildContext context) {\n'
        '    final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n'
        '    final themeProvider = context.read<ThemeProvider>();\n'
        '    showParanSheet(\n'
        '      context,\n'
        '      title: AppLocalizations.of(context)!.textSize,\n'
        '      builder: (ctx, setSheet) {\n'
        '        final cur = themeProvider.textStepIndex;\n'
        '        return Column(\n'
        '          children: [\n'
        '            // 미리보기 (고른 크기 그대로 보임)\n'
        '            ParanCard(\n'
        '              padding: const EdgeInsets.all(16),\n'
        '              children: [\n'
        '                Text(AppLocalizations.of(context)!.preview,\n'
        '                    style: TextStyle(color: _sText(isDarkMode), fontSize: 16)),\n'
        '              ],\n'
        '            ),\n'
        '            // 작게 · 보통 · 크게 (고른 칸은 먹색)\n'
        '            ParanCard(\n'
        '              padding: const EdgeInsets.all(8),\n'
        '              children: [\n'
        '                Row(\n'
        '                  children: [\n'
        '                    for (var i = 0; i < ThemeProvider.textSteps.length; i++) ...[\n'
        '                      if (i > 0) const SizedBox(width: 8),\n'
        '                      Expanded(\n'
        '                        child: GestureDetector(\n'
        '                          behavior: HitTestBehavior.opaque,\n'
        '                          onTap: () {\n'
        "                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
        '                            themeProvider.setTextScale(ThemeProvider.textSteps[i].$2);\n'
        '                            setSheet(() {});\n'
        '                          },\n'
        '                          child: AnimatedContainer(\n'
        '                            duration: const Duration(milliseconds: 160),\n'
        '                            height: 66,\n'
        '                            decoration: BoxDecoration(\n'
        '                              color: i == cur ? _sText(isDarkMode) : _sInputBg(isDarkMode),\n'
        '                              borderRadius: BorderRadius.circular(12),\n'
        '                            ),\n'
        '                            child: Column(\n'
        '                              mainAxisAlignment: MainAxisAlignment.center,\n'
        '                              children: [\n'
        "                                Text('가',\n"
        '                                    textScaler: TextScaler.noScaling,\n'
        '                                    style: TextStyle(\n'
        '                                        color: i == cur ? _sBg(isDarkMode) : _sText(isDarkMode),\n'
        '                                        fontSize: 15 + i * 4.0,\n'
        '                                        height: 1.2,\n'
        '                                        fontWeight: FontWeight.w700)),\n'
        '                                const SizedBox(height: 3),\n'
        '                                Text(ThemeProvider.textSteps[i].$1,\n'
        '                                    textScaler: TextScaler.noScaling,\n'
        '                                    style: TextStyle(\n'
        '                                        color: i == cur ? _sBg(isDarkMode) : _sTextSub(isDarkMode),\n'
        '                                        fontSize: 12,\n'
        '                                        fontWeight: i == cur ? FontWeight.w700 : FontWeight.w500)),\n'
        '                              ],\n'
        '                            ),\n'
        '                          ),\n'
        '                        ),\n'
        '                      ),\n'
        '                    ],\n'
        '                  ],\n'
        '                ),\n'
        '              ],\n'
        '            ),\n'
        '          ],\n'
        '        );\n'
        '      },\n'
        '    );\n'
        '  }\n')
    edit(ss, [('설정: 글자 크기 막대 → 버튼 3개', old_fn, new_fn)])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)

# 글꼴 파일 풀기 (assets/fonts)
os.makedirs(os.path.join('assets', 'fonts'), exist_ok=True)
count = 0
if FKIND == 'zip':
    z = zipfile.ZipFile(FPATH)
    for n in z.namelist():
        base = n.split('/')[-1]
        if not base or not (base.endswith('.ttf') or base.endswith('.txt')):
            continue
        with z.open(n) as src, open(os.path.join('assets', 'fonts', base), 'wb') as dst:
            shutil.copyfileobj(src, dst)
        count += 1
elif FKIND == 'ok':
    count = len(NEED)  # 이미 들어 있음
elif FKIND == 'loose':
    for base in os.listdir(FPATH):
        if base in NEED or base == 'FONT_LICENSES.txt':
            src = os.path.join(FPATH, base)
            dst = os.path.join('assets', 'fonts', base)
            if FPATH == '.':
                shutil.move(src, dst)  # 프로젝트 폴더 맨 위에 흩어진 건 옮기기
            else:
                shutil.copyfile(src, dst)
            count += 1
else:
    for base in os.listdir(FPATH):
        if base.endswith('.ttf') or base.endswith('.txt'):
            shutil.copyfile(os.path.join(FPATH, base), os.path.join('assets', 'fonts', base))
            count += 1
print('✔ 글꼴 파일 %d개 (assets/fonts)' % count)

BK = os.path.join('..', 'paransori_backup_fonts')
for p, (text, c) in writes.items():
    bp = os.path.join(BK, p)
    os.makedirs(os.path.dirname(bp), exist_ok=True)
    shutil.copyfile(p, bp)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_fonts) — flutter pub get 후 flutter run')
