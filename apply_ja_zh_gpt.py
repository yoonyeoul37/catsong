# -*- coding: utf-8 -*-
# GPT가 다듬은 일본어·중국어(간체·번체) 문구 넣기
#  - 키 이름 + 지금 문구가 정확히 맞을 때만 바꿈 (다르면 ❌, 아무것도 저장 안 함)
#  - 뺀 것: radioSleep(재생 화면 아래 아이콘 글자 — 짧아야 함), radioStatusFailed(라디오 상태 표시 — 짧아야 함)
import os, sys, json

CHANGES = {
 "ja": [
  [
   "artists",
   "歌手",
   "アーティスト"
  ],
  [
   "scanningMusic",
   "音楽をスキャン中...",
   "音楽を検索中..."
  ],
  [
   "noArtists",
   "アーティストがありません",
   "アーティストが見つかりません"
  ],
  [
   "permissionRequired",
   "ストレージの許可が必要です",
   "音楽へのアクセス許可が必要です"
  ],
  [
   "permissionMessage",
   "MP3ファイルをスキャンするには\nストレージの許可が必要です。",
   "MP3ファイルを探すには\n音楽へのアクセス許可が必要です。"
  ],
  [
   "reviewMessage",
   "評価を残していただけると\nアプリ改善に大変役立ちます 😊",
   "評価をいただけると\nアプリの改善に役立ちます 😊"
  ],
  [
   "autoStopFormat",
   "{time}後に自動的にオフになります",
   "{time}後に再生を自動停止します"
  ],
  [
   "radioSelectCountry",
   "国を選択",
   "国・地域を選択"
  ],
  [
   "radioPopular200",
   "人気200",
   "人気の200局"
  ],
  [
   "sleepTimerDesc",
   "選択した時間後に自動的にオフになります",
   "設定した時間が経過すると自動で再生を停止します"
  ],
  [
   "sleepTimerActiveDesc",
   "タイマー作動中です",
   "タイマーが作動中です"
  ],
  [
   "radioNoFavoritesDesc",
   "チャンネル一覧で♡をタップして追加してみてください",
   "チャンネル一覧の♡をタップして追加しましょう"
  ],
  [
   "radioLoadingPopular",
   "人気放送を読み込み中...",
   "人気のラジオ局を読み込み中..."
  ],
  [
   "radioScheduleCompleteToast",
   "{title} {time} 予約完了",
   "{title} {time} の予約が完了しました"
  ],
  [
   "radioPlaybackFailed",
   "再生に失敗しました。",
   "再生できませんでした。"
  ],
  [
   "radioNoStationsFound",
   "放送が見つかりません",
   "ラジオ局が見つかりません"
  ],
  [
   "sleepAutoStopToast",
   "{time}後に自動的にオフになります",
   "{time}後に再生を自動停止します"
  ],
  [
   "radioKoreaTitle",
   "韓国ラジオ",
   "韓国のラジオ"
  ]
 ],
 "zh": [
  [
   "artists",
   "艺术家",
   "歌手"
  ],
  [
   "scanningMusic",
   "正在扫描音乐...",
   "正在查找音乐..."
  ],
  [
   "artist",
   "艺术家",
   "歌手"
  ],
  [
   "noArtists",
   "找不到艺术家",
   "暂无歌手"
  ],
  [
   "searchArtists",
   "搜索艺术家...",
   "搜索歌手..."
  ],
  [
   "unknownArtist",
   "未知艺术家",
   "未知歌手"
  ],
  [
   "radioSelectCountry",
   "选择国家",
   "选择国家或地区"
  ],
  [
   "radioPopular200",
   "热门200个",
   "热门200个电台"
  ],
  [
   "sleepTimerDesc",
   "选择的时间后将自动关闭",
   "到达设定时间后自动停止播放"
  ],
  [
   "sleepTimerActiveDesc",
   "计时器运行中",
   "定时器正在运行"
  ],
  [
   "radioNoFavoritesDesc",
   "在频道列表中点击♡来添加收藏",
   "点击电台列表中的♡即可收藏"
  ],
  [
   "radioLoadingPopular",
   "正在加载热门广播...",
   "正在加载热门电台..."
  ],
  [
   "radioScheduleCompleteToast",
   "{title} {time} 预约完成",
   "已预约 {title} {time}"
  ],
  [
   "radioPlaybackFailed",
   "播放失败。",
   "播放失败，请重试。"
  ],
  [
   "radioNoStationsFound",
   "找不到广播",
   "未找到电台"
  ],
  [
   "sleepAutoStopToast",
   "{time}后自动关闭",
   "{time}后自动停止播放"
  ]
 ],
 "zh_Hant": [
  [
   "artists",
   "藝術家",
   "歌手"
  ],
  [
   "scanningMusic",
   "正在掃描音樂...",
   "正在尋找音樂..."
  ],
  [
   "artist",
   "藝術家",
   "歌手"
  ],
  [
   "noArtists",
   "找不到藝術家",
   "目前沒有歌手"
  ],
  [
   "searchArtists",
   "搜尋藝術家...",
   "搜尋歌手..."
  ],
  [
   "unknownArtist",
   "未知藝術家",
   "未知歌手"
  ],
  [
   "radioSelectCountry",
   "選擇國家",
   "選擇國家或地區"
  ],
  [
   "radioPopular200",
   "熱門200個",
   "熱門200個電台"
  ],
  [
   "sleepTimerDesc",
   "選擇的時間後將自動關閉",
   "設定時間一到，就會自動停止播放"
  ],
  [
   "sleepTimerActiveDesc",
   "計時器運作中",
   "計時器正在運作"
  ],
  [
   "radioNoFavoritesDesc",
   "在頻道列表中點擊♡來新增收藏",
   "點選電台清單中的♡即可加入收藏"
  ],
  [
   "radioLoadingPopular",
   "正在載入熱門廣播...",
   "正在載入熱門電台..."
  ],
  [
   "radioScheduleCompleteToast",
   "{title} {time} 預約完成",
   "已預約 {title} {time}"
  ],
  [
   "radioPlaybackFailed",
   "播放失敗。",
   "播放失敗，請再試一次。"
  ],
  [
   "radioNoStationsFound",
   "找不到廣播",
   "找不到電台"
  ],
  [
   "sleepAutoStopToast",
   "{time}後自動關閉",
   "{time}後自動停止播放"
  ]
 ]
}

