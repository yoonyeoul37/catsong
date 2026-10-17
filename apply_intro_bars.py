# -*- coding: utf-8 -*-
# 파란소리 소개 화면: 위로 올리면 글이 시계·배터리 아이콘과 겹치던 것 → 사진을 지나면 상태바 자리를 바탕색으로 가리고 아이콘을 어둡게
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_intro_bars.py
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
P = 'lib/screens/paran_intro_screen.dart'
E = json.loads('[["클래스를 스크롤 기억하게 바꾸기", "class ParanIntroScreen extends StatelessWidget {\\n  const ParanIntroScreen({super.key});\\n", "class ParanIntroScreen extends StatefulWidget {\\n  const ParanIntroScreen({super.key});\\n\\n  @override\\n  State<ParanIntroScreen> createState() => _ParanIntroScreenState();\\n}\\n\\nclass _ParanIntroScreenState extends State<ParanIntroScreen> {\\n  // 사진을 지나 위로 올렸는지 → 상태바 자리를 바탕색으로 가리고 아이콘을 어둡게\\n  final _covered = ValueNotifier(false);\\n\\n  @override\\n  void dispose() {\\n    _covered.dispose();\\n    super.dispose();\\n  }\\n"], ["상태바 아이콘: 사진 위는 흰색, 지나면 어둡게", "    return AnnotatedRegion<SystemUiOverlayStyle>(\\n      value: SystemUiOverlayStyle(\\n        statusBarColor: Colors.transparent,\\n        statusBarIconBrightness: Brightness.light, // 위는 사진이라 흰 아이콘\\n        statusBarBrightness: Brightness.dark,\\n", "    return ValueListenableBuilder<bool>(\\n      valueListenable: _covered,\\n      builder: (context, covered, _) => AnnotatedRegion<SystemUiOverlayStyle>(\\n      value: SystemUiOverlayStyle(\\n        statusBarColor: Colors.transparent,\\n        // 사진 위는 흰 아이콘 · 사진을 지나면 (라이트 모드) 어두운 아이콘\\n        statusBarIconBrightness: covered && !isDark ? Brightness.dark : Brightness.light,\\n        statusBarBrightness: covered && !isDark ? Brightness.light : Brightness.dark,\\n"], ["스크롤 위치 보기", "            SingleChildScrollView(\\n              child: Column(\\n                crossAxisAlignment: CrossAxisAlignment.start,\\n                children: [\\n                  // ── 맨 위 사진 + 로고 ──\\n", "            NotificationListener<ScrollNotification>(\\n              onNotification: (n) {\\n                final c = n.metrics.pixels > heroH - top - 8;\\n                if (c != _covered.value) _covered.value = c;\\n                return false;\\n              },\\n              child: SingleChildScrollView(\\n              child: Column(\\n                crossAxisAlignment: CrossAxisAlignment.start,\\n                children: [\\n                  // ── 맨 위 사진 + 로고 ──\\n"], ["사진 지나면 상태바 자리 가리기", "            ),\\n\\n            // ── 뒤로 (사진 위에 떠 있는 동그란 버튼) ──\\n", "            ),\\n            ),\\n\\n            // ── 사진을 지나 올리면 상태바 자리를 바탕색으로 (글이 시계·배터리와 안 겹치게) ──\\n            Positioned(\\n              left: 0,\\n              right: 0,\\n              top: 0,\\n              height: top,\\n              child: IgnorePointer(\\n                child: AnimatedOpacity(\\n                  opacity: covered ? 1 : 0,\\n                  duration: const Duration(milliseconds: 180),\\n                  child: ColoredBox(color: bg),\\n                ),\\n              ),\\n            ),\\n\\n            // ── 뒤로 (사진 위에 떠 있는 동그란 버튼) ──\\n"], ["괄호 닫기", "          ],\\n        ),\\n      ),\\n    );\\n  }\\n\\n  static const _featureIcons", "          ],\\n        ),\\n      ),\\n      ),\\n    );\\n  }\\n\\n  static const _featureIcons"]]')

def main():
    if not os.path.exists(P):
        print(f'❌ {P} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
    raw = open(P, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    t = raw.replace('\r\n', '\n')
    if '_ParanIntroScreenState' in t:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in E:
        n = t.count(old)
        if n == 1:
            t = t.replace(old, new); print(f'✔ paran_intro_screen.dart - {name}')
        else:
            print(f'❌ paran_intro_screen.dart - {name} (찾을 코드가 {n}군데)'); ok = False
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    open(P, 'wb').write((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
    print('\n완료!')

main()
