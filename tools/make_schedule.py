# -*- coding: utf-8 -*-
# 라디오 편성표 자동 만들기 → assets/schedule.json
# 지금은 CBS 음악FM · CBS 표준FM (CBS 홈페이지 편성표 데이터 + 프로그램 사진)
# CBS는 '오늘' 편성만 주기 때문에, 매일 돌리면 그날 요일 칸이 새로 바뀌어요
# 실행: python tools/make_schedule.py   (GitHub에서는 매일 새벽 자동으로)
import json, sys, datetime, urllib.request, os, re

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'schedule.json')
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'

# CBS 데이터의 방송 번호 → 앱의 방송국 이름
CBS_MEDIA = {'radio001': 'CBS 음악FM', 'radio002': 'CBS 표준FM'}
# CBS 프로그램 사진: 앞에 있는 것부터 씀
CBS_IMAGE_KEYS = ['vod', 'mobileTop', 'mainTop', 'programBanner', 'radioProfil']


def get_json(url, referer):
    req = urllib.request.Request(url, headers={
        'User-Agent': UA, 'Referer': referer, 'X-Requested-With': 'XMLHttpRequest',
        'Accept-Language': 'ko-KR,ko;q=0.9'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode('utf-8'))


def day_key(d):
    # 앱(schedule_service.dart)이 쓰는 이름: 월~목 = weekday, 금 = friday, 토 = saturday, 일 = sunday
    return {4: 'friday', 5: 'saturday', 6: 'sunday'}.get(d.weekday(), 'weekday')


def base_title(t):
    # "최강희의 영화음악 (재)" → "최강희의 영화음악" (재방송도 같은 사진 쓰기)
    return re.sub(r'\s*\((재|재방송)\)\s*$', '', t).strip()


def cbs_image(it):
    img = ((it.get('program') or {}).get('image')) or {}
    for k in CBS_IMAGE_KEYS:
        v = (img.get(k) or '').strip() if isinstance(img, dict) else ''
        if v:
            return v if v.startswith('http') else 'https://www.cbs.co.kr' + v
    return None


def cbs():
    """{방송국: {요일칸: [프로그램...]}} — 데이터에 있는 날짜(보통 오늘)만"""
    data = get_json('https://www.cbs.co.kr/schedule/radio/ajax', 'https://www.cbs.co.kr/schedule')
    by = {}
    for key, items in (data.items() if isinstance(data, dict) else []):
        if not isinstance(items, list):
            continue
        for it in items:
            if not isinstance(it, dict):
                continue
            station = CBS_MEDIA.get(((it.get('media') or {}).get('id')) or '')
            date, start, end = it.get('date'), it.get('startTime'), it.get('endTime')
            title = (it.get('name') or '').strip()
            if not (station and date and start and end and title):
                continue
            p = {'title': title, 'start': start[:5], 'end': end[:5]}
            img = cbs_image(it)
            if img:
                p['image'] = img
            by.setdefault(station, {}).setdefault(date, []).append(p)
    out = {}
    for station, days in by.items():
        for date, progs in days.items():
            progs.sort(key=lambda p: p['start'])
            seen, clean = set(), []
            for p in progs:  # 같은 시작 시간이 두 번 있으면 하나만
                if p['start'] not in seen:
                    seen.add(p['start'])
                    clean.append(p)
            if len(clean) >= 5:
                out.setdefault(station, {})[day_key(datetime.date.fromisoformat(date))] = clean
    return out


def fill_images(week):
    # 재방송처럼 사진이 없는 칸: 같은 프로그램 이름의 사진을 빌려 쓰기 (다른 요일 것도)
    pics = {}
    for progs in week.values():
        for p in progs:
            if p.get('image'):
                pics.setdefault(base_title(p['title']), p['image'])
    for progs in week.values():
        for p in progs:
            if not p.get('image') and base_title(p['title']) in pics:
                p['image'] = pics[base_title(p['title'])]


def main():
    try:
        with open(OUT, encoding='utf-8') as f:
            old = json.load(f)
    except Exception:
        old = {}
    new = json.loads(json.dumps(old))  # 깊은 복사
    ok = 0
    for name, fn in [('CBS', cbs)]:
        try:
            got = fn()
        except Exception as e:
            print(f'❌ {name} 못 가져옴 (예전 편성표 그대로 둠): {e}')
            continue
        if not got:
            print(f'❌ {name} 편성표가 비어 있음 (예전 편성표 그대로 둠)')
            continue
        for station, days in got.items():
            week = new.get(station) or {}
            week.update(days)  # 오늘 요일 칸만 새로 (나머지 요일은 예전 것 그대로)
            for k in ('weekday', 'friday', 'saturday', 'sunday'):
                week.setdefault(k, [])
            fill_images(week)
            new[station] = week
            for k, v in days.items():
                print(f'✔ {station} [{k}] 프로그램 {len(v)}개 · 사진 {sum(1 for p in v if p.get("image"))}개')
            ok += 1
    if ok == 0:
        print('❌ 새로 가져온 편성표가 없어요 — 파일을 바꾸지 않았어요')
        sys.exit(1)
    if new == old:
        print('바뀐 게 없어요 (편성 그대로)')
        return
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(new, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print('완료! assets/schedule.json 을 새로 저장했어요')


if __name__ == '__main__':
    main()