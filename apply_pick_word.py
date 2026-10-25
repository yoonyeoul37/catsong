# -*- coding: utf-8 -*-
# 한국어 화면 글자: '골라·고른·고르기' → '선택' (문장에 맞게)
# 바꾸지 않는 것: 앙골라(나라 이름) · '음량을 고르게'(뜻이 다름) · '주사위가 고른 방송'(주사위는 고른다가 자연스러움)
# app_ko.arb + app_localizations_ko.dart 둘 다 (flutter gen-l10n 안 돌려도 바로 보이게)
import os, re, sys

ARB = os.path.join('lib', 'l10n', 'app_ko.arb')
DART = os.path.join('lib', 'l10n', 'app_localizations_ko.dart')

# (키, 지금 글자, 바꿀 글자)
WORDS = [
    ('pickedPhotos', '고른 사진', '선택한 사진'),
    ('pickRightArt', '맞는 앨범 사진을 골라 주세요', '맞는 앨범 사진을 선택해 주세요'),
    ('savePart', '구간 골라서 저장', '구간 선택해서 저장'),
    ('saveMusicNote', '고른 구간의 소리만 음악 목록에 저장해요 (Music/Paransori · M4A)',
     '선택한 구간의 소리만 음악 목록에 저장해요 (Music/Paransori · M4A)'),
    ('pickTime', '시간 고르기', '시간 선택'),
    ('pickFromSchedule', '편성표에서 프로그램으로 고르기', '편성표에서 프로그램 선택'),
    ('pickVersion', '{name} 버전 고르기', '{name} 버전 선택'),
    ('pickType', '종류 고르기', '종류 선택'),
    ('infoTodaySongD', '내 음악에서 매일 한 곡을 골라 줘요', '내 음악에서 매일 한 곡을 추천해 줘요'),
    ('pickAlarmSong', '알람 곡 고르기', '알람 곡 선택'),
    ('pickPlaylist', '재생목록 고르기', '재생목록 선택'),
    ('pickRadioChannel', '라디오 채널 고르기', '라디오 채널 선택'),
    ('pickNatureSound', '자연 소리 고르기', '자연 소리 선택'),
    ('noDaysOnce', '요일을 하나도 안 고르면 한 번만 울려요', '요일을 하나도 선택하지 않으면 한 번만 울려요'),
    ('oneSongSub', '고른 노래 하나를 반복해서', '선택한 노래 하나를 반복해서'),
    ('helpCarUse3', '음악 · 라디오 · 팟캐스트 · 자연소리 탭에서 원하는 콘텐츠를 골라요.',
     '음악 · 라디오 · 팟캐스트 · 자연소리 탭에서 원하는 콘텐츠를 선택해요.'),
]


def dart_text(s):
    return re.sub(r'\{(\w+)\}', r'$\1', s).replace("'", "\\'")


def main():
    for p in (ARB, DART):
        if not os.path.exists(p):
            print('❌ 파일이 없어요:', p)
            sys.exit(1)
    raw = {p: open(p, 'rb').read().decode('utf-8') for p in (ARB, DART)}
    crlf = {p: '\r\n' in raw[p] for p in raw}
    arb = raw[ARB].replace('\r\n', '\n')
    dart = raw[DART].replace('\r\n', '\n')
    if '"pickedPhotos": "선택한 사진"' in arb:
        print('이미 적용돼 있어요')
        return
    ok = True
    for key, old, new in WORDS:
        a_old = '"%s": "%s"' % (key, old)
        if arb.count(a_old) != 1:
            print('❌ app_ko.arb %s 못 찾았어요' % key)
            ok = False
        else:
            arb = arb.replace(a_old, '"%s": "%s"' % (key, new))
            print('✔ app_ko.arb %s' % key)
        m = re.search(r'(get %s\b|\b%s\()' % (key, key), dart)
        d_old, d_new = "'%s'" % dart_text(old), "'%s'" % dart_text(new)
        i = dart.find(d_old, m.end()) if m else -1
        if m is None or i < 0 or i - m.end() > 300:
            print('❌ app_localizations_ko.dart %s 못 찾았어요' % key)
            ok = False
        else:
            dart = dart[:i] + d_new + dart[i + len(d_old):]
            print('✔ app_localizations_ko.dart %s' % key)
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for p, t in ((ARB, arb), (DART, dart)):
        if crlf[p]:
            t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
