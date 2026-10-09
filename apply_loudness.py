# -*- coding: utf-8 -*-
# 곡마다 소리 크기 맞추기 (볼륨 평준화)
# - 곡을 처음 틀 때 가운데 몇 군데를 잠깐 들어 보고 소리 크기를 재서 폰에 기억 (한 곡에 한 번만)
# - 다음 곡도 미리 재 둠 → 곡이 바뀔 때 바로 맞춰짐
# - 큰 곡만 조금 줄여서 비슷하게 (작은 곡은 키우지 않음: 소리가 찢어질 수 있어서)
# - 설정 → 도구 → "곡마다 소리 크기 맞추기" 켜기·끄기 (기본 켜짐)
# - 알람이 울릴 때 · 수면 타이머로 줄이는 중엔 그쪽 크기가 먼저
# - 새 파일 lib/services/loudness.dart 는 이 스크립트가 직접 만들어요
import os, sys, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')
PROV = os.path.join(LIB, 'providers', 'player_provider.dart')
RING = os.path.join(LIB, 'screens', 'alarm_ring_screen.dart')
SETTINGS = os.path.join(LIB, 'screens', 'settings_screen.dart')
NEW_FILE = os.path.join(LIB, 'services', 'loudness.dart')

LOUDNESS = "import 'dart:async';\nimport 'dart:convert';\nimport 'dart:math' as math;\nimport 'package:flutter/foundation.dart';\nimport 'package:flutter/services.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n\n/// 곡마다 소리 크기 맞추기 (볼륨 평준화)\n/// 곡 가운데 몇 군데를 잠깐 들어 보고 소리 크기(dB)를 재서 폰에 기억\n/// → 큰 곡만 조금 줄여서 다른 곡들과 비슷하게 (작은 곡은 키우지 않음: 소리가 찢어질 수 있어서)\nclass Loudness {\n  static const _ch = MethodChannel('kr.ssing.catsong/media');\n  static const _keyOn = 'loudnessOn';\n  static const _keyDb = 'loudnessDb';\n\n  /// 맞출 크기 (이보다 큰 곡만 줄임)\n  static const target = -14.0;\n\n  /// 아무리 커도 이 정도까지만 줄임\n  static const minGain = 0.45;\n\n  /// 설정 → 곡마다 소리 크기 맞추기 (기본 켜짐)\n  static final ValueNotifier<bool> enabled = ValueNotifier(true);\n\n  static final Map<String, double> _db = {};\n  static final Set<String> _busy = {};\n  static bool _loaded = false;\n  static Timer? _saveTimer;\n\n  static Future<void> load() async {\n    if (_loaded) return;\n    _loaded = true;\n    try {\n      final p = await SharedPreferences.getInstance();\n      enabled.value = p.getBool(_keyOn) ?? true;\n      final s = p.getString(_keyDb);\n      if (s != null) {\n        (jsonDecode(s) as Map).forEach((k, v) {\n          if (v is num) _db[k.toString()] = v.toDouble();\n        });\n      }\n    } catch (_) {}\n  }\n\n  static Future<void> setEnabled(bool v) async {\n    enabled.value = v;\n    final p = await SharedPreferences.getInstance();\n    await p.setBool(_keyOn, v);\n  }\n\n  /// 전에 잰 크기 (없으면 null)\n  static double? cached(String uri) => _db[uri];\n\n  /// 곡 크기 → 소리 비율 (큰 곡만 줄임, 0.45 ~ 1.0)\n  static double gainFor(double db) {\n    final diff = target - db;\n    if (diff >= 0) return 1.0;\n    return math.pow(10, diff / 20).toDouble().clamp(minGain, 1.0);\n  }\n\n  /// 소리 크기 재기 (한 곡에 한 번만, 결과는 폰에 기억)\n  static Future<double?> measure(String uri) async {\n    final c = _db[uri];\n    if (c != null) return c;\n    if (!_busy.add(uri)) return null; // 이미 재는 중\n    try {\n      final r = await _ch.invokeMethod('measureLoudness', {'path': uri});\n      if (r is num && r.isFinite && r > -80) {\n        _db[uri] = r.toDouble();\n        _scheduleSave();\n        return r.toDouble();\n      }\n    } catch (_) {\n    } finally {\n      _busy.remove(uri);\n    }\n    return null;\n  }\n\n  /// 여러 곡을 연달아 재도 저장은 한 번에\n  static void _scheduleSave() {\n    _saveTimer?.cancel();\n    _saveTimer = Timer(const Duration(seconds: 3), () async {\n      try {\n        final p = await SharedPreferences.getInstance();\n        await p.setString(_keyDb, jsonEncode(_db));\n      } catch (_) {}\n    });\n  }\n}\n"
KT_MEASURE = '    /// 곡마다 소리 크기 맞추기: 곡 가운데 몇 군데(각 8초)를 풀어서 평균 소리 크기(dB) 재기\n    /// 결과: -60 ~ 0 쯤 (클수록 큰 곡), 못 재면 null\n    private fun measureLoudness(path: String): Double? {\n        val ex = android.media.MediaExtractor()\n        var codec: android.media.MediaCodec? = null\n        try {\n            if (path.startsWith("content://")) {\n                ex.setDataSource(this, android.net.Uri.parse(path), null)\n            } else {\n                ex.setDataSource(path)\n            }\n            var track = -1\n            var fmt: android.media.MediaFormat? = null\n            for (i in 0 until ex.trackCount) {\n                val f = ex.getTrackFormat(i)\n                if ((f.getString(android.media.MediaFormat.KEY_MIME) ?: "").startsWith("audio/")) {\n                    track = i\n                    fmt = f\n                    break\n                }\n            }\n            if (track < 0 || fmt == null) return null\n            ex.selectTrack(track)\n            val durUs = if (fmt.containsKey(android.media.MediaFormat.KEY_DURATION))\n                fmt.getLong(android.media.MediaFormat.KEY_DURATION) else 0L\n            val c = android.media.MediaCodec.createDecoderByType(fmt.getString(android.media.MediaFormat.KEY_MIME)!!)\n            codec = c\n            c.configure(fmt, null, null, 0)\n            c.start()\n            var sumSq = 0.0\n            var count = 0L\n            // 1분 넘는 곡은 25% · 50% · 75% 지점, 짧은 곡은 처음부터\n            val starts = if (durUs > 60_000_000L) listOf(durUs / 4, durUs / 2, durUs * 3 / 4) else listOf(0L)\n            val segUs = 8_000_000L\n            val info = android.media.MediaCodec.BufferInfo()\n            for (s in starts) {\n                ex.seekTo(s, android.media.MediaExtractor.SEEK_TO_CLOSEST_SYNC)\n                c.flush()\n                val endUs = s + segUs\n                var inputDone = false\n                var outDone = false\n                var guard = 0\n                while (!outDone && guard++ < 4000) {\n                    if (!inputDone) {\n                        val ii = c.dequeueInputBuffer(10_000)\n                        if (ii >= 0) {\n                            val buf = c.getInputBuffer(ii)!!\n                            val n = ex.readSampleData(buf, 0)\n                            val t = ex.sampleTime\n                            if (n < 0 || t > endUs) {\n                                c.queueInputBuffer(ii, 0, 0, 0, android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM)\n                                inputDone = true\n                            } else {\n                                c.queueInputBuffer(ii, 0, n, t, 0)\n                                ex.advance()\n                            }\n                        }\n                    }\n                    val oi = c.dequeueOutputBuffer(info, 10_000)\n                    if (oi >= 0) {\n                        if (info.size > 0) {\n                            val ob = c.getOutputBuffer(oi)!!\n                            ob.position(info.offset)\n                            ob.limit(info.offset + info.size)\n                            val sb = ob.order(java.nio.ByteOrder.LITTLE_ENDIAN).asShortBuffer()\n                            while (sb.hasRemaining()) {\n                                val v = sb.get() / 32768.0\n                                sumSq += v * v\n                                count++\n                            }\n                        }\n                        c.releaseOutputBuffer(oi, false)\n                        if ((info.flags and android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) outDone = true\n                    }\n                }\n            }\n            if (count == 0L) return null\n            val rms = Math.sqrt(sumSq / count)\n            if (rms <= 0.0) return null\n            return 20 * Math.log10(rms)\n        } catch (e: Exception) {\n            android.util.Log.e("Loudness", "소리 크기 못 잼: ${e.message}")\n            return null\n        } finally {\n            try {\n                codec?.stop()\n                codec?.release()\n            } catch (_: Exception) {}\n            ex.release()\n        }\n    }\n\n    private fun getAlbumArt(path: String): ByteArray? {\n'

