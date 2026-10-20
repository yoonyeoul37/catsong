# -*- coding: utf-8 -*-
# 팟캐스트: 한 회차를 다 들으면 같은 팟캐스트의 바로 이전(더 오래된) 회차 중 아직 안 들은 것으로 이어서 재생
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast.dart')


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


if not os.path.exists(PATH):
    fail('파일이 없어요: ' + PATH)
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s


def rep(label, old, new, done):
    global s
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(label + ' — 찾을 코드를 못 찾았어요')
    s = s.replace(old, new)
    print('✔', label)


rep('받아 둔 회차 목록 꺼내기', '  static PodcastShow? showInfo(String id) => _shows[id];\n',
    '  static PodcastShow? showInfo(String id) => _shows[id];\n'
    '  static List<PodcastEpisode>? cached(String feedUrl) => _episodes[feedUrl];\n',
    done='static List<PodcastEpisode>? cached(')
rep('다 들으면 이어서',
    '        pp.player.pause();\n        _persist();\n        notifyListeners();\n      }\n',
    '        pp.player.pause();\n        _persist();\n        notifyListeners();\n'
    '        _playNextOlder(); // 같은 팟캐스트에서 아직 안 들은 바로 이전 회차로\n      }\n',
    done='_playNextOlder(); //')
rep('이어 들을 회차 고르기', '  /// 음악·자연소리를 틀면 팟캐스트는 비켜 줌\n',
    '  /// 다 들으면: 같은 팟캐스트에서 바로 이전(더 오래된) 회차 중 아직 안 들은 것으로 이어서\n'
    '  Future<void> _playNextOlder() async {\n'
    '    final s = show, e = episode;\n'
    '    if (s == null || e == null) return;\n'
    '    var eps = PodcastApi.cached(s.feedUrl);\n'
    '    if (eps == null) {\n'
    '      try {\n'
    '        eps = await PodcastApi.episodes(s);\n'
    '      } catch (_) {\n'
    '        return;\n'
    '      }\n'
    '    }\n'
    '    final i = eps.indexWhere((x) => x.guid == e.guid);\n'
    '    if (i < 0) return;\n'
    '    for (var j = i + 1; j < eps.length; j++) {\n'
    '      if (!_done.contains(eps[j].guid)) {\n'
    '        await play(s, eps[j]);\n'
    '        return;\n'
    '      }\n'
    '    }\n'
    '  }\n'
    '\n'
    '  /// 음악·자연소리를 틀면 팟캐스트는 비켜 줌\n',
    done='Future<void> _playNextOlder()')

if s.count('(') != s.count(')') or s.count('{') != s.count('}'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
