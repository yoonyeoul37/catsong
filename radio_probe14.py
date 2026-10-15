# -*- coding: utf-8 -*-
# BBS 불교방송: 프로그램마다 진짜 사진이 있는 화면 찾기 (앱 코드는 안 건드려요)
# 단서: 1207(이효주의 싱싱라디오) 진짜 사진 = UploadProgramImg/c482c80404c2dece11a7.jpg
# 실행: python radio_probe14.py  →  radio_probe14_result.txt 가 생겨요
import re, ssl, time, urllib.request

out = []
PC = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
MOBILE = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
REAL = 'c482c80404c2dece11a7'


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, ua):
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': ua, 'Accept-Language': 'ko-KR'}),
                                   timeout=20, context=c)
        return r.status, r.read().decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


pages = [
    ('PC 프로그램 홈', 'https://www.bbsi.co.kr/?ACT=RADIO&MODE=HOME&ProgramCode={c}', PC),
    ('PC HOME2 프로그램 홈', 'https://www.bbsi.co.kr/HOME2/?ACT=RADIO&MODE=HOME&ProgramCode={c}', PC),
    ('모바일 다시듣기', 'https://m.bbsi.co.kr/M/?ACT=RADIO_REPLAY_VIEW_BOARD&APP_END&ProgramCode={c}', MOBILE),
    ('모바일 프로그램', 'https://m.bbsi.co.kr/M/?ACT=RADIO_PROGRAM&ProgramCode={c}', MOBILE),
    ('모바일 프로그램 목록', 'https://m.bbsi.co.kr/M/?ACT=RADIO_PROGRAM_LIST', MOBILE),
    ('모바일 라디오 첫 화면', 'https://m.bbsi.co.kr/M/?ACT=RADIO_FM', MOBILE),
]
for code in ['1207', '2349']:
    log('#' * 60)
    log(f'■ 프로그램 번호 {code}')
    for name, url, ua in pages:
        u = url.format(c=code)
        st, txt = get(u, ua)
        imgs = re.findall(r'[^"\'\s(]*UploadProgramImg/[\w.\-]+', txt)
        log(f'  [{name}] {u} → 상태 {st} · 글자 수 {len(txt)} · 진짜 사진 있음: {"예" if REAL in txt else "아니오"} · 사진 {len(imgs)}개')
        for m in list(re.finditer(r'UploadProgramImg/[\w.\-]+', txt))[:6]:
            ctx = re.sub(r'\s+', ' ', txt[max(0, m.start() - 200): m.end() + 60])
            log('    … ' + ctx)
        og = re.search(r'og:image["\'][^>]+content=["\']([^"\']+)', txt)
        if og:
            log('    og:image ' + og.group(1))
        time.sleep(0.7)

with open('radio_probe14_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe14_result.txt 를 올려 주세요')
