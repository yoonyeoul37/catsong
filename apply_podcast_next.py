# -*- coding: utf-8 -*-
# 1. 다 들으면 다음 회차로 이어 듣기: 같은 팟캐스트에서 아직 안 들은 바로 이전(더 오래된) 회차
#    (수면 타이머가 켜져 있으면 타이머 시간까지 계속 이어서)
# 4. 미니플레이어에 수면 타이머 표시: 켜져 있으면 아래 줄 앞에 작은 달 + 남은 분
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


# ── 1. 다음 회차로 이어 듣기 ──
k = 'pod'
rep(k, '다 들으면 다음 회차로',
    '        _done.add(g);\n'
    '        _pos.remove(g);\n'
    '        pp.player.pause();\n'
    '        _persist();\n'
    '        notifyListeners();\n'
    '      }\n'
    '    });\n'
    '    _load();\n'
    '  }\n',
    '        _done.add(g);\n'
    '        _pos.remove(g);\n'
    '        pp.player.pause();\n'
    '        _persist();\n'
    '        notifyListeners();\n'
    '        _playNextOlder(); // 같은 팟캐스트에서 아직 안 들은 바로 이전 회차로\n'
    '      }\n'
    '    });\n'
    '    _load();\n'
    '  }\n'
    '\n'
    '  /// 다 들으면: 같은 팟캐스트에서 바로 이전(더 오래된) 회차 중 아직 안 들은 것으로 이어서\n'
    '  Future<void> _playNextOlder() async {\n'
    '    final s = show, e = episode;\n'
    '    if (s == null || e == null || s.feedUrl.isEmpty) return;\n'
    '    var eps = PodcastApi._episodes[s.feedUrl] ?? await PodcastApi.savedEpisodes(s);\n'
    '    if (eps == null) {\n'
    '      try {\n'
    '        eps = await PodcastApi.episodes(s);\n'
    '      } catch (_) {\n'
    '        return; // 인터넷이 안 되면 그냥 멈춘 채로\n'
    '      }\n'
    '    }\n'
    '    // 기다리는 동안 다른 걸 틀었으면 그만\n'
    '    if (!active || episode?.guid != e.guid) return;\n'
    '    final i = eps.indexWhere((x) => x.guid == e.guid);\n'
    '    if (i < 0) return;\n'
    '    for (var j = i + 1; j < eps.length; j++) {\n'
    '      if (!_done.contains(eps[j].guid)) {\n'
    '        await play(s, eps[j]);\n'
    '        return;\n'
    '      }\n'
    '    }\n'
    '  }\n',
    done='Future<void> _playNextOlder() async {')

# ── 4. 미니플레이어: 수면 타이머 표시 ──
k = 'screens'
rep(k, '미니플레이어에 작은 달 + 남은 분',
    '                              const SizedBox(height: 2),\n'
    '                              Text(\n'
    "                                  dur.inSeconds > 0 ? '${s.title} · ${podClock(pos)} / ${podClock(dur)}' : s.title,\n"
    '                                  maxLines: 1,\n'
    '                                  overflow: TextOverflow.ellipsis,\n'
    '                                  style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11)),\n',
    '                              const SizedBox(height: 2),\n'
    '                              Row(\n'
    '                                children: [\n'
    '                                  // 수면 타이머가 켜져 있으면: 작은 달 + 남은 분\n'
    '                                  if (pod.isSleepTimerActive && pod.sleepRemaining != null) ...[\n'
    '                                    Icon(Icons.bedtime_outlined, size: 11, color: fg.withOpacity(0.75)),\n'
    '                                    const SizedBox(width: 3),\n'
    '                                    Text(tr.durM(pod.sleepRemaining!.inMinutes + 1),\n'
    '                                        style: TextStyle(color: fg.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w600)),\n'
    "                                    Text('  ·  ', style: TextStyle(color: fg.withOpacity(0.4), fontSize: 11)),\n"
    '                                  ],\n'
    '                                  Expanded(\n'
    '                                    child: Text(\n'
    "                                        dur.inSeconds > 0 ? '${s.title} · ${podClock(pos)} / ${podClock(dur)}' : s.title,\n"
    '                                        maxLines: 1,\n'
    '                                        overflow: TextOverflow.ellipsis,\n'
    '                                        style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11)),\n'
    '                                  ),\n'
    '                                ],\n'
    '                              ),\n',
    done='// 수면 타이머가 켜져 있으면: 작은 달 + 남은 분')

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
