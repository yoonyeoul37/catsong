# -*- coding: utf-8 -*-
# 홈 → 라디오: 앱 언어 나라의 채널 목록으로 바로 (한국어 → 한국 · 독일어 → 독일 · 일본어 → 일본 …)
# ※ apply_device_country.py 와 MainActivity.kt 'systemCountry' 를 먼저 넣은 뒤에
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_radio_country.py
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
E = json.loads('[["lib/utils/device_country.dart", "번역 글자(언어) 불러오기", "import \'package:flutter/services.dart\';\\n", "import \'package:flutter/services.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["lib/utils/device_country.dart", "라디오 \'내 나라\' = 앱 언어의 나라", "    } catch (_) {}\\n  }\\n}\\n", "    } catch (_) {}\\n  }\\n\\n  /// 라디오 \'내 나라\' (홈 → 라디오를 누르면 바로 이 나라 채널 목록)\\n  /// 규칙: 앱 언어의 나라 — 한국어 KR · 독일어 DE · 일본어 JP …\\n  ///      폰 나라가 그 언어를 쓰는 나라면 폰 나라 (예: 스페인어 + 멕시코 폰 → MX)\\n  static String? radioCountry() {\\n    final dev = code;\\n    final lang = tr.localeName; // ko · en · ja · zh · zh_Hant · de …\\n    const home = {\\n      \'ko\': \'KR\', \'en\': \'US\', \'ja\': \'JP\', \'zh\': \'CN\', \'zh_Hant\': \'TW\', \'de\': \'DE\', \'es\': \'ES\',\\n      \'fr\': \'FR\', \'id\': \'ID\', \'pt\': \'BR\', \'vi\': \'VN\', \'th\': \'TH\',\\n    };\\n    const alsoSpeak = {\\n      \'en\': [\'US\', \'GB\', \'CA\', \'AU\', \'NZ\', \'IE\', \'IN\', \'PH\', \'SG\', \'ZA\'],\\n      \'es\': [\'ES\', \'MX\', \'AR\', \'CO\', \'CL\', \'PE\', \'VE\', \'EC\', \'GT\', \'CU\', \'BO\', \'DO\', \'HN\', \'PY\', \'SV\', \'NI\', \'CR\', \'PA\', \'UY\', \'PR\'],\\n      \'pt\': [\'BR\', \'PT\'],\\n      \'fr\': [\'FR\', \'BE\', \'CH\', \'CA\', \'LU\'],\\n      \'de\': [\'DE\', \'AT\', \'CH\', \'LU\'],\\n      \'zh_Hant\': [\'TW\', \'HK\', \'MO\'],\\n      \'zh\': [\'CN\', \'SG\'],\\n    };\\n    if (dev != null && (dev == home[lang] || (alsoSpeak[lang]?.contains(dev) ?? false))) return dev;\\n    return home[lang] ?? dev;\\n  }\\n}\\n", 1], ["lib/screens/radio_home_screen.dart", "홈 → 라디오: 앱 언어 나라의 채널 목록으로 바로", "  final deviceCode = DeviceCountry.code;\\n", "  final deviceCode = DeviceCountry.radioCountry(); // 앱 언어의 나라 (독일어 → 독일)\\n", 1], ["lib/screens/radio_home_screen.dart", "나라 목록 맨 위 내 나라도 같게 (2군데)", "    final deviceCountryCode = DeviceCountry.code;\\n", "    final deviceCountryCode = DeviceCountry.radioCountry();\\n", 2], ["lib/screens/home_screen.dart", "홈 라디오 칸 채널 수도 같은 나라로", "    final code = DeviceCountry.code ?? _radioCountry(l); // 누르면 나오는 목록(폰 나라)과 같게\\n", "    final code = DeviceCountry.radioCountry() ?? _radioCountry(l); // 누르면 나오는 목록과 같은 나라\\n", 1]]')


def main():
    files = sorted({e[0] for e in E})
    texts, crlf = {}, {}
    for p in files:
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. (apply_device_country.py 먼저 / 프로젝트 폴더에서 실행)'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[p] = '\r\n' in raw
        texts[p] = raw.replace('\r\n', '\n')
    if 'static String? radioCountry()' in texts['lib/utils/device_country.dart']:
        print('이미 적용돼 있어요'); return
    ok = True
    for p, name, old, new, want in E:
        n = texts[p].count(old)
        if n == want:
            texts[p] = texts[p].replace(old, new); print(f'✔ {os.path.basename(p)} - {name}')
        else:
            print(f'❌ {os.path.basename(p)} - {name} (찾을 코드가 {n}군데)'); ok = False
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for p in files:
        t = texts[p].replace('\n', '\r\n') if crlf[p] else texts[p]
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n완료!')


main()
