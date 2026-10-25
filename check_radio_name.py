# -*- coding: utf-8 -*-
# 찾은 주소가 진짜 그 방송인지 확인 — 방송 서버가 보내는 '방송 이름(icy-name)'을 읽어 보기
# 아무 이름이나 붙여도 소리가 나오는 서버인지도 같이 확인 (없는 이름 zz_test_123)
import ssl, urllib.request

UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

URLS = [
    ('없는 이름(시험)', 'http://115.85.182.39/zz_test_123'),
    ('관악FM?', 'http://115.85.182.39/gfm'),
    ('관악FM?', 'http://115.85.182.39/gwanakfm'),
    ('성남FM?', 'http://115.85.182.39/snfm'),
    ('성남FM?', 'http://115.85.182.39/sbnfm'),
    ('서대문FM?', 'http://115.85.182.39/sdmfm'),
    ('서대문FM?', 'http://115.85.182.39/myfm'),
    ('구리FM?', 'http://115.85.182.39/gurifm'),
    ('서대문FM(공식 듣기 링크)', 'http://115.68.193.176:8000/sdmfm'),
    ('단원FM', 'http://radiostream.communityradio.kr/dwfm1'),
    ('(비교) 수원 SoneFM', 'http://115.85.182.39/sonefm'),
    ('(비교) 성서공동체FM', 'http://115.85.182.39/scnfm'),
    ('라디오서울', 'https://onair1.radioseoul1650.com/radioseoul.mp3'),
]

lines = []
for label, u in URLS:
    try:
        req = urllib.request.Request(u, headers={'User-Agent': UA, 'Icy-MetaData': '1'})
        with urllib.request.urlopen(req, timeout=10, context=CTX) as r:
            h = r.headers
            info = ' / '.join('%s=%s' % (k, h.get(k)) for k in ('icy-name', 'icy-description', 'icy-genre', 'icy-url')
                              if h.get(k))
            row = '%-22s %s\n    → %s' % (label, u, info or '(방송 이름 정보 없음, %s)' % h.get('Content-Type'))
    except Exception as e:
        row = '%-22s %s\n    → 연결 안 됨 (%s)' % (label, u, str(e)[:60])
    print(row)
    lines.append(row)

with open('방송 이름 확인 결과.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('\n✔ 다 됐어요 → "방송 이름 확인 결과.txt" 를 보내 주세요')
