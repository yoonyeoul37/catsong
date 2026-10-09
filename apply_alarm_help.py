# -*- coding: utf-8 -*-
# 아침 알람 2: 설정 도움말에 "알람" 카드 + 권한 허용하고 돌아오면 자동 저장
# - 설정 도움말: "알람이 안 울릴 때" 카드 (설정 열기 → 알람 및 리마인더 화면 바로), 아이폰엔 안 보임
# - 알람 화면: 권한 허용하고 돌아오면 [저장] 다시 안 눌러도 바로 저장
# - 이름 바꾸기: 전체 곡 → "음악 전체 섞어 듣기", 즐겨찾기 → "음악 즐겨찾기 섞어 듣기" (라디오 즐겨찾기와 안 헷갈리게)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HELP = os.path.join(ROOT, 'lib', 'screens', 'settings_help_screen.dart')
ALARM = os.path.join(ROOT, 'lib', 'screens', 'alarm_screen.dart')

HELP_EDITS = [
    ('도움말: 알람 불러오기',
     "import '../providers/theme_provider.dart';\n",
     "import '../providers/theme_provider.dart';\n"
     "import '../services/alarm_service.dart';\n"),
    ('도움말: 알람 카드용 칸',
     "  final String? iosPath; // 직접 찾아갈 때 (아이폰)\n"
     "  const _HelpTopic(this.icon, this.title, this.when, this.android,\n"
     "      {this.ios, this.note, required this.path, this.iosPath});\n",
     "  final String? iosPath; // 직접 찾아갈 때 (아이폰)\n"
     "  final bool exactAlarm; // 설정 열기 → 알람 및 리마인더 화면으로 바로\n"
     "  const _HelpTopic(this.icon, this.title, this.when, this.android,\n"
     "      {this.ios, this.note, required this.path, this.iosPath, this.exactAlarm = false});\n"),
    ('도움말: 알람 카드',
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 배터리 → 제한 없음',\n"
     "  ),\n",
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 배터리 → 제한 없음',\n"
     "  ),\n"
     "  _HelpTopic(\n"
     "    Icons.alarm_rounded,\n"
     "    '아침 알람',\n"
     "    '알람이 안 울리거나 늦게 울릴 때',\n"
     "    ['아래 설정 열기 누르기', '알람 및 리마인더 허용 켜기', '앱으로 돌아오기'],\n"
     "    note: '위 \"화면 꺼도 안 끊기게\"의 배터리 제한 없음도 같이 해두면 더 정확해요',\n"
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 알람 및 리마인더 → 허용',\n"
     "    exactAlarm: true,\n"
     "  ),\n"),
    ('도움말: 알람 카드는 알람 권한 화면으로',
     "                          openAppSettings();\n",
     "                          t.exactAlarm ? AlarmService.openExactSettings() : openAppSettings();\n"),
]

ALARM_EDITS = [
    ('알람: 앱으로 돌아온 걸 알기',
     "class _AlarmScreenState extends State<AlarmScreen> {\n"
     "  late ParanAlarm _a = AlarmService.alarm.value?.copy() ?? ParanAlarm();\n",
     "class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {\n"
     "  late ParanAlarm _a = AlarmService.alarm.value?.copy() ?? ParanAlarm();\n"
     "  bool _waitPerm = false; // 권한 허용하러 설정에 다녀오는 중\n"
     "\n"
     "  @override\n"
     "  void initState() {\n"
     "    super.initState();\n"
     "    WidgetsBinding.instance.addObserver(this);\n"
     "  }\n"
     "\n"
     "  @override\n"
     "  void dispose() {\n"
     "    WidgetsBinding.instance.removeObserver(this);\n"
     "    super.dispose();\n"
     "  }\n"
     "\n"
     "  /// 설정에서 돌아오면: 허용했으면 바로 저장, 안 했으면 짧게 알려주기\n"
     "  @override\n"
     "  void didChangeAppLifecycleState(AppLifecycleState state) async {\n"
     "    if (state != AppLifecycleState.resumed || !_waitPerm) return;\n"
     "    _waitPerm = false;\n"
     "    if (await AlarmService.canExact()) {\n"
     "      if (mounted) _save();\n"
     "    } else if (mounted) {\n"
     "      showParanToast(context, '알람 및 리마인더를 허용해야 울릴 수 있어요');\n"
     "    }\n"
     "  }\n"),
    ('알람: 권한 안내 문구 · 다녀오기 표시',
     "        message: '정해진 시간에 깨우려면 \"알람 및 리마인더\"를 허용해 주세요. 허용한 뒤 다시 저장을 눌러 주세요.',\n"
     "        confirmLabel: '설정 열기',\n"
     "      );\n"
     "      if (go) AlarmService.openExactSettings();\n",
     "        message: '정해진 시간에 깨우려면 \"알람 및 리마인더\"를 허용해 주세요. 허용하고 돌아오면 바로 저장돼요.',\n"
     "        confirmLabel: '설정 열기',\n"
     "      );\n"
     "      if (go) {\n"
     "        _waitPerm = true;\n"
     "        AlarmService.openExactSettings();\n"
     "      }\n"),
    ('알람: 음악 전체 섞어 듣기',
     "      soundRow(Icons.shuffle_rounded, '전체 곡 섞어 듣기', _a.kind == 'music_all',\n"
     "                          () => _pickMusic('music_all', '전체 곡 섞어 듣기')),\n",
     "      soundRow(Icons.shuffle_rounded, '음악 전체 섞어 듣기', _a.kind == 'music_all',\n"
     "                          () => _pickMusic('music_all', '음악 전체 섞어 듣기')),\n"),
    ('알람: 음악 즐겨찾기 섞어 듣기',
     "      soundRow(Icons.favorite_border_rounded, '즐겨찾기 섞어 듣기', _a.kind == 'music_fav',\n"
     "                          () => _pickMusic('music_fav', '즐겨찾기 섞어 듣기')),\n",
     "      soundRow(Icons.favorite_border_rounded, '음악 즐겨찾기 섞어 듣기', _a.kind == 'music_fav',\n"
     "                          () => _pickMusic('music_fav', '음악 즐겨찾기 섞어 듣기')),\n"),
]

MARK = 'exactAlarm'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    for p in (HELP, ALARM):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(HELP, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((HELP, HELP_EDITS), (ALARM, ALARM_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
