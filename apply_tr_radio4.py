# -*- coding: utf-8 -*-
# 한국 라디오 목록 화면 번역 (버튼·탭만)
import os, sys, json
KEYS = json.loads('{"niceNow": ["지금 듣기 좋은", "Good to hear now", "今聴きたい", "现在适合收听", "現在適合收聽", null], "tryRolling": ["던져보세요!", "Roll it!", "振ってみて！", "掷一下吧！", "擲一下吧！", null], "byBroadcaster": ["방송사별", "By station", "放送局別", "按电台", "依電台", null], "byRegion": ["지역별", "By region", "地域別", "按地区", "依地區", null], "selectCountryShort": ["국가선택", "Country", "国を選択", "选择国家", "選擇國家", null], "stationLoadFailed": ["방송을 불러올 수 없습니다.\\n다른 채널을 선택해 주세요.", "Can\'t load this station.\\nPlease choose another one.", "放送を読み込めません。\\n別のチャンネルを選んでください。", "无法加载电台。\\n请选择其他频道。", "無法載入電台。\\n請選擇其他頻道。", null]}')
EDITS = json.loads('[["screens/radio_korea_screen2.dart", "import \'package:shared_preferences/shared_preferences.dart\';\\n", "import \'package:shared_preferences/shared_preferences.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["screens/radio_korea_screen2.dart", "Text(diceI >= 0 ? \'주사위가 고른 방송\' : \'지금 듣기 좋은\',", "Text(diceI >= 0 ? tr.heroDicePick : tr.niceNow,", 1], ["screens/radio_korea_screen2.dart", "child: const Text(\'던져보세요!\',\\n                                              textScaler: TextScaler.noScaling,\\n                                              style: TextStyle(", "child: Text(tr.tryRolling,\\n                                              textScaler: TextScaler.noScaling,\\n                                              style: const TextStyle(", 1], ["screens/radio_korea_screen2.dart", "          \'최근 들은 방송이 없어요\',", "          tr.noRecentStations,", 1], ["screens/radio_korea_screen2.dart", "        const weekdays = [\'월\', \'화\', \'수\', \'목\', \'금\', \'토\', \'일\'];", "        final weekdays = tr.weekdaysShort.split(\',\');", 1], ["screens/radio_korea_screen2.dart", "                Text(\\n                  region,\\n                  textAlign: TextAlign.center,", "                Text(\\n                  _regionLabel(region),\\n                  textAlign: TextAlign.center,", 1], ["screens/radio_korea_screen2.dart", "                Text(\'$count개 채널\',", "                Text(tr.channelsCount(count),", 1], ["screens/radio_korea_screen2.dart", "_toggleButton(\'전체\', _ViewMode.all, isDarkMode),", "_toggleButton(tr.all, _ViewMode.all, isDarkMode),", 1], ["screens/radio_korea_screen2.dart", "_toggleButton(\'방송사별\', _ViewMode.broadcaster, isDarkMode),", "_toggleButton(tr.byBroadcaster, _ViewMode.broadcaster, isDarkMode),", 1], ["screens/radio_korea_screen2.dart", "_toggleButton(\'지역별\', _ViewMode.region, isDarkMode),", "_toggleButton(tr.byRegion, _ViewMode.region, isDarkMode),", 1], ["screens/radio_korea_screen2.dart", "_toggleButton(\'최근청취\', _ViewMode.recent, isDarkMode),", "_toggleButton(tr.recentListened, _ViewMode.recent, isDarkMode),", 1], ["screens/radio_korea_screen2.dart", "                        Text(\'국가선택\',\\n", "                        Text(tr.selectCountryShort,\\n", 1], ["screens/radio_korea_screen2.dart", "                          child: Text(\'한국\',\\n", "                          child: Text(tr.countryKR,\\n", 1], ["screens/radio_korea_screen2.dart", "                Text(\\n                  key,\\n                  style: const TextStyle(\\n                    color: Colors.white,\\n                    fontSize: 17,", "                Text(\\n                  key == \'기타\' ? tr.categoryEtc : key,\\n                  style: const TextStyle(\\n                    color: Colors.white,\\n                    fontSize: 17,", 1], ["screens/radio_korea_screen2.dart", "                  \'${stations.length}개 채널\',", "                  tr.channelsCount(stations.length),", 1], ["screens/radio_korea_screen2.dart", "  Widget _buildRegionGrid(BuildContext context) {\\n", "  /// 지역 이름 (저장은 한국어 그대로, 화면엔 언어에 맞게)\\n  static String _regionLabel(String r) => switch (r) {\\n        \'수도권\' => tr.regionCapital,\\n        \'부산/경남\' => tr.regionBusanGyeongnam,\\n        \'대구/경북\' => tr.regionDaeguGyeongbuk,\\n        \'광주/전남\' => tr.regionGwangjuJeonnam,\\n        \'전북\' => tr.regionJeonbuk,\\n        \'대전/충남\' => tr.regionDaejeonChungnam,\\n        \'충북\' => tr.regionChungbuk,\\n        \'강원\' => tr.regionGangwon,\\n        \'제주\' => tr.regionJeju,\\n        _ => r,\\n      };\\n\\n  Widget _buildRegionGrid(BuildContext context) {\\n", 1], ["screens/radio_korea_screen2.dart", "        title: Text(broadcaster,\\n", "        title: Text(broadcaster == \'기타\' ? tr.categoryEtc : _RadioKoreaScreenState._regionLabel(broadcaster),\\n", 1], ["providers/radio_provider.dart", "import \'../screens/radio_korea_screen2.dart\' show koreanStationDesc;\\n", "import \'../screens/radio_korea_screen2.dart\' show koreanStationDesc;\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["providers/radio_provider.dart", "_errorMessage = \'방송을 불러올 수 없습니다.\\\\n다른 채널을 선택해 주세요.\';", "_errorMessage = tr.stationLoadFailed;", 2], ["providers/radio_provider.dart", "          final tr = m[\'clicktrend\'];\\n          if (tr is num) _stationTrend[s.stationUuid] = tr.toInt();", "          final trend = m[\'clicktrend\'];\\n          if (trend is num) _stationTrend[s.stationUuid] = trend.toInt();", 1], ["providers/radio_provider.dart", "              final tr = m[\'clicktrend\'];\\n              if (tr is num) _stationTrend[s.stationUuid] = tr.toInt();", "              final trend = m[\'clicktrend\'];\\n              if (trend is num) _stationTrend[s.stationUuid] = trend.toInt();", 1], ["providers/radio_provider.dart", "    final period = time.period == DayPeriod.am ? \'오전\' : \'오후\';\\n    return \'$period $h:$m\';", "    final period = time.period == DayPeriod.am ? tr.am : tr.pm;\\n    return tr.timeAmPm(period, \'$h:$m\');", 1]]')
LANGS = ['ko', 'en', 'ja', 'zh', 'zh_Hant']
ROOT = 'lib'
def rd(p):
    with open(p, 'r', encoding='utf-8', newline='') as f: return f.read()
