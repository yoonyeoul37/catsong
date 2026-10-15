# -*- coding: utf-8 -*-
# TBS FM · eFM: 프로그램 목록 화면에 프로그램 이름 + 사진이 있는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe15.py  →  radio_probe15_result.txt 가 생겨요
import re, ssl, time, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def log(s=''):
    print(s)
    out.append(str(s))


def get(url):
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://tbs.seoul.kr/'}),
                                   timeout=20, context=ssl.create_default_context())
        return r.status, r.read().decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


for name, url in [('TBS FM 프로그램 목록', 'https://tbs.seoul.kr/fm/programsDay.do'),
                  ('TBS eFM 프로그램 목록', 'https://tbs.seoul.kr/eFm/programsDaily.do')]:
    log('#' * 60)
    st, txt = get(url)
    log(f'■ {name} {url} → 상태 {st} · 글자 수 {len(txt)}')
    if not st:
        log('  ' + txt)
        continue
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', txt, flags=re.S | re.I)
    # 사진 + 근처 글자 (프로그램 이름 찾기)
    n = 0
    for m in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*>', body):
        src = m.group(1)
        if re.search(r'/common/images/(gnb|btn|footer|news|tv/btnPrint)|logo|icon', src, re.I):
            continue
        near = re.sub(r'<[^>]+>', ' ', body[max(0, m.start() - 300): m.end() + 300])
        near = re.sub(r'\s+', ' ', near).strip()
        log(f'  사진 {src}')
        log(f'     근처 글자: {near[:160]}')
        n += 1
        if n >= 40:
            break
    log(f'  (사진 {n}개)')
    i = body.find('<img', body.find('container') if 'container' in body else 0)
    log('  --- 첫 사진 근처 HTML ---')
    log(body[max(0, i - 600): i + 1500] if i >= 0 else '  (없음)')
    time.sleep(1)

with open('radio_probe15_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe15_result.txt 를 올려 주세요')
