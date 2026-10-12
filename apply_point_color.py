# -*- coding: utf-8 -*-
# 포인트 색 통일: 파랑으로 박혀 있던 곳을 전부 '포인트 색 꺼내기' 하나로
# - 새 파일 lib/utils/point_color.dart 만들기
# - 기본 색이면 라이트 #2F7DE8(로고 파랑) / 다크 #6FB0FF, 다른 색이면 그 색 (다크에서 너무 어두우면 살짝 밝게)
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

HELPER = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 포인트 색 꺼내기 — 앱 어디서든 이것 하나만 쓰기 (화면마다 파랑이 달라지지 않게)
/// - 기본(파란소리)이면: 밝은 바탕 #2F7DE8 (로고 파랑) / 어두운 바탕 #6FB0FF
/// - 다른 색이면: 그 색 그대로 (어두운 바탕에서 너무 어두운 색이면 살짝 밝게)
/// - onDark: 바탕이 어두운지 직접 정할 때 (예: 먹색 미니플레이어 = true, 흰 알림 = false)
///   안 정하면 다크 모드인지로 정함
Color pointColorOf(BuildContext context, {bool? onDark}) {
  Theme.of(context); // 색이 바뀌면 다시 그리기
  ThemeProvider? t;
  try {
    t = Provider.of<ThemeProvider>(context, listen: false);
  } catch (_) {}
  final dark = onDark ?? (t?.isDarkMode ?? false);
  final p = t?.primaryColor ?? const Color(0xFF2589E8);
  if (p.value == 0xFF2589E8) {
    return dark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8);
  }
  if (dark && p.computeLuminance() < 0.08) return Color.lerp(p, Colors.white, 0.45)!;
  return p;
}
'''

IMPORT_FROM = "import 'package:flutter/material.dart';\n"
IMPORT_TO = "import 'package:flutter/material.dart';\nimport '../utils/point_color.dart';\n"

FILES = {
    'action_feedback.dart': [
        ("완료 알림(원래대로 있는 큰 알림) 아이콘",
         "                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2589E8), size: 46),",
         "                        Icon(Icons.check_circle_rounded, color: pointColorOf(context), size: 46),"),
        ("저장했어요·수정했어요·추가했어요 아이콘",
         "    const blue = Color(0xFF2589E8);",
         "    final blue = pointColorOf(context);"),
    ],
    'player_screen.dart': [
        ("파란포토로 바꿨어요 ✓ 아이콘 (흰 알림)",
         "            const Icon(Icons.check_circle_rounded, color: Color(0xFF2589E8), size: 22),",
         "            Icon(Icons.check_circle_rounded, color: pointColorOf(context, onDark: false), size: 22),"),
        ("되돌리기 버튼 글자",
         "              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2589E8)),",
         "              style: TextButton.styleFrom(foregroundColor: pointColorOf(context, onDark: false)),"),
        ("파란포토 추천 카드 버튼",
         "                              backgroundColor: const Color(0xFF2589E8),",
         "                              backgroundColor: pointColorOf(context, onDark: false),"),
        ("TV 연결 표시 바탕",
         "                color: cast.isConnected ? const Color(0xFF2589E8).withOpacity(0.3) : Colors.transparent,",
         "                color: cast.isConnected ? pointColorOf(context).withOpacity(0.3) : Colors.transparent,"),
        ("재생 속도 창 색",
         "        child: _SpeedDialog(playerProvider: playerProvider, primaryColor: const Color(0xFF2589E8)),",
         "        child: _SpeedDialog(playerProvider: playerProvider, primaryColor: pointColorOf(context)),"),
        ("메뉴 'TV로 듣기' 켜짐",
         "        on ? const Color(0xFF2589E8) : const Color(0xFF8A8378),",
         "        on ? pointColorOf(context) : const Color(0xFF8A8378),"),
    ],
    'song_list_tile.dart': [
        ("자른 곡 배지",
         "                color: const Color(0xFF2589E8),\n                shape: BoxShape.circle,\n                border: Border.all(color: Colors.white, width: 1.5),",
         "                color: pointColorOf(context, onDark: false),\n                shape: BoxShape.circle,\n                border: Border.all(color: Colors.white, width: 1.5),"),
    ],
    'paran_dialog.dart': [
        ("확인 창 음표 아이콘",
         "                      color: _kBlue.withOpacity(0.15),\n                      child: const Icon(Icons.music_note_rounded, color: _kBlue, size: 26),",
         "                      color: pointColorOf(context).withOpacity(0.15),\n                      child: Icon(Icons.music_note_rounded, color: pointColorOf(context), size: 26),"),
    ],
    'radio_player_screen.dart': [
        ("라디오 TV 버튼",
         "                                      color: CastService.instance.isConnected ? const Color(0xFF2589E8) : baseColor,",
         "                                      color: CastService.instance.isConnected ? pointColorOf(context) : baseColor,"),
        ("라디오 'TV에서 재생 중' 뱃지",
         "                                color: const Color(0xFF2589E8).withOpacity(0.14),\n                                borderRadius: BorderRadius.circular(20),\n                                border: Border.all(color: const Color(0xFF2589E8).withOpacity(0.35)),\n                              ),\n                              child: Row(mainAxisSize: MainAxisSize.min, children: [\n                                const Icon(Icons.cast_connected, size: 14, color: Color(0xFF2589E8)),",
         "                                color: pointColorOf(context).withOpacity(0.14),\n                                borderRadius: BorderRadius.circular(20),\n                                border: Border.all(color: pointColorOf(context).withOpacity(0.35)),\n                              ),\n                              child: Row(mainAxisSize: MainAxisSize.min, children: [\n                                Icon(Icons.cast_connected, size: 14, color: pointColorOf(context)),"),
        ("라디오 'TV에서 재생 중' 글자",
         "                                  style: const TextStyle(\n                                      color: Color(0xFF2589E8), fontSize: 12, fontWeight: FontWeight.bold),",
         "                                  style: TextStyle(\n                                      color: pointColorOf(context), fontSize: 12, fontWeight: FontWeight.bold),"),
    ],
    'mini_player.dart': [
        ("미니플레이어 TV 아이콘 (먹색 띠 위)",
         "                                    const Icon(Icons.cast_connected, size: 13, color: Color(0xFF2589E8)),",
         "                                    Icon(Icons.cast_connected, size: 13, color: pointColorOf(context, onDark: true)),"),
        ("미니플레이어 'TV에서 재생' 글자",
         "                                              ? const Color(0xFF2589E8)\n                                              : baseColor.withOpacity(0.6),",
         "                                              ? pointColorOf(context, onDark: true)\n                                              : baseColor.withOpacity(0.6),"),
    ],
    'more_menu_sheet.dart': [
        ("⋮ 메뉴 맨 위 카드 음파 막대",
         "        final blue = dark ? const Color(0xFF2589E8) : const Color(0xFF7FB8F0);",
         "        final blue = pointColorOf(context, onDark: !dark); // 카드는 바탕과 반대 색"),
    ],
    'call_recordings_screen.dart': [
        ("통화 녹음: 재생 중 색",
         "  static const _blue = Color(0xFF2589E8); // 파란색은 \"지금 재생 중\"에만",
         "  Color get _blue => pointColorOf(context); // 포인트 색은 \"지금 재생 중\"에만"),
        ("통화 녹음: 진행 막대",
         "              valueColor: const AlwaysStoppedAnimation(_blue),",
         "              valueColor: AlwaysStoppedAnimation(_blue),"),
        ("통화 녹음: 정렬 ✓",
         "                                  const Icon(Icons.check_rounded, size: 17, color: Color(0xFF2589E8)),",
         "                                  Icon(Icons.check_rounded, size: 17, color: pointColorOf(context)),"),
    ],
    'bulk_art_screen.dart': [
        ("앨범 사진 한꺼번에: 고른 ✓",
         "                            if (selected) const Icon(Icons.check_circle, color: _blue, size: 20),",
         "                            if (selected) Icon(Icons.check_circle, color: pointColorOf(context), size: 20),"),
    ],
}

def balanced(t):
    return all(t.count(a) == t.count(b) for a, b in ('()', '{}', '[]'))

helper_path = os.path.join(LIB, 'utils', 'point_color.dart')
if os.path.exists(helper_path):
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
out = {}
for fname, edits in FILES.items():
    p = find(fname)
    if not p:
        ok = False; print('❌ 파일을 못 찾았어요:', fname); continue
    raw = open(p, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    t = raw.replace('\r\n', '\n')
    print('\n[%s]' % fname)
    if IMPORT_FROM in t and "utils/point_color.dart" not in t:
        t = t.replace(IMPORT_FROM, IMPORT_TO, 1)
    for name, a, b in edits:
        if t.count(a) == 1:
            t = t.replace(a, b); print('  ✔', name)
        else:
            ok = False; print('  ❌', name, '(찾은 개수: %d)' % t.count(a))
    if not balanced(t) and balanced(raw):
        ok = False; print('  ❌ 괄호 개수가 안 맞아요')
    elif not balanced(t) and [t.count(c) for c in '(){}[]'] != [raw.count(c) for c in '(){}[]']:
        ok = False; print('  ❌ 괄호 개수가 안 맞아요')
    out[p] = (t, crlf)

if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)

os.makedirs(os.path.dirname(helper_path), exist_ok=True)
open(helper_path, 'wb').write(HELPER.replace('\n', '\r\n').encode('utf-8'))
print('\n✔ 새 파일: lib/utils/point_color.dart')
for p, (t, crlf) in out.items():
    shutil.copyfile(p, p + '.bak')
    if crlf:
        t = t.replace('\n', '\r\n')
    open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
