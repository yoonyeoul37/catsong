# -*- coding: utf-8 -*-
# 새 언어 폰 확인에서 나온 것 고치기
#  1) 개인정보처리방침·이용약관: 페이지에 없는 언어(독일어·프랑스어)는 영어로 (한국어로 열리던 것)
#  2) 홈 위젯 글자를 앱에서 고른 언어로 (PlayerWidget.kt + 위젯 화면 2개)
#  3) 라디오에서 나라를 바꾸면 다음에 홈 → 라디오도 그 나라로
#  4) 베트남어: 제목 도현 글꼴 대신 굵은 기본 글꼴 (글꼴 섞임) + 홈 카드 제목 한 줄
# ※ apply_device_country.py · apply_radio_country.py 를 먼저 실행한 뒤에
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_lang_fix3.py
import os, sys, io, json, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
E = json.loads('[["lib/screens/settings_screen.dart", "약관 페이지: 없는 언어는 영어로 (한국어로 열리던 것)", "    final lang = Localizations.localeOf(context).languageCode; // 설정 → 언어에서 고른 언어\\n", "    // 설정 → 언어에서 고른 언어 — 약관 페이지에 없는 언어(독일어·프랑스어 등)는 영어로\\n    // (그냥 보내면 페이지가 폰 언어=한국어로 열려서)\\n    final code = Localizations.localeOf(context).languageCode;\\n    final lang = const [\'ko\', \'en\', \'ja\', \'zh\', \'vi\', \'hi\', \'id\', \'th\', \'es\', \'pt\'].contains(code) ? code : \'en\';\\n", 1], ["android/app/src/main/res/layout/widget_player.xml", "바로가기 \\"music\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_music\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_music_label\\"\\n                android:text=\\"@string/tab_music\\"", 1], ["android/app/src/main/res/layout/widget_player.xml", "바로가기 \\"radio\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_radio\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_radio_label\\"\\n                android:text=\\"@string/tab_radio\\"", 1], ["android/app/src/main/res/layout/widget_player.xml", "바로가기 \\"nature\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_nature\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_nature_label\\"\\n                android:text=\\"@string/tab_nature\\"", 1], ["android/app/src/main/res/layout/widget_player.xml", "바로가기 \\"sleep\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_sleep\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_sleep_label\\"\\n                android:text=\\"@string/tab_sleep\\"", 1], ["android/app/src/main/res/layout/widget_player2.xml", "바로가기 \\"music\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_music\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_music_label\\"\\n                android:text=\\"@string/tab_music\\"", 1], ["android/app/src/main/res/layout/widget_player2.xml", "바로가기 \\"radio\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_radio\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_radio_label\\"\\n                android:text=\\"@string/tab_radio\\"", 1], ["android/app/src/main/res/layout/widget_player2.xml", "바로가기 \\"nature\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_nature\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_nature_label\\"\\n                android:text=\\"@string/tab_nature\\"", 1], ["android/app/src/main/res/layout/widget_player2.xml", "바로가기 \\"sleep\\" 글자에 이름표 붙이기", "android:layout_marginTop=\\"2dp\\"\\n                android:text=\\"@string/tab_sleep\\"", "android:layout_marginTop=\\"2dp\\"\\n                android:id=\\"@+id/widget_go_sleep_label\\"\\n                android:text=\\"@string/tab_sleep\\"", 1], ["@@PLAYERWIDGET@@", "위젯 글자를 앱에서 고른 언어로 (바로가기·최근 비었을 때)", "            val views = RemoteViews(context.packageName, if (big) R.layout.widget_player2 else R.layout.widget_player)\\n", "            val views = RemoteViews(context.packageName, if (big) R.layout.widget_player2 else R.layout.widget_player)\\n            // 글자는 앱에서 고른 언어로 (위젯은 바탕화면 앱이 그려서, 그냥 두면 폰 언어로 나옴)\\n            val lc = localized(context)\\n            views.setTextViewText(R.id.widget_go_music_label, lc.getString(R.string.tab_music))\\n            views.setTextViewText(R.id.widget_go_radio_label, lc.getString(R.string.tab_radio))\\n            views.setTextViewText(R.id.widget_go_nature_label, lc.getString(R.string.tab_nature))\\n            views.setTextViewText(R.id.widget_go_sleep_label, lc.getString(R.string.tab_sleep))\\n            if (big) views.setTextViewText(R.id.widget_recent_empty, lc.getString(R.string.widget_recent_empty))\\n", 1], ["@@PLAYERWIDGET@@", "위젯 제목 줄도 고른 언어로", "                if (loading) context.getString(R.string.widget_loading) else if (empty) context.getString(R.string.app_name) else t)\\n", "                if (loading) lc.getString(R.string.widget_loading) else if (empty) lc.getString(R.string.app_name) else t)\\n", 1], ["@@PLAYERWIDGET@@", "위젯 둘째 줄도 고른 언어로", "                if (loading) context.getString(R.string.widget_wait) else if (empty) context.getString(R.string.widget_idle_sub) else a)\\n", "                if (loading) lc.getString(R.string.widget_wait) else if (empty) lc.getString(R.string.widget_idle_sub) else a)\\n", 1], ["@@PLAYERWIDGET@@", "앱에서 고른 언어 글자 꺼내는 곳 추가", "        /// 바탕화면에 붙은 위젯 전부 다시 그리기 (앱이 켜지고 꺼질 때)\\n", "        /// 앱에서 고른 언어(설정 → 언어)의 글자 꺼내기 — \'폰 언어\'면 그대로\\n        fun localized(context: Context): Context {\\n            return try {\\n                val code = context.getSharedPreferences(\\"FlutterSharedPreferences\\", Context.MODE_PRIVATE)\\n                    .getString(\\"flutter.appLanguage\\", \\"system\\") ?: \\"system\\"\\n                val tag = when (code) {\\n                    \\"system\\", \\"\\" -> return context\\n                    \\"zh_Hant\\" -> \\"zh-TW\\"\\n                    \\"zh_Hans\\" -> \\"zh-CN\\"\\n                    \\"pt\\" -> \\"pt-BR\\"\\n                    else -> code\\n                }\\n                val cfg = android.content.res.Configuration(context.resources.configuration)\\n                cfg.setLocale(java.util.Locale.forLanguageTag(tag))\\n                context.createConfigurationContext(cfg)\\n            } catch (_: Exception) {\\n                context\\n            }\\n        }\\n\\n        /// 바탕화면에 붙은 위젯 전부 다시 그리기 (앱이 켜지고 꺼질 때)\\n", 1], ["lib/utils/device_country.dart", "저장 기능 불러오기", "import \'package:flutter/services.dart\';\\n", "import \'package:flutter/services.dart\';\\nimport \'package:shared_preferences/shared_preferences.dart\';\\n", 1], ["lib/utils/device_country.dart", "언어별로 마지막에 고른 나라 기억 칸", "  static String? _code;\\n", "  static String? _code;\\n  static final Map<String, String> _picked = {}; // 앱 언어별로 마지막에 고른 라디오 나라\\n", 1], ["lib/utils/device_country.dart", "앱 켤 때 고른 나라도 불러오기", "      if (c != null && c.length == 2) _code = c.toUpperCase();\\n    } catch (_) {}\\n  }\\n", "      if (c != null && c.length == 2) _code = c.toUpperCase();\\n    } catch (_) {}\\n    try {\\n      final raw = (await SharedPreferences.getInstance()).getString(\'radio_pick_country\') ?? \'\';\\n      for (final e in raw.split(\',\')) {\\n        final kv = e.split(\':\');\\n        if (kv.length == 2 && kv[1].length == 2) _picked[kv[0]] = kv[1];\\n      }\\n    } catch (_) {}\\n  }\\n\\n  /// 라디오에서 나라를 고르면 기억 → 다음에 홈 → 라디오도 그 나라로 (앱 언어마다 따로)\\n  static void rememberPick(String country) {\\n    _picked[tr.localeName] = country;\\n    final raw = _picked.entries.map((e) => \'${e.key}:${e.value}\').join(\',\');\\n    SharedPreferences.getInstance().then((p) => p.setString(\'radio_pick_country\', raw)).catchError((_) => false);\\n  }\\n", 1], ["lib/utils/device_country.dart", "고른 나라가 있으면 그 나라 먼저", "  static String? radioCountry() {\\n    final dev = code;\\n    final lang = tr.localeName; // ko · en · ja · zh · zh_Hant · de …\\n", "  static String? radioCountry({bool usePick = true}) {\\n    final dev = code;\\n    final lang = tr.localeName; // ko · en · ja · zh · zh_Hant · de …\\n    if (usePick && _picked[lang] != null) return _picked[lang]; // 라디오에서 직접 고른 나라\\n", 1], ["lib/screens/radio_home_screen.dart", "나라 목록 맨 위 내 나라는 고른 나라 말고 원래 나라 (2군데)", "    final deviceCountryCode = DeviceCountry.radioCountry();\\n", "    final deviceCountryCode = DeviceCountry.radioCountry(usePick: false);\\n", 2], ["lib/screens/radio_home_screen.dart", "나라를 고르면 기억", "    context.read<RadioProvider>().selectCountry(country);\\n    final screen = country.code == \'KR\'\\n        ? RadioKoreaScreen()\\n", "    context.read<RadioProvider>().selectCountry(country);\\n    DeviceCountry.rememberPick(country.code); // 다음에 홈 → 라디오도 이 나라로\\n    final screen = country.code == \'KR\'\\n        ? RadioKoreaScreen()\\n", 1], ["lib/screens/home_screen.dart", "홈 카드 제목 한 줄로 (길면 …)", "                                          TextSpan(text: c.title),\\n                                        ]),\\n", "                                          TextSpan(text: c.title),\\n                                        ]),\\n                                        maxLines: 1,\\n                                        overflow: TextOverflow.ellipsis,\\n", 1]]')
NEW = json.loads('{"lib/utils/title_font.dart": "import \'package:flutter/material.dart\';\\nimport \'package:google_fonts/google_fonts.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n\\n/// 제목 글꼴 (도현) — 도현에 없는 글자를 쓰는 언어(베트남어)는 굵은 기본 글꼴로\\n/// (ư·ơ·ậ 같은 글자만 다른 글꼴로 바뀌어 섞여 보이는 것 막기)\\nTextStyle titleFont({Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, List<Shadow>? shadows}) {\\n  if (tr.localeName.startsWith(\'vi\')) {\\n    return TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: letterSpacing, shadows: shadows);\\n  }\\n  return GoogleFonts.doHyeon(\\n      color: color, fontSize: fontSize, fontWeight: fontWeight, letterSpacing: letterSpacing, shadows: shadows);\\n}\\n"}')
FONT = {'lib/screens/home_screen.dart': 6, 'lib/screens/radio_home_screen.dart': 1, 'lib/screens/radio_korea_screen2.dart': 1, 'lib/screens/nature_sounds_screen.dart': 2, 'lib/screens/sleep_focus_screen.dart': 2, 'lib/screens/lyrics_screen.dart': 1, 'lib/screens/sound_mix_screen.dart': 2}


