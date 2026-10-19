# -*- coding: utf-8 -*-
# 해외 라디오: 점검해서 확실히 안 나온 방송은 목록에서 빼기
# 빼는 목록은 R2(files.ssing.kr/radio/block.json)에서 받아 옴 → 앱 업데이트 없이 목록만 바꾸면 됨
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'providers', 'radio_provider.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_isBlocked(' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

def rep(name, old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)

rep('앱 켤 때 빼는 목록 받기',
"""    _loadFromPrefs();
    loadSavedSongs();""",
"""    _loadFromPrefs();
    loadSavedSongs();
    _loadBlocklist(); // 안 나오는 해외 방송 목록""")

rep('빼는 목록 받기·확인',
"""  Future<void> _initAudioSession() async {""",
"""  // ── 안 나오는 해외 방송 빼기 (두 번 점검해서 확실히 안 나온 방송 · 백신이 막는 주소) ──
  Set<String> _blockedUuids = {};
  List<String> _blockedDomains = [];
  static const _blockUrl = 'https://files.ssing.kr/radio/block.json';

  bool _isBlocked(RadioStation s) {
    if (_blockedUuids.contains(s.stationUuid)) return true;
    if (_blockedDomains.isEmpty) return false;
    for (final u in [s.streamUrl, s.urlResolved ?? '']) {
      final host = (Uri.tryParse(u)?.host ?? '').toLowerCase();
      if (host.isEmpty) continue;
      if (_blockedDomains.any((d) => host == d || host.endsWith('.$d'))) return true;
    }
    return false;
  }

  void _applyBlock(String body) {
    final j = json.decode(body) as Map<String, dynamic>;
    _blockedUuids = {for (final u in (j['uuids'] as List? ?? [])) u.toString()};
    _blockedDomains = [for (final d in (j['domains'] as List? ?? [])) d.toString().toLowerCase()];
  }

  /// 저장해 둔 목록 먼저 (인터넷 없어도) → 새 목록 받으면 바꿔 끼우고 저장
  Future<void> _loadBlocklist() async {
    final p = await SharedPreferences.getInstance();
    try {
      final cached = p.getString('radio_block_json');
      if (cached != null) _applyBlock(cached);
    } catch (_) {}
    try {
      final r = await http.get(Uri.parse(_blockUrl)).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        _applyBlock(r.body);
        await p.setString('radio_block_json', r.body);
      }
    } catch (_) {}
  }

  Future<void> _initAudioSession() async {""")

# 나라별 목록 · 지역 목록
n_before = s
s2, n = re.subn(r'(final s = RadioStation\.fromJson\(m\);\n(\s*)if \(s\.streamUrl\.isEmpty\) continue;)',
                lambda m: m.group(1) + '\n' + m.group(2) + 'if (_isBlocked(s)) continue; // 안 나오는 방송 빼기', s)
if n != 2:
    print(f'❌ 나라별·지역 목록 — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
s = s2; print('✔ 나라별·지역 목록에서 빼기')

rep('방송사·검색 목록에서 빼기',
"""              .where((s) => s.streamUrl.isNotEmpty)""",
"""              .where((s) => s.streamUrl.isNotEmpty && !_isBlocked(s))""", count=2)

if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
