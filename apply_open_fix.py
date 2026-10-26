# -*- coding: utf-8 -*-
# 다른 앱에서 열기: 시작 화면(라디오 등)이 재생 화면을 덮지 않게 · 노래를 닫으면 빈 재생 화면 대신 저절로 닫기
import os, sys

def find(name):
    for r, _, fs in os.walk('lib'):
        if name in fs: return os.path.join(r, name)
    return None

HOME = find('home_screen.dart')
PS = find('player_screen.dart')
for n, p in [('home_screen.dart', HOME), ('player_screen.dart', PS)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)
if not find('open_audio.dart'):
    print('❌ open_audio.dart 가 없어요 (apply_open_with.py 먼저)'); sys.exit(1)

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

hs, HNL = load(HOME)
ps, PNL = load(PS)
if '_autoClosed' in ps:
    print('이미 적용돼 있어요'); sys.exit(0)

home_steps = [
 ('[home_screen] open_audio 불러오기',
  "import '../services/alarm_service.dart';\n",
  "import '../services/alarm_service.dart';\n"
  "import '../services/open_audio.dart';\n"),
 ('[home_screen] 노래로 켜졌으면 시작 화면 준비 안 함',
  "    final savedStart = context.read<StartScreenProvider>().startScreen;\n"
  "    if (savedStart == StartScreenType.music) {\n",
  "    final savedStart = OpenAudio.target.value != null\n"
  "        ? null // 다른 앱에서 노래를 열어서 켜졌으면 시작 화면 대신 재생 화면\n"
  "        : context.read<StartScreenProvider>().startScreen;\n"
  "    if (savedStart == StartScreenType.music) {\n"),
 ('[home_screen] 노래로 켜졌으면 시작 화면으로 안 가기',
  "      if (WidgetGo.target.value != null) {\n"
  "        await _handleWidgetGo();\n"
  "      } else {\n"
  "        await _navigateToSavedStartScreen();\n"
  "      }\n",
  "      if (OpenAudio.target.value != null) {\n"
  "        // 다른 앱에서 연 노래: 재생 화면이 열려 있으니 시작 화면(라디오 등)으로 덮지 않음\n"
  "      } else if (WidgetGo.target.value != null) {\n"
  "        await _handleWidgetGo();\n"
  "      } else {\n"
  "        await _navigateToSavedStartScreen();\n"
  "      }\n"),
]

ps_steps = [
 ('[player_screen] 노래가 닫히면 재생 화면도 저절로 닫기',
  "    if (song == null) {\n"
  "      final baseColorEmpty = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;\n"
  "      return Scaffold(\n"
  "        backgroundColor: Colors.transparent,\n"
  "        body: Center(\n"
  "          child: Text('No song is playing',\n"
  "              style: TextStyle(color: baseColorEmpty.withOpacity(0.6))),\n"
  "        ),\n"
  "      );\n"
  "    }\n",
  "    if (song == null) {\n"
  "      // 미니플레이어 ✕ 등으로 노래를 닫으면: 빈 재생 화면('No song is playing')을 남기지 않고 이 화면만 닫기\n"
  "      // (위에 다른 화면이 있어도 이 화면만 빼기 — 맨 위 화면을 잘못 닫지 않게)\n"
  "      if (!_autoClosed) {\n"
  "        _autoClosed = true;\n"
  "        WidgetsBinding.instance.addPostFrameCallback((_) {\n"
  "          if (!mounted) return;\n"
  "          final route = ModalRoute.of(context);\n"
  "          final nav = Navigator.of(context);\n"
  "          if (route == null || route.isFirst) return;\n"
  "          if (route.isCurrent) {\n"
  "            nav.pop();\n"
  "          } else {\n"
  "            nav.removeRoute(route);\n"
  "          }\n"
  "        });\n"
  "      }\n"
  "      return const Scaffold(backgroundColor: Colors.transparent, body: SizedBox.shrink());\n"
  "    }\n"
  "    _autoClosed = false;\n"),
 ('[player_screen] 저절로 닫기 표시',
  "  @override\n"
  "  Widget build(BuildContext context) {\n"
  "    final playerProvider = context.watch<PlayerProvider>();\n"
  "    final musicProvider = context.watch<MusicProvider>();\n"
  "    final song = playerProvider.currentSong;\n",
  "  bool _autoClosed = false; // 노래가 닫혀서 이 화면을 저절로 닫는 중\n"
  "\n"
  "  @override\n"
  "  Widget build(BuildContext context) {\n"
  "    final playerProvider = context.watch<PlayerProvider>();\n"
  "    final musicProvider = context.watch<MusicProvider>();\n"
  "    final song = playerProvider.currentSong;\n"),
]

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

hs, a = apply(hs, HNL, home_steps)
ps, b = apply(ps, PNL, ps_steps)
if not (a and b):
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(HOME, 'wb').write(hs.encode('utf-8'))
open(PS, 'wb').write(ps.encode('utf-8'))
print('저장했어요')