def find_widget():
    for r, d, fs in os.walk(os.path.join('android', 'app', 'src', 'main')):
        if 'PlayerWidget.kt' in fs:
            return os.path.join(r, 'PlayerWidget.kt').replace('\\', '/')
    return None


def main():
    pw = find_widget()
    if pw is None:
        print('❌ PlayerWidget.kt 를 못 찾았어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
    edits = [[pw if e[0] == '@@PLAYERWIDGET@@' else e[0]] + e[1:] for e in E]
    files = sorted({e[0] for e in edits} | set(FONT))
    texts, crlf = {}, {}
    for p in files:
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. (apply_device_country.py 먼저 / 프로젝트 폴더에서 실행)'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[p] = '\r\n' in raw
        texts[p] = raw.replace('\r\n', '\n')
    if 'fun localized(context: Context)' in texts[pw] and all(os.path.exists(p) for p in NEW):
        print('이미 적용돼 있어요'); return
    ok = True
    for p, name, old, new, want in edits:
        n = texts[p].count(old)
        if n == want:
            texts[p] = texts[p].replace(old, new); print(f'✔ {os.path.basename(p)} - {name}')
        else:
            print(f'❌ {os.path.basename(p)} - {name} (찾을 코드가 {n}군데)'); ok = False
    # 도현 → titleFont (홈 로고 '파란소리'는 그대로)
    for p, want in FONT.items():
        t = texts[p]
        out, i, n = [], 0, 0
        for m in re.finditer(r'GoogleFonts\.doHyeon\(', t):
            before = t[max(0, m.start() - 260):m.start()]
            if re.search(r"Text\('(파란|소리)'", before):  # 한국어 로고 '파란소리'는 도현 그대로
                continue
            out.append(t[i:m.start()] + 'titleFont(')
            i = m.end(); n += 1
        out.append(t[i:])
        if n != want:
            print(f'❌ {os.path.basename(p)} - 제목 글꼴 바꿀 곳이 {n}군데 (예상 {want})'); ok = False; continue
        t = ''.join(out)
        imp = "import '../utils/title_font.dart';\n"
        if imp not in t:
            k = t.index("import 'package:flutter/material.dart';\n") + len("import 'package:flutter/material.dart';\n")
            t = t[:k] + imp + t[k:]
        texts[p] = t
        print(f'✔ {os.path.basename(p)} - 제목 글꼴 {n}군데 (베트남어는 기본 글꼴)')
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
    print('\n완료! 코틀린도 바뀌어서 앱을 완전히 끄고 flutter run 해 주세요.')


main()
