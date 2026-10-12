# -*- coding: utf-8 -*-
# 첫인사·끝인사 새 사진 4장씩 (음악·라디오·자연·수면) — 켤 때 무작위, 끌 때는 같은 장면의 밤 버전
# 한국어·일본어·중국어 화면만 새 사진 (영어 등은 지금 그대로)
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

GREETING = r'''import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _base =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images';

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
bool greetingHasTitle(BuildContext context) => _asia(context);

String introAssetPath(BuildContext context) => _asia(context)
    ? 'assets/hello_${_scenes[_scene]}.jpg'
    : 'assets/intro_photo_${_lang(context)}.png';

String farewellImageUrl(BuildContext context) =>
    '$_base/farewell_bg_${_lang(context)}.png';

/// 끝인사 사진: 한·중·일은 오늘 장면의 밤 버전(앱 안), 그 밖은 지금처럼 인터넷 사진
ImageProvider farewellImage(BuildContext context) => _asia(context)
    ? AssetImage('assets/bye_${_scenes[_scene]}.jpg')
    : CachedNetworkImageProvider(farewellImageUrl(context));
'''

OLD_GREETING_HEAD = "String farewellImageUrl(BuildContext context) =>\n    '$_base/farewell_bg_${_lang(context)}.png';"

MAIN_EDITS = [
    ("앱 켤 때 오늘 장면 고르기",
     "  await AlarmService.init(); // 아침 알람 (알람 때문에 켜졌는지도 확인)\n",
     "  await AlarmService.init(); // 아침 알람 (알람 때문에 켜졌는지도 확인)\n  await initGreetingScene(); // 첫인사·끝인사 오늘 장면 (지난번과 다르게)\n"),
    ("끝인사 사진 미리 준비",
     "      precacheImage(CachedNetworkImageProvider(farewellImageUrl(context)), context,",
     "      precacheImage(farewellImage(context), context,"),
    ("새 사진엔 Paransori 글자 얹기 (한·중·일)",
     "            showTitle: Localizations.localeOf(context).languageCode == 'ko',",
     "            showTitle: greetingHasTitle(context),"),
    ("Paransori 글자 먹색 (연한 파스텔 위에서 잘 보이게)",
     "                            color: Colors.white,\n                            fontSize: 34,",
     "                            color: const Color(0xFF17140F),\n                            fontSize: 34,"),
    ("글자 그림자를 은은한 흰빛으로",
     "                                color: Colors.black.withOpacity(0.18),",
     "                                color: Colors.white.withOpacity(0.55),"),
    ("소리 막대 색을 조금 진하게",
     "                                  color: _barColors[i],",
     "                                  color: Color.lerp(_barColors[i], const Color(0xFF17140F), 0.45),"),
]

SCREENS = ['home_screen.dart', 'player_screen.dart', 'nature_sound_detail_screen.dart',
           'nature_sounds_screen.dart', 'radio_player_screen.dart', 'sound_mix_screen.dart']
FW_OLD = "CachedNetworkImageProvider(farewellImageUrl(context))"
FW_NEW = "farewellImage(context)"

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw

def same_parens(a, b):
    # 여는 괄호와 닫는 괄호의 차이가 고치기 전과 같아야 함
    d = lambda t: [t.count(x) - t.count(y) for x, y in ('()', '{}', '[]')]
    return d(a) == d(b)

gp = find('greeting_images.dart')
mp = os.path.join(LIB, 'main.dart')
if not gp or not os.path.exists(mp):
    print('❌ greeting_images.dart 또는 main.dart를 못 찾았어요'); sys.exit(1)
g, gc = load(gp)
if 'initGreetingScene' in g:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
out = {}
print('[greeting_images.dart]')
if OLD_GREETING_HEAD in g and 'introAssetPath' in g:
    out[gp] = (GREETING, gc); print('  ✔ 장면 고르기 · 새 사진 연결')
else:
    ok = False; print('  ❌ 예전 내용과 달라요 (파일을 보내주세요)')

m, mc = load(mp)
m0 = m
print('[main.dart]')
for name, a, b in MAIN_EDITS:
    if m.count(a) == 1:
        m = m.replace(a, b); print('  ✔', name)
    else:
        ok = False; print('  ❌', name, '(찾은 개수: %d)' % m.count(a))
if not same_parens(m0, m):
    ok = False; print('  ❌ 괄호 개수가 안 맞아요')
out[mp] = (m, mc)

for s in SCREENS:
    p = find(s)
    print('[%s]' % s)
    if not p:
        ok = False; print('  ❌ 파일을 못 찾았어요'); continue
    t, c = load(p)
    if t.count(FW_OLD) == 1:
        out[p] = (t.replace(FW_OLD, FW_NEW), c); print('  ✔ 끝인사 사진')
    else:
        ok = False; print('  ❌ 끝인사 사진 (찾은 개수: %d)' % t.count(FW_OLD))

if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
for p, (t, c) in out.items():
    shutil.copyfile(p, p + '.bak')
    if c:
        t = t.replace('\n', '\r\n')
    open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
