# -*- coding: utf-8 -*-
# 설정 도움말 번역
import os, sys, json
KEYS = json.loads('{"helpMediaTitle": ["음악·동영상 불러오기", "Load music and videos", "音楽・動画の読み込み", "加载音乐和视频", "載入音樂和影片", null], "helpMediaWhen": ["음악이나 동영상이 목록에 나타나지 않을 때", "When music or videos don\'t show up", "音楽や動画が一覧に表示されないとき", "音乐或视频没有出现在列表中时", "音樂或影片沒有出現在清單中時", null], "helpStepOpen": ["[설정 열기] 선택", "Tap [Open settings]", "[設定を開く]を選択", "点击[打开设置]", "點擊[開啟設定]", null], "helpStepPerm": ["[권한] 선택", "Tap [Permissions]", "[権限]を選択", "点击[权限]", "點擊[權限]", null], "helpStepMediaAllow": ["[음악 및 오디오]와 [사진 및 동영상] 허용", "Allow [Music and audio] and [Photos and videos]", "[音楽とオーディオ]と[写真と動画]を許可", "允许[音乐和音频]与[照片和视频]", "允許[音樂和音訊]與[相片和影片]", null], "helpStepIosMedia": ["[미디어 및 Apple Music]과 [사진] 켜기", "Turn on [Media & Apple Music] and [Photos]", "[メディアとApple Music]と[写真]をオン", "开启[媒体与Apple Music]和[照片]", "開啟[媒體與Apple Music]和[照片]", null], "helpStepBack": ["앱으로 돌아오기", "Come back to the app", "アプリに戻る", "返回应用", "返回應用程式", null], "helpMediaNote": ["허용한 뒤 앱으로 돌아오면 목록이 바로 나타나요.", "After allowing, come back and the list appears right away.", "許可してアプリに戻ると、すぐに一覧が表示されます。", "允许后返回应用，列表会立即出现。", "允許後返回應用程式，清單會立即出現。", null], "helpMediaPath": ["설정 → 애플리케이션 → 파란소리 → 권한 → 음악 및 오디오 / 사진 및 동영상", "Settings → Apps → Paransori → Permissions → Music and audio / Photos and videos", "設定 → アプリ → Paransori → 権限 → 音楽とオーディオ / 写真と動画", "设置 → 应用 → Paransori → 权限 → 音乐和音频 / 照片和视频", "設定 → 應用程式 → Paransori → 權限 → 音樂和音訊 / 相片和影片", null], "helpMediaIosPath": ["설정 → 파란소리 → 미디어 및 Apple Music · 사진", "Settings → Paransori → Media & Apple Music · Photos", "設定 → Paransori → メディアとApple Music・写真", "设置 → Paransori → 媒体与Apple Music · 照片", "設定 → Paransori → 媒體與Apple Music · 照片", null], "helpBgTitle": ["백그라운드 재생", "Background playback", "バックグラウンド再生", "后台播放", "背景播放", null], "helpBgWhen": ["화면을 껐을 때 음악이 멈추는 경우", "When music stops with the screen off", "画面を消すと音楽が止まるとき", "熄屏后音乐停止时", "關閉螢幕後音樂停止時", null], "helpStepBattery": ["[배터리] 선택", "Tap [Battery]", "[バッテリー]を選択", "点击[电池]", "點擊[電池]", null], "helpStepUnrestricted": ["[제한 없음] 선택", "Choose [Unrestricted]", "[制限なし]を選択", "选择[无限制]", "選擇[不受限制]", null], "helpBgNote": ["화면을 꺼도 음악과 라디오가 끊기지 않도록 도와줘요.\\n휴대폰에 따라 \\"최적화 안 함\\" 등 다른 이름으로 표시될 수 있어요.", "Keeps music and radio playing with the screen off.\\nOn some phones it may be called \\"Don\'t optimize\\" or similar.", "画面を消しても音楽やラジオが途切れないようにします。\\n機種によっては「最適化しない」など別の名前の場合があります。", "让熄屏后音乐和广播也不中断。\\n部分手机可能显示为\\"不优化\\"等其他名称。", "讓關閉螢幕後音樂和廣播也不中斷。\\n部分手機可能顯示為「不最佳化」等其他名稱。", null], "helpBgPath": ["설정 → 애플리케이션 → 파란소리 → 배터리 → 제한 없음", "Settings → Apps → Paransori → Battery → Unrestricted", "設定 → アプリ → Paransori → バッテリー → 制限なし", "设置 → 应用 → Paransori → 电池 → 无限制", "設定 → 應用程式 → Paransori → 電池 → 不受限制", null], "helpAlarmTitle": ["아침 알람", "Morning alarm", "朝のアラーム", "早晨闹钟", "早晨鬧鐘", null], "helpAlarmWhen": ["알람이 울리지 않거나 지연되는 경우", "When the alarm doesn\'t ring or is late", "アラームが鳴らない・遅れるとき", "闹钟不响或延迟时", "鬧鐘不響或延遲時", null], "helpStepAlarmAllow": ["[알람 및 리마인더] 허용", "Allow [Alarms & reminders]", "[アラームとリマインダー]を許可", "允许[闹钟和提醒]", "允許[鬧鐘與提醒]", null], "helpAlarmNote": ["\\"백그라운드 재생\\"의 배터리 설정도 함께 해 두면 알람이 더 정확하게 울려요.", "Setting battery under \\"Background playback\\" too makes the alarm more accurate.", "「バックグラウンド再生」のバッテリー設定も一緒にすると、アラームがより正確に鳴ります。", "同时完成\\"后台播放\\"的电池设置，闹钟会更准时。", "同時完成「背景播放」的電池設定，鬧鐘會更準時。", null], "helpAlarmPath": ["설정 → 애플리케이션 → 파란소리 → 알람 및 리마인더 → 허용", "Settings → Apps → Paransori → Alarms & reminders → Allow", "設定 → アプリ → Paransori → アラームとリマインダー → 許可", "设置 → 应用 → Paransori → 闹钟和提醒 → 允许", "設定 → 應用程式 → Paransori → 鬧鐘與提醒 → 允許", null], "helpLockTitle": ["잠금 화면 재생 버튼", "Lock screen controls", "ロック画面の再生ボタン", "锁屏播放按钮", "鎖定畫面播放按鈕", null], "helpLockWhen": ["잠금 화면이나 알림창에 재생 버튼이 표시되지 않을 때", "When play buttons don\'t show on the lock screen or notifications", "ロック画面や通知に再生ボタンが表示されないとき", "锁屏或通知栏没有播放按钮时", "鎖定畫面或通知欄沒有播放按鈕時", null], "helpStepNotif": ["[알림] 선택", "Tap [Notifications]", "[通知]を選択", "点击[通知]", "點擊[通知]", null], "helpStepNotifAllow": ["[알림 허용] 켜기", "Turn on [Allow notifications]", "[通知を許可]をオン", "开启[允许通知]", "開啟[允許通知]", null], "helpLockNote": ["알림을 허용해야 잠금 화면과 알림창에 재생 버튼이 표시돼요.", "Play buttons appear on the lock screen and notifications only when notifications are allowed.", "通知を許可すると、ロック画面と通知に再生ボタンが表示されます。", "允许通知后，锁屏和通知栏才会显示播放按钮。", "允許通知後，鎖定畫面和通知欄才會顯示播放按鈕。", null], "helpLockPath": ["설정 → 애플리케이션 → 파란소리 → 알림 → 알림 허용", "Settings → Apps → Paransori → Notifications → Allow notifications", "設定 → アプリ → Paransori → 通知 → 通知を許可", "设置 → 应用 → Paransori → 通知 → 允许通知", "設定 → 應用程式 → Paransori → 通知 → 允許通知", null], "helpLockIosPath": ["설정 → 파란소리 → 알림 → 알림 허용", "Settings → Paransori → Notifications → Allow notifications", "設定 → Paransori → 通知 → 通知を許可", "设置 → Paransori → 通知 → 允许通知", "設定 → Paransori → 通知 → 允許通知", null], "helpRingTitle": ["벨소리 설정", "Ringtone", "着信音の設定", "铃声设置", "鈴聲設定", null], "helpRingWhen": ["벨소리나 알림음을 설정할 수 없을 때", "When you can\'t set a ringtone or notification sound", "着信音や通知音を設定できないとき", "无法设置铃声或通知音时", "無法設定鈴聲或通知音時", null], "helpStepModify": ["[시스템 설정 변경] 선택", "Tap [Modify system settings]", "[システム設定の変更]を選択", "点击[修改系统设置]", "點擊[修改系統設定]", null], "helpStepAllowOn": ["[허용] 켜기", "Turn on [Allow]", "[許可]をオン", "开启[允许]", "開啟[允許]", null], "helpRingNote": ["허용한 뒤 벨소리 설정을 다시 시도해 보세요.", "After allowing, try setting the ringtone again.", "許可したあと、もう一度着信音を設定してみてください。", "允许后请重新设置铃声。", "允許後請重新設定鈴聲。", null], "helpRingPath": ["설정 → 애플리케이션 → 파란소리 → 시스템 설정 변경 → 허용", "Settings → Apps → Paransori → Modify system settings → Allow", "設定 → アプリ → Paransori → システム設定の変更 → 許可", "设置 → 应用 → Paransori → 修改系统设置 → 允许", "設定 → 應用程式 → Paransori → 修改系統設定 → 允許", null], "helpCantOpen": ["설정 화면을 열 수 없어요. 아래 \\"직접 설정하기\\" 순서대로 이동해 주세요", "Can\'t open settings. Please follow \\"Set it manually\\" below.", "設定画面を開けません。下の「手動で設定」の手順で移動してください", "无法打开设置，请按照下方\\"手动设置\\"的步骤操作", "無法開啟設定，請依照下方「手動設定」的步驟操作", null], "mailBodyAsk": ["어떤 문제가 있나요?\\n(여기에 적어 주세요)", "What\'s the problem?\\n(Please write here)", "どんな問題がありますか？\\n（ここに書いてください）", "遇到了什么问题？\\n（请写在这里）", "遇到了什麼問題？\\n（請寫在這裡）", null], "mailBodyAuto": ["── 아래는 자동으로 들어가요 ──", "── Added automatically ──", "── 以下は自動で入ります ──", "── 以下内容自动填写 ──", "── 以下內容自動填寫 ──", null], "mailModel": ["휴대폰 모델", "Phone model", "機種", "手机型号", "手機型號", null], "mailSystem": ["시스템", "System", "システム", "系统", "系統", null], "mailAndroid": ["안드로이드", "Android", "Android", "Android", "Android", null], "mailAppVersion": ["앱 버전", "App version", "アプリのバージョン", "应用版本", "應用程式版本", null], "mailSubject": ["[파란소리 문의]", "[Paransori Support]", "[Paransori お問い合わせ]", "[Paransori 咨询]", "[Paransori 諮詢]", null], "mailCopied": ["메일 앱을 찾을 수 없어 주소를 복사했어요 ({mail})", "No mail app found, so the address was copied ({mail})", "メールアプリが見つからないため、アドレスをコピーしました ({mail})", "找不到邮件应用，已复制邮箱地址 ({mail})", "找不到郵件應用程式，已複製信箱地址 ({mail})", {"mail": "String"}], "helpIntro": ["앱 사용 중 문제가 발생하면 아래 안내를 확인하세요.", "If something goes wrong, check the guides below.", "困ったときは下の案内を確認してください。", "使用中遇到问题时，请查看以下指南。", "使用中遇到問題時，請查看以下指南。", null], "setManually": ["직접 설정하기", "Set it manually", "手動で設定", "手动设置", "手動設定", null], "openSettings": ["설정 열기", "Open settings", "設定を開く", "打开设置", "開啟設定", null], "needMoreHelp": ["추가 도움이 필요하신가요?", "Need more help?", "さらにサポートが必要ですか？", "还需要帮助吗？", "還需要幫助嗎？", null], "tellUsModel": ["휴대폰 모델과 문제 상황을 알려주세요.", "Tell us your phone model and what happened.", "機種と問題の状況を教えてください。", "请告诉我们手机型号和问题情况。", "請告訴我們手機型號和問題情況。", null], "emailUs": ["이메일 문의", "Email us", "メールで問い合わせ", "邮件咨询", "郵件諮詢", null]}')
EDITS = json.loads('[["screens/settings_help_screen.dart", "import \'../widgets/paran_toast.dart\';\\n", "import \'../widgets/paran_toast.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["screens/settings_help_screen.dart", "const _topics = <_HelpTopic>[\\n  _HelpTopic(\\n    Icons.perm_media_outlined,\\n    \'음악·동영상 불러오기\',\\n    \'음악이나 동영상이 목록에 나타나지 않을 때\',\\n    [\'[설정 열기] 선택\', \'[권한] 선택\', \'[음악 및 오디오]와 [사진 및 동영상] 허용\'],\\n    ios: [\'[설정 열기] 선택\', \'[미디어 및 Apple Music]과 [사진] 켜기\', \'앱으로 돌아오기\'],\\n    note: \'허용한 뒤 앱으로 돌아오면 목록이 바로 나타나요.\',\\n    path: \'설정 → 애플리케이션 → 파란소리 → 권한 → 음악 및 오디오 / 사진 및 동영상\',\\n    iosPath: \'설정 → 파란소리 → 미디어 및 Apple Music · 사진\',\\n  ),\\n  _HelpTopic(\\n    Icons.battery_charging_full_rounded,\\n    \'백그라운드 재생\',\\n    \'화면을 껐을 때 음악이 멈추는 경우\',\\n    [\'[설정 열기] 선택\', \'[배터리] 선택\', \'[제한 없음] 선택\'],\\n    note: \'화면을 꺼도 음악과 라디오가 끊기지 않도록 도와줘요.\\\\n휴대폰에 따라 \\"최적화 안 함\\" 등 다른 이름으로 표시될 수 있어요.\',\\n    path: \'설정 → 애플리케이션 → 파란소리 → 배터리 → 제한 없음\',\\n  ),\\n  _HelpTopic(\\n    Icons.alarm_rounded,\\n    \'아침 알람\',\\n    \'알람이 울리지 않거나 지연되는 경우\',\\n    [\'[설정 열기] 선택\', \'[알람 및 리마인더] 허용\', \'앱으로 돌아오기\'],\\n    note: \'\\"백그라운드 재생\\"의 배터리 설정도 함께 해 두면 알람이 더 정확하게 울려요.\',\\n    path: \'설정 → 애플리케이션 → 파란소리 → 알람 및 리마인더 → 허용\',\\n    exactAlarm: true,\\n  ),\\n  _HelpTopic(\\n    Icons.notifications_none_rounded,\\n    \'잠금 화면 재생 버튼\',\\n    \'잠금 화면이나 알림창에 재생 버튼이 표시되지 않을 때\',\\n    [\'[설정 열기] 선택\', \'[알림] 선택\', \'[알림 허용] 켜기\'],\\n    ios: [\'[설정 열기] 선택\', \'[알림] 선택\', \'[알림 허용] 켜기\'],\\n    note: \'알림을 허용해야 잠금 화면과 알림창에 재생 버튼이 표시돼요.\',\\n    path: \'설정 → 애플리케이션 → 파란소리 → 알림 → 알림 허용\',\\n    iosPath: \'설정 → 파란소리 → 알림 → 알림 허용\',\\n  ),\\n  _HelpTopic(\\n    Icons.music_note_outlined,\\n    \'벨소리 설정\',\\n    \'벨소리나 알림음을 설정할 수 없을 때\',\\n    [\'[설정 열기] 선택\', \'[시스템 설정 변경] 선택\', \'[허용] 켜기\'],\\n    note: \'허용한 뒤 벨소리 설정을 다시 시도해 보세요.\',\\n    path: \'설정 → 애플리케이션 → 파란소리 → 시스템 설정 변경 → 허용\',\\n  ),\\n];", "List<_HelpTopic> get _topics => [\\n  _HelpTopic(\\n    Icons.perm_media_outlined,\\n    tr.helpMediaTitle,\\n    tr.helpMediaWhen,\\n    [tr.helpStepOpen, tr.helpStepPerm, tr.helpStepMediaAllow],\\n    ios: [tr.helpStepOpen, tr.helpStepIosMedia, tr.helpStepBack],\\n    note: tr.helpMediaNote,\\n    path: tr.helpMediaPath,\\n    iosPath: tr.helpMediaIosPath,\\n  ),\\n  _HelpTopic(\\n    Icons.battery_charging_full_rounded,\\n    tr.helpBgTitle,\\n    tr.helpBgWhen,\\n    [tr.helpStepOpen, tr.helpStepBattery, tr.helpStepUnrestricted],\\n    note: tr.helpBgNote,\\n    path: tr.helpBgPath,\\n  ),\\n  _HelpTopic(\\n    Icons.alarm_rounded,\\n    tr.helpAlarmTitle,\\n    tr.helpAlarmWhen,\\n    [tr.helpStepOpen, tr.helpStepAlarmAllow, tr.helpStepBack],\\n    note: tr.helpAlarmNote,\\n    path: tr.helpAlarmPath,\\n    exactAlarm: true,\\n  ),\\n  _HelpTopic(\\n    Icons.notifications_none_rounded,\\n    tr.helpLockTitle,\\n    tr.helpLockWhen,\\n    [tr.helpStepOpen, tr.helpStepNotif, tr.helpStepNotifAllow],\\n    ios: [tr.helpStepOpen, tr.helpStepNotif, tr.helpStepNotifAllow],\\n    note: tr.helpLockNote,\\n    path: tr.helpLockPath,\\n    iosPath: tr.helpLockIosPath,\\n  ),\\n  _HelpTopic(\\n    Icons.music_note_outlined,\\n    tr.helpRingTitle,\\n    tr.helpRingWhen,\\n    [tr.helpStepOpen, tr.helpStepModify, tr.helpStepAllowOn],\\n    note: tr.helpRingNote,\\n    path: tr.helpRingPath,\\n  ),\\n];", 1], ["screens/settings_help_screen.dart", "  static const _levelNames = [\'기본\', \'크게\', \'아주 크게\'];", "  static List<String> get _levelNames => [tr.zoomDefault, tr.zoomLarge, tr.zoomXLarge];", 1], ["screens/settings_help_screen.dart", "showParanToast(context, \'설정 화면을 열 수 없어요. 아래 \\"직접 설정하기\\" 순서대로 이동해 주세요\');", "showParanToast(context, tr.helpCantOpen);", 1], ["screens/settings_help_screen.dart", "    final body = \'어떤 문제가 있나요?\\\\n(여기에 적어 주세요)\\\\n\\\\n\\\\n\\\\n\'\\n        \'── 아래는 자동으로 들어가요 ──\\\\n\'\\n        \'휴대폰 모델: $model\\\\n\'\\n        \'${Platform.isIOS ? \'시스템\' : \'안드로이드\'}: $os\\\\n\'\\n        \'앱 버전: 파란소리 $ver\';", "    final body = \'${tr.mailBodyAsk}\\\\n\\\\n\\\\n\\\\n\'\\n        \'${tr.mailBodyAuto}\\\\n\'\\n        \'${tr.mailModel}: $model\\\\n\'\\n        \'${Platform.isIOS ? tr.mailSystem : tr.mailAndroid}: $os\\\\n\'\\n        \'${tr.mailAppVersion}: Paransori $ver\';", 1], ["screens/settings_help_screen.dart", "\'?subject=${Uri.encodeComponent(\'[파란소리 문의]\')}\'", "\'?subject=${Uri.encodeComponent(tr.mailSubject)}\'", 1], ["screens/settings_help_screen.dart", "showParanToast(context, \'메일 앱을 찾을 수 없어 주소를 복사했어요 ($_contactMail)\');", "showParanToast(context, tr.mailCopied(_contactMail));", 1], ["screens/settings_help_screen.dart", "title: Text(\'설정 도움말\',", "title: Text(tr.moreHelpTitle,", 1], ["screens/settings_help_screen.dart", "child: Text(\'앱 사용 중 문제가 발생하면 아래 안내를 확인하세요.\',", "child: Text(tr.helpIntro,", 1], ["screens/settings_help_screen.dart", "Text(\'직접 설정하기\',\\n", "Text(tr.setManually,\\n", 1], ["screens/settings_help_screen.dart", "child: const Text(\'설정 열기\',\\n                                                    style: TextStyle(", "child: Text(tr.openSettings,\\n                                                    style: const TextStyle(", 1], ["screens/settings_help_screen.dart", "Text(\'추가 도움이 필요하신가요?\',", "Text(tr.needMoreHelp,", 1], ["screens/settings_help_screen.dart", "Text(\'휴대폰 모델과 문제 상황을 알려주세요.\',", "Text(tr.tellUsModel,", 1], ["screens/settings_help_screen.dart", "label: const Text(\'이메일 문의\',\\n                              style: TextStyle(", "label: Text(tr.emailUs,\\n                              style: const TextStyle(", 1]]')
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
