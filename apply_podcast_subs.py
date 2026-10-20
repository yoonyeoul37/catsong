# -*- coding: utf-8 -*-
# 팟캐스트 2단계 ① 구독(하트): 회차 목록 화면에 하트 버튼, 팟캐스트 탭에 '구독 중' 줄, 새 회차가 오면 빨간 점
import os, sys

FILES = {
    'core': os.path.join('lib', 'podcast', 'podcast.dart'),
    'ui': os.path.join('lib', 'podcast', 'podcast_screens.dart'),
}


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


D = {}
for k, p in FILES.items():
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8')
    D[k] = {'s': raw.replace('\r\n', '\n'), 'crlf': '\r\n' in raw}
    D[k]['orig'] = D[k]['s']


def rep(k, label, old, new, done):
    s = D[k]['s']
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(label + ' — 찾을 코드를 못 찾았어요')
    D[k]['s'] = s.replace(old, new)
    print('✔', label)


# ── podcast.dart: 구독 목록 · 새 회차 ──
rep('core', '구독 목록 · 새 회차 기능',
    '  int savedMs(String guid) => _pos[guid] ?? 0;\n',
    '  // ── 구독(하트) ──\n'
    '  final Map<String, PodcastShow> subs = {}; // 구독한 팟캐스트 (넣은 순서)\n'
    '  final Map<String, String> _seen = {}; // 팟캐스트별로 마지막에 본 최신 회차\n'
    '  final Set<String> newOnes = {}; // 새 회차가 올라온 구독\n'
    '  bool _checked = false;\n'
    '\n'
    '  bool isSub(String id) => subs.containsKey(id);\n'
    '\n'
    '  void toggleSub(PodcastShow s, {String? latestGuid}) {\n'
    '    if (subs.remove(s.id) == null) {\n'
    '      subs[s.id] = s;\n'
    '      if (latestGuid != null) _seen[s.id] = latestGuid; // 지금 회차까지는 본 걸로\n'
    '    } else {\n'
    '      newOnes.remove(s.id);\n'
    '    }\n'
    '    _persist();\n'
    '    notifyListeners();\n'
    '  }\n'
    '\n'
    '  /// 회차 목록을 열면: 새 회차 표시 지우기 + 구독 정보(그림·주소) 새로\n'
    '  void markSeen(PodcastShow s, List<PodcastEpisode> eps) {\n'
    '    if (eps.isEmpty) return;\n'
    '    _seen[s.id] = eps.first.guid;\n'
    '    if (subs.containsKey(s.id)) subs[s.id] = s;\n'
    '    newOnes.remove(s.id);\n'
    '    _persist();\n'
    '    notifyListeners();\n'
    '  }\n'
    '\n'
    '  /// 구독한 팟캐스트에 새 회차가 왔는지 (앱 켜고 팟캐스트 탭을 처음 열 때 한 번)\n'
    '  Future<void> checkNewOnce() async {\n'
    '    if (_checked) return;\n'
    '    _checked = true;\n'
    '    for (final s in subs.values.toList()) {\n'
    '      if (s.feedUrl.isEmpty) continue;\n'
    '      try {\n'
    '        final eps = await PodcastApi.episodes(s, refresh: true);\n'
    '        if (eps.isEmpty) continue;\n'
    '        final seen = _seen[s.id];\n'
    '        if (seen == null) {\n'
    '          _seen[s.id] = eps.first.guid;\n'
    '        } else if (seen != eps.first.guid) {\n'
    '          newOnes.add(s.id);\n'
    '        }\n'
    '      } catch (_) {}\n'
    '    }\n'
    '    _persist();\n'
    '    notifyListeners();\n'
    '  }\n'
    '\n'
    '  int savedMs(String guid) => _pos[guid] ?? 0;\n',
    done='bool isSub(String id)')
rep('core', '구독 불러오기',
    "      speed = sp.getDouble('pod_speed') ?? 1.0;\n",
    "      speed = sp.getDouble('pod_speed') ?? 1.0;\n"
    "      final subsRaw = sp.getString('pod_subs');\n"
    '      if (subsRaw != null) {\n'
    '        for (final j in (jsonDecode(subsRaw) as List)) {\n'
    '          final s = PodcastShow.fromJson(Map<String, dynamic>.from(j));\n'
    '          if (s.id.isNotEmpty) subs[s.id] = s;\n'
    '        }\n'
    '      }\n'
    "      final seenRaw = sp.getString('pod_seen');\n"
    '      if (seenRaw != null) {\n'
    '        (jsonDecode(seenRaw) as Map).forEach((k, v) => _seen[\'$k\'] = \'$v\');\n'
    '      }\n',
    done="sp.getString('pod_subs')")
