# -*- coding: utf-8 -*-
# TBN 편성표 페이지 본문(그날 편성표) 모양 보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe25.py  →  radio_probe25_result.txt 가 생겨요
import re, ssl, datetime, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
today = datetime.date.today()


def log(s=''):
    print(s)
    out.append(str(s))


def get(url):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://www.tbn.or.kr/main.tbn'}),
                               timeout=20, context=c)
    return r.read().decode('utf-8', 'replace')


for label, url in [
    ('경인 오늘', 'https://www.tbn.or.kr/broadcast/program.tbn?BOARD_ID=P001&page_code=1&area_code=6'),
    ('경인 내일(today=YYYYMMDD)', f'https://www.tbn.or.kr/broadcast/program.tbn?today={today + datetime.timedelta(days=1):%Y%m%d}&area_code=6&page_code=1'),
    ('경인 내일(today=YYYY-MM-DD)', f'https://www.tbn.or.kr/broadcast/program.tbn?today={today + datetime.timedelta(days=1):%Y-%m-%d}&area_code=6&page_code=1'),
]:
    log('#' * 60)
    try:
        t = get(url)
    except Exception as e:
        log(f'■ {label} 못 가져옴: {e}')
        continue
    log(f'■ {label} · 글자 수 {len(t)}')
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)
    i = max(body.find('id="contents"'), body.find("id='contents'"))
    if i < 0:
        i = body.find('calendar')
    log(f'  본문 시작 위치 {i}')
    part = body[i: i + 9000] if i >= 0 else body[-9000:]
    log(re.sub(r'\n\s*\n+', '\n', part))
    # 사진 후보
    imgs = [u for u in re.findall(r'<img[^>]+src=["\']([^"\']+)', part) if not re.search(r'/images/common/|icon|btn', u)]
    log('  --- 본문 사진 후보 ---')
    for u in imgs[:15]:
        log('  ' + u)

with open('radio_probe25_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe25_result.txt 를 올려 주세요')
