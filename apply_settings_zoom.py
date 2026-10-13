# -*- coding: utf-8 -*-
# 설정 화면에 돋보기 (기본 → 크게 → 아주 크게) — 설정 도움말과 같은 크기·같이 기억
import os, sys, shutil

NAME = 'settings_screen.dart'
path = None
for root, _, files in os.walk('lib'):
    if NAME in files:
        path = os.path.join(root, NAME)
        break
if not path:
    print('❌ lib 폴더에서 %s 를 못 찾았어요' % NAME); sys.exit(1)

raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')
if '_nextZoom' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

EDITS = [
('돋보기 크기 기억·바꾸기',
"""  bool _isSosOn = false;
""",
"""  bool _isSosOn = false;

  // 돋보기: 설정 글자만 크게 (기본 → 크게 → 아주 크게) — 설정 도움말과 같은 크기를 같이 기억
  static const _zoomLevels = [1.0, 1.2, 1.4];
  static const _zoomNames = ['기본', '크게', '아주 크게'];
  double _zoom = 1.0;

  int get _zoomIndex {
    var best = 0;
    for (var i = 0; i < _zoomLevels.length; i++) {
      if ((_zoomLevels[i] - _zoom).abs() < (_zoomLevels[best] - _zoom).abs()) best = i;
    }
    return best;
  }

  void _nextZoom() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    _hideBubble();
    final next = _zoomLevels.firstWhere((l) => l > _zoom + 0.01, orElse: () => _zoomLevels.first);
    setState(() => _zoom = next);
    SharedPreferences.getInstance().then((p) => p.setDouble('helpZoom', next));
  }
"""),
('들어올 때 기억한 크기 불러오기',
"""    HomeCardPref.load();
  }""",
"""    HomeCardPref.load();
    SharedPreferences.getInstance().then((p) {
      final z = p.getDouble('helpZoom');
      if (z != null && mounted) setState(() => _zoom = z.clamp(1.0, 1.6));
    });
  }"""),
('오른쪽 위 돋보기 버튼',
"""        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _sBorder(isDarkMode))),
      ),
      body: SafeArea(""",
"""        actions: [
          // 돋보기: 기본 → 크게 → 아주 크게 (설정 도움말과 같은 모양)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _nextZoom,
              style: TextButton.styleFrom(
                foregroundColor: _sText(isDarkMode),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(48, 40),
              ),
              icon: Icon(_zoomIndex == _zoomLevels.length - 1 ? Icons.zoom_out_rounded : Icons.zoom_in_rounded, size: 22),
              label: Text(_zoomNames[_zoomIndex],
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _sBorder(isDarkMode))),
      ),
      body: SafeArea("""),
('목록 글자 크게 (시작)',
"""        child: ListView(
        padding: const EdgeInsets.only(bottom: 16),""",
"""        // 이 화면 글자만 크게 (앱 전체 글자 크기 × 돋보기)
        child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaler.scale(1) * _zoom)),
        child: ListView(
        padding: const EdgeInsets.only(bottom: 16),"""),
('목록 글자 크게 (끝)',
"""          Center(child: Text('KNEXM.Co.,LTD', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
          const SizedBox(height: 8),
        ],
      ),
      ),""",
"""          Center(child: Text('KNEXM.Co.,LTD', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
          const SizedBox(height: 8),
        ],
      ),
      ),
      ),"""),
('도움말에서 바꾼 크기도 돌아오면 반영',
"""              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen())),""",
"""              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen()))
                  .then((_) => SharedPreferences.getInstance().then((p) {
                        final z = p.getDouble('helpZoom');
                        if (z != null && mounted) setState(() => _zoom = z.clamp(1.0, 1.6));
                      })),"""),
]

ok = True
for label, old, new in EDITS:
    n = src.count(old)
    if n != 1:
        print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
    src = src.replace(old, new)
    print('✔ %s' % label)
if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)

shutil.copyfile(path, path + '.bak')
out = src.replace('\n', '\r\n') if crlf else src
open(path, 'wb').write(out.encode('utf-8'))
print('\n저장했어요: %s (원본은 .bak)' % path)
