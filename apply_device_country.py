# -*- coding: utf-8 -*-
# 앱 언어를 바꾸면 홈 → 라디오가 나라 목록으로 열리던 것 → 폰이 있는 나라의 방송 목록으로
#  - 새 파일 lib/utils/device_country.dart (폰 나라 기억)
#  - main.dart · radio_home_screen.dart · home_screen.dart 고치기
# ※ MainActivity.kt 에 'systemCountry' 한 군데도 같이 넣어야 해요 (따로 드린 찾기/바꾸기)
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_device_country.py
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
E = json.loads('[["lib/main.dart", "폰 나라 기억 파일 불러오기", "import \'package:flutter/material.dart\';\\n", "import \'package:flutter/material.dart\';\\nimport \'utils/device_country.dart\';\\n"], ["lib/main.dart", "앱 켤 때 폰 나라 받아 두기", "  // 설정 → 언어에서 고른 언어 (첫 화면부터 그 언어로)\\n", "  await DeviceCountry.load(); // 폰이 있는 나라 (앱 언어를 바꿔도 라디오는 내 나라 목록으로)\\n  // 설정 → 언어에서 고른 언어 (첫 화면부터 그 언어로)\\n"], ["lib/screens/radio_home_screen.dart", "폰 나라 기억 파일 불러오기", "import \'package:flutter/material.dart\';\\n", "import \'package:flutter/material.dart\';\\nimport \'../utils/device_country.dart\';\\n"], ["lib/screens/radio_home_screen.dart", "라디오 내 나라: 앱 언어 대신 폰 나라로 (3군데)", "PlatformDispatcher.instance.locale.countryCode", "DeviceCountry.code", 3], ["lib/screens/home_screen.dart", "폰 나라 기억 파일 불러오기", "import \'package:flutter/material.dart\';\\n", "import \'package:flutter/material.dart\';\\nimport \'../utils/device_country.dart\';\\n"], ["lib/screens/home_screen.dart", "홈 라디오 칸 채널 수도 폰 나라로 (누르면 나오는 목록과 같게)", "    final l = Localizations.localeOf(context);\\n    final code = _radioCountry(l);\\n", "    final l = Localizations.localeOf(context);\\n    final code = DeviceCountry.code ?? _radioCountry(l); // 누르면 나오는 목록(폰 나라)과 같게\\n"]]')
NEW = json.loads('{"lib/utils/device_country.dart": "import \'dart:ui\' show PlatformDispatcher;\\nimport \'package:flutter/services.dart\';\\n\\n/// 폰이 있는 나라 (KR, US …) — 앱 언어와 상관없이\\n/// 설정 → 언어를 바꾸면 폰이 앱 언어를 \'de\'처럼 나라 없이 알려 줘서,\\n/// 폰 전체 설정의 나라를 따로 받아 둠 (라디오 \'내 나라\' 목록에 씀)\\nclass DeviceCountry {\\n  static String? _code;\\n\\n  /// 폰 나라 (못 받았으면 지금 언어 설정의 나라)\\n  static String? get code => _code ?? PlatformDispatcher.instance.locale.countryCode;\\n\\n  /// main()에서 앱 켤 때 한 번\\n  static Future<void> load() async {\\n    try {\\n      final c = await const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod<String>(\'systemCountry\');\\n      if (c != null && c.length == 2) _code = c.toUpperCase();\\n    } catch (_) {}\\n  }\\n}\\n"}')


def main():
    files = sorted({e[0] for e in E})
    texts, crlf = {}, {}
    for p in files:
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[p] = '\r\n' in raw
        texts[p] = raw.replace('\r\n', '\n')
    if 'DeviceCountry.load()' in texts['lib/main.dart'] and all(os.path.exists(p) for p in NEW):
        print('이미 적용돼 있어요'); return
    ok = True
    for e in E:
        p, name, old, new = e[:4]
        want = e[4] if len(e) > 4 else 1
        n = texts[p].count(old)
        if n == want:
            texts[p] = texts[p].replace(old, new); print(f'✔ {os.path.basename(p)} - {name}')
        else:
            print(f'❌ {os.path.basename(p)} - {name} (찾을 코드가 {n}군데)'); ok = False
    for p in NEW:
        if os.path.exists(p):
            print(f'❌ {p} 가 이미 있어요'); ok = False
    if not ok:
        print('\n❌ 문제가 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for p in files:
        t = texts[p].replace('\n', '\r\n') if crlf[p] else texts[p]
        open(p, 'wb').write(t.encode('utf-8'))
    for p, t in NEW.items():
        open(p, 'wb').write(t.replace('\n', '\r\n').encode('utf-8'))
        print(f'✔ 새 파일 {p}')
    print('\n완료!')


main()
