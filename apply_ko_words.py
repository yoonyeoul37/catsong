# -*- coding: utf-8 -*-
# 한국어 문구 다듬기: '섞기/섞어서' → 믹스·랜덤, '틀어놓고/틀려면' → 자연스러운 말 (app_ko.arb 7곳)
import os, sys

PATH = os.path.join('lib', 'l10n', 'app_ko.arb')

EDITS = [
    ('지난번 섞기 → 지난번 믹스',
     '"lastMix": "지난번 섞기"',
     '"lastMix": "지난번 믹스"'),
    ('빗소리 섞기 → 빗소리 믹스',
     '"infoTipsD": "벨소리 만들기, 빗소리 섞기 같은 팁"',
     '"infoTipsD": "벨소리 만들기, 빗소리 믹스 같은 팁"'),
    ('섞어서 재생 → 랜덤 재생',
     '"genreShuffle": "{label} {n}곡 섞어서 재생"',
     '"genreShuffle": "{label} {n}곡 랜덤 재생"'),
    ('섞어서 틀어요 → 랜덤으로 들려줘요',
     '"infoLongTimeD": "한 달 동안 안 들은 곡을 섞어서 틀어요"',
     '"infoLongTimeD": "한 달 동안 안 들은 곡을 랜덤으로 들려줘요"'),
    ('파도소리 틀어놓고 쉬어요 → 파도소리와 함께 쉬어가요',
     '"dailyEveningLine": "파도소리 틀어놓고 쉬어요"',
     '"dailyEveningLine": "파도소리와 함께 쉬어가요"'),
    ('빗소리 틀어놓고 쉬어요 → 빗소리와 함께 쉬어가요',
     '"dailyNightLine": "빗소리 틀어놓고 쉬어요"',
     '"dailyNightLine": "빗소리와 함께 쉬어가요"'),
    ('알람 곡을 틀려면 → 음악이 재생되도록 하려면',
     '"alarmBatteryAsk": "정해진 시간에 알람 곡을 틀려면 ',
     '"alarmBatteryAsk": "정해진 시간에 음악이 재생되도록 하려면 '),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    raw = open(PATH, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if all(new in text for _, _, new in EDITS):
        print('이미 적용돼 있어요'); return 0
    ok = True
    for name, old, new in EDITS:
        if new in text:
            print('✔', name, '(이미 바뀌어 있음)'); continue
        n = text.count(old)
        if n == 1:
            text = text.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok = False
    try:
        import json; json.loads(text)
    except Exception as e:
        print('❌ 번역 파일 모양이 깨졌어요:', e); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print('\n저장했어요:', PATH)
    return 0

if __name__ == '__main__':
    sys.exit(main())
