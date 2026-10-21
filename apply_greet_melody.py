# -*- coding: utf-8 -*-
# 한국어 첫인사·끝인사도 해외처럼 멜로디로 + 한국어 목소리 파일은 '파란소리 자료'로 옮겨 보관
import os, re, sys, shutil

MOVE_TO = os.path.join('..', '파란소리 자료', '한국어 인사 목소리')
VOICE_FILES = ['assets/welcome_ko_v4.mp3', 'assets/farewell_ko_v4.mp3']

NEW_FAREWELL = r"\1const farewellAsset = 'assets/greet_outro.mp3'; // 끝인사: 어느 언어나 멜로디 (한국어 목소리는 '파란소리 자료'에 보관)\n"

# 끝인사 switch (한국어 → 목소리, 해외 → 멜로디)
SWITCH = re.compile(
    r"( *)final langCode = Localizations\.localeOf\(context\)\.languageCode;\n"
    r" *late final String farewellAsset;\n"
    r" *switch \(langCode\) \{\n"
    r" *case 'ko':\n"
    r" *farewellAsset = 'assets/farewell_ko_v4\.mp3';\n"
    r" *break;\n"
    r" *default:\n"
    r" *farewellAsset = 'assets/greet_outro\.mp3';[^\n]*\n"
    r" *\}\n"
)
# 팟캐스트: 한 줄짜리
PODCAST = re.compile(
    r"( *)final langCode = Localizations\.localeOf\(context\)\.languageCode;\n"
    r" *final farewellAsset = langCode == 'ko' \? 'assets/farewell_ko_v4\.mp3' : 'assets/greet_outro\.mp3';\n"
)
# 첫인사 (main.dart)
WELCOME = re.compile(
    r"( *)final langCode = Localizations\.localeOf\(context\)\.languageCode;\n"
    r" *final welcomeAsset = langCode == 'ko' \? 'assets/welcome_ko_v4\.mp3' : 'assets/greet_intro\.mp3';[^\n]*\n"
    r" *if \(welcomeAsset == null\) return;\n"
)
NEW_WELCOME = r"\1const welcomeAsset = 'assets/greet_intro.mp3'; // 첫인사: 어느 언어나 멜로디 (한국어 목소리는 '파란소리 자료'에 보관)\n"

OLD_NOTE = '// 한국어는 목소리 · 해외는 멜로디'
NEW_NOTE = '// 어느 언어나 멜로디'

JOBS = [
    ('lib/main.dart', WELCOME, NEW_WELCOME, False),
    ('lib/screens/home_screen.dart', SWITCH, NEW_FAREWELL, True),
    ('lib/screens/player_screen.dart', SWITCH, NEW_FAREWELL, False),
    ('lib/screens/radio_player_screen.dart', SWITCH, NEW_FAREWELL, True),
    ('lib/screens/nature_sound_detail_screen.dart', SWITCH, NEW_FAREWELL, True),
    ('lib/screens/sound_mix_screen.dart', SWITCH, NEW_FAREWELL, True),
    ('lib/podcast/podcast_screens.dart', PODCAST, NEW_FAREWELL, True),
]


def read(path):
    with open(path, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)


def main():
    out = {}
    already = 0
    for path, pat, new, has_note in JOBS:
        p = os.path.normpath(path)
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        text, crlf = read(p)
        if '_ko_v4.mp3' not in text:
            already += 1
            print('  (이미 바뀜)', os.path.basename(p))
            continue
        text, n = pat.subn(new, text)
        if n != 1:
            print('❌', os.path.basename(p), '— 바꿀 곳을 못 찾았어요 (찾은 개수: %d). 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        if has_note:
            if text.count(OLD_NOTE) != 1:
                print('❌', os.path.basename(p), '— 설명 글을 못 찾았어요. 아무것도 저장 안 했어요')
                sys.exit(1)
            text = text.replace(OLD_NOTE, NEW_NOTE)
        if '_ko_v4.mp3' in text:
            print('❌', os.path.basename(p), '— 한국어 목소리가 아직 남아 있어요. 아무것도 저장 안 했어요')
            sys.exit(1)
        out[p] = (text, crlf)
        print('✔', os.path.basename(p))

    # pubspec.yaml: 목소리 두 줄 빼기 + 설명 바꾸기
    pp = 'pubspec.yaml'
    if not os.path.exists(pp):
        print('❌ pubspec.yaml 을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text, crlf = read(pp)
    if '_ko_v4.mp3' in text:
        for v in VOICE_FILES:
            line = '    - ' + v + '\n'
            if text.count(line) != 1:
                print('❌ pubspec.yaml 에서', v, '줄을 못 찾았어요 — 아무것도 저장 안 했어요')
                sys.exit(1)
            text = text.replace(line, '')
        text = text.replace('# 해외 첫인사 멜로디', '# 첫인사 멜로디 (모든 언어)')
        text = text.replace('# 해외 끝인사 멜로디', '# 끝인사 멜로디 (모든 언어)')
        out[pp] = (text, crlf)
        print('✔ pubspec.yaml (목소리 두 줄 빼기)')
    else:
        already += 1
        print('  (이미 바뀜) pubspec.yaml')

    if not out:
        print('이미 적용돼 있어요')
    else:
        for p, (text, crlf) in out.items():
            if crlf:
                text = text.replace('\n', '\r\n')
            with open(p, 'wb') as f:
                f.write(text.encode('utf-8'))
        print('✔ 코드 저장했어요')

    # 목소리 파일 옮기기 (지우지 않고 보관)
    os.makedirs(MOVE_TO, exist_ok=True)
    for v in VOICE_FILES:
        src = os.path.normpath(v)
        dst = os.path.join(MOVE_TO, os.path.basename(v))
        if os.path.exists(src):
            if os.path.exists(dst):
                print('  보관 폴더에 이미 같은 이름이 있어서 옮기지 않았어요:', os.path.basename(v))
            else:
                shutil.move(src, dst)
                print('✔ 보관했어요:', os.path.basename(v), '→', os.path.abspath(MOVE_TO))
        elif os.path.exists(dst):
            print('  (이미 보관됨)', os.path.basename(v))
        else:
            print('  (파일이 없어요)', os.path.basename(v))


main()