PROV_EDITS = [
    ('음악: 소리 크기 맞추기 불러오기',
     "import '../services/cast_service.dart';\n",
     "import '../services/cast_service.dart';\n"
     "import '../services/loudness.dart';\n"),
    ('음악: 켤 때 기억해둔 크기 불러오기 · 설정 바꾸면 바로',
     "    CastService.instance.onTrackEnded = () => playNext();\n"
     "  }\n",
     "    CastService.instance.onTrackEnded = () => playNext();\n"
     "    Loudness.load(); // 곡마다 소리 크기 (기억해둔 것)\n"
     "    Loudness.enabled.addListener(() {\n"
     "      final s = currentSong;\n"
     "      if (s != null) _applyLoudness(s);\n"
     "    });\n"
     "  }\n"
     "\n"
     "  // ───── 곡마다 소리 크기 맞추기 ─────\n"
     "  double _normGain = 1.0; // 이 곡을 얼마나 줄일지 (1.0 = 그대로)\n"
     "  double get normGain => _normGain;\n"
     "\n"
     "  /// 알람이 소리 크기를 쥐고 있는 동안 true (그동안 맞추기 안 함)\n"
     "  bool volumeLocked = false;\n"
     "\n"
     "  void _setNorm(double g) {\n"
     "    _normGain = g;\n"
     "    if (!volumeLocked && _sleepFade == null) _player.setVolume(g);\n"
     "  }\n"
     "\n"
     "  /// 잰 적 있으면 바로 맞추고, 없으면 재서 곡 앞부분일 때 맞추기 + 다음 곡 미리 재기\n"
     "  void _applyLoudness(Song song) {\n"
     "    final uri = song.uri;\n"
     "    if (uri == null) return;\n"
     "    if (!Loudness.enabled.value) {\n"
     "      _setNorm(1.0);\n"
     "      return;\n"
     "    }\n"
     "    final db = Loudness.cached(uri);\n"
     "    if (db != null) {\n"
     "      _setNorm(Loudness.gainFor(db));\n"
     "    } else {\n"
     "      _setNorm(1.0);\n"
     "      Loudness.measure(uri).then((d) {\n"
     "        if (d == null || currentSong?.uri != uri) return;\n"
     "        // 곡 중간에 갑자기 바뀌면 어색해서, 앞부분일 때만 (다음부터는 처음부터 맞춰짐)\n"
     "        if (_player.position < const Duration(seconds: 4)) _setNorm(Loudness.gainFor(d));\n"
     "      });\n"
     "    }\n"
     "    if (hasNext) {\n"
     "      final next = _queue[_currentIndex + 1].uri;\n"
     "      if (next != null) Loudness.measure(next);\n"
     "    }\n"
     "  }\n"),
    ('음악: 곡을 틀 때 크기 맞추기',
     "      // 자연소리가 남긴 \"무한반복\" 설정을 꺼준다 (반복은 앱이 직접 처리함)\n"
     "      await _player.setLoopMode(LoopMode.off);\n",
     "      // 자연소리가 남긴 \"무한반복\" 설정을 꺼준다 (반복은 앱이 직접 처리함)\n"
     "      await _player.setLoopMode(LoopMode.off);\n"
     "      _applyLoudness(song); // 곡마다 소리 크기 맞추기\n"),
    ('자연: 소리 크기는 그대로',
     "      await _player.setLoopMode(LoopMode.one);\n"
     "      await _player.play();\n",
     "      await _player.setLoopMode(LoopMode.one);\n"
     "      _setNorm(1.0); // 자연은 크기 맞추기 안 함\n"
     "      await _player.play();\n"),
    ('수면 타이머: 맞춘 크기에서 줄이기',
     "      _player.setVolume(left.clamp(0.0, 1.0));\n",
     "      _player.setVolume(left.clamp(0.0, 1.0) * _normGain);\n"),
    ('수면 타이머: 끝나면 맞춘 크기로',
     "    _sleepFade!.cancel();\n"
     "    _sleepFade = null;\n"
     "    _player.setVolume(1.0);\n",
     "    _sleepFade!.cancel();\n"
     "    _sleepFade = null;\n"
     "    _player.setVolume(_normGain);\n"),
]

