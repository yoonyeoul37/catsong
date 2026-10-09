# -*- coding: utf-8 -*-
# 이어폰·블루투스 연결하면 이어서 듣기
#  - 설정 '도구'에 칸 추가: 끄기 / 알림으로 묻기 / 바로 재생 (기본 끄기)
#  - 바로 재생: 듣다가 멈춘 곡·라디오·자연을 아주 작게 시작해서 3초 동안 천천히 키움
#  - 알림으로 묻기: "이어서 들을까요?" 알림 → 누르면 재생
#  - 새 권한 없음 (소리 나가는 곳이 바뀌는 것만 봄), 앱을 완전히 끄면 동작 안 함
import os, sys

def find_main_activity():
    base = os.path.join("android", "app", "src", "main")
    for root, _, files in os.walk(base):
        if "MainActivity.kt" in files:
            return os.path.join(root, "MainActivity.kt")
    return None

MA = find_main_activity() or "android/app/src/main/kotlin/kr/ssing/catsong/MainActivity.kt"
PP = "lib/providers/player_provider.dart"
ST = "lib/screens/settings_screen.dart"
MN = "lib/main.dart"
NEW = "lib/services/headset_resume.dart"

NEW_CODE = r"""import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import 'cast_service.dart';

/// 이어폰·블루투스를 연결하면 듣던 것 이어서 듣기
/// 0 끄기 · 1 알림으로 묻기 · 2 바로 재생 (작게 시작해서 천천히 커짐)
class HeadsetResume {
  static final mode = ValueNotifier<int>(0);
  static const names = ['끄기', '알림으로 묻기', '바로 재생'];
  static const _ch = MethodChannel('kr.ssing.catsong/media');
  static PlayerProvider? _pp;
  static RadioProvider? _radio;
  static Timer? _fade;

  static Future<void> init(PlayerProvider pp, RadioProvider radio) async {
    _pp = pp;
    _radio = radio;
    try {
      final p = await SharedPreferences.getInstance();
      mode.value = p.getInt('headsetResumeMode') ?? 0;
    } catch (_) {}
  }

  static Future<void> setMode(int m) async {
    mode.value = m;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('headsetResumeMode', m);
    } catch (_) {}
  }

  /// 이어서 들을 게 있으면 (종류, 이름) — 없으면 null
  static (String, String)? _target() {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return null;
    if (CastService.instance.isConnected) return null; // TV로 듣는 중
    if (pp.volumeLocked) return null; // 알람 울리는 중
    if (pp.isPlaying || radio.isPlaying || radio.isLoading) return null; // 이미 듣는 중
    final st = radio.currentStation;
    if (st != null) return ('radio', st.name);
    final nature = pp.natureSoundName;
    if (nature != null) return ('nature', nature);
    final song = pp.currentSong;
    if (song != null) return ('music', '${song.titleDisplay} · ${song.artistDisplay}');
    return null;
  }

  /// 안드로이드에서 오는 신호 (연결됨 / 알림의 재생 누름)
  static Future<void> onCall(String method) async {
    if (method == 'onHeadsetResume') {
      await _resume();
      return;
    }
    if (method != 'onHeadsetConnected' || mode.value == 0) return;
    final t = _target();
    if (t == null) return;
    if (mode.value == 1) {
      try {
        await _ch.invokeMethod('showHeadsetAsk', {'title': '이어서 들을까요?', 'text': t.$2});
      } catch (_) {}
    } else {
      await Future.delayed(const Duration(milliseconds: 900)); // 소리 길이 이어폰으로 바뀔 시간
      await _resume();
    }
  }

  static Future<void> _resume() async {
    final t = _target();
    final pp = _pp, radio = _radio;
    if (t == null || pp == null || radio == null) return;
    _fade?.cancel();
    try {
      switch (t.$1) {
        case 'radio':
          await radio.setAlarmVolume(0.05);
          await radio.playStation(radio.currentStation!);
          _rampUp((v) => radio.setAlarmVolume(v));
        case 'nature':
          await pp.player.setVolume(0.05);
          await pp.resumeNatureSound();
          _rampUp((v) => pp.player.setVolume(v));
        default:
          final full = pp.normGain; // 곡마다 소리 크기 맞추기 값까지만
          await pp.player.setVolume(0.05 * full);
          await pp.togglePlayPause();
          _rampUp((v) => pp.player.setVolume(v * full));
      }
    } catch (e) {
      debugPrint('이어서 듣기 오류: $e');
    }
  }

  /// 3초 동안 천천히 원래 크기로 (처음엔 아주 천천히)
  static void _rampUp(void Function(double v) set) {
    var step = 0;
    _fade = Timer.periodic(const Duration(milliseconds: 150), (t) {
      step++;
      final x = (step / 20).clamp(0.0, 1.0);
      set(0.05 + 0.95 * x * x);
      if (step >= 20) t.cancel();
    });
  }
}
"""

