# -*- coding: utf-8 -*-
# OBS 라디오 편성표 화면 한 줄 모양 보기 + 지금 만든 OBS 편성 목록 (앱 코드는 안 건드려요)
# 실행: python radio_probe9.py  →  radio_probe9_result.txt 가 생겨요
import json, re, ssl, datetime, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def log(s=''):
    print(s)
    out.append(str(s))


c = ssl.create_default_context()
c.set_ciphers('DEFAULT@SECLEVEL=0')
c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
d = datetime.date.today()
url = f'https://www.obs.co.kr/schedule/?type=radio&year={d.year}&month={d.month:02d}&day={d.day:02d}'
req = urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://www.obs.co.kr/schedule/?type=radio'})
html = urllib.request.urlopen(req, timeout=20, context=c).read().decode('utf-8', 'replace')
log(f'[OBS 라디오 화면] {url} · 글자 수 {len(html)}')
i = html.find('tbl_radio_schedule')
log(html[i - 300: i + 4000] if i >= 0 else '  (표 없음)')
log('--- 사진 후보 전부 ---')
for u in re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', html):
    if not re.search(r'desktop/(OBS|search|all|btn|sch_icon)', u):
        log('  ' + u)
log('--- 배경 사진 후보 ---')
for u in re.findall(r'url\(["\']?([^"\')]+)', html)[:20]:
    log('  ' + u)

log('=' * 60)
log('[지금 만든 schedule.json 의 OBS 라디오 금요일]')
try:
    with open('assets/schedule.json', encoding='utf-8') as f:
        data = json.load(f)
    for p in data.get('OBS 라디오', {}).get('friday', []):
        log(f"  {p['start']}~{p['end']}  {p['title']}")
except Exception as e:
    log(f'  못 읽음: {e}')

with open('radio_probe9_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe9_result.txt 를 올려 주세요')
