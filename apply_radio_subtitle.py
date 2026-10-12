# -*- coding: utf-8 -*-
# 미디어 출력 둘째 줄: 'South Korea' 대신 한글로 (한국 방송은 목록 설명, 해외는 나라 이름)
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

HELPER = '''  /// 미디어 출력 둘째 줄 (편성표 없을 때): 한국 방송은 목록 설명, 해외는 나라 이름 (앱 언어로)
  String _mediaSubtitle(RadioStation station) {
    final code = (station.countryCode ?? '').toUpperCase();
    final isKo = AppLocale.current?.localeName.startsWith('ko') ?? false;
    if (code == 'KR' && isKo) {
      final d = koreanStationDesc(station.name);
      if (d != null) return d;
    }
    for (final c in RadioCountry.supported) {
      if (c.code == code) return c.displayName;
    }
    return station.country ?? 'Radio';
  }

'''

FILES = {
    'radio_provider.dart': [
        ("한글 설명 가져오기 연결",
         "import '../services/schedule_service.dart';\n",
         "import '../services/schedule_service.dart';\nimport '../l10n/locale_holder.dart';\nimport '../screens/radio_korea_screen2.dart' show koreanStationDesc;\n"),
        ("둘째 줄 정하는 함수",
         "  void _startForeground(RadioStation station, String url) {\n",
         HELPER + "  void _startForeground(RadioStation station, String url) {\n"),
        ("South Korea 대신 한글",
         "        artist: station.country ?? 'Radio',\n",
         "        artist: _mediaSubtitle(station),\n"),
    ],
    'radio_korea_screen2.dart': [
        ("방송 이름으로 설명 찾기",
         "/// 방송 둘째 줄: '지역 · 방송 성격' (예: 서울 · 뉴스·시사)\nString _stationDesc(_KStation s) {",
         "/// 미디어 출력용: 방송 이름 → 목록과 같은 설명 (없으면 null)\nString? koreanStationDesc(String name) {\n  for (final s in koreanStations) {\n    if (s.name == name) return _stationDesc(s);\n  }\n  return null;\n}\n\n/// 방송 둘째 줄: '지역 · 방송 성격' (예: 서울 · 뉴스·시사)\nString _stationDesc(_KStation s) {"),
    ],
}

texts = {}
for fname in FILES:
    p = find(fname)
    if not p:
        print('❌ 파일을 못 찾았어요:', fname); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    texts[fname] = [p, raw.replace('\r\n', '\n'), '\r\n' in raw]

if '_mediaSubtitle' in texts['radio_provider.dart'][1]:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for fname, edits in FILES.items():
    t = texts[fname][1]
    for name, a, b in edits:
        if t.count(a) == 1:
            t = t.replace(a, b); print('✔', name)
        else:
            ok = False; print('❌', name, '(찾은 개수: %d)' % t.count(a))
    if not all(t.count(x) == t.count(y) for x, y in ('()', '{}', '[]')):
        ok = False; print('❌ 괄호 개수가 안 맞아요:', fname)
    texts[fname][1] = t

if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
for fname, (p, t, crlf) in texts.items():
    shutil.copyfile(p, p + '.bak')
    if crlf:
        t = t.replace('\n', '\r\n')
    open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
