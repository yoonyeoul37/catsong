# -*- coding: utf-8 -*-
# 영어 문구 대문자 맞추기 (첫 글자만 대문자) — app_en.arb만 바꿔요
import os, json
P = os.path.join('lib', 'l10n', 'app_en.arb')
C = [
 ('editSong', 'Edit Song Info', 'Edit song info'),
 ('songInfo', 'Song Info', 'Song info'),
 ('sleepTimer', 'Sleep Timer', 'Sleep timer'),
 ('playbackSpeed', 'Playback Speed', 'Playback speed'),
 ('repeatMode', 'Repeat Mode', 'Repeat mode'),
 ('noRepeat', 'No Repeat', 'No repeat'),
 ('repeatOne', 'Repeat One', 'Repeat one'),
 ('repeatAll', 'Repeat All', 'Repeat all'),
 ('textSize', 'Text Size', 'Text size'),
 ('fontChange', 'Font Change', 'Font change'),
 ('playerStyle', 'Player Style', 'Player style'),
 ('sos', 'SOS Emergency Light', 'SOS emergency light'),
 ('ringtone', 'Set Ringtone', 'Set ringtone'),
 ('widget', 'Home Widget', 'Home widget'),
 ('version', 'Version Info', 'Version info'),
 ('promoCode', 'Promo Code', 'Promo code'),
 ('clearRecent', 'Clear Recent Songs', 'Clear recent songs'),
 ('playAll', 'Play All', 'Play all'),
 ('permissionRequired', 'Storage Permission Required', 'Storage permission required'),
 ('allowPermission', 'Allow Permission', 'Allow permission'),
 ('deleteSong', 'Delete Song', 'Delete song'),
 ('playNext', 'Play Next', 'Play next'),
 ('timerCancel', 'Cancel Timer', 'Cancel timer'),
 ('bassBooster', 'Bass Booster', 'Bass booster'),
 ('reviewButton', '⭐ Leave a Rating', '⭐ Leave a rating'),
 ('reviewLater', 'Maybe Later', 'Maybe later'),
 ('fontDefault', 'Default Font', 'Default font'),
 ('styleCD', 'CD Rotation', 'CD rotation'),
 ('styleCard', 'Album Art Card', 'Album art card'),
 ('noTitle', 'No Title', 'No title'),
 ('selectAll', 'Select All', 'Select all'),
 ('radioRecentListening', 'Recently Listened', 'Recently listened'),
 ('radioSelectCountry', 'Select Country', 'Select country'),
 ('remainingTime', 'Time Remaining', 'Time remaining'),
 ('cancelTimerX', '× Cancel Timer', '× Cancel timer'),
 ('categoryRegionalPrivate', 'Regional Private', 'Regional private'),
 ('categoryTraffic', 'Traffic Broadcasting', 'Traffic broadcasting'),
 ('regionCapital', 'Capital Area', 'Capital area'),
 ('selectSong', 'Select Song', 'Select song'),
 ('selectRange', 'Select Range', 'Select range'),
 ('updateReadyTitle', 'Update Ready', 'Update ready'),
 ('updateReadyButton', 'Restart Now', 'Restart now'),
 ('darkMode', 'Dark Mode', 'Dark mode'),
 ('rateApp', 'Rate App', 'Rate app'),
]
if not os.path.exists(P):
    print('❌ lib/l10n/app_en.arb 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); raise SystemExit
with open(P, 'r', encoding='utf-8', newline='') as f: t = f.read()
o = t; done = 0
for k, a, b in C:
    old = '%s: %s' % (json.dumps(k), json.dumps(a, ensure_ascii=False))
    new = '%s: %s' % (json.dumps(k), json.dumps(b, ensure_ascii=False))
    if t.count(old) == 1:
        t = t.replace(old, new); print('✔', a, '→', b)
    elif t.count(new) == 1:
        done += 1
    else:
        print('❌', k, '를 못 찾았어요 — 아무것도 저장 안 했어요'); raise SystemExit
if done == len(C):
    print('이미 적용돼 있어요'); raise SystemExit
try:
    json.loads(t)
except Exception as e:
    print('❌ 저장하면 파일이 깨져요 — 아무것도 저장 안 했어요', e); raise SystemExit
with open(P, 'w', encoding='utf-8', newline='') as f: f.write(t)
print('\n완료! %d개 바꿨어요' % (len(C) - done))
