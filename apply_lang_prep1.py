# -*- coding: utf-8 -*-
# 번역 준비 1: 곡 목록 초성 바 악센트 글자 + 안드로이드 '앱별 언어' 메뉴
#  - Ä·É·Ñ·Đ 같은 글자로 시작하는 제목이 # 대신 A·E·N·D 칸으로
#  - 폰 설정 → 앱 → 파란소리 → 언어 에서 파란소리만 다른 언어로 (안드로이드 13 이상)
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_lang_prep1.py
import os, sys, json

FILES = {'index': 'lib/utils/index_letter.dart', 'manifest': 'android/app/src/main/AndroidManifest.xml'}
LOCALES_PATH = 'android/app/src/main/res/xml/locales_config.xml'
LOCALES = '<?xml version="1.0" encoding="utf-8"?>\n<!-- 폰 설정 → 앱 → 파란소리 → 언어 에 나오는 목록 (안드로이드 13 이상)\n     새 언어를 넣으면 여기에도 한 줄 추가 -->\n<locale-config xmlns:android="http://schemas.android.com/apk/res/android">\n    <locale android:name="ko"/>\n    <locale android:name="en"/>\n    <locale android:name="ja"/>\n    <locale android:name="zh-CN"/>\n    <locale android:name="zh-TW"/>\n</locale-config>\n'
EDITS = json.loads(r"""[["index", "한국어 막대: 악센트 글자도 A-Z로", "  // 영어 → 대문자\n  final ch = String.fromCharCode(c).toUpperCase();\n  if (ch.length == 1 && ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) {\n    return ch;\n  }\n", "  // 영어 → 대문자 (악센트 글자는 기본 글자로: Ä→A, É→E, Ñ→N)\n  final latin = latinLetterOf(c);\n  if (latin != null) return latin;\n"], ["index", "다른 언어 막대: 악센트 글자도 A~Z로", "  final ch = String.fromCharCode(c).toUpperCase();\n  final isLatin = ch.length == 1 && ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90;\n", "  final ch = latinLetterOf(c) ?? ''; // 악센트 글자는 기본 글자로 (Ä→A, É→E, Ñ→N, Đ→D)\n  final isLatin = ch.isNotEmpty;\n"], ["index", "악센트 → 기본 글자 표 추가", "__APPEND__", "\n// ───────── 악센트 글자 → 기본 글자 (Ä→A, É→E, Ñ→N, Đ→D, Ş→S, 베트남어 Ế→E …) ─────────\n// 스페인어·포르투갈어·독일어·프랑스어·베트남어 제목도 A~Z 칸으로 (예전엔 전부 # 으로 갔음)\nconst _foldFrom =\n    'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝŸĀĂĄĆĈĊČĎĒĔĖĘĚĜĞĠĢĤĨĪĬĮİĴĶĹĻĽŃŅŇŌŎŐŔŖŘŚŜŞŠŢŤŨŪŬŮŰŲŴŶŹŻŽƠƯǍǏǑǓǕǗǙǛǞǠǦǨǪǬǴǸǺȀȂȄȆȈȊȌȎȐȒȔȖȘȚȞȦȨȪȬȮȰȲḀḂḄḆḈḊḌḎḐḒḔḖḘḚḜḞḠḢḤḦḨḪḬḮḰḲḴḶḸḺḼḾṀṂṄṆṈṊṌṎṐṒṔṖṘṚṜṞṠṢṤṦṨṪṬṮṰṲṴṶṸṺṼṾẀẂẄẆẈẊẌẎẐẒẔẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼẾỀỂỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪỬỮỰỲỴỶỸĐŁØÆŒÞÐĦŦĿŊƗƵẞ';\nconst _foldTo =\n    'AAAAAACEEEEIIIINOOOOOUUUUYYAAACCCCDEEEEEGGGGHIIIIIJKLLLNNNOOORRRSSSSTTUUUUUUWYZZZOUAIOUUUUUAAGKOOGNAAAEEIIOORRUUSTHAEOOOOYABBBCDDDDDEEEEEFGHHHHHIIKKKLLLLMMMNNNNOOOOPPRRRRSSSSSTTTTUUUUUVVWWWWWXXYZZZAAAAAAAAAAAAEEEEEEEEIIOOOOOOOOOOOOUUUUUUUYYYYDLOAOTDHTLNIZS';\n\n/// 첫 글자 → 영어 대문자 A~Z (악센트는 기본 글자로, ß→S), 영어 글자가 아니면 null\nString? latinLetterOf(int rune) {\n  var up = String.fromCharCode(rune).toUpperCase();\n  if (up.isEmpty) return null;\n  up = up.substring(0, 1); // ß → SS 처럼 두 글자가 되면 첫 글자만\n  final i = _foldFrom.indexOf(up);\n  if (i >= 0) up = _foldTo[i];\n  final u = up.codeUnitAt(0);\n  return (u >= 65 && u <= 90) ? up : null;\n}\n"], ["manifest", "앱별 언어 목록 연결 (안드로이드 13+)", "        android:name=\"${applicationName}\"\n", "        android:name=\"${applicationName}\"\n        android:localeConfig=\"@xml/locales_config\"\n"]]""")

def main():
    texts, crlf = {}, {}
    for k, p in FILES.items():
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[k] = '\r\n' in raw
        texts[k] = raw.replace('\r\n', '\n')
    if 'String? latinLetterOf(' in texts['index'] and 'localeConfig' in texts['manifest'] and os.path.exists(LOCALES_PATH):
        print('이미 적용돼 있어요'); return
    if os.path.exists(LOCALES_PATH):
        print(f'❌ {LOCALES_PATH} 가 이미 있어요. 아무것도 바꾸지 않았어요.'); sys.exit(1)
    ok = True
    for f, name, old, new in EDITS:
        if old == '__APPEND__':
            texts[f] = texts[f].rstrip('\n') + '\n' + new
            print(f'✔ {os.path.basename(FILES[f])} - {name}'); continue
        n = texts[f].count(old)
        if n == 1:
            texts[f] = texts[f].replace(old, new); print(f'✔ {os.path.basename(FILES[f])} - {name}')
        else:
            print(f'❌ {os.path.basename(FILES[f])} - {name} (찾을 코드가 {n}군데)'); ok = False
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for k, p in FILES.items():
        t = texts[k].replace('\n', '\r\n') if crlf[k] else texts[k]
        open(p, 'wb').write(t.encode('utf-8'))
    os.makedirs(os.path.dirname(LOCALES_PATH), exist_ok=True)
    loc = LOCALES.replace('\n', '\r\n') if crlf['manifest'] else LOCALES
    open(LOCALES_PATH, 'wb').write(loc.encode('utf-8'))
    print('✔ locales_config.xml - 앱별 언어 목록 새로 만듦 (한국어·영어·일본어·간체·번체)')
    print('\n완료!')

if __name__ == '__main__':
    main()
