# -*- coding: utf-8 -*-
# 위젯 아래 버튼을 '바로 재생'으로 (앱 안 열고)
#  · 음악: 내 음악 목록 첫 곡부터 · 라디오: 마지막에 듣던 방송 · 자연: 마지막에 듣던 소리
#  · 같은 종류가 이미 나오고 있으면 누를 때 멈춤 / 다시
#  · 수면: 아직 소리가 없어서 지금처럼 화면 열기
# apply_widget_headless.py 다음에 실행
import os, re, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if '_backup_widget' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
pw = find('PlayerWidget.kt', 'android')
cur = open(pw, encoding='utf-8').read() if pw else ''
if 'ACTION_KIND' in cur:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'widget_play_at' not in cur:
    print('❌ apply_widget_headless.py 를 먼저 실행해 주세요'); sys.exit(1)

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

# ── 1) 위젯 코드 ──
edit(pw, [
    ('버튼 이름 앞부분',
     '        const val ACTION_PREV = "kr.ssing.catsong.PREV"\n',
     '        const val ACTION_PREV = "kr.ssing.catsong.PREV"\n'
     '        const val ACTION_KIND = "kr.ssing.catsong.PLAY_KIND_" // 뒤에 music · radio · nature\n'),
    ('위젯 재생 버튼 표시에서 종류 지우기',
     '.edit().putLong("flutter.widget_play_at", System.currentTimeMillis()).apply()',
     '.edit().putLong("flutter.widget_play_at", System.currentTimeMillis())\n'
     '                    .remove("flutter.widget_play_kind").apply()'),
    ('아래 버튼 눌렀을 때 (앱 안 열고 바로 재생)',
     '            ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)\n        }\n',
     '            ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)\n'
     '            else -> {\n'
     '                // 아래 버튼: 음악 · 라디오 · 자연 바로 재생 (앱 안 열고)\n'
     '                val a = intent.action ?: return\n'
     '                if (!a.startsWith(ACTION_KIND)) return\n'
     '                val kind = a.removePrefix(ACTION_KIND)\n'
     '                val ch = MainActivity.mediaChannel\n'
     '                if (ch != null) {\n'
     '                    try {\n'
     '                        ch.invokeMethod("widgetPlayKind", kind)\n'
     '                        return\n'
     '                    } catch (_: Exception) {}\n'
     '                }\n'
     '                // 앱이 꺼져 있으면: 재생 엔진만 깨워서 (다트가 이 표시를 보고 그 종류를 틂)\n'
     '                context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()\n'
     '                    .putLong("flutter.widget_play_at", System.currentTimeMillis())\n'
     '                    .putString("flutter.widget_play_kind", kind).apply()\n'
     '                sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY)\n'
     '            }\n'
     '        }\n'),
])
src, crlf = writes[pw]
pat = re.compile(r"            go\.forEachIndexed \{ i, \(viewId, target\) ->\n.*?\n            \}\n\n            appWidgetManager\.updateAppWidget", re.S)
if len(pat.findall(src)) != 1:
    print('❌ 아래 버튼 연결 부분'); ok = False
else:
    src = pat.sub(lambda _: (
        "            go.forEachIndexed { i, (viewId, target) ->\n"
        "                val pi = if (target == \"sleep\") {\n"
        "                    // 수면: 아직 소리가 없어서 화면 열기\n"
        "                    val goIntent = Intent(context, MainActivity::class.java).apply {\n"
        "                        action = \"kr.ssing.catsong.WIDGET_GO_$target\"\n"
        "                        putExtra(\"widgetGo\", target)\n"
        "                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP\n"
        "                    }\n"
        "                    PendingIntent.getActivity(context, 20 + i, goIntent,\n"
        "                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)\n"
        "                } else {\n"
        "                    // 음악(첫 곡부터) · 라디오 · 자연: 앱 안 열고 위젯에서 바로 재생\n"
        "                    PendingIntent.getBroadcast(context, 20 + i,\n"
        "                        Intent(context, PlayerWidget::class.java).setAction(ACTION_KIND + target),\n"
        "                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)\n"
        "                }\n"
        "                views.setOnClickPendingIntent(viewId, pi)\n"
        "            }\n\n"
        "            appWidgetManager.updateAppWidget"), src)
    print('✔ 아래 버튼 연결 (음악·라디오·자연 = 바로 재생, 수면 = 화면 열기)')
    writes[pw] = (src, crlf)

