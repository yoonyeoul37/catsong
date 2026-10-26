# -*- coding: utf-8 -*-
# 다른 앱에서 "파란소리로 열기" → 바로 재생 화면 + 그 노래 재생
import os, sys

def find(name, base):
    for r, _, fs in os.walk(base):
        if name in fs and 'build' not in r.split(os.sep):
            return os.path.join(r, name)
    return None

KT = find('MainActivity.kt', 'android')
PP = find('player_provider.dart', 'lib')
MAIN = os.path.join('lib', 'main.dart')
NEW = os.path.join('lib', 'services', 'open_audio.dart')
for n, p in [('MainActivity.kt', KT), ('player_provider.dart', PP), ('main.dart', MAIN if os.path.exists(MAIN) else None)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)
if not os.path.isdir(os.path.join('lib', 'services')):
    print('❌ lib/services 폴더를 못 찾았어요'); sys.exit(1)

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

kt, KNL = load(KT)
pp, PNL = load(PP)
mn, MNL = load(MAIN)
if 'prepareOpenAudio' in kt or os.path.exists(NEW):
    print('이미 적용돼 있어요'); sys.exit(0)

# ───────── MainActivity.kt ─────────
kt_steps = [
 ('[MainActivity] 넘겨받은 노래 주소 기억할 칸',
  "    private var pendingWidgetGo: String? = null // 홈 위젯 바로가기로 켜졌으면 어느 화면인지\n",
  "    private var pendingWidgetGo: String? = null // 홈 위젯 바로가기로 켜졌으면 어느 화면인지\n"
  "    private var pendingOpenAudio: String? = null // 다른 앱에서 '파란소리로 열기'로 넘겨받은 노래 주소\n"),
 ('[MainActivity] 꺼져 있다 켜질 때 노래 주소 받기',
  "            intent.removeExtra(\"widgetGo\")\n"
  "        }\n"
  "        super.onCreate(savedInstanceState)\n",
  "            intent.removeExtra(\"widgetGo\")\n"
  "        }\n"
  "        takeOpenAudio(intent) // 다른 앱에서 연 노래 (플러터가 주소를 화면 이름으로 착각하지 않게 먼저 빼 둠)\n"
  "        super.onCreate(savedInstanceState)\n"),
 ('[MainActivity] 켜질 때 앱에 알리기',
  "        pushPendingWidgetGo(0)\n"
  "        activityAlive = true\n",
  "        pushPendingWidgetGo(0)\n"
  "        pushPendingOpenAudio(0)\n"
  "        activityAlive = true\n"),
 ('[MainActivity] 켜져 있을 때 노래 주소 받기',
  "        super.onNewIntent(intent)\n"
  "        setIntent(intent)\n",
  "        takeOpenAudio(intent) // 다른 앱에서 연 노래\n"
  "        super.onNewIntent(intent)\n"
  "        setIntent(intent)\n"),
 ('[MainActivity] 켜져 있을 때 앱에 알리기',
  "        handleWidgetGo(intent, true)\n"
  "    }\n",
  "        handleWidgetGo(intent, true)\n"
  "        pushPendingOpenAudio(0)\n"
  "    }\n"),
 ('[MainActivity] 노래 주소 받기 · 앱에 알리기 · 복사해 두기',
  "    /// 홈 위젯 바로가기 (음악·라디오·자연·수면)\n",
  "    /// 다른 앱에서 '파란소리로 열기' (content:// · file:// 음악 파일) → 주소만 기억하고 인텐트에서 빼기\n"
  "    private fun takeOpenAudio(i: android.content.Intent?) {\n"
  "        if (i == null || i.action != android.content.Intent.ACTION_VIEW) return\n"
  "        val u = i.data ?: return\n"
  "        if (u.scheme != \"content\" && u.scheme != \"file\") return\n"
  "        pendingOpenAudio = u.toString()\n"
  "        i.action = android.content.Intent.ACTION_MAIN // 화면을 다시 그릴 때 또 열지 않게\n"
  "        i.data = null\n"
  "    }\n"
  "\n"
  "    /// 앱(다트)에 '이 노래 틀어 줘' (다트가 아직 준비 전이면 0.1초마다 다시 · 4초까지)\n"
  "    private fun pushPendingOpenAudio(tries: Int) {\n"
  "        val u = pendingOpenAudio ?: return\n"
  "        if (tries > 40) return\n"
  "        val retry = { android.os.Handler(mainLooper).postDelayed({ pushPendingOpenAudio(tries + 1) }, 100) }\n"
  "        val ch = flutterMethodChannel\n"
  "        if (ch == null) {\n"
  "            retry()\n"
  "            return\n"
  "        }\n"
  "        ch.invokeMethod(\"openAudio\", u, object : MethodChannel.Result {\n"
  "            override fun success(result: Any?) {\n"
  "                if (pendingOpenAudio == u) pendingOpenAudio = null\n"
  "            }\n"
  "            override fun error(code: String, msg: String?, details: Any?) {}\n"
  "            override fun notImplemented() {\n"
  "                retry() // 다트가 아직 준비 중\n"
  "            }\n"
  "        })\n"
  "    }\n"
  "\n"
  "    /// 넘겨받은 노래: 내 음악에 같은 파일이 있으면 그 곡 번호 · 그리고 앱 안에 잠깐 복사 (넘겨준 앱의 허락이 곧 끝나서)\n"
  "    @Suppress(\"DEPRECATION\")\n"
  "    private fun prepareOpenAudio(u: android.net.Uri): HashMap<String, Any?>? {\n"
  "        return try {\n"
  "            var name: String? = null\n"
  "            var size = -1L\n"
  "            if (u.scheme == \"content\") {\n"
  "                contentResolver.query(u, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME, android.provider.OpenableColumns.SIZE), null, null, null)?.use { c ->\n"
  "                    if (c.moveToFirst()) {\n"
  "                        name = c.getString(0)\n"
  "                        if (!c.isNull(1)) size = c.getLong(1)\n"
  "                    }\n"
  "                }\n"
  "            }\n"
  "            if (name.isNullOrBlank()) name = u.lastPathSegment?.substringAfterLast('/')\n"
  "            val out = HashMap<String, Any?>()\n"
  "            val n = name\n"
  "            if (!n.isNullOrBlank()) {\n"
  "                out[\"name\"] = n\n"
  "                var sel = \"${MediaStore.Audio.Media.DISPLAY_NAME}=?\"\n"
  "                val args = mutableListOf(n)\n"
  "                if (size > 0) {\n"
  "                    sel += \" AND ${MediaStore.Audio.Media.SIZE}=?\"\n"
  "                    args.add(size.toString())\n"
  "                }\n"
  "                try {\n"
  "                    contentResolver.query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,\n"
  "                        arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DATA), sel, args.toTypedArray(), null)?.use { c ->\n"
  "                        if (c.moveToFirst()) {\n"
  "                            out[\"libId\"] = c.getLong(0)\n"
  "                            out[\"libPath\"] = c.getString(1)\n"
  "                        }\n"
  "                    }\n"
  "                } catch (_: Exception) {}\n"
  "            }\n"
  "            val dir = File(cacheDir, \"opened_audio\")\n"
  "            dir.mkdirs()\n"
  "            dir.listFiles()?.forEach { it.delete() } // 지난번에 연 노래는 지우기\n"
  "            val safe = (n ?: \"audio.mp3\").replace(Regex(\"[\\\\\\\\/:*?\\\"<>|]\"), \"_\")\n"
  "            val f = File(dir, \"${System.currentTimeMillis()}_$safe\")\n"
  "            val input = contentResolver.openInputStream(u) ?: return null\n"
  "            input.use { inp -> f.outputStream().use { inp.copyTo(it) } }\n"
  "            out[\"path\"] = f.absolutePath\n"
  "            val r = MediaMetadataRetriever()\n"
  "            try {\n"
  "                r.setDataSource(f.absolutePath)\n"
  "                out[\"title\"] = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)\n"
  "                out[\"artist\"] = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)\n"
  "                out[\"album\"] = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)\n"
  "                out[\"duration\"] = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()\n"
  "                out[\"art\"] = r.embeddedPicture\n"
  "            } catch (_: Exception) {\n"
  "            } finally {\n"
  "                try { r.release() } catch (_: Exception) {}\n"
  "            }\n"
  "            out\n"
  "        } catch (e: Exception) {\n"
  "            null\n"
  "        }\n"
  "    }\n"
  "\n"
  "    /// 홈 위젯 바로가기 (음악·라디오·자연·수면)\n"),
 ('[MainActivity] 앱이 복사를 부탁하는 통로',
  "                \"vibrate\" -> {\n",
  "                \"prepareOpenAudio\" -> {\n"
  "                    val s = call.argument<String>(\"uri\")\n"
  "                    if (s == null) {\n"
  "                        result.success(null)\n"
  "                    } else {\n"
  "                        Thread {\n"
  "                            val out = prepareOpenAudio(android.net.Uri.parse(s))\n"
  "                            runOnUiThread { result.success(out) }\n"
  "                        }.start()\n"
  "                    }\n"
  "                }\n"
  "                \"vibrate\" -> {\n"),
]

