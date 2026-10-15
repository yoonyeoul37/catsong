# -*- coding: utf-8 -*-
# 해외 라디오 목록 번역
import os, sys, json
KEYS = json.loads('{"popMost": ["많이 듣는", "Most played", "よく聴かれる", "最多收听", "最多收聽", null], "popTrend": ["요즘 뜨는", "Trending", "話題の", "正在流行", "正在流行", null], "recentListened": ["최근청취", "Recent", "最近聴いた", "最近收听", "最近收聽", null], "myRadio": ["내 라디오", "My radio", "マイラジオ", "我的电台", "我的電台", null], "popularTab": ["인기", "Popular", "人気", "热门", "熱門", null], "genreTab": ["장르", "Genre", "ジャンル", "类型", "類型", null], "regionTab": ["지역", "Region", "地域", "地区", "地區", null], "languageTab": ["언어", "Language", "言語", "语言", "語言", null], "genreNews": ["뉴스", "News", "ニュース", "新闻", "新聞", null], "genreTalk": ["토크", "Talk", "トーク", "谈话", "談話", null], "genreSports": ["스포츠", "Sports", "スポーツ", "体育", "體育", null], "genrePop": ["팝", "Pop", "ポップ", "流行", "流行", null], "genreHits": ["인기곡", "Hits", "ヒット曲", "热门歌曲", "熱門歌曲", null], "genreRock": ["록", "Rock", "ロック", "摇滚", "搖滾", null], "genreJazz": ["재즈", "Jazz", "ジャズ", "爵士", "爵士", null], "genreClassical": ["클래식", "Classical", "クラシック", "古典", "古典", null], "genreDance": ["댄스·일렉", "Dance·EDM", "ダンス・EDM", "舞曲·电子", "舞曲·電子", null], "genreHiphop": ["힙합", "Hip-hop", "ヒップホップ", "嘻哈", "嘻哈", null], "genreRnb": ["R&B·소울", "R&B·Soul", "R&B・ソウル", "R&B·灵魂", "R&B·靈魂", null], "genreLatin": ["라틴", "Latin", "ラテン", "拉丁", "拉丁", null], "genreCountry": ["컨트리", "Country", "カントリー", "乡村", "鄉村", null], "genreOldies": ["올디스", "Oldies", "オールディーズ", "怀旧金曲", "懷舊金曲", null], "genreLounge": ["라운지", "Lounge", "ラウンジ", "休闲", "休閒", null], "genreFolk": ["포크", "Folk", "フォーク", "民谣", "民謠", null], "genreBlues": ["블루스", "Blues", "ブルース", "蓝调", "藍調", null], "genreReggae": ["레게", "Reggae", "レゲエ", "雷鬼", "雷鬼", null], "genreMetal": ["메탈", "Metal", "メタル", "金属", "金屬", null], "genreReligious": ["종교", "Religious", "宗教", "宗教", "宗教", null], "genreKids": ["어린이", "Kids", "キッズ", "儿童", "兒童", null], "genreBollywood": ["볼리우드", "Bollywood", "ボリウッド", "宝莱坞", "寶萊塢", null], "genreSertanejo": ["세르타네주", "Sertanejo", "セルタネージョ", "Sertanejo", "Sertanejo", null], "noRegionStations": ["지역 정보가 있는 방송국이 없어요", "No stations with region info", "地域情報のある放送局はありません", "没有带地区信息的电台", "沒有帶地區資訊的電台", null], "favAddHint": ["하트를 눌러 즐겨찾기에 추가해보세요", "Tap the heart to add favorites", "ハートを押してお気に入りに追加しましょう", "点击爱心添加收藏", "點擊愛心加入收藏", null], "noRecentStations": ["최근 들은 방송이 없어요", "No recently played stations", "最近聴いた放送はありません", "没有最近收听的电台", "沒有最近收聽的電台", null], "loadingMoreStations": ["방송을 더 불러오는 중", "Loading more stations", "放送をさらに読み込み中", "正在加载更多电台", "正在載入更多電台", null], "nowPlayingSong": ["지금 나오는 곡", "Now playing", "再生中の曲", "正在播放的歌曲", "正在播放的歌曲", null], "noSongInfoYet": ["곡 정보가 아직 없어요", "No song info yet", "曲情報はまだありません", "暂无歌曲信息", "暫無歌曲資訊", null], "trendingSort": ["요즘 듣는 사람이 늘어난 순", "Sorted by rising listeners", "リスナーが増えている順", "按收听人数增长排序", "依收聽人數成長排序", null], "heroDicePick": ["주사위가 고른 방송", "Picked by dice", "サイコロが選んだ放送", "骰子选中的电台", "骰子選中的電台", null], "heroRecent": ["최근 들은 방송", "Recently played", "最近聴いた放送", "最近收听", "最近收聽", null], "slotMorning": ["아침", "Morning", "朝", "早上", "早上", null], "slotDay": ["낮", "Daytime", "昼", "白天", "白天", null], "slotEvening": ["저녁", "Evening", "夕方", "傍晚", "傍晚", null], "slotNight": ["밤", "Night", "夜", "夜晚", "夜晚", null], "heroTopN": ["인기 {n}위", "#{n} popular", "人気{n}位", "人气第{n}", "人氣第{n}", {"n": "int"}], "heroNowIn": ["지금 {country} {slot} · {why}", "{slot} in {country} · {why}", "今{country}は{slot}・{why}", "{country}现在是{slot} · {why}", "{country}現在是{slot} · {why}", {"country": "String", "slot": "String", "why": "String"}], "stationsPopular": ["방송 {n}개 · 인기순", "{n} stations · by popularity", "放送{n}件・人気順", "{n}个电台 · 按人气", "{n}個電台 · 依人氣", {"n": "String"}], "countStr": ["{n}개", "{n}", "{n}件", "{n}个", "{n}個", {"n": "String"}], "channelsCount": ["{count}개 채널", "{count, plural, =1{1 channel} other{{count} channels}}", "{count}チャンネル", "{count}个频道", "{count}個頻道", {"count": "int"}], "localTime": ["현지 {time}", "Local {time}", "現地 {time}", "当地 {time}", "當地 {time}", {"time": "String"}]}')
EDITS = json.loads('[["screens/radio_country_stations_screen.dart", "import \'../providers/theme_provider.dart\';\\n", "import \'../providers/theme_provider.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["screens/radio_country_stations_screen.dart", "child: Text(\'지역 정보가 있는 방송국이 없어요\',", "child: Text(tr.noRegionStations,", 1], ["screens/radio_country_stations_screen.dart", "child: Text(\'하트를 눌러 즐겨찾기에 추가해보세요\',", "child: Text(tr.favAddHint,", 1], ["screens/radio_country_stations_screen.dart", "child: Text(\'최근 들은 방송이 없어요\',", "child: Text(tr.noRecentStations,", 1], ["screens/radio_country_stations_screen.dart", "                  \'${list.length}개 채널\',", "                  tr.channelsCount(list.length),", 1], ["screens/radio_country_stations_screen.dart", "                Text(\\n                  key,\\n                  style: TextStyle(\\n                    color: baseColor,", "                Text(\\n                  key == \'기타\' ? tr.categoryEtc : key,\\n                  style: TextStyle(\\n                    color: baseColor,", 1], ["screens/radio_country_stations_screen.dart", "  String _langName(String raw) {\\n    final k = raw.toLowerCase().trim();\\n    if (k.isEmpty) return \'\';\\n    return _langKo[k] ?? (k[0].toUpperCase() + k.substring(1));\\n  }", "  String _langName(String raw) {\\n    final k = raw.toLowerCase().trim();\\n    if (k.isEmpty) return \'\';\\n    final loc = tr.localeName;\\n    final map = loc.startsWith(\'ko\')\\n        ? _langKo\\n        : loc.startsWith(\'ja\')\\n            ? _langJa\\n            : loc == \'zh_Hant\'\\n                ? _langZhHant\\n                : loc.startsWith(\'zh\')\\n                    ? _langZh\\n                    : const <String, String>{};\\n    return map[k] ?? (k[0].toUpperCase() + k.substring(1));\\n  }\\n\\n  static const Map<String, String> _langJa = {\\n    \'english\': \'英語\', \'spanish\': \'スペイン語\', \'portuguese\': \'ポルトガル語\', \'french\': \'フランス語\',\\n    \'german\': \'ドイツ語\', \'italian\': \'イタリア語\', \'hindi\': \'ヒンディー語\', \'tamil\': \'タミル語\',\\n    \'telugu\': \'テルグ語\', \'malayalam\': \'マラヤーラム語\', \'bengali\': \'ベンガル語\', \'marathi\': \'マラーティー語\',\\n    \'kannada\': \'カンナダ語\', \'punjabi\': \'パンジャーブ語\', \'gujarati\': \'グジャラート語\', \'urdu\': \'ウルドゥー語\',\\n    \'japanese\': \'日本語\', \'chinese\': \'中国語\', \'mandarin\': \'中国語\', \'cantonese\': \'広東語\',\\n    \'korean\': \'韓国語\', \'vietnamese\': \'ベトナム語\', \'thai\': \'タイ語\', \'indonesian\': \'インドネシア語\',\\n    \'malay\': \'マレー語\', \'javanese\': \'ジャワ語\', \'arabic\': \'アラビア語\', \'russian\': \'ロシア語\',\\n    \'ukrainian\': \'ウクライナ語\', \'dutch\': \'オランダ語\', \'catalan\': \'カタルーニャ語\', \'basque\': \'バスク語\',\\n    \'galician\': \'ガリシア語\', \'swiss german\': \'スイスドイツ語\', \'romansh\': \'ロマンシュ語\', \'turkish\': \'トルコ語\',\\n    \'polish\': \'ポーランド語\', \'swedish\': \'スウェーデン語\', \'welsh\': \'ウェールズ語\', \'irish\': \'アイルランド語\',\\n    \'filipino\': \'フィリピン語\', \'tagalog\': \'タガログ語\', \'persian\': \'ペルシャ語\', \'hebrew\': \'ヘブライ語\',\\n    \'greek\': \'ギリシャ語\',\\n  };\\n\\n  static const Map<String, String> _langZh = {\\n    \'english\': \'英语\', \'spanish\': \'西班牙语\', \'portuguese\': \'葡萄牙语\', \'french\': \'法语\',\\n    \'german\': \'德语\', \'italian\': \'意大利语\', \'hindi\': \'印地语\', \'tamil\': \'泰米尔语\',\\n    \'telugu\': \'泰卢固语\', \'malayalam\': \'马拉雅拉姆语\', \'bengali\': \'孟加拉语\', \'marathi\': \'马拉地语\',\\n    \'kannada\': \'卡纳达语\', \'punjabi\': \'旁遮普语\', \'gujarati\': \'古吉拉特语\', \'urdu\': \'乌尔都语\',\\n    \'japanese\': \'日语\', \'chinese\': \'中文\', \'mandarin\': \'普通话\', \'cantonese\': \'粤语\',\\n    \'korean\': \'韩语\', \'vietnamese\': \'越南语\', \'thai\': \'泰语\', \'indonesian\': \'印尼语\',\\n    \'malay\': \'马来语\', \'javanese\': \'爪哇语\', \'arabic\': \'阿拉伯语\', \'russian\': \'俄语\',\\n    \'ukrainian\': \'乌克兰语\', \'dutch\': \'荷兰语\', \'catalan\': \'加泰罗尼亚语\', \'basque\': \'巴斯克语\',\\n    \'galician\': \'加利西亚语\', \'swiss german\': \'瑞士德语\', \'romansh\': \'罗曼什语\', \'turkish\': \'土耳其语\',\\n    \'polish\': \'波兰语\', \'swedish\': \'瑞典语\', \'welsh\': \'威尔士语\', \'irish\': \'爱尔兰语\',\\n    \'filipino\': \'菲律宾语\', \'tagalog\': \'他加禄语\', \'persian\': \'波斯语\', \'hebrew\': \'希伯来语\',\\n    \'greek\': \'希腊语\',\\n  };\\n\\n  static const Map<String, String> _langZhHant = {\\n    \'english\': \'英語\', \'spanish\': \'西班牙語\', \'portuguese\': \'葡萄牙語\', \'french\': \'法語\',\\n    \'german\': \'德語\', \'italian\': \'義大利語\', \'hindi\': \'印地語\', \'tamil\': \'坦米爾語\',\\n    \'telugu\': \'泰盧固語\', \'malayalam\': \'馬拉雅拉姆語\', \'bengali\': \'孟加拉語\', \'marathi\': \'馬拉地語\',\\n    \'kannada\': \'卡納達語\', \'punjabi\': \'旁遮普語\', \'gujarati\': \'古吉拉特語\', \'urdu\': \'烏爾都語\',\\n    \'japanese\': \'日語\', \'chinese\': \'中文\', \'mandarin\': \'國語\', \'cantonese\': \'粵語\',\\n    \'korean\': \'韓語\', \'vietnamese\': \'越南語\', \'thai\': \'泰語\', \'indonesian\': \'印尼語\',\\n    \'malay\': \'馬來語\', \'javanese\': \'爪哇語\', \'arabic\': \'阿拉伯語\', \'russian\': \'俄語\',\\n    \'ukrainian\': \'烏克蘭語\', \'dutch\': \'荷蘭語\', \'catalan\': \'加泰隆尼亞語\', \'basque\': \'巴斯克語\',\\n    \'galician\': \'加利西亞語\', \'swiss german\': \'瑞士德語\', \'romansh\': \'羅曼什語\', \'turkish\': \'土耳其語\',\\n    \'polish\': \'波蘭語\', \'swedish\': \'瑞典語\', \'welsh\': \'威爾斯語\', \'irish\': \'愛爾蘭語\',\\n    \'filipino\': \'菲律賓語\', \'tagalog\': \'他加祿語\', \'persian\': \'波斯語\', \'hebrew\': \'希伯來語\',\\n    \'greek\': \'希臘語\',\\n  };\\n\\n  /// 칩 아래 글자 (저장은 한국어 그대로, 화면엔 언어에 맞게)\\n  String _subLabel(String v) => switch (v) {\\n        _popMost => tr.popMost,\\n        _popTrend => tr.popTrend,\\n        \'즐겨찾기\' => tr.favorites,\\n        \'최근청취\' => tr.recentListened,\\n        \'저장한 곡\' => tr.savedSongs,\\n        \'뉴스\' => tr.genreNews,\\n        \'토크\' => tr.genreTalk,\\n        \'스포츠\' => tr.genreSports,\\n        \'팝\' => tr.genrePop,\\n        \'인기곡\' => tr.genreHits,\\n        \'록\' => tr.genreRock,\\n        \'재즈\' => tr.genreJazz,\\n        \'클래식\' => tr.genreClassical,\\n        \'댄스·일렉\' => tr.genreDance,\\n        \'힙합\' => tr.genreHiphop,\\n        \'R&B·소울\' => tr.genreRnb,\\n        \'라틴\' => tr.genreLatin,\\n        \'컨트리\' => tr.genreCountry,\\n        \'올디스\' => tr.genreOldies,\\n        \'라운지\' => tr.genreLounge,\\n        \'포크\' => tr.genreFolk,\\n        \'블루스\' => tr.genreBlues,\\n        \'레게\' => tr.genreReggae,\\n        \'메탈\' => tr.genreMetal,\\n        \'종교\' => tr.genreReligious,\\n        \'어린이\' => tr.genreKids,\\n        \'볼리우드\' => tr.genreBollywood,\\n        \'세르타네주\' => tr.genreSertanejo,\\n        _ => v,\\n      };", 1], ["screens/radio_country_stations_screen.dart", "    const names = {\'mine\': \'내 라디오\', \'pop\': \'인기\', \'genre\': \'장르\', \'region\': \'지역\', \'lang\': \'언어\'};", "    final names = {\'mine\': tr.myRadio, \'pop\': tr.popularTab, \'genre\': tr.genreTab, \'region\': tr.regionTab, \'lang\': tr.languageTab};", 1], ["screens/radio_country_stations_screen.dart", "                          TextSpan(text: cur[i].$1),", "                          TextSpan(text: _subLabel(cur[i].$1)),", 1], ["screens/radio_country_stations_screen.dart", "      why = \'주사위가 고른 방송\';\\n    } else {\\n      why = \'인기 1위\';", "      why = tr.heroDicePick;\\n    } else {\\n      why = tr.heroTopN(1);", 1], ["screens/radio_country_stations_screen.dart", "          why = \'최근 들은 방송\';", "          why = tr.heroRecent;", 1], ["screens/radio_country_stations_screen.dart", "        why = all.indexOf(pick) <= 0 ? \'인기 1위\' : \'인기 ${all.indexOf(pick) + 1}위\';", "        why = tr.heroTopN(all.indexOf(pick) <= 0 ? 1 : all.indexOf(pick) + 1);", 1], ["screens/radio_country_stations_screen.dart", "    const slotName = [\'아침\', \'낮\', \'저녁\', \'밤\'];", "    final slotName = [tr.slotMorning, tr.slotDay, tr.slotEvening, tr.slotNight];", 1], ["screens/radio_country_stations_screen.dart", "    final label = why == \'주사위가 고른 방송\' ? why : \'지금 $cname$josa ${slotName[slot]} · $why\';", "    final label = why == tr.heroDicePick\\n        ? why\\n        : tr.localeName.startsWith(\'ko\')\\n            ? \'지금 $cname$josa ${slotName[slot]} · $why\'\\n            : tr.heroNowIn(cname, slotName[slot], why);", 1], ["screens/radio_country_stations_screen.dart", "      ..._genresOf(st).take(1),", "      ..._genresOf(st).take(1).map(_subLabel),", 1], ["screens/radio_country_stations_screen.dart", "          Text(\'다시 듣기\',\\n", "          Text(tr.dailyListenAgain,\\n", 1], ["screens/radio_country_stations_screen.dart", "Text(\'방송을 더 불러오는 중\', style:", "Text(tr.loadingMoreStations, style:", 1], ["screens/radio_country_stations_screen.dart", "          programLabel: \'지금 나오는 곡\',\\n          emptyProgram: \'곡 정보가 아직 없어요\',", "          programLabel: tr.nowPlayingSong,\\n          emptyProgram: tr.noSongInfoYet,", 1], ["screens/radio_country_stations_screen.dart", "                              ? \'요즘 듣는 사람이 늘어난 순\'\\n                              : _chip == \'pop\' && _query.isEmpty\\n                              ? \'방송 ${_fmtNum(radioProvider.getCountryStationCount(widget.country.code) ?? stations.length)}개 · 인기순\'\\n                              : \'${_fmtNum(stations.length)}개\',", "                              ? tr.trendingSort\\n                              : _chip == \'pop\' && _query.isEmpty\\n                              ? tr.stationsPopular(_fmtNum(radioProvider.getCountryStationCount(widget.country.code) ?? stations.length))\\n                              : tr.countStr(_fmtNum(stations.length)),", 1], ["screens/radio_country_stations_screen.dart", "  return \'현지 ${t.hour < 12 ? \'오전\' : \'오후\'} $h12:${t.minute.toString().padLeft(2, \'0\')}\';", "  return tr.localTime(tr.timeAmPm(t.hour < 12 ? tr.am : tr.pm, \'$h12:${t.minute.toString().padLeft(2, \'0\')}\'));", 1]]')
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
