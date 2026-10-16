# -*- coding: utf-8 -*-
# 곡 정보 수정에 장르 넣기 + 인터넷 정보 찾기로 장르 자동 채우기
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_genre_edit.py
import os, sys

FILES = {
    'song': 'lib/models/song.dart',
    'provider': 'lib/providers/music_provider.dart',
    'lookup': 'lib/services/music_lookup.dart',
    'edit': 'lib/screens/edit_song_screen.dart',
}

# (파일, 설명, 찾을 코드, 바꿀 코드)
EDITS = []
def E(f, desc, old, new):
    EDITS.append((f, desc, old, new))

# ───────── song.dart ─────────
E('song', '장르 이름 바꾸기 함수 추가',
"""  /// 폰 언어 → 이름 칸 번호 (0 한국어 · 1 영어 · 2 일본어 · 3 번체 · 4 간체)
  static int _genreLangIndex() {""",
"""  /// 장르 글자(파일에 적힌 것·고른 것) → 화면에 보일 이름 ('' = 장르 없음)
  static String genreNameOf(String raw) {
    final k = _cleanGenre(raw);
    if (k.isEmpty || !k.startsWith('@')) return k;
    final names = _genreNames[k.substring(1)];
    return names == null ? k.substring(1) : names[_genreLangIndex()];
  }

  /// 고르는 창에 보여 줄 많이 쓰는 장르 ('@ballad' …)
  static List<String> get commonGenres => [for (final k in _genreNames.keys) '@$k'];

  /// 폰 언어 칸 번호 (다른 화면에서 5개 언어 글자 고를 때)
  static int langIndex() => _genreLangIndex();

  /// 폰 언어 → 이름 칸 번호 (0 한국어 · 1 영어 · 2 일본어 · 3 번체 · 4 간체)
  static int _genreLangIndex() {""")

E('song', '고른 장르(@이름)는 그대로',
"""    var g = raw.trim();
    if (g.isEmpty) return '';
""",
"""    var g = raw.trim();
    if (g.isEmpty) return '';
    // 고르는 창에서 고른 장르 ('@ballad')는 그대로
    if (g.startsWith('@') && _genreNames.containsKey(g.substring(1))) return g;
""")

E('song', '인터넷 검색 장르 이름 추가',
"""    '童谣': 'kids',
  };""",
"""    '童谣': 'kids',
    // 인터넷 검색(디저)에서 오는 이름
    'films/games': 'ost', 'filmscores': 'ost', 'electro': 'electronic',
  };""")

NONE_OLD = """  static const _none = {'', 'unknown', '<unknown>', 'other', 'others', 'genre', 'none', 'unknowngenre', '기타'};"""
NONE_NEW = """  static const _none = {
    '', 'unknown', '<unknown>', 'other', 'others', 'genre', 'none', 'unknowngenre', '기타',
    'music', 'musica', 'misc', 'miscellaneous', 'various', 'etc',
    '음악', '音楽', '音樂', '音乐', 'その他', '其他',
  };"""

# ───────── music_lookup.dart ─────────
E('lookup', '검색 결과에 장르·앨범 번호 칸',
"""  final String? origArtist; // 한글로 바꿨으면 원래 영어 가수 이름
  const LookupResult(this.title, this.artist, this.album, this.artUrl, this.thumbUrl,
      {this.durationSec = 0, this.origTitle, this.origArtist});""",
"""  final String? origArtist; // 한글로 바꿨으면 원래 영어 가수 이름
  final String genre; // 장르 (애플은 바로 옴, 디저는 앨범에서 따로 찾음)
  final int albumId; // 디저 앨범 번호 (장르 찾을 때 씀)
  const LookupResult(this.title, this.artist, this.album, this.artUrl, this.thumbUrl,
      {this.durationSec = 0, this.origTitle, this.origArtist, this.genre = '', this.albumId = 0});""")

