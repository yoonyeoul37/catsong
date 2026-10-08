# 동영상: 찍은 곳(위치 태그) 보여주기 — "서울 중구"
# 실행: python apply_video_place.py   (mp3_player_new 폴더에서)
import os, sys

SCREEN = os.path.join('lib', 'screens', 'video_screen.dart')
PROVIDER = os.path.join('lib', 'providers', 'video_provider.dart')
MANIFEST = os.path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')
DONE_FILE = PROVIDER
DONE_MARK = 'getVideoPlace'

MANIFEST_EDITS = [
    ("영상 속 위치 읽는 권한 (지금 위치 추적 아님)",
     '    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>',
     '    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>\n'
     '    <!-- 영상에 저장된 찍은 곳 읽기 (지금 위치 추적 아님) -->\n'
     '    <uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION"/>'),
]

KOTLIN_EDITS = [
    ("찍은 곳 찾기 전용 일꾼 (썸네일 안 느려지게)",
     "    private val metaExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()\n",
     "    private val metaExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()\n"
     "    // 영상 찍은 곳 찾기는 따로 (주소 바꾸느라 느려도 썸네일은 안 막히게)\n"
     "    private val placeExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()\n"),

    ("앱에서 찍은 곳 물어보면 답하기",
     '                "getVideoThumbnail" -> {',
     '''                "getVideoPlace" -> {
                    // 영상 속 찍은 곳(위치 태그) → "서울 중구" (뒤에서 하나씩, 화면 안 멈추게)
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        placeExecutor.execute {
                            val r = getVideoPlace(path)
                            runOnUiThread { result.success(r) }
                        }
                    }
                }
                "getVideoThumbnail" -> {'''),

    ("위치 태그 읽고 주소로 바꾸기",
     "    private fun doRenameVideo(",
     '''    /// 영상 속 위치 태그 → 주소 짧게 ("서울 중구"). 위치 없으면 null, 주소를 못 바꾸면 place 없이 좌표만
    private fun getVideoPlace(path: String): Map<String, Any?>? {
        val retriever = MediaMetadataRetriever()
        try {
            // 안드로이드 10 이상은 위치가 가려진 채로 읽혀서 '원본'으로 열기 (ACCESS_MEDIA_LOCATION)
            var opened = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    contentResolver.query(
                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                        arrayOf(MediaStore.Video.Media._ID),
                        "${MediaStore.Video.Media.DATA}=?", arrayOf(path), null
                    )?.use {
                        if (it.moveToFirst()) {
                            val id = it.getLong(0)
                            val uri = MediaStore.setRequireOriginal(
                                android.net.Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString()))
                            retriever.setDataSource(this, uri)
                            opened = true
                        }
                    }
                } catch (_: Exception) {}
            }
            if (!opened) retriever.setDataSource(path)
            val loc = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_LOCATION) ?: return null
            val m = Regex("([+-]\\\\d+(?:\\\\.\\\\d+)?)([+-]\\\\d+(?:\\\\.\\\\d+)?)").find(loc) ?: return null
            val lat = m.groupValues[1].toDouble()
            val lng = m.groupValues[2].toDouble()
            if (lat == 0.0 && lng == 0.0) return null
            var place: String? = null
            try {
                if (android.location.Geocoder.isPresent()) {
                    @Suppress("DEPRECATION")
                    val a = android.location.Geocoder(this, java.util.Locale.getDefault())
                        .getFromLocation(lat, lng, 1)?.firstOrNull()
                    if (a != null) {
                        // 짧게: 서울특별시 → 서울, 경기도 → 경기
                        val short = mapOf(
                            "서울특별시" to "서울", "부산광역시" to "부산", "대구광역시" to "대구", "인천광역시" to "인천",
                            "광주광역시" to "광주", "대전광역시" to "대전", "울산광역시" to "울산", "세종특별자치시" to "세종",
                            "경기도" to "경기", "강원도" to "강원", "강원특별자치도" to "강원", "충청북도" to "충북",
                            "충청남도" to "충남", "전라북도" to "전북", "전북특별자치도" to "전북", "전라남도" to "전남",
                            "경상북도" to "경북", "경상남도" to "경남", "제주특별자치도" to "제주"
                        )
                        val parts = listOf(a.adminArea, a.subAdminArea, a.locality, a.subLocality)
                            .mapNotNull { it?.trim()?.takeIf { s -> s.isNotEmpty() } }
                            .map { short[it] ?: it }
                            .distinct()
                            .take(2)
                        place = if (parts.isNotEmpty()) parts.joinToString(" ") else a.countryName
                    }
                }
            } catch (_: Exception) {}
            return mapOf("lat" to lat, "lng" to lng, "place" to place)
        } catch (e: Exception) {
            return null
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }

    private fun doRenameVideo('''),
]

