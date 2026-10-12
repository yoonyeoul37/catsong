# -*- coding: utf-8 -*-
# 미니플레이어 ×로 닫으면 알림창 미디어 출력도 없애기 (음악·라디오·자연소리·믹스)
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

names = ['player_provider.dart', 'mini_player.dart', 'radio_mini_player.dart',
         'nature_mini_player.dart', 'sound_mix_mini_player.dart', 'main.dart']
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

if 'void dismissMediaNotification()' in files['player_provider.dart'][0]:
    print('이미 적용돼 있어요')
    sys.exit(0)

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

# player_provider.dart
rep('player_provider.dart', '알림 지우기 함수 (provider)',
    "  void setAudioHandler(AudioHandler handler) {\n"
    "    _audioHandler = handler;\n"
    "  }\n",
    "  void setAudioHandler(AudioHandler handler) {\n"
    "    _audioHandler = handler;\n"
    "  }\n"
    "\n"
    "  /// 미니플레이어 ×로 닫을 때: 알림창의 미디어 출력도 없애기\n"
    "  void dismissMediaNotification() {\n"
    "    final h = _audioHandler;\n"
    "    if (h is SimpleAudioHandler) h.dismiss();\n"
    "  }\n")

rep('player_provider.dart', '알림 지우기 함수 (handler)',
    "  Future<void> updateMediaItem(MediaItem item) async {\n",
    "  /// 완전히 끝: '정지(idle)'로 알려야 알림창 미디어 출력이 사라짐\n"
    "  /// (그냥 멈추면 '일시정지'로 남아서, 눌러도 안 되는 알림이 남았음)\n"
    "  void dismiss() {\n"
    "    _radioMode = false;\n"
    "    _mixMode = false;\n"
    "    _natureMode = false;\n"
    "    if (playbackState.value.processingState != AudioProcessingState.idle) {\n"
    "      playbackState.add(playbackState.value.copyWith(\n"
    "        processingState: AudioProcessingState.idle,\n"
    "        playing: false,\n"
    "      ));\n"
    "    }\n"
    "  }\n"
    "\n"
    "  Future<void> updateMediaItem(MediaItem item) async {\n")

# mini_player.dart (음악)
rep('mini_player.dart', '× 누르면 알림도 지우기',
    "    p.clearNatureSoundState();\n"
    "    p.clearCurrentSong();\n",
    "    p.clearNatureSoundState();\n"
    "    p.clearCurrentSong();\n"
    "    p.dismissMediaNotification();\n")

# nature_mini_player.dart (자연소리)
rep('nature_mini_player.dart', '× 누르면 알림도 지우기',
    "    await p.player.stop();\n"
    "    p.clearNatureSoundState();\n"
    "  }\n",
    "    await p.player.stop();\n"
    "    p.clearNatureSoundState();\n"
    "    p.dismissMediaNotification();\n"
    "  }\n")

# radio_mini_player.dart (라디오)
rep('radio_mini_player.dart', 'player_provider 가져오기',
    "import '../providers/radio_provider.dart';\n",
    "import '../providers/radio_provider.dart';\n"
    "import '../providers/player_provider.dart';\n")
rep('radio_mini_player.dart', '× 누르면 알림도 지우기',
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "    if (CastService.instance.isConnected) await CastService.instance.disconnect();\n"
    "    await context.read<RadioProvider>().stopRadioAndClear();\n",
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "    final pp = context.read<PlayerProvider>();\n"
    "    final radio = context.read<RadioProvider>();\n"
    "    if (CastService.instance.isConnected) await CastService.instance.disconnect();\n"
    "    await radio.stopRadioAndClear();\n"
    "    pp.dismissMediaNotification();\n")

# sound_mix_mini_player.dart (믹스)
rep('sound_mix_mini_player.dart', 'player_provider 가져오기',
    "import '../providers/sound_mix_provider.dart';\n",
    "import '../providers/sound_mix_provider.dart';\n"
    "import '../providers/player_provider.dart';\n")
rep('sound_mix_mini_player.dart', '× 누르면 알림도 지우기',
    "    await context.read<SoundMixProvider>().closeSession();\n",
    "    final pp = context.read<PlayerProvider>();\n"
    "    await context.read<SoundMixProvider>().closeSession();\n"
    "    pp.dismissMediaNotification();\n")

# main.dart: 알림이 끝날 때 '떼어두기' 말고 '지우기'로
rep('main.dart', '끝나면 알림 지우기 설정',
    "      androidNotificationClickStartsActivity: true,\n",
    "      androidNotificationClickStartsActivity: true,\n"
    "      androidResumeOnClick: false, // 끝나면 알림을 남기지 않고 지움\n")

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
print('저장했어요 (6개 파일)')
