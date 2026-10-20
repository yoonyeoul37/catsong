# -*- coding: utf-8 -*-
# 한국 음악방송 점검: Radio Browser에서 한국 방송을 모두 받아
# 장르(트로트·가요·발라드·댄스 등)로 나누고, 실제로 소리가 나오는지 하나씩 확인
# 결과: "한국 음악방송 점검 결과.txt" (사람이 보는 것) + "한국 음악방송 점검 결과.csv"
import csv, json, re, sys, time, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor

SERVERS = ['de1.api.radio-browser.info', 'de2.api.radio-browser.info', 'fi1.api.radio-browser.info', 'nl1.api.radio-browser.info']
UA = 'VLC/3.0.20 LibVLC/3.0.20'  # 앱과 같은 재생기 이름표

# 장르 → 찾을 낱말 (태그·이름에 들어 있으면 그 장르)
GENRES = [
    ('트로트', ['trot', '트로트', 'enka', '성인가요', '뽕짝']),
    ('가요·K-POP', ['k-pop', 'kpop', 'k pop', '가요', 'korean pop', 'kpop hits', 'idol']),
    ('발라드', ['ballad', '발라드']),
    ('댄스·EDM', ['dance', '댄스', 'edm', 'electronic', 'club']),
    ('7080·추억', ['7080', '8090', 'oldies', 'retro', '추억', '옛노래', '90s', '80s', '70s']),
    ('OST·드라마', ['ost', 'soundtrack', 'drama']),
    ('힙합·R&B', ['hip hop', 'hiphop', '힙합', 'r&b', 'rnb']),
    ('인디·록', ['indie', '인디', 'rock', '록']),
    ('재즈·클래식', ['jazz', '재즈', 'classical', '클래식', 'lounge']),
    ('국악', ['국악', 'gugak', 'traditional']),
]
NOT_MUSIC = ['news', '뉴스', 'talk', 'religio', 'christian', 'gospel', 'buddh', '불교', '기독', '교회', 'church', 'catholic', '천주', 'sport', 'traffic', '교통']


def get_json(path):
    last = None
    for s in SERVERS:
        try:
            req = urllib.request.Request(f'https://{s}{path}', headers={'User-Agent': 'Paransori/1.0'})
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.loads(r.read().decode('utf-8'))
        except Exception as e:
            last = e
    raise SystemExit(f'❌ Radio Browser 서버에 연결 못 했어요: {last}')


def _has(text, w):
    # 영어 낱말은 따로 떨어진 것만 (ost가 host·most에 걸리지 않게), 한글은 들어 있기만 하면
    if w.isascii():
        return re.search(r'(?<![a-z])' + re.escape(w) + r'(?![a-z])', text) is not None
    return w in text


def genres_of(st):
    text = (st.get('tags', '') + ' ' + st.get('name', '')).lower()
    return [g for g, words in GENRES if any(_has(text, w) for w in words)]


def is_not_music(st):
    text = (st.get('tags', '') + ' ' + st.get('name', '')).lower()
    return any(w in text for w in NOT_MUSIC)


def check_stream(st):
    """소리가 나오는지: 주소에 붙어서 실제로 데이터가 오는지 (최대 10초)"""
    url = st.get('url_resolved') or st.get('url')
    if not url:
        return '주소 없음'
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA, 'Icy-MetaData': '0'})
        with urllib.request.urlopen(req, timeout=10) as r:
            ctype = (r.headers.get('Content-Type') or '').lower()
            data = r.read(32 * 1024)
            if 'text/html' in ctype:
                return '웹페이지(소리 아님)'
            if len(data) < 2048 and not ('mpegurl' in ctype or url.split('?')[0].endswith(('.m3u8', '.m3u', '.pls'))):
                return '데이터 거의 없음'
            return '잘 나옴'
    except urllib.error.HTTPError as e:
        return f'안 나옴({e.code})'
    except Exception as e:
        msg = str(e)
        if 'timed out' in msg:
            return '안 나옴(응답 없음)'
        return '안 나옴(연결 실패)'


def main():
    print('한국 방송 목록 받는 중…')
    all_kr = get_json('/json/stations/bycountrycodeexact/KR?hidebroken=false&limit=5000')
    # 같은 방송 여러 번 → 표 많은 것 하나만
    seen = {}
    for st in all_kr:
        key = (st.get('url_resolved') or st.get('url') or st.get('stationuuid'))
        if key not in seen or st.get('votes', 0) > seen[key].get('votes', 0):
            seen[key] = st
    stations = list(seen.values())
    print(f'한국 방송 {len(all_kr)}개 (같은 주소 합치면 {len(stations)}개)')

    music = []
    for st in stations:
        g = genres_of(st)
        if g and not is_not_music(st):
            music.append((st, g))
    print(f'음악 장르 방송 {len(music)}개 — 소리 나오는지 확인 중 (몇 분 걸려요)…')

    with ThreadPoolExecutor(max_workers=16) as ex:
        results = list(ex.map(lambda x: check_stream(x[0]), music))

    rows = []
    for (st, g), res in zip(music, results):
        rows.append({
            '장르': ' / '.join(g),
            '방송 이름': st.get('name', '').strip(),
            '결과': res,
            '표(인기)': st.get('votes', 0),
            '최근 클릭': st.get('clickcount', 0),
            '음질': f"{st.get('codec','')} {st.get('bitrate',0)}kbps".strip(),
            '마지막 점검 정상': '예' if st.get('lastcheckok') == 1 else '아니오',
            '홈페이지': st.get('homepage', ''),
            '태그': st.get('tags', ''),
            '주소': st.get('url_resolved') or st.get('url'),
            'uuid': st.get('stationuuid', ''),
        })
    rows.sort(key=lambda r: (r['장르'], r['결과'] != '잘 나옴', -int(r['표(인기)'] or 0)))

    with open('한국 음악방송 점검 결과.csv', 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else ['장르'])
        w.writeheader()
        w.writerows(rows)

    ok = [r for r in rows if r['결과'] == '잘 나옴']
    lines = [f'한국 음악방송 점검 결과 ({time.strftime("%Y-%m-%d %H:%M")})',
             f'한국 방송 {len(stations)}개 중 음악 장르 {len(rows)}개 · 잘 나옴 {len(ok)}개', '']
    for gname, _ in GENRES:
        g_rows = [r for r in rows if gname in r['장르'].split(' / ')]
        g_ok = [r for r in g_rows if r['결과'] == '잘 나옴']
        lines.append(f'■ {gname}: {len(g_ok)}개 잘 나옴 / 전체 {len(g_rows)}개')
        for r in g_rows:
            mark = '✔' if r['결과'] == '잘 나옴' else '✖'
            lines.append(f"   {mark} {r['방송 이름']}  [{r['결과']}]  표 {r['표(인기)']} · {r['음질']} · {r['홈페이지']}")
        lines.append('')
    open('한국 음악방송 점검 결과.txt', 'w', encoding='utf-8').write('\n'.join(lines))
    print('\n'.join(lines[:3]))
    print('✔ 저장했어요: 한국 음악방송 점검 결과.txt · 한국 음악방송 점검 결과.csv')


if __name__ == '__main__':
    main()
