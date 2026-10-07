# 파란소리: 인터넷 찾기에서 영어 제목·가수를 한글로 (목록에서 바로 보이게)
# 실행: C:\apps\mp3_player_new 에서  python apply_lookup_korean.py
import os, sys, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
ROOT = os.path.dirname(os.path.abspath(__file__))
ML = os.path.join(ROOT, "lib", "services", "music_lookup.dart")
ES = os.path.join(ROOT, "lib", "screens", "edit_song_screen.dart")
for p in (ML, ES):
    if not os.path.exists(p):
        print("[실패] 파일을 못 찾았어요:", p)
        sys.exit(1)
def read(p):
    with open(p, "r", encoding="utf-8", newline="") as f:
        return f.read()
def write(p, s, nl):
    with open(p, "w", encoding="utf-8", newline="") as f:
        f.write(s.replace("\n", nl) if nl == "\r\n" else s)
raw_es = read(ES); nl_es = "\r\n" if "\r\n" in raw_es else "\n"; es = raw_es.replace("\r\n", "\n")
raw_ml = read(ML); nl_ml = "\r\n" if "\r\n" in raw_ml else "\n"
if "koreanize(" in raw_ml and "koreanize(" in es:
    print("[참고] 이미 바뀌어 있어요. 그대로 둘게요.")
    sys.exit(0)
# 편집 화면 _lookup 함수 통째로 바꾸기
SIG = "  Future<void> _lookup() async"
i = es.find(SIG)
if i < 0:
    print("[실패] 편집 화면에서 _lookup 을 못 찾았어요. 이 메시지를 보내주세요.")
    sys.exit(1)
# 위에 붙은 설명 줄도 같이
li = es.rfind("\n", 0, i)
prev = es.rfind("\n", 0, li)
if es[prev+1:li].strip().startswith("///"):
    i = prev + 1
j = es.find("{", es.find(SIG))
d = 0; k = j
while True:
    c = es[k]
    if c == "{": d += 1
    elif c == "}":
        d -= 1
        if d == 0: break
    k += 1
FN = r"""  /// 🔍 인터넷에서 정확한 정보 찾기 → 후보 중에서 고르기 (영어 제목·가수는 한글로 바꿔서 보여줌)
  Future<void> _lookup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _searching = true);
    final results = await lookupSong(_titleController.text, _artistController.text);
    if (!mounted) return;
    setState(() => _searching = false);
    if (results.isEmpty) {
      showParanToast(context, '인터넷에서 이 곡을 찾지 못했어요');
      return;
    }
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final hangul = RegExp(r'[가-힣]');

    // 위에서 4개까지 한글로 바꿔서 보여주기 (1초에 하나씩 쓱 바뀜)
    final shown = List<LookupResult>.from(results);
    StateSetter? sheetSet;
    var open = true;
    () async {
      for (var i = 0; i < shown.length && i < 4; i++) {
        if (!open) return;
        final k = await koreanize(shown[i]);
        if (!open) return;
        if (!identical(k, shown[i])) {
          shown[i] = k;
          try {
            sheetSet?.call(() {});
          } catch (_) {}
        }
      }
    }();

    final picked = await showModalBottomSheet<LookupResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        sheetSet = setSheet;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5), // 다른 고르는 창과 같은 베이지
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이 곡이 맞나요?', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('맞는 곡을 고르면 제목·가수·앨범·앨범 사진이 채워져요',
                    style: TextStyle(color: sub, fontSize: 12.5)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final r = shown[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(ctx, r),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(r.thumbUrl,
                                    width: 52, height: 52, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(width: 52, height: 52, color: sub.withOpacity(0.2))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('${r.artist} · ${r.album}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: sub, fontSize: 12.5)),
                                    // 한글로 바꿨으면 원래 영어는 작게
                                    if (r.koreanized)
                                      Text('${r.origTitle ?? r.title} · ${r.origArtist ?? r.artist}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: sub.withOpacity(0.7), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: sub),
                    child: const Text('맞는 곡이 없어요'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
    open = false;
    sheetSet = null;
    if (picked == null || !mounted) return;
    setState(() {
      // 제목: 지금 한글인데 고른 게 영어면 한글 그대로
      final curTitle = _titleController.text.trim();
      _titleController.text =
          (hangul.hasMatch(curTitle) && !hangul.hasMatch(picked.title)) ? curTitle : picked.title;
      // 가수: 지금 한글인데 고른 게 영어면 한글 그대로 (아이유 → IU 방지)
      final curArtist = _artistController.text.trim();
      final keepKorean =
          hangul.hasMatch(curArtist) && !hangul.hasMatch(picked.artist) && !curArtist.contains('알 수 없');
      _artistController.text = keepKorean ? curArtist : picked.artist;
      _albumController.text = picked.album;
      _pickedArt = picked.artUrl;
    });
    // 아래쪽 후보라 목록에서 못 바꿨으면 → 고른 다음 한글로 한 번 더 (Kim Hyun Sik → 김현식)
    if (!picked.koreanized &&
        (!hangul.hasMatch(_artistController.text) || !hangul.hasMatch(_titleController.text))) {
      final k = await koreanize(picked);
      if (!mounted || identical(k, picked)) return;
      setState(() {
        if (!hangul.hasMatch(_artistController.text)) _artistController.text = k.artist;
        if (!hangul.hasMatch(_titleController.text)) _titleController.text = k.title;
      });
    }
  }
"""
es = es[:i] + FN.rstrip("\n") + es[k+1:]
if "paran_toast.dart" not in es:
    es = es.replace("import '../services/music_lookup.dart';\n", "import '../services/music_lookup.dart';\nimport '../widgets/paran_toast.dart';\n", 1)
