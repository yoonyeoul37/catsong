# -*- coding: utf-8 -*-
# 팟캐스트 0단계 점검: 애플 팟캐스트 '나라별 인기 순위'와 '검색'이 되는지,
# 회차 목록(RSS)을 읽고 소리 파일이 실제로 열리는지 확인
# 결과: "팟캐스트 점검 결과.txt"
import json, time, urllib.request, urllib.parse, xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor

UA = 'Paransori/1.0 (Android) podcast-check'
# 파란소리 23개 언어 → 그 언어를 많이 쓰는 나라 (애플 나라 코드)
COUNTRIES = [
    ('한국어', 'kr'), ('영어', 'us'), ('일본어', 'jp'), ('중국어 간체', 'cn'), ('중국어 번체', 'tw'),
    ('독일어', 'de'), ('스페인어', 'es'), ('프랑스어', 'fr'), ('이탈리아어', 'it'), ('포르투갈어', 'br'),
    ('폴란드어', 'pl'), ('러시아어', 'ru'), ('튀르키예어', 'tr'), ('인도네시아어', 'id'), ('베트남어', 'vn'),
    ('태국어', 'th'), ('우크라이나어', 'ua'), ('힌디어', 'in'), ('루마니아어', 'ro'), ('체코어', 'cz'),
    ('헝가리어', 'hu'), ('아랍어', 'sa'), ('우르두어', 'pk'),
]
# 한국 라디오 프로그램이 팟캐스트로 있는지 검색해 볼 낱말
KR_SEARCH = ['컬투쇼', '배철수의 음악캠프', '두시탈출 컬투쇼', '정오의 희망곡', '여성시대', 'KBS 라디오', 'MBC 라디오', 'SBS 라디오', 'EBS 라디오', 'CBS 라디오']


def get(url, timeout=20):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def top_chart(cc, n=25):
    url = f'https://rss.applemarketingtools.com/api/v2/{cc}/podcasts/top/{n}/podcasts.json'
    try:
        d = json.loads(get(url))
        return [(x.get('name', ''), x.get('id', ''), x.get('artistName', '')) for x in d['feed']['results']], None
    except Exception as e:
        return [], str(e)[:80]


def lookup(pid, cc):
    try:
        d = json.loads(get(f'https://itunes.apple.com/lookup?id={pid}&entity=podcast&country={cc}'))
        r = d.get('results') or [{}]
        return r[0].get('feedUrl'), r[0].get('primaryGenreName', ''), r[0].get('artworkUrl600', '')
    except Exception:
        return None, '', ''


def feed_check(feed):
    """회차 수 · 최신 회차 날짜 · 첫 회차 소리 파일이 열리는지"""
    if not feed:
        return '주소 없음'
    try:
        root = ET.fromstring(get(feed, 25))
    except Exception as e:
        return f'회차 목록 못 읽음 ({str(e)[:40]})'
    items = root.findall('./channel/item')
    if not items:
        return '회차 0개'
    latest = (items[0].findtext('pubDate') or '').strip()[:16]
    enc = items[0].find('enclosure')
    url = enc.get('url') if enc is not None else None
    if not url:
        return f'회차 {len(items)}개 · 최신 {latest} · 소리 주소 없음'
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA, 'Range': 'bytes=0-4095'})
        with urllib.request.urlopen(req, timeout=15) as r:
            ok = len(r.read(4096)) > 1000
        sound = '소리 ✔' if ok else '소리 ✖(데이터 없음)'
    except Exception as e:
        sound = f'소리 ✖({str(e)[:30]})'
    return f'회차 {len(items)}개 · 최신 {latest} · {sound}'


def search(term, cc='kr', n=5):
    q = urllib.parse.urlencode({'term': term, 'media': 'podcast', 'country': cc, 'limit': n})
    try:
        d = json.loads(get(f'https://itunes.apple.com/search?{q}'))
        return [(r.get('collectionName', ''), r.get('artistName', ''), r.get('feedUrl')) for r in d.get('results', [])], None
    except Exception as e:
        return [], str(e)[:80]


def main():
    out = [f'팟캐스트 점검 결과 ({time.strftime("%Y-%m-%d %H:%M")})', '']

    # ① 나라별 인기 순위
    print('① 나라별 인기 순위 받는 중…')
    with ThreadPoolExecutor(8) as ex:
        charts = list(ex.map(lambda c: top_chart(c[1]), COUNTRIES))
    out.append('■ ① 나라별 인기 순위 (애플 팟캐스트 상위 25)')
    for (lang, cc), (rows, err) in zip(COUNTRIES, charts):
        if err:
            out.append(f'   ✖ {lang}({cc}): 못 받음 — {err}')
        else:
            out.append(f'   ✔ {lang}({cc}): {len(rows)}개 — 1위 {rows[0][0] if rows else "-"}')
    out.append('')

    # ② 한국 순위 상위 10개: 회차 목록·소리 확인
    print('② 한국 인기 10개 회차 목록·소리 확인 중…')
    kr = charts[0][0][:10]
    with ThreadPoolExecutor(8) as ex:
        looks = list(ex.map(lambda r: lookup(r[1], 'kr'), kr))
        checks = list(ex.map(lambda l: feed_check(l[0]), looks))
    out.append('■ ② 한국 인기 상위 10 — 회차 목록과 소리')
    for i, ((name, _, artist), (feed, genre, _), chk) in enumerate(zip(kr, looks, checks), 1):
        out.append(f'   {i}. {name} ({artist}) · {genre or "분야 ?"} · {chk}')
    out.append('')

    # ③ 다른 나라 1위 몇 개도 소리 확인
    print('③ 다른 나라 1위 소리 확인 중…')
    picks = [(lang, cc, rows[0]) for (lang, cc), (rows, err) in zip(COUNTRIES[1:], charts[1:]) if rows][:10]
    with ThreadPoolExecutor(8) as ex:
        looks2 = list(ex.map(lambda p: lookup(p[2][1], p[1]), picks))
        checks2 = list(ex.map(lambda l: feed_check(l[0]), looks2))
    out.append('■ ③ 다른 나라 1위 — 회차 목록과 소리')
    for (lang, cc, row), chk in zip(picks, checks2):
        out.append(f'   {lang}: {row[0]} · {chk}')
    out.append('')

    # ④ 한국 라디오 프로그램 검색
    print('④ 한국 라디오 프로그램 검색 중…')
    out.append('■ ④ 한국 라디오 프로그램이 팟캐스트로 있는지 (검색 상위 5)')
    for term in KR_SEARCH:
        rows, err = search(term)
        if err:
            out.append(f'   ✖ "{term}": 검색 안 됨 — {err}')
            continue
        names = ' / '.join(f'{n}({a})' for n, a, _ in rows) or '없음'
        out.append(f'   "{term}": {names}')
    out.append('')

    open('팟캐스트 점검 결과.txt', 'w', encoding='utf-8').write('\n'.join(out))
    print('✔ 저장했어요: 팟캐스트 점검 결과.txt')


if __name__ == '__main__':
    main()
