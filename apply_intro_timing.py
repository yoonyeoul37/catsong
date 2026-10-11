# -*- coding: utf-8 -*-
# 첫인사 화면: 사진이 '실제로 화면에 뜬 뒤'부터 4.5초 보여주기
# (전에는 앱이 켜지는 순간부터 시간을 재서, 사진 불러오는 사이에 시간이 다 지나가 버림)
import sys, os, re, shutil

path = os.path.join('lib', 'main.dart')
if not os.path.exists(path):
    print('❌ lib/main.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'onDone: () {' in s and '_started' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)
if 'class _IntroView' not in s:
    print('❌ apply_intro_anim.py 를 먼저 실행해 주세요'); sys.exit(1)

def sub1(label, pattern, repl):
    global s
    n = len(re.findall(pattern, s))
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = re.sub(pattern, repl, s)
    print(f'✔ {label}')

# 1) 앱 켜지자마자 재던 타이머 빼기 (3초든 4.5초든)
sub1('앱 켜질 때 재던 시간 빼기',
     r"    Future\.delayed\(const Duration\((?:seconds: 3|milliseconds: \d+)\), \(\) \{\n      if \(mounted\) setState\(\(\) => _showIntro = false\);\n    \}\);\n",
     "    // (첫인사 시간은 사진이 화면에 뜬 뒤부터 _IntroView가 잼)\n")

# 2) 첫인사 화면에 '끝나면 알려주기' 연결
sub1('첫인사 끝나면 홈으로',
     r"          body: _IntroView\(\n            path: introAssetPath\(context\),\n",
     "          body: _IntroView(\n            path: introAssetPath(context),\n            onDone: () {\n              if (mounted) setState(() => _showIntro = false);\n            },\n")

sub1('첫인사 화면이 끝 알림을 받게',
     r"  final bool showTitle;\n  const _IntroView\(\{required this\.path, required this\.showTitle\}\);",
     "  final bool showTitle;\n  final VoidCallback onDone;\n  const _IntroView({required this.path, required this.showTitle, required this.onDone});")

# 3) 사진이 다 불러와진 뒤에 움직이기 시작 → 끝나면 홈으로
sub1('사진이 뜬 뒤부터 4.5초',
     r"  late final AnimationController _c =\n      AnimationController\(vsync: this, duration: const Duration\(milliseconds: \d+\)\)\.\.forward\(\);\n",
     """  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // 사진을 다 불러온 다음에 시작 (불러오는 동안 시간이 흘러가지 않게)
    precacheImage(AssetImage(widget.path), context).whenComplete(() {
      if (!mounted) return;
      _c.forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
    });
  }
""")

shutil.copy(path, path + '.bak_timing')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_timing)')
