# -*- coding: utf-8 -*-
# ×로 닫은 뒤 알림창 '미디어 출력'에 남는 카드의 재생 버튼을 누르면
# 닫았던 걸(곡·라디오·자연소리·믹스) 다시 틀기
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

names = ['player_provider.dart', 'mini_player.dart', 'radio_mini_player.dart',
         'nature_mini_player.dart', 'sound_mix_mini_player.dart']
paths = {}
for n in names:
    p = find_file(n)
    if not p:
        print('❌ lib 폴더에서', n, '을(를) 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
        sys.exit(1)
    paths[n] = p

files = {}
for n, p in paths.items():
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    files[n] = [raw.replace('\r\n', '\n'), '\r\n' in raw]

pp = files['player_provider.dart'][0]
if 'onResumeLast' in pp:
    print('이미 적용돼 있어요')
    sys.exit(0)
if 'void dismissMediaNotification()' not in pp:
    print('❌ 먼저 apply_close_notif.py를 적용해야 해요. 아무것도 저장 안 했어요.')
    sys.exit(1)

ok = True
def rep(n, title, old, new):
    global ok
    src = files[n][0]
    if src.count(old) == 1:
        files[n][0] = src.replace(old, new)
        print('✔', n, '-', title)
    else:
        print('❌', n, '-', title, '— 코드를 못 찾았어요')
        ok = False

P = 'player_provider.dart'
rep(P, '닫았던 걸 다시 트는 함수 넣기',
    "  /// 미니플레이어 ×로 닫을 때: 알림창의 미디어 출력도 없애기\n"
    "  void dismissMediaNotification() {\n"
    "    final h = _audioHandler;\n"
    "    if (h is SimpleAudioHandler) h.dismiss();\n"
    "  }\n",
    "  /// 미니플레이어 ×로 닫을 때: 알림을 끝내고, 알림창 카드의 재생 버튼으로 다시 틀 수 있게\n"
    "  void dismissMediaNotification({Future<void> Function()? resume}) {\n"
    "    final h = _audioHandler;\n"
    "    if (h is SimpleAudioHandler) {\n"
    "      h.dismiss();\n"
    "      h.onResumeLast = resume;\n"
    "    }\n"
    "  }\n"
    "\n"
    "  /// 지금 곡을 나중에 다시 틀기 (닫기 전에 불러 둠)\n"
    "  Future<void> Function()? songResumer() {\n"
    "    final i = _currentIndex;\n"
    "    if (i < 0 || i >= _queue.length) return null;\n"
    "    final q = List<Song>.from(_queue);\n"
    "    return () => playFromList(q, i);\n"
    "  }\n"
    "\n"
    "  /// 지금 자연소리를 나중에 다시 틀기 (닫기 전에 불러 둠)\n"
    "  Future<void> Function()? natureResumer() {\n"
    "    final name = _natureSoundName;\n"
    "    if (name == null) return null;\n"
    "    final i = natureSoundOrder.indexWhere((s) => s['name'] == name);\n"
    "    if (i < 0) return null;\n"
    "    final path = natureSoundOrder[i]['assetPath']!;\n"
    "    return () => playNatureSound(path, name);\n"
    "  }\n")

rep(P, '알림 쪽에 다시 틀 것 기억',
    "  VoidCallback? onNaturePrevious;\n"
    "\n"
    "  SimpleAudioHandler(",
    "  VoidCallback? onNaturePrevious;\n"
    "\n"
    "  /// ×로 닫은 뒤 알림창(미디어 출력) 카드의 재생 버튼: 닫았던 걸 다시 틀기\n"
    "  Future<void> Function()? onResumeLast;\n"
    "\n"
    "  SimpleAudioHandler(")

rep(P, '재생 버튼: 비어 있으면 닫았던 걸 다시 틀기',
    "      if (_player.processingState != ProcessingState.idle) {\n"
    "        _radioMode = false;\n"
    "        await _player.play();\n"
    "      }\n",
    "      if (_player.processingState != ProcessingState.idle) {\n"
    "        _radioMode = false;\n"
    "        await _player.play();\n"
    "      } else if (onResumeLast != null) {\n"
    "        final f = onResumeLast!;\n"
    "        onResumeLast = null;\n"
    "        await f();\n"
    "      }\n")

rep(P, '새로 틀면 기억 지우기 (음악·자연)',
    "  Future<void> updateMediaItem(MediaItem item) async {\n"
    "    mediaItem.add(item);\n",
    "  Future<void> updateMediaItem(MediaItem item) async {\n"
    "    onResumeLast = null;\n"
    "    mediaItem.add(item);\n")

rep(P, '새로 틀면 기억 지우기 (라디오)',
    "    String? url,\n"
    "  }) {\n"
    "    if (_player.processingState == ProcessingState.idle) {\n",
    "    String? url,\n"
    "  }) {\n"
    "    onResumeLast = null;\n"
    "    if (_player.processingState == ProcessingState.idle) {\n")

rep(P, '새로 틀면 기억 지우기 (믹스)',
    "    required String subtitle,\n"
    "  }) {\n"
    "    mediaItem.add(MediaItem(\n"
    "      id: 'sound_mix',\n",
    "    required String subtitle,\n"
    "  }) {\n"
    "    onResumeLast = null;\n"
    "    mediaItem.add(MediaItem(\n"
    "      id: 'sound_mix',\n")

rep('mini_player.dart', '닫은 곡 기억',
    "    await p.player.stop();\n"
    "    p.clearNatureSoundState();\n"
    "    p.clearCurrentSong();\n"
    "    p.dismissMediaNotification();\n",
    "    final resume = p.songResumer();\n"
    "    await p.player.stop();\n"
    "    p.clearNatureSoundState();\n"
    "    p.clearCurrentSong();\n"
    "    p.dismissMediaNotification(resume: resume);\n")

rep('nature_mini_player.dart', '닫은 자연소리 기억',
    "    await p.player.stop();\n"
    "    p.clearNatureSoundState();\n"
    "    p.dismissMediaNotification();\n",
    "    final resume = p.natureResumer();\n"
    "    await p.player.stop();\n"
    "    p.clearNatureSoundState();\n"
    "    p.dismissMediaNotification(resume: resume);\n")

rep('radio_mini_player.dart', '닫은 방송 기억',
    "    await radio.stopRadioAndClear();\n"
    "    pp.dismissMediaNotification();\n",
    "    final st = radio.currentStation;\n"
    "    await radio.stopRadioAndClear();\n"
    "    pp.dismissMediaNotification(resume: st == null ? null : () => radio.playStation(st));\n")

rep('sound_mix_mini_player.dart', '닫은 믹스 기억',
    "    final pp = context.read<PlayerProvider>();\n"
    "    await context.read<SoundMixProvider>().closeSession();\n"
    "    pp.dismissMediaNotification();\n",
    "    final pp = context.read<PlayerProvider>();\n"
    "    final mix = context.read<SoundMixProvider>();\n"
    "    await mix.closeSession();\n"
    "    pp.dismissMediaNotification(resume: () => mix.playAll());\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

for n, p in paths.items():
    src, crlf = files[n]
    shutil.copy(p, p + '.bak')
    if crlf:
        src = src.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(src.encode('utf-8'))
print('저장했어요 (5개 파일)')
