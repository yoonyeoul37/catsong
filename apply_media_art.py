# -*- coding: utf-8 -*-
# 폰 미디어 출력(알림창)에 앨범 사진·라디오 사진 넘기기 → 사진 색으로 배경·버튼 색이 바뀜
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

ART_CLASS = r'''
/// 폰 미디어 출력(알림창)에 보일 사진 — 폰이 이 사진 색으로 배경·버튼 색을 칠함
class MediaArt {
  static final Map<String, Uri> _done = {};

  static String? _dir;
  static Future<String?> _folder() async {
    if (_dir != null) return _dir;
    try {
      final d = Directory('${Directory.systemTemp.path}/media_art');
      if (!await d.exists()) await d.create(recursive: true);
      _dir = d.path;
    } catch (_) {}
    return _dir;
  }

  /// 사진을 작은 파일로 저장해서 주소 돌려주기 (앱 켜져 있는 동안 한 번만)
  static Future<Uri?> _file(String name, Future<List<int>?> Function() bytes) async {
    final hit = _done[name];
    if (hit != null) return hit;
    try {
      final dir = await _folder();
      if (dir == null) return null;
      final b = await bytes();
      if (b == null || b.isEmpty) return null;
      final f = File('$dir/$name');
      await f.writeAsBytes(b, flush: true);
      return _done[name] = Uri.file(f.path);
    } catch (_) {
      return null;
    }
  }

  /// 사진 준비되면 지금 알림창 항목에 붙이기 (그사이 다른 곡으로 바뀌었으면 안 붙임)
  static void _put(SimpleAudioHandler h, String id, String title, Future<Uri?> art) {
    art.then((uri) {
      final cur = h.mediaItem.value;
      if (uri == null || cur == null || cur.id != id || cur.title != title) return;
      h.mediaItem.add(cur.copyWith(artUri: uri));
    });
  }

  /// 음악: 곡의 앨범 사진 (없으면 그냥 둠)
  static void attachSong(SimpleAudioHandler h, Song song, {String? id, String? title}) {
    final art = song.albumArt;
    if (art == null || art.isEmpty) return;
    _put(h, id ?? song.uri ?? '', title ?? song.titleDisplay,
        _file('song_${song.id}_${art.length}.img', () async => art));
  }

  /// 앱 안의 사진 (라디오 등)
  static void attachAsset(SimpleAudioHandler h, String asset, String id, String title) {
    final name = asset.split('/').last;
    _put(h, id, title, _file(name, () async {
      final data = await rootBundle.load(asset);
      return data.buffer.asUint8List();
    }));
  }

  /// 라디오: 지금 시간대 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
  static String radioHero() {
    final h = DateTime.now().hour;
    final slot = h >= 5 && h < 11
        ? 'morning'
        : h >= 11 && h < 17
            ? 'day'
            : h >= 17 && h < 22
                ? 'evening'
                : 'night';
    return 'assets/radio_hero_$slot.jpg';
  }
}
'''

PP_EDITS = [
    ("import 'dart:io' 추가",
     "import 'dart:async';\n",
     "import 'dart:async';\nimport 'dart:io';\n"),
    ("음악 재생할 때 앨범 사진",
     "          duration: Duration(milliseconds: song.duration),\n        ));\n      }\n\n      _startListen(song);",
     "          duration: Duration(milliseconds: song.duration),\n        ));\n        MediaArt.attachSong(handler, song);\n      }\n\n      _startListen(song);"),
    ("다시 재생할 때 앨범 사진",
     "            duration: Duration(milliseconds: song.duration),\n          ));\n        }\n",
     "            duration: Duration(milliseconds: song.duration),\n          ));\n          MediaArt.attachSong(handler, song);\n        }\n"),
    ("믹스: 곡 받기",
     "    required String subtitle,\n  }) {\n    onResumeLast = null;\n    mediaItem.add(MediaItem(\n      id: 'sound_mix',\n      title: title,\n      artist: subtitle,\n      album: '파란소리 믹스',\n    ));\n",
     "    required String subtitle,\n    Song? song,\n  }) {\n    onResumeLast = null;\n    mediaItem.add(MediaItem(\n      id: 'sound_mix',\n      title: title,\n      artist: subtitle,\n      album: '파란소리 믹스',\n    ));\n    if (song != null) MediaArt.attachSong(this, song, id: 'sound_mix', title: title);\n"),
    ("라디오: 시간대 사진",
     "      album: '파란소리 라디오',\n    ));\n",
     "      album: '파란소리 라디오',\n    ));\n    MediaArt.attachAsset(this, MediaArt.radioHero(), url ?? '', title);\n"),
]

MIX_EDITS = [
    ("믹스 알림에 지금 곡 넘기기",
     "handler.setMixMediaItem(title: title, subtitle: subtitle);",
     "handler.setMixMediaItem(title: title, subtitle: subtitle, song: currentSong);"),
]

def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    return raw.replace('\r\n', '\n'), crlf

def save(p, text, crlf):
    shutil.copyfile(p, p + '.bak')
    if crlf:
        text = text.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(text.encode('utf-8'))

def balanced(t):
    return all(t.count(a) == t.count(b) for a, b in ('()', '{}', '[]'))

pp = find('player_provider.dart')
mx = find('sound_mix_provider.dart')
if not pp or not mx:
    print('❌ 파일을 못 찾았어요:', 'player_provider.dart' if not pp else 'sound_mix_provider.dart')
    sys.exit(1)

t1, c1 = load(pp)
t2, c2 = load(mx)
if 'class MediaArt' in t1:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
for name, a, b in PP_EDITS:
    if t1.count(a) == 1:
        t1 = t1.replace(a, b); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % t1.count(a))
for name, a, b in MIX_EDITS:
    if t2.count(a) == 1:
        t2 = t2.replace(a, b); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % t2.count(a))
t1 = t1.rstrip('\n') + '\n' + ART_CLASS

if ok and not (balanced(t1) and balanced(t2)):
    ok = False; print('❌ 괄호 개수가 안 맞아요')
if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.')
    sys.exit(1)
save(pp, t1, c1)
save(mx, t2, c2)
print('\n완료! 앱을 완전히 껐다가 다시 실행(flutter run)해서 확인하세요.')
