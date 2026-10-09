# -*- coding: utf-8 -*-
# 9번: 동영상 권한 화면 새 디자인 + 설정 도움말 화면(새 파일) + ⋮ 메뉴 "설정 도움말"(안 열어본 사람에게 작은 점) + 설정 > 기타에도
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
VIDEO = os.path.join(ROOT, 'lib', 'screens', 'video_screen.dart')
MENU = os.path.join(ROOT, 'lib', 'widgets', 'more_menu_sheet.dart')
SET = os.path.join(ROOT, 'lib', 'screens', 'settings_screen.dart')
HELP = os.path.join(ROOT, 'lib', 'screens', 'settings_help_screen.dart')

HELP_CODE = 'import \'dart:io\' show Platform;\nimport \'package:flutter/material.dart\';\nimport \'package:flutter/services.dart\';\nimport \'package:provider/provider.dart\';\nimport \'package:permission_handler/permission_handler.dart\';\nimport \'package:shared_preferences/shared_preferences.dart\';\nimport \'../providers/theme_provider.dart\';\n\n/// 설정 도움말을 한 번이라도 열어봤는지 (⋮ 메뉴의 작은 점 표시용)\nclass HelpSeen {\n  static final seen = ValueNotifier<bool>(true);\n  static bool _loaded = false;\n\n  static Future<void> load() async {\n    if (_loaded) return;\n    _loaded = true;\n    final p = await SharedPreferences.getInstance();\n    seen.value = p.getBool(\'helpSeen\') ?? false;\n  }\n\n  static Future<void> mark() async {\n    seen.value = true;\n    final p = await SharedPreferences.getInstance();\n    await p.setBool(\'helpSeen\', true);\n  }\n}\n\n/// 도움말 한 칸 (안드로이드 / 아이폰 순서가 다를 수 있음)\nclass _HelpTopic {\n  final IconData icon;\n  final String title;\n  final String when; // 이럴 때 보세요\n  final List<String> android;\n  final List<String>? ios; // null이면 아이폰에선 안 보임 (필요 없는 설정)\n  final String? note;\n  const _HelpTopic(this.icon, this.title, this.when, this.android, {this.ios, this.note});\n}\n\nconst _topics = <_HelpTopic>[\n  _HelpTopic(\n    Icons.perm_media_outlined,\n    \'음악·동영상 불러오기\',\n    \'곡이나 동영상 목록이 안 나올 때\',\n    [\'아래 설정 열기 누르기\', \'권한 → 음악 및 오디오 / 사진 및 동영상\', \'허용 고르고 돌아오기\'],\n    ios: [\'아래 설정 열기 누르기\', \'미디어 및 Apple Music · 사진 켜기\', \'앱으로 돌아오기\'],\n    note: \'돌아오면 바로 목록이 나와요\',\n  ),\n  _HelpTopic(\n    Icons.battery_charging_full_rounded,\n    \'화면 꺼도 안 끊기게\',\n    \'화면을 끄면 음악·라디오가 멈출 때\',\n    [\'아래 설정 열기 누르기\', \'배터리 누르기\', \'제한 없음 고르기\'],\n    note: \'폰마다 "최적화 안 함"이라고 나올 수도 있어요\',\n  ),\n  _HelpTopic(\n    Icons.notifications_none_rounded,\n    \'잠금화면 재생 버튼\',\n    \'잠금화면·알림창에 재생 버튼이 안 보일 때\',\n    [\'아래 설정 열기 누르기\', \'알림 누르기\', \'알림 허용 켜기\'],\n    ios: [\'아래 설정 열기 누르기\', \'알림 누르기\', \'알림 허용 켜기\'],\n  ),\n  _HelpTopic(\n    Icons.music_note_outlined,\n    \'벨소리로 지정\',\n    \'벨소리·알림음 지정이 안 될 때\',\n    [\'아래 설정 열기 누르기\', \'시스템 설정 변경(설정 변경) 누르기\', \'허용 켜기\'],\n  ),\n];\n\nclass SettingsHelpScreen extends StatefulWidget {\n  const SettingsHelpScreen({super.key});\n\n  @override\n  State<SettingsHelpScreen> createState() => _SettingsHelpScreenState();\n}\n\nclass _SettingsHelpScreenState extends State<SettingsHelpScreen> {\n  @override\n  void initState() {\n    super.initState();\n    HelpSeen.mark(); // 한 번 열면 ⋮ 메뉴의 점이 사라짐\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final d = context.watch<ThemeProvider>().isDarkMode;\n    final bg = d ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);\n    final card = d ? const Color(0xFF26221C) : Colors.white;\n    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final sub = d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);\n    final hint = d ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n    final iconBg = d ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5);\n    final line = d ? const Color(0xFF3A342B) : const Color(0xFFEEE9DF);\n    final isIos = Platform.isIOS;\n    final topics = _topics.where((t) => !isIos || t.ios != null).toList();\n\n    return Scaffold(\n      backgroundColor: bg,\n      appBar: AppBar(\n        backgroundColor: bg,\n        elevation: 0,\n        title: Text(\'설정 도움말\',\n            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),\n        leading: IconButton(\n          onPressed: () => Navigator.pop(context),\n          icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),\n        ),\n        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),\n      ),\n      body: SafeArea(\n        top: false,\n        child: ListView(\n          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),\n          children: [\n            Padding(\n              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),\n              child: Text(\'안 될 때 아래 순서대로 한 번만 해주세요\',\n                  style: TextStyle(color: hint, fontSize: 12.5)),\n            ),\n            for (final t in topics) ...[\n              Container(\n                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),\n                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    // 제목 줄: 아이콘 · 제목 / 이럴 때\n                    Row(\n                      children: [\n                        Container(\n                          width: 30,\n                          height: 30,\n                          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),\n                          child: Icon(t.icon, size: 17, color: sub),\n                        ),\n                        const SizedBox(width: 12),\n                        Expanded(\n                          child: Column(\n                            crossAxisAlignment: CrossAxisAlignment.start,\n                            children: [\n                              Text(t.title,\n                                  style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),\n                              const SizedBox(height: 2),\n                              Text(t.when, style: TextStyle(color: hint, fontSize: 12)),\n                            ],\n                          ),\n                        ),\n                      ],\n                    ),\n                    const SizedBox(height: 12),\n                    // 1 · 2 · 3 순서\n                    for (var i = 0; i < (isIos ? t.ios! : t.android).length; i++)\n                      Padding(\n                        padding: const EdgeInsets.only(bottom: 8),\n                        child: Row(\n                          children: [\n                            const SizedBox(width: 3),\n                            Container(\n                              width: 22,\n                              height: 22,\n                              alignment: Alignment.center,\n                              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),\n                              child: Text(\'${i + 1}\',\n                                  style: TextStyle(color: bg, fontSize: 11.5, fontWeight: FontWeight.w700)),\n                            ),\n                            const SizedBox(width: 12),\n                            Expanded(\n                              child: Text((isIos ? t.ios! : t.android)[i],\n                                  style: TextStyle(color: sub, fontSize: 13)),\n                            ),\n                          ],\n                        ),\n                      ),\n                    if (t.note != null)\n                      Padding(\n                        padding: const EdgeInsets.only(left: 37, bottom: 4),\n                        child: Text(t.note!, style: TextStyle(color: hint, fontSize: 11.5)),\n                      ),\n                    const SizedBox(height: 6),\n                    // 먹색 버튼: 이 앱 설정 화면 바로 열기\n                    SizedBox(\n                      width: double.infinity,\n                      height: 40,\n                      child: ElevatedButton(\n                        onPressed: () {\n                          const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n                          openAppSettings();\n                        },\n                        style: ElevatedButton.styleFrom(\n                          backgroundColor: ink,\n                          foregroundColor: bg,\n                          elevation: 0,\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n                        ),\n                        child: const Text(\'설정 열기\', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n              const SizedBox(height: 10),\n            ],\n          ],\n        ),\n      ),\n    );\n  }\n}\n'

