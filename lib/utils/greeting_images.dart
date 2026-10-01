import 'package:flutter/widgets.dart';

const _base =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images';

/// 한국어·영어·일본어·중국어는 그 언어, 나머지는 영어
String _lang(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return const ['ko', 'en', 'ja', 'zh'].contains(code) ? code : 'en';
}

String introImageUrl(BuildContext context) =>
    '$_base/intro_photo_${_lang(context)}.png';

String farewellImageUrl(BuildContext context) =>
    '$_base/farewell_bg_${_lang(context)}.png';