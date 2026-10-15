# -*- coding: utf-8 -*-
# YTN 라디오 · 경인방송 편성표 모양 자세히 보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe4.py  →  radio_probe4_result.txt 가 생겨요
import re, ssl, urllib.request, datetime, time

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []

def log(s=''):
    print(s)
    out.append(str(s))

def get(url, referer=None):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
        if referer:
            h['Referer'] = referer
        req = urllib.request.Request(url, headers=h)
        with urllib.request.urlopen(req, timeout=20, context=ssl.create_default_context()) as r:
            raw = r.read()
            ct = r.headers.get('Content-Type', '')
            enc = 'utf-8'
            m = re.search(r'charset=([\w-]+)', ct, re.I)
            if m:
                enc = m.group(1)
            else:
                m = re.search(rb'encoding=["\']([\w-]+)|charset=["\']?([\w-]+)', raw[:2000], re.I)
                if m:
                    enc = (m.group(1) or m.group(2)).decode()
            try:
                return r.status, ct, raw.decode(enc, errors='replace')
            except LookupError:
                return r.status, ct, raw.decode('utf-8', errors='replace')
    except Exception as e:
        return None, '', str(e)[:200]

def around_first_time(html, before=800, after=3000):
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', html, flags=re.S | re.I)
    m = re.search(r'\b\d{2}:\d{2}\b', body)
    if not m:
        return '  (시간 모양 글자를 못 찾음)\n' + body[:1500]
    i = m.start()
    return body[max(0, i - before): i + after]

today = datetime.date.today()
tests = [
    ('YTN 지금 방송 파일', 'https://radio.ytn.co.kr/incfile/nowSchedule.xml', 'https://radio.ytn.co.kr/', 'raw'),
    ('YTN 편성표', 'https://radio.ytn.co.kr/schedule/daily.php', 'https://radio.ytn.co.kr/', 'html'),
    ('YTN 프로그램 목록', 'https://radio.ytn.co.kr/program/daily.php', 'https://radio.ytn.co.kr/', 'html'),
    ('경인방송 오늘', f'https://www.ifm.kr/schedule?date={today:%Y-%m-%d}', 'https://www.ifm.kr/', 'html'),
]
for name, url, ref, kind in tests:
    log('=' * 60)
    log(f'[{name}] {url}')
    st, ct, txt = get(url, ref)
    log(f'  상태 {st} · {ct} · 글자 수 {len(txt)}')
    if not st:
        log('  ' + txt)
        continue
    if kind == 'raw':
        log(txt[:3000])
    else:
        log('  --- 첫 시간 근처 HTML (그대로) ---')
        log(around_first_time(txt))
        # 사진 주소 후보
        imgs = re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', txt)
        log('  --- 사진 후보 (처음 15개) ---')
        for u in imgs[:15]:
            log('  ' + u)
    time.sleep(1)

with open('radio_probe4_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe4_result.txt 를 올려 주세요')
