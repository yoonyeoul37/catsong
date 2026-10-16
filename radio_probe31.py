# -*- coding: utf-8 -*-
# 춘천MBC 라디오 편성표 모양 보기 + 울산MBC 편성 게시판 안 보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe31.py  →  radio_probe31_result.txt 가 생겨요
import re, ssl, datetime, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
tomorrow = datetime.date.today() + datetime.timedelta(days=1)


def log(s=''):
    print(s)
    out.append(str(s))


def get(url):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=20, context=c)
    return r.geturl(), r.read().decode('utf-8', 'replace')


def body(t):
    return re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)


# ── 1) 춘천MBC: 시간 칸 주변 HTML 그대로 ──
for label, url in [('표준FM 오늘', 'https://chmbc.co.kr/guide2/channel/radio2'),
                   ('음악FM 오늘', 'https://chmbc.co.kr/guide2/channel/radio'),
                   ('표준FM 내일(date 주소)', f'https://chmbc.co.kr/guide2/channel/radio2/date/{tomorrow:%Y-%m-%d}')]:
    log('#' * 70)
    try:
        final, t = get(url)
    except Exception as e:
        log(f'■ 춘천 {label} 못 가져옴 {e}')
        continue
    b = body(t)
    i = b.find('05시 00분')
    log(f'■ 춘천 {label} {final} · 첫 시간 위치 {i}')
    if i >= 0:
        log(re.sub(r'\n\s*\n+', '\n', b[max(0, i - 1500): i + 4500]))
    imgs = [u for u in re.findall(r'<img[^>]+src=["\']([^"\']+)', b) if not re.search(r'logo|icon|btn|/common/', u, re.I)]
    log('  --- 사진 후보 ---')
    for u in imgs[:12]:
        log('  ' + urllib.parse.urljoin(final, u))
    if 'date' not in url:
        break_after = False

# ── 2) 울산MBC: 편성 게시판 첫 글 ──
log('#' * 70)
try:
    final, t = get('https://www.usmbc.co.kr/StandardFMProgramming')
    b = body(t)
    posts = sorted(set(re.findall(r'href=["\']([^"\']*StandardFMProgramming/[^"\']+)["\']', b)))
    log(f'■ 울산 표준FM 편성 게시판 글 링크 {posts[:10]}')
    i = b.find('Radio편성표', b.find('<main') if '<main' in b else 0)
    j = b.find('board') if b.find('board') > 0 else i
    log(re.sub(r'\s+', ' ', re.sub(r'<(?!img|a )[^>]+>', ' ', b[j: j + 3000])))
    if posts:
        u = urllib.parse.urljoin(final, posts[0])
        f2, t2 = get(u)
        b2 = body(t2)
        log(f'  첫 글 {f2}')
        for a in re.findall(r'(?:src|href)=["\']([^"\']+\.(?:jpg|jpeg|png|gif|pdf|hwp|xlsx?|docx?))["\']', b2, re.I)[:10]:
            log('  첨부·그림 ' + urllib.parse.urljoin(f2, a))
        times = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b', b2)
        log(f'  글 안 시간 글자 {len(times)}개 {times[:10]}')
except Exception as e:
    log(f'■ 울산 못 가져옴 {e}')

with open('radio_probe31_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe31_result.txt 를 올려 주세요')