def wr(p, t):
    with open(p, 'w', encoding='utf-8', newline='') as f: f.write(t)
import re
STR = re.compile(r"'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\"|//[^\n]*")
def diff(s):
    s = STR.sub('', s)
    return [s.count(a) - s.count(b) for a, b in ['()', '[]', '{}']]
if not os.path.isdir(ROOT):
    print('❌ lib 폴더가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
out = {}
ok = True
# 1) 번역 문구 넣기
arbs = {}
for i, lang in enumerate(LANGS):
    p = os.path.join(ROOT, 'l10n', 'app_%s.arb' % lang)
    if not os.path.exists(p):
        print('❌', 'app_%s.arb' % lang, '파일이 없어요'); sys.exit(1)
    arbs[lang] = (p, rd(p))
have = json.loads(arbs['ko'][1])
if KEYS and all(k in have for k in KEYS):
    already_keys = True
else:
    already_keys = False
    for lang, (p, t) in arbs.items():
        d = json.loads(t)
        dup = [k for k in KEYS if k in d]
        if dup:
            print('❌', os.path.basename(p), '에 이미 있는 이름:', ', '.join(dup)); ok = False; continue
        nl = '\r\n' if '\r\n' in t else '\n'
        lines = []
        for k, v in KEYS.items():
            val = v[LANGS.index(lang)]
            lines.append('  %s: %s' % (json.dumps(k), json.dumps(val, ensure_ascii=False)))
            if lang in ('ko', 'en') and v[5]:
                ph = {name: {'type': typ} for name, typ in v[5].items()}
                lines.append('  %s: %s' % (json.dumps('@' + k), json.dumps({'placeholders': ph}, ensure_ascii=False)))
        end = t.rstrip()
        if not end.endswith('}'):
            print('❌', os.path.basename(p), '모양이 이상해요'); ok = False; continue
        body = end[:-1].rstrip()
        new = body + ',' + nl + (',' + nl).join(lines) + nl + '}' + (nl if t.endswith(('\n',)) else '')
        try:
            json.loads(new)
        except Exception as ex:
            print('❌', os.path.basename(p), '저장하면 깨져요', ex); ok = False; continue
        out[p] = new
        print('✔', os.path.basename(p), '문구 %d개' % len(KEYS))
# 2) 코드 고치기
done_edits = 0
for rel, old, new, cnt in EDITS:
    p = os.path.join(ROOT, rel)
    if p not in out:
        if not os.path.exists(p):
            print('❌', rel, '파일이 없어요'); ok = False; continue
        out[p] = rd(p)
    t = out[p]
    crlf = '\r\n' in t
    o = old.replace('\n', '\r\n') if crlf else old
    n = new.replace('\n', '\r\n') if crlf else new
    c = t.count(o)
    if (n and o in n and t.count(n) >= 1) or (c == 0 and (n == '' or t.count(n) >= 1)):
        done_edits += 1; continue
    if c != cnt:
        print('❌', rel, '고칠 곳을 못 찾았어요:', old.strip().splitlines()[0][:70]); ok = False; continue
    out[p] = t.replace(o, n)
if done_edits == len(EDITS) and already_keys:
    print('이미 적용돼 있어요'); sys.exit(0)
if done_edits and not ok:
    pass
if not ok:
    print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
for p, t in out.items():
    if p.endswith('.dart'):
        before = diff(rd(p)); after = diff(t)
        if before != after:
            print('❌', p, '괄호 개수가 안 맞아요'); print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
files = sorted(set(os.path.basename(r) for r, *_ in EDITS))
for p, t in out.items(): wr(p, t)
for f in files: print('✔', f)
print('다 됐어요 (코드 %d곳)' % (len(EDITS) - done_edits))
