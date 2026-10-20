# -*- coding: utf-8 -*-
# 프로젝트 폴더 정리
#  · 지우기: 한 번 쓰고 끝난 점검·작업 파일, 보내려고 만든 압축(lib.zip·assets.zip)
#  · 옮기기: 점검 결과 엑셀·번역 압축·스토어 사진 → 프로젝트 밖 'C:\apps\파란소리 자료' 폴더 (나중에 볼 수 있게)
#  · 앱·홈페이지·출시에 필요한 파일(CNAME, app-ads, play-key, 키, privacy/terms, release_play 등)은 건드리지 않음
import os, shutil, sys
sys.stdout.reconfigure(encoding='utf-8')

here = os.getcwd()
if not os.path.isfile(os.path.join(here, 'pubspec.yaml')):
    print('❌ 프로젝트 폴더(pubspec.yaml 있는 곳)에서 실행해 주세요'); sys.exit(1)

DELETE = [
    'check_kr_music.py', 'check_podcast.py', 'check_radio4.py',
    'fix_radio_count.py', 'missing_countries.py', 'long_test.py',
    'get_listing.py', 'listing_now.json',
    'lib.zip', 'assets.zip',
]
MOVE = [
    '번역 1차 5개 언어.zip', '번역 2차 아랍어 우르두어.zip',
    '보류 방송 다시 점검.xlsx', '앱에 없는 나라.xlsx', '웹페이지 방송 재확인.xlsx',
    '팟캐스트 점검 결과.txt', '한국 음악방송 점검 결과.xlsx', '한국 음악방송 점검 결과.txt',
    '해외 라디오 점검 결과 1차.xlsx', '해외 라디오 점검 결과 2차.xlsx',
    '스토어 사진',
]
dest = os.path.join(os.path.dirname(here), '파란소리 자료')

dels = [f for f in DELETE if os.path.exists(os.path.join(here, f))]
moves = [f for f in MOVE if os.path.exists(os.path.join(here, f))]
if not dels and not moves:
    print('✔ 정리할 게 없어요 (이미 정리돼 있어요)'); sys.exit(0)

if dels:
    print('[지울 것]')
    for f in dels: print('  ·', f)
if moves:
    print('[옮길 것] →', dest)
    for f in moves: print('  ·', f)
print('이대로 정리할까요? 하려면 y 를 누르고 엔터')
if input('> ').strip().lower() != 'y':
    print('✔ 아무것도 안 했어요'); sys.exit(0)

for f in dels:
    try:
        os.remove(os.path.join(here, f)); print('✔ 지움:', f)
    except Exception as e:
        print('❌', f, e)
if moves:
    os.makedirs(dest, exist_ok=True)
    for f in moves:
        to = os.path.join(dest, f)
        if os.path.exists(to):
            print('❌ 이미 같은 이름이 있어서 그대로 둠:', f); continue
        try:
            shutil.move(os.path.join(here, f), to); print('✔ 옮김:', f)
        except Exception as e:
            print('❌', f, e)
print('✔ 끝')
