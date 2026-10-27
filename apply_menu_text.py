# -*- coding: utf-8 -*-
# ⋮ 메뉴 설명 문구 (한국어만) — 정중한 말투로 · 설명은 두 줄까지 · 앱 평가하기는 앱 안에서
import os, re, sys, json

def find(name):
    for r, _, fs in os.walk('lib'):
        if name in fs: return os.path.join(r, name)
    return None

ARB = find('app_ko.arb')
GEN = find('app_localizations_ko.dart')
MENU = find('more_menu_sheet.dart')
FB = find('feedback_screen.dart')
RATE = find('rate_app.dart')
for n, p in [('app_ko.arb', ARB), ('app_localizations_ko.dart', GEN), ('more_menu_sheet.dart', MENU), ('feedback_screen.dart', FB)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)
if not RATE:
    print('❌ rate_app.dart 가 없어요 (apply_rate_in_app.py 를 먼저 돌려 주세요)'); sys.exit(1)

NEW = {
 'moreAlarmSub': '좋아하는 노래, 라디오, 자연의 소리로 기분 좋은 아침을 시작하세요.',
 'darkModeInfo': '화면을 어두운 톤으로 변경하여 야간 시청 시 눈의 피로를 줄여줍니다.',
 'moreSettingsSub': '앱 내 환경을 맞춤 설정합니다.',
 'moreHelpSub': '앱 권한, 배터리 최적화, 알림 설정 방법에 대한 가이드를 제공합니다.',
 'moreShareSub': '지인에게 파란소리 앱을 추천합니다.',
 'moreRateSub': '스토어에 별점과 리뷰를 남겨주세요.',
}
FB_OLD = '파란소리에 바라는 점을 들려주세요.'
FB_NEW = '서비스 이용 중 개선점이나 건의사항을 전달합니다.'

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

ar, ANL = load(ARB)
gn, GNL = load(GEN)
mn, MNL = load(MENU)
fb, FNL = load(FB)
if FB_NEW in mn and 'RateApp.open' in mn:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for k, v in NEW.items():
    pat = re.compile(r'("%s":\s*)"(?:[^"\\]|\\.)*"' % re.escape(k))
    if len(pat.findall(ar)) == 1:
        ar = pat.sub(lambda mm: mm.group(1) + json.dumps(v, ensure_ascii=False), ar); print('✔ [app_ko.arb]', k)
    else:
        ok = False; print('❌ [app_ko.arb]', k)
    pat2 = re.compile(r"(String get %s =>)\s*'(?:[^'\\]|\\.)*';" % re.escape(k))
    if len(pat2.findall(gn)) == 1:
        dv = v.replace('\\', '\\\\').replace("'", "\\'").replace('"', '\\"').replace('$', '\\$')
        gn = pat2.sub(lambda mm: mm.group(1) + " '" + dv + "';", gn); print('✔ [app_localizations_ko.dart]', k)
    else:
        ok = False; print('❌ [app_localizations_ko.dart]', k)

def rep(s, nl, name, old, new):
    global ok
    o = old.replace('\n', nl); n = new.replace('\n', nl)
    c = s.count(o)
    if c == 1:
        print('✔', name); return s.replace(o, n)
    ok = False; print('❌', name, '(찾은 개수: %d)' % c); return s

mn = rep(mn, MNL, '[more_menu_sheet] 의견 보내기 설명',
  "subtitle: fbText('%s', " % FB_OLD, "subtitle: fbText('%s', " % FB_NEW)
mn = rep(mn, MNL, '[more_menu_sheet] 설명 두 줄까지 (긴 문구가 … 로 잘리지 않게)',
  "                        subtitle,\n"
  "                        maxLines: 1,\n",
  "                        subtitle,\n"
  "                        maxLines: 2, // 긴 설명은 두 줄까지 (… 로 잘리지 않게)\n")
mn = rep(mn, MNL, '[more_menu_sheet] rate_app 불러오기',
  "import '../l10n/locale_holder.dart';\n",
  "import '../l10n/locale_holder.dart';\n"
  "import '../utils/rate_app.dart';\n")
mn = rep(mn, MNL, '[more_menu_sheet] 앱 평가하기 → 앱 안에서',
  "      onRate: () async {\n"
  "        Navigator.pop(ctx);\n"
  "        final uri = Uri.parse(_kStoreUrl);\n"
  "        if (await canLaunchUrl(uri)) {\n"
  "          await launchUrl(uri, mode: LaunchMode.externalApplication);\n"
  "        }\n"
  "      },\n",
  "      onRate: () async {\n"
  "        Navigator.pop(ctx);\n"
  "        await RateApp.open(); // 앱 안에서 바로 별점 (안 뜨면 플레이 스토어로)\n"
  "      },\n")
fb = rep(fb, FNL, '[feedback_screen] 번역표 열쇠도 같은 문장으로 (다른 언어 번역 그대로)',
  "  '%s': {\n" % FB_OLD, "  '%s': {\n" % FB_NEW)

if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
for p, s in [(ARB, ar), (GEN, gn), (MENU, mn), (FB, fb)]:
    open(p, 'wb').write(s.encode('utf-8'))
print('저장했어요')
