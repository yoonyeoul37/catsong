# 파란포토 새 사진 10장으로 바꾸기 (사진은 클라우드플레어 R2: app-images/paranphoto 폴더)
#  - 옛 사진(봄·여름·가을·겨울·감성·동물·사랑·기타) 목록 → 새 사진 한 묶음
#  - 지금은 카테고리 하나라 사진 고르기 창에 카테고리 칩은 안 보임 (전체 · 내 사진 · 고른 사진만)
#    나중에 카테고리를 나누면 묶음만 더 만들면 칩이 저절로 생김
#  - 예전 사진을 골라 둔 사람(배경·하트·고른 사진)은 새 사진으로 자동 정리 (내 사진은 그대로)
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")
COUNT = 10


def one(name):
    hits = []
    for d, dirs, files in os.walk(os.path.join(ROOT, "lib")):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        if name in files:
            hits.append(os.path.normpath(os.path.join(d, name)))
    if len(hits) != 1:
        print(f"❌ {name} 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
        sys.exit(1)
    return hits[0]


def read(p):
    raw = open(p, "rb").read().decode("utf-8")
    return raw.replace("\r\n", "\n"), "\r\n" in raw


ps = one("player_screen.dart")
pp = one("paran_photo.dart")
st = one("song_list_tile.dart")
ps_s, ps_c = read(ps)
pp_s, pp_c = read(pp)
st_s, st_c = read(st)

if "assets/paranphoto/001.png" in ps_s:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(src, old, new, what):
    global ok
    if src.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {src.count(old)}곳)")
        ok = False
        return src
    print(f"✔ {what}")
    return src.replace(old, new)


# 1. 옛 사진 목록 → 새 사진 한 묶음
a = ps_s.find("  static const Map<String, String> _nightCategoryCover = {")
b = ps_s.find("  Color _dominantColor = const Color(0xFF1A1A1A);")
if a < 0 or b < 0 or b < a or "'기타': [" not in ps_s[a:b]:
    print("❌ player_screen.dart: 옛 사진 목록을 못 찾았어요")
    ok = False
else:
    photos = "\n".join(f"      'assets/paranphoto/{i:03d}.png'," for i in range(1, COUNT + 1))
    ps_s = ps_s[:a] + f"""  // ───── 파란포토 사진 (클라우드플레어 R2: app-images/paranphoto/001.jpg + 001_thumb.jpg) ─────
  //  · 이름은 'assets/paranphoto/번호.png'로 적으면 paran_photo.dart가 R2에서 받아와요
  //  · 사진 추가: R2에 큰 사진·작은 사진(_thumb)을 올리고 아래 묶음에 한 줄 추가
  //  · 카테고리 나누기: '비 오는 날': [...] 처럼 묶음을 더 만들면 사진 고르기 창에 칩이 저절로 생겨요
  //    (묶음이 하나뿐이면 칩은 안 보이고 전체 · 내 사진 · 고른 사진만)
  static const String _paranDefault = 'assets/paranphoto/001.png'; // 처음 쓰는 사람 기본 사진
  static const Map<String, String> _nightCategoryCover = {{}}; // 카테고리 칩 사진 (비우면 그 묶음 첫 사진)

  static const Map<String, List<String>> _nightCategoryPhotos = {{
    '파란포토': [
{photos}
    ],
  }};
""" + ps_s[b:]
    print("✔ player_screen.dart: 사진 목록을 새 사진 10장으로")

# 2. 기본 사진 (처음 쓰는 사람 · 내 사진 지웠을 때)
ps_s = rep(ps_s, "      _nightBgPath = prefs.getString('nightBgPath') ?? 'assets/spring_photo1.png';\n",
           "      _nightBgPath = prefs.getString('nightBgPath') ?? _paranDefault;\n",
           "player_screen.dart: 처음 기본 사진")
ps_s = rep(ps_s, "              final next = _nightFavPaths.isNotEmpty ? _nightFavPaths.first : 'assets/spring_photo1.png';\n",
           "              final next = _nightFavPaths.isNotEmpty ? _nightFavPaths.first : _paranDefault;\n",
           "player_screen.dart: 내 사진 지웠을 때 기본 사진")