E('lookup', '디저: 앨범 번호 기억',
"""      final dur = (r['duration'] is num) ? (r['duration'] as num).toInt() : 0;
      if (title.isEmpty || art.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue; // 같은 것 빼기
      out.add(LookupResult(title, artist, album, art, thumb, durationSec: dur));""",
"""      final dur = (r['duration'] is num) ? (r['duration'] as num).toInt() : 0;
      final albumId = (albumMap['id'] is num) ? (albumMap['id'] as num).toInt() : 0;
      if (title.isEmpty || art.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue; // 같은 것 빼기
      out.add(LookupResult(title, artist, album, art, thumb, durationSec: dur, albumId: albumId));""")

E('lookup', '애플: 장르 같이 받기',
"""      out.add(LookupResult(title, artist, album, small.replaceAll('100x100bb', '600x600bb'), small,
          durationSec: dur));""",
"""      out.add(LookupResult(title, artist, album, small.replaceAll('100x100bb', '600x600bb'), small,
          durationSec: dur, genre: (r['primaryGenreName'] ?? '').toString()));""")

E('lookup', '한글로 바꿀 때 장르 유지',
"""      origArtist: a != r.artist ? r.artist : null);
}""",
"""      origArtist: a != r.artist ? r.artist : null,
      genre: r.genre,
      albumId: r.albumId);
}""")

E('lookup', '장르 찾기 함수 추가',
"""/// 앨범 사진 받아오기
Future<List<int>?> downloadArt(String url) async {""",
"""/// 고른 곡의 장르 찾기 (못 찾으면 '')
/// 애플 결과는 이미 장르가 있고, 디저는 앨범 정보에서 → 그래도 없으면 애플에서 한 번 더
Future<String> lookupGenre(LookupResult r) async {
  const skip = {'', 'all', 'music', 'asian music', 'other', 'others'};
  bool ok(String g) => !skip.contains(g.trim().toLowerCase());
  if (ok(r.genre)) return r.genre.trim();
  if (r.albumId > 0) {
    try {
      final res = await http
          .get(Uri.parse('https://api.deezer.com/album/${r.albumId}'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
        final list = ((data['genres'] as Map?)?['data'] as List?) ?? [];
        for (final g in list.cast<Map>()) {
          final name = (g['name'] ?? '').toString();
          if (ok(name)) return name.trim();
        }
      }
    } catch (e) {
      debugPrint('장르 찾기 오류(디저): $e');
    }
  }
  // 애플에서 같은 곡을 찾아서 장르만 가져오기
  final list = await _itunes('${r.origArtist ?? r.artist} ${r.origTitle ?? r.title}');
  if (list.isNotEmpty && ok(list.first.genre)) return list.first.genre.trim();
  return '';
}

/// 앨범 사진 받아오기
Future<List<int>?> downloadArt(String url) async {""")

# ───────── music_provider.dart ─────────
E('provider', '고친 정보 불러오기: 장르(4번째)도',
"""      if (data != null && data.length == 3) {
        _editedSongs[uri] = {
          'title': data[0],
          'artist': data[1],
          'album': data[2],
        };
      }""",
"""      // 예전: [제목, 가수, 앨범] / 장르까지 고친 곡: [제목, 가수, 앨범, 장르]
      if (data != null && data.length >= 3) {
        _editedSongs[uri] = {
          'title': data[0],
          'artist': data[1],
          'album': data[2],
          if (data.length >= 4) 'genre': data[3],
        };
      }""")

E('provider', '고친 정보 저장: 장르 고친 곡만 4번째에',
"""    if (song.uri != null) {
      await prefs.setStringList('edited_song_${song.uri}', [
        song.title,
        song.artist,
        song.album,
      ]);
    }""",
"""    if (song.uri != null) {
      final keepGenre = _editedSongs[song.uri]?['genre'] != null; // 장르를 고친 적 있는 곡만
      await prefs.setStringList('edited_song_${song.uri}', [
        song.title,
        song.artist,
        song.album,
        if (keepGenre) song.genre,
      ]);
    }""")

