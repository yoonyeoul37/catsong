import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_holder.dart';
import '../models/radio_country.dart';

/// 폰이 있는 나라 (KR, US …) — 앱 언어와 상관없이
/// 설정 → 언어를 바꾸면 폰이 앱 언어를 'de'처럼 나라 없이 알려 줘서,
/// 폰 전체 설정의 나라를 따로 받아 둠 (라디오 '내 나라' 목록에 씀)
class DeviceCountry {
  static String? _code;
  static final Map<String, String> _picked = {}; // 앱 언어별로 마지막에 고른 라디오 나라

  /// 폰 나라 (못 받았으면 지금 언어 설정의 나라)
  static String? get code => _code ?? PlatformDispatcher.instance.locale.countryCode;

  /// main()에서 앱 켤 때 한 번
  static Future<void> load() async {
    try {
      final c = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('systemCountry');
      if (c != null && c.length == 2) _code = c.toUpperCase();
    } catch (_) {}
    try {
      final raw = (await SharedPreferences.getInstance()).getString('radio_pick_country') ?? '';
      for (final e in raw.split(',')) {
        final kv = e.split(':');
        if (kv.length == 2 && kv[1].length == 2) _picked[kv[0]] = kv[1];
      }
    } catch (_) {}
  }

  /// 라디오에서 나라를 고르면 기억 → 다음에 홈 → 라디오도 그 나라로 (앱 언어마다 따로)
  static void rememberPick(String country) {
    _picked[tr.localeName] = country;
    final raw = _picked.entries.map((e) => '${e.key}:${e.value}').join(',');
    SharedPreferences.getInstance().then((p) => p.setString('radio_pick_country', raw)).catchError((_) => false);
  }

  /// 라디오 '내 나라' (홈 → 라디오를 누르면 바로 이 나라 채널 목록)
  /// 규칙: 앱 언어의 나라 — 한국어 KR · 독일어 DE · 일본어 JP …
  ///      폰 나라가 그 언어를 쓰는 나라면 폰 나라 (예: 스페인어 + 멕시코 폰 → MX)
  static String? radioCountry({bool usePick = true}) {
    final dev = code;
    final lang = tr.localeName; // ko · en · ja · zh · zh_Hant · de …
    if (usePick && _picked[lang] != null) return _picked[lang]; // 라디오에서 직접 고른 나라
    const home = {
      'ko': 'KR', 'en': 'US', 'ja': 'JP', 'zh': 'CN', 'zh_Hant': 'TW', 'de': 'DE', 'es': 'ES',
      'fr': 'FR', 'id': 'ID', 'pt': 'BR', 'vi': 'VN', 'th': 'TH',
      'ru': 'RU', 'it': 'IT', 'tr': 'TR', 'pl': 'PL',
    };
    const alsoSpeak = {
      // 아프리카·카리브·아시아·오세아니아에서 영어 쓰는 나라도 (라디오 나라 목록에 있는 나라만)
      'en': ['US', 'GB', 'CA', 'AU', 'NZ', 'IE', 'IN', 'PH', 'SG', 'ZA',
             'NG', 'KE', 'GH', 'TZ', 'UG', 'ZW', 'JM', 'TT', 'MY', 'PK', 'MT', 'FJ', 'PG'],
      'es': ['ES', 'MX', 'AR', 'CO', 'CL', 'PE', 'VE', 'EC', 'GT', 'CU', 'BO', 'DO', 'HN', 'PY', 'SV', 'NI', 'CR', 'PA', 'UY', 'PR'],
      'pt': ['BR', 'PT', 'MZ'],
      'fr': ['FR', 'BE', 'CH', 'CA', 'LU', 'SN', 'CM', 'MA', 'TN', 'MG', 'HT'],
      'de': ['DE', 'AT', 'CH', 'LU'],
      'ru': ['RU', 'BY', 'KZ', 'KG', 'UZ'],
      'it': ['IT', 'CH', 'SM'],
      'zh_Hant': ['TW', 'HK', 'MO'],
      'zh': ['CN', 'SG'],
    };
    if (dev != null && (dev == home[lang] || (alsoSpeak[lang]?.contains(dev) ?? false))) return dev;
    // 폰 언어가 앱에 없는 언어라 영어로 나올 때 (노르웨이어·헝가리어 …) → 폰 나라 라디오
    // (앱 라디오 나라 목록에 있는 나라만 — 없으면 아래 규칙대로)
    final phoneLang = PlatformDispatcher.instance.locale.languageCode;
    const appLangs = ['ko', 'en', 'ja', 'zh', 'de', 'es', 'fr', 'id', 'in', 'pt', 'th', 'vi', 'ru', 'it', 'tr', 'pl'];
    if (dev != null && lang == 'en' && !appLangs.contains(phoneLang) &&
        RadioCountry.supported.any((c) => c.code == dev)) {
      return dev;
    }
    return home[lang] ?? dev;
  }
}
