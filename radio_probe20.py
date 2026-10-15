# -*- coding: utf-8 -*-
# EBS FM: 편성 데이터가 오는 채널 이름 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe20.py  →  radio_probe20_result.txt 가 생겨요
import json, re, ssl, time, urllib.request

out = []
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def log(s=''):
    print(s)
    out.append(str(s))


def get(url):
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://www.ebs.co.kr/onair'}),
                                   timeout=20, context=ssl.create_default_context())
        return r.status, r.read().decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:150]


for code in ['FM', 'RADIO', 'EBSFM', 'RFM', 'EBSRADIO', 'FMRADIO', 'IRADIO']:
    st, t = get(f'https://www.ebs.co.kr/onair/scheduleNew.json?channelCodeString={code}&mode=newlist')
    n, now = 0, ''
    try:
        d = json.loads(t)
        n = len(d.get('program') or [])
        now = (d.get('nowProgram') or {}).get('title', '')
    except Exception:
        pass
    log(f'[{code}] 상태 {st} · 글자 수 {len(t)} · 편성 {n}개 · 지금: {now}')
    time.sleep(0.7)

# EBS 온에어 화면에서 채널 이름 후보 찾기
for page in ['https://www.ebs.co.kr/onair', 'https://www.ebs.co.kr/onair/radio', 'https://www.ebs.co.kr/radio/home']:
    st, t = get(page)
    log('=' * 60)
    log(f'{page} → 상태 {st} · 글자 수 {len(t)}')
    if st:
        for m in sorted(set(re.findall(r'channelCode(?:String)?["\']?\s*[:=]\s*["\']?([A-Z0-9_]+)', t)))[:30]:
            log('  채널 후보 ' + m)
        for m in sorted(set(re.findall(r'["\']([^"\'\s]*schedule[^"\'\s]*)["\']', t)))[:15]:
            log('  주소 후보 ' + m)
    time.sleep(0.7)

with open('radio_probe20_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe20_result.txt 를 올려 주세요')
