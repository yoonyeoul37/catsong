# -*- coding: utf-8 -*-
# 손으로 적은 공동체 라디오 편성표(마포FM · 전주FM)가 바뀌었는지 확인
# 홈페이지의 편성표 그림 이름이 아래와 다르면 "실패"로 끝나서 GitHub가 알림 메일을 보내요
# (편성표 저장이 다 끝난 뒤에 돌아서, 다른 방송 편성표에는 영향 없어요)
# 새 그림으로 표를 고친 뒤에는 아래 그림 이름도 새 것으로 바꿔 주세요
import re, ssl, sys, urllib.request

PAGES = {
    '마포FM': ('https://www.mapofm.net/timetable', 'image_1789353845765'),
    '전주FM': ('https://www.jcfm.kr/untitled-7', 'image_1788224630991'),
}
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def get(url):
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=30, context=c) as r:
        return r.read().decode('utf-8', errors='replace')


changed = []
for station, (url, known) in PAGES.items():
    try:
        page = get(url)
    except Exception as e:
        print(f'⚠ {station} 홈페이지를 못 열었어요 (오늘은 확인 건너뜀): {e}')
        continue
    if known in page:
        print(f'✔ {station} 편성표 그림 그대로예요')
        continue
    imgs = sorted(set(re.findall(r'uploadedFiles/\d+/default/(image_\d+)', page)))
    print(f'❗ {station} 편성표 그림이 바뀌었어요 → {url}')
    print(f'   예전 그림: {known} · 지금 페이지 그림: {imgs}')
    changed.append(station)

if changed:
    print(f'\n편성표가 바뀐 방송: {", ".join(changed)} — 새 편성표 그림을 보고 make_schedule.py 의 FIXED_TABLES 를 고쳐 주세요')
    sys.exit(1)
print('\n모두 그대로예요')