RING_EDITS = [
    ('알람: 울리는 동안 크기 맞추기 잠시 멈춤',
     "    final player = context.read<PlayerProvider>();\n"
     "    final radio = context.read<RadioProvider>();\n"
     "    // 저절로 다시 울리는 거면 처음부터 조금 더 크게\n",
     "    final player = context.read<PlayerProvider>();\n"
     "    final radio = context.read<RadioProvider>();\n"
     "    player.volumeLocked = true; // 울리는 동안은 알람이 소리 크기를 정함\n"
     "    // 저절로 다시 울리는 거면 처음부터 조금 더 크게\n"),
    ('알람: 끝나면 맞춘 크기로',
     "    try {\n"
     "      await context.read<PlayerProvider>().player.setVolume(1.0);\n"
     "      await context.read<RadioProvider>().setAlarmVolume(1.0);\n"
     "    } catch (_) {}\n",
     "    try {\n"
     "      final pp = context.read<PlayerProvider>();\n"
     "      pp.volumeLocked = false;\n"
     "      await pp.player.setVolume(pp.normGain); // 곡마다 소리 크기 맞춘 크기로\n"
     "      await context.read<RadioProvider>().setAlarmVolume(1.0);\n"
     "    } catch (_) {}\n"),
]

SETTINGS_EDITS = [
    ('설정: 불러오기',
     "import 'settings_help_screen.dart';\n",
     "import 'settings_help_screen.dart';\n"
     "import '../services/loudness.dart';\n"),
    ('설정: 도구 → 곡마다 소리 크기 맞추기',
     "          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone,",
     "          // 곡마다 소리 크기 맞추기 (큰 곡만 조금 줄여서 비슷하게)\n"
     "          ValueListenableBuilder<bool>(\n"
     "            valueListenable: Loudness.enabled,\n"
     "            builder: (context, on, _) => _buildTile(context,\n"
     "                icon: Icons.graphic_eq_rounded,\n"
     "                title: '곡마다 소리 크기 맞추기',\n"
     "                onTap: () => Loudness.setEnabled(!on),\n"
     "                primaryColor: primaryColor,\n"
     "                trailing: Switch(value: on, onChanged: (v) => Loudness.setEnabled(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),\n"
     "          ),\n"
     "          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone,"),
]

