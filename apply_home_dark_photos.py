# -*- coding: utf-8 -*-
# 다크 모드일 때 메인 홈 사진을 모두 같은 필터로 (색 반쯤 빼고 살짝 어둡게)
import io, sys
PATH = 'lib/screens/home_screen.dart'

def norm(s): return s.replace('\r\n', '\n')
raw = io.open(PATH, 'r', encoding='utf-8', newline='').read()
crlf = '\r\n' in raw
src = norm(raw)

MARK = 'Widget darkPhoto(bool dark, Widget child)'
if MARK in src:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(name, old, new, alt_old=None):
    global src, ok
    if old in src and src.count(old) == 1:
        src = src.replace(old, new); print('✔', name); return
    if alt_old and alt_old in src and src.count(alt_old) == 1:
        src = src.replace(alt_old, new); print('✔', name); return
    print('❌', name, '(찾을 코드를 못 찾음)'); ok = False

# 1) 메뉴 카드 4장 사진 (원래 코드 / 아침에 준 ColorFiltered 코드 둘 다 처리)
CAT_ORIG = """                        Image.asset(
                          c.imageAsset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.4), // 물건·사람이 위쪽에 있어서
                          cacheWidth: 600, // 화면 크기만큼만 불러오기 (램 아끼기)
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: baseColor.withOpacity(0.08),
                          ),
                        ),
"""
CAT_MORNING = """                        // 다크 모드: 사진 색을 반쯤 빼고 살짝 어둡게 (시안 2번)
                        ColorFiltered(
                          colorFilter: isDarkMode
                              ? const ColorFilter.matrix(<double>[
                                  0.4082, 0.2832, 0.0286, 0, 0,
                                  0.0842, 0.6072, 0.0286, 0, 0,
                                  0.0842, 0.2832, 0.3526, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: Image.asset(
                            c.imageAsset,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.4), // 물건·사람이 위쪽에 있어서
                            cacheWidth: 600, // 화면 크기만큼만 불러오기 (램 아끼기)
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: baseColor.withOpacity(0.08),
                            ),
                          ),
                        ),
"""
CAT_NEW = """                        darkPhoto(isDarkMode, Image.asset(
                          c.imageAsset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.4), // 물건·사람이 위쪽에 있어서
                          cacheWidth: 600, // 화면 크기만큼만 불러오기 (램 아끼기)
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: baseColor.withOpacity(0.08),
                          ),
                        )),
"""
if CAT_MORNING in src:
    rep('메뉴 카드 4장 (아침 코드 정리)', CAT_MORNING, CAT_NEW)
else:
    rep('메뉴 카드 4장', CAT_ORIG, CAT_NEW)

# 2) 잠시 쉬어가요 카드
rep('잠시 쉬어가요 카드',
"""                            paranPhoto(
                              item.$2,
                              thumb: true,
                              fit: BoxFit.cover,
                              fallback: Container(color: baseColor.withOpacity(0.08)),
                            ),
""",
"""                            darkPhoto(isDarkMode, paranPhoto(
                              item.$2,
                              thumb: true,
                              fit: BoxFit.cover,
                              fallback: Container(color: baseColor.withOpacity(0.08)),
                            )),
""")

# 3) 최근에 들었어요 사진
rep('최근에 들었어요 사진',
"""                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: thumbnail,
                                  ),
""",
"""                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: darkPhoto(isDarkMode, thumbnail),
                                  ),
""")

# 4) 오늘의 카드: 자연소리 동그라미 사진
rep('오늘의 카드 자연소리 사진',
"""        child: ClipOval(
          child: paranPhoto(
            natureImg[sound] ?? 'assets/nature_wave_bg.png',
            thumb: true,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            fallback: Container(color: softBox, child: Icon(ic, size: 18, color: ink)),
          ),
        ),
""",
"""        child: ClipOval(
          child: darkPhoto(isDark, paranPhoto(
            natureImg[sound] ?? 'assets/nature_wave_bg.png',
            thumb: true,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            fallback: Container(color: softBox, child: Icon(ic, size: 18, color: ink)),
          )),
        ),
""")

# 5) 오늘의 카드: 앨범 사진
rep('오늘의 카드 앨범 사진',
"""          child: s.albumArt != null
              ? Image.memory(Uint8List.fromList(s.albumArt!),
                  width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (size * 3).round())
              : NoArtTile(""",
"""          child: s.albumArt != null
              ? darkPhoto(isDark, Image.memory(Uint8List.fromList(s.albumArt!),
                  width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (size * 3).round()))
              : NoArtTile(""")

# 6) 함수 추가 (최근 카드 사진 함수 바로 앞)
rep('darkPhoto 함수 추가',
"""/// 최근 카드 사진 (앱 안 사진)
Widget _recentAsset(String asset) {""",
"""/// 다크 모드: 홈 사진 색을 반쯤 빼고 살짝 어둡게 (밝기 72% · 색 45%) — 메인 홈 사진 모두 같게
const ColorFilter _kDarkPhotoFilter = ColorFilter.matrix(<double>[
  0.4082, 0.2832, 0.0286, 0, 0,
  0.0842, 0.6072, 0.0286, 0, 0,
  0.0842, 0.2832, 0.3526, 0, 0,
  0, 0, 0, 1, 0,
]);
Widget darkPhoto(bool dark, Widget child) =>
    dark ? ColorFiltered(colorFilter: _kDarkPhotoFilter, child: child) : child;

/// 최근 카드 사진 (앱 안 사진)
Widget _recentAsset(String asset) {""")

if not ok:
    print('\\n아무것도 저장하지 않았어요. 지금 파일을 다시 보내 주세요.'); sys.exit(1)
out = src.replace('\n', '\r\n') if crlf else src
io.open(PATH, 'w', encoding='utf-8', newline='').write(out)
print('\n저장했어요 ✔')
