# -*- coding: utf-8 -*-
# 말로 틀기 2단계: 구글이 앱 화면으로 보내는 "검색해서 틀어" 신호도 받기
# (apply_voice_search.py 를 먼저 돌린 뒤에)
import os, sys, glob

MANIFEST = os.path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')
PLAYER = os.path.join('lib', 'providers', 'player_provider.dart')
VOICE = os.path.join('lib', 'services', 'voice_search.dart')

KOTLIN_FUNCS = '''    // 말로 틀기: 구글 어시스턴트 "파란소리에서 ○○ 틀어줘" → 앱(다트)에 검색어 전달
    private var pendingVoice: HashMap<String, String>? = null

    private fun handleVoiceSearch(i: android.content.Intent?) {
        if (i == null || i.action != android.provider.MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH) return
        val m = hashMapOf(
            "query" to (i.getStringExtra(android.app.SearchManager.QUERY) ?: ""),
            "artist" to (i.getStringExtra(android.provider.MediaStore.EXTRA_MEDIA_ARTIST) ?: ""),
            "title" to (i.getStringExtra(android.provider.MediaStore.EXTRA_MEDIA_TITLE) ?: ""),
            "album" to (i.getStringExtra(android.provider.MediaStore.EXTRA_MEDIA_ALBUM) ?: ""),
        )
        i.action = android.content.Intent.ACTION_MAIN // 화면을 돌려도 다시 틀지 않게
        pendingVoice = m
        pushPendingVoice(0)
    }

    /// 다트가 준비될 때까지 0.1초마다 다시 (최대 8초)
    private fun pushPendingVoice(tries: Int) {
        val m = pendingVoice ?: return
        if (tries > 80) return
        val retry = { android.os.Handler(mainLooper).postDelayed({ pushPendingVoice(tries + 1) }, 100) }
        val ch = flutterMethodChannel
        if (ch == null) {
            retry()
            return
        }
        ch.invokeMethod("voiceSearch", m, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (pendingVoice === m) pendingVoice = null
            }
            override fun error(code: String, msg: String?, details: Any?) {
                if (pendingVoice === m) pendingVoice = null
            }
            override fun notImplemented() {
                retry() // 다트가 아직 준비 중
            }
        })
    }

    /// 앱(다트)이 화면 없이 살아 있다가'''

KOTLIN_EDITS = [
    ('앱이 켜질 때 말로 틀기 신호 확인',
     "        handleWidgetGo(intent, false)\n",
     "        handleWidgetGo(intent, false)\n        handleVoiceSearch(intent) // 말로 틀기\n", 1),
    ('앱이 켜져 있을 때 말로 틀기 신호 확인',
     "        handleWidgetGo(intent, true)\n",
     "        handleWidgetGo(intent, true)\n        handleVoiceSearch(intent) // 말로 틀기\n", 1),
    ('말로 틀기 신호 받는 곳',
     "    /// 앱(다트)이 화면 없이 살아 있다가", KOTLIN_FUNCS, 1),
]

MANIFEST_EDITS = [
    ('앱 설정에 "검색해서 틀기" 받는다고 적기',
     '                <data android:scheme="file" android:mimeType="audio/*"/>\n            </intent-filter>\n        </activity>',
     '                <data android:scheme="file" android:mimeType="audio/*"/>\n            </intent-filter>\n\n'
     '            <!-- 말로 틀기: "헤이 구글, 파란소리에서 ○○ 틀어줘" -->\n'
     '            <intent-filter>\n'
     '                <action android:name="android.media.action.MEDIA_PLAY_FROM_SEARCH"/>\n'
     '                <category android:name="android.intent.category.DEFAULT"/>\n'
     '            </intent-filter>\n        </activity>', 1),
]

PLAYER_EDITS = [
    ('다트에서 말로 틀기 신호 받기',
     "        case 'onAudioFocusGain':\n",
     "        case 'voiceSearch':\n"
     "          WidgetGo.launched = true; // 말로 틀었으면 인삿말 소리 안 함\n"
     "          final m = Map<String, dynamic>.from(call.arguments as Map);\n"
     "          VoiceSearch.play('${m['query'] ?? ''}', {\n"
     "            'android.intent.extra.artist': m['artist'],\n"
     "            'android.intent.extra.title': m['title'],\n"
     "            'android.intent.extra.album': m['album'],\n"
     "          });\n"
     "          break;\n"
     "        case 'onAudioFocusGain':\n", 1),
]

VOICE_EDITS = [
    ('준비 전에 온 말은 기억해 두기',
     "  static MusicProvider? _music;\n",
     "  static MusicProvider? _music;\n"
     "  static (String, Map<String, dynamic>?)? _pending; // 앱이 막 켜지는 중에 온 말\n", 1),
    ('준비되면 기억해 둔 말 틀기',
     "    _music = music;\n  }\n",
     "    _music = music;\n"
     "    final p = _pending;\n"
     "    _pending = null;\n"
     "    if (p != null) Future.delayed(const Duration(milliseconds: 800), () => play(p.$1, p.$2));\n"
     "  }\n", 1),
    ('준비 전이면 기억만',
     "    if (pp == null || radio == null || music == null) return;\n",
     "    if (pp == null || radio == null || music == null) {\n"
     "      _pending = (query, extras);\n"
     "      return;\n"
     "    }\n", 1),
]


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def edit(path, edits):
    if not os.path.exists(path):
        print('❌ 파일을 못 찾았어요:', path, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    text, crlf = load(path)
    for name, old, new, cnt in edits:
        n = text.count(old)
        if n != cnt:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        print('✔', name)
    return path, text, crlf


def main():
    if not os.path.exists(VOICE):
        print('❌ apply_voice_search.py 를 먼저 돌려 주세요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    kts = glob.glob(os.path.join('android', 'app', 'src', 'main', '**', 'MainActivity.kt'), recursive=True)
    if len(kts) != 1:
        print('❌ MainActivity.kt 를 못 찾았어요 (찾은 개수: %d) — 아무것도 저장 안 했어요' % len(kts))
        sys.exit(1)
    if 'handleVoiceSearch' in load(kts[0])[0]:
        print('이미 적용돼 있어요')
        return
    out = [
        edit(kts[0], KOTLIN_EDITS),
        edit(MANIFEST, MANIFEST_EDITS),
        edit(PLAYER, PLAYER_EDITS),
        edit(VOICE, VOICE_EDITS),
    ]
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('✔ 저장했어요 (4개 파일)')


main()
