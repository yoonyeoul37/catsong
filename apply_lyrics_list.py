# 파란소리: 가사 배경 목록 파일(list.json)로 바꾸기 — 사진 빼기·넣기를 앱 업데이트 없이
# 실행: C:\apps\mp3_player_new 에서  python apply_lyrics_list.py
import os, sys, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
ROOT = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(ROOT, "lib", "screens", "lyrics_screen.dart")
if not os.path.exists(P):
    print("[실패] lib/screens/lyrics_screen.dart 를 못 찾았어요.")
    sys.exit(1)
with open(P, "r", encoding="utf-8", newline="") as f:
    raw = f.read()
nl = "\r\n" if "\r\n" in raw else "\n"
s = raw.replace("\r\n", "\n")
if "_loadBgList" in s:
    print("[참고] 이미 바뀌어 있어요. 그대로 둘게요.")
    sys.exit(0)
CONST = r"""/// 가사 배경 사진 (수파베이스 app-images/lyrics) — 목록은 list.json 으로 앱 업데이트 없이 바꿀 수 있어요
const _kLyricsBgBase =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images/lyrics';

class _LyricsBg {
  final String file;
  final bool light; // 밝은 사진 → 가사를 먹색으로
  final bool busy; // 화려한 사진 → 위에 크림색 막을 조금 더
  const _LyricsBg(this.file, {this.light = false, this.busy = false});
}

/// 기본 목록 (인터넷 목록을 아직 못 받았을 때)
const _kDefaultBgs = <_LyricsBg>[
  _LyricsBg('lyrics_bg_1.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_3.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_5.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_7.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_8.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_10.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_12.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_13.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_14.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_15.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_16.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_17.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_18.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_19.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_20.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_21.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_22.jpg', light: true, busy: false),
  _LyricsBg('lyrics_bg_23.jpg', light: false, busy: false),
  _LyricsBg('lyrics_bg_24.jpg', light: true, busy: true),
  _LyricsBg('lyrics_bg_25.jpg', light: false, busy: false),
];

List<_LyricsBg> _bgs = _kDefaultBgs; // 지금 쓰는 목록 (list.json 받으면 바뀜)
int get _kLyricsBgCount => _bgs.length;
Set<int> get _kLightBgs => {for (var i = 0; i < _bgs.length; i++) if (_bgs[i].light) i + 1};
Set<int> get _kBusyBgs => {for (var i = 0; i < _bgs.length; i++) if (_bgs[i].busy) i + 1};
String _bgUrl(int i) => '$_kLyricsBgBase/${_bgs[(i - 1).clamp(0, _bgs.length - 1)].file}';
"""
INIT = r"""    _loadBgList(); // 인터넷 목록 받기 (못 받으면 기본 목록)
    SharedPreferences.getInstance().then((p) {
      // 고른 사진은 파일 이름으로 기억 (예전 번호로 저장한 것도 알아보기)
      final old = p.getInt('lyricsBg');
      final f = p.getString('lyricsBgFile') ?? (old != null ? 'lyrics_bg_$old.jpg' : null);
      if (f == null || !mounted) return;
      final i = _bgs.indexWhere((b) => b.file == f);
      if (i >= 0) {
        _lastBg = i + 1;
        if (_lastBg != _bg) setState(() => _bg = _lastBg!);
      }
    });"""
