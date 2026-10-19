# 해외 라디오 점검: 앱과 같은 조건으로 나라별 인기 방송을 받아와서, 실제로 소리가 나오는지(접속되는지) 확인
# 결과: 같은 폴더에 "해외 라디오 점검 결과.csv" (엑셀로 열림)
# 파이썬만 있으면 됨 (따로 설치할 것 없음)
import json, csv, sys, time, urllib.request, urllib.parse, ssl
from concurrent.futures import ThreadPoolExecutor

# 앱 해외 라디오에 있는 나라만 (models/radio_country.dart, 한국은 국내 목록이라 뺌)
APP_COUNTRIES = 'AE,AL,AM,AR,AT,AU,AZ,BA,BD,BE,BG,BO,BR,CA,CH,CL,CM,CN,CO,CR,CU,CY,CZ,DE,DK,DO,EC,EE,EG,ES,ET,FI,FJ,FR,GB,GE,GH,GR,GT,HK,HN,HR,HT,HU,ID,IE,IL,IN,IQ,IR,IS,IT,JM,JO,JP,KE,KH,KZ,LA,LB,LK,LT,LU,LV,MA,ME,MG,MK,MM,MN,MT,MX,MY,MZ,NG,NI,NL,NO,NP,NZ,PA,PE,PG,PH,PK,PL,PR,PT,PY,RO,RS,RU,SA,SE,SG,SI,SK,SN,SV,TH,TN,TR,TT,TW,TZ,UA,UG,US,UY,UZ,VE,VN,ZA,ZW,DZ,QA,BH,KW,PS,YE,LY,OM,SD,CI,AO,BY,MD'.split(',')
# ALL_COUNTRIES = True 이면 앱에 있는 나라 전부 점검 (아래 COUNTRIES 목록은 무시)
ALL_COUNTRIES = True
# ALL_COUNTRIES = False 일 때만 쓰는 나라 목록
COUNTRIES = {
    'US': '미국', 'GB': '영국', 'DE': '독일', 'FR': '프랑스', 'ES': '스페인', 'MX': '멕시코',
    'BR': '브라질', 'PT': '포르투갈', 'IT': '이탈리아', 'PL': '폴란드', 'RU': '러시아',
    'TR': '튀르키예', 'ID': '인도네시아', 'VN': '베트남', 'TH': '태국', 'JP': '일본',
    'TW': '대만', 'IN': '인도',
}
PER_COUNTRY = 100000     # 나라마다 인기순 몇 개 (앱 목록 맨 위에 보이는 것들)
TIMEOUT = 8          # 방송 하나 기다리는 시간(초)
THREADS = 40         # 동시에 몇 개씩 확인할지
UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'  # 앱과 같은 이름표
API = 'https://de1.api.radio-browser.info'
ctx = ssl.create_default_context()

def get_json(path, params):
    url = f'{API}{path}?{urllib.parse.urlencode(params)}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Paransori/1.0'})
    with urllib.request.urlopen(req, timeout=20, context=ctx) as r:
        return json.loads(r.read().decode('utf-8'))

def check(st):
    url = st.get('url_resolved') or st.get('url')
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA, 'Icy-MetaData': '0'})
        with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as r:
            ctype = (r.headers.get('Content-Type') or '').lower()
            data = r.read(16384)
            if not data:
                return '❌ 안 나옴', '받은 내용 없음'
            if 'text/html' in ctype:
                return '❌ 안 나옴', '방송이 아니라 웹페이지'
            if 'mpegurl' in ctype or url.lower().split('?')[0].endswith('.m3u8'):
                return '✔ 나옴', 'HLS(m3u8)'
            return '✔ 나옴', ctype or '알 수 없음'
    except urllib.error.HTTPError as e:
        return '❌ 안 나옴', f'서버 오류 {e.code}'
    except Exception as e:
        msg = str(e)
        if 'timed out' in msg: msg = f'{TIMEOUT}초 안에 응답 없음'
        elif 'CERTIFICATE' in msg.upper(): msg = '보안 인증서 문제'
        return '❌ 안 나옴', msg[:80]

def save(rows, out):
    with open(out, 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['나라', '방송 이름', '결과', '이유', '형식', '주소', '방송 번호(uuid)'])
        w.writerows(rows)

def main():
    rows = []
    out = '해외 라디오 점검 결과.csv'
    countries = COUNTRIES
    if ALL_COUNTRIES:
        try:
            data = get_json('/json/countries', {'hidebroken': 'true'})
            names = {c['iso_3166_1']: c['name'] for c in data if c.get('iso_3166_1')}
            countries = {code: names.get(code, code) for code in APP_COUNTRIES}
        except Exception as e:
            print(f'나라 목록을 못 받아서 기본 18개 나라만 할게요 ({e})')
    print(f'나라 {len(countries)}개 점검 시작 (나라마다 인기 방송 {PER_COUNTRY}개) — 시간이 꽤 걸려요\n')
    for i, (code, name) in enumerate(countries.items(), 1):
        name = f'{name} ({code})'
        try:
            sts = get_json(f'/json/stations/bycountrycodeexact/{code}', {
                'order': 'clickcount', 'reverse': 'true', 'offset': 0, 'limit': PER_COUNTRY,
                'hidebroken': 'true', 'lastcheckok': '1', 'codec': 'MP3,AAC,AAC+,OGG'})
        except Exception as e:
            print(f'❌ {name}: 목록을 못 받았어요 ({e})'); continue
        if not sts:
            continue
        with ThreadPoolExecutor(THREADS) as ex:
            res = list(ex.map(check, sts))
        bad = sum(1 for r in res if r[0].startswith('❌'))
        print(f'[{i}/{len(countries)}] {name}: {len(sts)}개 중 {len(sts)-bad}개 나옴, {bad}개 안 나옴')
        for st, (ok, why) in zip(sts, res):
            rows.append([name, st.get('name', '').strip(), ok, why, st.get('codec', ''), st.get('url_resolved') or st.get('url'), st.get('stationuuid', '')])
        save(rows, out)  # 나라 하나 끝날 때마다 저장 (중간에 꺼져도 남게)
    total = len(rows); bad = sum(1 for r in rows if r[2].startswith('❌'))
    print(f'\n전체 {total}개 중 {total-bad}개 나옴, {bad}개 안 나옴 → "{out}" 저장했어요')

main()