PROVIDER_EDITS = [
    ("저장 미루기용 도구",
     "import 'package:flutter/foundation.dart';",
     "import 'dart:async';\nimport 'package:flutter/foundation.dart';"),

    ("찍은 곳 칸",
     "  bool _isLoading = false;\n  String _errorMessage = '';",
     """  final Map<String, String> _places = {}; // 영상마다 찍은 곳 ('' = 위치 없는 영상)
  final Set<String> _placeLoading = {};
  bool _placesRestored = false;
  bool _mediaLocAsked = false;
  Timer? _placeSaveTimer;
  bool _isLoading = false;
  String _errorMessage = '';"""),

    ("찍은 곳 알려주기 / 찾아오기 (한 번 찾은 건 기억)",
     "  // 이름을 바꾸면 경로가 바뀌어",
     """  // 찍은 곳 ("서울 중구"), 없으면 null
  String? placeOf(String uri) {
    final p = _places[uri];
    return (p == null || p.isEmpty) ? null : p;
  }

  // 찍은 곳 찾아오기 — 한 번 찾은 건 폰에 기억해서 다음엔 바로
  Future<void> loadPlace(String uri) async {
    if (!_placesRestored) {
      _placesRestored = true;
      final saved = (await SharedPreferences.getInstance()).getStringList('videoPlaces') ?? [];
      for (final s in saved) {
        final i = s.indexOf('\\t');
        if (i > 0) _places.putIfAbsent(s.substring(0, i), () => s.substring(i + 1));
      }
      if (saved.isNotEmpty) notifyListeners();
    }
    if (_places.containsKey(uri) || _placeLoading.contains(uri)) return;
    _placeLoading.add(uri);
    try {
      // 영상 속 위치를 읽는 권한 (보통 따로 묻는 창 없이 허용돼요)
      if (!_mediaLocAsked) {
        _mediaLocAsked = true;
        try {
          await Permission.accessMediaLocation.request();
        } catch (_) {}
      }
      final r = await _channel.invokeMethod('getVideoPlace', {'path': uri});
      final m = r == null ? null : Map<String, dynamic>.from(r);
      if (m == null || m['lat'] == null) {
        _places[uri] = ''; // 위치 태그 없는 영상
      } else if (m['place'] != null) {
        _places[uri] = m['place'] as String;
      } else {
        return; // 좌표는 있는데 주소를 못 바꿈 (인터넷 없음 등) → 다음에 다시
      }
      notifyListeners();
      _placeSaveTimer?.cancel();
      _placeSaveTimer = Timer(const Duration(seconds: 1), () async {
        (await SharedPreferences.getInstance())
            .setStringList('videoPlaces', [for (final e in _places.entries) '${e.key}\\t${e.value}']);
      });
    } catch (_) {
    } finally {
      _placeLoading.remove(uri);
    }
  }

  // 이름을 바꾸면 경로가 바뀌어"""),
]

SCREEN_EDITS = [
    ("영상 칸이 나타나면 찍은 곳 찾기",
     "    _loadThumbnail();\n    _loadResume();\n  }",
     "    _loadThumbnail();\n    _loadResume();\n"
     "    context.read<VideoProvider>().loadPlace(widget.video.uri); // 찍은 곳 (위치 태그 있으면)\n  }"),

    ("썸네일 왼쪽 아래: 찍은 곳 (재생 시간 표와 같은 모양, 흰 선 핀)",
     "                    // 새로 찍은(아직 안 본) 영상: 왼쪽 위 NEW",
     """                    // 찍은 곳: 왼쪽 아래 (오른쪽 재생 시간 표와 같은 모양, 흰 선 핀)
                    if (ctx.watch<VideoProvider>().placeOf(widget.video.uri) case final place?)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 110),
                          padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17140F).withOpacity(0.72),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place_outlined, size: 11, color: Colors.white),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  place,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // 새로 찍은(아직 안 본) 영상: 왼쪽 위 NEW"""),

    ("길게 눌렀을 때 창: 이름 아래 찍은 곳 (회색)",
     """                        child: Text(widget.video.titleDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),""",
     """                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.video.titleDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                            // 찍은 곳 (위치 태그 있으면) — 회색 선 핀
                            if (context.read<VideoProvider>().placeOf(widget.video.uri) case final place?)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.place_outlined, size: 13, color: sub),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(place,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),"""),

    ("재생 화면 제목 아래 찍은 곳 (회색)",
     """        title: Text(widget.video.titleDisplay,
            style: const TextStyle(color: Colors.white)),""",
     """        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.video.titleDisplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white)),
            // 찍은 곳 (위치 태그 있으면) — 회색 작은 글씨
            if (context.watch<VideoProvider>().placeOf(widget.video.uri) case final place?)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_outlined, size: 13, color: Colors.white54),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
          ],
        ),"""),
]


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def find_main_activity():
    for root, _, files in os.walk(os.path.join('android', 'app', 'src', 'main')):
        if 'MainActivity.kt' in files:
            return os.path.join(root, 'MainActivity.kt')
    return None


def main():
    ma = find_main_activity()
    for path in (SCREEN, PROVIDER, MANIFEST):
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path)
            print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
            sys.exit(1)
    if ma is None:
        print('❌ MainActivity.kt 를 못 찾았어요. mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    if DONE_MARK in open(DONE_FILE, encoding='utf-8').read():
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    jobs = [(MANIFEST, MANIFEST_EDITS), (ma, KOTLIN_EDITS), (PROVIDER, PROVIDER_EDITS), (SCREEN, SCREEN_EDITS)]
    results = {}
    num = 0
    for path, edits in jobs:
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balance(text)
        print(f'[{os.path.basename(path)}]')
        for name, old, new in edits:
            num += 1
            n = text.count(old)
            if n != 1:
                print(f'❌ {num}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
                print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
                sys.exit(1)
            text = text.replace(old, new)
            print(f'✔ {num}. {name}')
        if balance(text) != before:
            print(f'❌ {os.path.basename(path)} 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
            sys.exit(1)
        if crlf:
            text = text.replace('\n', '\r\n')
        results[path] = text

    for path, text in results.items():
        open(path, 'wb').write(text.encode('utf-8'))
    print(f'완료! {num}군데 바꿨어요.')


main()