B = os.path.join(ROOT, "backup_lookup_korean")
os.makedirs(os.path.join(B, "services"), exist_ok=True)
os.makedirs(os.path.join(B, "screens"), exist_ok=True)
shutil.copy2(ML, os.path.join(B, "services", "music_lookup.dart"))
shutil.copy2(ES, os.path.join(B, "screens", "edit_song_screen.dart"))
ML_NEW = r"""import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// 인터넷에서 찾은 곡 정보
class LookupResult {
  final String title;
  final String artist;
  final String album;
  final String artUrl; // 앨범 사진 (큰 사이즈)
  final String thumbUrl; // 목록에 보여줄 작은 사진
  final int durationSec; // 노래 길이 (한글 제목 찾을 때 씀)
  final String? origTitle; // 한글로 바꿨으면 원래 영어 제목
  final String? origArtist; // 한글로 바꿨으면 원래 영어 가수 이름
  const LookupResult(this.title, this.artist, this.album, this.artUrl, this.thumbUrl,
      {this.durationSec = 0, this.origTitle, this.origArtist});

  bool get koreanized => origTitle != null || origArtist != null;
}

final _hangul = RegExp(r'[가-힣]');

/// 제목·가수로 곡 찾기
/// 1) 디저(한국 노래 많음) → 2) 못 찾으면 애플(미국 스토어) → 3) 그래도 없으면 제목만으로 다시
Future<List<LookupResult>> lookupSong(String title, String artist) async {
  final t = title.trim();
  final a = artist.trim();
  final unknown = a.isEmpty || a.contains('알 수 없') || a.toLowerCase().contains('unknown');
  final term = unknown ? t : '$a $t';

  var list = await _deezer(term);
  if (list.isEmpty) list = await _itunes(term);
  if (list.isEmpty && !unknown) {
    list = await _deezer(t);
    if (list.isEmpty) list = await _itunes(t);
  }
  return list;
}

/// 디저 검색 (가입·키 필요 없음)
Future<List<LookupResult>> _deezer(String term) async {
  if (term.isEmpty) return [];
  try {
    final url = Uri.parse('https://api.deezer.com/search?q=${Uri.encodeQueryComponent(term)}&limit=8');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    debugPrint('곡 찾기(디저): "$term" → ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
    final out = <LookupResult>[];
    final seen = <String>{};
    for (final r in (data['data'] as List? ?? []).cast<Map>()) {
      final title = (r['title'] ?? '').toString();
      final artist = ((r['artist'] as Map?)?['name'] ?? '').toString();
      final albumMap = (r['album'] as Map?) ?? {};
      final album = (albumMap['title'] ?? '').toString();
      final art = (albumMap['cover_xl'] ?? albumMap['cover_big'] ?? '').toString();
      final thumb = (albumMap['cover_medium'] ?? art).toString();
      final dur = (r['duration'] is num) ? (r['duration'] as num).toInt() : 0;
      if (title.isEmpty || art.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue; // 같은 것 빼기
      out.add(LookupResult(title, artist, album, art, thumb, durationSec: dur));
    }
    debugPrint('곡 찾기 결과(디저): ${out.length}개');
    return out;
  } catch (e) {
    debugPrint('곡 찾기 오류(디저): $e');
    return [];
  }
}

/// 애플 검색 (한국 스토어는 노래 판매가 없어서 미국 스토어로)
Future<List<LookupResult>> _itunes(String term) async {
  if (term.isEmpty) return [];
  try {
    final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeQueryComponent(term)}&entity=song&country=US&limit=8');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    debugPrint('곡 찾기(애플): "$term" → ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
    final out = <LookupResult>[];
    final seen = <String>{};
    for (final r in (data['results'] as List? ?? []).cast<Map>()) {
      final title = (r['trackName'] ?? '').toString();
      final artist = (r['artistName'] ?? '').toString();
      final album = (r['collectionName'] ?? '').toString();
      final small = (r['artworkUrl100'] ?? '').toString();
      final dur = (r['trackTimeMillis'] is num) ? (r['trackTimeMillis'] as num).toInt() ~/ 1000 : 0;
      if (title.isEmpty || small.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue;
      out.add(LookupResult(title, artist, album, small.replaceAll('100x100bb', '600x600bb'), small,
          durationSec: dur));
    }
    debugPrint('곡 찾기 결과(애플): ${out.length}개');
    return out;
  } catch (e) {
    debugPrint('곡 찾기 오류(애플): $e');
    return [];
  }
}

// ───────── 뮤직브레인즈: 영어로 된 한국 가수·제목 → 한글 ─────────
// 무료라 1초에 한 번만 물어볼 수 있어서 순서대로 천천히

DateTime _mbLast = DateTime(2000);

Future<Map?> _mbGet(String url) async {
  final wait = 1100 - DateTime.now().difference(_mbLast).inMilliseconds;
  if (wait > 0) await Future.delayed(Duration(milliseconds: wait));
  _mbLast = DateTime.now();
  try {
    final res = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Paransori/1.0 (info@knexm.com)', // 뮤직브레인즈는 이름표가 필요해요
    }).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
  } catch (e) {
    debugPrint('뮤직브레인즈 오류: $e');
    return null;
  }
}

/// 영어 가수 이름 → (한글 이름, 뮤직브레인즈 번호). 못 찾으면 (null, null)
Future<(String?, String?)> _mbArtist(String latin) async {
  final name = latin.trim();
  if (name.isEmpty) return (null, null);
  final q = Uri.encodeQueryComponent('artist:"$name" OR alias:"$name"');
  final data = await _mbGet('https://musicbrainz.org/ws/2/artist/?query=$q&fmt=json&limit=5');
  if (data == null) return (null, null);
  for (final a in (data['artists'] as List? ?? []).cast<Map>()) {
    if ((a['score'] ?? 0) < 85) continue; // 이름이 거의 같은 사람만
    final id = (a['id'] ?? '').toString();
    final n = (a['name'] ?? '').toString();
    if (_hangul.hasMatch(n)) return (n, id);
    for (final al in (a['aliases'] as List? ?? []).cast<Map>()) {
      final an = (al['name'] ?? '').toString();
      if (_hangul.hasMatch(an)) return (an, id);
    }
    return (null, id); // 같은 사람인데 한글 이름이 없음
  }
  return (null, null);
}

/// 영어로 된 한국 가수 이름 → 한글 이름 (Kim Hyun Sik → 김현식). 못 찾으면 null
Future<String?> koreanArtistName(String latin) async {
  if (_hangul.hasMatch(latin)) return null;
  final (ko, _) = await _mbArtist(latin);
  return ko;
}

/// 그 가수의 노래 중 길이가 같은 노래의 한글 제목 찾기 (Like Rain, Like Music → 비처럼 음악처럼)
Future<String?> _mbKoreanTitle(String artistId, int durationSec) async {
  if (artistId.isEmpty || durationSec <= 0) return null;
  final lo = (durationSec - 3) * 1000, hi = (durationSec + 3) * 1000;
  final q = Uri.encodeQueryComponent('arid:$artistId AND dur:[$lo TO $hi]');
  final data = await _mbGet('https://musicbrainz.org/ws/2/recording/?query=$q&fmt=json&limit=10');
  if (data == null) return null;
  for (final r in (data['recordings'] as List? ?? []).cast<Map>()) {
    final t = (r['title'] ?? '').toString();
    if (_hangul.hasMatch(t)) return t;
  }
  return null;
}

/// 찾은 곡의 가수·제목이 영어면 한글로 바꾼 것 (못 바꾸면 그대로)
Future<LookupResult> koreanize(LookupResult r) async {
  if (_hangul.hasMatch(r.title) && _hangul.hasMatch(r.artist)) return r; // 이미 한글
  var t = r.title, a = r.artist;
  String? artistId;
  if (!_hangul.hasMatch(a)) {
    final (ko, id) = await _mbArtist(a);
    artistId = id;
    if (ko != null) a = ko;
  }
  // 한국 가수일 때만 제목도 찾아보기 (외국 노래는 그대로)
  if (!_hangul.hasMatch(t) && _hangul.hasMatch(a) && artistId != null) {
    final kt = await _mbKoreanTitle(artistId, r.durationSec);
    if (kt != null) t = kt;
  }
  if (t == r.title && a == r.artist) return r;
  return LookupResult(t, a, r.album, r.artUrl, r.thumbUrl,
      durationSec: r.durationSec,
      origTitle: t != r.title ? r.title : null,
      origArtist: a != r.artist ? r.artist : null);
}

/// 앨범 사진 받아오기
Future<List<int>?> downloadArt(String url) async {
  try {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    return res.statusCode == 200 ? res.bodyBytes : null;
  } catch (_) {
    return null;
  }
}
"""
write(ML, ML_NEW, nl_ml)
write(ES, es, nl_es)
print("[완료] 바꿨어요: services/music_lookup.dart")
print("[완료] 바꿨어요: screens/edit_song_screen.dart")
print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
print("   문제가 있으면 backup_lookup_korean 폴더의 원본으로 되돌릴 수 있어요.")
