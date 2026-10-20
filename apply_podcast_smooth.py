# -*- coding: utf-8 -*-
# 팟캐스트 재생 중 목록 스크롤이 버벅이는 것 고치기
# 원인: 재생 위치가 바뀔 때마다(1초에 여러 번) 회차 목록·탭 화면 전체를 다시 그림
# → 위치는 미니플레이어·재생 화면만 다시 그리고, 목록은 재생·멈춤이 바뀔 때만
import os, sys

FILES = {
    'core': os.path.join('lib', 'podcast', 'podcast.dart'),
    'ui': os.path.join('lib', 'podcast', 'podcast_screens.dart'),
}


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


D = {}
for k, p in FILES.items():
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8')
    D[k] = {'s': raw.replace('\r\n', '\n'), 'crlf': '\r\n' in raw}
    D[k]['orig'] = D[k]['s']


def rep(k, label, old, new, done):
    s = D[k]['s']
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(label + ' — 찾을 코드를 못 찾았어요')
    D[k]['s'] = s.replace(old, new)
    print('✔', label)


rep('core', '재생 위치 알림 따로',
    '  Timer? _saveTick;\n',
    '  Timer? _saveTick;\n'
    '  /// 재생 위치가 바뀔 때마다 (미니플레이어·재생 화면만 듣기 — 목록은 안 다시 그려서 스크롤이 부드럽게)\n'
    '  final ValueNotifier<int> tick = ValueNotifier(0);\n'
    "  String _stateKey = '';\n",
    done='final ValueNotifier<int> tick')
rep('core', '목록은 재생·멈춤이 바뀔 때만 다시 그리기',
    '    notifyListeners(); // 재생 위치·상태가 바뀔 때마다 화면도\n  }\n',
    '    tick.value++; // 재생 위치 → 미니플레이어·재생 화면만\n'
    "    final key = '${episode?.guid}|$isPlaying|$isLoading';\n"
    '    if (key != _stateKey) {\n'
    '      _stateKey = key;\n'
    '      notifyListeners(); // 재생·멈춤·불러오는 중이 바뀔 때만 목록도\n'
    '    }\n'
    '  }\n',
    done='tick.value++;')
rep('ui', '미니플레이어는 재생 위치 따라 다시 그리기',
    'class PodcastMiniPlayer extends StatelessWidget {\n  const PodcastMiniPlayer({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n',
    'class PodcastMiniPlayer extends StatelessWidget {\n  const PodcastMiniPlayer({super.key});\n\n'
    '  @override\n'
    '  Widget build(BuildContext context) => ValueListenableBuilder<int>(\n'
    '      valueListenable: PodcastPlayer.instance.tick, builder: (ctx, _, __) => _build(ctx));\n\n'
    '  Widget _build(BuildContext context) {\n',
    done='class PodcastMiniPlayer extends StatelessWidget {\n  const PodcastMiniPlayer({super.key});\n\n  @override\n  Widget build(BuildContext context) => ValueListenableBuilder<int>(')
rep('ui', '재생 화면은 재생 위치 따라 다시 그리기',
    '  double? _drag; // 막대를 끄는 동안의 자리 (0~1)\n\n  @override\n  Widget build(BuildContext context) {\n',
    '  double? _drag; // 막대를 끄는 동안의 자리 (0~1)\n\n'
    '  @override\n'
    '  Widget build(BuildContext context) => ValueListenableBuilder<int>(\n'
    '      valueListenable: PodcastPlayer.instance.tick, builder: (ctx, _, __) => _build(ctx));\n\n'
    '  Widget _build(BuildContext context) {\n',
    done='  double? _drag; // 막대를 끄는 동안의 자리 (0~1)\n\n  @override\n  Widget build(BuildContext context) => ValueListenableBuilder<int>(')

changed = [k for k in D if D[k]['s'] != D[k]['orig']]
for k in D:
    s = D[k]['s']
    if s.count('(') != s.count(')') or s.count('{') != s.count('}'):
        fail(os.path.basename(FILES[k]) + ' 괄호가 안 맞아요')
if not changed:
    print('이미 적용돼 있어요')
    sys.exit(0)
for k in changed:
    s = D[k]['s']
    if D[k]['crlf']:
        s = s.replace('\n', '\r\n')
    open(FILES[k], 'wb').write(s.encode('utf-8'))
print('저장했어요:', ', '.join(os.path.basename(FILES[k]) for k in changed))