rep('core', '구독 저장하기',
    "      await sp.setDouble('pod_speed', speed);\n",
    "      await sp.setDouble('pod_speed', speed);\n"
    "      await sp.setString('pod_subs', jsonEncode([for (final s in subs.values) s.toJson()]));\n"
    "      await sp.setString('pod_seen', jsonEncode(_seen));\n",
    done="sp.setString('pod_subs'")

# ── podcast_screens.dart ──
rep('ui', 'import', "import '../providers/radio_provider.dart';\n",
    "import '../providers/radio_provider.dart';\nimport '../widgets/heart_pop.dart';\n",
    done="import '../widgets/heart_pop.dart';")
rep('ui', '탭 열면 새 회차 확인',
    '  void initState() {\n    super.initState();\n    _loadChart();\n  }\n',
    '  void initState() {\n    super.initState();\n    _loadChart();\n    PodcastPlayer.instance.checkNewOnce(); // 구독한 팟캐스트 새 회차\n  }\n',
    done='PodcastPlayer.instance.checkNewOnce();')
rep('ui', "탭에 '구독 중' 줄",
    '            if (cont != null && !searching) ...[\n'
    '              _continueCard(cont.$1, cont.$2, pod, dark),\n'
    '              const SizedBox(height: 22),\n'
    '            ],\n',
    '            if (cont != null && !searching) ...[\n'
    '              _continueCard(cont.$1, cont.$2, pod, dark),\n'
    '              const SizedBox(height: 22),\n'
    '            ],\n'
    '            if (pod.subs.isNotEmpty && !searching) ...[\n'
    '              _subsRow(pod, dark),\n'
    '              const SizedBox(height: 22),\n'
    '            ],\n',
    done='_subsRow(pod, dark),')
rep('ui', "'구독 중' 줄 모양",
    '  Widget _roundButton(IconData icon, bool dark, VoidCallback onTap) => GestureDetector(\n',
    "  // '구독 중': 동그란 모서리 그림이 옆으로 줄 서고, 새 회차가 있으면 빨간 점\n"
    '  Widget _subsRow(PodcastPlayer pod, bool dark) {\n'
    '    final list = pod.subs.values.toList().reversed.toList(); // 최근에 구독한 것부터\n'
    '    return Column(\n'
    '      crossAxisAlignment: CrossAxisAlignment.start,\n'
    '      children: [\n'
    '        Row(\n'
    '          children: [\n'
    "            Text(podText('구독 중', 'Subscribed'),\n"
    '                style: TextStyle(color: _text(dark), fontSize: 15, fontWeight: FontWeight.w700)),\n'
    '            const SizedBox(width: 6),\n'
    "            Text('${list.length}', style: TextStyle(color: _sub(dark), fontSize: 13, fontWeight: FontWeight.w600)),\n"
    '          ],\n'
    '        ),\n'
    '        const SizedBox(height: 10),\n'
    '        SizedBox(\n'
    '          height: 100,\n'
    '          child: ListView.separated(\n'
    '            scrollDirection: Axis.horizontal,\n'
    '            itemCount: list.length,\n'
    '            separatorBuilder: (_, __) => const SizedBox(width: 12),\n'
    '            itemBuilder: (_, i) {\n'
    '              final s = list[i];\n'
    '              final isNew = pod.newOnes.contains(s.id);\n'
    '              return GestureDetector(\n'
    '                onTap: () => _openShow(s),\n'
    '                child: SizedBox(\n'
    '                  width: 72,\n'
    '                  child: Column(\n'
    '                    children: [\n'
    '                      Stack(\n'
    '                        clipBehavior: Clip.none,\n'
    '                        children: [\n'
    '                          PodcastArt(url: s.art, title: s.title, size: 72, radius: 14),\n'
    '                          if (isNew)\n'
    '                            Positioned(\n'
    '                              top: -3,\n'
    '                              right: -3,\n'
    '                              child: Container(\n'
    '                                width: 12,\n'
    '                                height: 12,\n'
    '                                decoration: BoxDecoration(\n'
    '                                  color: const Color(0xFFD84A3A),\n'
    '                                  shape: BoxShape.circle,\n'
    '                                  border: Border.all(color: _bg(dark), width: 2),\n'
    '                                ),\n'
    '                              ),\n'
    '                            ),\n'
    '                        ],\n'
    '                      ),\n'
    '                      const SizedBox(height: 6),\n'
    '                      Text(s.title,\n'
    '                          maxLines: 1,\n'
    '                          overflow: TextOverflow.ellipsis,\n'
    '                          textAlign: TextAlign.center,\n'
    '                          style: TextStyle(\n'
    '                              color: isNew ? _text(dark) : _sub(dark),\n'
    '                              fontSize: 11.5,\n'
    '                              fontWeight: isNew ? FontWeight.w700 : FontWeight.w500)),\n'
    '                    ],\n'
    '                  ),\n'
    '                ),\n'
    '              );\n'
    '            },\n'
    '          ),\n'
    '        ),\n'
    '      ],\n'
    '    );\n'
    '  }\n'
    '\n'
    '  Widget _roundButton(IconData icon, bool dark, VoidCallback onTap) => GestureDetector(\n',
    done='Widget _subsRow(PodcastPlayer pod, bool dark)')
