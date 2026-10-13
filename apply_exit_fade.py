# -*- coding: utf-8 -*-
# 종료(끝인사) 때 음악·라디오 소리를 천천히 작게 — 홈 화면과 라디오 재생 화면 둘 다
import os, re, sys, shutil

def find(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

FADE = """    // 끝인사 동안 음악·라디오 소리를 1.5초에 걸쳐 천천히 작게 (목소리가 잘 들리게)
    final fadePlayer = context.read<PlayerProvider>().player;
    final fadeRadio = context.read<RadioProvider>();
    final fadeStart = DateTime.now();
    Timer.periodic(const Duration(milliseconds: 50), (t) {
      final p = (DateTime.now().difference(fadeStart).inMilliseconds / 1500).clamp(0.0, 1.0);
      final v = 1 - 0.88 * Curves.easeOut.transform(p);
      fadePlayer.setVolume(v);
      fadeRadio.setAlarmVolume(v);
      if (p >= 1) t.cancel();
    });
"""
MARK = 'fadeRadio.setAlarmVolume'

jobs = []

# ── 홈 화면 ──
p = find('home_screen.dart')
if not p:
    print('❌ home_screen.dart 를 못 찾았어요'); sys.exit(1)
src, crlf = load(p)
if MARK in src:
    print('home_screen.dart: 이미 적용돼 있어요')
else:
    old1 = "    context.read<PlayerProvider>().player.setVolume(0.12);\n"
    old2 = "        await context.read<RadioProvider>().stopRadio();\n"
    new2 = old2 + "        await context.read<RadioProvider>().setAlarmVolume(1.0); // 다음에 켤 때는 원래 크기\n"
    ok = True
    for label, o in [('홈 - 소리 천천히 줄이기', old1), ('홈 - 라디오 끈 뒤 원래 크기로', old2)]:
        if src.count(o) != 1:
            print('❌ %s (찾은 개수 %d)' % (label, src.count(o))); ok = False
        else:
            print('✔ %s' % label)
    if not ok:
        print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
    src = src.replace(old1, FADE).replace(old2, new2)
    jobs.append((p, src, crlf))

# ── 라디오 재생 화면 ──
p = find('radio_player_screen.dart')
if not p:
    print('❌ radio_player_screen.dart 를 못 찾았어요'); sys.exit(1)
src, crlf = load(p)
if MARK in src:
    print('radio_player_screen.dart: 이미 적용돼 있어요')
else:
    # 앞에서 넣은 줄이기 코드(어느 버전이든)를 통째로 새 코드로
    pat = re.compile(r"    // 끝인사 동안 라디오 소리를 천천히 작게[^\n]*\n.*?\n    \}\);\n", re.S)
    m = pat.findall(src)
    if len(m) != 1:
        print('❌ 라디오 화면 - 예전 줄이기 코드 (찾은 개수 %d)' % len(m))
        print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
    src = pat.sub(lambda _: FADE, src)
    src = src.replace("      await radio.stopRadio();", "      await fadeRadio.stopRadio();")
    src = src.replace("      await radio.setAlarmVolume(1.0);", "      await fadeRadio.setAlarmVolume(1.0);")
    imp_old = "import '../providers/player_provider.dart' show SimpleAudioHandler;"
    if imp_old in src:
        src = src.replace(imp_old, "import '../providers/player_provider.dart' show SimpleAudioHandler, PlayerProvider;")
    elif "providers/player_provider.dart';" not in src:
        print('❌ 라디오 화면 - player_provider 불러오는 줄'); sys.exit(1)
    if 'await fadeRadio.stopRadio();' not in src:
        print('❌ 라디오 화면 - 라디오 끄는 줄'); sys.exit(1)
    print('✔ 라디오 화면 - 소리 천천히 줄이기 (홈과 같게)')
    jobs.append((p, src, crlf))

for p, src, crlf in jobs:
    shutil.copyfile(p, p + '.bak')
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
    print('저장했어요: %s (원본은 .bak)' % p)
