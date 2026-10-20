# -*- coding: utf-8 -*-
# 해외(한국어가 아닌 언어) 첫인사·끝인사 멜로디 넣기 — 한국어는 지금처럼 목소리
# 먼저 assets 폴더에 greet_intro.mp3 · greet_outro.mp3 를 넣어 둘 것
import os, re, sys

FILES = {
    'pubspec': 'pubspec.yaml',
    'main': os.path.join('lib', 'main.dart'),
    'home': os.path.join('lib', 'screens', 'home_screen.dart'),
    'nature': os.path.join('lib', 'screens', 'nature_sound_detail_screen.dart'),
    'player': os.path.join('lib', 'screens', 'player_screen.dart'),
    'radio': os.path.join('lib', 'screens', 'radio_player_screen.dart'),
    'mix': os.path.join('lib', 'screens', 'sound_mix_screen.dart'),
}

def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.'); sys.exit(1)

for a in ('greet_intro.mp3', 'greet_outro.mp3'):
    if not os.path.exists(os.path.join('assets', a)):
        fail(f'assets 폴더에 {a} 가 없어요. 먼저 넣어 주세요')

data = {}
for k, p in FILES.items():
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8')
    data[k] = [raw.replace('\r\n', '\n'), '\r\n' in raw, None]
for k in data:
    data[k][2] = data[k][0]

def edit(k, name, old, new, regex=False):
    s = data[k][0]
    done = (re.search(new, s) if regex else None) if False else (new.replace('\\', '') in s if regex else new in s)
    if done:
        print('✔', p_name(k), name, '(이미 돼 있음)'); return
    if regex:
        s2, n = re.subn(old, new, s)
    else:
        n = s.count(old); s2 = s.replace(old, new)
    if n != 1:
        fail(f'{p_name(k)} {name} — 찾을 코드를 못 찾았어요 ({n}곳)')
    data[k][0] = s2
    print('✔', p_name(k), name)

def p_name(k): return os.path.basename(FILES[k])

# pubspec: 소리 파일 등록
edit('pubspec', '멜로디 파일 등록',
     '    - assets/welcome_ko_v4.mp3\n',
     '    - assets/welcome_ko_v4.mp3\n    - assets/greet_intro.mp3   # 해외 첫인사 멜로디\n    - assets/greet_outro.mp3   # 해외 끝인사 멜로디\n')

# main.dart: 첫인사
edit('main', '해외 첫인사 멜로디',
     "    final welcomeAsset = langCode == 'ko' ? 'assets/welcome_ko_v4.mp3' : null;",
     "    final welcomeAsset = langCode == 'ko' ? 'assets/welcome_ko_v4.mp3' : 'assets/greet_intro.mp3'; // 해외: 첫인사 멜로디")

# 끝인사 5곳
SW_OLD = re.compile(r"(\n[ \t]*)case 'ja':\n[ \t]*farewellAsset = 'assets/farewell_ja\.mp3';\n[ \t]*break;\n[ \t]*case 'zh':\n[ \t]*farewellAsset = 'assets/farewell_zh\.mp3';\n[ \t]*break;\n([ \t]*)default:\n([ \t]*)farewellAsset = 'assets/farewell_en\.mp3';")
SW_NEW_MARK = "farewellAsset = 'assets/greet_outro.mp3'; // 해외: 끝인사 멜로디"
IF_OLD = re.compile(r"if \(langCode == 'ko' && context\.read<ThemeProvider>\(\)\.voiceGreetingEnabled\) \{(?: // 목소리는 한국어만)?")
IF_NEW = "if (context.read<ThemeProvider>().voiceGreetingEnabled) { // 한국어는 목소리 · 해외는 멜로디"
for k in ('home', 'nature', 'player', 'radio', 'mix'):
    s = data[k][0]
    if SW_NEW_MARK in s:
        print('✔', p_name(k), '끝인사 소리 (이미 돼 있음)')
    else:
        s, n = SW_OLD.subn(lambda m: f"{m.group(1)}default:\n{m.group(3)}{SW_NEW_MARK}", s)
        if n != 1: fail(f'{p_name(k)} 끝인사 소리 고르는 곳을 못 찾았어요 ({n}곳)')
        print('✔', p_name(k), '끝인사 소리 → 해외 멜로디')
    if IF_NEW in s:
        print('✔', p_name(k), '해외도 소리 내기 (이미 돼 있음)')
    else:
        s, n = IF_OLD.subn(IF_NEW, s)
        if n != 1: fail(f'{p_name(k)} 한국어만 소리 내는 줄을 못 찾았어요 ({n}곳)')
        print('✔', p_name(k), '해외도 소리 내기')
    data[k][0] = s

changed = [k for k in data if data[k][0] != data[k][2]]
if not changed:
    print('이미 적용돼 있어요'); sys.exit(0)
for k in changed:
    s, crlf, _ = data[k]
    if crlf: s = s.replace('\n', '\r\n')
    open(FILES[k], 'wb').write(s.encode('utf-8'))
print('저장했어요:', ', '.join(p_name(k) for k in changed))