E('provider', 'updateSongInfo에 장르 받기',
"""  Future<void> updateSongInfo(Song song, {String? title, String? artist, String? album}) async {
    if (title != null) song.title = title;
    if (artist != null) song.artist = artist;
    if (album != null) song.album = album;
    song.isEdited = true;
    await _saveEditedSong(song);
    // 새로고침해도 방금 고친 내용이 유지되도록 바로 기억해둠
    if (song.uri != null) {
      _editedSongs[song.uri!] = {
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
      };
    }
""",
"""  Future<void> updateSongInfo(Song song, {String? title, String? artist, String? album, String? genre}) async {
    if (title != null) song.title = title;
    if (artist != null) song.artist = artist;
    if (album != null) song.album = album;
    if (genre != null) song.genre = genre; // 장르 (앱 안에만 저장)
    song.isEdited = true;
    // 새로고침해도 방금 고친 내용이 유지되도록 바로 기억해둠 (장르는 고친 적 있을 때만)
    if (song.uri != null) {
      final keepGenre = genre != null || _editedSongs[song.uri!]?['genre'] != null;
      _editedSongs[song.uri!] = {
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        if (keepGenre) 'genre': song.genre,
      };
    }
    await _saveEditedSong(song);
""")

E('provider', '곡 읽을 때 고친 장르로',
"""          song.isEdited = true;
        }
        // 인터넷에서 찾아 넣은 앨범 사진이 있으면 그걸로""",
"""          song.isEdited = true;
          final eg = edited['genre'];
          if (eg != null) song.genre = eg; // 고친 장르
        }
        // 인터넷에서 찾아 넣은 앨범 사진이 있으면 그걸로""")

# ───────── edit_song_screen.dart ─────────
E('edit', '장르 값 추가',
"""  late TextEditingController _albumController;
""",
"""  late TextEditingController _albumController;
  late String _genre = widget.song.genre; // 장르 (파일에 적힌 것 또는 고른 것)
""")

E('edit', '되돌리기에 장르 포함 (값)',
"""  // 검색 결과 넣기 전 값 (되돌리기용: 제목·가수·앨범·사진)
  (String, String, String, String?)? _beforePick;""",
"""  // 검색 결과 넣기 전 값 (되돌리기용: 제목·가수·앨범·사진·장르)
  (String, String, String, String?, String)? _beforePick;""")

E('edit', '되돌리기에 장르 포함 (되돌릴 때)',
"""      _pickedArt = b.$4;
      _beforePick = null;""",
"""      _pickedArt = b.$4;
      _genre = b.$5;
      _beforePick = null;""")

E('edit', '되돌리기에 장르 포함 (넣기 전)',
"""      _beforePick ??= (_titleController.text, _artistController.text, _albumController.text, _pickedArt);""",
"""      _beforePick ??= (_titleController.text, _artistController.text, _albumController.text, _pickedArt, _genre);""")

E('edit', '인터넷 정보 고르면 장르도 채우기',
"""      _pickedArt = picked.artUrl;
    });
""",
"""      _pickedArt = picked.artUrl;
    });
    // 장르도 같이 채우기 (뒤에서 찾아서, 찾으면 쓱 들어감)
    lookupGenre(picked).then((g) {
      if (!mounted || _beforePick == null || Song.genreNameOf(g).isEmpty) return;
      setState(() => _genre = g);
    });
""")

E('edit', '카드에 장르 줄 추가',
"""                  _field(tr.fieldAlbum, _albumController, ink, sub),
""",
"""                  _field(tr.fieldAlbum, _albumController, ink, sub),
                  Divider(height: 1, thickness: 0.5, indent: 16, color: line),
                  _genreField(ink, sub),
""")

