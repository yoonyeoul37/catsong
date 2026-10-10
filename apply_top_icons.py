# -*- coding: utf-8 -*-
# 재생 화면 · 가사 화면 위쪽 아이콘: 사진기(부드러운 선) · 전파 · 점 3개(둥근)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

FILES = {
'lib/screens/player_screen.dart': ('CupertinoIcons.camera,\n                  color: baseColor,', [
('사진 → 사진기',
"""                child: Icon(
                  Icons.photo_outlined,
                  color: baseColor,
                  size: 20,
                ),""",
"""                child: Icon(
                  CupertinoIcons.camera,
                  color: baseColor,
                  size: 21,
                ),"""),
('TV → 전파 (위쪽)',
"""                    cast.isConnected ? Icons.cast_connected : Icons.cast,
                    color: cast.isConnected ? const Color(0xFF7FB8F0) : baseColor,
                    size: 20,""",
"""                    Icons.sensors_rounded, // 연결되면 하늘색
                    color: cast.isConnected ? const Color(0xFF7FB8F0) : baseColor,
                    size: 21,"""),
('TV → 전파 (연결 표시)',
"""                  Icon(cast.isConnected ? Icons.cast_connected : Icons.cast,
                      color: Colors.white.withOpacity(0.85), size: 18),""",
"""                  Icon(Icons.sensors_rounded,
                      color: Colors.white.withOpacity(0.85), size: 18),"""),
('점 3개 → 둥근 점',
"""                  Icon(Icons.more_vert, color: baseColor, size: 20),""",
"""                  Icon(Icons.more_vert_rounded, color: baseColor, size: 20),"""),
]),
'lib/screens/lyrics_screen.dart': ('btn(CupertinoIcons.camera,', [
('cupertino 불러오기',
"""import 'package:flutter/material.dart';
""",
"""import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
"""),
('배경 사진 → 사진기',
"""              btn(Icons.wallpaper_rounded, _pickBackground),""",
"""              btn(CupertinoIcons.camera, _pickBackground),"""),
]),
}

def main():
    out = {}
    ok = True
    for path, (mark, edits) in FILES.items():
        print(f'── {path.split("/")[-1]}')
        try:
            raw = open(path, 'rb').read().decode('utf-8')
        except FileNotFoundError:
            print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
        crlf = '\r\n' in raw
        s = raw.replace('\r\n', '\n')
        if mark in s:
            print('이미 적용돼 있어요'); continue
        b = (s.count('{') - s.count('}'), s.count('(') - s.count(')'))
        for name, old, new in edits:
            n = s.count(old)
            if n != 1:
                print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
            s = s.replace(old, new); print(f'✔ {name}')
        if (s.count('{') - s.count('}'), s.count('(') - s.count(')')) != b:
            print('❌ 괄호가 안 맞아요'); ok = False
        out[path] = s.replace('\n', '\r\n') if crlf else s
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    for path, s in out.items():
        open(path, 'wb').write(s.encode('utf-8'))
    if out: print('저장했어요 ✔')

main()