METHODS = r"""  /// 수파베이스 list.json 받기 → 사진 빼기·넣기·순서를 앱 업데이트 없이
  Future<void> _loadBgList() async {
    final p = await SharedPreferences.getInstance();
    List<_LyricsBg>? parse(String? s) {
      if (s == null) return null;
      try {
        final list = (jsonDecode(s) as Map)['photos'] as List;
        return [
          for (final m in list.cast<Map>())
            if ((m['file'] ?? '').toString().isNotEmpty)
              _LyricsBg(m['file'].toString(), light: m['text'] == 'dark', busy: m['busy'] == true),
        ];
      } catch (_) {
        return null;
      }
    }

    final cached = parse(p.getString('lyricsBgList'));
    if (cached != null && cached.isNotEmpty) _applyBgList(cached);
    try {
      final r = await http.get(Uri.parse('$_kLyricsBgBase/list.json')).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final body = utf8.decode(r.bodyBytes);
        final l = parse(body);
        if (l != null && l.isNotEmpty) {
          await p.setString('lyricsBgList', body);
          _applyBgList(l);
        }
      }
    } catch (_) {}
  }

  /// 새 목록으로 바꾸기 (고른 사진은 그대로 유지, 목록에서 빠졌으면 첫 번째로)
  void _applyBgList(List<_LyricsBg> l) {
    final curFile = _bgs[(_bg - 1).clamp(0, _bgs.length - 1)].file;
    _bgs = l;
    final i = _bgs.indexWhere((b) => b.file == curFile);
    final n = i >= 0 ? i + 1 : 1;
    _lastBg = n;
    if (mounted) setState(() => _bg = n);
  }

"""
def fail(msg):
    print("[실패]", msg, "— 아무것도 안 바꿨어요. 이 메시지를 보내주세요.")
    sys.exit(1)
# ① 맨 위 사진 정보 → 목록 방식
a = s.find("/// 가사 배경 사진 (수파베이스 app-images/lyrics)")
b = s.find("String _bgUrl(int i)")
if a < 0 or b < 0: fail("사진 정보 자리를 못 찾았어요")
b = s.find("\n", b) + 1
s = s[:a] + CONST + s[b:]
# ② 고른 사진 불러오기 (번호 → 파일 이름)
a = s.find("SharedPreferences.getInstance().then((p) {")
if a < 0: fail("고른 사진 불러오는 곳을 못 찾았어요")
ls = s.rfind("\n", 0, a) + 1
j = s.find("{", a); d = 0; k = j
while True:
    c = s[k]
    if c == "{": d += 1
    elif c == "}":
        d -= 1
        if d == 0: break
    k += 1
e = s.find(";", k) + 1  # "});"
s = s[:ls] + INIT + s[e:]
# ③ 고를 때 파일 이름으로 저장
old = "await p.setInt('lyricsBg', i);"
if old not in s: fail("배경 저장하는 줄을 못 찾았어요")
s = s.replace(old, "await p.setString('lyricsBgFile', _bgs[(i - 1).clamp(0, _bgs.length - 1)].file);")
# ④ 목록 받는 함수 넣기
m = s.find("  /// 🖼 배경 고르기 창")
if m < 0: fail("배경 고르기 창을 못 찾았어요")
s = s[:m] + METHODS + s[m:]
# ⑤ 필요한 것들
if "static int? _lastBg" not in s:
    s = s.replace("  final ScrollController _scrollController = ScrollController();\n",
                  "  final ScrollController _scrollController = ScrollController();\n  static int? _lastBg;\n", 1)
if "import 'dart:convert';" not in s:
    s = "import 'dart:convert';\n" + s
if "package:http/http.dart" not in s:
    s = s.replace("import 'package:shared_preferences/shared_preferences.dart';\n",
                  "import 'package:shared_preferences/shared_preferences.dart';\nimport 'package:http/http.dart' as http;\n", 1)
B = os.path.join(ROOT, "backup_lyrics_list", "screens")
os.makedirs(B, exist_ok=True)
shutil.copy2(P, os.path.join(B, "lyrics_screen.dart"))
with open(P, "w", encoding="utf-8", newline="") as f:
    f.write(s.replace("\n", nl) if nl == "\r\n" else s)
print("[완료] 바꿨어요: screens/lyrics_screen.dart")
print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
print("   문제가 있으면 backup_lyrics_list 폴더의 원본으로 되돌릴 수 있어요.")
