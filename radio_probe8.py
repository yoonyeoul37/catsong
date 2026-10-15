# -*- coding: utf-8 -*-
# CPBC · TBN · OBS · BeFM 편성표 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe8.py  →  radio_probe8_result.txt 가 생겨요
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def log(s=''):
    print(s)
    out.append(str(s))


def ctx(old=False):
    c = ssl.create_default_context()
    if old:  # 옛날 보안 방식 홈페이지도 열 수 있게
        c.set_ciphers('DEFAULT@SECLEVEL=0')
        try:
            c.minimum_version = ssl.TLSVersion.TLSv1
        except Exception:
            pass
        c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, referer=None, old=False):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
        if referer:
            h['Referer'] = referer
        req = urllib.request.Request(url, headers=h)
        with urllib.request.urlopen(req, timeout=20, context=ctx(old)) as r:
            raw = r.read()
            m = re.search(r'charset=([\w-]+)', r.headers.get('Content-Type', ''), re.I) \
                or re.search(r'charset=["\']?([\w-]+)', raw[:3000].decode('ascii', 'ignore'), re.I)
            try:
                return r.status, r.geturl(), raw.decode(m.group(1) if m else 'utf-8', errors='replace')
            except LookupError:
                return r.status, r.geturl(), raw.decode('utf-8', errors='replace')
    except Exception as e:
        return None, url, str(e)[:200]


def sched_links(base, html):
    found = []
    for href, text in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', html, re.S | re.I):
        t = re.sub(r'<[^>]+>|\s+', ' ', text).strip()
        if re.search(r'편성|schedule|timetable|sch', href + ' ' + t, re.I):
            u = urllib.parse.urljoin(base, href)
            if u not in [f[0] for f in found]:
                found.append((u, t[:30]))
    return found[:10]


def around_time(html, after=2500):
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', html, flags=re.S | re.I)
    m = re.search(r'\b\d{2}:\d{2}\b', body)
    return body[max(0, m.start() - 600): m.start() + after] if m else '  (시간 모양 글자 없음)'


def explore(name, homes, old=False):
    log('#' * 70)
    log(f'■ {name}')
    for home in homes:
        st, final, txt = get(home, old=old)
        log(f'  홈 {home} → 상태 {st} ({final}) · 글자 수 {len(txt)}')
        if not st:
            log('    ' + txt)
            continue
        if len(txt) < 4000:
            log('  --- 홈 전체 ---')
            log(txt)
        links = sched_links(final, txt)
        for u, t in links:
            log(f'  링크: [{t}] {u}')
        for u, _ in links[:3]:
            time.sleep(1)
            st2, _, t2 = get(u, final, old=old)
            log('  ' + '-' * 60)
            log(f'  [편성표 후보] {u} → 상태 {st2} · 글자 수 {len(t2)}')
            if st2:
                hints = sorted(set(re.findall(r'["\']([^"\'\s]*(?:ajax|json|api|[Ss]chedule)[^"\'\s]*)["\']', t2)))
                for h in [h for h in hints if len(h) < 150][:12]:
                    log('    데이터 주소 후보 ' + h)
                log(around_time(t2))
                imgs = [i for i in re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', t2) if not re.search(r'btn|ico|logo', i, re.I)]
                log('  --- 사진 후보 ---')
                for i in imgs[:12]:
                    log('    ' + i)
        if links:
            return
        time.sleep(1)


# ── CPBC: 홈페이지 스크립트 전체 + 모바일 홈페이지 ──
log('#' * 70)
log('■ CPBC 스크립트 전체')
st, _, js = get('https://www.cpbc.co.kr/javascript/cpbc-app.js', 'https://www.cpbc.co.kr/')
log(js if st else js)
explore('CPBC 모바일', ['https://m.cpbc.co.kr/', 'https://www.cpbc.co.kr/radio/', 'https://radio.cpbc.co.kr/'])

# ── TBN ──
explore('TBN', ['https://www.tbn.or.kr/', 'https://gyeongin.tbn.or.kr/', 'https://www.tbn.or.kr/gyeongin/'])

# ── OBS · BeFM (옛날 보안 방식으로) ──
explore('OBS 라디오', ['https://www.obs.co.kr/', 'http://www.obs.co.kr/'], old=True)
explore('BeFM', ['https://www.befm.or.kr/', 'http://www.befm.or.kr/'], old=True)

with open('radio_probe8_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe8_result.txt 를 올려 주세요')
