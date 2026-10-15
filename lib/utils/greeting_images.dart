import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

const _base =
    'https://files.ssing.kr/app-images';

/// 한국어·영어·일본어·중국어는 그 언어, 나머지는 영어
String _lang(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return const ['ko', 'en', 'ja', 'zh'].contains(code) ? code : 'en';
}

/// 새 인사 사진(미니어처 4장면)을 쓰는 언어: 한국어·일본어·중국어
bool _asia(BuildContext context) => const ['ko', 'ja', 'zh'].contains(_lang(context));

// ── 오늘의 장면: 앱 켤 때 하나 고르고, 끝인사도 같은 장면의 밤 버전 ──
const _scenes = ['music', 'radio', 'nature', 'sleep'];
int _scene = 0;

/// main()에서 앱 켤 때 한 번: 지난번과 다른 장면으로 무작위
Future<void> initGreetingScene() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('greeting_scene') ?? -1;
    var pick = Random().nextInt(_scenes.length);
    if (pick == last) pick = (pick + 1 + Random().nextInt(_scenes.length - 1)) % _scenes.length;
    _scene = pick;
    await prefs.setInt('greeting_scene', pick);
  } catch (_) {
    _scene = Random().nextInt(_scenes.length);
  }
}

/// 첫인사 사진 위에 'Paransori' 글자를 코드로 얹는지 (새 사진엔 글자가 없어서)
bool greetingHasTitle(BuildContext context) => true;

/// 한·중·일은 아시아 여성, 그 밖은 금발 여성(_w)
String _who(BuildContext context) => _asia(context) ? '' : '_w';

String introAssetPath(BuildContext context) =>
    'assets/hello_${_scenes[_scene]}${_who(context)}.jpg';

String farewellImageUrl(BuildContext context) =>
    '$_base/farewell_bg_${_lang(context)}.png';

/// 끝인사 사진: 한·중·일은 오늘 장면의 밤 버전(앱 안), 그 밖은 지금처럼 인터넷 사진
ImageProvider farewellImage(BuildContext context) =>
    AssetImage('assets/bye_${_scenes[_scene]}${_who(context)}.jpg');

/// 끝인사 한 줄 인사: 오늘 장면에 맞게 (화면 언어로)
String farewellLine(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [l.byeLine1, l.byeLine2, l.byeLine3, l.byeLine4][_scene];
}
