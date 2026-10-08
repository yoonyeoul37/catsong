# 정리: 확인용 로그(VideoPlace · NEW 확인) 빼기 + 녹음 화면 안내 문구 이모지 빼기
# 실행: python apply_cleanup_logs.py   (mp3_player_new 폴더에서)
import os, sys

PROVIDER = os.path.join('lib', 'providers', 'video_provider.dart')
RECORDINGS = os.path.join('lib', 'screens', 'call_recordings_screen.dart')

KOTLIN_EDITS = [
    ("로그 빼기: 위치 읽기",
     '            android.util.Log.d("VideoPlace", "원본으로 열림=$opened | 위치=$loc | 파일=$path")\n',
     ''),
    ("로그 빼기: 주소 후보",
     '                    all.forEachIndexed { i, x ->\n'
     '                        android.util.Log.d("VideoPlace", "후보$i=${x.getAddressLine(0)} | subLoc=${x.subLocality} | road=${x.thoroughfare} | feat=${x.featureName}")\n'
     '                    }\n',
     ''),
    ("로그 빼기: 첫 주소",
     '                        android.util.Log.d("VideoPlace", "주소=${a.getAddressLine(0)} | admin=${a.adminArea} | subAdmin=${a.subAdminArea} | loc=${a.locality} | subLoc=${a.subLocality} | road=${a.thoroughfare} | feat=${a.featureName}")\n',
     ''),
]

PROVIDER_EDITS = [
    ("로그 빼기: NEW 확인",
     "      debugPrint('NEW 확인: 본 영상 ${_seen?.length}개 기억 / NEW = ${_videos.where((v) => isNew(v.uri)).map((v) => v.title).toList()}');\n",
     ''),
    ("로그 빼기: 위치 권한",
     "          final st = await Permission.accessMediaLocation.request();\n"
     "          debugPrint('VideoPlace 권한: $st');\n",
     "          await Permission.accessMediaLocation.request();\n"),
]

RECORDING_EDITS = [
    ("녹음 안내 문구: 이모지 대신 글자",
     "'오른쪽 아래 🎙 버튼으로\\n바로 녹음할 수 있어요'",
     "'오른쪽 아래 녹음 버튼으로\\n바로 녹음할 수 있어요'"),
]


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def find_main_activity():
    for root, _, files in os.walk(os.path.join('android', 'app', 'src', 'main')):
        if 'MainActivity.kt' in files:
            return os.path.join(root, 'MainActivity.kt')
    return None


def main():
    ma = find_main_activity()
    for path in (PROVIDER, RECORDINGS):
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path)
            print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
            sys.exit(1)
    if ma is None:
        print('❌ MainActivity.kt 를 못 찾았어요. mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    jobs = [(ma, KOTLIN_EDITS), (PROVIDER, PROVIDER_EDITS), (RECORDINGS, RECORDING_EDITS)]
    texts = {p: open(p, 'rb').read().decode('utf-8') for p, _ in jobs}
    left = any(old in texts[p].replace('\r\n', '\n') for p, eds in jobs for _, old, _ in eds)
    if not left:
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    results = {}
    num = 0
    for path, edits in jobs:
        raw = texts[path]
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balance(text)
        print(f'[{os.path.basename(path)}]')
        for name, old, new in edits:
            num += 1
            n = text.count(old)
            if n != 1:
                print(f'❌ {num}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
                print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
                sys.exit(1)
            text = text.replace(old, new)
            print(f'✔ {num}. {name}')
        if balance(text) != before:
            print(f'❌ {os.path.basename(path)} 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
            sys.exit(1)
        if crlf:
            text = text.replace('\n', '\r\n')
        results[path] = text

    for path, text in results.items():
        open(path, 'wb').write(text.encode('utf-8'))
    print(f'완료! {num}군데 바꿨어요.')


main()
