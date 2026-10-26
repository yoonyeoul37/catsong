# -*- coding: utf-8 -*-
# 다른 앱에서 연 노래도 다음·이전 되게 (내 음악 목록 순서대로 이어서)
import os, sys
P = None
for r, _, fs in os.walk('lib'):
    if 'open_audio.dart' in fs: P = os.path.join(r, 'open_audio.dart')
if not P:
    print('❌ open_audio.dart 를 못 찾았어요 (apply_open_with.py 먼저)'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
NL = '\r\n' if '\r\n' in s else '\n'
if 'HeadsetResume.screenOrder' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
steps = [
 ('목록 순서 불러오기',
  "import 'alarm_service.dart';\n",
  "import 'alarm_service.dart';\n"
  "import 'headset_resume.dart';\n"),
 ('다음·이전: 내 음악 목록 순서대로',
  "      if (song == null || uri != target.value) return;\n"
  "      await pp.playFromList([song], 0);\n",
  "      if (song == null || uri != target.value) return;\n"
  "      final picked = song;\n"
  "      // 다음·이전: 내 음악 목록 순서대로 (목록에 있는 곡은 그 자리부터 · 없는 곡은 맨 앞에 두고 목록 처음부터 이어서)\n"
  "      if (music.allSongs.isEmpty) {\n"
  "        if (!music.isLoading) music.initialize();\n"
  "        for (var k = 0; k < 20 && music.allSongs.isEmpty; k++) {\n"
  "          await Future.delayed(const Duration(milliseconds: 250)); // 5초까지\n"
  "        }\n"
  "      }\n"
  "      var list = <Song>[picked];\n"
  "      var start = 0;\n"
  "      try {\n"
  "        final order = (await HeadsetResume.screenOrder(music.allSongs)).where((x) => x.uri != null).toList();\n"
  "        final i = order.indexWhere((x) => identical(x, picked) || x.uri == picked.uri);\n"
  "        if (i >= 0) {\n"
  "          list = order;\n"
  "          start = i;\n"
  "        } else {\n"
  "          list = [picked, ...order];\n"
  "        }\n"
  "      } catch (_) {}\n"
  "      if (uri != target.value) return; // 그사이 다른 노래를 열었으면 그만\n"
  "      await pp.playFromList(list, start);\n"),

 ('곡 번호로 찾지 않고 파일 경로로만 찾기 (번호가 겹쳐 다른 곡이 나올 수 있어서)',
  "          if ((libId != null && s.id == libId) || (libPath != null && s.uri == libPath)) {\n",
  "          if (libPath != null && s.uri == libPath) {\n"),
]
ok = True
for name, old, new in steps:
    o = old.replace('\n', NL); n = new.replace('\n', NL)
    c = s.count(o)
    if c == 1:
        s = s.replace(o, n); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % c)
if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요:', P)
