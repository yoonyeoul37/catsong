# 설정 화면 문구 정리 (settings_screen.dart) + ⋮ 메뉴 이름 맞추기 (more_menu_sheet.dart)
import sys, os
FILES = {
 'settings': os.path.join('lib', 'screens', 'settings_screen.dart'),
 'menu': os.path.join('lib', 'widgets', 'more_menu_sheet.dart'),
}
if len(sys.argv) > 2: FILES = {'settings': sys.argv[1], 'menu': sys.argv[2]}

S = [
('맨 위 카드 문구', "'광고 없이 듣고 계세요'", "'광고 없는 음악, 편안한 일상'"),
('강조 색상 이름', "Text('포인트 색', style", "Text('강조 색상', style"),
('강조 색상 말풍선 제목', "title: '포인트 색이 바뀌는 곳'", "title: '강조 색상이 바뀌는 곳'"),
('강조 색상 설명',
 "Text('재생 중 표시·막대·스위치 같은 작은 곳의 색',\n                        maxLines: 1,",
 "Text('버튼과 표시 색상을 변경해요',\n                        maxLines: 2,"),
('색 고르는 창 제목', "title: '포인트 색',\n      builder", "title: '강조 색상',\n      builder"),
('재생 화면 스타일 설명', "desc: '시디롬·파란포토·앨범 중에서 골라요'", "desc: '원하는 재생 화면을 선택하세요'"),
('글꼴 설명', "desc: '앱 글꼴을 바꿔요'", "desc: '원하는 글꼴을 선택하세요'"),
('글자 크기 설명', "desc: '앱 글자 크기를 키우거나 줄여요'", "desc: '글자 크기를 조절하세요'"),
('홈 추천 카드 설명', "desc: '홈 맨 위에 날마다 바뀌는 카드'", "desc: '홈 화면에 새로운 추천을 보여줘요'"),
('음악 정보 일괄 정리',
 "title: '곡 정보 한꺼번에 정리', desc: '제목·가수 이름을 깔끔하게 정리해요'",
 "title: '음악 정보 일괄 정리', desc: '곡 제목과 가수 정보를 정리하세요'"),
('앨범 사진 자동 찾기',
 "title: '앨범 사진 한꺼번에 찾기', desc: '사진 없는 곡에 앨범 사진을 찾아 넣어요'",
 "title: '앨범 사진 자동 찾기', desc: '없는 앨범 사진을 찾아 추가해요'"),
('이퀄라이저 설명', "desc: '저음·고음 같은 소리 색을 맞춰요'", "desc: '취향에 맞게 음질을 조절하세요'"),
('음량 자동 조절',
 "title: '곡마다 소리 크기 맞추기',\n                desc: '유난히 큰 곡을 줄여 비슷하게 들려요',",
 "title: '음량 자동 조절',\n                desc: '곡마다 다른 음량을 고르게 맞춰요',"),
('이어폰 자동 재생',
 "title: '이어폰 연결하면 이어서 듣기',\n                desc: '이어폰을 연결하면 듣던 걸 다시 틀어요',",
 "title: '이어폰 자동 재생',\n                desc: '이어폰 연결 시 음악을 이어서 재생해요',"),
('이어폰 자동 재생 창 제목', "title: '이어폰 연결하면 이어서 듣기',\n      builder", "title: '이어폰 자동 재생',\n      builder"),
('벨소리 설명', "desc: '노래로 전화 벨소리를 만들어요'", "desc: '좋아하는 음악을 벨소리로 설정하세요'"),
('손전등 (오른쪽 상태 글자 빼기)',
 "desc: '휴대폰 플래시를 켜요', subtitle: _isFlashlightOn ? l.on : l.off,",
 "desc: '휴대폰 플래시를 켜고 끄세요',"),
('SOS (오른쪽 중복 글자 빼기)',
 "desc: '플래시로 구조 신호를 깜빡여요', subtitle: _isSosOn ? l.sosWorking : l.sos,",
 "desc: '플래시로 긴급 구조 신호를 보내요',"),
('위젯 설명', "desc: '홈 화면에 파란소리 위젯을 놓아요'", "desc: '홈 화면에서 음악을 간편하게 제어하세요'"),
('설정 도움말 설명', "desc: '권한·배터리·알림 설정 방법'", "desc: '권한, 배터리 및 알림 설정을 안내해요'"),
('설명이 길면 두 줄로 (잘림 방지)',
 "                          Text(desc,\n                              maxLines: 1,",
 "                          Text(desc,\n                              maxLines: 2,"),
]
M = [
('메뉴: 음악 정보 일괄 정리', "title: '곡 정보 한꺼번에 정리',", "title: '음악 정보 일괄 정리',"),
('메뉴: 앨범 사진 자동 찾기', "title: '앨범 사진 한꺼번에 찾기',", "title: '앨범 사진 자동 찾기',"),
]

def run(path, reps, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    src = raw.replace('\r\n', '\n')
    if done_mark in src:
        print(f'{os.path.basename(path)}: 이미 적용돼 있어요'); return None
    ok = True
    for name, old, new in reps:
        n = src.count(old)
        if n != 1:
            print(f'❌ {name}: 찾을 코드를 {"못 찾았어요" if n == 0 else f"{n}곳에서 찾았어요"}'); ok = False
        else:
            src = src.replace(old, new); print(f'✔ {name}')
    if not ok: return False
    return (path, src.replace('\n', '\r\n') if crlf else src)

r1 = run(FILES['settings'], S, "'광고 없는 음악, 편안한 일상'")
r2 = run(FILES['menu'], M, "title: '음악 정보 일괄 정리',")
if r1 is False or r2 is False:
    print('아무것도 저장하지 않았어요'); sys.exit(1)
for r in (r1, r2):
    if r:
        open(r[0], 'wb').write(r[1].encode('utf-8')); print('저장했어요:', r[0])
