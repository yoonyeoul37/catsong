# -*- coding: utf-8 -*-
# 위젯 재생 버튼: '최근에 들었어요'(30초 넘게 들은 것) 대신 '마지막에 튼 것'을 이어서
# (라디오를 잠깐 듣다 껐는데 음악이 나오던 것 고치기)
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if '_backup_widget' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

p = find('headset_resume.dart', 'lib')
if not p:
    print('❌ headset_resume.dart 를 못 찾았어요 (프로젝트 폴더에서 실행)'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')
if 'widget_last_played' in src:
    print('이미 적용돼 있어요'); sys.exit(0)
if '_playLastRecent' not in src:
    print('❌ apply_widget_fix.py 를 먼저 실행해 주세요'); sys.exit(1)

EDITS = [
('불러오기', "import 'dart:async';\n", "import 'dart:async';\nimport 'dart:convert';\n"),
('마지막에 튼 것 기억하기',
"""    _recent = r;
    _music = m;
  }
""",
"""    _recent = r;
    _music = m;
    // 마지막에 튼 것 기억 (30초 안 들었어도) → 위젯 재생 버튼이 이걸 이어서
    _radio?.addListener(_rememberLast);
    _pp?.addListener(_rememberLast);
  }

  static String _lastKey = '';
  static void _rememberLast() {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return;
    String key;
    Map<String, dynamic> data;
    final st = radio.currentStation;
    final song = pp.currentSong;
    final nature = pp.natureSoundName;
    if (radio.isPlaying && st != null) {
      key = 'radio|${st.stationUuid}';
      data = {'type': 'radio', 'station': st.toJson()};
    } else if (pp.isPlaying && nature != null) {
      final i = PlayerProvider.natureSoundOrder.indexWhere((s) => s['name'] == nature);
      if (i < 0) return;
      key = 'nature|$nature';
      data = {'type': 'nature', 'name': nature, 'path': PlayerProvider.natureSoundOrder[i]['assetPath']};
    } else if (pp.isPlaying && song?.uri != null) {
      key = 'music|${song!.uri}';
      data = {'type': 'music', 'uri': song.uri};
    } else {
      return;
    }
    if (key == _lastKey) return; // 바뀔 때만 저장
    _lastKey = key;
    SharedPreferences.getInstance().then((p) => p.setString('widget_last_played', jsonEncode(data)));
  }

  /// 기억해 둔 '마지막에 튼 것' 틀기 (못 틀면 false)
  static Future<bool> _playSaved(Map<String, dynamic> d, RecentContentProvider r) async {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return false;
    switch (d['type']) {
      case 'radio':
        final st = RadioStation.fromJson(Map<String, dynamic>.from(d['station'] as Map));
        // 다음·이전용 목록: 이 방송 + 최근에 들은 다른 방송들
        final list = <RadioStation>[st];
        for (final x in r.entries) {
          if (x.type == RecentContentType.radio && x.stationData != null) {
            try {
              final s = RadioStation.fromJson(x.stationData!);
              if (s.stationUuid != st.stationUuid) list.add(s);
            } catch (_) {}
          }
        }
        radio.setQueue(list, 0);
        await radio.playStation(st);
        return true;
      case 'nature':
        await pp.playNatureSound(d['path'] as String, d['name'] as String);
        return true;
      case 'music':
        final m = _music;
        if (m == null) return false;
        for (var k = 0; k < 40 && m.allSongs.isEmpty; k++) {
          await Future.delayed(const Duration(milliseconds: 250));
        }
        final all = m.songs.isNotEmpty ? m.songs : m.allSongs;
        final i = all.indexWhere((s) => s.uri == d['uri']);
        if (i < 0) return false;
        await pp.playFromList(all, i); // 그 곡부터 목록 순서대로 계속
        return true;
    }
    return false;
  }
"""),
('위젯 재생: 마지막에 튼 것 먼저',
"""    final r = _recent, pp = _pp, radio = _radio;
    if (r == null || pp == null || radio == null) return;
""",
"""    final r = _recent, pp = _pp, radio = _radio;
    if (r == null || pp == null || radio == null) return;
    // 먼저: 마지막에 튼 것 (30초 안 들었어도) — 없거나 못 틀면 아래 '최근에 들었어요' 맨 앞
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString('widget_last_played');
      if (saved != null && await _playSaved(Map<String, dynamic>.from(jsonDecode(saved) as Map), r)) return;
    } catch (err) {
      debugPrint('위젯 마지막 재생 오류: $err');
    }
"""),
]
ok = True
for label, old, new in EDITS:
    n = src.count(old)
    if n != 1:
        print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
    src = src.replace(old, new)
    print('✔ %s' % label)
if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
shutil.copyfile(p, p + '.bak')
out = src.replace('\n', '\r\n') if crlf else src
open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요: %s (원본은 .bak)' % p)