PERM_NEW = r"""    if (videoProvider.permissionDenied) {
      // 권한 안내: 작은 아이콘 + 부드러운 문구 + 1·2·3 순서 카드 + 먹색 버튼
      final card = isDarkMode ? const Color(0xFF26221C) : Colors.white;
      final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
      final sub = isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
      final hint = isDarkMode ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
      Widget step(int n, String text, {String? note}) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                  child: Text('$n', style: TextStyle(color: bgColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: TextStyle(color: ink, fontSize: 13.5)),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(note, style: TextStyle(color: hint, fontSize: 11.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: card, shape: BoxShape.circle),
                      child: Icon(Icons.movie_outlined, size: 26, color: sub),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('폰에 있는 동영상을 불러올게요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Text('동영상 접근을 한 번만 허용해 주세요',
                      textAlign: TextAlign.center, style: TextStyle(color: hint, fontSize: 13)),
                  const SizedBox(height: 22),
                  step(1, '아래 설정에서 허용하기 누르기'),
                  step(2, '권한 → 사진 및 동영상'),
                  step(3, '허용 고르고 돌아오기', note: '돌아오면 바로 목록이 나와요'),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: bgColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('설정에서 허용하기',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen())),
                      style: TextButton.styleFrom(foregroundColor: hint),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('다른 설정 도움말 보기', style: TextStyle(fontSize: 12.5)),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

"""