E('edit', '장르 줄·고르는 창 추가',
"""  /// 흰 카드 안 한 줄: 위에 작은 이름, 아래에 고칠 글자""",
"""  /// 장르 칸 글자 (5개 언어: 한국어·영어·일본어·번체·간체)
  static const _gtText = {
    'label': ['장르', 'Genre', 'ジャンル', '類型', '类型'],
    'pick': ['장르 고르기', 'Choose a genre', 'ジャンルを選ぶ', '選擇類型', '选择类型'],
    'none': ['장르 없음', 'No genre', 'ジャンルなし', '無類型', '无类型'],
    'type': ['직접 쓰기', 'Type your own', '自分で入力', '自行輸入', '自行输入'],
  };
  String _gt(String k) => _gtText[k]![Song.langIndex()];

  /// 장르 줄: 누르면 고르는 창 (제목·가수·앨범 줄과 같은 모양)
  Widget _genreField(Color ink, Color sub) {
    final name = Song.genreNameOf(_genre);
    return InkWell(
      onTap: () => _pickGenre(ink, sub),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_gt('label'), style: TextStyle(color: sub, fontSize: 12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(name.isEmpty ? _gt('none') : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: name.isEmpty ? sub : ink,
                            fontSize: 15.5,
                            fontWeight: name.isEmpty ? FontWeight.w500 : FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: sub, size: 22),
          ],
        ),
      ),
    );
  }

  /// 장르 고르는 창: 직접 쓰기 + 많이 쓰는 장르 + 장르 없음
  Future<void> _pickGenre(Color ink, Color sub) async {
    FocusManager.instance.primaryFocus?.unfocus();
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final card = isDark ? const Color(0xFF24221F) : Colors.white;
    final onInk = isDark ? const Color(0xFF24221F) : Colors.white;
    final curName = Song.genreNameOf(_genre); // 지금 장르 (같은 이름 칸을 진하게)
    final typed = TextEditingController();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        Widget chip(String text, String value, bool on) => GestureDetector(
              onTap: () => Navigator.pop(ctx, value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: on ? ink : card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(text,
                    style: TextStyle(
                        color: on ? onInk : ink,
                        fontSize: 13.5,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
        void submit() {
          final t = typed.text.trim();
          if (t.isNotEmpty) Navigator.pop(ctx, t);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 자판이 올라오면 같이 위로
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5), // 다른 고르는 창과 같은 베이지
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_gt('pick'), style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  // 직접 쓰기
                  Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: typed,
                            style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600),
                            cursorColor: ink,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: _gt('type'),
                              hintStyle: TextStyle(color: sub, fontSize: 14, fontWeight: FontWeight.w500),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: submit,
                          icon: Icon(Icons.check_rounded, color: ink, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 많이 쓰는 장르 (폰 언어로) + 맨 끝에 장르 없음
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in Song.commonGenres)
                            chip(Song.genreNameOf(g), g, Song.genreNameOf(g) == curName),
                          chip(_gt('none'), '', curName.isEmpty),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _genre = picked);
  }

  /// 흰 카드 안 한 줄: 위에 작은 이름, 아래에 고칠 글자""")

E('edit', '저장할 때 장르도 (바꿨을 때만)',
"""      album: _albumController.text,
    );""",
"""      album: _albumController.text,
      genre: _genre != widget.song.genre ? _genre : null, // 장르는 바꿨을 때만
    );""")


def main():
    texts, crlf = {}, {}
    for k, p in FILES.items():
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.')
            sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[k] = '\r\n' in raw
        texts[k] = raw.replace('\r\n', '\n')

    if 'Future<String> lookupGenre(' in texts['lookup'] and '_pickGenre(' in texts['edit']:
        print('이미 적용돼 있어요')
        return

    ok = True
    for f, desc, old, new in EDITS:
        n = texts[f].count(old)
        if n == 1:
            texts[f] = texts[f].replace(old, new)
            print(f'✔ {os.path.basename(FILES[f])} - {desc}')
        else:
            print(f'❌ {os.path.basename(FILES[f])} - {desc} (찾을 코드가 {n}군데)')
            ok = False

    # 'Music' 같은 이름 → 기타 (아까 바꾸기 코드로 이미 했으면 넘어감)
    if NONE_OLD in texts['song']:
        texts['song'] = texts['song'].replace(NONE_OLD, NONE_NEW)
        print('✔ song.dart - Music 같은 이름은 기타로')
    elif "'music', 'musica'" in texts['song']:
        print('✔ song.dart - Music 같은 이름은 기타로 (이미 돼 있음)')
    else:
        print('❌ song.dart - Music 같은 이름은 기타로 (_none 줄을 못 찾음)')
        ok = False

    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.')
        sys.exit(1)

    for k, p in FILES.items():
        t = texts[k].replace('\n', '\r\n') if crlf[k] else texts[k]
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n완료! 4개 파일을 저장했어요.')


if __name__ == '__main__':
    main()
