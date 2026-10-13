# 4×3 위젯 아래 3줄을 '지금 듣는 종류'에 맞추기
#  음악 듣는 중 → 최근에 들은 곡
#  라디오 듣는 중 → 최근에 들은 방송 (모자라면 라디오 최근·즐겨찾기)
#  자연 듣는 중 → 최근에 들은 자연소리 (모자라면 다른 자연소리)
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")


def one(name, under):
    hits = []
    for d, dirs, files in os.walk(os.path.join(ROOT, under)):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        if name in files:
            hits.append(os.path.normpath(os.path.join(d, name)))
    if len(hits) != 1:
        print(f"❌ {name} 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
        sys.exit(1)
    return hits[0]


def read(p):
    raw = open(p, "rb").read().decode("utf-8")
    return raw.replace("\r\n", "\n"), "\r\n" in raw


pw = one("PlayerWidget.kt", os.path.join("android", "app", "src", "main"))
hr = one("headset_resume.dart", "lib")
pw_s, pw_c = read(pw)
hr_s, hr_c = read(hr)

if "saveWidgetList" in hr_s:
    print("이미 적용돼 있어요")
    sys.exit(0)
if "_playRecent" not in hr_s or "fun recentRows" not in pw_s:
    print("❌ 먼저 apply_widget_4x3.py 를 실행해야 해요")
    sys.exit(1)

ok = True


def rep(src, old, new, what):
    global ok
    if src.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {src.count(old)}곳)")
        ok = False
        return src
    print(f"✔ {what}")
    return src.replace(old, new)


# ───────── PlayerWidget.kt: 앱이 골라 둔 3개를 읽기 ─────────
pw_s = rep(pw_s,
'''                val raw = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .getString("flutter.recent_content_v1", null)
''',
'''                // 앱이 지금 듣는 종류에 맞춰 골라 둔 3개 (아직 없으면 '최근에 들었어요' 앞에서)
                val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val picked = fp.getString("flutter.w_list", null)
                val raw = picked ?: fp.getString("flutter.recent_content_v1", null)
''', "PlayerWidget.kt: 앱이 골라 둔 3줄 읽기")
pw_s = rep(pw_s,
'''                        if (now != null && o.optString("title") == now) continue
''',
'''                        if (picked == null && now != null && o.optString("title") == now) continue
''', "PlayerWidget.kt: 지금 나오는 것 빼기는 앱이 함")

# ───────── headset_resume.dart ─────────
hr_s = rep(hr_s,
'''    _pp?.addListener(_rememberLast);
''',
'''    _pp?.addListener(_rememberLast);
    r.addListener(saveWidgetList); // 최근 목록이 바뀌면 4×3 위젯 아래 줄도
    saveWidgetList();
''', "headset_resume.dart: 최근 목록 바뀌면 위젯 줄 다시 고르기")

hr_s = rep(hr_s,
'''    SharedPreferences.getInstance().then((p) => p.setString('widget_last_played', jsonEncode(data)));
''',
'''    SharedPreferences.getInstance().then((p) => p.setString('widget_last_played', jsonEncode(data)));
    // 4×3 위젯 아래 줄: 지금 듣는 종류에 맞춰 다시 고르기
    final kind = data['type'] as String;
    SharedPreferences.getInstance().then((p) => p.setString('w_kind', kind)).then((_) => saveWidgetList());
''', "headset_resume.dart: 듣는 종류가 바뀌면 위젯 줄 다시 고르기")

hr_s = rep(hr_s,
'''    if (e == null) return;
    try {
      switch (e.type) {
        case RecentContentType.radio:''',
'''    if (e == null) {
      // 최근 기록에 없는 줄 (라디오 최근·즐겨찾기, 다른 자연소리에서 채운 것)
      try {
        if (type == 'radio') {
          for (final s in [...radio.recentlyListened, ...radio.favorites]) {
            if (s.stationUuid == key) {
              await _playSaved({'type': 'radio', 'station': s.toJson()}, r);
              return;
            }
          }
        } else if (type == 'nature') {
          for (final s in PlayerProvider.natureSoundOrder) {
            if (s['assetPath'] == key) {
              await pp.playNatureSound(key, s['name']!);
              return;
            }
          }
        }
      } catch (err) {
        debugPrint('위젯 최근 재생 오류: $err');
      }
      return;
    }
    try {
      switch (e.type) {
        case RecentContentType.radio:''', "headset_resume.dart: 채운 줄도 누르면 재생")

hr_s = rep(hr_s,
'''  /// 4×3 위젯 '최근에 들었어요' 줄 ("종류|키"): 그것 바로 틀기
''',
'''  /// 4×3 위젯 아래 3줄 고르기 — 지금 듣는 종류에 맞춰 (지금 나오는 것은 빼고)
  /// 음악 → 최근 곡 · 라디오 → 최근 방송 (모자라면 라디오 최근·즐겨찾기) · 자연 → 최근 자연 (모자라면 다른 자연소리)
  static Future<void> saveWidgetList() async {
    final pp = _pp, radio = _radio, r = _recent;
    if (pp == null || radio == null || r == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      final kind = p.getString('w_kind') ?? (r.entries.isNotEmpty ? r.entries.first.type.name : 'music');
      final items = <Map<String, String>>[];
      void add(String type, String key, String title, String sub) {
        if (items.length >= 3 || key.isEmpty || items.any((x) => x['key'] == key)) return;
        items.add({'type': type, 'key': key, 'title': title, 'subtitle': sub});
      }

      if (kind == 'radio') {
        final now = radio.currentStation?.stationUuid;
        for (final x in r.entries) {
          if (x.type == RecentContentType.radio && x.key != now) add('radio', x.key, x.title, x.subtitle);
        }
        for (final s in [...radio.recentlyListened, ...radio.favorites]) {
          if (s.stationUuid == now) continue;
          add('radio', s.stationUuid, s.name, (s.country?.isNotEmpty ?? false) ? s.country! : '라디오');
        }
      } else if (kind == 'nature') {
        final now = pp.natureSoundName;
        for (final x in r.entries) {
          if (x.type == RecentContentType.nature && x.title != now) add('nature', x.key, x.title, '자연소리');
        }
        for (final s in PlayerProvider.natureSoundOrder) {
          if (s['name'] == now) continue;
          add('nature', s['assetPath']!, s['name']!, '자연소리');
        }
      } else {
        final now = pp.natureSoundName == null ? pp.currentSong?.uri : null;
        for (final x in r.entries) {
          if (x.type == RecentContentType.music && x.key != now) add('music', x.key, x.title, x.subtitle);
        }
      }
      await p.setString('w_list', jsonEncode(items));
      await _ch.invokeMethod('refreshWidget');
    } catch (_) {}
  }

  /// 4×3 위젯 '최근에 들었어요' 줄 ("종류|키"): 그것 바로 틀기
''', "headset_resume.dart: 위젯 줄 고르는 코드 넣기")

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)

for p, s, c in ((pw, pw_s, pw_c), (hr, hr_s, hr_c)):
    if c:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