pp_steps = [
 ('[player_provider] open_audio 불러오기',
  "import '../services/car_browse.dart';\n",
  "import '../services/car_browse.dart';\n"
  "import '../services/open_audio.dart';\n"),
 ('[player_provider] 다른 앱에서 연 노래 신호 받기',
  "        case 'widgetGo':\n",
  "        case 'openAudio':\n"
  "          OpenAudio.request(call.arguments as String); // 다른 앱에서 '파란소리로 열기'\n"
  "          break;\n"
  "        case 'widgetGo':\n"),
]

mn_steps = [
 ('[main] open_audio 불러오기',
  "import 'services/car_browse.dart';\n",
  "import 'services/car_browse.dart';\n"
  "import 'services/open_audio.dart';\n"),
 ('[main] 잠깐 연 노래는 최근 목록에 안 남기기',
  "  playerProvider.onSongPlayed = (song) {\n",
  "  playerProvider.onSongPlayed = (song) {\n"
  "    if (OpenAudio.isTemp(song)) return; // 다른 앱에서 잠깐 연 노래(복사본)는 최근에 안 남김\n"),
 ('[main] 다른 앱에서 연 노래 준비',
  "  CarBrowse.init(playerProvider, radioProvider, musicProvider); // 안드로이드 오토 (차 화면)\n",
  "  CarBrowse.init(playerProvider, radioProvider, musicProvider); // 안드로이드 오토 (차 화면)\n"
  "  OpenAudio.init(playerProvider, musicProvider); // 다른 앱에서 '파란소리로 열기' → 바로 재생\n"),
 ('[main] 노래로 켜졌으면 첫인사 없이',
  "  bool _showIntro = !AlarmService.launchedByAlarm && WidgetGo.target.value == null;\n",
  "  bool _showIntro = !AlarmService.launchedByAlarm && WidgetGo.target.value == null && OpenAudio.target.value == null;\n"),
 ('[main] 첫인사 멜로디도 안 함',
  "    if (WidgetGo.launched || WidgetGo.target.value != null) return; // 위젯으로 켜졌으면 인삿말 없이\n",
  "    if (WidgetGo.launched || WidgetGo.target.value != null) return; // 위젯으로 켜졌으면 인삿말 없이\n"
  "    if (OpenAudio.target.value != null) return; // 다른 앱에서 노래를 열었으면 인삿말 없이\n"),
 ('[main] 첫인사 중에 노래가 오면 첫인사 끄기 (함수)',
  "  /// 첫인사 멈추고 재생기 정리\n",
  "  /// 첫인사 중에 다른 앱에서 노래가 넘어오면 → 첫인사를 바로 끄고 재생 화면으로\n"
  "  void _onOpenAudioIntro() {\n"
  "    if (OpenAudio.target.value == null || !mounted) return;\n"
  "    _stopWelcome();\n"
  "    if (_showIntro) setState(() => _showIntro = false);\n"
  "  }\n"
  "\n"
  "  /// 첫인사 멈추고 재생기 정리\n"),
 ('[main] 첫인사 중에 노래가 오면 첫인사 끄기 (연결)',
  "    WidgetGo.target.addListener(_onWidgetGoIntro); // 첫인사 중에 위젯 바로가기 → 첫인사 끄기\n",
  "    WidgetGo.target.addListener(_onWidgetGoIntro); // 첫인사 중에 위젯 바로가기 → 첫인사 끄기\n"
  "    OpenAudio.target.addListener(_onOpenAudioIntro); // 첫인사 중에 다른 앱에서 노래 → 첫인사 끄기\n"),
 ('[main] 화면 닫을 때 연결 풀기',
  "    WidgetGo.target.removeListener(_onWidgetGoIntro);\n",
  "    WidgetGo.target.removeListener(_onWidgetGoIntro);\n"
  "    OpenAudio.target.removeListener(_onOpenAudioIntro);\n"),
]

