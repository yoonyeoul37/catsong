# -*- coding: utf-8 -*-
# 해외 라디오 2차 점검: 1차에서 안 나온 방송만 다시 확인 (+ 1차에서 빠진 나라는 처음부터)
# 1차 결과: "해외 라디오 점검 결과 1차.csv" (같은 폴더)
# 결과: "해외 라디오 점검 결과 2차.csv" — 두 번 다 확실히 안 나온 방송만 '빼기'로 표시
import csv, json, os, sys, time, socket, ssl, urllib.request, urllib.parse
from concurrent.futures import ThreadPoolExecutor
sys.stdout.reconfigure(encoding='utf-8')

IN1 = '해외 라디오 점검 결과 1차.csv'
OUT = '해외 라디오 점검 결과 2차.csv'
TIMEOUT = 15        # 2차는 더 넉넉하게 기다림
THREADS = 40
UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
API = 'https://de1.api.radio-browser.info'
OK_CTX = ssl.create_default_context()
LOOSE_CTX = ssl._create_unverified_context()  # 앱 재생기(mpv)는 인증서 검사를 안 해서, 인증서 문제는 앱에선 나옴
APP_COUNTRIES = 'AE,AL,AM,AR,AT,AU,AZ,BA,BD,BE,BG,BO,BR,CA,CH,CL,CM,CN,CO,CR,CU,CY,CZ,DE,DK,DO,EC,EE,EG,ES,ET,FI,FJ,FR,GB,GE,GH,GR,GT,HK,HN,HR,HT,HU,ID,IE,IL,IN,IQ,IR,IS,IT,JM,JO,JP,KE,KH,KZ,LA,LB,LK,LT,LU,LV,MA,ME,MG,MK,MM,MN,MT,MX,MY,MZ,NG,NI,NL,NO,NP,NZ,PA,PE,PG,PH,PK,PL,PR,PT,PY,RO,RS,RU,SA,SE,SG,SI,SK,SN,SV,TH,TN,TR,TT,TW,TZ,UA,UG,US,UY,UZ,VE,VN,ZA,ZW,DZ,QA,BH,KW,PS,YE,LY,OM,SD,CI,AO,BY,MD'.split(',')

def get_json(path, params, tries=4):
    url = f'{API}{path}?{urllib.parse.urlencode(params)}'
    for t in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Paransori/1.0'})
            with urllib.request.urlopen(req, timeout=60, context=OK_CTX) as r:
                return json.loads(r.read().decode('utf-8'))
        except Exception as e:
            if t == tries - 1: raise
            time.sleep(5)

def looks_audio(data):
    head = data[:64].lstrip().lower()
    return (head.startswith(b'#extm3u') or head.startswith(b'[playlist]') or head.startswith(b'id3')
            or head.startswith(b'oggs') or data[:2] in (b'\xff\xfb', b'\xff\xf3', b'\xff\xf2', b'\xff\xf1', b'\xff\xf9'))

def check(url):
    """('ok'|'fail', 이유, 확실히 안 나옴인지)"""
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA, 'Icy-MetaData': '0'})
        with urllib.request.urlopen(req, timeout=TIMEOUT, context=LOOSE_CTX) as r:
            ctype = (r.headers.get('Content-Type') or '').lower()
            data = r.read(16384)
            if not data:
                return 'fail', '받은 내용 없음', False
            if 'text/html' in ctype and not looks_audio(data):
                return 'fail', '방송이 아니라 웹페이지', True
            return 'ok', ctype or '알 수 없음', False
    except urllib.error.HTTPError as e:
        return 'fail', f'서버 오류 {e.code}', e.code in (400, 401, 403, 404, 410)
    except Exception as e:
        msg = str(e)
        if 'ICY 200' in msg:  # 옛날 방송 서버(Shoutcast) 방식: 재생기에선 정상
            return 'ok', 'ICY(옛날 방송 서버)', False
        if 'timed out' in msg:
            return 'fail', f'{TIMEOUT}초 안에 응답 없음', False
        if 'getaddrinfo' in msg or 'Name or service' in msg:
            return 'fail', '주소(도메인) 없음', True
        if '10061' in msg or 'refused' in msg.lower():
            return 'fail', '연결 거부', True
        return 'fail', msg[:80], False

def main():
    if not os.path.exists(IN1):
        print(f'❌ "{IN1}" 파일이 없어요. 1차 결과 파일 이름을 이걸로 바꿔 주세요.'); return
    rows1 = list(csv.DictReader(open(IN1, encoding='utf-8-sig')))
    done_codes = {r['나라'].rsplit('(', 1)[-1].rstrip(')') for r in rows1}
    redo = [r for r in rows1 if not r['결과'].startswith('✔')]
    print(f'1차에서 안 나온 방송 {len(redo)}개 다시 확인할게요')

    jobs = [(r['나라'], r['방송 이름'], r['형식'], r['주소'], r['방송 번호(uuid)'], r['이유']) for r in redo]
    missing = [c for c in APP_COUNTRIES if c not in done_codes]
    if missing:
        print(f'1차에서 빠진 나라 {len(missing)}개는 처음부터: {", ".join(missing)}')
        for code in missing:
            try:
                sts = get_json(f'/json/stations/bycountrycodeexact/{code}', {
                    'order': 'clickcount', 'reverse': 'true', 'offset': 0, 'limit': 100000,
                    'hidebroken': 'true', 'lastcheckok': '1', 'codec': 'MP3,AAC,AAC+,OGG'})
            except Exception as e:
                print(f'  ❌ {code}: 목록을 못 받았어요 ({e})'); continue
            print(f'  {code}: {len(sts)}개')
            for st in sts:
                jobs.append((f'({code})', st.get('name', '').strip(), st.get('codec', ''),
                             st.get('url_resolved') or st.get('url'), st.get('stationuuid', ''), '1차 없음'))

    with ThreadPoolExecutor(THREADS) as ex:
        res = list(ex.map(lambda j: check(j[3]), jobs))
    # 빠진 나라 방송은 1차가 없으니, 안 나온 것만 1분 뒤 한 번 더
    again = [i for i, j in enumerate(jobs) if j[5] == '1차 없음' and res[i][0] == 'fail']
    if again:
        print(f'빠진 나라에서 안 나온 {len(again)}개는 1분 뒤 한 번 더 확인할게요')
        time.sleep(60)
        with ThreadPoolExecutor(THREADS) as ex:
            res2 = list(ex.map(lambda i: check(jobs[i][3]), again))
        for i, r in zip(again, res2):
            if r[0] == 'ok': res[i] = r
            else: res[i] = (r[0], r[1], r[2] and res[i][2])

    rows = []; remove = 0
    for j, (st, why, sure) in zip(jobs, res):
        verdict = '빼기' if st == 'fail' and sure else ('살아남' if st == 'ok' else '보류(일시적일 수 있음)')
        if verdict == '빼기': remove += 1
        rows.append([j[0], j[1], verdict, j[5], why, j[2], j[3], j[4]])
    with open(OUT, 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['나라', '방송 이름', '판정', '1차 이유', '2차 이유', '형식', '주소', '방송 번호(uuid)'])
        w.writerows(rows)
    ok = sum(1 for r in rows if r[2] == '살아남')
    print(f'\n다시 본 {len(rows)}개 중: 살아남 {ok}개 · 빼기 {remove}개 · 보류 {len(rows)-ok-remove}개')
    print(f'→ "{OUT}" 저장했어요')

main()
