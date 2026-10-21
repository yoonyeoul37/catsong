# -*- coding: utf-8 -*-
# 말로 틀기 되돌리기: 넣었던 코드를 다 빼고, voice_search.dart 는 '파란소리 자료'로 옮겨 보관
import os, sys, glob, shutil

MANIFEST = os.path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')
PLAYER = os.path.join('lib', 'providers', 'player_provider.dart')
MAIN = os.path.join('lib', 'main.dart')
VOICE = os.path.join('lib', 'services', 'voice_search.dart')
KEEP_DIR = os.path.join('..', '파란소리 자료', '말로 틀기 코드')

# (이름, 지금 있는 글, 되돌릴 글, 개수)
PLAYER_EDITS = [
    ('불러오기 줄 빼기',
     "import '../services/headset_resume.dart';\nimport '../services/voice_search.dart';\n",
     "import '../services/headset_resume.dart';\n", 1),
    ('처음 알리기 빼기',
     "  // 구글 어시스턴트가 '검색해서 틀기'를 보낼 수 있다고 알려 두기\n"
     "  static const _voiceActions = {MediaAction.playFromSearch};\n\n"
     "  SimpleAudioHandler(this._provider) : _player = _provider.player {\n"
     "    playbackState.add(playbackState.value.copyWith(systemActions: _voiceActions)); // 앱이 막 켜졌을 때도\n",
     "  SimpleAudioHandler(this._provider) : _player = _provider.player {\n", 1),
    ('재생 상태 알리기 빼기',
     "      systemActions: _voiceActions,\n", "", 3),
    ('구글 글자 받는 곳 빼기',
     "  // 말로 틀기: \"헤이 구글, 파란소리에서 ○○ 틀어줘\" → 구글이 보낸 글자로 찾아서 틀기\n"
     "  @override\n"
     "  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) =>\n"
     "      VoiceSearch.play(query, extras);\n\n", "", 1),
    ('앱 화면 신호 받는 곳 빼기',
     "        case 'voiceSearch':\n"
     "          WidgetGo.launched = true; // 말로 틀었으면 인삿말 소리 안 함\n"
     "          final m = Map<String, dynamic>.from(call.arguments as Map);\n"
     "          VoiceSearch.play('${m['query'] ?? ''}', {\n"
     "            'android.intent.extra.artist': m['artist'],\n"
     "            'android.intent.extra.title': m['title'],\n"
     "            'android.intent.extra.album': m['album'],\n"
     "          });\n"
     "          break;\n", "", 1),
]

MAIN_EDITS = [
    ('불러오기 줄 빼기 (main)',
     "import 'services/headset_resume.dart';\nimport 'services/voice_search.dart';\n",
     "import 'services/headset_resume.dart';\n", 1),
    ('준비 줄 빼기',
     "  VoiceSearch.init(playerProvider, radioProvider, musicProvider); // \"헤이 구글, 파란소리에서 ○○ 틀어줘\"\n",
     "", 1),
]

MANIFEST_EDITS = [
    ('앱 설정에서 빼기',
     '\n            <!-- 말로 틀기: "헤이 구글, 파란소리에서 ○○ 틀어줘" -->\n'
     '            <intent-filter>\n'
     '                <action android:name="android.media.action.MEDIA_PLAY_FROM_SEARCH"/>\n'
     '                <category android:name="android.intent.category.DEFAULT"/>\n'
     '            </intent-filter>\n', '', 1),
]


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def edit(path, edits, optional=False):
    if not os.path.exists(path):
        print('❌ 파일을 못 찾았어요:', path, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    text, crlf = load(path)
    changed = False
    for name, old, new, cnt in edits:
        n = text.count(old)
        if n == 0 and optional:
            continue
        if n != cnt:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        changed = True
        print('✔', name)
    return (path, text, crlf) if changed else None


def kotlin_remove(path):
    text, crlf = load(path)
    if 'handleVoiceSearch' not in text:
        return None
    for line in ["        handleVoiceSearch(intent) // 말로 틀기\n"]:
        if text.count(line) != 2:
            print('❌ MainActivity.kt 신호 확인 줄을 못 찾았어요 — 아무것도 저장 안 했어요')
            sys.exit(1)
        text = text.replace(line, '')
    start = text.find("    // 말로 틀기: 구글 어시스턴트 \"파란소리에서 ○○ 틀어줘\" → 앱(다트)에 검색어 전달\n")
    end = text.find("    /// 앱(다트)이 화면 없이 살아 있다가")
    if start < 0 or end < 0 or end < start:
        print('❌ MainActivity.kt 받는 곳을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text[:start] + text[end:]
    print('✔ MainActivity.kt 신호 받는 곳 빼기')
    return (path, text, crlf)


def main():
    if not os.path.exists(VOICE):
        print('이미 적용돼 있어요')
        return
    out = []
    kts = glob.glob(os.path.join('android', 'app', 'src', 'main', '**', 'MainActivity.kt'), recursive=True)
    if len(kts) == 1:
        r = kotlin_remove(kts[0])
        if r:
            out.append(r)
    for r in [edit(MANIFEST, MANIFEST_EDITS, optional=True),
              edit(PLAYER, PLAYER_EDITS[:4] + [], optional=False),
              edit(MAIN, MAIN_EDITS)]:
        if r:
            out.append(r)
    # 앱 화면 신호 받는 곳(2단계)을 넣었을 때만
    p = [x for x in out if x[0] == PLAYER][0]
    if "        case 'voiceSearch':\n" in p[1]:
        name, old, new, cnt = PLAYER_EDITS[4]
        if p[1].count(old) != 1:
            print('❌', name, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        out[out.index(p)] = (p[0], p[1].replace(old, new), p[2])
        print('✔', name)
    for path, text, crlf in out:
        if 'VoiceSearch' in text:
            print('❌', os.path.basename(path), '에 말로 틀기 코드가 남아 있어요 — 아무것도 저장 안 했어요')
            sys.exit(1)
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    os.makedirs(KEEP_DIR, exist_ok=True)
    dst = os.path.join(KEEP_DIR, 'voice_search.dart')
    if os.path.exists(dst):
        os.remove(dst)
    shutil.move(VOICE, dst)
    print('✔ voice_search.dart 보관했어요 →', os.path.abspath(KEEP_DIR))
    print('✔ 되돌렸어요')


main()
