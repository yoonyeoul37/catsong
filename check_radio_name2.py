# -*- coding: utf-8 -*-
# 새로 찾은 방송 주소가 진짜 그 방송인지 이름(icy-name) 확인
import urllib.request
L = [
    ('성남FM (공식 홈페이지 링크)', 'http://115.85.182.39/seongnamfm'),
    ('(비교) 없는 이름', 'http://115.85.182.39/zz_test_123'),
    ('관악FM (공식 홈페이지 링크)', 'http://115.68.193.176:8000/gwanakfm'),
    ('라디오코리아 (공식 홈페이지 링크)', 'https://onairweb.radiokorea.com/live;stream/1'),
    ('WBS 원음방송', 'https://wbsradio.kr/wbs-seoul'),
]
for name, url in L:
    print(f'{name:28} {url}')
    try:
        req = urllib.request.Request(url, headers={'Icy-MetaData': '1', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as r:
            h = r.headers
            info = [f'{k}={h[k]}' for k in ('icy-name', 'icy-description', 'icy-url') if h.get(k)]
            data = r.read(4096)
            print('    ✔ 소리 받음 (%s, %d바이트)' % (h.get('Content-Type'), len(data)), ' / '.join(info))
    except Exception as e:
        print('    ❌ 연결 안 됨', e)
input('\n엔터를 누르면 닫혀요')
