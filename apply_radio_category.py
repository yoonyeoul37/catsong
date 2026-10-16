# -*- coding: utf-8 -*-
# 라디오 전체 목록: 카테고리(주요·음악시사·외국어·종교·교통·지역·공동체)별 정렬 + 이름 뒤 가는 선 제목
# 상세화면 이전/다음 · 주사위 · 홈 '최근에 들었어요'도 같은 순서     실행: python apply_radio_category.py
import os, sys

EDITS = {
    'radio_korea_screen2.dart': [('    final radioStations = koreanStations.map((ks) => _toRadioStation(ks)).toList();', '    final radioStations = koreanStationsSorted.map((ks) => _toRadioStation(ks)).toList(); // 화면 순서(카테고리별) 그대로'), ('    return _DialHost(\n      tickColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),\n      child: ListView.separated(\n      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n      itemCount: koreanStations.length + 1,\n      separatorBuilder: (_, i) => i == 0\n          ? const SizedBox(height: 6)\n          : _DialEffect(\n              child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),\n      itemBuilder: (context, n) {', "    // 카테고리별로 나눈 목록: 제목 줄(-1 - 카테고리) + 방송 줄(정렬된 목록 번호)\n    final items = <int>[];\n    var lastCat = -99;\n    for (var j = 0; j < koreanStationsSorted.length; j++) {\n      final c = stationCategory(koreanStationsSorted[j]);\n      if (c != lastCat) {\n        items.add(-1 - c);\n        lastCat = c;\n      }\n      items.add(j);\n    }\n    final catCounts = <int, int>{};\n    for (final s in koreanStationsSorted) {\n      final c = stationCategory(s);\n      catCounts[c] = (catCounts[c] ?? 0) + 1;\n    }\n    final baseC = isDarkMode ? Colors.white : Colors.black;\n\n    return _DialHost(\n      tickColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),\n      child: ListView.separated(\n      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n      itemCount: items.length + 1,\n      separatorBuilder: (_, i) => i == 0\n          ? const SizedBox(height: 6)\n          : (items[i - 1] < 0 || (i < items.length && items[i] < 0)) // 카테고리 제목 앞뒤는 선 없이\n              ? const SizedBox.shrink()\n              : _DialEffect(\n                  child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),\n      itemBuilder: (context, n) {\n        if (n > 0 && items[n - 1] < 0) {\n          // 카테고리 제목: 이름 · 개수 뒤로 가는 선\n          final c = -1 - items[n - 1];\n          return _DialEffect(\n            child: Padding(\n              padding: EdgeInsets.only(top: n == 1 ? 6 : 22, bottom: 6),\n              child: Row(\n                children: [\n                  Flexible(\n                    child: Text(\n                      stationCategoryLabel(context, c),\n                      maxLines: 1,\n                      overflow: TextOverflow.ellipsis,\n                      style: TextStyle(color: baseC.withOpacity(0.72), fontSize: 12.5, fontWeight: FontWeight.w700),\n                    ),\n                  ),\n                  const SizedBox(width: 6),\n                  Text('${catCounts[c] ?? 0}',\n                      style: GoogleFonts.quicksand(color: baseC.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),\n                  const SizedBox(width: 10),\n                  Expanded(child: Container(height: 1, color: baseC.withOpacity(0.18))),\n                ],\n              ),\n            ),\n          );\n        }"), ('        final i = n - 1;\n        final ks = koreanStations[i];\n        final current = radioProvider.currentStation;', '        final i = items[n - 1];\n        final ks = koreanStationsSorted[i];\n        final current = radioProvider.currentStation;'), ('      final list = koreanStations.map(_toRadioStation).toList();', '      final list = koreanStationsSorted.map(_toRadioStation).toList();'), ('List<RadioStation> koreanRadioStations() =>\n    koreanStations.map(_RadioKoreaScreenState._toRadioStation).toList();', 'List<RadioStation> koreanRadioStations() =>\n    koreanStationsSorted.map(_RadioKoreaScreenState._toRadioStation).toList();'), ('class _KStation {\n  final String name;', "// ── 전체 목록 카테고리 · 정렬 ──\n// 0 주요 방송 · 1 음악·시사 · 2 외국어 · 3 종교 방송 · 4 교통 방송 · 5 지역 방송 · 6 공동체 라디오\nconst _foreignNames = {'아리랑 라디오', 'TBS eFM', 'BeFM', 'EBS 반디'};\n\nint stationCategory(_KStation s) {\n  if (s.broadcaster == '공동체') return 6;\n  if (s.broadcaster == 'TBN') return 4;\n  if (_foreignNames.contains(s.name)) return 2;\n  if (const {'CPBC', 'FEBC', 'BBS'}.contains(s.broadcaster)) return 3;\n  if (s.region == '수도권') return const {'KBS', 'MBC', 'SBS'}.contains(s.broadcaster) ? 0 : 1;\n  return 5;\n}\n\nString stationCategoryLabel(BuildContext context, int c) {\n  final l = Localizations.localeOf(context);\n  final k = l.languageCode == 'zh'\n      ? ((l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'tw' : 'cn')\n      : l.languageCode;\n  const labels = {\n    'ko': ['주요 방송', '음악·시사', '외국어', '종교 방송', '교통 방송', '지역 방송', '공동체 라디오'],\n    'en': ['Major stations', 'Music & news', 'Foreign language', 'Religious', 'Traffic', 'Regional', 'Community radio'],\n    'ja': ['主要局', '音楽・時事', '外国語', '宗教放送', '交通放送', '地方局', 'コミュニティFM'],\n    'tw': ['主要電台', '音樂・時事', '外語', '宗教電台', '交通電台', '地方電台', '社區電台'],\n    'cn': ['主要电台', '音乐・时事', '外语', '宗教电台', '交通电台', '地方电台', '社区电台'],\n  };\n  return (labels[k] ?? labels['ko']!)[c];\n}\n\nconst _regionOrder = ['수도권', '부산/경남', '대구/경북', '광주/전남', '전북', '대전/충남', '충북', '강원', '제주'];\nconst _brandOrder = ['KBS', 'MBC', 'SBS', 'TBC', 'JTV', 'EBS', 'CBS', 'YTN', 'TBS', 'OBS', 'CPBC', 'FEBC', 'BBS',\n    '국악방송', '국방FM', 'Arirang', 'BeFM', 'TBN', '공동체'];\n// 같은 방송사·도시 안 채널 순서 (1라디오 → 해피FM → 1FM …)\nconst _channelOrder = [('1라디오', 1), ('표준FM', 1), ('러브FM', 1), ('해피FM', 2), ('음악FM', 2), ('파워FM', 2),\n    (' AM', 2), ('1FM', 3), ('Classic', 3), ('JOY4U', 3), ('Cool', 4), ('FM4U', 4), ('3라디오', 5), ('올댓뮤직', 6)];\n\nint _channelRank(String name) {\n  for (final (k, r) in _channelOrder) {\n    if (name.contains(k)) return r;\n  }\n  return 0;\n}\n\n/// 전체 목록 화면 순서: 카테고리 → 지역 → 방송사 → 도시 → 채널\nfinal List<_KStation> koreanStationsSorted = () {\n  int idx(List<String> l, String v) {\n    final i = l.indexOf(v);\n    return i < 0 ? 99 : i;\n  }\n\n  int city(_KStation s) => koreanStations.indexWhere((k) => k.region == s.region && k.subLabel == s.subLabel);\n  final l = [...koreanStations];\n  final orig = {for (var i = 0; i < koreanStations.length; i++) koreanStations[i].name: i};\n  l.sort((a, b) {\n    for (final d in [\n      stationCategory(a) - stationCategory(b),\n      idx(_regionOrder, a.region) - idx(_regionOrder, b.region),\n      idx(_brandOrder, a.broadcaster) - idx(_brandOrder, b.broadcaster),\n      city(a) - city(b),\n      _channelRank(a.name) - _channelRank(b.name),\n      orig[a.name]! - orig[b.name]!,\n    ]) {\n      if (d != 0) return d;\n    }\n    return 0;\n  });\n  return l;\n}();\n\nclass _KStation {\n  final String name;")],
}


def find(name):
    for root, _, files in list(os.walk('tools')) + list(os.walk('lib')):
        if name in files:
            return os.path.join(root, name)
    return None


done = {}
total = 0
for name, edits in EDITS.items():
    p = find(name)
    if not p:
        print(f'❌ {name} 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(p, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    cnt = lambda x: [x.count(ch) - x.count(cl) for ch, cl in ('()', '{}', '[]')]
    before = cnt(t)
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if name.endswith('.py'):
        try:
            compile(t, p, 'exec')
        except SyntaxError as e:
            print(f'❌ {name} 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
    elif cnt(t) != before:  # 고치기 전과 괄호 짝이 같아야 함
        print(f'❌ {name} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    done[p] = (t, crlf, n)
    total += n

if total == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, (t, crlf, n) in done.items():
    if n:
        with open(p, 'w', encoding='utf-8', newline='') as f:
            f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
