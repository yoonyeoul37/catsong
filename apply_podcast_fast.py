# -*- coding: utf-8 -*-
# 팟캐스트 회차 목록 빨리 뜨게
#  A. 한 번 연 팟캐스트는 폰에 저장 → 다음부터 저장된 목록을 바로 보여 주고, 새 회차는 뒤에서 조용히 확인
#     (최근 연 20개까지만 저장 · 회차 목록 주소도 기억해서 애플에 다시 안 물어봄)
#  C. 큰 회차 목록 파일은 뒤에서 읽기 (화면이 멈칫하지 않게)
import os, sys

P = {
    'pod': os.path.join('lib', 'podcast', 'podcast.dart'),
    'screens': os.path.join('lib', 'podcast', 'podcast_screens.dart'),
}


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


D = {}
for k, p in P.items():
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8')
    D[k] = {'s': raw.replace('\r\n', '\n'), 'crlf': '\r\n' in raw}
    D[k]['orig'] = D[k]['s']


def name(k):
    return os.path.basename(P[k])


def rep(k, label, old, new, done):
    s = D[k]['s']
    if done in s:
        print('✔', name(k), label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{name(k)} {label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    D[k]['s'] = s.replace(old, new)
    print('✔', name(k), label)


# ───────── podcast.dart ─────────
k = 'pod'
rep(k, '설명 글자도 읽기 (저장된 목록용)',
    "        art: '${j['art'] ?? ''}',\n      );\n}\n\n// ───────────────────────── 가져오기",
    "        art: '${j['art'] ?? ''}',\n        desc: '${j['desc'] ?? ''}',\n      );\n}\n\n// ───────────────────────── 가져오기",
    done="desc: '${j['desc'] ?? ''}',")

rep(k, '회차 목록 주소 기억',
    '  static final Map<String, PodcastShow> _shows = {}; // 회차 목록에서 읽은 그림·이름으로 채운 것\n',
    '  static final Map<String, PodcastShow> _shows = {}; // 회차 목록에서 읽은 그림·이름으로 채운 것\n'
    '  static final Map<String, String> _feedOf = {}; // 애플 번호 → 회차 목록 주소 (폰에도 저장)\n'
    '  static bool _feedOfLoaded = false;\n'
    '\n'
    '  static Future<void> _loadFeedOf() async {\n'
    '    if (_feedOfLoaded) return;\n'
    '    _feedOfLoaded = true;\n'
    '    try {\n'
    '      final raw = (await SharedPreferences.getInstance()).getString(\'pod_feed_ids\');\n'
    "      if (raw != null) (jsonDecode(raw) as Map).forEach((k, v) => _feedOf['$k'] = '$v');\n"
    '    } catch (_) {}\n'
    '  }\n',
    done='static final Map<String, String> _feedOf = {};')

rep(k, '순위에서 고른 것: 기억한 주소 먼저',
    '  static Future<PodcastShow> withFeed(PodcastShow s, String country) async {\n'
    '    if (s.feedUrl.isNotEmpty) return s;\n'
    "    final u = Uri.https('itunes.apple.com', '/lookup', {'id': s.id, 'entity': 'podcast', 'country': country.toLowerCase()});\n"
    '    final r = await http.get(u, headers: _ua).timeout(const Duration(seconds: 15));\n'
    "    final res = (jsonDecode(utf8.decode(r.bodyBytes))['results'] as List?) ?? const [];\n"
    "    if (res.isEmpty || '${res.first['feedUrl'] ?? ''}'.isEmpty) throw Exception('no feed');\n"
    '    final x = res.first;\n'
    "    return s.copyWith(feedUrl: '${x['feedUrl']}', art: '${x['artworkUrl600'] ?? s.art}');\n"
    '  }\n',
    '  static Future<PodcastShow> withFeed(PodcastShow s, String country) async {\n'
    '    if (s.feedUrl.isNotEmpty) return s;\n'
    '    await _loadFeedOf();\n'
    '    final known = _feedOf[s.id];\n'
    '    if (known != null && known.isNotEmpty) return s.copyWith(feedUrl: known); // 전에 물어본 것 → 바로\n'
    "    final u = Uri.https('itunes.apple.com', '/lookup', {'id': s.id, 'entity': 'podcast', 'country': country.toLowerCase()});\n"
    '    final r = await http.get(u, headers: _ua).timeout(const Duration(seconds: 15));\n'
    "    final res = (jsonDecode(utf8.decode(r.bodyBytes))['results'] as List?) ?? const [];\n"
    "    if (res.isEmpty || '${res.first['feedUrl'] ?? ''}'.isEmpty) throw Exception('no feed');\n"
    '    final x = res.first;\n'
    "    final feed = '${x['feedUrl']}';\n"
    '    _feedOf[s.id] = feed;\n'
    '    try {\n'
    '      if (_feedOf.length > 300) _feedOf.remove(_feedOf.keys.first);\n'
    "      (await SharedPreferences.getInstance()).setString('pod_feed_ids', jsonEncode(_feedOf));\n"
    '    } catch (_) {}\n'
    "    return s.copyWith(feedUrl: feed, art: '${x['artworkUrl600'] ?? s.art}');\n"
    '  }\n',
    done='final known = _feedOf[s.id];')

OLD_EPISODES = (
    '  static Future<List<PodcastEpisode>> episodes(PodcastShow s, {bool refresh = false}) async {\n'
    '    final hit = _episodes[s.feedUrl];\n'
    '    if (hit != null && !refresh) return hit;\n'
    '    final r = await http.get(Uri.parse(s.feedUrl), headers: _ua).timeout(const Duration(seconds: 25));\n'
    "    if (r.statusCode != 200) throw Exception('feed ${r.statusCode}');\n"
    '    final doc = XmlDocument.parse(utf8.decode(r.bodyBytes, allowMalformed: true));\n'
    "    final channel = doc.findAllElements('channel').first;\n"
    "    final showArt = _attr(_child(channel, 'itunes:image'), 'href') ??\n"
    "        _child(_child(channel, 'image'), 'url')?.innerText.trim() ??\n"
    '        s.art;\n'
    '    _shows[s.id] = s.copyWith(\n'
    '      art: s.art.isNotEmpty ? s.art : showArt,\n'
    "      title: s.title.isNotEmpty ? s.title : (_child(channel, 'title')?.innerText.trim() ?? ''),\n"
    '    );\n'
    '    final list = <PodcastEpisode>[];\n'
    "    for (final it in channel.findElements('item')) {\n"
    "      final enc = _child(it, 'enclosure');\n"
    "      final url = _attr(enc, 'url') ?? '';\n"
    '      if (url.isEmpty) continue;\n'
    "      final title = _child(it, 'title')?.innerText.trim() ?? '';\n"
    '      list.add(PodcastEpisode(\n'
    "        guid: (_child(it, 'guid')?.innerText.trim().isNotEmpty ?? false) ? _child(it, 'guid')!.innerText.trim() : url,\n"
    '        title: title,\n'
    '        url: url,\n'
    "        published: _parseDate(_child(it, 'pubDate')?.innerText ?? ''),\n"
    "        durationSec: _parseDuration(_child(it, 'itunes:duration')?.innerText ?? ''),\n"
    "        art: _attr(_child(it, 'itunes:image'), 'href') ?? showArt,\n"
    "        desc: _plain(_child(it, 'description')?.innerText ?? _child(it, 'itunes:summary')?.innerText ?? ''),\n"
    '      ));\n'
    '      if (list.length >= 200) break;\n'
    '    }\n'
    '    return _episodes[s.feedUrl] = list;\n'
    '  }\n')
NEW_EPISODES = (
    '  static Future<List<PodcastEpisode>> episodes(PodcastShow s, {bool refresh = false}) async {\n'
    '    final hit = _episodes[s.feedUrl];\n'
    '    if (hit != null && !refresh) return hit;\n'
    '    final r = await http.get(Uri.parse(s.feedUrl), headers: _ua).timeout(const Duration(seconds: 25));\n'
    "    if (r.statusCode != 200) throw Exception('feed ${r.statusCode}');\n"
    '    // 큰 파일 읽기는 뒤에서 (화면이 멈칫하지 않게)\n'
    '    final parsed = await compute(_parseFeed, (r.bodyBytes as List<int>, s.art));\n'
    '    final info = s.copyWith(\n'
    '      art: s.art.isNotEmpty ? s.art : parsed.$1,\n'
    '      title: s.title.isNotEmpty ? s.title : parsed.$2,\n'
    '    );\n'
    '    _shows[s.id] = info;\n'
    '    final list = parsed.$3;\n'
    '    _saveFeed(s.feedUrl, info, list); // 다음에 바로 보이게 폰에 저장\n'
    '    return _episodes[s.feedUrl] = list;\n'
    '  }\n'
    '\n'
    '  /// 폰에 저장해 둔 회차 목록 (한 번 연 팟캐스트) — 없으면 null\n'
    '  static Future<List<PodcastEpisode>?> savedEpisodes(PodcastShow s) async {\n'
    '    if (s.feedUrl.isEmpty) return null;\n'
    '    final hit = _episodes[s.feedUrl];\n'
    '    if (hit != null) return hit;\n'
    '    try {\n'
    '      final raw = (await SharedPreferences.getInstance()).getString(_feedKey(s.feedUrl));\n'
    '      if (raw == null) return null;\n'
    '      final j = jsonDecode(raw) as Map<String, dynamic>;\n'
    "      final info = j['show'];\n"
    '      if (info is Map) _shows[s.id] = PodcastShow.fromJson(Map<String, dynamic>.from(info));\n'
    "      final eps = [for (final x in (j['eps'] as List)) PodcastEpisode.fromJson(Map<String, dynamic>.from(x))];\n"
    '      return eps.isEmpty ? null : eps;\n'
    '    } catch (_) {\n'
    '      return null;\n'
    '    }\n'
    '  }\n'
    '\n'
    '  /// 회차 목록 저장 (최근 연 20개까지 · 설명 글자는 맨 위 회차만 → 작게)\n'
    '  static Future<void> _saveFeed(String feedUrl, PodcastShow info, List<PodcastEpisode> eps) async {\n'
    '    try {\n'
    '      final sp = await SharedPreferences.getInstance();\n'
    '      final key = _feedKey(feedUrl);\n'
    '      await sp.setString(\n'
    '          key,\n'
    '          jsonEncode({\n'
    "            'show': info.toJson(),\n"
    "            'eps': [for (var i = 0; i < eps.length; i++) i == 0 ? {...eps[i].toJson(), 'desc': eps[i].desc} : eps[i].toJson()],\n"
    '          }));\n'
    "      final keys = (sp.getStringList('pod_feed_keys') ?? <String>[])\n"
    '        ..remove(key)\n'
    '        ..insert(0, key);\n'
    '      while (keys.length > 20) {\n'
    '        await sp.remove(keys.removeLast());\n'
    '      }\n'
    "      await sp.setStringList('pod_feed_keys', keys);\n"
    '    } catch (_) {}\n'
    '  }\n'
    '\n'
    '  /// 주소 → 짧은 저장 이름 (언제나 같은 값)\n'
    '  static String _feedKey(String url) {\n'
    '    var h = 0x811c9dc5;\n'
    '    for (final c in url.codeUnits) {\n'
    '      h ^= c;\n'
    '      h = (h * 0x01000193) & 0xffffffff;\n'
    '    }\n'
    "    return 'pod_feed_${h.toRadixString(16)}';\n"
    '  }\n')
rep(k, '회차 목록: 뒤에서 읽고 폰에 저장', OLD_EPISODES, NEW_EPISODES, done='static Future<List<PodcastEpisode>?> savedEpisodes(')

rep(k, '뒤에서 읽는 함수',
    "/// '오늘' · '어제' · '3일 전'",
    '/// 회차 목록 파일 읽기 (뒤에서 따로 돌아감) → (그림, 이름, 회차들)\n'
    '(String, String, List<PodcastEpisode>) _parseFeed((List<int>, String) input) {\n'
    '  final doc = XmlDocument.parse(utf8.decode(input.$1, allowMalformed: true));\n'
    "  final channel = doc.findAllElements('channel').first;\n"
    "  final showArt = PodcastApi._attr(PodcastApi._child(channel, 'itunes:image'), 'href') ??\n"
    "      PodcastApi._child(PodcastApi._child(channel, 'image'), 'url')?.innerText.trim() ??\n"
    '      input.$2;\n'
    "  final showTitle = PodcastApi._child(channel, 'title')?.innerText.trim() ?? '';\n"
    '  final list = <PodcastEpisode>[];\n'
    "  for (final it in channel.findElements('item')) {\n"
    "    final enc = PodcastApi._child(it, 'enclosure');\n"
    "    final url = PodcastApi._attr(enc, 'url') ?? '';\n"
    '    if (url.isEmpty) continue;\n'
    "    final guid = PodcastApi._child(it, 'guid')?.innerText.trim() ?? '';\n"
    '    list.add(PodcastEpisode(\n'
    '      guid: guid.isNotEmpty ? guid : url,\n'
    "      title: PodcastApi._child(it, 'title')?.innerText.trim() ?? '',\n"
    '      url: url,\n'
    "      published: PodcastApi._parseDate(PodcastApi._child(it, 'pubDate')?.innerText ?? ''),\n"
    "      durationSec: PodcastApi._parseDuration(PodcastApi._child(it, 'itunes:duration')?.innerText ?? ''),\n"
    "      art: PodcastApi._attr(PodcastApi._child(it, 'itunes:image'), 'href') ?? showArt,\n"
    "      desc: PodcastApi._plain(\n"
    "          PodcastApi._child(it, 'description')?.innerText ?? PodcastApi._child(it, 'itunes:summary')?.innerText ?? ''),\n"
    '    ));\n'
    '    if (list.length >= 200) break;\n'
    '  }\n'
    '  return (showArt, showTitle, list);\n'
    '}\n'
    '\n'
    "/// '오늘' · '어제' · '3일 전'",
    done='_parseFeed((List<int>, String) input)')

# ───────── podcast_screens.dart: 저장된 목록 먼저 → 뒤에서 새로 ─────────
k = 'screens'
rep(k, '저장된 목록 먼저 보여 주기',
    '  Future<List<PodcastEpisode>> _load() async {\n'
    '    _show = await PodcastApi.withFeed(_show, widget.country);\n'
    '    final eps = await PodcastApi.episodes(_show);\n'
    '    final info = PodcastApi.showInfo(_show.id);\n'
    '    if (info != null && mounted) setState(() => _show = info.copyWith(feedUrl: _show.feedUrl));\n'
    '    _latestGuid = eps.isNotEmpty ? eps.first.guid : null;\n'
    '    PodcastPlayer.instance.markSeen(_show, eps);\n'
    '    return eps;\n'
    '  }\n',
    '  List<PodcastEpisode>? _fresh; // 저장된 목록을 먼저 보여 준 뒤 뒤에서 새로 받은 목록\n'
    '\n'
    '  Future<List<PodcastEpisode>> _load() async {\n'
    '    _show = await PodcastApi.withFeed(_show, widget.country);\n'
    '    // 한 번 연 팟캐스트: 폰에 저장된 목록을 바로 보여 주고, 새 회차는 뒤에서 조용히 확인\n'
    '    final saved = await PodcastApi.savedEpisodes(_show);\n'
    '    if (saved != null) {\n'
    '      _useInfo(saved);\n'
    '      _refresh();\n'
    '      return saved;\n'
    '    }\n'
    '    final eps = await PodcastApi.episodes(_show);\n'
    '    _useInfo(eps);\n'
    '    return eps;\n'
    '  }\n'
    '\n'
    '  void _useInfo(List<PodcastEpisode> eps) {\n'
    '    final info = PodcastApi.showInfo(_show.id);\n'
    '    if (info != null && mounted) setState(() => _show = info.copyWith(feedUrl: _show.feedUrl));\n'
    '    _latestGuid = eps.isNotEmpty ? eps.first.guid : null;\n'
    '    PodcastPlayer.instance.markSeen(_show, eps);\n'
    '  }\n'
    '\n'
    '  Future<void> _refresh() async {\n'
    '    try {\n'
    '      final eps = await PodcastApi.episodes(_show, refresh: true);\n'
    '      if (!mounted) return;\n'
    '      setState(() => _fresh = eps);\n'
    '      _useInfo(eps);\n'
    '    } catch (_) {} // 인터넷이 안 되면 저장된 목록 그대로\n'
    '  }\n',
    done='List<PodcastEpisode>? _fresh;')
rep(k, '새로 받은 목록 쓰기',
    '          final eps = snap.data ?? const <PodcastEpisode>[];\n',
    '          final eps = _fresh ?? snap.data ?? const <PodcastEpisode>[];\n',
    done='final eps = _fresh ?? snap.data')
rep(k, '불러오는 중 표시',
    '              if (snap.connectionState != ConnectionState.done)\n                const Padding(\n',
    '              if (_fresh == null && snap.connectionState != ConnectionState.done)\n                const Padding(\n',
    done='if (_fresh == null && snap.connectionState != ConnectionState.done)')
rep(k, '못 불러왔을 때',
    '              else if (snap.hasError || eps.isEmpty)\n',
    '              else if ((_fresh == null && snap.hasError) || eps.isEmpty)\n',
    done='(_fresh == null && snap.hasError) || eps.isEmpty')
rep(k, '다시 시도',
    '                          onPressed: () => setState(() => _eps = _load()),\n',
    '                          onPressed: () => setState(() {\n'
    '                                _fresh = null;\n'
    '                                _eps = _load();\n'
    '                              }),\n',
    done='                                _fresh = null;\n')

for k in D:
    s = D[k]['s']
    if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
        fail(name(k) + ' 괄호가 안 맞아요')
changed = [k for k in D if D[k]['s'] != D[k]['orig']]
if not changed:
    print('이미 적용돼 있어요')
    sys.exit(0)
for k in changed:
    s = D[k]['s']
    if D[k]['crlf']:
        s = s.replace('\n', '\r\n')
    open(P[k], 'wb').write(s.encode('utf-8'))
print('저장했어요:', ', '.join(name(k) for k in changed))
