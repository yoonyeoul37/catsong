# -*- coding: utf-8 -*-
# 라디오 재생 화면 번역
import os, sys, json
KEYS = json.loads('{"castNeedsPlaying": ["방송이 나오고 있을 때 TV로 보낼 수 있어요", "You can send to TV while the station is playing", "放送の再生中にテレビへ送れます", "电台播放时才能投放到电视", "電台播放時才能投放到電視", null], "radioShareText": ["지금 {name} 듣고 있어요! 파란소리에서 같이 들어요 🎧", "I\'m listening to {name}! Listen with me on Paransori 🎧", "今{name}を聴いています！Paransoriで一緒に聴こう 🎧", "我正在听{name}！一起用Paransori收听吧 🎧", "我正在聽{name}！一起用Paransori收聽吧 🎧", {"name": "String"}], "radioShareSub": ["지금 듣는 방송을 소개해보세요.", "Share what you\'re listening to.", "聴いている放送を紹介しましょう。", "分享正在收听的电台。", "分享正在收聽的電台。", null], "savedSongAdded": ["저장한 곡에 넣었어요", "Added to saved songs", "保存した曲に追加しました", "已加入收藏歌曲", "已加入收藏歌曲", null], "savedSongRemoved": ["저장한 곡에서 뺐어요", "Removed from saved songs", "保存した曲から外しました", "已从收藏歌曲移除", "已從收藏歌曲移除", null], "smsJoin": ["문자 참여 #{number}", "Text in #{number}", "メッセージ参加 #{number}", "短信参与 #{number}", "簡訊參與 #{number}", {"number": "String"}], "tvPaused": ["TV에서 일시정지", "Paused on TV", "テレビで一時停止中", "电视上已暂停", "電視上已暫停", null], "similarStation": ["비슷한 방송 듣기 · {name}", "Similar station · {name}", "似た放送を聴く・{name}", "收听类似电台 · {name}", "收聽類似電台 · {name}", {"name": "String"}], "minutesLeft": ["{m}분 남음", "{m} min left", "残り{m}分", "剩余{m}分钟", "剩餘{m}分鐘", {"m": "int"}], "countItems": ["{count}개", "{count}", "{count}件", "{count}个", "{count}個", {"count": "int"}], "listeningNow": ["듣는 중", "Playing", "再生中", "正在收听", "正在收聽", null], "tapToListen": ["눌러서 바로 듣기", "Tap to listen", "タップしてすぐ聴く", "点击立即收听", "點擊立即收聽", null], "removedFromFav": ["즐겨찾기에서 뺐어요", "Removed from favorites", "お気に入りから外しました", "已从收藏中移除", "已從收藏中移除", null], "swipeToRemoveFav": ["왼쪽으로 밀면 즐겨찾기에서 빼요", "Swipe left to remove from favorites", "左にスワイプでお気に入りから外せます", "向左滑动可从收藏中移除", "向左滑動可從收藏中移除", null], "partDawn": ["새벽", "Early morning", "早朝", "凌晨", "凌晨", null], "partMorning": ["아침", "Morning", "朝", "早上", "早上", null], "partAfternoon": ["오후", "Afternoon", "午後", "下午", "下午", null], "partEvening": ["저녁 · 밤", "Evening · Night", "夕方・夜", "傍晚 · 夜间", "傍晚 · 夜間", null], "scheduledToast": ["예약했어요", "Scheduled", "予約しました", "已预约", "已預約", null], "scheduleFull": ["예약을 더 넣을 수 없어요. 예약 창에서 지난 예약을 지워주세요", "Can\'t add more. Delete old ones in Schedules.", "予約をこれ以上追加できません。予約画面で過去の予約を削除してください", "无法再添加预约，请在预约窗口删除旧的预约", "無法再新增預約，請在預約視窗刪除舊的預約", null], "nextShort": ["다음", "Next", "次", "下一个", "下一個", null], "todayFull": ["오늘 · {month}월 {day}일 {weekday}요일", "Today · {weekday}, {month}/{day}", "今日・{month}月{day}日({weekday})", "今天 · {month}月{day}日 周{weekday}", "今天 · {month}月{day}日 週{weekday}", {"month": "String", "day": "String", "weekday": "String"}], "onAirNow": ["지금 방송 중", "On air now", "放送中", "正在直播", "正在直播", null]}')
EDITS = json.loads('[["screens/radio_player_screen.dart", "import \'../widgets/paran_dialog.dart\';\\n", "import \'../widgets/paran_dialog.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["screens/radio_player_screen.dart", "showParanToast(context, \'방송이 나오고 있을 때 TV로 보낼 수 있어요\');", "showParanToast(context, tr.castNeedsPlaying);", 1], ["screens/radio_player_screen.dart", "? \'${radioProvider.sleepRemaining!.inMinutes + 1}분\'", "? tr.durM(radioProvider.sleepRemaining!.inMinutes + 1)", 1], ["screens/radio_player_screen.dart", "shareText: \'지금 ${current.name} 듣고 있어요! 파란소리에서 같이 들어요 🎧\',\\n                                        shareSubtitle: \'지금 듣는 방송을 소개해보세요.\',", "shareText: tr.radioShareText(current.name),\\n                                        shareSubtitle: tr.radioShareSub,", 1], ["screens/radio_player_screen.dart", "showParanToast(context, now ? \'저장한 곡에 넣었어요\' : \'저장한 곡에서 뺐어요\');", "showParanToast(context, now ? tr.savedSongAdded : tr.savedSongRemoved);", 1], ["screens/radio_player_screen.dart", "\'문자 참여 #$smsNumber\',", "tr.smsJoin(smsNumber),", 1], ["screens/radio_player_screen.dart", "? \'${CastService.instance.device?.name ?? \'TV\'}에서 재생 중\'\\n                                      : \'TV에서 일시정지\',", "? tr.castPlayingNow(CastService.instance.device?.name ?? \'TV\')\\n                                      : tr.tvPaused,", 1], ["screens/radio_player_screen.dart", "\'비슷한 방송 듣기 · ${radioProvider.similarStation!.name}\',", "tr.similarStation(radioProvider.similarStation!.name),", 1], ["screens/radio_player_screen.dart", "Text(\'${end - nowM}분 남음\', style:", "Text(tr.minutesLeft(end - nowM), style:", 1], ["screens/radio_player_screen.dart", "Text(\'${favorites.length}개\', style:", "Text(tr.countItems(favorites.length), style:", 1], ["screens/radio_player_screen.dart", "Text(\'듣는 중\',\\n", "Text(tr.listeningNow,\\n", 1], ["screens/radio_player_screen.dart", "child: Text(\'눌러서 바로 듣기\',", "child: Text(tr.tapToListen,", 1], ["screens/radio_player_screen.dart", "message: \'즐겨찾기에서 뺐어요\');", "message: tr.removedFromFav);", 1], ["screens/radio_player_screen.dart", "child: Text(\'왼쪽으로 밀면 즐겨찾기에서 빼요\', style:", "child: Text(tr.swipeToRemoveFav, style:", 1], ["screens/radio_player_screen.dart", "    if (h < 6) return \'새벽\';\\n    if (h < 12) return \'아침\';\\n    if (h < 18) return \'오후\';\\n    return \'저녁 · 밤\';", "    if (h < 6) return tr.partDawn;\\n    if (h < 12) return tr.partMorning;\\n    if (h < 18) return tr.partAfternoon;\\n    return tr.partEvening;", 1], ["screens/radio_player_screen.dart", "message: \'예약했어요\', icon:", "message: tr.scheduledToast, icon:", 1], ["screens/radio_player_screen.dart", "showParanToast(context, \'예약을 더 넣을 수 없어요. 예약 창에서 지난 예약을 지워주세요\');", "showParanToast(context, tr.scheduleFull);", 1], ["screens/radio_player_screen.dart", "child: Text(\'다음\',\\n", "child: Text(tr.nextShort,\\n", 1], ["screens/radio_player_screen.dart", "Text(\'오늘 · ${now.month}월 ${now.day}일 ${[\'월\', \'화\', \'수\', \'목\', \'금\', \'토\', \'일\'][now.weekday - 1]}요일\',", "Text(tr.todayFull(\'${now.month}\', \'${now.day}\', tr.weekdaysShort.split(\',\')[now.weekday - 1]),", 1], ["screens/radio_player_screen.dart", "Text(\'지금 방송 중\',\\n", "Text(tr.onAirNow,\\n", 1], ["screens/radio_player_screen.dart", "Text(\'${_hm(cur.start)} – ${_hm(cur.end)} · ${cur.end - nowM}분 남음\',", "Text(\'${_hm(cur.start)} – ${_hm(cur.end)} · ${tr.minutesLeft(cur.end - nowM)}\',", 1]]')
LANGS = ['ko', 'en', 'ja', 'zh', 'zh_Hant']
ROOT = 'lib'
def rd(p):
    with open(p, 'r', encoding='utf-8', newline='') as f: return f.read()