# ── 2) 다트 ──
edit(find('main.dart', 'lib'), [
    ('앱이 꺼져 있을 때 아래 버튼 → 그 종류 바로 재생',
     "    final at = sp.getInt('widget_play_at') ?? 0;\n"
     "    if (at > 0) await sp.remove('widget_play_at');\n",
     "    final at = sp.getInt('widget_play_at') ?? 0;\n"
     "    final kind = sp.getString('widget_play_kind') ?? ''; // 아래 버튼 (음악·라디오·자연)\n"
     "    if (at > 0) await sp.remove('widget_play_at');\n"
     "    if (kind.isNotEmpty) await sp.remove('widget_play_kind');\n"),
    ('종류가 있으면 그걸로',
     "      HeadsetResume.widgetPlay();\n    }\n  } catch (_) {}\n",
     "      if (kind.isNotEmpty) {\n"
     "        HeadsetResume.widgetPlayKind(kind);\n"
     "      } else {\n"
     "        HeadsetResume.widgetPlay();\n"
     "      }\n"
     "    }\n  } catch (_) {}\n"),
])
edit(find('player_provider.dart', os.path.join('lib', 'providers')), [
    ('앱이 켜져 있을 때 아래 버튼',
     "        case 'widgetGo':\n",
     "        case 'widgetPlayKind':\n"
     "          await HeadsetResume.widgetPlayKind(call.arguments as String); // 위젯 아래 버튼\n"
     "          break;\n"
     "        case 'widgetGo':\n"),
    ('재생 버튼 신호는 조금 늦게 (아래 버튼과 겹치지 않게)',
     "        HeadsetResume.widgetPlay(); // 틀 게 없으면 마지막에 듣던 것 (위젯·블루투스 재생 버튼)\n",
     "        // 틀 게 없으면 마지막에 듣던 것 (위젯·블루투스 재생 버튼)\n"
     "        // 조금 늦게: 위젯 아래 버튼으로 깨어난 경우엔 그쪽이 먼저 틀게\n"
     "        Future.delayed(const Duration(milliseconds: 800), HeadsetResume.widgetPlay);\n"),
])
edit(find('headset_resume.dart', 'lib'), [
    ('위젯 아래 버튼 기능',
     "  static DateTime _lastWidgetPlay = DateTime(2000);\n",
     "  static DateTime _lastWidgetPlay = DateTime(2000);\n\n"
     "  /// 위젯 아래 버튼: 음악(내 목록 첫 곡부터) · 라디오(마지막에 듣던 방송) · 자연(마지막에 듣던 소리)\n"
     "  /// 같은 종류가 이미 나오고 있으면 → 멈춤 / 다시\n"
     "  static Future<void> widgetPlayKind(String kind) async {\n"
     "    final pp = _pp, radio = _radio, r = _recent;\n"
     "    if (pp == null || radio == null || r == null) return;\n"
     "    _lastWidgetPlay = DateTime.now(); // 재생 버튼 신호가 같이 와도 겹치지 않게\n"
     "    final nowRadio = radio.isPlaying || radio.isLoading;\n"
     "    final nowNature = pp.isPlaying && pp.natureSoundName != null;\n"
     "    final nowMusic = pp.isPlaying && pp.natureSoundName == null && pp.currentSong != null;\n"
     "    try {\n"
     "      switch (kind) {\n"
     "        case 'music':\n"
     "          if (nowMusic) {\n"
     "            await pp.togglePlayPause(); // 듣는 중이면 멈춤\n"
     "            return;\n"
     "          }\n"
     "          final m = _music;\n"
     "          if (m == null) return;\n"
     "          if (m.allSongs.isEmpty && !m.isLoading) m.initialize();\n"
     "          for (var k = 0; k < 40 && m.allSongs.isEmpty; k++) {\n"
     "            await Future.delayed(const Duration(milliseconds: 250));\n"
     "          }\n"
     "          final all = m.songs.isNotEmpty ? m.songs : m.allSongs;\n"
     "          if (all.isNotEmpty) pp.playFromList(all, 0); // 첫 곡부터 목록 순서대로\n"
     "          break;\n"
     "        case 'radio':\n"
     "          if (nowRadio) {\n"
     "            await radio.togglePlayPause();\n"
     "            return;\n"
     "          }\n"
     "          // 마지막에 듣던 방송 (없으면 최근에 들은 방송) + 다음·이전용 목록\n"
     "          final list = <RadioStation>[];\n"
     "          final rp = await SharedPreferences.getInstance();\n"
     "          final saved = rp.getString('widget_last_radio');\n"
     "          if (saved != null) {\n"
     "            try {\n"
     "              list.add(RadioStation.fromJson(Map<String, dynamic>.from(jsonDecode(saved) as Map)));\n"
     "            } catch (_) {}\n"
     "          }\n"
     "          for (final x in r.entries) {\n"
     "            if (x.type == RecentContentType.radio && x.stationData != null) {\n"
     "              try {\n"
     "                final s = RadioStation.fromJson(x.stationData!);\n"
     "                if (!list.any((e) => e.stationUuid == s.stationUuid)) list.add(s);\n"
     "              } catch (_) {}\n"
     "            }\n"
     "          }\n"
     "          if (list.isEmpty) return;\n"
     "          radio.setQueue(list, 0);\n"
     "          await radio.playStation(list.first);\n"
     "          break;\n"
     "        case 'nature':\n"
     "          if (nowNature) {\n"
     "            await pp.pauseNatureSound();\n"
     "            return;\n"
     "          }\n"
     "          // 마지막에 듣던 자연 소리 (없으면 첫 번째 자연 소리)\n"
     "          final np = await SharedPreferences.getInstance();\n"
     "          final name = np.getString('widget_last_nature');\n"
     "          final order = PlayerProvider.natureSoundOrder;\n"
     "          final i = order.indexWhere((s) => s['name'] == name);\n"
     "          final pick = order[i >= 0 ? i : 0];\n"
     "          pp.playNatureSound(pick['assetPath']!, pick['name']!);\n"
     "          break;\n"
     "      }\n"
     "    } catch (err) {\n"
     "      debugPrint('위젯 버튼 재생 오류: $err');\n"
     "    }\n"
     "  }\n"),
    ('종류마다 마지막 것도 따로 기억 (라디오)',
     "      data = {'type': 'radio', 'station': st.toJson()};\n",
     "      data = {'type': 'radio', 'station': st.toJson()};\n"
     "      final js = jsonEncode(st.toJson());\n"
     "      SharedPreferences.getInstance().then((p) => p.setString('widget_last_radio', js));\n"),
    ('종류마다 마지막 것도 따로 기억 (자연)',
     "      key = 'nature|$nature';\n",
     "      key = 'nature|$nature';\n"
     "      SharedPreferences.getInstance().then((p) => p.setString('widget_last_nature', nature));\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_widget9')
for p, (text, crlf) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if crlf else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요')