VIDEO_EDITS = [
    ('동영상: 도움말 화면 연결',
     "import '../widgets/cast_sheets.dart';\n",
     "import '../widgets/cast_sheets.dart';\n"
     "import 'settings_help_screen.dart';\n"),
    ('동영상: 설정에서 허용하고 돌아오면 바로 목록',
     "    if (!provider.permissionDenied && !provider.isLoading) {\n"
     "      provider.loadVideos(quiet: true);\n"
     "    }\n",
     "    if (!provider.permissionDenied && !provider.isLoading) {\n"
     "      provider.loadVideos(quiet: true);\n"
     "    } else if (provider.permissionDenied) {\n"
     "      // 설정에서 허용하고 돌아왔으면 바로 불러오기 (아직 안 했으면 창 안 띄움)\n"
     "      Permission.videos.status.then((s) {\n"
     "        if (s.isGranted || s.isLimited) provider.requestPermissionAndLoad();\n"
     "      });\n"
     "    }\n"),
]
PERM_START = "    if (videoProvider.permissionDenied) {\n"
PERM_END = "    if (videoProvider.isLoading) {\n"

MENU_EDITS = [
    ('⋮ 메뉴: 도움말 화면 연결',
     "import '../screens/bulk_art_screen.dart';\n",
     "import '../screens/bulk_art_screen.dart';\n"
     "import '../screens/settings_help_screen.dart';\n"),
    ('⋮ 메뉴: 물음표 아이콘',
     "const String _kIconClose =\n",
     "const String _kIconHelp =\n"
     "    '<circle cx=\"12\" cy=\"12\" r=\"10\"/><path d=\"M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3\"/>'\n"
     "    '<line x1=\"12\" y1=\"17\" x2=\"12.01\" y2=\"17\"/>';\n"
     "const String _kIconClose =\n"),
    ('⋮ 메뉴: 열 때 점 표시 여부 읽기',
     "  final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n"
     "  showModalBottomSheet(\n",
     "  final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n"
     "  HelpSeen.load();\n"
     "  showModalBottomSheet(\n"),
    ('⋮ 메뉴: 도움말 열기',
     "      onHomepage: () async {\n",
     "      onHelp: () {\n"
     "        Navigator.pop(ctx);\n"
     "        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen()));\n"
     "      },\n"
     "      onHomepage: () async {\n"),
    ('⋮ 메뉴: 도움말 버튼 받기',
     "  final VoidCallback onHomepage;\n"
     "  final bool showSongTools;\n",
     "  final VoidCallback onHomepage;\n"
     "  final VoidCallback onHelp;\n"
     "  final bool showSongTools;\n"),
    ('⋮ 메뉴: 도움말 버튼 받기 2',
     "    required this.onHomepage,\n"
     "  });\n",
     "    required this.onHomepage,\n"
     "    required this.onHelp,\n"
     "  });\n"),
    ('⋮ 메뉴: 설정 아래 "설정 도움말" 줄',
     "                    title: '설정',\n"
     "                    subtitle: '앱 환경을 설정해요.',\n"
     "                    onTap: onSettings,\n"
     "                  ),\n",
     "                    title: '설정',\n"
     "                    subtitle: '앱 환경을 설정해요.',\n"
     "                    onTap: onSettings,\n"
     "                  ),\n"
     "                  // 한 번도 안 열어봤으면 작은 점\n"
     "                  ValueListenableBuilder<bool>(\n"
     "                    valueListenable: HelpSeen.seen,\n"
     "                    builder: (context, seen, _) => _MenuCard(\n"
     "                      p: p,\n"
     "                      icon: _kIconHelp,\n"
     "                      title: '설정 도움말',\n"
     "                      subtitle: '권한·배터리·알림 설정 방법을 알려드려요.',\n"
     "                      onTap: onHelp,\n"
     "                      dot: !seen,\n"
     "                    ),\n"
     "                  ),\n"),
    ('⋮ 메뉴: 줄에 점 넣을 수 있게',
     "  final String subtitle;\n"
     "  final VoidCallback onTap;\n\n"
     "  const _MenuCard({\n",
     "  final String subtitle;\n"
     "  final VoidCallback onTap;\n"
     "  final bool dot; // 안 열어본 새 항목 표시\n\n"
     "  const _MenuCard({\n"),
    ('⋮ 메뉴: 줄에 점 넣을 수 있게 2',
     "    required this.onTap,\n"
     "  });\n\n"
     "  @override\n"
     "  Widget build(BuildContext context) {\n"
     "    return Material(\n",
     "    required this.onTap,\n"
     "    this.dot = false,\n"
     "  });\n\n"
     "  @override\n"
     "  Widget build(BuildContext context) {\n"
     "    return Material(\n"),
    ('⋮ 메뉴: 점 그리기',
     "              const SizedBox(width: 8),\n"
     "              _LineIcon(_kIconChevron,",
     "              const SizedBox(width: 8),\n"
     "              if (dot) ...[\n"
     "                Container(\n"
     "                  width: 7,\n"
     "                  height: 7,\n"
     "                  decoration: BoxDecoration(\n"
     "                    color: Theme.of(context).colorScheme.primary,\n"
     "                    shape: BoxShape.circle,\n"
     "                  ),\n"
     "                ),\n"
     "                const SizedBox(width: 6),\n"
     "              ],\n"
     "              _LineIcon(_kIconChevron,"),
]

