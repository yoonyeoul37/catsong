# -*- coding: utf-8 -*-
# 팟캐스트 목록: 줄이 화면에 들어올 때 아래에서 살짝 떠오르며 나타나기 (한 번 나타난 줄은 다시 안 움직임)
#  · 인기 순위 · 검색 결과 · 회차 목록 · 구독 목록 창
#  · 처음 화면에 보이는 줄은 위에서부터 차례로 (짧게), 스크롤해서 들어오는 줄은 바로
#  · 폰에서 '애니메이션 줄이기'를 켜 두면 움직이지 않음
# (apply_podcast_bar4.py 를 먼저 돌린 다음에)
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast_screens.dart')


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


if not os.path.exists(PATH):
    fail('파일이 없어요: ' + PATH)
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s
if 'class _PodSubsSheet' not in s:
    fail('구독 목록 창이 아직 없어요. apply_podcast_bar4.py 를 먼저 돌려 주세요')


def rep(label, old, new, done, count=1):
    global s
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != count:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


# ── 팟캐스트 탭: 순위 · 검색 결과 ──
rep('탭: 화면마다 따로 기억',
    '  bool _latestLoading = false; // 1위 카드 \'최신 회차\' 누른 뒤 불러오는 중\n',
    '  bool _latestLoading = false; // 1위 카드 \'최신 회차\' 누른 뒤 불러오는 중\n'
    "  final String _tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이 화면에서 한 번만\n",
    done="final String _tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이 화면에서 한 번만\n  Future<List<PodcastShow>>?")
rep('탭: 순위·검색 목록 줄마다 나타나기 (2곳)',
    '              _listCard([',
    '              ..._listCard([',
    done='..._listCard([', count=2)
rep('탭: 흰 카드를 줄 조각으로 (스크롤할 때 들어오는 줄만 움직이게)',
    '  Widget _listCard(List<(PodcastShow, int?)> rows, bool dark) {\n'
    '    return Container(\n'
    '      decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),\n'
    '      padding: const EdgeInsets.symmetric(horizontal: 14),\n'
    '      child: Column(\n'
    '        children: [\n'
    '          for (var i = 0; i < rows.length; i++) ...[\n'
    '            if (i > 0) Divider(height: 1, thickness: 0.6, color: _line(dark), indent: rows[i].$2 != null ? 90 : 62),\n'
    '            _showRow(rows[i].$1, rows[i].$2, dark),\n'
    '          ],\n'
    '        ],\n'
    '      ),\n'
    '    );\n'
    '  }\n',
    '  // (줄마다 따로 그려서 화면에 들어올 때 나타나기 · 모양은 예전과 같은 흰 카드 하나)\n'
    '  List<Widget> _listCard(List<(PodcastShow, int?)> rows, bool dark) => [\n'
    '        for (var i = 0; i < rows.length; i++)\n'
    '          _podPiece(\n'
    '            dark,\n'
    '            first: i == 0,\n'
    '            last: i == rows.length - 1,\n'
    '            child: Column(\n'
    '              mainAxisSize: MainAxisSize.min,\n'
    '              children: [\n'
    '                if (i > 0) Divider(height: 1, thickness: 0.6, color: _line(dark), indent: rows[i].$2 != null ? 90 : 62),\n'
    "                _PodAppear(id: '$_tok:$_query:${rows[i].$1.id}', index: i, child: _showRow(rows[i].$1, rows[i].$2, dark)),\n"
    '              ],\n'
    '            ),\n'
    '          ),\n'
    '      ];\n',
    done='List<Widget> _listCard(List<(PodcastShow, int?)> rows, bool dark) => [')

# ── 회차 목록 ──
rep('회차 목록: 화면마다 따로 기억',
    '  List<PodcastEpisode>? _fresh; // 저장된 목록을 먼저 보여 준 뒤 뒤에서 새로 받은 목록\n',
    '  List<PodcastEpisode>? _fresh; // 저장된 목록을 먼저 보여 준 뒤 뒤에서 새로 받은 목록\n'
    "  final String _tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이 화면에서 한 번만\n",
    done="  List<PodcastEpisode>? _fresh; // 저장된 목록을 먼저 보여 준 뒤 뒤에서 새로 받은 목록\n  final String _tok")
rep('회차 목록: 줄마다 나타나기',
    '              else\n'
    '                Container(\n'
    '                  decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),\n'
    '                  padding: const EdgeInsets.symmetric(horizontal: 14),\n'
    '                  child: Column(\n'
    '                    children: [\n'
    '                      for (var i = 0; i < eps.length; i++) ...[\n'
    '                        if (i > 0) Divider(height: 1, thickness: 0.6, color: _line(dark), indent: 46),\n'
    '                        _episodeRow(eps[i], pod, dark),\n'
    '                      ],\n'
    '                    ],\n'
    '                  ),\n'
    '                ),\n',
    '              else\n'
    '                // 줄마다 따로 그려서 스크롤해 들어올 때 나타나기 (모양은 예전과 같은 흰 카드 하나)\n'
    '                for (var i = 0; i < eps.length; i++)\n'
    '                  _podPiece(\n'
    '                    dark,\n'
    '                    first: i == 0,\n'
    '                    last: i == eps.length - 1,\n'
    '                    child: Column(\n'
    '                      mainAxisSize: MainAxisSize.min,\n'
    '                      children: [\n'
    '                        if (i > 0) Divider(height: 1, thickness: 0.6, color: _line(dark), indent: 46),\n'
    "                        _PodAppear(id: '$_tok:${eps[i].guid}', index: i, child: _episodeRow(eps[i], pod, dark)),\n"
    '                      ],\n'
    '                    ),\n'
    '                  ),\n',
    done="_PodAppear(id: '$_tok:${eps[i].guid}'")

