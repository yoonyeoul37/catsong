# -*- coding: utf-8 -*-
# 위젯 사진 오른쪽 위에 🔀 섞기 · 🔁 반복 (음악일 때만)
#  - 🔁 누를 때마다: 반복 안 함(흐리게) → 한 곡 반복(🔂) → 전체 반복
#  - 🔀 켜면 진하게, 끄면 흐리게
#  - 앱 안에서 바꿔도 위젯에 똑같이 / 라디오·자연일 땐 숨김
#  (apply_widget_lyrics.py 먼저 해야 해요)
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

res = os.path.join('android', 'app', 'src', 'main', 'res')
pw = find('PlayerWidget.kt', 'android')
lay = find('widget_player.xml', res)
pp = find('player_provider.dart', os.path.join('lib', 'providers'))
lp = find('lyrics_provider.dart', os.path.join('lib', 'providers'))
hr = find('headset_resume.dart', 'lib')
for n, p in (('PlayerWidget.kt', pw), ('widget_player.xml', lay), ('player_provider.dart', pp),
             ('lyrics_provider.dart', lp), ('headset_resume.dart', hr)):
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

if 'ACTION_REPEAT' in open(pw, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)
if 'attachWidget' not in open(lp, encoding='utf-8').read():
    print('❌ apply_widget_lyrics.py 를 먼저 해 주세요'); sys.exit(1)

writes = {}
ok = True
def edit(path, pairs):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    for item in pairs:
        label, old, new = item[0], item[1], item[2]
        cnt = item[3] if len(item) > 3 else 1
        n = src.count(old)
        if n != cnt:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

# ───────── 아이콘 3개 (새 파일) ─────────
ICONS = {
    'paran_ic_shuffle.xml': 'M10.59,9.17L5.41,4 4,5.41l5.17,5.17 1.42,-1.41zM14.5,4l2.04,2.04L4,18.59 5.41,20 17.96,7.46 20,9.5L20,4h-5.5zM14.83,13.41l-1.41,1.41 3.13,3.13L14.5,20L20,20v-5.5l-2.04,2.04 -3.13,-3.13z',
    'paran_ic_repeat.xml': 'M7,7h10v3l4,-4 -4,-4v3L5,5v6h2L7,7zM17,17L7,17v-3l-4,4 4,4v-3h12v-6h-2v4z',
    'paran_ic_repeat_one.xml': 'M7,7h10v3l4,-4 -4,-4v3L5,5v6h2L7,7zM17,17L7,17v-3l-4,4 4,4v-3h12v-6h-2v4zM13,15L13,9h-1l-2,1v1h1.5v4L13,15z',
}
new_files = {}
for name, path_data in ICONS.items():
    new_files[os.path.join(res, 'drawable', name)] = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="24dp"\n'
        '    android:height="24dp"\n'
        '    android:viewportWidth="24"\n'
        '    android:viewportHeight="24">\n'
        '    <path android:fillColor="#FFFFFFFF" android:pathData="%s" />\n'
        '</vector>\n' % path_data)
    print('✔ 아이콘 만들기: %s' % name)

# ───────── widget_player.xml: 사진 오른쪽 위 ─────────
edit(lay, [
    ('위젯 모양: 오른쪽 위 섞기·반복 자리',
     '            android:text="Paransori"\n'
     '            android:textColor="#F2FFFFFF"\n'
     '            android:textSize="11.5sp"\n'
     '            android:textStyle="bold" />\n',
     '            android:text="Paransori"\n'
     '            android:textColor="#F2FFFFFF"\n'
     '            android:textSize="11.5sp"\n'
     '            android:textStyle="bold" />\n'
     '\n'
     '        <!-- 섞기 · 반복 (음악일 때만 보임) -->\n'
     '        <LinearLayout\n'
     '            android:id="@+id/widget_modes"\n'
     '            android:layout_width="wrap_content"\n'
     '            android:layout_height="wrap_content"\n'
     '            android:layout_gravity="top|end"\n'
     '            android:layout_marginTop="2dp"\n'
     '            android:layout_marginEnd="6dp"\n'
     '            android:orientation="horizontal"\n'
     '            android:visibility="gone">\n'
     '\n'
     '            <ImageView\n'
     '                android:id="@+id/widget_shuffle"\n'
     '                android:layout_width="34dp"\n'
     '                android:layout_height="34dp"\n'
     '                android:padding="8dp"\n'
     '                android:src="@drawable/paran_ic_shuffle"\n'
     '                android:tint="#FFFFFF" />\n'
     '\n'
     '            <ImageView\n'
     '                android:id="@+id/widget_repeat"\n'
     '                android:layout_width="34dp"\n'
     '                android:layout_height="34dp"\n'
     '                android:padding="8dp"\n'
     '                android:src="@drawable/paran_ic_repeat"\n'
     '                android:tint="#FFFFFF" />\n'
     '        </LinearLayout>\n'),
])

