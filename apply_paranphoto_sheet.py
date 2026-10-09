# 파란포토 사진 고르기를 "아래에서 올라오는 창"으로 바꾸기 (가사 배경 창과 같은 모양)
import os, sys

PATH = os.path.join('lib', 'screens', 'player_screen.dart')

NEW_METHOD = r'''  /// 파란포토 사진 고르기 창 (가사 배경 창과 같은 모양: 아래에서 올라오고, 사진은 3장씩 위아래로)
  void _openParanPhotoSheet() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    // 처음 열 때는 지금 배경 사진이 들어 있는 카테고리로
    String cat = '전체';
    if (_nightBgIsFile) {
      cat = '내 사진';
    } else {
      for (final e in _nightCategoryPhotos.entries) {
        if (e.value.contains(_nightBgPath)) {
          cat = e.key;
          break;
        }
      }
    }
    bool manage = false; // 내 사진 관리(✕) 모드

    showParanSheet(
      context,
      title: '파란포토',
      builder: (ctx, setSheet) {
        final dark = context.read<ThemeProvider>().isDarkMode;
        final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
        final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
        final chipBg = dark ? const Color(0xFF32302C) : Colors.white;
        final chipLine = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
        void tick() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

        // 작은 칩 (고른 것은 먹색, 다크 모드는 크림색)
        Widget chip(String label, bool on, VoidCallback onTap) => GestureDetector(
              onTap: () {
                tick();
                onTap();
                setSheet(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: on ? ink : chipBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: on ? ink : chipLine),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: on ? (dark ? const Color(0xFF17140F) : Colors.white) : sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            );

        // 카드 안 한 줄 (아이콘 · 이름 · 오른쪽 칩들)
        Widget optionRow(IconData icon, String title, List<Widget> chips) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Row(
                children: [
                  SizedBox(width: 22, child: Icon(icon, color: sub, size: 20)),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    chips[i],
                  ],
                ],
              ),
            );

        // 내 사진 지우기 (지금 배경이면 다른 사진으로)
        void removeMine(String path) {
          tick();
          setState(() {
            _nightFavPaths.remove(path);
            if (_nightBgPath == path) {
              final next = _nightFavPaths.isNotEmpty ? _nightFavPaths.first : 'assets/spring_photo1.png';
              _nightBgPath = next;
              _nightBgIsFile = !next.startsWith('assets/');
              _saveNightBg(next, isFile: _nightBgIsFile);
            }
          });
          SharedPreferences.getInstance()
              .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
          setSheet(() {});
        }

        // 사진 한 장: 누르면 배경으로 + 창 닫기, 오른쪽 위 하트는 "자동으로 바꿀 때 쓸 사진"
        Widget photoTile(String path, {bool isFile = false}) {
          final selected = _nightBgPath == path;
          final fav = _nightFavPaths.contains(path);
          return GestureDetector(
            onTap: manage
                ? null
                : () {
                    tick();
                    setState(() {
                      _nightBgPath = path;
                      _nightBgIsFile = isFile;
                    });
                    _saveNightBg(path, isFile: isFile);
                    Navigator.pop(ctx);
                  },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected && !manage ? ink : Colors.transparent, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    isFile
                        ? Image.file(File(path),
                            fit: BoxFit.cover,
                            cacheWidth: 270, // 작게 미리보기
                            errorBuilder: (_, __, ___) => Container(color: const Color(0x22000000)))
                        : paranPhoto(path, thumb: true, fit: BoxFit.cover),
                    if (selected && !manage)
                      const Positioned(
                        left: 6,
                        top: 6,
                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      ),
                    if (manage)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => removeMine(path),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: Color(0xB317140F), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    else if (!isFile)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            tick();
                            _toggleNightFav(path);
                            setSheet(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 18,
                              color: fav ? const Color(0xFFE05A4F) : Colors.white,
                              shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        // + 사진 추가 (가사 배경 창과 같은 모양)
        Widget addTile() => GestureDetector(
              onTap: () async {
                final before = _nightBgPath;
                await _pickFromGallery();
                if (!ctx.mounted) return;
                if (_nightBgPath != before) {
                  Navigator.pop(ctx);
                } else {
                  setSheet(() {});
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chipLine, width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: sub, size: 26),
                    const SizedBox(height: 4),
                    Text('사진 추가', style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );

        final cats = <String>['전체', ..._nightCategoryPhotos.keys, '내 사진'];
        final mine = _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
        final List<Widget> tiles;
        if (cat == '내 사진') {
          tiles = [if (!manage) addTile(), for (final f in mine) photoTile(f, isFile: true)];
        } else {
          final photos = cat == '전체'
              ? _nightCategoryPhotos.values.expand((e) => e).toList()
              : (_nightCategoryPhotos[cat] ?? const <String>[]);
          tiles = [for (final p in photos) photoTile(p)];
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 색감 · 자동으로 바꾸기
            ParanCard(
              children: [
                optionRow(Icons.palette_outlined, '색감', [
                  chip('컬러', _bgFilter == 0, () => _setBgFilter(0)),
                  chip('흑백', _bgFilter == 1, () => _setBgFilter(1)),
                  chip('세피아', _bgFilter == 2, () => _setBgFilter(2)),
                  chip('필름', _bgFilter == 3, () => _setBgFilter(3)),
                ]),
                optionRow(Icons.schedule_rounded, '자동 바꾸기', [
                  chip('끄기', _autoBgMin == 0, () => _setAutoBg(0)),
                  chip('10분', _autoBgMin == 10, () => _setAutoBg(10)),
                  chip('30분', _autoBgMin == 30, () => _setAutoBg(30)),
                ]),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text('하트한 사진이 2장 이상이면 그 사진들 안에서 바뀌어요',
                  style: TextStyle(color: sub, fontSize: 11.5)),
            ),
            const SizedBox(height: 16),
            // 카테고리 한 줄
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Center(
                  child: chip(cats[i], cat == cats[i], () {
                    cat = cats[i];
                    manage = false;
                  }),
                ),
              ),
            ),
            // 내 사진: 관리 / 완료
            if (cat == '내 사진' && mine.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setSheet(() => manage = !manage),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                    child: Text(manage ? '완료' : '관리',
                        style: TextStyle(
                            color: manage ? Theme.of(ctx).colorScheme.primary : sub,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (tiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text('준비 중이에요',
                    textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 13)),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 9 / 16,
                children: tiles,
              ),
          ],
        );
      },
    );
  }

'''

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        print('   프로젝트 맨 바깥 폴더(mp3_player_new)에서 실행해 주세요.')
        sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    t = raw.replace('\r\n', '\n')

    if '_openParanPhotoSheet' in t:
        print('이미 적용돼 있어요')
        return

    ok = True

    def cut(text, start, end, insert, name):
        nonlocal ok
        a = text.find(start)
        b = text.find(end, a + 1) if a >= 0 else -1
        if a < 0 or b < 0:
            print('❌', name)
            ok = False
            return text
        print('✔', name)
        return text[:a] + insert + text[b:]

    def rep(text, old, new, name):
        nonlocal ok
        if text.count(old) != 1:
            print('❌', name)
            ok = False
            return text
        print('✔', name)
        return text.replace(old, new)

    # 1) 옛 가로 줄의 색감·자동 칩 → 새 창 함수로 바꾸기
    t = cut(t, '  Widget _buildPhotoOptions() {', '  Future<void> _saveStyle(', NEW_METHOD,
            '새 사진 고르기 창 넣기')
    # 2) 옛 "내 사진 관리" 창 지우기 (새 창 안 "내 사진 → 관리"로 옮김)
    t = cut(t, '  void _showGalleryFavManager(BuildContext context) {', '  Future<void> _pickFromGallery()', '',
            '옛 내 사진 관리 창 지우기')
    # 3) 옛 가로 사진 줄 지우기
    t = cut(t, '  Widget _buildNightBgPicker() {', '  Widget _buildCDStyle(', '',
            '옛 가로 사진 줄 지우기')
    # 4) 재생화면에서 가로 줄 부르던 곳 빼기
    t = rep(t,
            '        // 사진 고르기를 제일 위에 (제목 박스에 가려서 안 눌리는 것 방지)\n        _buildNightBgPicker(),\n',
            '',
            '재생화면에서 가로 줄 빼기')
    # 5) 위쪽 사진 아이콘 → 새 창 열기
    t = rep(t,
            "              onTap: () {\n"
            "                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
            "                final open = !_showNightPicker;\n"
            "                setState(() => _showNightPicker = open);\n"
            "                SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', open));\n"
            "              },\n",
            "              onTap: _openParanPhotoSheet,\n",
            '사진 아이콘 누르면 새 창 열기')
    t = rep(t,
            "                  color: _showNightPicker ? const Color(0xFF7FB8F0) : baseColor,\n",
            "                  color: baseColor,\n",
            '사진 아이콘 색 정리')

    if not ok:
        print('\n못 찾은 곳이 있어서 아무것도 저장하지 않았어요.')
        sys.exit(1)

    if t.count('{') != t.count('}') or t.count('(') != t.count(')') or t.count('[') != t.count(']'):
        print('❌ 괄호 짝이 안 맞아요. 저장하지 않았어요.')
        sys.exit(1)

    if crlf:
        t = t.replace('\n', '\r\n')
    open(PATH, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요.')

main()
