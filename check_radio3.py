# -*- coding: utf-8 -*-
# '방송이 아니라 웹페이지'로 나온 방송 다시 보기:
# 옛날 방송 서버(Shoutcast)는 브라우저 이름표로 물으면 웹페이지를 주고, 재생기 이름표로 물으면 소리를 줌
# → ① 주소 끝에 ';' 붙이기 ② 재생기(VLC) 이름표로 묻기 — 둘 중 어느 쪽이면 나오는지 확인
import csv, sys, ssl, urllib.request
from concurrent.futures import ThreadPoolExecutor
sys.stdout.reconfigure(encoding='utf-8')
IN2 = '해외 라디오 점검 결과 2차.csv'
OUT = '웹페이지 방송 재확인.csv'
CTX = ssl._create_unverified_context()
BROWSER = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
PLAYER = 'VLC/3.0.20 LibVLC/3.0.20'

def is_audio(url, ua):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': ua, 'Icy-MetaData': '0'})
        with urllib.request.urlopen(req, timeout=12, context=CTX) as r:
            ct = (r.headers.get('Content-Type') or '').lower()
            data = r.read(8192)
            if not data: return False
            if 'text/html' in ct: return False
            return True
    except Exception as e:
        return 'ICY 200' in str(e)

def semi(url):
    return url if url.endswith(';') else (url + ';' if url.endswith('/') else url + '/;')

def test(row):
    url = row['주소']
    a = is_audio(semi(url), BROWSER)   # ① ';' 붙이고 지금 앱과 같은 이름표
    b = is_audio(url, PLAYER)          # ② 주소 그대로, 재생기 이름표
    return '둘 다' if a and b else ("';' 붙이면" if a else ('재생기 이름표면' if b else '안 됨'))

rows = [r for r in csv.DictReader(open(IN2, encoding='utf-8-sig'))
        if r['판정'] == '빼기' and '웹페이지' in r['2차 이유']]
print(f'웹페이지로 나온 {len(rows)}개 다시 확인할게요 (몇 분 걸려요)')
with ThreadPoolExecutor(40) as ex:
    res = list(ex.map(test, rows))
with open(OUT, 'w', newline='', encoding='utf-8-sig') as f:
    w = csv.writer(f)
    w.writerow(['나라', '방송 이름', '결과', '주소', '방송 번호(uuid)'])
    for r, x in zip(rows, res):
        w.writerow([r['나라'], r['방송 이름'], x, r['주소'], r['방송 번호(uuid)']])
from collections import Counter
for k, v in Counter(res).most_common(): print(f'  {k}: {v}개')
print(f'→ "{OUT}" 저장했어요')
