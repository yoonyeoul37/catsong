# -*- coding: utf-8 -*-
# 설정에 '언어' 메뉴 넣기: 폰 설정 따라가기 / 한국어 / English / 日本語 / 繁體中文 / 简体中文
#  - 고르면 앱을 다시 켜지 않아도 바로 바뀌고, 다음에 켜도 기억 (첫 화면부터 그 언어)
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_app_language.py
import os, sys, json

FILES = {'theme': 'lib/providers/theme_provider.dart', 'main': 'lib/main.dart',
         'settings': 'lib/screens/settings_screen.dart'}
EDITS = json.loads(r"""[["theme", "앱 언어 값 추가", "  bool _feedbackSoundEnabled = true; // 완료 효과음 (물방울 소리·진동)\n", "  bool _feedbackSoundEnabled = true; // 완료 효과음 (물방울 소리·진동)\n  /// 앱 시작 전에 main.dart가 미리 읽어 둔 앱 언어 (첫 화면부터 그 언어로 → 깜빡임 없게)\n  static String preloadLanguage = 'system';\n  String _appLanguage = preloadLanguage; // 앱 언어 ('system' = 폰 설정 따라가기)\n"], ["theme", "앱 언어 목록·바꾸기 추가", "  bool get feedbackSoundEnabled => _feedbackSoundEnabled;\n", "  bool get feedbackSoundEnabled => _feedbackSoundEnabled;\n  String get appLanguage => _appLanguage;\n\n  /// 설정 → 언어 (코드, 그 나라 말로 쓴 이름) — 새 언어를 넣으면 여기에 한 줄 추가\n  static const appLanguages = <(String, String)>[\n    ('ko', '한국어'),\n    ('en', 'English'),\n    ('ja', '日本語'),\n    ('zh_Hant', '繁體中文'),\n    ('zh_Hans', '简体中文'),\n  ];\n\n  /// MaterialApp에 넘길 언어 (null = 폰 설정 따라가기)\n  Locale? get appLocale => switch (_appLanguage) {\n        'ko' => const Locale('ko'),\n        'en' => const Locale('en'),\n        'ja' => const Locale('ja'),\n        'zh_Hant' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),\n        'zh_Hans' => const Locale('zh'),\n        _ => null,\n      };\n\n  Future<void> setAppLanguage(String code) async {\n    _appLanguage = code;\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setString('appLanguage', code);\n    notifyListeners();\n  }\n"], ["theme", "저장된 앱 언어 불러오기", "    if (feedbackSoundEnabled != null) {\n      _feedbackSoundEnabled = feedbackSoundEnabled;\n    }\n", "    if (feedbackSoundEnabled != null) {\n      _feedbackSoundEnabled = feedbackSoundEnabled;\n    }\n    final appLanguage = prefs.getString('appLanguage');\n    if (appLanguage != null && (appLanguage == 'system' || appLanguages.any((l) => l.$1 == appLanguage))) {\n      _appLanguage = appLanguage;\n    }\n"], ["main", "시작 전에 앱 언어 미리 읽기", "  await WidgetGo.loadLaunch(); // 홈 위젯 바로가기로 켜졌는지\n", "  await WidgetGo.loadLaunch(); // 홈 위젯 바로가기로 켜졌는지\n  // 설정 → 언어에서 고른 언어 (첫 화면부터 그 언어로)\n  try {\n    ThemeProvider.preloadLanguage =\n        (await SharedPreferences.getInstance()).getString('appLanguage') ?? 'system';\n  } catch (_) {}\n"], ["main", "고른 언어로 앱 띄우기", "            supportedLocales: const [\n              Locale('ko'),", "            locale: themeProvider.appLocale, // 설정 → 언어 (null이면 폰 설정 따라가기)\n            supportedLocales: const [\n              Locale('ko'),"], ["settings", "꾸미기에 언어 줄 추가 (글자 크기 아래)", "          _buildTile(context, icon: Icons.text_fields, title: l.textSize, desc: tr.descTextSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor),\n", "          _buildTile(context, icon: Icons.text_fields, title: l.textSize, desc: tr.descTextSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor),\n          // 언어: 폰 설정 따라가기 / 한국어 / English … (오른쪽에 지금 언어)\n          Consumer<ThemeProvider>(\n            builder: (context, t, _) => _buildTile(context,\n                icon: Icons.language_rounded,\n                title: l.languageTab,\n                desc: _langText('desc'),\n                subtitle: _langName(t.appLanguage),\n                onTap: () => _showLanguageSheet(context),\n                primaryColor: primaryColor),\n          ),\n"], ["settings", "언어 고르는 창 추가", "  /// 약관 주소: 폰 언어 + 앱 다크/라이트를 붙여서 (페이지가 그대로 맞춰 열림)", "  /// 언어 줄 글자 (5개 언어) — 번역 작업 때 arb로 옮기기\n  String _langText(String key) {\n    final loc = Localizations.localeOf(context);\n    final k = loc.languageCode == 'zh' ? (loc.scriptCode == 'Hant' ? 'tw' : 'cn') : loc.languageCode;\n    const t = {\n      'desc': {\n        'ko': '앱 글자를 다른 언어로 볼 수 있어요.',\n        'en': 'Show the app in another language.',\n        'ja': 'アプリの表示言語を選べます。',\n        'tw': '選擇應用程式的顯示語言。',\n        'cn': '选择应用的显示语言。',\n      },\n      'system': {\n        'ko': '폰 설정 따라가기',\n        'en': 'Follow phone settings',\n        'ja': '端末の設定に合わせる',\n        'tw': '跟隨手機設定',\n        'cn': '跟随手机设置',\n      },\n    };\n    return t[key]![k] ?? t[key]!['en']!;\n  }\n\n  /// 언어 이름: 폰 설정 따라가기는 지금 언어로, 나머지는 그 나라 말로 (모르는 언어로 바꿔도 다시 찾게)\n  String _langName(String code) {\n    if (code == 'system') return _langText('system');\n    for (final l in ThemeProvider.appLanguages) {\n      if (l.$1 == code) return l.$2;\n    }\n    return _langText('system');\n  }\n\n  /// 설정 → 언어: 폰 설정 따라가기 + 앱이 아는 언어들 (고르면 바로 바뀌고 기억)\n  void _showLanguageSheet(BuildContext context) {\n    final themeProvider = context.read<ThemeProvider>();\n    showParanSheet(\n      context,\n      title: AppLocalizations.of(context)!.languageTab,\n      builder: (ctx, setSheet) => ParanCard(\n        children: [\n          for (final code in ['system', for (final l in ThemeProvider.appLanguages) l.$1])\n            ParanRow(\n              icon: code == 'system' ? Icons.phone_android_rounded : Icons.language_rounded,\n              title: _langName(code),\n              selected: themeProvider.appLanguage == code,\n              onTap: () {\n                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                Navigator.pop(ctx);\n                themeProvider.setAppLanguage(code);\n              },\n            ),\n        ],\n      ),\n    );\n  }\n\n  /// 약관 주소: 폰 언어 + 앱 다크/라이트를 붙여서 (페이지가 그대로 맞춰 열림)"], ["settings", "약관 페이지도 앱에서 고른 언어로", "    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;\n", "    final lang = Localizations.localeOf(context).languageCode; // 설정 → 언어에서 고른 언어\n"]]""")

def main():
    texts, crlf = {}, {}
    for k, p in FILES.items():
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[k] = '\r\n' in raw
        texts[k] = raw.replace('\r\n', '\n')
    if 'setAppLanguage(' in texts['theme'] and '_showLanguageSheet(' in texts['settings'] and 'appLocale' in texts['main']:
        print('이미 적용돼 있어요'); return
    ok = True
    for f, name, old, new in EDITS:
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
    print('\n완료! 설정 → 꾸미기 → 언어 가 생겼어요.')

if __name__ == '__main__':
    main()
