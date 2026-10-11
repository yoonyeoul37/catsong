# -*- coding: utf-8 -*-
# 해외 라디오 화면 정리: 위쪽에 나라 이름 · 글자 탭(내 라디오 · 인기 · 장르 · 지역 · 언어) · 점으로 나눈 아래 탭
# 번역해서 글자가 길어져도: 탭 줄은 옆으로 밀리고, 나라 이름·개수 글자는 … 로 줄어서 잘리거나 넘치지 않음
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'radio_country_stations_screen.dart'), recursive=True)
if not hits:
    print('❌ radio_country_stations_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_mineTabs' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

def fail(label, n):
    print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)

def between(s, label, start, end, new, keep_end=True):
    """start 부터 end 앞(또는 end 까지)을 new 로 바꾸기"""
    if s.count(start) != 1: fail(label + ' 시작', s.count(start))
    if s.count(end) != 1: fail(label + ' 끝', s.count(end))
    a = s.index(start); b = s.index(end)
    if b < a: fail(label + ' 순서', 0)
    if not keep_end: b += len(end)
    print(f'✔ {label}')
    return s[:a] + new + s[b:]

def rep(s, label, old, new):
    if s.count(old) != 1: fail(label, s.count(old))
    print(f'✔ {label}')
    return s.replace(old, new)

CHIPBAR = r"""  // '내 라디오' 아래 탭: 즐겨찾기 · 최근청취 · 저장한 곡
  static const List<(String, _ViewMode)> _mineTabs = [
    ('즐겨찾기', _ViewMode.favorite),
    ('최근청취', _ViewMode.recent),
    ('저장한 곡', _ViewMode.saved),
  ];

  /// 글자 탭 한 줄 (고른 것만 진하게 + 밑줄) + 점으로 나눈 아래 탭
  /// 번역해서 글자가 길어져도 줄바꿈 없이 옆으로 밀어서 보게 함
  Widget _chipBar(List<RadioStation> all, RadioProvider radio, Color baseColor, bool isDarkMode) {
    final opts = <String, List<(String, int)>>{
      'genre': _optionsFor('genre', all, radio),
      'region': _optionsFor('region', all, radio),
      'lang': _optionsFor('lang', all, radio),
    };
    const names = {'mine': '내 라디오', 'pop': '인기', 'genre': '장르', 'region': '지역', 'lang': '언어'};
    final chips = ['mine', 'pop', for (final k in ['genre', 'region', 'lang']) if (opts[k]!.isNotEmpty) k];
    final popOpts = _hasTrend(all, radio) ? const [(_popMost, 0), (_popTrend, 0)] : const <(String, int)>[];
    final code = widget.country.code;
    final mineCounts = [
      radio.favorites.length,
      radio.recentlyListened.where((s) => s.countryCode == code).length,
      radio.savedSongs.length,
    ];
    final List<(String, int)> cur = _chip == 'mine'
        ? [for (var i = 0; i < _mineTabs.length; i++) (_mineTabs[i].$1, mineCounts[i])]
        : _chip == 'pop'
            ? popOpts
            : (opts[_chip] ?? const <(String, int)>[]);
    final selSub = _chip == 'mine'
        ? _mineTabs.firstWhere((t) => t.$2 == _mode, orElse: () => _mineTabs.first).$1
        : _chip == 'pop'
            ? (_sub ?? _popMost)
            : _sub;

    void toTop() {
      if (_listCtrl.hasClients) _listCtrl.jumpTo(0);
    }

    void pickChip(String c) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      setState(() {
        _chip = c;
        if (c == 'mine') {
          _mode = _ViewMode.favorite;
          _sub = null;
        } else {
          _mode = _ViewMode.all;
          final o = opts[c] ?? const <(String, int)>[];
          _sub = o.isEmpty ? null : o.first.$1;
        }
        _savedChip = null;
      });
      if (c != 'mine') _saveChip();
      toTop();
    }

    void pickSub(String name) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      setState(() {
        if (_chip == 'mine') {
          _mode = _mineTabs.firstWhere((t) => t.$1 == name).$2;
        } else {
          _sub = name;
        }
        _savedChip = null;
      });
      if (_chip != 'mine') _saveChip();
      toTop();
    }

    final dim = baseColor.withOpacity(0.38);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 위 줄: 글자 탭
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pickChip(c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 22),
                      padding: const EdgeInsets.only(top: 6, bottom: 9),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _chip == c ? baseColor : Colors.transparent, width: 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c == 'mine') ...[
                            Icon(_chip == c ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                size: 14, color: _chip == c ? baseColor : dim),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            names[c]!,
                            softWrap: false,
                            style: TextStyle(
                              color: _chip == c ? baseColor : dim,
                              fontSize: 15,
                              fontWeight: _chip == c ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 아래 줄: 점(·)으로만 나눈 가벼운 탭
        if (cur.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < cur.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(color: baseColor.withOpacity(0.25), shape: BoxShape.circle),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pickSub(cur[i].$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: cur[i].$1),
                          if (cur[i].$2 > 0)
                            TextSpan(
                              text: ' ${cur[i].$2}',
                              style: TextStyle(
                                  fontSize: 11, color: baseColor.withOpacity(0.35), fontWeight: FontWeight.w500),
                            ),
                        ]),
                        softWrap: false,
                        style: TextStyle(
                          color: selSub == cur[i].$1 ? baseColor : baseColor.withOpacity(0.42),
                          fontSize: 13,
                          fontWeight: selSub == cur[i].$1 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
      ],
    );
  }

"""

TITLE = r"""        // 나라 이름 (누르면 나라 고르기) — 긴 이름은 … 로 줄임
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RadioHomeScreen()),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.country.displayName,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: baseColor.withOpacity(0.5)),
            ],
          ),
        ),
"""

s = between(s, '글자 탭 (칩 모양 바꾸기)',
            "  /// 검색칸 아래 칩 한 줄 + (고르면) 밑줄 탭\n",
            "  /// 목록 맨 아래: 다음 방송 불러오는 중", CHIPBAR)
s = between(s, '위쪽에 나라 이름',
            "        title: Row(\n          mainAxisSize: MainAxisSize.min,",
            "        actions: [\n", TITLE)
s = between(s, '위쪽 탭 줄 · 국가선택 줄 빼기',
            "            Padding(\n              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),\n              child: Container(\n                height: 38,",
            "              _chipBar(allStations, radioProvider, baseColor, isDarkMode),\n",
            "            const SizedBox(height: 2),\n            _chipBar(allStations, radioProvider, baseColor, isDarkMode),\n",
            keep_end=False)
s = rep(s, '개수 줄 국기 빼기 (위에 이미 있음)',
        """                        Text(widget.country.flag, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
""", "")

shutil.copy(path, path + '.bak8')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak8)')
