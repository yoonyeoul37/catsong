# -*- coding: utf-8 -*-
# 아티스트 정보 창 번역
import os, sys, json
KEYS = json.loads('{"artistFormed": ["{year}년 결성", "Formed in {year}", "{year}年結成", "{year}年成立", "{year}年成立", {"year": "String"}], "artistFirstAlbum": ["첫 앨범 {year}년", "First album {year}", "ファーストアルバム {year}年", "首张专辑 {year}年", "首張專輯 {year}年", {"year": "String"}], "albumCountChip": ["앨범 {count}장", "{count, plural, =1{1 album} other{{count} albums}}", "アルバム{count}枚", "专辑{count}张", "專輯{count}張", {"count": "int"}], "releaseDate": ["발매일", "Released", "リリース日", "发行日期", "發行日期", null], "genre": ["장르", "Genre", "ジャンル", "风格", "曲風", null], "trackNumber": ["{n}번째 곡", "Track {n}", "{n}曲目", "第{n}首", "第{n}首", {"n": "String"}], "nowListening": ["지금 듣는 곡", "Now playing", "再生中の曲", "正在收听", "正在收聽", null], "findingArtistInfo": ["{artist} 정보를 찾는 중…", "Looking up {artist}…", "{artist}の情報を検索中…", "正在查找{artist}的信息…", "正在尋找{artist}的資訊…", {"artist": "String"}], "songInfoNotFound": ["이 곡의 정보를 찾지 못했어요", "Couldn\'t find info for this song", "この曲の情報が見つかりませんでした", "找不到这首歌的信息", "找不到這首歌的資訊", null], "addArtistToSearch": ["곡 정보 수정에서 가수 이름을 넣으면 찾을 수 있어요", "Add the artist name in Edit info to search", "情報を編集で歌手名を入れると検索できます", "在编辑信息中填入歌手名即可查找", "在編輯資訊中填入歌手名即可尋找", null], "accurateNamesHelp": ["가수 이름이나 제목이 정확하면 더 잘 찾아요", "Accurate artist and title names help", "歌手名やタイトルが正確だと見つかりやすくなります", "歌手名或标题准确时更容易找到", "歌手名或標題準確時更容易找到", null], "showLess": ["접기", "Less", "閉じる", "收起", "收起", null], "showMore": ["더 보기", "More", "もっと見る", "展开", "展開", null], "autoTranslated": ["자동 번역", "Auto-translated", "自動翻訳", "自动翻译", "自動翻譯", null], "findingCredits": ["작사·작곡 찾는 중…", "Looking up credits…", "クレジットを検索中…", "正在查找词曲信息…", "正在尋找詞曲資訊…", null], "artistAlbums": ["이 가수의 앨범", "Albums by this artist", "この歌手のアルバム", "该歌手的专辑", "該歌手的專輯", null], "mayHaveErrors": ["(일부 오류가 있을 수 있어요)", "(may contain errors)", "（一部誤りがある場合があります）", "（可能有部分错误）", "（可能有部分錯誤）", null], "sourcesLabel": ["정보", "Sources", "情報", "信息来源", "資訊來源", null], "hiddenIfNotFound": ["찾지 못한 항목은 보이지 않아요", "Items not found are hidden", "見つからない項目は表示されません", "未找到的项目不会显示", "未找到的項目不會顯示", null], "moreOnWikipedia": ["Wikipedia에서 더 보기 ›", "More on Wikipedia ›", "Wikipediaで詳しく ›", "在Wikipedia查看更多 ›", "在Wikipedia查看更多 ›", null], "roleLyrics": ["작사", "Lyrics", "作詞", "作词", "作詞", null], "roleComposer": ["작곡", "Composer", "作曲", "作曲", "作曲", null], "roleWriter": ["작사·작곡", "Writer", "作詞・作曲", "词曲", "詞曲", null], "roleArranger": ["편곡", "Arranger", "編曲", "编曲", "編曲", null], "roleProducer": ["프로듀서", "Producer", "プロデュース", "制作人", "製作人", null], "kindSingle": ["싱글", "Single", "シングル", "单曲", "單曲", null], "kindCompilation": ["모음집", "Compilation", "コンピレーション", "合辑", "合輯", null], "kindLive": ["라이브", "Live", "ライブ", "现场", "現場", null], "artistSolo": ["솔로", "Solo", "ソロ", "个人", "個人", null], "artistGroup": ["그룹", "Group", "グループ", "组合", "團體", null]}')
EDITS = json.loads('[["widgets/artist_info_sheet.dart", "import \'../providers/theme_provider.dart\';\\n", "import \'../providers/theme_provider.dart\';\\nimport \'../l10n/locale_holder.dart\';\\n", 1], ["widgets/artist_info_sheet.dart", "  static String _date(String ymd) {\\n    final p = ymd.split(\'-\');\\n    if (p.length < 3) return ymd;\\n    return \'${p[0]}년 ${int.tryParse(p[1]) ?? p[1]}월 ${int.tryParse(p[2]) ?? p[2]}일\';\\n  }", "  static String _date(String ymd) {\\n    final p = ymd.split(\'-\');\\n    if (p.length < 3) return ymd;\\n    return tr.dateFormat(p[0], \'${int.tryParse(p[1]) ?? p[1]}\', \'${int.tryParse(p[2]) ?? p[2]}\');\\n  }\\n\\n  // ── 저장은 한국어 그대로, 화면엔 언어에 맞게 ──\\n  static String _kindLabel(String k) => switch (k) {\\n        \'앨범\' => tr.fieldAlbum,\\n        \'싱글\' => tr.kindSingle,\\n        \'모음집\' => tr.kindCompilation,\\n        \'라이브\' => tr.kindLive,\\n        _ => k,\\n      };\\n  static String _roleLabel(String r) => switch (r) {\\n        \'작사\' => tr.roleLyrics,\\n        \'작곡\' => tr.roleComposer,\\n        \'작사·작곡\' => tr.roleWriter,\\n        \'편곡\' => tr.roleArranger,\\n        \'프로듀서\' => tr.roleProducer,\\n        _ => r,\\n      };\\n  static String _typeLabel(String t) => switch (t) {\\n        \'솔로\' => tr.artistSolo,\\n        \'그룹\' => tr.artistGroup,\\n        _ => t,\\n      };\\n  static String _countryLabel(String v) {\\n    if (tr.localeName.startsWith(\'ko\')) return v;\\n    var code = v;\\n    for (final e in _ArtistApi._countries.entries) {\\n      if (e.value == v) code = e.key;\\n    }\\n    return switch (code) {\\n      \'KR\' => tr.countryKR, \'US\' => tr.countryUS, \'GB\' => tr.countryGB, \'JP\' => tr.countryJP,\\n      \'CA\' => tr.countryCA, \'AU\' => tr.countryAU, \'SE\' => tr.countrySE, \'FR\' => tr.countryFR,\\n      \'DE\' => tr.countryDE, \'CN\' => tr.countryCN, \'TW\' => tr.countryTW, \'IE\' => tr.countryIE,\\n      \'NO\' => tr.countryNO, \'NZ\' => tr.countryNZ, \'IT\' => tr.countryIT, \'ES\' => tr.countryES,\\n      \'BR\' => tr.countryBR, \'HK\' => tr.countryHK,\\n      _ => v,\\n    };\\n  }", 1], ["widgets/artist_info_sheet.dart", "tooltip: \'닫기\',", "tooltip: tr.close,", 1], ["widgets/artist_info_sheet.dart", "Text(\'${widget.song.artistDisplay} 정보를 찾는 중…\', style:", "Text(tr.findingArtistInfo(widget.song.artistDisplay), style:", 1], ["widgets/artist_info_sheet.dart", "Text(\'이 곡의 정보를 찾지 못했어요\',", "Text(tr.songInfoNotFound,", 1], ["widgets/artist_info_sheet.dart", "_unknownArtist ? \'곡 정보 수정에서 가수 이름을 넣으면 찾을 수 있어요\' : \'가수 이름이나 제목이 정확하면 더 잘 찾아요\',", "_unknownArtist ? tr.addArtistToSearch : tr.accurateNamesHelp,", 1], ["widgets/artist_info_sheet.dart", "label: const Text(\'다시 찾기\', style: TextStyle(fontWeight: FontWeight.w700)),", "label: Text(tr.searchAgain, style: const TextStyle(fontWeight: FontWeight.w700)),", 1], ["widgets/artist_info_sheet.dart", "        if (info.type != null) info.type!,\\n        if (info.country != null) info.country!,\\n        if (info.formed != null)\\n          \'${info.formed}년 결성\'\\n        else if (info.firstYear != null)\\n          \'첫 앨범 ${info.firstYear}년\',", "        if (info.type != null) _typeLabel(info.type!),\\n        if (info.country != null) _countryLabel(info.country!),\\n        if (info.formed != null)\\n          tr.artistFormed(\'${info.formed}\')\\n        else if (info.firstYear != null)\\n          tr.artistFirstAlbum(\'${info.firstYear}\'),", 1], ["widgets/artist_info_sheet.dart", "if (info.albumCount != null) \'앨범 ${info.albumCount}장\',", "if (info.albumCount != null) tr.albumCountChip(info.albumCount!),", 1], ["widgets/artist_info_sheet.dart", "Text(_bioOpen ? \'접기\' : \'더 보기\',", "Text(_bioOpen ? tr.showLess : tr.showMore,", 1], ["widgets/artist_info_sheet.dart", "Text(\'자동 번역\', style:", "Text(tr.autoTranslated, style:", 1], ["widgets/artist_info_sheet.dart", "        if (info.release != null) (\'발매일\', _date(info.release!)),\\n        for (final role in const [\'작사\', \'작곡\', \'작사·작곡\', \'편곡\', \'프로듀서\'])\\n          if (info.credits[role] != null) (role, info.credits[role]!.join(\', \')),\\n        if (info.genre != null) (\'장르\', info.genre!),", "        if (info.release != null) (tr.releaseDate, _date(info.release!)),\\n        for (final role in const [\'작사\', \'작곡\', \'작사·작곡\', \'편곡\', \'프로듀서\'])\\n          if (info.credits[role] != null) (_roleLabel(role), info.credits[role]!.join(\', \')),\\n        if (info.genre != null) (tr.genre, info.genre!),", 1], ["widgets/artist_info_sheet.dart", "if (info.trackNo != null) \'${info.trackNo}번째 곡\',", "if (info.trackNo != null) tr.trackNumber(\'${info.trackNo}\'),", 1], ["widgets/artist_info_sheet.dart", "children.add(section(\'지금 듣는 곡\'));", "children.add(section(tr.nowListening));", 1], ["widgets/artist_info_sheet.dart", "                      SizedBox(\\n                        width: 64,\\n                        child: Text(r.$1, style:", "                      SizedBox(\\n                        width: 76,\\n                        child: Text(r.$1, style:", 1], ["widgets/artist_info_sheet.dart", "Text(\'작사·작곡 찾는 중…\', style:", "Text(tr.findingCredits, style:", 1], ["widgets/artist_info_sheet.dart", "Text(\'이 가수의 앨범\', style:", "Text(tr.artistAlbums, style:", 1], ["widgets/artist_info_sheet.dart", "child: Text(\'(일부 오류가 있을 수 있어요)\',", "child: Text(tr.mayHaveErrors,", 1], ["widgets/artist_info_sheet.dart", "Text(\'정보: Deezer · Apple · MusicBrainz · Genius · Wikipedia\',", "Text(\'${tr.sourcesLabel}: Deezer · Apple · MusicBrainz · Genius · Wikipedia\',", 1], ["widgets/artist_info_sheet.dart", "Text(\'찾지 못한 항목은 보이지 않아요\',", "Text(tr.hiddenIfNotFound,", 1], ["widgets/artist_info_sheet.dart", "child: const Text(\'Wikipedia에서 더 보기 ›\', style: TextStyle(fontSize: 12.5)),", "child: Text(tr.moreOnWikipedia, style: const TextStyle(fontSize: 12.5)),", 1], ["widgets/artist_info_sheet.dart", "Text([a.year, a.kind].where((s) => s.isNotEmpty).join(\' · \'),", "Text([a.year, _kindLabel(a.kind)].where((s) => s.isNotEmpty).join(\' · \'),", 1]]')
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
