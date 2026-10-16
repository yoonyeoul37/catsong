# -*- coding: utf-8 -*-
# 남은 방송 편성표 · 사진 찾기: 원주MBC · MBC강원영동 · TBC 드림FM · 아리랑 · BeFM · 마포FM · 수원SoneFM · 성서공동체FM · 전주FM
# (앱 코드는 안 건드려요)   실행: python radio_probe50.py  →  radio_probe50_result.txt (몇 분 걸려요)
import re, ssl, time, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, ref=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if ref:
        h['Referer'] = ref
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=15, context=ctx())
    raw = r.read()
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


TIMES = re.compile(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b|\b\d{1,2}시\s*\d{1,2}분')
SITES = [
    ('원주MBC', ['https://www.wjmbc.co.kr/', 'https://wjmbc.co.kr/']),
    ('MBC강원영동', ['https://www.mbceg.co.kr/', 'https://mbceg.co.kr/']),
    ('TBC 드림FM', ['https://www.tbc.co.kr/']),
    ('아리랑 라디오', ['https://www.arirang.com/radio', 'https://www.arirang.com/']),
    ('BeFM', ['https://www.befm.or.kr/', 'https://befm.or.kr/']),
    ('마포FM', ['https://www.mapofm.net/', 'http://mapofm.net/', 'http://www.mapofm.net/']),
    ('수원 SoneFM', ['https://www.sonefm.kr/', 'http://sonefm.kr/', 'https://www.suwonfm.kr/', 'http://www.sonefm.com/']),
    ('성서공동체FM', ['https://www.scnfm.or.kr/', 'http://scnfm.or.kr/', 'http://www.scnfm.kr/']),
    ('전주FM', ['https://www.jcfm.kr/', 'http://jcfm.or.kr/', 'https://jjfm.kr/', 'http://www.jeonjufm.kr/']),
]


def scan(item):
    name, homes = item
    L = [f'■ {name}']
    for home in homes:
        try:
            final, t = get(home)
        except Exception as e:
            L.append(f'  {home} → X {str(e)[:50]}')
            continue
        L.append(f'  {home} → {final} · 글자 수 {len(t)}')
        if len(t) < 1500:
            L.append('    (전체) ' + re.sub(r'\s+', ' ', t)[:400])
        links = []
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I):
            a = re.sub(r'<[^>]+>|\s+', ' ', a).strip()
            if re.search(r'편성|schedule|timetable|program|프로그램|라디오|radio|onair', h + ' ' + a, re.I):
                v = urllib.parse.urljoin(final, h)
                if v not in [x[0] for x in links] and not v.startswith('javascript'):
                    links.append((v, a[:20]))
        for v, a in links[:18]:
            L.append(f'    링크 [{a}] {v}')
        for v, a in [x for x in links if re.search(r'편성|schedule|timetable', x[0] + x[1], re.I)][:4]:
            try:
                f2, t2 = get(v, final)
            except Exception as e:
                L.append(f'    [편성 페이지] {v} → X {str(e)[:40]}')
                continue
            tx = text(t2)
            tm = TIMES.findall(tx)
            imgs = [x for x in re.findall(r'<img[^>]+src=["\']([^"\']+)', t2) if not re.search(r'logo|icon|btn|sns|common', x, re.I)]
            L.append(f'    [편성 페이지] {v} → 시간 {len(tm)}개 · 사진 {len(imgs)}개')
            if len(tm) >= 8:
                i = tx.find(tm[2])
                L.append('      … ' + tx[max(0, i - 150): i + 700])
            for x in imgs[:3]:
                L.append(f'      사진 {urllib.parse.urljoin(f2, x)}')
            time.sleep(0.2)
        break
    return L


out = []
with cf.ThreadPoolExecutor(4) as ex:
    for L in ex.map(scan, SITES):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe50_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe50_result.txt 를 올려 주세요')