# ── 구독 목록 창 ──
rep('구독 창: 열 때마다 따로 기억',
    '                          _buzz();\n'
    '                          showModalBottomSheet(\n'
    '                            context: context,\n'
    '                            backgroundColor: Colors.transparent,\n'
    '                            isScrollControlled: true,\n'
    '                            builder: (_) => const _PodSubsSheet(),\n',
    '                          _buzz();\n'
    "                          final tok = '${DateTime.now().microsecondsSinceEpoch}'; // 나타나기: 이번에 연 창에서 한 번만\n"
    '                          showModalBottomSheet(\n'
    '                            context: context,\n'
    '                            backgroundColor: Colors.transparent,\n'
    '                            isScrollControlled: true,\n'
    '                            builder: (_) => _PodSubsSheet(tok: tok),\n',
    done='builder: (_) => _PodSubsSheet(tok: tok),')
rep('구독 창: 값 받기',
    'class _PodSubsSheet extends StatelessWidget {\n  const _PodSubsSheet();\n',
    'class _PodSubsSheet extends StatelessWidget {\n  final String tok;\n  const _PodSubsSheet({this.tok = \'\'});\n',
    done="const _PodSubsSheet({this.tok = ''});")
rep('구독 창: 줄마다 나타나기 (앞)',
    '                                InkWell(\n'
    '                                  onTap: () => open(others[i]),\n',
    '                                _PodAppear(\n'
    "                                  id: '$tok:${others[i].id}',\n"
    '                                  index: i,\n'
    '                                  child: InkWell(\n'
    '                                  onTap: () => open(others[i]),\n',
    done="id: '$tok:${others[i].id}',")
rep('구독 창: 줄마다 나타나기 (끝)',
    '                                        Icon(Icons.chevron_right_rounded, color: sub.withOpacity(0.6), size: 20),\n'
    '                                      ],\n'
    '                                    ),\n'
    '                                  ),\n'
    '                                ),\n'
    '                              ],\n',
    '                                        Icon(Icons.chevron_right_rounded, color: sub.withOpacity(0.6), size: 20),\n'
    '                                      ],\n'
    '                                    ),\n'
    '                                  ),\n'
    '                                ),\n'
    '                                ),\n'
    '                              ],\n',
    done='size: 20),\n                                      ],\n                                    ),\n                                  ),\n                                ),\n                                ),\n')

if 'class _PodAppear' not in s:
    s = s.rstrip('\n') + '\n' + r'''
/// 흰 카드 한 조각 (첫 줄은 위 모서리, 마지막 줄은 아래 모서리만 둥글게 → 붙이면 카드 하나)
Widget _podPiece(bool dark, {required bool first, required bool last, required Widget child}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _card(dark),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(first ? 10 : 0),
          bottom: Radius.circular(last ? 10 : 0),
        ),
      ),
      child: child,
    );

/// 줄이 화면에 들어올 때 아래에서 살짝 떠오르며 나타나기 (0.38초)
/// 한 번 나타난 줄은 스크롤해서 다시 와도 안 움직임 · 처음 보이는 줄(8개까지)만 차례로
class _PodAppear extends StatefulWidget {
  final String id; // 이 줄 이름 (한 번만 움직이게)
  final int index;
  final Widget child;
  const _PodAppear({required this.id, required this.index, required this.child});

  @override
  State<_PodAppear> createState() => _PodAppearState();
}

class _PodAppearState extends State<_PodAppear> with SingleTickerProviderStateMixin {
  static final Set<String> _shown = {};
  static DateTime _firstAt = DateTime(2000);
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void initState() {
    super.initState();
    if (_shown.contains(widget.id)) {
      _c.value = 1;
      return;
    }
    if (_shown.length > 3000) _shown.clear();
    _shown.add(widget.id);
    // 화면을 처음 열 때 보이는 줄만 위에서부터 차례로 (0.04초씩) · 스크롤로 들어오는 줄은 바로
    final now = DateTime.now();
    if (widget.index == 0) _firstAt = now;
    final opening = now.difference(_firstAt) < const Duration(milliseconds: 500);
    final wait = opening && widget.index < 8 ? widget.index * 40 : 0;
    if (wait == 0) {
      _c.forward();
    } else {
      Future.delayed(Duration(milliseconds: wait), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child; // 애니메이션 줄이기
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
        );
      },
    );
  }
}
'''
    print('✔ 나타나기 모양 · 카드 조각')
else:
    print('✔ 나타나기 모양 · 카드 조각 (이미 돼 있음)')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
