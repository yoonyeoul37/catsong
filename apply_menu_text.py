# -*- coding: utf-8 -*-
# 재생 화면 ⋮ 메뉴 · 곡 목록 ⋮ 메뉴 문구 바꾸기 (두 메뉴 같이)
# 메뉴 안 글자만 바꿈 — 설정 화면·재생 화면 아래 버튼 등 다른 곳 글자는 그대로
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
    for label, old, new, cnt in edits:
        n = s.count(old)
        if n != cnt:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요 (있어야 할 수 {cnt}). 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

L = 'AppLocalizations.of(context)!'
player = [
('셔플 → 랜덤 재생 (재생 화면 메뉴)',
 f"                    Icons.shuffle_rounded,\n                    {L}.shuffle,",
 "                    Icons.shuffle_rounded,\n                    '랜덤 재생',", 1),
('셔플 → 랜덤 재생 (곡 목록 메뉴)',
 f"context, Icons.shuffle_rounded, {L}.shuffle, accent, textColor,",
 "context, Icons.shuffle_rounded, '랜덤 재생', accent, textColor,", 1),
('반복 → 반복 재생 (재생 화면 메뉴)',
 "                    Icons.repeat_rounded,\n                    '반복',",
 "                    Icons.repeat_rounded,\n                    '반복 재생',", 1),
('반복 → 반복 재생 (곡 목록 메뉴)',
 "context, Icons.repeat_rounded, '반복', accent, textColor,",
 "context, Icons.repeat_rounded, '반복 재생', accent, textColor,", 1),
('꺼짐 → 끔 (반복 재생 고르기)',
 "chip('꺼짐', LoopMode.off),", "chip('끔', LoopMode.off),", 1),
('수면 → 수면 타이머 (재생 화면 메뉴)',
 "                    Icons.nightlight_round,\n                    '수면',",
 "                    Icons.nightlight_round,\n                    '수면 타이머',", 1),
('수면 → 수면 타이머 (곡 목록 메뉴)',
 "context, Icons.nightlight_round, '수면', accent, textColor,",
 "context, Icons.nightlight_round, '수면 타이머', accent, textColor,", 1),
('재생 화면 스타일 → 재생 화면 (재생 화면 메뉴)',
 f"_playerSheetItem(ctx, Icons.style, {L}.playerStyle,",
 "_playerSheetItem(ctx, Icons.style, '재생 화면',", 1),
('재생 화면 스타일 → 재생 화면 (곡 목록 메뉴)',
 f"context, Icons.style, {L}.playerStyle, accent, textColor,",
 "context, Icons.style, '재생 화면', accent, textColor,", 1),
('시디롬 → CD', "box(1, '시디롬', cd),", "box(1, 'CD', cd),", 1),
('앨범 → 앨범 사진', "box(3, '앨범', album),", "box(3, '앨범 사진', album),", 1),
('배속 → 재생 속도 (두 메뉴)', "Icons.speed, '배속',", "Icons.speed, '재생 속도',", 2),
('가사 → 가사 보기',
 f"Icons.lyrics_outlined, {L}.lyrics,", "Icons.lyrics_outlined, '가사 보기',", 1),
('자연소리 섞기 → 자연 소리 믹스 (두 메뉴)', "'자연소리 섞기'", "'자연 소리 믹스'", 2),
('벨소리로 설정 → 벨소리 설정',
 f"Icons.music_note, {L}.setRingtone,", "Icons.music_note, '벨소리 설정',", 1),
('자르기 → 오디오 자르기', "Icons.content_cut, '자르기',", "Icons.content_cut, '오디오 자르기',", 1),
]

tile = [
('벨소리로 설정 → 벨소리 설정',
 f"Icons.music_note, {L}.setRingtone, 'ringtone',", "Icons.music_note, '벨소리 설정', 'ringtone',", 1),
('자르기 → 오디오 자르기', "Icons.content_cut, '자르기', 'trim',", "Icons.content_cut, '오디오 자르기', 'trim',", 1),
]

overlay = [
('창 제목: 자연 소리 믹스', "child: Text('자연소리 섞기',", "child: Text('자연 소리 믹스',", 1),
]

home = [
('홈 팁 안내', "'재생 화면 ⋮ 메뉴 → 자연소리 섞기'", "'재생 화면 ⋮ 메뉴 → 자연 소리 믹스'", 1),
]

jobs = [
    prepare(find('player_screen.dart'), player, "'랜덤 재생'"),
    prepare(find('song_list_tile.dart'), tile, "'오디오 자르기'"),
    prepare(find('nature_overlay.dart'), overlay, "Text('자연 소리 믹스'"),
    prepare(find('home_screen.dart'), home, '→ 자연 소리 믹스'),
]
for r in jobs:   # 모두 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak_text')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_text)')
