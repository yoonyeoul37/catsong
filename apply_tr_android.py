# -*- coding: utf-8 -*-
# 파란소리 안드로이드 쪽(위젯·알림) 번역
# 실행: C:\apps\mp3_player_new 에서  python apply_tr_android.py
import os, sys, re

BASE = sys.argv[1] if len(sys.argv) > 1 else os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(BASE, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(BASE, 'res')

# key: (en, ko, ja, zh 간체, zh 번체)
S = [
 ('app_name', 'Paransori', '파란소리', 'Paransori', 'Paransori', 'Paransori'),
 ('widget_idle_sub', 'Music · Radio · Nature', '음악 · 라디오 · 자연을 들어보세요', '音楽・ラジオ・自然', '音乐 · 广播 · 自然', '音樂 · 廣播 · 自然'),
 ('widget_loading', 'Loading…', '불러오는 중…', '読み込み中…', '正在加载…', '正在載入…'),
 ('widget_wait', 'Please wait a moment', '잠시만 기다려 주세요', '少々お待ちください', '请稍候', '請稍候'),
 ('widget_play_music', 'Play some music', '음악을 재생해보세요', '音楽を再生してみてください', '播放一些音乐吧', '播放一些音樂吧'),
 ('tab_music', 'Music', '음악', '音楽', '音乐', '音樂'),
 ('tab_radio', 'Radio', '라디오', 'ラジオ', '广播', '廣播'),
 ('tab_nature', 'Nature', '자연', '自然', '自然', '自然'),
 ('tab_sleep', 'Sleep', '수면', 'スリープ', '睡眠', '睡眠'),
 ('widget_recent_empty', 'Recently played items show up here', '최근에 들은 게 여기에 나와요', '最近聴いたものがここに表示されます', '最近收听的内容会显示在这里', '最近收聽的內容會顯示在這裡'),
 ('sample_song', 'Favorite song', '좋아하는 노래', 'お気に入りの曲', '喜欢的歌曲', '喜歡的歌曲'),
 ('sample_artist', 'Artist', '가수', '歌手', '歌手', '歌手'),
 ('sample_station', 'Radio station', '라디오 방송', 'ラジオ局', '广播电台', '廣播電台'),
 ('sample_rain', 'Rain', '빗소리', '雨の音', '雨声', '雨聲'),
 ('sample_nature', 'Nature sounds', '자연소리', '自然の音', '自然声音', '自然聲音'),
 ('alarm_channel', 'Morning alarm', '아침 알람', '朝のアラーム', '早晨闹钟', '早晨鬧鐘'),
 ('alarm_channel_desc', 'Paransori morning alarm', '파란소리 아침 알람', 'Paransori 朝のアラーム', 'Paransori 早晨闹钟', 'Paransori 早晨鬧鐘'),
 ('alarm_quiet_channel', 'Morning alarm (open screen)', '아침 알람 (화면 열기)', '朝のアラーム（画面を開く）', '早晨闹钟（打开画面）', '早晨鬧鐘（開啟畫面）'),
 ('alarm_quiet_desc', 'When the alarm screen opens over the lock screen', '잠금화면 위로 알람 화면을 열 때', 'ロック画面の上にアラーム画面を開くとき', '在锁屏上方打开闹钟画面时', '在鎖定畫面上方開啟鬧鐘畫面時'),
 ('alarm_text', 'Tap to open the alarm screen', '눌러서 알람 화면 열기', 'タップしてアラーム画面を開く', '点按打开闹钟画面', '點按開啟鬧鐘畫面'),
 ('headset_channel', 'Earphone connected', '이어폰 연결 알림', 'イヤホン接続のお知らせ', '耳机连接通知', '耳機連接通知'),
 ('action_play', 'Play', '재생', '再生', '播放', '播放'),
 ('resume_ask', 'Continue listening?', '이어서 들을까요?', '続きを聴きますか？', '要继续收听吗？', '要繼續收聽嗎？'),
 ('rec_channel', 'Recording', '녹음', '録音', '录音', '錄音'),
 ('rec_channel_desc', 'Shown while recording', '녹음 중일 때 알림창에 표시', '録音中に通知に表示', '录音时在通知栏显示', '錄音時在通知欄顯示'),
 ('rec_title_paused', 'Paransori · Recording paused', '파란소리 녹음 일시정지', 'Paransori 録音一時停止中', 'Paransori 录音已暂停', 'Paransori 錄音已暫停'),
 ('rec_title_on', 'Paransori · Recording', '파란소리 녹음 중', 'Paransori 録音中', 'Paransori 正在录音', 'Paransori 正在錄音'),
 ('rec_tap_resume', '%1$02d:%2$02d · Tap to resume', '%1$02d:%2$02d · 탭해서 이어서 녹음', '%1$02d:%2$02d · タップして録音を再開', '%1$02d:%2$02d · 点按继续录音', '%1$02d:%2$02d · 點按繼續錄音'),
 ('rec_tap_back', 'Tap to return to the recording screen', '탭하면 녹음 화면으로 돌아가요', 'タップで録音画面に戻ります', '点按返回录音画面', '點按返回錄音畫面'),
 ('rec_resume', 'Resume', '이어서', '再開', '继续', '繼續'),
 ('rec_pause', 'Pause', '일시정지', '一時停止', '暂停', '暫停'),
 ('rec_done', 'Done', '완료', '完了', '完成', '完成'),
]
# 폴더: 몇 번째 글자를 쓸지 (1=en 2=ko 3=ja 4=zh 5=zh번체)
FOLDERS = [('values', 1), ('values-en', 1), ('values-ko', 2), ('values-ja', 3), ('values-zh', 4),
           ('values-zh-rTW', 5), ('values-zh-rHK', 5), ('values-zh-rMO', 5)]

def esc(s):
    s = s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    return s.replace("'", "\\'").replace('"', '\\"')

def strings_xml(col):
    L = ['<?xml version="1.0" encoding="utf-8"?>', '<resources>']
    for r in S:
        L.append('    <string name="%s">%s</string>' % (r[0], esc(r[col])))
    L.append('</resources>')
    return '\r\n'.join(L) + '\r\n'

GS = 'getString(R.string.%s)'
EDITS = [
 # 위젯 화면
 ('res/layout/widget_player.xml', 'android:text="파란소리"', 'android:text="@string/app_name"', 1),
 ('res/layout/widget_player.xml', 'android:text="음악 · 라디오 · 자연을 들어보세요"', 'android:text="@string/widget_idle_sub"', 1),
 ('res/layout/widget_player.xml', 'android:text="음악"', 'android:text="@string/tab_music"', 1),
 ('res/layout/widget_player.xml', 'android:text="라디오"', 'android:text="@string/tab_radio"', 1),
 ('res/layout/widget_player.xml', 'android:text="자연"', 'android:text="@string/tab_nature"', 1),
 ('res/layout/widget_player.xml', 'android:text="수면"', 'android:text="@string/tab_sleep"', 1),
 ('res/layout/widget_player2.xml', 'android:text="파란소리"', 'android:text="@string/app_name"', 1),
 ('res/layout/widget_player2.xml', 'android:text="음악 · 라디오 · 자연을 들어보세요"', 'android:text="@string/widget_idle_sub"', 1),
 ('res/layout/widget_player2.xml', 'android:text="음악"', 'android:text="@string/tab_music"', 1),
 ('res/layout/widget_player2.xml', 'android:text="라디오"', 'android:text="@string/tab_radio"', 2),
 ('res/layout/widget_player2.xml', 'android:text="자연"', 'android:text="@string/tab_nature"', 1),
 ('res/layout/widget_player2.xml', 'android:text="수면"', 'android:text="@string/tab_sleep"', 1),
 ('res/layout/widget_player2.xml', 'android:text="최근에 들은 게 여기에 나와요"', 'android:text="@string/widget_recent_empty"', 1),
 ('res/layout/widget_player2.xml', 'android:text="좋아하는 노래"', 'android:text="@string/sample_song"', 1),
 ('res/layout/widget_player2.xml', 'android:text="가수"', 'android:text="@string/sample_artist"', 1),
 ('res/layout/widget_player2.xml', 'android:text="라디오 방송"', 'android:text="@string/sample_station"', 1),
 ('res/layout/widget_player2.xml', 'android:text="빗소리"', 'android:text="@string/sample_rain"', 1),
 ('res/layout/widget_player2.xml', 'android:text="자연소리"', 'android:text="@string/sample_nature"', 1),
 # 아침 알람 알림
 ('AlarmReceiver.kt', 'NotificationChannel(CHANNEL_ID, "아침 알람",', 'NotificationChannel(CHANNEL_ID, ctx.getString(R.string.alarm_channel),', 1),
 ('AlarmReceiver.kt', 'description = "파란소리 아침 알람"', 'description = ctx.getString(R.string.alarm_channel_desc)', 1),
 ('AlarmReceiver.kt', 'NotificationChannel(QUIET_CHANNEL_ID, "아침 알람 (화면 열기)",', 'NotificationChannel(QUIET_CHANNEL_ID, ctx.getString(R.string.alarm_quiet_channel),', 1),
 ('AlarmReceiver.kt', 'description = "잠금화면 위로 알람 화면을 열 때"', 'description = ctx.getString(R.string.alarm_quiet_desc)', 1),
 ('AlarmReceiver.kt', '.setContentTitle("아침 알람")', '.setContentTitle(ctx.getString(R.string.alarm_channel))', 1),
 ('AlarmReceiver.kt', '.setContentText("눌러서 알람 화면 열기")', '.setContentText(ctx.getString(R.string.alarm_text))', 1),
 # 이어폰 알림 · 위젯 기본 글자
 ('MainActivity.kt', '"paran_headset", "이어폰 연결 알림",', '"paran_headset", ' + GS % 'headset_channel' + ',', 1),
 ('MainActivity.kt', 'null as android.graphics.drawable.Icon?, "재생", pi)', 'null as android.graphics.drawable.Icon?, ' + GS % 'action_play' + ', pi)', 1),
 ('MainActivity.kt', 'call.argument<String>("title") ?: "이어서 들을까요?"', 'call.argument<String>("title") ?: ' + GS % 'resume_ask', 1),
 ('MainActivity.kt', 'call.argument<String>("title") ?: "파란소리"', 'call.argument<String>("title") ?: ' + GS % 'app_name', 1),
 ('MainActivity.kt', 'call.argument<String>("artist") ?: "음악을 재생해보세요"', 'call.argument<String>("artist") ?: ' + GS % 'widget_play_music', 1),
 # 위젯
 ('PlayerWidget.kt', 'call.argument<String>("title") ?: "파란소리",', 'call.argument<String>("title") ?: app.getString(R.string.app_name),', 1),
 ('PlayerWidget.kt', 'if (loading) "불러오는 중…" else if (empty) "파란소리" else t)',
  'if (loading) context.getString(R.string.widget_loading) else if (empty) context.getString(R.string.app_name) else t)', 1),
 ('PlayerWidget.kt', 'if (loading) "잠시만 기다려 주세요" else if (empty) "음악 · 라디오 · 자연을 들어보세요" else a)',
  'if (loading) context.getString(R.string.widget_wait) else if (empty) context.getString(R.string.widget_idle_sub) else a)', 1),
 # 녹음 알림
 ('RecordingService.kt', 'NotificationChannel(CHANNEL_ID, "녹음",', 'NotificationChannel(CHANNEL_ID, ' + GS % 'rec_channel' + ',', 1),
 ('RecordingService.kt', 'ch.description = "녹음 중일 때 알림창에 표시"', 'ch.description = ' + GS % 'rec_channel_desc', 1),
 ('RecordingService.kt', '.setContentTitle(if (paused) "파란소리 녹음 일시정지" else "파란소리 녹음 중")',
  '.setContentTitle(if (paused) ' + GS % 'rec_title_paused' + ' else ' + GS % 'rec_title_on' + ')', 1),
 ('RecordingService.kt', 'b.setContentText(String.format("%02d:%02d · 탭해서 이어서 녹음", s / 60, s % 60))',
  'b.setContentText(getString(R.string.rec_tap_resume, s / 60, s % 60))', 1),
 ('RecordingService.kt', '.setContentText("탭하면 녹음 화면으로 돌아가요")', '.setContentText(' + GS % 'rec_tap_back' + ')', 1),
 ('RecordingService.kt', 'if (paused) "이어서" else "일시정지",', 'if (paused) ' + GS % 'rec_resume' + ' else ' + GS % 'rec_pause' + ',', 1),
 ('RecordingService.kt', 'ic_menu_save, "완료", pi(ACTION_FINISH)', 'ic_menu_save, ' + GS % 'rec_done' + ', pi(ACTION_FINISH)', 1),
]

def path_of(f):
    return os.path.join(BASE, *f.split('/')) if f.startswith('res/') else os.path.join(KT, f)

def balance(t):
    t = re.sub(r'"(?:\\.|[^"\\])*"', '""', t)
    t = re.sub(r'//[^\n]*', '', t)
    return all(t.count(a) == t.count(b) for a, b in ['()', '{}', '[]'])

def main():
    if not os.path.isdir(KT) or not os.path.isdir(RES):
        print('❌ 폴더를 못 찾았어요:', BASE, '\n   C:\\apps\\mp3_player_new 에서 실행해 주세요')
        return
    texts, out, done, total = {}, {}, 0, 0
    for f, old, new, cnt in EDITS:
        p = path_of(f)
        if p not in texts:
            if not os.path.isfile(p):
                print('❌ 파일 없음:', p); return
            with open(p, 'r', encoding='utf-8', newline='') as fh:
                texts[p] = fh.read()
            out[p] = texts[p]
        total += 1
        n = out[p].count(old)
        if n == cnt:
            out[p] = out[p].replace(old, new)
            print('✔', f, '|', old[:40])
        elif n == 0 and out[p].count(new) >= cnt:
            done += 1
            print('✔ (이미 됨)', f, '|', old[:40])
        else:
            print('❌', f, '| 찾을 코드가', n, '번 있어요 (', cnt, '번이어야 함):', old)
            print('   아무것도 저장 안 했어요'); return
    for p, t in out.items():
        if p.endswith('.kt') and not balance(t):
            print('❌ 괄호 짝이 안 맞아요:', p, '\n   아무것도 저장 안 했어요'); return
    # strings.xml
    sx = {}
    for d, col in FOLDERS:
        p = os.path.join(RES, d, 'strings.xml')
        new = strings_xml(col)
        old = open(p, encoding='utf-8', newline='').read() if os.path.isfile(p) else None
        total += 1
        if old == new:
            done += 1
        else:
            sx[p] = new
    if done == total:
        print('이미 적용돼 있어요'); return
    for p, t in out.items():
        if t != texts[p]:
            with open(p, 'w', encoding='utf-8', newline='') as fh:
                fh.write(t)
    for p, t in sx.items():
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8', newline='') as fh:
            fh.write(t)
        print('✔', os.path.relpath(p, BASE))
    print('\n완료! 글자', len(S), '개 · 바꾼 곳', len(EDITS), '군데')

main()