# ───────── PlayerWidget.kt ─────────
edit(pw, [
    ('위젯: 버튼 이름',
     '        const val ACTION_KIND = "kr.ssing.catsong.PLAY_KIND_" // 뒤에 music · radio · nature\n',
     '        const val ACTION_KIND = "kr.ssing.catsong.PLAY_KIND_" // 뒤에 music · radio · nature\n'
     '        const val ACTION_REPEAT = "kr.ssing.catsong.REPEAT"\n'
     '        const val ACTION_SHUFFLE = "kr.ssing.catsong.SHUFFLE"\n'),
    ('위젯: 섞기·반복 누르면 앱에게',
     '            a == ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)\n',
     '            a == ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)\n'
     '            a == ACTION_REPEAT || a == ACTION_SHUFFLE -> {\n'
     '                if (MainActivity.mediaChannel != null) {\n'
     '                    flipMode(context, a == ACTION_REPEAT) // 누르자마자 모양 먼저\n'
     '                    toApp(if (a == ACTION_REPEAT) "widgetRepeat" else "widgetShuffle", null) {}\n'
     '                }\n'
     '            }\n'),
    ('위젯: 누르자마자 모양 바꾸기',
     '        /// 누르자마자 위젯 모양부터 바꾸기\n',
     '        /// 반복·섞기: 누르자마자 위젯 모양 먼저 (앱도 같은 값으로 저장함)\n'
     '        private fun flipMode(context: Context, repeat: Boolean) {\n'
     '            try {\n'
     '                val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)\n'
     '                if (repeat) {\n'
     '                    // 0 반복 안 함 → 1 한 곡 반복 → 2 전체 반복\n'
     '                    fp.edit().putLong("flutter.w_loop", (fp.getLong("flutter.w_loop", 0L) + 1) % 3).apply()\n'
     '                } else {\n'
     '                    fp.edit().putBoolean("flutter.w_shuffle", !fp.getBoolean("flutter.w_shuffle", false)).apply()\n'
     '                }\n'
     '            } catch (_: Exception) {}\n'
     '            refreshAll(context)\n'
     '        }\n'
     '\n'
     '        /// 누르자마자 위젯 모양부터 바꾸기\n'),
    ('위젯: 섞기·반복 그리기',
     '                if (playing || loading) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)\n',
     '                if (playing || loading) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)\n'
     '            // 섞기 · 반복 (음악일 때만, 꺼져 있으면 흐리게)\n'
     '            val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)\n'
     '            val music = try { fp.getBoolean("flutter.w_music", false) } catch (_: Exception) { false }\n'
     '            val loop = try { fp.getLong("flutter.w_loop", 0L) } catch (_: Exception) { 0L }\n'
     '            val shuf = try { fp.getBoolean("flutter.w_shuffle", false) } catch (_: Exception) { false }\n'
     '            views.setViewVisibility(R.id.widget_modes, if (music && !empty) View.VISIBLE else View.GONE)\n'
     '            views.setImageViewResource(R.id.widget_repeat,\n'
     '                if (loop == 1L) R.drawable.paran_ic_repeat_one else R.drawable.paran_ic_repeat)\n'
     '            views.setInt(R.id.widget_repeat, "setImageAlpha", if (loop == 0L) 110 else 255)\n'
     '            views.setInt(R.id.widget_shuffle, "setImageAlpha", if (shuf) 255 else 110)\n'),
    ('위젯: 섞기·반복 누르는 곳',
     '            views.setOnClickPendingIntent(R.id.widget_next, media(ACTION_NEXT, 3))\n',
     '            views.setOnClickPendingIntent(R.id.widget_next, media(ACTION_NEXT, 3))\n'
     '            views.setOnClickPendingIntent(R.id.widget_repeat, media(ACTION_REPEAT, 4))\n'
     '            views.setOnClickPendingIntent(R.id.widget_shuffle, media(ACTION_SHUFFLE, 5))\n'),
])