def wr(p, t):
    with open(p, 'w', encoding='utf-8', newline='') as f: f.write(t)
import re
STR = re.compile(r"'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\"|//[^\n]*")
def diff(s):
    s = STR.sub('', s)
    return [s.count(a) - s.count(b) for a, b in ['()', '[]', '{}']]
if not os.path.isdir(ROOT):
    print('❌ lib 폴더가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
out = {}
ok = True
# 1) 번역 문구 넣기
arbs = {}
for i, lang in enumerate(LANGS):
    p = os.path.join(ROOT, 'l10n', 'app_%s.arb' % lang)
    if not os.path.exists(p):
        print('❌', 'app_%s.arb' % lang, '파일이 없어요'); sys.exit(1)
    arbs[lang] = (p, rd(p))
have = json.loads(arbs['ko'][1])
if KEYS and all(k in have for k in KEYS):
    already_keys = True
else:
    already_keys = False
    for lang, (p, t) in arbs.items():
        d = json.loads(t)
        dup = [k for k in KEYS if k in d]
        if dup:
            print('❌', os.path.basename(p), '에 이미 있는 이름:', ', '.join(dup)); ok = False; continue
        nl = '\r\n' if '\r\n' in t else '\n'
        lines = []
        for k, v in KEYS.items():
            val = v[LANGS.index(lang)]
            lines.append('  %s: %s' % (json.dumps(k), json.dumps(val, ensure_ascii=False)))
            if lang in ('ko', 'en') and v[5]:
                ph = {name: {'type': typ} for name, typ in v[5].items()}
                lines.append('  %s: %s' % (json.dumps('@' + k), json.dumps({'placeholders': ph}, ensure_ascii=False)))
        end = t.rstrip()
        if not end.endswith('}'):
            print('❌', os.path.basename(p), '모양이 이상해요'); ok = False; continue
        body = end[:-1].rstrip()
        new = body + ',' + nl + (',' + nl).join(lines) + nl + '}' + (nl if t.endswith(('\n',)) else '')
        try:
            json.loads(new)
        except Exception as ex:
            print('❌', os.path.basename(p), '저장하면 깨져요', ex); ok = False; continue
        out[p] = new
        print('✔', os.path.basename(p), '문구 %d개' % len(KEYS))
# 2) 코드 고치기
done_edits = 0
for rel, old, new, cnt in EDITS:
    p = os.path.join(ROOT, rel)
    if p not in out:
        if not os.path.exists(p):
            print('❌', rel, '파일이 없어요'); ok = False; continue
        out[p] = rd(p)
    t = out[p]
    crlf = '\r\n' in t
    o = old.replace('\n', '\r\n') if crlf else old
    n = new.replace('\n', '\r\n') if crlf else new
    c = t.count(o)
    if (n and o in n and t.count(n) >= 1) or (c == 0 and (n == '' or t.count(n) >= 1)):
        done_edits += 1; continue
    if c != cnt:
        print('❌', rel, '고칠 곳을 못 찾았어요:', old.strip().splitlines()[0][:70]); ok = False; continue
    out[p] = t.replace(o, n)
if done_edits == len(EDITS) and already_keys:
    print('이미 적용돼 있어요'); sys.exit(0)
if done_edits and not ok:
    pass
if not ok:
    print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
for p, t in out.items():
    if p.endswith('.dart'):
        before = diff(rd(p)); after = diff(t)
        if before != after:
            print('❌', p, '괄호 개수가 안 맞아요'); print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
files = sorted(set(os.path.basename(r) for r, *_ in EDITS))
for p, t in out.items(): wr(p, t)
for f in files: print('✔', f)
print('다 됐어요 (코드 %d곳)' % (len(EDITS) - done_edits))