KT_EDITS = [
    ('MainActivity: 소리 크기 재는 일꾼',
     "    private val metaExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()\n",
     "    private val metaExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()\n"
     "    // 곡마다 소리 크기 재기는 따로 (재는 동안 앨범 사진 불러오기가 안 막히게)\n"
     "    private val loudExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()\n"),
    ('MainActivity: 소리 크기 재기 통로',
     "                \"getVideoList\" -> {\n",
     "                \"measureLoudness\" -> {\n"
     "                    // 곡마다 소리 크기 맞추기: 곡 가운데 몇 군데를 잠깐 풀어서 평균 소리 크기(dB)\n"
     "                    val path = call.argument<String>(\"path\")\n"
     "                    if (path == null) {\n"
     "                        result.success(null)\n"
     "                    } else {\n"
     "                        loudExecutor.execute {\n"
     "                            val db = measureLoudness(path)\n"
     "                            runOnUiThread { result.success(db) }\n"
     "                        }\n"
     "                    }\n"
     "                }\n"
     "                \"getVideoList\" -> {\n"),
    ('MainActivity: 소리 크기 재기',
     "    private fun getAlbumArt(path: String): ByteArray? {\n",
     KT_MEASURE),
]

MARK = 'measureLoudness'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    hits = glob.glob(os.path.join(ROOT, 'android', 'app', 'src', 'main', 'kotlin', '**', 'MainActivity.kt'),
                     recursive=True)
    if len(hits) != 1:
        print('❌ MainActivity.kt 를 못 찾았어요 (android/app/src/main/kotlin 안)')
        sys.exit(1)
    act = hits[0]
    for p in (PROV, RING, SETTINGS):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(act, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    if os.path.exists(NEW_FILE):
        print('❌ 이미 같은 이름 파일이 있어요: lib/services/loudness.dart')
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    out = []
    ok = True
    for path, edits in ((PROV, PROV_EDITS), (RING, RING_EDITS), (SETTINGS, SETTINGS_EDITS), (act, KT_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not balanced(LOUDNESS):
        print('❌ 괄호가 안 맞아요: loudness.dart')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    open(NEW_FILE, 'wb').write(LOUDNESS.encode('utf-8'))
    print('✔ 새 파일: lib/services/loudness.dart')
    print('\n다 바꿨어요. 앱을 완전히 끄고 flutter run 으로 다시 켜 주세요 (안드로이드 쪽도 바뀌어서).')


if __name__ == '__main__':
    main()
