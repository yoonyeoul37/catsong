# 버그: 전체 즐겨찾기 → 자연 탭에서 소리가 안 나던 것 (옛날 앱 안 주소 → 자연소리 목록과 같은 목록 쓰기)
import re, sys

PATH = "lib/screens/all_favorites_screen.dart"

NEW_LIST = """  // 자연소리 화면과 같은 목록(nature_sound_catalog)에서 가져오기
  // → 클라우드 주소·새로 생긴 소리(잔잔한 파도 등)가 자동으로 같이 따라와요
  static const _categoryColors = <String, Color>{
    '파도소리': Color(0xFF4A7BA6),
    '빗소리': Color(0xFF3E5A78),
    '새소리': Color(0xFF5C7A5E),
    '모닥불': Color(0xFFC97B4A),
    '시냇물': Color(0xFF2C6BB3),
  };
  static final _natureSoundData = <Map<String, dynamic>>[
    for (final s in natureSoundCatalog)
      if (s.isReady)
        {
          'name': s.name,
          'icon': s.icon,
          'color': _categoryColors[s.category] ?? const Color(0xFF3E9C7E),
          'description': s.description,
          'assetPath': s.assetPath,
        },
  ];
"""

try:
    raw = open(PATH, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({PATH})")
    sys.exit(1)
crlf = "\r\n" in raw
t = raw.replace("\r\n", "\n")

if "static final _natureSoundData" in t:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
IMP_OLD = "import 'nature_sound_detail_screen.dart';\n"
IMP_NEW = "import 'nature_sound_detail_screen.dart';\nimport '../utils/nature_sound_catalog.dart';\n"
if t.count(IMP_OLD) == 1:
    t = t.replace(IMP_OLD, IMP_NEW)
    print("✔ 자연소리 목록 불러오기")
else:
    print("❌ import 자리 못 찾음"); ok = False

t2, n = re.subn(r"  static const _natureSoundData = <Map<String, dynamic>>\[\n.*?\n  \];\n", lambda m: NEW_LIST, t, count=1, flags=re.S)
if n == 1 and "assets/wave_sound.mp3" not in t2:
    t = t2
    print("✔ 옛날 목록(앱 안 주소 5개) → 자연소리 전체 목록")
else:
    print("❌ 옛날 목록 못 찾음"); ok = False

if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
    print("❌ 괄호 짝이 안 맞아요"); ok = False
if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if crlf:
    t = t.replace("\n", "\r\n")
open(PATH, "wb").write(t.encode("utf-8"))
print("완료")