rep('ui', '회차 목록: 최신 회차 기억 값',
    '  bool _descOpen = false;\n\n  Future<List<PodcastEpisode>> _load() async {\n',
    '  bool _descOpen = false;\n  String? _latestGuid; // 하트 누를 때: 지금 회차까지는 본 걸로\n\n  Future<List<PodcastEpisode>> _load() async {\n',
    done='String? _latestGuid;')
rep('ui', '회차 목록 열면 새 회차 표시 지우기',
    '    if (info != null && mounted) setState(() => _show = info.copyWith(feedUrl: _show.feedUrl));\n    return eps;\n',
    '    if (info != null && mounted) setState(() => _show = info.copyWith(feedUrl: _show.feedUrl));\n'
    '    _latestGuid = eps.isNotEmpty ? eps.first.guid : null;\n'
    '    PodcastPlayer.instance.markSeen(_show, eps);\n'
    '    return eps;\n',
    done='PodcastPlayer.instance.markSeen(_show, eps);')
rep('ui', '최신 회차 듣기 옆 하트 (시작)',
    '              if (eps.isNotEmpty)\n                SizedBox(\n                  height: 46,\n                  child: ElevatedButton.icon(\n',
    '              if (eps.isNotEmpty)\n                Row(\n                  children: [\n                Expanded(\n                child: SizedBox(\n                  height: 46,\n                  child: ElevatedButton.icon(\n',
    done='                Expanded(\n                child: SizedBox(\n                  height: 46,')
rep('ui', '최신 회차 듣기 옆 하트 (끝)',
    '                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n'
    '                    ),\n'
    '                  ),\n'
    '                ),\n'
    '              if (eps.isNotEmpty && eps.first.desc.isNotEmpty) ...[\n',
    '                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n'
    '                    ),\n'
    '                  ),\n'
    '                ),\n'
    '                ),\n'
    '                    const SizedBox(width: 10),\n'
    '                    _heartButton(pod, dark), // 구독\n'
    '                  ],\n'
    '                ),\n'
    '              if (eps.isNotEmpty && eps.first.desc.isNotEmpty) ...[\n',
    done='_heartButton(pod, dark), // 구독')
rep('ui', '하트 버튼 모양',
    '  Widget _episodeRow(PodcastEpisode e, PodcastPlayer pod, bool dark) {\n',
    '  // 구독 하트: 최신 회차 듣기 버튼과 같은 높이의 둥근 네모\n'
    '  Widget _heartButton(PodcastPlayer pod, bool dark) {\n'
    '    final on = pod.isSub(_show.id);\n'
    '    return GestureDetector(\n'
    '      onTap: () {\n'
    '        _buzz();\n'
    '        pod.toggleSub(_show, latestGuid: _latestGuid);\n'
    '      },\n'
    '      child: Container(\n'
    '        width: 46,\n'
    '        height: 46,\n'
    '        decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(14)),\n'
    '        child: HeartPop(\n'
    '          on: on,\n'
    '          child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,\n'
    '              size: 22, color: on ? const Color(0xFFE05A4F) : _text(dark)),\n'
    '        ),\n'
    '      ),\n'
    '    );\n'
    '  }\n'
    '\n'
    '  Widget _episodeRow(PodcastEpisode e, PodcastPlayer pod, bool dark) {\n',
    done='Widget _heartButton(PodcastPlayer pod, bool dark)')

for k in D:
    s = D[k]['s']
    if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
        fail(os.path.basename(FILES[k]) + ' 괄호가 안 맞아요')
changed = [k for k in D if D[k]['s'] != D[k]['orig']]
if not changed:
    print('이미 적용돼 있어요')
    sys.exit(0)
for k in changed:
    s = D[k]['s']
    if D[k]['crlf']:
        s = s.replace('\n', '\r\n')
    open(FILES[k], 'wb').write(s.encode('utf-8'))
print('저장했어요:', ', '.join(os.path.basename(FILES[k]) for k in changed))
