# -*- coding: utf-8 -*-
# 라디오 국가 검색칸에 마이크(음성 검색) 넣기 — 음악 검색칸과 같은 방식
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

VOICE = r'''  String _query = '';

  // ── 마이크로 나라 찾기 (음악 검색칸과 같은 방식) ──
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available || !mounted) return;
    // 앱 언어에 맞춰 알아듣기
    final lang = Localizations.localeOf(context).languageCode;
    final localeId = switch (lang) {
      'ko' => 'ko_KR',
      'ja' => 'ja_JP',
      'zh' => 'zh_CN',
      _ => 'en_US',
    };
    setState(() => _isListening = true);
    _speech.listen(
      localeId: localeId,
      onResult: (result) {
        // "일본." 처럼 끝에 붙는 문장부호는 빼기
        final words = result.recognizedWords.replaceAll(RegExp(r'[.,!?。、]'), '').trim();
        _search.text = words;
        _search.selection = TextSelection.fromPosition(TextPosition(offset: words.length));
        if (mounted) setState(() => _query = words);
      },
    );
  }
'''

EDITS = [
    ("음성 검색 연결",
     "import '../l10n/app_localizations.dart';\n",
     "import '../l10n/app_localizations.dart';\nimport 'package:speech_to_text/speech_to_text.dart' as stt;\nimport 'package:permission_handler/permission_handler.dart';\n"),
    ("마이크로 듣기",
     "  String _query = '';\n",
     VOICE),
    ("화면 닫으면 듣기 멈춤",
     "  void dispose() {\n    _search.dispose();",
     "  void dispose() {\n    _speech.cancel();\n    _search.dispose();"),
    ("검색칸 오른쪽에 마이크",
     "                child: Icon(Icons.cancel_rounded, size: 18, color: hint),\n              ),\n            )\n          else\n            const SizedBox(width: 12),\n",
     "                child: Icon(Icons.cancel_rounded, size: 18, color: hint),\n              ),\n            )\n          else\n            GestureDetector(\n              behavior: HitTestBehavior.opaque,\n              onTap: _toggleListening,\n              child: Padding(\n                padding: const EdgeInsets.symmetric(horizontal: 12),\n                child: Icon(\n                  _isListening ? Icons.mic : Icons.mic_none,\n                  size: 20,\n                  color: _isListening ? Colors.redAccent : hint,\n                ),\n              ),\n            ),\n"),
]

p = find('radio_home_screen.dart')
if not p:
    print('❌ radio_home_screen.dart 파일을 못 찾았어요'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')
if '_toggleListening' in t:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for name, a, b in EDITS:
    if t.count(a) == 1:
        t = t.replace(a, b); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % t.count(a))
if ok and not all(t.count(x) == t.count(y) for x, y in ('()', '{}', '[]')):
    ok = False; print('❌ 괄호 개수가 안 맞아요')
if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
shutil.copyfile(p, p + '.bak')
if crlf:
    t = t.replace('\n', '\r\n')
open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