# 3. 예전 사진을 골라 둔 사람 → 새 사진으로 정리
ps_s = rep(ps_s, """  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = false;
""", """  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = false;
    var fixedOld = false; // 예전 사진(봄·여름…)을 정리했는지
""", "player_screen.dart: 예전 사진 정리 준비")
ps_s = rep(ps_s, """      _photoPicks = picks != null ? picks.toSet() : _nightFavPaths.where((p) => p.startsWith('assets/')).toSet();
      _styleLoaded = true;
    });
""", """      _photoPicks = picks != null ? picks.toSet() : _nightFavPaths.where((p) => p.startsWith('assets/')).toSet();
      // 예전 사진은 없어졌으니 정리 (배경 → 새 기본 사진, 하트·고른 사진에서는 빼기 / 내 사진은 그대로)
      final all = _nightCategoryPhotos.values.expand((e) => e).toSet();
      bool gone(String p) => p.startsWith('assets/') && !all.contains(p) && p != 'assets/music_night_bg.png';
      if (!_nightBgIsFile && gone(_nightBgPath)) {
        _nightBgPath = _paranDefault;
        fixedOld = true;
      }
      final favBefore = _nightFavPaths.length, picksBefore = _photoPicks.length;
      _nightFavPaths.removeWhere(gone);
      _photoPicks.removeWhere(gone);
      if (_nightFavPaths.length != favBefore || _photoPicks.length != picksBefore) fixedOld = true;
      if (_photoRange.isNotEmpty &&
          !['전체', '하트', '내 사진', '고른 사진', ..._nightCategoryPhotos.keys].contains(_photoRange)) {
        _photoRange = '';
        fixedOld = true;
      }
      _styleLoaded = true;
    });
    if (fixedOld) {
      await prefs.setString('nightBgPath', _nightBgPath);
      await prefs.setStringList('nightFavPaths', _nightFavPaths.toList());
      await prefs.setStringList('paranPhotoPicks', _photoPicks.toList());
      await prefs.setString('paranPhotoRange', _photoRange);
    }
""", "player_screen.dart: 예전 사진 고른 사람은 새 사진으로")

# 4. 카테고리가 하나뿐이면 칩 숨기기
ps_s = rep(ps_s,
           "        final cats = <String>['전체', '내 사진', if (picksNow.isNotEmpty) '고른 사진', ..._nightCategoryPhotos.keys];\n",
           "        // 카테고리 묶음이 둘 이상일 때만 칩으로 (하나뿐이면 '전체'와 같아서 숨김)\n"
           "        final cats = <String>['전체', '내 사진', if (picksNow.isNotEmpty) '고른 사진',\n"
           "          if (_nightCategoryPhotos.length > 1) ..._nightCategoryPhotos.keys];\n",
           "player_screen.dart: 카테고리 하나면 칩 숨기기")

# 5. paran_photo.dart: paranphoto/ 로 시작하는 사진도 R2에서 받기
pp_s = rep(pp_s, "  'rest_radio_',\n];", "  'rest_radio_',\n  'paranphoto/', // 파란포토 새 사진 (app-images/paranphoto)\n];",
           "paran_photo.dart: 새 사진은 R2에서 받기")
if "files.ssing.kr" not in pp_s:
    print("❌ paran_photo.dart 가 아직 수파베이스 주소예요 — 먼저 apply_r2_urls.py 를 실행해 주세요")
    ok = False

# 5-2. song_list_tile.dart: 재생화면 사진을 읽는 곳도 새 사진으로 (옛 사진이 저장돼 있으면 새 기본 사진)
st_s = rep(st_s, "final bgPath = prefs.getString('nightBgPath') ?? 'assets/spring_photo1.png';",
           "final savedBg = prefs.getString('nightBgPath'); // 예전 사진(봄·여름…)이면 새 기본 사진으로\n"
           "    final bgPath = (savedBg == null ||\n"
           "            RegExp(r'^assets/(spring|summer|autumn|winter|mood|animal|love|etc)_').hasMatch(savedBg))\n"
           "        ? 'assets/paranphoto/001.png'\n"
           "        : savedBg;",
           "song_list_tile.dart: 재생화면 사진 기본값도 새 사진으로")

# 6. 다른 파일에 옛 사진 이름이 남아 있는지
OLDS = ("spring_photo", "summer_photo", "autumn_photo", "winter_photo",
        "mood_photo", "animal_photo", "love_photo", "etc_photo")
for nm, src in (("player_screen.dart", ps_s), ("song_list_tile.dart", st_s)):
    if any(o in src for o in OLDS):
        print(f"❌ {nm} 에 옛 사진 이름이 남아 있어요")
        ok = False
for d, dirs, files in os.walk(os.path.join(ROOT, "lib")):
    dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
    for n in files:
        p = os.path.normpath(os.path.join(d, n))
        if not n.endswith(".dart") or p in (ps, pp, st):
            continue
        s = open(p, "rb").read().decode("utf-8", "ignore")
        for i, line in enumerate(s.splitlines(), 1):
            if any(o in line for o in OLDS):
                print(f"❌ {os.path.relpath(p, ROOT)} {i}줄에 옛 사진 이름: {line.strip()[:100]}")
                ok = False

if ps_s.count("{") != ps_s.count("}") or ps_s.count("(") != ps_s.count(")") or ps_s.count("[") != ps_s.count("]"):
    print("❌ player_screen.dart: 괄호 짝이 안 맞아요")
    ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)

for p, s, c in ((ps, ps_s, ps_c), (pp, pp_s, pp_c), (st, st_s, st_c)):
    if c:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
