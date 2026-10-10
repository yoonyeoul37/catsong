# -*- coding: utf-8 -*-
# 빌드 → 구글 플레이 프로덕션에 올리기 → 검토 보내기 까지 한 번에
# 실행: python release_play.py   (mp3_player_new 폴더에서) — 아무것도 안 물어보고 끝까지
#       python release_play.py "업데이트 내용"   ← 내용을 직접 넣고 싶을 때만
#  1) build_release.py 로 버전 번호 +1 하고 .aab 만들기
#  2) 업데이트 내용: 적은 게 없으면 "작은 개선과 오류 수정"
#  3) 플레이 콘솔 프로덕션에 올리고 검토 보내기
# 처음 한 번 준비: play-key.json (서비스 계정 키) 를 이 폴더에 두기
import os, sys, subprocess, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)

PACKAGE = 'kr.ssing.catsong'
KEY_FILE = 'play-key.json'
AAB = os.path.join('build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab')
TRACK = 'production'
DEFAULT_NOTES = '작은 개선과 오류 수정'


def keep_key_out_of_github():
    """키 파일이 깃허브에 올라가지 않게 .gitignore 에 넣기"""
    gi = '.gitignore'
    text = open(gi, 'rb').read().decode('utf-8') if os.path.exists(gi) else ''
    if KEY_FILE not in text.split():
        nl = '\r\n' if '\r\n' in text else '\n'
        add = ('' if text.endswith(('\n', '\r\n')) or not text else nl) + KEY_FILE + nl
        open(gi, 'ab').write(add.encode('utf-8'))
        print(f'✔ .gitignore 에 {KEY_FILE} 를 넣었어요 (키가 깃허브에 안 올라가게)')


def main():
    if not os.path.exists('pubspec.yaml'):
        print('❌ mp3_player_new 폴더에서 실행해 주세요.'); sys.exit(1)
    if not os.path.exists(KEY_FILE):
        print(f'❌ {KEY_FILE} 가 없어요. 서비스 계정 키 파일을 이 폴더에 {KEY_FILE} 이름으로 넣어 주세요.'); sys.exit(1)
    keep_key_out_of_github()
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print('❌ 처음 한 번 설치가 필요해요:  pip install google-api-python-client google-auth'); sys.exit(1)

    # 1) 빌드
    r = subprocess.run([sys.executable, 'build_release.py'])
    if r.returncode != 0 or not os.path.exists(AAB):
        print('❌ 빌드가 안 돼서 올리지 않았어요.'); sys.exit(1)

    # 2) 업데이트 내용
    # 묻지 않고 바로: 명령어 뒤에 적은 게 있으면 그걸, 없으면 기본 문구
    notes = ' '.join(sys.argv[1:]).strip() or DEFAULT_NOTES
    if len(notes) > 500:
        print('❌ 업데이트 내용은 500자까지예요.'); sys.exit(1)
    print(f'✔ 업데이트 내용: {notes}')

    # 3) 플레이 콘솔에 올리기
    try:
        creds = service_account.Credentials.from_service_account_file(
            KEY_FILE, scopes=['https://www.googleapis.com/auth/androidpublisher'])
        svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)
        edits = svc.edits()
        eid = edits.insert(packageName=PACKAGE, body={}).execute()['id']
        print('… 올리는 중이에요 (1~2분)')
        media = MediaFileUpload(AAB, mimetype='application/octet-stream', resumable=True)
        vc = edits.bundles().upload(packageName=PACKAGE, editId=eid, media_body=media).execute()['versionCode']
        print(f'✔ 앱 번들 올림 (버전 코드 {vc})')
        edits.tracks().update(
            packageName=PACKAGE, editId=eid, track=TRACK,
            body={'track': TRACK, 'releases': [{
                'versionCodes': [str(vc)],
                'status': 'completed',
                'releaseNotes': [{'language': 'ko-KR', 'text': notes}],
            }]}).execute()
        print('✔ 프로덕션에 새 버전 넣음')
        edits.commit(packageName=PACKAGE, editId=eid).execute()
        print('✔ 검토 보냈어요! 플레이 콘솔 → 게시 개요에서 진행 상황을 볼 수 있어요.')
    except Exception as e:
        msg = str(e)
        print('❌ 올리지 못했어요.')
        if '403' in msg or 'permission' in msg.lower():
            print('   권한 문제예요. 플레이 콘솔 → 사용자 및 권한에서 서비스 계정에 출시 권한이 있는지 확인해 주세요.')
            print('   (처음 초대한 뒤에는 하루 정도 지나야 될 때도 있어요)')
        elif 'versionCode' in msg or 'already been used' in msg:
            print('   같은 버전 번호가 이미 올라가 있어요. 다시 실행하면 번호를 올려서 새로 만들어요.')
        else:
            print('  ', msg[:400])
        sys.exit(1)


main()
