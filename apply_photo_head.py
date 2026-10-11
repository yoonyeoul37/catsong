# -*- coding: utf-8 -*-
# 파란포토 창 제목: 왼쪽 카메라 아이콘 칸 + '파란포토'(도현) + 아래 '나만의 재생 화면 꾸미기'
import sys, glob, os, re, shutil

NAME = 'player_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'Icons.photo_camera_outlined, size: 20' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

pat = re.compile(
    r"        child: Text\.rich\(\n          TextSpan\(children: \[\n            TextSpan\(\n              text: '파란포토',\n"
    r".*?"
    r"          \]\),\n        \),\n      \),\n      builder: \(ctx, setSheet\) \{", re.S)
m = pat.findall(s)
if len(m) != 1:
    print(f'❌ [파란포토 제목] 찾을 곳이 {len(m)}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)

new = """        child: Builder(builder: (_) {
          final dark = context.read<ThemeProvider>().isDarkMode;
          return Row(
            children: [
              // 왼쪽 카메라 아이콘 칸 (수면 타이머 창과 같은 모양)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF3E3B37) : Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.photo_camera_outlined, size: 20,
                    color: dark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('파란포토',
                        style: GoogleFonts.doHyeon( // 홈과 같은 글꼴
                          color: dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),
                          fontSize: 19,
                        )),
                    const SizedBox(height: 1),
                    Text('나만의 재생 화면 꾸미기',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378),
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
      builder: (ctx, setSheet) {"""
s = pat.sub(lambda _: new, s)
print('✔ 파란포토 제목: 카메라 아이콘 칸 + 두 줄')

if "package:google_fonts/google_fonts.dart" not in s:
    s = s.replace("import 'package:flutter/material.dart';\n",
                  "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';\n", 1)
    print('✔ 도현 글꼴 불러오기')

shutil.copy(path, path + '.bak_phead')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_phead)')
