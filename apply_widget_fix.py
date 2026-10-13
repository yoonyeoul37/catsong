# -*- coding: utf-8 -*-
# 홈 위젯 고치기
#  · 재생 버튼: 앱에서 아무것도 안 틀었어도 → 마지막에 듣던 것 이어서 (앱이 꺼져 있으면 첫인사 없이 열면서)
#  · 다음·이전 버튼이 안 되던 것
#  · 바깥 모서리가 너무 둥글어서 안쪽 사진·칸과 겹쳐 보이던 것
# (apply_widget_b.py 를 먼저 적용한 다음에 실행)
import os, sys, shutil

KT = r'''package kr.ssing.catsong

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

/// 홈 위젯 B안 (4×2)
/// 위: 시간대 라디오 사진 위에 지금 듣는 것 + 이전·재생·다음
/// 아래: 음악 · 라디오 · 자연 · 수면 바로가기 (누르면 앱이 그 화면으로 열림)
class PlayerWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) updateAppWidget(context, appWidgetManager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PLAY_PAUSE -> {
                // 앱이 켜져 있으면 앱에게: 듣는 중이면 멈춤·다시, 아무것도 안 틀었으면 마지막에 듣던 것
                val ch = MainActivity.mediaChannel
                if (ch != null) {
                    try {
                        ch.invokeMethod("widgetPlayPause", null)
                        return
                    } catch (_: Exception) {}
                }
                // 앱이 꺼져 있으면: 첫인사 없이 열면서 마지막에 듣던 것 이어서
                try {
                    context.startActivity(Intent(context, MainActivity::class.java).apply {
                        action = "kr.ssing.catsong.WIDGET_GO_resume"
                        putExtra("widgetGo", "resume")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    })
                } catch (_: Exception) {
                    sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                }
            }
            ACTION_NEXT -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_NEXT)
            ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)
        }
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "kr.ssing.catsong.PLAY_PAUSE"
        const val ACTION_NEXT = "kr.ssing.catsong.NEXT"
        const val ACTION_PREV = "kr.ssing.catsong.PREV"
        private const val PREFS = "paran_widget"

        /// 다음·이전 → 앱의 재생 버튼 받는 곳(audio_service)으로 바로
        fun sendMediaKey(context: Context, keyCode: Int) {
            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                component = android.content.ComponentName(
                    context.packageName, "com.ryanheise.audioservice.MediaButtonReceiver")
                putExtra(Intent.EXTRA_KEY_EVENT,
                    android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keyCode))
            })
        }

        /// 곡 정보가 오면 기억해 두고, 없으면(시간대 바뀔 때 등) 기억한 걸로 다시 그림
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String? = null,
            artist: String? = null,
            isPlaying: Boolean? = null,
            schedule: String = ""
        ) {
            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (title != null) {
                p.edit().putString("t", title).putString("a", artist ?: "")
                    .putBoolean("p", isPlaying ?: false).putString("s", schedule).apply()
            }
            val t = p.getString("t", null)
            val a = p.getString("a", null) ?: ""
            val s = p.getString("s", null) ?: ""
            val playing = p.getBoolean("p", false)
            val empty = t == null || t == "플레이쏭" || t == "캣송"

            val views = RemoteViews(context.packageName, R.layout.widget_player)
            views.setTextViewText(R.id.widget_title, if (empty) "파란소리" else t)
            views.setTextViewText(R.id.widget_artist, if (empty) "음악 · 라디오 · 자연을 들어보세요" else a)
            views.setTextViewText(R.id.widget_schedule, s)
            views.setViewVisibility(R.id.widget_schedule, if (s.isEmpty()) View.GONE else View.VISIBLE)
            views.setImageViewResource(R.id.widget_play_pause,
                if (playing) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)
            photo(context)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }

            // 사진 부분 누르면 앱 열기
            val open = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_top, PendingIntent.getActivity(
                context, 0, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))

            // 이전 · 재생 · 다음 (이 위젯에게만 보내기 → 두 번 눌리는 일 없게)
            fun media(action: String, code: Int) = PendingIntent.getBroadcast(
                context, code, Intent(context, PlayerWidget::class.java).setAction(action),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_prev, media(ACTION_PREV, 1))
            views.setOnClickPendingIntent(R.id.widget_play_pause, media(ACTION_PLAY_PAUSE, 2))
            views.setOnClickPendingIntent(R.id.widget_next, media(ACTION_NEXT, 3))

            // 바로가기 4개
            val go = listOf(
                R.id.widget_go_music to "music",
                R.id.widget_go_radio to "radio",
                R.id.widget_go_nature to "nature",
                R.id.widget_go_sleep to "sleep"
            )
            go.forEachIndexed { i, (viewId, target) ->
                val goIntent = Intent(context, MainActivity::class.java).apply {
                    action = "kr.ssing.catsong.WIDGET_GO_$target" // 버튼마다 다른 이름 (안 섞이게)
                    putExtra("widgetGo", target)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                views.setOnClickPendingIntent(viewId, PendingIntent.getActivity(
                    context, 20 + i, goIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /// 지금 시간대 라디오 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
        /// 위젯 띠 모양으로 자르고, 모서리 둥글게, 아래쪽은 글자가 보이게 살짝 어둡게
        private fun photo(context: Context): Bitmap? {
            val h = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val slot = when (h) {
                in 5..10 -> "morning"
                in 11..16 -> "day"
                in 17..21 -> "evening"
                else -> "night"
            }
            val path = "flutter_assets/assets/radio_media_$slot.jpg"
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                context.assets.open(path).use { BitmapFactory.decodeStream(it, null, bounds) }
                var sample = 1
                while (bounds.outWidth / (sample * 2) >= 560) sample *= 2
                val src = context.assets.open(path).use {
                    BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
                } ?: return null
                val w = src.width
                val bh = (w / 2.2f).toInt().coerceAtMost(src.height)
                val top = ((src.height - bh) * 0.35f).toInt()
                val out = Bitmap.createBitmap(w, bh, Bitmap.Config.ARGB_8888)
                val c = Canvas(out)
                val r = w * 0.035f
                c.clipPath(Path().apply {
                    addRoundRect(RectF(0f, 0f, w.toFloat(), bh.toFloat()), r, r, Path.Direction.CW)
                })
                c.drawBitmap(src, Rect(0, top, w, top + bh), Rect(0, 0, w, bh), Paint(Paint.FILTER_BITMAP_FLAG))
                c.drawRect(0f, 0f, w.toFloat(), bh.toFloat(), Paint().apply {
                    shader = LinearGradient(0f, bh * 0.25f, 0f, bh.toFloat(),
                        0x00000000, 0x99000000.toInt(), Shader.TileMode.CLAMP)
                })
                src.recycle()
                out
            } catch (e: Exception) {
                null
            }
        }
    }
}
'''

