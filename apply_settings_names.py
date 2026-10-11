# 설정 이름 맞추기: 번역 파일(app_ko.arb) 6개 + 일괄 정리·사진 찾기 화면 제목
import sys, os, json
FILES = {
 'arb': os.path.join('lib', 'l10n', 'app_ko.arb'),
 'clean': os.path.join('lib', 'screens', 'bulk_clean_screen.dart'),
 'art': os.path.join('lib', 'screens', 'bulk_art_screen.dart'),
}
if len(sys.argv) > 3: FILES = dict(zip(['arb', 'clean', 'art'], sys.argv[1:4]))

PLAN = {
 'arb': [
  ('글자 크기', '"textSize": "텍스트 크기"', '"textSize": "글자 크기"', 1),
  ('글꼴 변경', '"fontChange": "텍스트 변경"', '"fontChange": "글꼴 변경"', 1),
  ('재생 화면 스타일', '"playerStyle": "재생화면 스타일"', '"playerStyle": "재생 화면 스타일"', 1),
  ('SOS 긴급 신호', '"sos": "SOS 비상등"', '"sos": "SOS 긴급 신호"', 1),
  ('벨소리 설정', '"ringtone": "벨소리 지정"', '"ringtone": "벨소리 설정"', 1),
  ('홈 화면 위젯', '"widget": "홈화면 위젯"', '"widget": "홈 화면 위젯"', 1),
 ],
 'clean': [('일괄 정리 화면 제목', "Text('곡 정보 한꺼번에 정리',", "Text('음악 정보 일괄 정리',", 2)],
 'art': [('사진 찾기 화면 제목', "title: Text('앨범 사진 한꺼번에 찾기',", "title: Text('앨범 사진 자동 찾기',", 1)],
}
DONE = {'arb': '"sos": "SOS 긴급 신호"', 'clean': "Text('음악 정보 일괄 정리',", 'art': "Text('앨범 사진 자동 찾기',"}

results, ok = [], True
for k, path in FILES.items():
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    src = raw.replace('\r\n', '\n')
    if DONE[k] in src:
        print(f'{os.path.basename(path)}: 이미 적용돼 있어요'); continue
    for name, old, new, want in PLAN[k]:
        n = src.count(old)
        if n != want:
            print(f'❌ {name}: 찾을 코드가 {n}곳이에요 ({want}곳이어야 해요)'); ok = False
        else:
            src = src.replace(old, new); print(f'✔ {name}')
    if k == 'arb':
        try: json.loads(src)
        except Exception as e: print('❌ app_ko.arb 형식이 깨졌어요:', e); ok = False
    results.append((path, src.replace('\n', '\r\n') if crlf else src))
if not ok:
    print('아무것도 저장하지 않았어요'); sys.exit(1)
for path, out in results:
    open(path, 'wb').write(out.encode('utf-8')); print('저장했어요:', path)
