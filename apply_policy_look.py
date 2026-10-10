# -*- coding: utf-8 -*-
# 앱 안 약관 화면 다듬기: 글자 원래 크기 + 위쪽 "← 제목" 줄 빼기 (페이지 머리만 남김)
# 먼저 한 번:  flutter pub add webview_flutter_android
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
PATH = 'lib/screens/policy_web_screen.dart'
MARK = 'setTextZoom(100)'

EDITS = [
('불러오기',
"""import 'package:webview_flutter/webview_flutter.dart';
""",
"""import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
"""),
('글자 원래 크기',
"""      ..loadRequest(Uri.parse(widget.url));
  }""",
"""      ..loadRequest(Uri.parse(widget.url));
    // 글자 크기: 폰 글꼴 크기 설정 때문에 커지지 않게 (브라우저에서 보던 크기 그대로)
    final p = _c.platform;
    if (p is AndroidWebViewController) p.setTextZoom(100);
  }"""),
('위쪽 줄 빼기',
"""          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: _back,
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 18),
            ),
            title: Text(widget.title,
                style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),
          ),
          body: SafeArea(
            top: false,""",
"""          // 위쪽 줄 없이 페이지 머리(홈·언어)만 · 뒤로는 폰 뒤로가기
          body: SafeArea("""),
('안 쓰는 색 정리',
"""    final line = dark ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
""", ''),
]

def main():
    if not os.path.exists('pubspec.yaml'):
        print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    if 'webview_flutter_android' not in open('pubspec.yaml', encoding='utf-8').read():
        print('❌ 먼저 이걸 실행해 주세요:  flutter pub add webview_flutter_android'); return
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ policy_web_screen.dart 가 없어요. apply_policy_inapp.py 를 먼저 실행해 주세요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    for o, c in ('{}', '()', '[]'):
        if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
            print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요 ✔')

main()