KT_FUNCS = r"""    // ───── 이어폰·블루투스 연결하면 "이어서 들을까요?" 알림 ─────
    private val headsetNotiId = 4207

    private fun showHeadsetAsk(title: String, text: String) {
        try {
            val nm = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
            if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel("paran_headset") == null) {
                val ch = android.app.NotificationChannel(
                    "paran_headset", "이어폰 연결 알림", android.app.NotificationManager.IMPORTANCE_HIGH)
                ch.setSound(null, null) // 소리 없이 위에 살짝만
                ch.enableVibration(false)
                nm.createNotificationChannel(ch)
            }
            val open = android.content.Intent(this, MainActivity::class.java).apply {
                putExtra("headsetResume", true)
                addFlags(android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val pi = android.app.PendingIntent.getActivity(
                this, headsetNotiId, open,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE)
            val b = if (Build.VERSION.SDK_INT >= 26) android.app.Notification.Builder(this, "paran_headset")
                    else android.app.Notification.Builder(this)
            b.setSmallIcon(applicationInfo.icon)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(pi)
                .setAutoCancel(true)
                .addAction(android.app.Notification.Action.Builder(
                    null as android.graphics.drawable.Icon?, "재생", pi).build())
            if (Build.VERSION.SDK_INT >= 26) b.setTimeoutAfter(5 * 60 * 1000L) // 5분 지나면 저절로 사라짐
            nm.notify(headsetNotiId, b.build())
        } catch (_: Exception) {}
    }

    private fun cancelHeadsetAsk() {
        try {
            (getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager).cancel(headsetNotiId)
        } catch (_: Exception) {}
    }

    /// 알림의 "재생"을 눌러서 열렸으면 → 앱에 이어서 재생하라고
    private fun handleHeadsetIntent(i: android.content.Intent?) {
        if (i == null || !i.getBooleanExtra("headsetResume", false)) return
        i.removeExtra("headsetResume")
        cancelHeadsetAsk()
        flutterMethodChannel?.invokeMethod("onHeadsetResume", null)
    }

"""

KT_OBJECT = r"""

/// 이어폰·블루투스 연결 알아채기 (앱이 켜져 있거나 뒤에 있을 때)
/// 소리 나가는 곳이 이어폰·블루투스로 바뀌는 것만 봐서 새 권한이 필요 없음
object HeadsetWatch {
    private var channel: MethodChannel? = null
    private var registered = false
    private var startedAt = 0L
    private var lastAt = 0L

    private fun isHeadset(t: Int): Boolean = when (t) {
        AudioDeviceInfo.TYPE_WIRED_HEADSET,
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_USB_HEADSET -> true
        else -> Build.VERSION.SDK_INT >= 31 &&
            (t == AudioDeviceInfo.TYPE_BLE_HEADSET || t == AudioDeviceInfo.TYPE_BLE_SPEAKER)
    }

    private val callback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>?) {
            val now = System.currentTimeMillis()
            if (now - startedAt < 2500) return // 처음 등록할 때 이미 연결돼 있던 건 무시
            if (added == null || added.none { it.isSink && isHeadset(it.type) }) return
            if (now - lastAt < 4000) return // 블루투스는 신호가 여러 번 와서 한 번만
            lastAt = now
            channel?.invokeMethod("onHeadsetConnected", null)
        }
    }

    fun start(ctx: android.content.Context, ch: MethodChannel) {
        channel = ch
        if (registered) return
        registered = true
        startedAt = System.currentTimeMillis()
        val am = ctx.applicationContext.getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager
        am.registerAudioDeviceCallback(callback, android.os.Handler(android.os.Looper.getMainLooper()))
    }
}
"""