WIDGET_PLAY = r'''  // ───── 홈 위젯 재생 버튼 ─────
  static RecentContentProvider? _recent;
  static MusicProvider? _music;
  static void attachRecent(RecentContentProvider r, MusicProvider m) {
    _recent = r;
    _music = m;
  }

  /// 위젯 재생 버튼: 듣는 중이면 멈춤, 멈춰 있으면 이어서,
  /// 앱을 켜고 아무것도 안 틀었으면 '최근에 들었어요' 맨 앞의 것
  static Future<void> widgetPlay() async {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return;
    if (CastService.instance.isConnected) {
      await pp.togglePlayPause(); // TV로 듣는 중
      return;
    }
    if (radio.isPlaying || radio.isLoading) {
      await radio.togglePlayPause();
      return;
    }
    if (pp.isPlaying) {
      if (pp.natureSoundName != null) {
        await pp.pauseNatureSound();
      } else {
        await pp.togglePlayPause();
      }
      return;
    }
    if (_target() != null) {
      await _resume(); // 멈춰 둔 것 이어서 (작게 시작해서 천천히)
      return;
    }
    await _playLastRecent();
  }

  /// 이번에 켜고 아무것도 안 틀었으면: 최근에 들었어요 맨 앞의 것
  static Future<void> _playLastRecent() async {
    final r = _recent, pp = _pp, radio = _radio;
    if (r == null || pp == null || radio == null) return;
    // 앱을 막 켰으면 기록이 불러와질 때까지 잠깐 기다리기
    for (var i = 0; i < 25 && r.entries.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (r.entries.isEmpty) return;
    final e = r.entries.first;
    try {
      switch (e.type) {
        case RecentContentType.radio:
          if (e.stationData != null) await radio.playStation(RadioStation.fromJson(e.stationData!));
          break;
        case RecentContentType.nature:
          if (e.natureAssetPath != null) await pp.playNatureSound(e.natureAssetPath!, e.title);
          break;
        case RecentContentType.music:
          final m = _music;
          if (m == null) return;
          // 곡 목록을 다 불러올 때까지 잠깐 기다리기
          for (var i = 0; i < 40 && m.allSongs.isEmpty; i++) {
            await Future.delayed(const Duration(milliseconds: 250));
          }
          final list = m.allSongs.where((s) => s.uri == e.songUri).toList();
          if (list.isNotEmpty) await pp.playFromList(list, 0);
          break;
        case RecentContentType.sleep:
          break;
      }
    } catch (err) {
      debugPrint('위젯 재생 오류: $err');
    }
  }

'''

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

kt_widget = find('PlayerWidget.kt', 'android')
if not kt_widget:
    print('❌ PlayerWidget.kt 를 못 찾았어요'); sys.exit(1)
cur = open(kt_widget, encoding='utf-8').read()
if 'paran_ic_play' not in cur:
    print('❌ 새 위젯이 아직 안 들어가 있어요. apply_widget_b.py 를 먼저 실행해 주세요'); sys.exit(1)
