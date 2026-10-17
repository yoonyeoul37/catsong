# -*- coding: utf-8 -*-
# 지금 플레이 스토어 등록 정보(앱 이름·간단한 설명·자세한 설명)를 언어별로 읽어서 listing_now.json 에 저장
# 읽기만 해요 — 스토어에는 아무것도 안 바꿔요
# 실행: python get_listing.py   (mp3_player_new 폴더, play-key.json 있는 곳)
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
PACKAGE = 'kr.ssing.catsong'
KEY_FILE = 'play-key.json'


def main():
    if not os.path.exists(KEY_FILE):
        print(f'❌ {KEY_FILE} 가 없어요. mp3_player_new 폴더에서 실행해 주세요.'); sys.exit(1)
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        print('❌ 처음 한 번 설치가 필요해요:  pip install google-api-python-client google-auth'); sys.exit(1)
    creds = service_account.Credentials.from_service_account_file(
        KEY_FILE, scopes=['https://www.googleapis.com/auth/androidpublisher'])
    edits = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False).edits()
    eid = edits.insert(packageName=PACKAGE, body={}).execute()['id']
    try:
        ls = edits.listings().list(packageName=PACKAGE, editId=eid).execute().get('listings', [])
        out = {x['language']: {'title': x.get('title', ''), 'shortDescription': x.get('shortDescription', ''),
                               'fullDescription': x.get('fullDescription', '')} for x in ls}
        json.dump(out, open('listing_now.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
        print(f'✔ {len(out)}개 언어를 listing_now.json 에 저장했어요: {", ".join(out)}')
    finally:
        try:
            edits.delete(packageName=PACKAGE, editId=eid).execute()  # 읽기만 했으니 그냥 버리기
        except Exception:
            pass


main()
