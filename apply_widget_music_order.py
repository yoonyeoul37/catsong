# -*- coding: utf-8 -*-
# 위젯 음악 버튼: 음악 화면에 보이는 순서(제목·가수·장르 정렬 + 초성 묶음) 그대로 맨 위 곡부터
# (예전엔 파일 이름 순서라 화면 맨 위 곡과 달랐음)
import os, sys

PATH = os.path.join('lib', 'services', 'headset_resume.dart')

IMPORT_ANCHOR = "import '../utils/nature_sound_catalog.dart';"
IMPORT_ADD = "\nimport '../models/song.dart';\nimport '../utils/index_letter.dart';"

OLD_LIST = "m.songs.isNotEmpty ? m.songs : m.allSongs"
NEW_LIST = "await _screenOrder(m.allSongs)"

HELPER_ANCHOR = "  /// 3초 동안 천천히 원래 크기로 (처음엔 아주 천천히)\n"
HELPER = """  /// 음악 화면과 같은 순서 (제목 / 가수 / 장르 정렬 · 초성 묶음) — 위젯 '첫 곡'이 화면 맨 위 곡과 같게
  static Future<List<Song>> _screenOrder(List<Song> songs) async {
    var byArtist = false, byGenre = false;
    try {
      final p = await SharedPreferences.getInstance();
      byArtist = p.getBool('song_sort_by_artist') ?? false;
      byGenre = (p.getBool('song_sort_by_genre') ?? false) && !byArtist;
    } catch (_) {}
    int byTitle(Song a, Song b) => a.titleDisplay.toLowerCase().compareTo(b.titleDisplay.toLowerCase());
    if (byGenre) {
      // 장르: 곡 많은 장르부터, 장르 없는 곡은 맨 아래, 장르 안에서는 제목순
      final byG = <String, List<Song>>{};
      for (final s in songs) {
        byG.putIfAbsent(s.genreKey, () => []).add(s);
      }
      final keys = byG.keys.where((k) => k.isNotEmpty).toList()
        ..sort((a, b) {
          final c = byG[b]!.length.compareTo(byG[a]!.length);
          return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
        });
      if (byG.containsKey('')) keys.add('');
      return [for (final k in keys) ...(byG[k]!..sort(byTitle))];
    }
    // 제목 · 가수: 초성(글자) 묶음 순서대로, 묶음 안에서는 가나다순
    final lang = tr.localeName.split('_').first;
    String keyOf(Song s) => byArtist ? s.artistDisplay : s.titleDisplay;
    final byGroup = <String, List<Song>>{};
    for (final s in songs) {
      byGroup.putIfAbsent(indexGroupFor(keyOf(s), lang), () => []).add(s);
    }
    final out = <Song>[];
    for (final g in indexGroupsFor(lang)) {
      final list = byGroup[g];
      if (list == null) continue;
      list.sort((a, b) {
        if (byArtist) {
          final c = a.artistDisplay.toLowerCase().compareTo(b.artistDisplay.toLowerCase());
          if (c != 0) return c;
        }
        return byTitle(a, b);
      });
      out.addAll(list);
    }
    return out.isEmpty ? songs : out;
  }

"""


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if '_screenOrder(' in text:
        print('이미 적용돼 있어요')
        return

    if text.count(IMPORT_ANCHOR) != 1:
        print('❌ import 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(IMPORT_ANCHOR, IMPORT_ANCHOR + IMPORT_ADD)
    print('✔ 곡·초성 묶음 가져오기')

    n = text.count(OLD_LIST)
    if n != 3:
        print('❌ 곡 목록 고르는 곳이 3군데가 아니에요 (찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
        sys.exit(1)
    text = text.replace(OLD_LIST, NEW_LIST)
    print('✔ 위젯 음악 버튼 · 재생 버튼 · 최근 곡 → 화면과 같은 순서로 (3군데)')

    if text.count(HELPER_ANCHOR) != 1:
        print('❌ 순서 맞추기 넣을 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(HELPER_ANCHOR, HELPER + HELPER_ANCHOR)
    print('✔ 음악 화면 순서 만들기 추가')

    if crlf:
        text = text.replace('\n', '\r\n')
    with open(PATH, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요:', PATH)


main()
