# -*- coding: utf-8 -*-
# 안드로이드 오토(차 화면) 바꾸기
#  - 라디오: 맨 위 '최근에 들었어요' → 즐겨찾기 → 국내는 방송사별 폴더 · 해외는 장르 폴더
#  - 음악: 맨 위 '랜덤 재생'
import os, sys

CAR = 'lib/services/car_browse.dart'
KOR = 'lib/screens/radio_korea_screen2.dart'
CTY = 'lib/screens/radio_country_stations_screen.dart'

EDITS = {
    KOR: [
        (
"""RadioStation? niceKoreanStationNow({""",
"""/// 차 화면(안드로이드 오토) 방송사별 폴더: (묶음 키, 이름, 칸 색) — 앱 '방송사별' 화면과 같은 묶음 · 순서
List<(String, String, int)> koreanCarGroups() => [
      for (final key in _BroadcasterGridScreen._order)
        (
          key,
          switch (key) {
            '기타' => tr.categoryEtc,
            '종교' => tr.stationCatReligion,
            '공동체' => tr.stationCatCommunity,
            '지역민방' => tr.stationCatPrivate,
            _ => key,
          },
          (_BroadcasterGridScreen._cardColors[key] ?? const Color(0xFF3A342A)).value,
        ),
    ];

/// 국내 방송 이름 → 방송사별 묶음 키 (KBS · MBC · … · 종교 · 지역민방 · 공동체 · 기타)
String koreanCarGroupOf(String name) {
  for (final k in koreanStations) {
    if (k.name == name) return _BroadcasterGridScreen._keyOf(k.broadcaster);
  }
  return '기타';
}

RadioStation? niceKoreanStationNow({""",
        ),
    ],
    CTY: [
        (
"""  Set<String> _genresOf(RadioStation s) {
    final tags = (s.tags ?? '')
        .toLowerCase()
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final out = <String>{};
    if (tags.isEmpty) return out;
    for (final g in _genreMap) {
      if (tags.any((t) => g.$2.any((k) => t.contains(k)))) out.add(g.$1);
    }
    return out;
  }""",
"""  Set<String> _genresOf(RadioStation s) => radioGenresOf(s); // 차 화면 장르 폴더와 같은 규칙""",
        ),
        (
"""class RadioCountryStationsScreen extends StatefulWidget {""",
"""/// 방송 하나의 장르 (해외 라디오 '장르' 칩 · 차 화면 장르 폴더가 같이 씀)
Set<String> radioGenresOf(RadioStation s) {
  final tags = (s.tags ?? '')
      .toLowerCase()
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
  final out = <String>{};
  if (tags.isEmpty) return out;
  for (final g in _RadioCountryStationsScreenState._genreMap) {
    if (tags.any((t) => g.$2.any((k) => t.contains(k)))) out.add(g.$1);
  }
  return out;
}

/// 장르 이름 (저장은 한국어 그대로, 보이는 건 앱 언어로) — 차 화면 장르 폴더용
String radioGenreLabel(String v) => switch (v) {
      '뉴스' => tr.genreNews,
      '토크' => tr.genreTalk,
      '스포츠' => tr.genreSports,
      '팝' => tr.genrePop,
      '인기곡' => tr.genreHits,
      '록' => tr.genreRock,
      '재즈' => tr.genreJazz,
      '클래식' => tr.genreClassical,
      '댄스·일렉' => tr.genreDance,
      '힙합' => tr.genreHiphop,
      'R&B·소울' => tr.genreRnb,
      '라틴' => tr.genreLatin,
      '컨트리' => tr.genreCountry,
      '올디스' => tr.genreOldies,
      '라운지' => tr.genreLounge,
      '포크' => tr.genreFolk,
      '블루스' => tr.genreBlues,
      '레게' => tr.genreReggae,
      '메탈' => tr.genreMetal,
      '종교' => tr.genreReligious,
      '어린이' => tr.genreKids,
      '볼리우드' => tr.genreBollywood,
      '세르타네주' => tr.genreSertanejo,
      _ => v,
    };

class RadioCountryStationsScreen extends StatefulWidget {""",
        ),
    ],
    CAR: [
        (
"""import '../screens/radio_korea_screen2.dart' show koreanStationsForCar;""",
"""import '../screens/radio_korea_screen2.dart' show koreanStationsForCar, koreanCarGroups, koreanCarGroupOf;
import '../screens/radio_country_stations_screen.dart' show radioGenresOf, radioGenreLabel;""",
        ),
        (
"""      if (parent.startsWith('ml:')) return await _musicList(parent.substring(3));""",
"""      if (parent.startsWith('ml:')) return await _musicList(parent.substring(3));
      if (parent.startsWith('rb:') || parent.startsWith('rg:')) return await _radioFolder(parent);""",
        ),
        (
"""  static Future<List<MediaItem>> _radioTab() async {
    final radio = _radio;
    if (radio == null) return const [];
    final items = <MediaItem>[];
    final kr = _country == 'KR';
    final korean = kr ? _korean() : const <RadioStation>[];
    // 즐겨찾기 먼저
    final favs = radio.favorites.toList();
    for (final s in favs) {
      if (s.countryCode == 'KR') {
        final i = korean.indexWhere((k) => k.name == s.name);
        if (i >= 0) _krArt[s.stationUuid] = _krArt[korean[i].stationUuid]!;
      }
    }
    _radioLists['rf'] = favs;
    for (final s in favs) {
      items.add(_stationItem(s, 'rf', group: tr.favorites));
    }
    // 그다음: 국내 방송 전체 / 해외는 고른 나라 인기 방송
    if (kr) {
      _radioLists['rk'] = korean;
      for (final s in korean) {
        items.add(_stationItem(s, 'rk', group: tr.all));
      }
    } else {
      final top = await _overseasTop(_country);
      _radioLists['ro'] = top;
      for (final s in top) {
        items.add(_stationItem(s, 'ro', group: tr.popularTab, sub: s.genre.isEmpty ? null : s.genre));
      }
    }
    return items;
  }""",
"""  /// 라디오 탭: 최근에 들었어요 → 즐겨찾기 → 폴더 (국내 방송사별 · 해외 장르)
  /// 운전 중에는 차 화면이 목록을 짧게만 보여 줘서, 한 줄로 길게 두지 않고 폴더로 나눔
  /// (최근·즐겨찾기가 없으면 그 줄은 안 보임)
  static Future<List<MediaItem>> _radioTab() async {
    final radio = _radio;
    if (radio == null) return const [];
    final items = <MediaItem>[];
    final kr = _country == 'KR';
    final korean = _korean(); // 국내 방송은 해외에서도 최근·즐겨찾기에 있으면 방송사별 칸 그림으로
    void krArt(List<RadioStation> list) {
      for (final s in list) {
        if (s.countryCode != 'KR') continue;
        final i = korean.indexWhere((k) => k.name == s.name);
        if (i >= 0) _krArt[s.stationUuid] = _krArt[korean[i].stationUuid]!;
      }
    }

    // 최근에 들었어요 (5개까지)
    final recent = radio.recentlyListened.take(5).toList();
    krArt(recent);
    _radioLists['rr'] = recent;
    for (final s in recent) {
      items.add(_stationItem(s, 'rr', group: tr.homeRecentHeader));
    }
    // 즐겨찾기
    final favs = radio.favorites.toList();
    krArt(favs);
    _radioLists['rf'] = favs;
    for (final s in favs) {
      items.add(_stationItem(s, 'rf', group: tr.favorites));
    }
    if (kr) {
      // 국내: 방송사별 폴더 (KBS · MBC · SBS · EBS · CBS · TBN · 종교 · 지역 민방 · 공동체)
      _radioLists['rk'] = korean;
      final byKey = <String, List<RadioStation>>{};
      for (final s in korean) {
        byKey.putIfAbsent(koreanCarGroupOf(s.name), () => []).add(s);
      }
      for (final (key, label, color) in koreanCarGroups()) {
        final list = byKey[key];
        if (list == null || list.isEmpty) continue;
        _radioLists['rb:$key'] = list;
        items.add(_folderItem('rb:$key', label, list.length, _tile(label, '', color), tr.byBroadcaster));
      }
    } else {
      // 해외: 장르 폴더 (앱 해외 라디오 '장르' 칩과 같은 묶음 · 방송 많은 장르부터 10개 · 나머지는 기타)
      final top = await _overseasTop(_country);
      _radioLists['ro'] = top;
      final byG = <String, List<RadioStation>>{};
      for (final s in top) {
        for (final g in radioGenresOf(s)) {
          byG.putIfAbsent(g, () => []).add(s);
        }
      }
      final keys = byG.keys.where((k) => byG[k]!.length >= 2).toList()
        ..sort((a, b) => byG[b]!.length.compareTo(byG[a]!.length));
      final shown = keys.take(10).toList();
      if (shown.isEmpty) {
        // 장르 정보가 거의 없는 나라: 예전처럼 인기 방송 한 묶음
        for (final s in top) {
          items.add(_stationItem(s, 'ro', group: tr.popularTab, sub: s.genre.isEmpty ? null : s.genre));
        }
        return items;
      }
      final inFolder = <String>{
        for (final k in shown)
          for (final s in byG[k]!) s.stationUuid,
      };
      for (final k in shown) {
        final label = radioGenreLabel(k);
        _radioLists['rg:$k'] = byG[k]!;
        items.add(_folderItem('rg:$k', label, byG[k]!.length, _tile(label, '', _colorOf(k)), tr.genre));
      }
      final etc = top.where((s) => !inFolder.contains(s.stationUuid)).toList();
      if (etc.isNotEmpty) {
        _radioLists['rg:기타'] = etc;
        items.add(_folderItem('rg:기타', tr.categoryEtc, etc.length, _tile(tr.categoryEtc, '', 0xFF3A342A), tr.genre));
      }
    }
    return items;
  }

  /// 폴더 칸 (누르면 그 방송사·장르 방송만 — 칸 모양으로)
  static MediaItem _folderItem(String id, String title, int n, Uri art, String group) => MediaItem(
        id: id,
        title: title,
        displaySubtitle: '$n',
        artist: '$n',
        playable: false,
        artUri: art,
        extras: {_group: group, ..._style(playable: _grid)},
      );

  /// 폴더 안 (방송사별 · 장르)
  static Future<List<MediaItem>> _radioFolder(String key) async {
    var list = _radioLists[key];
    if (list == null) {
      await _radioTab(); // 앱이 막 켜졌으면 목록부터
      list = _radioLists[key] ?? const <RadioStation>[];
    }
    final genre = key.startsWith('rg:');
    return [for (final s in list) _stationItem(s, key, sub: genre && s.genre.isNotEmpty ? s.genre : null)];
  }

  /// 라디오 목록이 바뀌면 라디오 탭 + 열어 둔 장르 폴더도 다시
  static void _changedRadio() {
    _changed(tabRadio);
    for (final k in _subjects.keys.where((k) => k.startsWith('rg:')).toList()) {
      _changed(k);
    }
  }""",
        ),
        (
"""        if (l.isNotEmpty) _changed(tabRadio); // 늦게 오면 그때 바꿔 끼우기""",
"""        if (l.isNotEmpty) _changedRadio(); // 늦게 오면 그때 바꿔 끼우기""",
        ),
        (
"""        if (had) _changed(tabRadio); // 저장된 걸 먼저 보여 줬으면 → 새 목록으로 바꿔 끼우기""",
"""        if (had) _changedRadio(); // 저장된 걸 먼저 보여 줬으면 → 새 목록으로 바꿔 끼우기""",
        ),
        (
"""    final all = m?.allSongs.length ?? 0;
    return [
      folder('recent', tr.homeRecentHeader),""",
"""    final all = m?.allSongs.length ?? 0;
    return [
      // 맨 위: 랜덤 재생 (누르면 내 곡 전체를 섞어서 바로 — 음악 화면 랜덤 듣기와 같음, 곡이 없으면 안 보임)
      if (all > 0)
        MediaItem(
            id: 'mshuffle', title: tr.shufflePlay, displaySubtitle: '$all', artist: '$all', playable: true,
            artUri: _icon('paran_ic_shuffle')),
      folder('recent', tr.homeRecentHeader),""",
        ),
        (
"""      } else if (id.startsWith('m:')) {""",
"""      } else if (id == 'mshuffle') {
        final songs = List<Song>.from(await _songsOf('all'))..shuffle();
        if (songs.isNotEmpty) await pp.playFromList(songs, 0);
      } else if (id.startsWith('m:')) {""",
        ),
        (
"""      for (final key in ['rf', 'rk', 'ro']) {""",
"""      for (final key in ['rr', 'rf', 'rk', 'ro']) {""",
        ),
    ],
}

MARK = ('lib/services/car_browse.dart', '_radioFolder')


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    p = MARK[0]
    if os.path.exists(p):
        with open(p, 'rb') as f:
            if MARK[1].encode() in f.read():
                print('이미 적용돼 있어요')
                return
    out = {}
    ok = True
    for rel, pairs in EDITS.items():
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(rel, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[rel] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for rel, text in out.items():
        with open(rel, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
