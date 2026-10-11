# -*- coding: utf-8 -*-
# 내 사진(파란포토 · 가사 배경): '세로 사진 추천' 안내 + 가로 사진 고르면 한 번 짧게 알려 주기
import sys, glob, os, shutil

def find(name):
    hits = [h for h in glob.glob(os.path.join('lib', '**', name), recursive=True) if os.path.basename(h) == name]
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

TILE_OLD = """                    Text('사진 추가', style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],"""
TILE_NEW = """                    Text('사진 추가', style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text('세로 사진 추천', style: TextStyle(color: sub.withOpacity(0.75), fontSize: 9.5)),
                  ],"""

def warn_fn(codec_call):
    return f"""  /// 가로 사진을 골랐으면 한 번만 짧게 알려 주기 (사진은 그대로 들어가요)
  Future<void> _warnIfLandscape(List<String> paths) async {{
    for (final path in paths) {{
      try {{
        final codec = await {codec_call}(await File(path).readAsBytes(), targetWidth: 64);
        final frame = await codec.getNextFrame();
        final landscape = frame.image.width > frame.image.height * 1.05;
        frame.image.dispose();
        codec.dispose();
        if (landscape) {{
          if (mounted) showParanToast(context, '가로 사진은 가운데 부분만 보여요. 세로로 찍은 사진이 가장 잘 어울려요');
          return;
        }}
      }} catch (_) {{}}
    }}
  }}

"""

player = [
('사진 추가 칸: 세로 사진 추천', TILE_OLD, TILE_NEW),
('가로 사진 알림 (파란포토)',
"""    _saveNightBg(first, isFile: true);
  }

  Future<void> _extractColor(""",
"""    _saveNightBg(first, isFile: true);
    _warnIfLandscape([for (final f in picked) f.path]);
  }

""" + warn_fn('instantiateImageCodec') + """  Future<void> _extractColor("""),
]

lyrics = [
('사진 추가 칸: 세로 사진 추천', TILE_OLD, TILE_NEW),
('가로 사진 알림 (가사 배경)',
"""    await _useMyPhoto(picked.first.path);
    setSheet(() {});
  }
""",
"""    await _useMyPhoto(picked.first.path);
    setSheet(() {});
    _warnIfLandscape([for (final f in picked) f.path]);
  }

""" + warn_fn('ui.instantiateImageCodec').rstrip('\n') + "\n"),
]

jobs = [
    prepare(find('player_screen.dart'), player, '_warnIfLandscape'),
    prepare(find('lyrics_screen.dart'), lyrics, '_warnIfLandscape'),
]
for r in jobs:   # 둘 다 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak_photo')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_photo)')
