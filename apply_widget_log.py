# -*- coding: utf-8 -*-
# [원인 찾기용] 위젯 버튼을 누를 때 앱 안에서 무슨 일이 일어나는지 터미널에 'PARAN_W'로 찍기
# (원인을 찾고 나면 지워도 됨 — 동작은 하나도 안 바뀜)
import os, sys, shutil

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
if 'PARAN_W' in open(pw, encoding='utf-8').read():
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

edit(pw, [
    ('위젯: 버튼 눌림 찍기', '        val a = intent.action ?: return\n',
     '        val a = intent.action ?: return\n'
     '        android.util.Log.d("PARAN_W", "위젯 버튼: $a / 앱 통로 ${if (MainActivity.mediaChannel != null) "있음" else "없음"}")\n'),
    ('위젯: 앱 대답 찍기 (성공)', '                override fun success(result: Any?) = finish(false)\n',
     '                override fun success(result: Any?) {\n'
     '                    android.util.Log.d("PARAN_W", "앱 대답: 받음 ($method)")\n'
     '                    finish(false)\n'
     '                }\n'),
    ('위젯: 앱 대답 찍기 (못 받음)', '                override fun notImplemented() = finish(true)\n',
     '                override fun notImplemented() {\n'
     '                    android.util.Log.d("PARAN_W", "앱 대답: 받을 곳 없음 ($method) → 엔진 깨우기")\n'
     '                    finish(true)\n'
     '                }\n'),
    ('위젯: 시간 초과 찍기', '        h.postDelayed({ finish(true) }, 1200)\n',
     '        h.postDelayed({\n'
     '            if (!done) android.util.Log.d("PARAN_W", "앱 대답: 1.2초 넘게 없음 ($method) → 엔진 깨우기")\n'
     '            finish(true)\n'
     '        }, 1200)\n'),
    ('위젯: 엔진 깨우기 찍기', '    private fun wakeAndPlay(context: Context, kind: String?) {\n',
     '    private fun wakeAndPlay(context: Context, kind: String?) {\n'
     '        android.util.Log.d("PARAN_W", "엔진 깨우기 (종류: $kind)")\n'),
])
pp = find('player_provider.dart', os.path.join('lib', 'providers'))
edit(pp, [
    ('앱: 받은 신호 찍기', '    _channel.setMethodCallHandler((call) async {\n',
     "    _channel.setMethodCallHandler((call) async {\n"
     "      if (call.method.startsWith('widget') || call.method.startsWith('onAudio')) {\n"
     "        debugPrint('PARAN_W 앱이 받음: ${call.method} ${call.arguments ?? ''}');\n"
     "      }\n"),
    ('앱: 재생 버튼 신호 찍기', '  Future<void> play() async {\n',
     "  Future<void> play() async {\n    debugPrint('PARAN_W 미디어 버튼: 재생 (라디오모드 $_radioMode, 자연모드 $_natureMode)');\n"),
    ('앱: 멈춤 신호 찍기', '  Future<void> pause() async {\n',
     "  Future<void> pause() async {\n    debugPrint('PARAN_W 미디어 버튼: 멈춤 (라디오모드 $_radioMode, 자연모드 $_natureMode)');\n"),
    ('앱: 다음 곡 신호 찍기', '  Future<void> skipToNext() async {\n',
     "  Future<void> skipToNext() async {\n    debugPrint('PARAN_W 미디어 버튼: 다음 (라디오모드 $_radioMode, 자연모드 $_natureMode)');\n"),
])
hr = find('headset_resume.dart', 'lib')
edit(hr, [
    ('앱: 아래 버튼 처리 찍기', '  static Future<void> widgetPlayKind(String kind) async {\n',
     "  static Future<void> widgetPlayKind(String kind) async {\n"
     "    debugPrint('PARAN_W 아래 버튼 처리: $kind (음악중 ${_pp?.isPlaying}, 라디오중 ${_radio?.isPlaying})');\n"),
    ('앱: 라디오 목록 찍기', "          if (list.isEmpty) return;\n          radio.setQueue(list, 0);\n",
     "          debugPrint('PARAN_W 라디오 후보 ${list.length}개 ${list.isNotEmpty ? list.first.name : ''}');\n"
     "          if (list.isEmpty) return;\n          radio.setQueue(list, 0);\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_widget_log')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if c else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 — 이제 flutter run 하고 위젯 버튼을 눌러 보세요 (터미널에 PARAN_W 줄이 찍혀요)')