def raw(s):
    return json.dumps(s, ensure_ascii=False)[1:-1]

def main():
    ok = True; out = {}; total = 0
    for code, pairs in CHANGES.items():
        path = os.path.join('lib', 'l10n', 'app_%s.arb' % code)
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
        b = open(path, 'rb').read(); crlf = b'\r\n' in b
        text = b.decode('utf-8').replace('\r\n', '\n'); changed = 0
        for key, old, new in pairs:
            o = '"%s": "%s"' % (key, raw(old)); n = '"%s": "%s"' % (key, raw(new))
            if text.count(n) >= 1 and text.count(o) == 0: continue
            if text.count(o) >= 1:  # 같은 키가 두 번 적힌 파일도 있어서 둘 다 바꿈
                text = text.replace(o, n); changed += 1; print('✔', code, key, ':', new.replace('\n', ' / '))
            else:
                print('❌', code, key, ': 지금 문구가 달라서 못 바꿨어요'); ok = False
        try:
            json.loads(text)
        except Exception as e:
            print('❌', path, '모양이 깨졌어요:', e); ok = False
        if changed:
            out[path] = (text, crlf); total += changed
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if not out:
        print('이미 적용돼 있어요'); return 0
    for p, (t, crlf) in out.items():
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요: %d곳 바꿈 (%d개 파일)' % (total, len(out)))
    return 0

if __name__ == '__main__':
    sys.exit(main())