# ───────── player_provider.dart ─────────
edit(pp, [
    ('앱: 위젯 섞기·반복 받기',
     "        case 'widgetGo':\n",
     "        case 'widgetRepeat':\n"
     "          toggleLoopMode(); // 위젯: 반복 안 함 → 한 곡 → 전체\n"
     "          break;\n"
     "        case 'widgetShuffle':\n"
     "          toggleShuffle(); // 위젯: 섞기 켜기·끄기\n"
     "          break;\n"
     "        case 'widgetGo':\n"),
    ('앱: 위젯에 알려줄 곳',
     '  Future<void> _saveLoopMode() async {\n',
     '  /// 위젯이 직접 읽는 반복·섞기 값 저장 (+ 위젯 다시 그리기)\n'
     '  static VoidCallback? widgetResend; // 가사 줄까지 다시 보내기 (lyrics_provider가 채움)\n'
     '  Future<void> _saveWidgetModes({bool redraw = true}) async {\n'
     '    try {\n'
     '      final p = await SharedPreferences.getInstance();\n'
     "      await p.setInt('w_loop', _loopMode == LoopMode.one ? 1 : _loopMode == LoopMode.all ? 2 : 0);\n"
     "      await p.setBool('w_shuffle', _isShuffled);\n"
     '    } catch (_) {}\n'
     '    if (!redraw || currentSong == null) return;\n'
     '    _updateWidgetPlayState(_isPlaying);\n'
     '    widgetResend?.call();\n'
     '  }\n'
     '\n'
     '  Future<void> _saveLoopMode() async {\n'),
    ('앱: 켤 때 반복 값 위젯에',
     '    _loopMode = LoopMode.values[saved];\n'
     '    notifyListeners();\n',
     '    _loopMode = LoopMode.values[saved];\n'
     '    notifyListeners();\n'
     '    _saveWidgetModes(redraw: false);\n'),
    ('앱: 반복 바꾸면 위젯에 (2곳)',
     '    _saveLoopMode();\n'
     '  }\n',
     '    _saveLoopMode();\n'
     '    _saveWidgetModes();\n'
     '  }\n', 2),
    ('앱: 섞기 바꾸면 위젯에',
     '    }\n'
     '    notifyListeners();\n'
     '  }\n'
     '\n'
     '  void toggleLoopMode() {\n',
     '    }\n'
     '    notifyListeners();\n'
     '    _saveWidgetModes();\n'
     '  }\n'
     '\n'
     '  void toggleLoopMode() {\n'),
])

# ───────── lyrics_provider.dart: 모양만 바뀌어도 가사 줄 다시 ─────────
edit(lp, [
    ('가사: 위젯 다시 그릴 때 가사 줄도',
     '    _wp = pp;\n'
     '    pp.addListener(_widgetTick);\n',
     '    _wp = pp;\n'
     '    pp.addListener(_widgetTick);\n'
     '    PlayerProvider.widgetResend = () {\n'
     '      _wLine = null;\n'
     '      _widgetTick();\n'
     '    };\n'),
])

# ───────── headset_resume.dart: 지금 음악인지 위젯에 ─────────
edit(hr, [
    ('앱: 지금 음악인지 위젯에 알려주기',
     '    _lastKey = key;\n',
     '    _lastKey = key;\n'
     "    final isMusic = data['type'] == 'music';\n"
     "    SharedPreferences.getInstance().then((p) => p.setBool('w_music', isMusic)); // 위젯 섞기·반복 보이기\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)

BK = os.path.join('..', 'paransori_backup_widget_modes')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
for p, text in new_files.items():
    open(p, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_modes)')