NEW_CODE = r'''import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import 'alarm_service.dart';

/// 다른 앱(DownKit · 파일 앱 · 카톡 등)에서 "파란소리로 열기" → 바로 재생 화면 + 그 노래
/// - 앱이 꺼져 있어도, 켜져 있어도 (안드로이드 쪽 MainActivity가 'openAudio'로 주소를 보내 줌)
/// - 내 음악에 같은 파일이 있으면 그 곡으로, 없으면 앱 안에 잠깐 복사한 파일로 틀기
class OpenAudio {
  static const _ch = MethodChannel('kr.ssing.catsong/media');
  static const _route = '/open_audio_player';

  /// 넘겨받은 노래 주소 (첫인사 끄기 · 인삿말 안 하기에 씀)
  static final ValueNotifier<String?> target = ValueNotifier<String?>(null);

  static PlayerProvider? _pp;
  static MusicProvider? _music;
  static String? _last;
  static DateTime _lastAt = DateTime(2000);

  static void init(PlayerProvider pp, MusicProvider music) {
    _pp = pp;
    _music = music;
    final t = target.value;
    if (t != null) _run(t); // 준비 전에 먼저 온 노래
  }

  /// 앱 안에 잠깐 복사한 노래인지 (최근에 들었어요 · 재생 기록에 안 남기기)
  static bool isTemp(Song s) => (s.uri ?? '').contains('/opened_audio/');

  static void request(String uri) {
    // 같은 주소가 두 번 오면 한 번만 (켜질 때 두 길로 올 수 있어서)
    if (uri == _last && DateTime.now().difference(_lastAt) < const Duration(seconds: 3)) return;
    _last = uri;
    _lastAt = DateTime.now();
    target.value = uri;
    if (_pp != null) _run(uri);
  }

  static Future<void> _run(String uri) async {
    final pp = _pp, music = _music;
    if (pp == null || music == null) return;
    try {
      final m = await _ch.invokeMethod('prepareOpenAudio', {'uri': uri});
      if (m is! Map || uri != target.value) return; // 못 받았거나 그사이 다른 노래를 열었으면 그만
      Song? song;
      final libId = m['libId'];
      final libPath = m['libPath'];
      if (libId != null || libPath != null) {
        // 내 음악에 같은 파일이 있으면 그 곡 (즐겨찾기 · 가사가 그대로 이어짐)
        if (music.allSongs.isEmpty) {
          if (!music.isLoading) music.initialize();
          for (var k = 0; k < 20 && music.allSongs.isEmpty; k++) {
            await Future.delayed(const Duration(milliseconds: 250)); // 5초까지
          }
        }
        for (final s in music.allSongs) {
          if ((libId != null && s.id == libId) || (libPath != null && s.uri == libPath)) {
            song = s;
            break;
          }
        }
      }
      final path = m['path'] as String?;
      if (song == null && path != null) {
        final name = (m['name'] as String?) ?? '';
        final t = (m['title'] as String?)?.trim() ?? '';
        final art = m['art'];
        song = Song(
          id: -(path.hashCode.abs() + 1),
          title: t.isNotEmpty ? t : _noExt(name),
          artist: (m['artist'] as String?) ?? '',
          album: (m['album'] as String?) ?? '',
          uri: path,
          duration: int.tryParse('${m['duration'] ?? ''}') ?? 0,
          albumArt: art is Uint8List && art.isNotEmpty ? art.toList() : null,
        );
      }
      if (song == null || uri != target.value) return;
      await pp.playFromList([song], 0);
      _showPlayer();
    } catch (e) {
      debugPrint('다른 앱에서 연 노래 재생 오류: $e');
    }
  }

  static String _noExt(String n) {
    final i = n.lastIndexOf('.');
    return i > 0 ? n.substring(0, i) : n;
  }

  /// 음악 재생 화면 열기 (미니플레이어를 눌렀을 때와 같은 모양) · 앱 화면이 준비될 때까지 잠깐 기다림
  static void _showPlayer([int tries = 0]) {
    final nav = AlarmService.navKey.currentState;
    if (nav == null) {
      if (tries < 40) Future.delayed(const Duration(milliseconds: 150), () => _showPlayer(tries + 1));
      return;
    }
    nav.popUntil((r) => r.settings.name != _route); // 이미 이걸로 연 재생 화면이 있으면 닫고 새로
    nav.push(PageRouteBuilder(
      settings: const RouteSettings(name: _route),
      pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }
}
'''

def apply(s, nl, steps):
    ok = True
    for name, old, new in steps:
        o = old.replace('\n', nl); n = new.replace('\n', nl)
        c = s.count(o)
        if c == 1:
            s = s.replace(o, n); print('✔', name)
        else:
            ok = False; print('❌', name, '(찾은 개수: %d)' % c)
    return s, ok

kt, ok1 = apply(kt, KNL, kt_steps)
pp, ok2 = apply(pp, PNL, pp_steps)
mn, ok3 = apply(mn, MNL, mn_steps)
if not (ok1 and ok2 and ok3):
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(KT, 'wb').write(kt.encode('utf-8'))
open(PP, 'wb').write(pp.encode('utf-8'))
open(MAIN, 'wb').write(mn.encode('utf-8'))
open(NEW, 'wb').write(NEW_CODE.replace('\n', MNL).encode('utf-8'))
print('✔ 새 파일 만들었어요:', NEW)
print('저장했어요')
