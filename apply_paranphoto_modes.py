# -*- coding: utf-8 -*-
# 파란포토 창: 자동(시간대) · 랜덤 · 고정 + 카테고리는 작은 사진 + 이름(B안)
import os, sys

PATH = os.path.join('lib', 'screens', 'player_screen.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'player_screen.dart' in files:
            PATH = os.path.join(root, 'player_screen.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')
orig = src

if '_photoPool()' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(name, old, new):
    global src, ok
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

rep('자동·랜덤·고정 기억할 자리',
"""  Timer? _autoBgTimer;
""",
"""  Timer? _autoBgTimer;
  int _photoMode = 1; // 파란포토: 0 자동(시간대) · 1 랜덤 · 2 고정
  String _photoRange = ''; // 랜덤 범위: 카테고리 이름 · 전체 · 하트 · 내 사진 (비어 있으면 지금 사진의 카테고리)
""")

rep('불러오기 (예전 "몇 분마다 바꾸기"는 곡마다 바뀌는 자동·랜덤으로 대신)',
"""      _autoBgMin = prefs.getInt('autoBgMin') ?? 0;
""",
"""      _autoBgMin = 0; // (예전 10분·30분마다 바꾸기 → 곡마다 바뀌는 자동·랜덤으로 대신)
      _photoMode = prefs.getInt('paranPhotoMode') ?? 1;
      _photoRange = prefs.getString('paranPhotoRange') ?? '';
""")

rep('시간대 · 사진 후보 고르기',
"""  /// 파란포토 사진 고르기 창 (가사 배경 창과 같은 모양: 아래에서 올라오고, 사진은 3장씩 위아래로)
""",
"""  // ───── 파란포토: 자동(시간대) · 랜덤 · 고정 ─────

  /// 지금 시각의 시간대 (노을은 계절 따라: 여름 19시 · 겨울 17시 · 그 밖 18시부터 1시간 반)
  static String _timeCategory([DateTime? now]) {
    final t = now ?? DateTime.now();
    final h = t.hour + t.minute / 60;
    final dusk = (t.month >= 5 && t.month <= 8) ? 19.0 : ((t.month >= 11 || t.month <= 2) ? 17.0 : 18.0);
    if (h >= 4 && h < 7) return '새벽';
    if (h >= 7 && h < 12) return '아침';
    if (h >= 12 && h < dusk) return '오후';
    if (h >= dusk && h < dusk + 1.5) return '노을';
    if (h >= dusk + 1.5 && h < 23) return '밤';
    return '깊은 밤';
  }

  /// 사진이 들어 있는 카테고리 (없으면 null)
  String? _catOf(String path) {
    for (final e in _nightCategoryPhotos.entries) {
      if (e.value.contains(path)) return e.key;
    }
    return null;
  }

  /// 다음 곡에 보여 줄 사진 후보 (고정이면 빈 목록)
  List<String> _photoPool() {
    if (_photoMode == 2) return <String>[];
    if (_photoMode == 0) {
      final list = _nightCategoryPhotos[_timeCategory()];
      if (list != null && list.isNotEmpty) return List.of(list);
      // 시간대 사진이 아직 없으면 랜덤처럼
    }
    final r = _photoRange;
    if (r == '전체') return _nightCategoryPhotos.values.expand((e) => e).toList();
    if (r == '하트') return _nightFavPaths.where((p) => p.startsWith('assets/')).toList();
    if (r == '내 사진') return _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
    final list = _nightCategoryPhotos[r] ?? _nightCategoryPhotos[_catOf(_nightBgPath) ?? ''];
    return List.of(list ?? const <String>[]);
  }

  Future<void> _setPhotoMode(int m) async {
    setState(() => _photoMode = m);
    final p = await SharedPreferences.getInstance();
    await p.setInt('paranPhotoMode', m);
    // 자동으로 바꾸면 바로 지금 시간대 사진으로
    if (m == 0) {
      final list = _nightCategoryPhotos[_timeCategory()];
      if (list != null && list.isNotEmpty && !list.contains(_nightBgPath)) {
        final next = list[math.Random().nextInt(list.length)];
        if (!mounted) return;
        setState(() {
          _nightBgPath = next;
          _nightBgIsFile = false;
        });
        _saveNightBg(next);
      }
    }
  }

  Future<void> _setPhotoRange(String r) async {
    _photoRange = r;
    final p = await SharedPreferences.getInstance();
    await p.setString('paranPhotoRange', r);
  }

  /// 파란포토 사진 고르기 창 (가사 배경 창과 같은 모양: 아래에서 올라오고, 사진은 3장씩 위아래로)
""")

rep('곡이 바뀔 때: 모드에 맞는 사진으로',
"""        // 하트한 사진이 2장 이상이면 그중에서, 아니면 지금 사진과 같은 카테고리에서
        final List<String> options = (_nightFavPaths.length >= 2
                ? _nightFavPaths.toList()
                : _nightCategoryPhotos.values
                    .firstWhere((l) => l.contains(_nightBgPath), orElse: () => const [])
                    .toList())
          ..remove(_nightBgPath);""",
"""        // 자동: 지금 시간대 · 랜덤: 고른 범위 · 고정: 안 바꿈
        final List<String> options = _photoPool()..remove(_nightBgPath);""")

rep('시간마다 바꾸기도 같은 규칙으로',
"""    // 하트한 사진이 2장 이상이면 그중에서, 아니면 지금 사진과 같은 카테고리에서
    final List<String> pool = _nightFavPaths.length >= 2
        ? _nightFavPaths.toList()
        : _nightCategoryPhotos.values
            .firstWhere((l) => l.contains(_nightBgPath), orElse: () => const [])
            .toList();""",
"""    final List<String> pool = _photoPool();""")

rep('창을 열 때: 고른 범위·시간대 카테고리로',
"""    bool manage = false; // 내 사진 관리(✕) 모드
""",
"""    if (_photoMode == 0 && (_nightCategoryPhotos[_timeCategory()] ?? const []).isNotEmpty) {
      cat = _timeCategory();
    } else if (_photoMode == 1 && _photoRange.isNotEmpty) {
      cat = _photoRange;
    }
    bool manage = false; // 내 사진 관리(✕) 모드
""")

rep('한 덩어리 칸 바탕색',
"""        final chipLine = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
""",
"""        final chipLine = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
        final segBg = dark ? const Color(0xFF2E2C28) : const Color(0xFFEDE6D8);
""")

rep('사진 누르면: 랜덤이면 이 카테고리 안에서',
"""                : () {
                    tick();
                    setState(() {
                      _nightBgPath = path;
                      _nightBgIsFile = isFile;
                    });""",
"""                : () {
                    tick();
                    if (_photoMode == 1) _setPhotoRange(cat); // 랜덤이면 이 카테고리 안에서
                    setState(() {
                      _nightBgPath = path;
                      _nightBgIsFile = isFile;
                    });""")

rep('카테고리 목록 (하트 추가)',
"""        final cats = <String>['전체', ..._nightCategoryPhotos.keys, '내 사진'];
        final mine = _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();""",
"""        final mine = _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
        final favAssets = _nightFavPaths.where((p) => p.startsWith('assets/')).toList();
        final cats = <String>['전체', ..._nightCategoryPhotos.keys, if (favAssets.isNotEmpty) '하트', '내 사진'];
        if (!cats.contains(cat)) cat = '전체';

        // 카테고리 작은 사진
        Widget coverOf(String c) {
          if (c == '내 사진') {
            if (mine.isNotEmpty) {
              return Image.file(File(mine.first),
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  errorBuilder: (_, __, ___) => Container(color: chipBg));
            }
            return Container(color: chipBg, child: Icon(Icons.add_photo_alternate_outlined, color: sub, size: 22));
          }
          final String? p = c == '전체'
              ? (_nightCategoryPhotos.values.isNotEmpty ? _nightCategoryPhotos.values.first.first : null)
              : c == '하트'
                  ? (favAssets.isNotEmpty ? favAssets.first : null)
                  : (_nightCategoryCover[c] ?? _nightCategoryPhotos[c]?.first);
          if (p == null) return Container(color: chipBg);
          return Stack(
            fit: StackFit.expand,
            children: [
              paranPhoto(p, thumb: true, fit: BoxFit.cover),
              if (c == '하트')
                const Center(
                  child: Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 20, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                ),
            ],
          );
        }

        // 모드 설명 한 줄
        final tc = _timeCategory();
        final hasTime = (_nightCategoryPhotos[tc] ?? const <String>[]).isNotEmpty;
        final rangeName = _photoRange.isEmpty ? (_catOf(_nightBgPath) ?? '같은 카테고리') : _photoRange;
        final modeHint = _photoMode == 0
            ? (hasTime ? '지금은 $tc · 곡마다 $tc 사진으로 바뀌어요' : '시간대 사진을 준비 중이에요 · 지금은 고른 카테고리 안에서 바뀌어요')
            : _photoMode == 1
                ? '곡마다 "$rangeName" 사진 중에서 바뀌어요'
                : '고른 사진 한 장만 계속 보여요';""")

rep('하트 카테고리 사진',
"""          final photos = cat == '전체'
              ? _nightCategoryPhotos.values.expand((e) => e).toList()
              : (_nightCategoryPhotos[cat] ?? const <String>[]);""",
"""          final photos = cat == '전체'
              ? _nightCategoryPhotos.values.expand((e) => e).toList()
              : cat == '하트'
                  ? favAssets
                  : (_nightCategoryPhotos[cat] ?? const <String>[]);""")

# 위쪽: 색감·자동 바꾸기 카드 + 알약 카테고리 → 자동·랜덤·고정 칸 + 작은 사진 카테고리
a = src.find("            // 색감 · 자동으로 바꾸기\n")
b = src.find("            // 내 사진: 관리 / 완료\n")
NEW_TOP = r"""            // 자동 · 랜덤 · 고정 (한 덩어리 칸, 고른 칸만 하얗게)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: segBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  for (final m in const [(0, '자동'), (1, '랜덤'), (2, '고정')])
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          tick();
                          _setPhotoMode(m.$1).then((_) {
                            if (ctx.mounted) setSheet(() {});
                          });
                          setSheet(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _photoMode == m.$1 ? chipBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _photoMode == m.$1
                                ? [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 3, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Text(m.$2,
                              style: TextStyle(
                                  color: _photoMode == m.$1 ? ink : sub,
                                  fontSize: 13,
                                  fontWeight: _photoMode == m.$1 ? FontWeight.w800 : FontWeight.w600)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(modeHint, style: TextStyle(color: sub, fontSize: 11.5)),
            ),
            const SizedBox(height: 14),
            // 카테고리: 작은 사진 + 이름 (옆으로 넘기기)
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final on = cat == c;
                  return GestureDetector(
                    onTap: () {
                      tick();
                      cat = c;
                      manage = false;
                      if (_photoMode == 1) _setPhotoRange(c); // 랜덤이면 이 카테고리 안에서
                      setSheet(() {});
                    },
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: on ? ink : Colors.transparent, width: 2),
                            ),
                            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: coverOf(c)),
                          ),
                          const SizedBox(height: 5),
                          Text(c,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: on ? ink : sub,
                                  fontSize: 11.5,
                                  fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
"""
if a != -1 and b != -1 and a < b:
    src = src[:a] + NEW_TOP + src[b:]; print('✔ 위쪽: 자동·랜덤·고정 + 작은 사진 카테고리')
else:
    ok = False; print('❌ 위쪽 부분을 못 찾음')

rep('맨 아래: 색감',
"""                childAspectRatio: 9 / 16,
                children: tiles,
              ),
          ],
        );
      },
    );
  }

  Future<void> _saveStyle(int style) async {""",
"""                childAspectRatio: 9 / 16,
                children: tiles,
              ),
            const SizedBox(height: 14),
            // 색감은 맨 아래로
            ParanCard(
              children: [
                optionRow(Icons.palette_outlined, '색감', [
                  chip('컬러', _bgFilter == 0, () => _setBgFilter(0)),
                  chip('흑백', _bgFilter == 1, () => _setBgFilter(1)),
                  chip('세피아', _bgFilter == 2, () => _setBgFilter(2)),
                  chip('필름', _bgFilter == 3, () => _setBgFilter(3)),
                ]),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveStyle(int style) async {""")

def bal(t):
    return tuple(t.count(x) - t.count(y) for x, y in ('()', '[]', '{}'))
if ok and bal(src) != bal(orig):
    ok = False; print('❌ 괄호 짝이 안 맞아요', bal(src), bal(orig))

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
