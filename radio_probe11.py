# -*- coding: utf-8 -*-
# BBS 불교방송: 막히지 않은 편성표 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe11.py  →  radio_probe11_result.txt 가 생겨요
import re, ssl, time, datetime, urllib.request, http.cookiejar

out = []
today = datetime.date.today()
PC = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
MOBILE = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'


def log(s=''):
    print(s)
    out.append(str(s))


cj = http.cookiejar.CookieJar()
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj), urllib.request.HTTPSHandler(context=c))


def get(url, ua=PC, referer=None):
    h = {'User-Agent': ua, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    try:
        r = op.open(urllib.request.Request(url, headers=h), timeout=20)
        return r.status, r.read().decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


def show(title, url, ua=PC, referer=None):
    log('=' * 60)
    st, txt = get(url, ua, referer)
    blocked = 'Detect client IP' in txt
    log(f'■ {title} {url} → 상태 {st} · 글자 수 {len(txt)} · 차단화면 {"예" if blocked else "아니오"}')
    if not st or blocked:
        return txt
    hints = sorted(set(re.findall(r'["\']([^"\'\s]*(?:ajax|Ajax|[Ss]chedule|SCHEDULE|json)[^"\'\s]*)["\']', txt)))
    for h in [h for h in hints if len(h) < 160][:20]:
        log('  데이터 주소 후보 ' + h)
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', txt, flags=re.S | re.I)
    m = re.search(r'\b\d{2}:\d{2}\b', body)
    log('  --- 첫 시간 근처 HTML ---')
    log(body[max(0, m.start() - 800): m.start() + 3000] if m else '  (시간 모양 글자 없음)')
    time.sleep(1)
    return txt


show('PC 편성표', 'https://www.bbsi.co.kr/?ACT=SCHEDULE', referer='https://www.bbsi.co.kr/')
show('PC 편성표(라디오)', f'https://www.bbsi.co.kr/?ACT=SCHEDULE&SchGubun=RADIO&SchDate={today:%Y-%m-%d}',
     referer='https://www.bbsi.co.kr/?ACT=SCHEDULE')
m = show('모바일 라디오 첫 화면', 'https://m.bbsi.co.kr/M/?ACT=RADIO_FM', MOBILE)
show('모바일 편성표', 'https://m.bbsi.co.kr/M/?ACT=SCHEDULE', MOBILE, 'https://m.bbsi.co.kr/M/?ACT=RADIO_FM')

# 모바일 첫 화면 스크립트 안에서 편성표 부르는 코드
log('=' * 60)
log('■ 모바일 첫 화면 안 ajaxSchedule 부르는 코드')
i = m.find('ajaxSchedule') if isinstance(m, str) else -1
log(m[max(0, i - 1500): i + 800] if i >= 0 else '  (없음)')

with open('radio_probe11_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe11_result.txt 를 올려 주세요')
