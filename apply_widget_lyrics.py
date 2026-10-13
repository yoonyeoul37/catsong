# -*- coding: utf-8 -*-
# 위젯에 지금 부르는 가사 한 줄 (음악일 때, 가사 있는 곡만)
#  - 곡이 바뀌면 가사 화면을 안 열어도 가사를 찾아옴 (전에 찾은 곡은 인터넷 없이 바로)
#  - 줄이 바뀔 때만 위젯에 보냄 / 폰 화면이 꺼져 있으면 위젯은 안 그림 (배터리)
#  - 가사 없는 곡·라디오·자연은 그 줄이 사라짐
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)

lp = find('lyrics_provider.dart', os.path.join('lib', 'providers'))
mn = os.path.join('lib', 'main.dart')
pw = find('PlayerWidget.kt', 'android')
for n, p in (('lyrics_provider.dart', lp), ('main.dart', mn), ('PlayerWidget.kt', pw)):
    if not p or not os.path.isfile(p):
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

if 'attachWidget' in open(lp, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)

writes = {}
ok = True
def edit(path, pairs):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

# ───────── lyrics_provider.dart ─────────
edit(lp, [
    ('가사: 필요한 것 불러오기',
     "import 'package:flutter/foundation.dart';\n",
     "import 'package:flutter/foundation.dart';\n"
     "import 'package:flutter/services.dart';\n"
     "import 'player_provider.dart';\n"),
    ('가사: 위젯에 지금 줄 보내기',
     'class LyricsProvider extends ChangeNotifier {\n',
     'class LyricsProvider extends ChangeNotifier {\n'
     '  /// 앱 전체에서 하나만 (가사 화면 · 재생 화면 · 홈 위젯이 같이 씀)\n'
     '  static final LyricsProvider shared = LyricsProvider();\n'
     '\n'
     '  // ───── 홈 위젯: 지금 부르는 가사 한 줄 ─────\n'
     '  PlayerProvider? _wp;\n'
     "  String _wSong = '';\n"
     "  String? _wLine; // 위젯에 마지막으로 보낸 줄 (null = 다시 보내기)\n"
     '  bool _wPlaying = false;\n'
     '\n'
     '  void attachWidget(PlayerProvider pp) {\n'
     '    _wp = pp;\n'
     '    pp.addListener(_widgetTick);\n'
     '  }\n'
     '\n'
     '  void _widgetTick() {\n'
     '    final pp = _wp;\n'
     '    if (pp == null) return;\n'
     '    final song = pp.currentSong;\n'
     '    final playing = pp.isPlaying && song != null && pp.natureSoundName == null;\n'
     '    if (playing != _wPlaying) {\n'
     '      _wPlaying = playing;\n'
     '      _wLine = null; // 멈췄다 다시 틀면 위젯이 가사 줄을 지우니까 다시 보내기\n'
     '    }\n'
     '    if (!playing || song == null) return;\n'
     "    final key = '${song.titleDisplay}-${song.artistDisplay}';\n"
     '    if (key != _wSong) {\n'
     '      _wSong = key;\n'
     '      _wLine = null;\n'
     '      // 가사 화면을 안 열어도 찾아오기 (이미 찾는 중이거나 찾았으면 그대로)\n'
     '      if (key != _currentSongKey || (!_hasLyrics && !_isLoading)) {\n'
     '        fetchLyrics(song.titleDisplay, song.artistDisplay, filePath: song.uri);\n'
     '      }\n'
     '    }\n'
     "    var line = '';\n"
     '    if (key == _currentSongKey && _hasLyrics) {\n'
     '      ensureEstimated(pp.duration); // 시간 없는 가사는 노래 길이로 짐작\n'
     '      updateCurrentLine(pp.position);\n'
     '      final i = _currentLineIndex;\n'
     '      if (_lyrics.isNotEmpty && i >= 0 && i < _lyrics.length) line = _lyrics[i].text.trim();\n'
     '    }\n'
     '    if (line == _wLine) return; // 줄이 바뀔 때만\n'
     '    _wLine = line;\n'
     "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('updateWidget', {\n"
     "      'title': song.titleDisplay,\n"
     "      'artist': song.artistDisplay,\n"
     "      'isPlaying': true,\n"
     "      'schedule': line.isEmpty ? '' : '♪ $line',\n"
     '    }).catchError((Object _) => null);\n'
     '  }\n'
     '\n'),
])

# ───────── main.dart ─────────
edit(mn, [
    ('앱: 가사 하나로 같이 쓰기',
     '        ChangeNotifierProvider(create: (_) => LyricsProvider()),\n',
     '        ChangeNotifierProvider.value(value: LyricsProvider.shared),\n'),
    ('앱: 위젯 가사 켜기',
     '  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n',
     '  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n'
     '  LyricsProvider.shared.attachWidget(playerProvider); // 위젯에 지금 가사 한 줄\n'),
])

# ───────── PlayerWidget.kt: 화면 꺼져 있으면 가사 줄은 안 그림 ─────────
edit(pw, [
    ('위젯: 화면 꺼져 있으면 가사 줄은 그리지 않기 (배터리)',
     '                if (isPlaying == true || p.getBoolean("load_any", false)) p.edit().remove("load").apply()\n'
     '            }\n',
     '                if (isPlaying == true || p.getBoolean("load_any", false)) p.edit().remove("load").apply()\n'
     '            }\n'
     '            // 가사 줄만 바뀐 건 폰 화면이 꺼져 있으면 기억만 하고 안 그림 (화면 켜면 다음 줄부터)\n'
     '            if (schedule.startsWith("♪")) {\n'
     '                val pm = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager\n'
     '                if (!pm.isInteractive) return\n'
     '            }\n'),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)

BK = os.path.join('..', 'paransori_backup_widget_lyrics')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_lyrics)')