EDITS = [
    # ── MainActivity.kt ──
    (MA, "import android.media.AudioFocusRequest\n",
         "import android.media.AudioFocusRequest\nimport android.media.AudioDeviceCallback\nimport android.media.AudioDeviceInfo\n"),
    (MA, "        super.onCreate(savedInstanceState)\n        handleAlarmIntent(intent)\n",
         "        super.onCreate(savedInstanceState)\n        handleAlarmIntent(intent)\n        handleHeadsetIntent(intent)\n"),
    (MA, "        setIntent(intent)\n        handleAlarmIntent(intent)\n",
         "        setIntent(intent)\n        handleAlarmIntent(intent)\n        handleHeadsetIntent(intent)\n"),
    (MA, "        flutterMethodChannel = channel\n",
         "        flutterMethodChannel = channel\n        HeadsetWatch.start(this, channel) // 이어폰·블루투스 연결 알아채기\n"),
    (MA, "                \"vibrate\" -> {\n",
         "                \"showHeadsetAsk\" -> {\n"
         "                    showHeadsetAsk(call.argument<String>(\"title\") ?: \"이어서 들을까요?\",\n"
         "                        call.argument<String>(\"text\") ?: \"\")\n"
         "                    result.success(true)\n"
         "                }\n"
         "                \"cancelHeadsetAsk\" -> {\n"
         "                    cancelHeadsetAsk()\n"
         "                    result.success(true)\n"
         "                }\n"
         "                \"vibrate\" -> {\n"),
    (MA, "    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {\n",
         KT_FUNCS + "    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {\n"),

    # ── player_provider.dart: 신호 받기 ──
    (PP, "import '../services/loudness.dart';\n",
         "import '../services/loudness.dart';\nimport '../services/headset_resume.dart';\n"),
    (PP, "        case 'onAudioFocusLost':\n",
         "        case 'onHeadsetConnected':\n"
         "        case 'onHeadsetResume':\n"
         "          await HeadsetResume.onCall(call.method); // 이어폰 연결하면 이어서 듣기\n"
         "          break;\n"
         "        case 'onAudioFocusLost':\n"),

    # ── main.dart: 시작할 때 준비 ──
    (MN, "import 'services/alarm_service.dart';\n",
         "import 'services/alarm_service.dart';\nimport 'services/headset_resume.dart';\n"),
    (MN, "  SystemChrome.setSystemUIOverlayStyle(\n    SystemUiOverlayStyle(\n",
         "  HeadsetResume.init(playerProvider, radioProvider); // 이어폰 연결하면 이어서 듣기\n\n"
         "  SystemChrome.setSystemUIOverlayStyle(\n    SystemUiOverlayStyle(\n"),

    # ── settings_screen.dart: 도구에 칸 + 고르는 창 ──
    (ST, "import '../services/loudness.dart';\n",
         "import '../services/loudness.dart';\nimport '../services/headset_resume.dart';\n"),
    (ST, "          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone,",
         "          // 이어폰·블루투스 연결하면 이어서 듣기 (끄기 · 알림으로 묻기 · 바로 재생)\n"
         "          ValueListenableBuilder<int>(\n"
         "            valueListenable: HeadsetResume.mode,\n"
         "            builder: (context, m, _) => _buildTile(context,\n"
         "                icon: Icons.headphones_outlined,\n"
         "                title: '이어폰 연결하면 이어서 듣기',\n"
         "                subtitle: HeadsetResume.names[m],\n"
         "                onTap: () => _showHeadsetResumeSheet(context),\n"
         "                primaryColor: primaryColor),\n"
         "          ),\n"
         "          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone,"),
    (ST, "  void _showPlayerStyleDialog(BuildContext context) {\n",
         "  /// 이어폰 연결하면 이어서 듣기: 끄기 · 알림으로 묻기 · 바로 재생\n"
         "  void _showHeadsetResumeSheet(BuildContext context) {\n"
         "    final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n"
         "    const icons = [\n"
         "      Icons.do_not_disturb_on_outlined,\n"
         "      Icons.notifications_none_rounded,\n"
         "      Icons.play_circle_outline_rounded,\n"
         "    ];\n"
         "    showParanSheet(\n"
         "      context,\n"
         "      title: '이어폰 연결하면 이어서 듣기',\n"
         "      builder: (ctx, setSheet) => Column(\n"
         "        crossAxisAlignment: CrossAxisAlignment.start,\n"
         "        children: [\n"
         "          ParanCard(\n"
         "            children: [\n"
         "              for (var i = 0; i < HeadsetResume.names.length; i++)\n"
         "                ParanRow(\n"
         "                  icon: icons[i],\n"
         "                  title: HeadsetResume.names[i],\n"
         "                  selected: HeadsetResume.mode.value == i,\n"
         "                  onTap: () {\n"
         "                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
         "                    HeadsetResume.setMode(i);\n"
         "                    Navigator.pop(ctx);\n"
         "                  },\n"
         "                ),\n"
         "            ],\n"
         "          ),\n"
         "          Padding(\n"
         "            padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),\n"
         "            child: Text(\n"
         "                '듣다가 멈춘 곡·라디오·자연을 아주 작게 시작해서 천천히 키워요.\\n앱을 완전히 끄면 동작하지 않아요.',\n"
         "                style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5, height: 1.5)),\n"
         "          ),\n"
         "        ],\n"
         "      ),\n"
         "    );\n"
         "  }\n\n"
         "  void _showPlayerStyleDialog(BuildContext context) {\n"),
]

