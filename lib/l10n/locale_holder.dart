import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// 어디서든 번역 문구 꺼내기: tr.키이름 (앱 언어에 맞게)
AppLocalizations get tr => AppLocale.current ?? lookupAppLocalizations(_deviceLocale());

/// 앱 화면이 뜨기 전(시작할 때 등)엔 폰 언어로 고르기 — main.dart와 같은 규칙
Locale _deviceLocale() {
  final l = WidgetsBinding.instance.platformDispatcher.locale;
  if (l.languageCode == 'zh') {
    final hant = l.scriptCode == 'Hant' ||
        (l.scriptCode == null && const ['TW', 'HK', 'MO'].contains(l.countryCode));
    return hant ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant') : const Locale('zh');
  }
  if (const ['ko', 'en', 'ja', 'de', 'es', 'fr', 'id', 'pt', 'th', 'vi'].contains(l.languageCode)) {
    return Locale(l.languageCode);
  }
  if (l.languageCode == 'in') return const Locale('id'); // 옛 안드로이드의 인도네시아어 코드
  return const Locale('en');
}

class AppLocale {
  static AppLocalizations? current;
}