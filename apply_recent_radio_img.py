# -*- coding: utf-8 -*-
# 홈 '최근에 들었어요' 라디오 카드: 들었을 때 프로그램 사진 보여 주기 (없으면 지금처럼 시간대 그림)
# 고치는 파일 4개: radio_provider · recent_content_provider · main · home_screen     실행: python apply_recent_radio_img.py
import os, sys

EDITS = {
    'radio_provider.dart': [('  void Function(RadioStation station)? onStationPlayed;', '  void Function(RadioStation station, String? image)? onStationPlayed; // image: 그때 프로그램 사진 (없으면 null)'), ('      if (_currentStation?.stationUuid == station.stationUuid && isPlaying) {\n        onStationPlayed?.call(station);\n      }', "      if (_currentStation?.stationUuid == station.stationUuid && isPlaying) {\n        // 들었을 때 나오던 프로그램 사진도 같이 (홈 '최근에 들었어요' 카드 사진)\n        final img = (currentProgramFor(station.name)?['image'] ?? '').toString().trim();\n        onStationPlayed?.call(station, img.isEmpty ? null : img);\n      }")],
    'recent_content_provider.dart': [("  Future<void> addRadio(RadioStation station) async {\n    await _addEntry(RecentContentEntry(\n      type: RecentContentType.radio,\n      key: station.stationUuid,\n      title: station.name,\n      subtitle: (station.country?.isNotEmpty ?? false) ? station.country! : '라디오',\n      playedAt: DateTime.now(),\n      stationData: station.toJson(),\n    ));\n  }", "  Future<void> addRadio(RadioStation station, {String? image}) async {\n    await _addEntry(RecentContentEntry(\n      type: RecentContentType.radio,\n      key: station.stationUuid,\n      title: station.name,\n      subtitle: (station.country?.isNotEmpty ?? false) ? station.country! : '라디오',\n      playedAt: DateTime.now(),\n      // recentImage: 들었을 때 프로그램 사진 (홈 카드에 보여 줌)\n      stationData: {...station.toJson(), if (image != null) 'recentImage': image},\n    ));\n  }")],
    'main.dart': [('    ..onStationPlayed = ((station) => recentContentProvider.addRadio(station))', '    ..onStationPlayed = ((station, image) => recentContentProvider.addRadio(station, image: image))')],
    'home_screen.dart': [('                        thumbnail = _recentAsset(_radioSlotImage(item.playedAt));', "                        // 들었을 때 프로그램 사진 → 없거나 못 불러오면 시간대 라디오 그림\n                        final recentImg = (item.stationData?['recentImage'] ?? '').toString();\n                        final slotImg = _radioSlotImage(item.playedAt);\n                        thumbnail = recentImg.isEmpty\n                            ? _recentAsset(slotImg)\n                            : CachedNetworkImage(\n                                imageUrl: recentImg,\n                                width: 72,\n                                height: 72,\n                                fit: BoxFit.cover,\n                                memCacheWidth: 216,\n                                placeholder: (_, __) => _recentAsset(slotImg),\n                                errorWidget: (_, __, ___) => _recentAsset(slotImg),\n                              );")],
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