texts, crlf = {}, {}
ok, done = True, 0
for path, old, new in EDITS:
    name = os.path.basename(path)
    if path not in texts:
        if not os.path.exists(path):
            print(f"❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)")
            ok = False
            texts[path] = None
            continue
        raw = open(path, "rb").read().decode("utf-8")
        crlf[path] = "\r\n" in raw
        texts[path] = raw.replace("\r\n", "\n")
    t = texts[path]
    if t is None:
        continue
    if new in t:
        print(f"✔ {name} - 이미 적용돼 있어요")
    elif t.count(old) == 1:
        texts[path] = t.replace(old, new)
        print(f"✔ {name}")
        done += 1
    else:
        print(f"❌ {name} - 고칠 곳을 못 찾았어요 ({t.count(old)}곳)")
        ok = False

# MainActivity 맨 끝에 연결 알아채기(HeadsetWatch) 붙이기
if ok and texts.get(MA) is not None:
    if "object HeadsetWatch" in texts[MA]:
        print("✔ MainActivity.kt (연결 알아채기) - 이미 적용돼 있어요")
    else:
        texts[MA] = texts[MA].rstrip("\n") + "\n" + KT_OBJECT
        print("✔ MainActivity.kt (연결 알아채기 추가)")
        done += 1

# 새 파일: lib/services/headset_resume.dart
new_file = False
if ok:
    if os.path.exists(NEW):
        cur = open(NEW, "rb").read().decode("utf-8").replace("\r\n", "\n")
        if cur == NEW_CODE:
            print("✔ headset_resume.dart - 이미 적용돼 있어요")
        else:
            print("❌ headset_resume.dart 가 이미 다른 내용으로 있어요 (지우고 다시 실행해 주세요)")
            ok = False
    else:
        new_file = True

if not ok:
    print("\n❌ 문제가 있어서 아무것도 저장하지 않았어요")
    sys.exit(1)
if done == 0 and not new_file:
    print("\n이미 적용돼 있어요")
    sys.exit(0)
for path, t in texts.items():
    out = t.replace("\n", "\r\n") if crlf[path] else t
    open(path, "wb").write(out.encode("utf-8"))
if new_file:
    use_crlf = crlf.get(PP, False)
    data = NEW_CODE.replace("\n", "\r\n") if use_crlf else NEW_CODE
    open(NEW, "wb").write(data.encode("utf-8"))
    print("✔ headset_resume.dart (새 파일 만듦)")
print("\n✔ 모두 저장했어요")
