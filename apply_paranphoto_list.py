# -*- coding: utf-8 -*-
# 파란포토 사진 목록을 R2(app-images/paranphoto/list.json)에서 받아 쓰기
#  → 앞으로 사진 추가는 R2에 올리고 list.json에 번호만 더하면 끝 (앱 업데이트 필요 없음)
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

def find(name):
    for root, dirs, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

def load(name):
    p = find(name)
    if not p:
        print('❌', name, '못 찾음 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    return p, raw.replace('\r\n', '\n'), '\r\n' in raw

pp, p, pcrlf = load('paran_photo.dart')
sp, s, scrlf = load('player_screen.dart')

if 'class ParanPhotoList' in p and 'ParanPhotoList.of(' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(txt, label, old, new):
    global ok
    n = txt.count(old)
    if n != 1:
        print('❌', label, '(찾은 개수 %d)' % n); ok = False; return txt
    print('✔', label)
    return txt.replace(old, new)

# ── paran_photo.dart ──
p = rep(p, 'paran_photo.dart: 필요한 import',
    "import 'package:cached_network_image/cached_network_image.dart';\n",
    "import 'package:cached_network_image/cached_network_image.dart';\n"
    "import 'dart:convert';\n"
    "import 'package:http/http.dart' as http;\n"
    "import 'package:shared_preferences/shared_preferences.dart';\n")

LIST_CLASS = r'''

/// 파란포토 사진 목록 — R2(app-images/paranphoto/list.json)에서 받아 씀
///  · 사진 추가: R2 app-images/paranphoto 에 번호.jpg + 번호_thumb.jpg 올리고 list.json에 번호만 추가 (앱 업데이트 필요 없음)
///  · list.json 모양: {"파란포토": ["001", "002"]}  (묶음을 더 만들면 사진 고르기 창에 카테고리 칩이 생김)
///                    또는 그냥 ["001", "002"]
///  · 인터넷이 안 되면 마지막으로 받은 목록 → 그것도 없으면 앱 안 기본 목록(001~010)
class ParanPhotoList {
  static const _url = '$_paranBase/paranphoto/list.json';
  static const _prefKey = 'paranPhotoListJson';
  static Map<String, List<String>>? _list;
  static bool _fetched = false;

  /// 지금 쓸 목록 (받은 게 없으면 앱 안 기본 목록)
  static Map<String, List<String>> of(Map<String, List<String>> builtin) => _list ?? builtin;

  static Map<String, List<String>>? _parse(String body) {
    try {
      final j = jsonDecode(body);
      String path(Object? n) {
        final v = n is int ? n.toString().padLeft(3, '0') : n.toString().trim();
        return 'assets/paranphoto/$v.png';
      }
      final out = <String, List<String>>{};
      if (j is List) {
        final l = [for (final n in j) path(n)];
        if (l.isNotEmpty) out['파란포토'] = l;
      } else if (j is Map) {
        j.forEach((k, v) {
          if (v is List && v.isNotEmpty) out[k.toString()] = [for (final n in v) path(n)];
        });
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null; // 목록 파일이 잘못돼도 앱은 그대로 (기본 목록)
    }
  }

  /// 지난번에 받은 목록 먼저 (재생 화면 설정 불러올 때)
  static void readCache(SharedPreferences prefs) {
    if (_list != null) return;
    final s = prefs.getString(_prefKey);
    if (s != null) _list = _parse(s);
  }

  /// 새 목록 받기 (앱 켜고 한 번만) — 목록이 바뀌었으면 true
  static Future<bool> refresh() async {
    if (_fetched) return false;
    _fetched = true;
    try {
      // 한 시간마다 주소를 살짝 바꿔서 예전 목록이 캐시에 남아 있지 않게
      final hour = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
      final r = await http.get(Uri.parse('$_url?h=$hour')).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) {
        _fetched = false;
        return false;
      }
      final body = utf8.decode(r.bodyBytes);
      final parsed = _parse(body);
      if (parsed == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final changed = prefs.getString(_prefKey) != body || _list == null;
      await prefs.setString(_prefKey, body);
      _list = parsed;
      return changed;
    } catch (_) {
      _fetched = false; // 다음에 재생 화면 열 때 다시
      return false;
    }
  }
}
'''
if ok:
    p = p.rstrip('\n') + '\n' + LIST_CLASS
    print('✔ paran_photo.dart: 사진 목록 받기 추가')

# ── player_screen.dart ──
s = rep(s, 'player_screen.dart: 안내 주석',
    "  //  · 사진 추가: R2에 큰 사진·작은 사진(_thumb)을 올리고 아래 묶음에 한 줄 추가\n",
    "  //  · 사진 추가: R2에 큰 사진·작은 사진(_thumb)을 올리고 R2 paranphoto/list.json에 번호만 추가 (앱 업데이트 필요 없음)\n"
    "  //    아래 묶음은 목록을 못 받았을 때 쓰는 기본 목록\n")
s = rep(s, 'player_screen.dart: 앱 안 기본 목록 이름 바꾸기',
    "  static const Map<String, List<String>> _nightCategoryPhotos = {\n",
    "  static const Map<String, List<String>> _builtinPhotos = {\n")
s = rep(s, 'player_screen.dart: R2 목록 쓰기',
    "    ],\n  };\n  Color _dominantColor = const Color(0xFF1A1A1A);\n",
    "    ],\n  };\n"
    "  // 지금 쓸 사진 목록: R2에서 받은 것 (없으면 위 기본 목록)\n"
    "  static Map<String, List<String>> get _nightCategoryPhotos => ParanPhotoList.of(_builtinPhotos);\n"
    "  Color _dominantColor = const Color(0xFF1A1A1A);\n")
s = rep(s, 'player_screen.dart: 지난번 목록 먼저 읽기',
    "    final shown = false;\n",
    "    final shown = false;\n"
    "    ParanPhotoList.readCache(prefs); // 지난번에 받은 사진 목록 먼저 (새 사진 고른 사람 그대로)\n")
s = rep(s, 'player_screen.dart: 새 목록 받기',
    "    _loadStyle();\n",
    "    _loadStyle();\n"
    "    // 새 사진 목록 받기 (앱 켜고 한 번만) — 바뀌었으면 화면 다시\n"
    "    ParanPhotoList.refresh().then((changed) {\n"
    "      if (changed && mounted) setState(() {});\n"
    "    });\n")

def brackets(txt, name):
    global ok
    t = re.sub(r"'''.*?'''", "''", txt, flags=re.S)
    t = re.sub(r"r?'(?:\\.|[^'\\\n])*'", "''", t)
    t = re.sub(r'r?"(?:\\.|[^"\\\n])*"', '""', t)
    t = re.sub(r'//[^\n]*', '', t)
    for a, b in ('()', '[]', '{}'):
        if t.count(a) != t.count(b):
            print('❌ 괄호 안 맞음', name, a, t.count(a), t.count(b)); ok = False
brackets(p, 'paran_photo.dart')
brackets(s, 'player_screen.dart')

if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)
for path, txt, crlf in ((pp, p, pcrlf), (sp, s, scrlf)):
    if crlf: txt = txt.replace('\n', '\r\n')
    open(path, 'wb').write(txt.encode('utf-8'))
    print('✔ 저장:', os.path.basename(path))
