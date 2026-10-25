# -*- coding: utf-8 -*-
# MBC·SBS·CPBC: 개인 중계 서버 대신 방송사 공식 주소를 그때그때 받아서 재생
import os, sys

def find(name, sub):
    p = os.path.join('lib', sub, name)
    if os.path.exists(p): return p
    for r, _, fs in os.walk('lib'):
        if name in fs: return os.path.join(r, name)
    return None

PROV = find('radio_provider.dart', 'providers')
KOR = find('radio_korea_screen2.dart', 'screens')
for n, p in [('radio_provider.dart', PROV), ('radio_korea_screen2.dart', KOR)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

ps = open(PROV, 'rb').read().decode('utf-8')
ks = open(KOR, 'rb').read().decode('utf-8')
if 'apis.cpbc.co.kr' in ps:
    print('이미 적용돼 있어요'); sys.exit(0)
PNL = '\r\n' if '\r\n' in ps else '\n'
KNL = '\r\n' if '\r\n' in ks else '\n'

MBC_API = 'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel='
SBS_API = 'https://apis.sbs.co.kr/play-api/1.0/livestream/'
CPBC_API = 'https://apis.cpbc.co.kr/play-api/2.0/onair/channel/radio'

prov_steps = [
 ('MBC: 예전 주소·새 주소 둘 다 알아보기',
  "      if (url.contains('mbcsfm.pls') || url.contains('mbcfm.pls') || url.contains('mbcatm.pls')) {\n"
  "        final channel = url.contains('mbcsfm.pls')\n"
  "            ? 'sfm'\n"
  "            : url.contains('mbcatm.pls')\n"
  "                ? 'chm'\n"
  "                : 'mfm';\n",
  "      if (url.contains('mbcsfm.pls') || url.contains('mbcfm.pls') || url.contains('mbcatm.pls') ||\n"
  "          url.contains('sminiplay.imbc.com')) {\n"
  "        final channel = (url.contains('mbcsfm.pls') || url.contains('channel=sfm'))\n"
  "            ? 'sfm'\n"
  "            : (url.contains('mbcatm.pls') || url.contains('channel=chm'))\n"
  "                ? 'chm'\n"
  "                : 'mfm';\n"),
 ('SBS · CPBC 공식 주소 받기 추가',
  "          debugPrint('MBC 토큰 발급 오류: $e');\n"
  "        }\n"
  "        return null;\n"
  "      }\n",
  "          debugPrint('MBC 토큰 발급 오류: $e');\n"
  "        }\n"
  "        return null;\n"
  "      }\n"
  "\n"
  "      // SBS 파워FM/러브FM: 개인 중계 서버 대신 SBS 공식 주소 (틀 때마다 새로 받음 · 시간이 지나면 못 쓰는 주소)\n"
  "      if (url.contains('sbsfm.pls') || url.contains('sbs2fm.pls') || url.contains('apis.sbs.co.kr')) {\n"
  "        final love = url.contains('sbs2fm.pls') || url.contains('lovefm');\n"
  "        final api = love\n"
  "            ? '" + SBS_API + "lovepc/lovefm?protocol=hls&ssl=Y'\n"
  "            : '" + SBS_API + "powerpc/powerfm?protocol=hls&ssl=Y';\n"
  "        try {\n"
  "          final response = await http.get(Uri.parse(api), headers: {\n"
  "            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',\n"
  "            'Referer': 'https://www.sbs.co.kr/',\n"
  "          }).timeout(const Duration(seconds: 10));\n"
  "          if (response.statusCode == 200) {\n"
  "            final fresh = response.body.trim();\n"
  "            if (fresh.startsWith('http')) return fresh;\n"
  "          }\n"
  "        } catch (e) {\n"
  "          debugPrint('SBS 주소 받기 오류: $e');\n"
  "        }\n"
  "        return null;\n"
  "      }\n"
  "\n"
  "      // CPBC 가톨릭평화방송(서울): 개인 중계 서버 대신 공식 주소 (틀 때마다 새로 받음)\n"
  "      if (url.contains('cpbc.pls') || url.contains('apis.cpbc.co.kr')) {\n"
  "        try {\n"
  "          final response = await http.get(Uri.parse('" + CPBC_API + "'), headers: {\n"
  "            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',\n"
  "            'Referer': 'https://www.cpbc.co.kr/',\n"
  "          }).timeout(const Duration(seconds: 10));\n"
  "          if (response.statusCode == 200) {\n"
  "            final data = json.decode(utf8.decode(response.bodyBytes));\n"
  "            final fresh = data['onair']?['source']?['mediasource']?['mediaurl'];\n"
  "            if (fresh is String && fresh.startsWith('http')) return fresh;\n"
  "          }\n"
  "        } catch (e) {\n"
  "          debugPrint('CPBC 주소 받기 오류: $e');\n"
  "        }\n"
  "        return null;\n"
  "      }\n"),
 ('국내 방송 목록에 SBS·CPBC 넣기 (해외 주소 찾기 안 함)',
  "          station.streamUrl.contains('sbs.co.kr') ||\n",
  "          station.streamUrl.contains('sbs.co.kr') ||\n"
  "          station.streamUrl.contains('sbsfm.pls') ||\n"
  "          station.streamUrl.contains('sbs2fm.pls') ||\n"
  "          station.streamUrl.contains('cpbc') ||\n"),
 ('공식 주소를 못 받으면 중계 서버로 가지 않고 안내',
  "      if (gen != _playGen) return; // 주소 찾는 사이 다른 방송을 눌렀으면 이건 그만\n"
  "      debugPrint('FINAL_URL: $playUrl');\n",
  "      if (gen != _playGen) return; // 주소 찾는 사이 다른 방송을 눌렀으면 이건 그만\n"
  "      // 예전에 저장된 개인 중계 서버 주소로는 틀지 않음 (공식 주소를 못 받았으면 '불러올 수 없어요')\n"
  "      if (playUrl.contains('duckdns.org')) {\n"
  "        _stallTimer?.cancel();\n"
  "        _errorMessage = tr.stationLoadFailed;\n"
  "        _setPlayerState(RadioPlayerState.error);\n"
  "        return;\n"
  "      }\n"
  "      debugPrint('FINAL_URL: $playUrl');\n"),
 ('CPBC 주소에 평화방송 홈페이지 표시 (Referer)',
  "    if (url.contains('sbs')) return 'https://www.sbs.co.kr/';\n",
  "    if (url.contains('sbs')) return 'https://www.sbs.co.kr/';\n"
  "    if (url.contains('cpbc')) return 'https://www.cpbc.co.kr/';\n"),
 ('CPBC 주소에 평화방송 홈페이지 표시 (Origin)',
  "    if (url.contains('sbs')) return 'https://www.sbs.co.kr';\n",
  "    if (url.contains('sbs')) return 'https://www.sbs.co.kr';\n"
  "    if (url.contains('cpbc')) return 'https://www.cpbc.co.kr';\n"),
]

R = "http://serpent0.duckdns.org:8088/"
kor_steps = [
 ('MBC 표준FM 주소', R + "mbcsfm.pls", MBC_API + "sfm"),
 ('MBC FM4U 주소', R + "mbcfm.pls", MBC_API + "mfm"),
 ('MBC 올댓뮤직 주소', R + "mbcatm.pls", MBC_API + "chm"),
 ('SBS 파워FM 주소', R + "sbsfm.pls", SBS_API + "powerpc/powerfm?protocol=hls&ssl=Y"),
 ('SBS 러브FM 주소', R + "sbs2fm.pls", SBS_API + "lovepc/lovefm?protocol=hls&ssl=Y"),
 ('CPBC 가톨릭 주소', R + "cpbc.pls", CPBC_API),
]

ok = True
for name, old, new in prov_steps:
    old = old.replace('\n', PNL); new = new.replace('\n', PNL)
    c = ps.count(old)
    if c == 1:
        ps = ps.replace(old, new); print('✔ [radio_provider]', name)
    else:
        ok = False; print('❌ [radio_provider]', name, '(찾은 개수: %d)' % c)
if 'utf8.decode' in ps and "import 'dart:convert'" not in ps:
    ok = False; print('❌ [radio_provider] dart:convert 가 없어요')
for name, old, new in kor_steps:
    c = ks.count(old)
    if c == 1:
        ks = ks.replace(old, new); print('✔ [radio_korea_screen2]', name)
    else:
        ok = False; print('❌ [radio_korea_screen2]', name, '(찾은 개수: %d)' % c)
if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(PROV, 'wb').write(ps.encode('utf-8'))
open(KOR, 'wb').write(ks.encode('utf-8'))
print('저장했어요:', PROV, '/', KOR)
