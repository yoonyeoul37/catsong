# -*- coding: utf-8 -*-
# CPBC 라디오 편성 데이터 · TBN 경인/울산 첫 화면 편성 · BeFM 프로그램 목록 모양 (앱 코드는 안 건드려요)
# 실행: python radio_probe18.py  →  radio_probe18_result.txt 가 생겨요
import json, re, ssl, time, datetime, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
today = datetime.date.today()


def log(s=''):
    print(s)
    out.append(str(s))


def ctx():
    c = ssl.create_default_context()
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, referer=None):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
        if referer:
            h['Referer'] = referer
        r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=20, context=ctx())
        raw = r.read()
        m = re.search(r'charset=([\w-]+)', r.headers.get('Content-Type', ''), re.I) \
            or re.search(r'charset=["\']?([\w-]+)', raw[:3000].decode('ascii', 'ignore'), re.I)
        try:
            return r.status, raw.decode(m.group(1) if m else 'utf-8', 'replace')
        except LookupError:
            return r.status, raw.decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


# ── CPBC ──
log('#' * 60)
log('■ CPBC 라디오 편성 데이터')
for u in [f'https://static.apis.cpbc.co.kr/radio-api/schedule/01/{today:%Y%m%d}',
          f'https://apis.cpbc.co.kr/radio-api/schedule/{today:%Y%m%d}']:
    st, t = get(u, 'https://www.cpbc.co.kr/')
    log(f'  {u} → 상태 {st} · 글자 수 {len(t)}')
    if not st:
        log('    ' + t)
        continue
    try:
        d = json.loads(t)
    except Exception:
        log('    (JSON 아님) ' + t[:500])
        continue
    items = d if isinstance(d, list) else (d.get('items') or d.get('list') or d.get('data') or [])
    log(f'    종류 {type(d).__name__} · 칸 {len(items) if isinstance(items, list) else "?"}개')
    if isinstance(items, list) and items:
        log('    --- 첫 칸 통째로 ---')
        log(json.dumps(items[0], ensure_ascii=False, indent=1)[:2500])
        log('    --- 앞 25칸 요약 ---')
        for it in items[:25]:
            p = it.get('program') or {}
            img = ((p.get('images') or {}).get('horizontal')) if isinstance(p, dict) else None
            log(f"    {it.get('startTime') or it.get('START_DATE') or it.get('start')} ~ "
                f"{it.get('endTime') or it.get('END_DATE') or it.get('end')} | {p.get('title') if isinstance(p, dict) else ''} | {img}")
    else:
        log('    ' + t[:1500])
    time.sleep(1)

# ── TBN 경인 · 울산 ──
for area, name in [('6', '경인'), ('9', '울산')]:
    log('#' * 60)
    log(f'■ TBN {name} 첫 화면 편성')
    st, t = get(f'https://www.tbn.or.kr/main.tbn?area_code={area}')
    log(f'  상태 {st} · 글자 수 {len(t)}')
    if not st:
        continue
    rows = re.findall(r'<a[^>]+href=["\']([^"\']*program/main\.tbn[^"\']*)["\'][^>]*>(.*?)</a>', t, re.S)
    seen = set()
    for href, inner in rows:
        tx = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', inner)).strip()
        if tx in seen:
            continue
        seen.add(tx)
        log(f'    {tx[:60]}  ←  {href}')
    i = t.find('program/main.tbn')
    log('  --- 첫 프로그램 링크 근처 HTML ---')
    log(t[max(0, i - 1500): i + 1500])
    time.sleep(1)

# ── BeFM ──
log('#' * 60)
log('■ BeFM 첫 화면 프로그램 목록')
st, t = get('https://www.befm.or.kr/main.php?lang=ko')
if st:
    i = t.find('pg=allstar')
    log(t[max(0, i - 1200): i + 3500])

with open('radio_probe18_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe18_result.txt 를 올려 주세요')
