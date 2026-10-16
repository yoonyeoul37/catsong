# -*- coding: utf-8 -*-
# TBN 프로그램 소개 페이지에 사진이 있는지 보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe26.py  →  radio_probe26_result.txt 가 생겨요
import re, ssl, time, datetime, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
today = datetime.date.today()


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, raw=False):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://www.tbn.or.kr/main.tbn'}),
                               timeout=20, context=c)
    b = r.read()
    if raw:
        return r.status, r.headers.get('Content-Type', ''), len(b)
    return b.decode('utf-8', 'replace')


# 1) 편성표에서 프로그램 번호(forum_seq) 모으기: 본부 · 경인 · 부산
progs = {}
for code, label in [(1, '본부'), (6, '경인'), (2, '부산')]:
    try:
        t = get(f'https://www.tbn.or.kr/broadcast/program.tbn?area_code=6&page_code={code}&today={today:%Y%m%d}')
    except Exception as e:
        log(f'■ {label} 편성표 못 가져옴: {e}')
        continue
    found = re.findall(r'forum_seq=(\d+)\s*(?:&amp;|&)area_code=(\d+)"\s*>\s*<strong>(.*?)</strong>', t, re.S)
    log(f'■ {label} 편성표: 프로그램 링크 {len(found)}개')
    for seq, area, title in found:
        progs.setdefault(seq, (title.strip(), area, label))
    time.sleep(0.5)

# 2) 프로그램 소개 페이지마다 사진 찾기
SKIP = re.compile(r'/images/common/|icon|btn_|/btn|logo|blank|bullet|cal0', re.I)
for n, (seq, (title, area, label)) in enumerate(list(progs.items())[:14]):
    url = f'https://www.tbn.or.kr/program/main.tbn?forum_seq={seq}&area_code={area}'
    log('#' * 60)
    log(f'■ [{label}] {title} · {url}')
    try:
        t = get(url)
    except Exception as e:
        log(f'  못 가져옴: {e}')
        continue
    og = re.findall(r'property=["\']og:image["\']\s+content=["\']([^"\']+)', t)
    log(f'  og:image {og[:2]}')
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)
    imgs = []
    for m in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*>', body, re.I):
        u = m.group(1)
        if SKIP.search(u):
            continue
        imgs.append((urllib.parse.urljoin(url, u), m.group(0)[:200]))
    bgs = re.findall(r'background(?:-image)?\s*:\s*url\(([^)]+)\)', t)
    for u, tag in imgs[:8]:
        log(f'  사진 후보 {u}')
        log(f'     태그 {tag}')
    for b in bgs[:5]:
        log(f'  배경 사진 후보 {b}')
    # 첫 후보가 실제로 열리는지
    if imgs:
        try:
            st, ct, size = get(imgs[0][0], raw=True)
            log(f'  → 첫 사진 열기: {st} {ct} {size}바이트')
        except Exception as e:
            log(f'  → 첫 사진 열기 실패: {e}')
    if n == 0:  # 첫 페이지는 본문 모양도 조금 보기
        i = body.find('forum')
        log('  --- 첫 페이지 본문 일부 ---')
        j = max(body.find('id="contents"'), body.find('class="contents'), 0)
        log(re.sub(r'\n\s*\n+', '\n', body[j: j + 4000]))
    time.sleep(0.6)

with open('radio_probe26_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe26_result.txt 를 올려 주세요')