if 'WIDGET_GO_resume' in cur:
    print('이미 적용돼 있어요'); sys.exit(0)

RES = os.path.join('android', 'app', 'src', 'main', 'res')
writes = {}
ok = True

def edit(name, top, pairs):
    global ok
    p = find(name, top)
    if not p:
        print('❌ %s 를 못 찾았어요' % name); ok = False; return
    src, crlf = writes[p] if p in writes else load(p)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[p] = (src, crlf)

# 1) 위젯 코드 다시 쓰기 (재생은 앱에게 · 다음/이전은 바로 · 사진 모서리)
writes[kt_widget] = (KT, True)
print('✔ PlayerWidget.kt (재생·다음·이전, 사진 모서리)')

# 2) 모서리 맞추기: 바깥 20 · 안쪽 여백 10 · 사진/칸 10~12
edit('widget_player.xml', RES, [
    ('위젯 안쪽 여백 8 → 10', 'android:orientation="vertical"\n    android:padding="8dp">', 'android:orientation="vertical"\n    android:padding="10dp">'),
    ('사진과 바로가기 사이 6 → 8', 'android:layout_height="46dp"\n        android:layout_marginTop="6dp"', 'android:layout_height="46dp"\n        android:layout_marginTop="8dp"'),
])
edit('paran_widget_bg.xml', RES, [('바깥 모서리 22 → 20', 'android:radius="22dp"', 'android:radius="20dp"')])
edit('paran_widget_chip.xml', RES, [('바로가기 칸 모서리 12 → 10', 'android:radius="12dp"', 'android:radius="10dp"')])
edit('paran_widget_photo_empty.xml', RES, [('사진 자리 모서리 16 → 12', 'android:radius="16dp"', 'android:radius="12dp"')])

# 3) MainActivity: 위젯이 앱에 바로 말할 수 있게
edit('MainActivity.kt', 'android', [
    ('위젯 → 앱 통로 칸', '        var recordingChannel: MethodChannel? = null\n',
     '        var recordingChannel: MethodChannel? = null\n'
     '        // 홈 위젯 재생 버튼 → 앱 (앱이 켜져 있을 때만 있음)\n'
     '        var mediaChannel: MethodChannel? = null\n'),
    ('위젯 → 앱 통로 연결', '        flutterMethodChannel = channel\n',
     '        flutterMethodChannel = channel\n        mediaChannel = channel\n'),
])

# 4) 다트: 위젯 재생 버튼
edit('headset_resume.dart', 'lib', [
    ('불러오기', "import 'cast_service.dart';\n",
     "import 'cast_service.dart';\n"
     "import '../providers/recent_content_provider.dart';\n"
     "import '../providers/music_provider.dart';\n"
     "import '../models/recent_content_entry.dart';\n"
     "import '../models/radio_station.dart';\n"),
    ('위젯 재생 버튼 기능', "  /// 3초 동안 천천히 원래 크기로 (처음엔 아주 천천히)\n",
     WIDGET_PLAY + "  /// 3초 동안 천천히 원래 크기로 (처음엔 아주 천천히)\n"),
])
edit('main.dart', 'lib', [
    ('최근 기록 연결', "  HeadsetResume.init(playerProvider, radioProvider); // 이어폰 연결하면 이어서 듣기\n",
     "  HeadsetResume.init(playerProvider, radioProvider); // 이어폰 연결하면 이어서 듣기\n"
     "  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n"),
])
edit('player_provider.dart', os.path.join('lib', 'providers'), [
    ('위젯 재생 버튼 → 똑똑하게', "        case 'widgetPlayPause':\n          await togglePlayPause();\n",
     "        case 'widgetPlayPause':\n          await HeadsetResume.widgetPlay(); // 안 틀었으면 마지막에 듣던 것\n"),
])
edit('home_screen.dart', os.path.join('lib', 'screens'), [
    ('불러오기', "import '../utils/widget_go.dart';\n",
     "import '../utils/widget_go.dart';\nimport '../services/headset_resume.dart';\n"),
    ('꺼져 있다 위젯 재생으로 켜졌을 때',
     "      case 'sleep':\n        await Navigator.push(context, instant(const SleepFocusScreen()));\n        break;\n",
     "      case 'sleep':\n        await Navigator.push(context, instant(const SleepFocusScreen()));\n        break;\n"
     "      case 'resume':\n        await HeadsetResume.widgetPlay(); // 위젯 재생: 마지막에 듣던 것\n        break;\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)

BK = '_backup_widget2'
for p, (src, crlf) in writes.items():
    if os.path.exists(p):
        b = os.path.join(BK, p)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        shutil.copyfile(p, b)
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (%d개 파일, 원래 것은 _backup_widget2 폴더에 백업)' % len(writes))