SET_EDITS = [
    ('설정: 도움말 화면 연결',
     "import '../utils/home_card_pref.dart';\n",
     "import '../utils/home_card_pref.dart';\n"
     "import 'settings_help_screen.dart';\n"),
    ('설정: 기타 맨 위에 "설정 도움말"',
     "          _buildSection('기타'),\n",
     "          _buildSection('기타'),\n"
     "          _buildTile(context, icon: Icons.help_outline_rounded, title: '설정 도움말',\n"
     "              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen())),\n"
     "              primaryColor: primaryColor, isFirst: true),\n"),
    ('설정: 프로모션 코드 줄은 둘째로',
     "            if (mounted) setState(() {}); // 맨 위 카드 글자도 바로 바뀌게\n"
     "          }, primaryColor: primaryColor, isFirst: true),\n",
     "            if (mounted) setState(() {}); // 맨 위 카드 글자도 바로 바뀌게\n"
     "          }, primaryColor: primaryColor),\n"),
]

MARK = 'SettingsHelpScreen'


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


def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def apply(text, edits):
    ok = True
    for name, old, new in edits:
        if text.count(old) != 1:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    return text, ok


def main():
    for p in (VIDEO, MENU, SET):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in load(VIDEO)[0]:
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True

    text, crlf = load(VIDEO)
    before = balanced(text)
    if text.count(PERM_START) == 1 and text.count(PERM_END) == 1 and text.index(PERM_START) < text.index(PERM_END):
        a, b = text.index(PERM_START), text.index(PERM_END)
        text = text[:a] + PERM_NEW + text[b:]
        print('✔ 동영상: 권한 화면 새 디자인')
    else:
        print('❌ 동영상: 권한 화면 (찾을 코드를 못 찾았어요)')
        ok = False
    text, o = apply(text, VIDEO_EDITS)
    ok = ok and o
    if before and not balanced(text):
        print('❌ 괄호가 안 맞아요: video_screen.dart')
        ok = False
    out.append((VIDEO, text, crlf))

    for path, edits in ((MENU, MENU_EDITS), (SET, SET_EDITS)):
        text, crlf = load(path)
        before = balanced(text)
        text, o = apply(text, edits)
        ok = ok and o
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text, crlf))

    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        open(path, 'wb').write(text.encode('utf-8'))
    if not os.path.exists(HELP):
        open(HELP, 'wb').write(HELP_CODE.replace('\n', '\r\n').encode('utf-8'))
        print('✔ 새 파일 만듦: lib/screens/settings_help_screen.dart')
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
