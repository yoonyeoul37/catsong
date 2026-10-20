# -*- coding: utf-8 -*-
# 홈 '최근에 들었어요'에 팟캐스트 넣기 (30초 넘게 들은 회차 · 누르면 듣던 곳부터)
# 팟캐스트 기록은 따로 저장 → 홈 위젯·이어폰 이어 듣기 쪽 기록은 그대로 (영향 없음)
# + 홈에서 팟캐스트가 나오면 아래 팟캐스트 미니플레이어
import os, re, sys

P = {
    'entry': os.path.join('lib', 'models', 'recent_content_entry.dart'),
    'headset': os.path.join('lib', 'services', 'headset_resume.dart'),
    'pod': os.path.join('lib', 'podcast', 'podcast.dart'),
    'home': os.path.join('lib', 'screens', 'home_screen.dart'),
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


def rep(k, label, old, new, done, count=1):
    s = D[k]['s']
    if done in s:
        print('✔', name(k), label, '(이미 돼 있음)')
        return
    n = s.count(old)
    if n != count:
        fail(f'{name(k)} {label} — 찾을 코드를 못 찾았어요 ({n}곳)')
    D[k]['s'] = s.replace(old, new)
    print('✔', name(k), label)


# ── 기록 종류에 '팟캐스트' ──
k = 'entry'
rep(k, "종류에 '팟캐스트'", 'enum RecentContentType { music, radio, nature, sleep }',
    'enum RecentContentType { music, radio, nature, sleep, podcast }', done='sleep, podcast }')
rep(k, '팟캐스트 정보 칸', '  final String? natureAssetPath;\n',
    '  final String? natureAssetPath;\n  final Map<String, dynamic>? podcastData; // 팟캐스트: {show, ep} (홈에서만 씀)\n',
    done='final Map<String, dynamic>? podcastData;')
rep(k, '팟캐스트 정보 받기', '    this.natureAssetPath,\n  });',
    '    this.natureAssetPath,\n    this.podcastData,\n  });', done='    this.podcastData,\n  });')
rep(k, '팟캐스트 정보 저장', "    'natureAssetPath': natureAssetPath,\n  };",
    "    'natureAssetPath': natureAssetPath,\n    'podcastData': podcastData,\n  };", done="'podcastData': podcastData,")
rep(k, '팟캐스트 정보 읽기', "      natureAssetPath: json['natureAssetPath']?.toString(),\n    );",
    "      natureAssetPath: json['natureAssetPath']?.toString(),\n"
    "      podcastData: json['podcastData'] != null ? Map<String, dynamic>.from(json['podcastData']) : null,\n    );",
    done="podcastData: json['podcastData']")

# ── 이어폰·위젯 쪽: 새 종류는 그냥 넘어가기 (이 기록에는 안 들어옴) ──
rep('headset', '새 종류 넘어가기 (2곳)',
    '        case RecentContentType.sleep:\n          break;',
    '        case RecentContentType.sleep:\n'
    '        case RecentContentType.podcast: // 팟캐스트는 이 기록에 안 들어감 (홈에서만 따로 섞어 보여 줌)\n'
    '          break;',
    done='case RecentContentType.podcast:', count=2)

# ── podcast.dart: 최근 들은 회차 (따로 저장) ──
k = 'pod'
rep(k, '최근 기록 모양', 'class PodcastPlayer extends ChangeNotifier {\n',
    "/// 홈 '최근에 들었어요'용 팟캐스트 기록 하나\n"
    'class PodRecent {\n'
    '  final PodcastShow show;\n'
    '  final PodcastEpisode episode;\n'
    '  final DateTime at;\n'
    '  const PodRecent(this.show, this.episode, this.at);\n'
    '}\n'
    '\n'
    'class PodcastPlayer extends ChangeNotifier {\n',
    done='class PodRecent {')
rep(k, '최근 기록 목록', '  final Set<String> _done = {}; // 끝까지 들은 회차\n',
    '  final Set<String> _done = {}; // 끝까지 들은 회차\n'
    "  final List<PodRecent> recent = []; // 홈 '최근에 들었어요'용 (30초 넘게 들은 회차, 최근 10개)\n"
    '  Timer? _recentTimer;\n',
    done='final List<PodRecent> recent = [];')
rep(k, '30초 넘게 들으면 기록',
    '    _saveTick = Timer.periodic(const Duration(seconds: 5), (_) => _savePos());\n    _persist();\n  }\n',
    '    _saveTick = Timer.periodic(const Duration(seconds: 5), (_) => _savePos());\n'
    "    // 30초 넘게 들으면 홈 '최근에 들었어요'에\n"
    '    _recentTimer?.cancel();\n'
    '    _recentTimer = Timer(const Duration(seconds: 30), () {\n'
    '      if (active && episode?.guid == e.guid && isPlaying) _addRecent(s, e);\n'
    '    });\n'
    '    _persist();\n'
    '  }\n'
    '\n'
    '  void _addRecent(PodcastShow s, PodcastEpisode e) {\n'
    '    recent.removeWhere((r) => r.episode.guid == e.guid);\n'
    '    recent.insert(0, PodRecent(s, e, DateTime.now()));\n'
    '    if (recent.length > 10) recent.removeRange(10, recent.length);\n'
    '    _persist();\n'
    '    notifyListeners();\n'
    '  }\n',
    done='void _addRecent(PodcastShow s, PodcastEpisode e)')
rep(k, '최근 기록 불러오기', "      final last = sp.getString('pod_last');\n",
    "      final recRaw = sp.getString('pod_recent');\n"
    '      if (recRaw != null) {\n'
    '        for (final j in (jsonDecode(recRaw) as List)) {\n'
    '          final m = Map<String, dynamic>.from(j);\n'
    '          recent.add(PodRecent(\n'
    "            PodcastShow.fromJson(Map<String, dynamic>.from(m['show'])),\n"
    "            PodcastEpisode.fromJson(Map<String, dynamic>.from(m['ep'])),\n"
    "            DateTime.tryParse('${m['at']}') ?? DateTime.now(),\n"
    '          ));\n'
    '        }\n'
    '      }\n'
    "      final last = sp.getString('pod_last');\n",
    done="sp.getString('pod_recent')")
rep(k, '최근 기록 저장', "      await sp.setDouble('pod_speed', speed);\n",
    "      await sp.setDouble('pod_speed', speed);\n"
    "      await sp.setString('pod_recent',\n"
    "          jsonEncode([for (final r in recent) {'show': r.show.toJson(), 'ep': r.episode.toJson(), 'at': r.at.toIso8601String()}]));\n",
    done="sp.setString('pod_recent'")

# ── 홈 화면 ──
k = 'home'
rep(k, 'import', "import '../widgets/more_menu_sheet.dart';\n",
    "import '../widgets/more_menu_sheet.dart';\nimport '../podcast/podcast.dart';\nimport '../podcast/podcast_screens.dart' show PodcastMiniPlayer;\n",
    done="import '../podcast/podcast.dart';")
rep(k, '최근 목록에 팟캐스트 섞기',
    '      for (final e in context.watch<RecentContentProvider>().entries) {\n',
    '      for (final e in _withPodcasts(context.watch<RecentContentProvider>().entries, context.watch<PodcastPlayer>())) {\n',
    done='_withPodcasts(context.watch<RecentContentProvider>().entries')
rep(k, '팟캐스트 카드 (그림 · 누르면 이어 듣기)',
    '                      case RecentContentType.sleep:\n                        typeIcon = Icons.bedtime_rounded;\n',
    '                      case RecentContentType.podcast:\n'
    '                        typeIcon = Icons.podcasts_rounded;\n'
    '                        typeColor = const Color(0xFFB4876A);\n'
    '                        final pd = item.podcastData ?? const {};\n'
    "                        final pShow = PodcastShow.fromJson(Map<String, dynamic>.from(pd['show'] ?? const {}));\n"
    "                        final pEp = PodcastEpisode.fromJson(Map<String, dynamic>.from(pd['ep'] ?? const {}));\n"
    '                        final pArt = pEp.art.isNotEmpty ? pEp.art : pShow.art;\n'
    '                        final pTile = _recentTile(isDarkMode, const Color(0xFFE4DCCD), Icons.podcasts_rounded);\n'
    "                        thumbnail = pArt.startsWith('http')\n"
    '                            ? CachedNetworkImage(\n'
    '                                imageUrl: pArt,\n'
    '                                width: 72,\n'
    '                                height: 72,\n'
    '                                fit: BoxFit.cover,\n'
    '                                memCacheWidth: 216,\n'
    '                                placeholder: (_, __) => pTile,\n'
    '                                errorWidget: (_, __, ___) => pTile,\n'
    '                              )\n'
    '                            : pTile;\n'
    '                        onTapAction = () {\n'
    '                          if (pEp.url.isNotEmpty) PodcastPlayer.instance.play(pShow, pEp); // 듣던 곳부터\n'
    '                        };\n'
    '                        break;\n'
    '                      case RecentContentType.sleep:\n                        typeIcon = Icons.bedtime_rounded;\n',
    done='case RecentContentType.podcast:\n                        typeIcon = Icons.podcasts_rounded;')
rep(k, '홈 아래 팟캐스트 미니플레이어',
    '                  if (context.watch<SoundMixProvider>().hasSession) {\n'
    '                    return const SoundMixMiniPlayer();\n'
    '                  }\n'
    '                  return const SizedBox.shrink();\n',
    '                  if (context.watch<SoundMixProvider>().hasSession) {\n'
    '                    return const SoundMixMiniPlayer();\n'
    '                  }\n'
    '                  if (context.watch<PodcastPlayer>().active) {\n'
    '                    return const PodcastMiniPlayer();\n'
    '                  }\n'
    '                  return const SizedBox.shrink();\n',
    done='return const PodcastMiniPlayer();')
if 'List<RecentContentEntry> _withPodcasts(' not in D[k]['s']:
    D[k]['s'] = D[k]['s'].rstrip('\n') + '\n' + (
        '\n'
        "/// 홈 '최근에 들었어요': 음악·라디오·자연 기록 + 팟캐스트 기록(따로 저장)을 시간순으로 섞기\n"
        'List<RecentContentEntry> _withPodcasts(List<RecentContentEntry> base, PodcastPlayer pod) {\n'
        '  if (pod.recent.isEmpty) return base;\n'
        '  final pods = [\n'
        '    for (final r in pod.recent)\n'
        '      RecentContentEntry(\n'
        '        type: RecentContentType.podcast,\n'
        '        key: r.episode.guid,\n'
        '        title: r.episode.title,\n'
        '        subtitle: r.show.title,\n'
        '        playedAt: r.at,\n'
        "        podcastData: {'show': r.show.toJson(), 'ep': r.episode.toJson()},\n"
        '      ),\n'
        '  ];\n'
        '  return [...base, ...pods]..sort((a, b) => b.playedAt.compareTo(a.playedAt));\n'
        '}\n')
    print('✔', name(k), '시간순으로 섞는 함수')
else:
    print('✔', name(k), '시간순으로 섞는 함수 (이미 돼 있음)')

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
