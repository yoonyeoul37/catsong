# 해외 라디오 서버에는 있는데 파란소리 앱에는 없는 나라 목록 (방송 많은 순)
# 결과: 같은 폴더에 "앱에 없는 나라.csv"
import json, csv, urllib.request, ssl

APP = set('KR,AE,AL,AM,AR,AT,AU,AZ,BA,BD,BE,BG,BO,BR,CA,CH,CL,CM,CN,CO,CR,CU,CY,CZ,DE,DK,DO,EC,EE,EG,ES,ET,FI,FJ,FR,GB,GE,GH,GR,GT,HK,HN,HR,HT,HU,ID,IE,IL,IN,IQ,IR,IS,IT,JM,JO,JP,KE,KH,KZ,LA,LB,LK,LT,LU,LV,MA,ME,MG,MK,MM,MN,MT,MX,MY,MZ,NG,NI,NL,NO,NP,NZ,PA,PE,PG,PH,PK,PL,PR,PT,PY,RO,RS,RU,SA,SE,SG,SI,SK,SN,SV,TH,TN,TR,TT,TW,TZ,UA,UG,US,UY,UZ,VE,VN,ZA,ZW'.split(','))

req = urllib.request.Request('https://de1.api.radio-browser.info/json/countries?hidebroken=true',
                             headers={'User-Agent': 'Paransori/1.0'})
with urllib.request.urlopen(req, timeout=30, context=ssl.create_default_context()) as r:
    data = json.loads(r.read().decode('utf-8'))

rows = sorted(((c['iso_3166_1'], c['name'], c.get('stationcount', 0)) for c in data
               if c.get('iso_3166_1') and c['iso_3166_1'] not in APP), key=lambda x: -x[2])
with open('앱에 없는 나라.csv', 'w', newline='', encoding='utf-8-sig') as f:
    w = csv.writer(f)
    w.writerow(['나라 코드', '나라 이름', '방송 수'])
    w.writerows(rows)

print(f'앱에 없는 나라: {len(rows)}개 (방송 많은 순)\n')
for code, name, n in rows:
    print(f'{code}  {name}: {n}개')
print('\n"앱에 없는 나라.csv" 저장했어요')
