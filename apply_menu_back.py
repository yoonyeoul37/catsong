# ⋮ 메뉴(홈·라디오·자연)에서 설정 등 화면에 갔다가 뒤로가기 하면 메뉴가 다시 열리게
import sys, os
PATH = os.path.join('lib', 'widgets', 'more_menu_sheet.dart')
if len(sys.argv) > 1: PATH = sys.argv[1]
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

R = [
('다시 열기 도우미 추가',
"""  final isDarkMode = context.read<ThemeProvider>().isDarkMode;
  HelpSeen.load();
  showModalBottomSheet(""",
"""  final isDarkMode = context.read<ThemeProvider>().isDarkMode;
  HelpSeen.load();
  // 메뉴에서 화면으로 갔다가 뒤로 오면 메뉴를 다시 열어 준다
  Future<void> openPage(BuildContext ctx, Route<void> route) async {
    Navigator.pop(ctx);
    await Navigator.push(context, route);
    if (!context.mounted) return;
    showMoreMenuSheet(
      context,
      shareText: shareText,
      shareSubtitle: shareSubtitle,
      stationHomepage: stationHomepage,
      showSongTools: showSongTools,
    );
  }

  showModalBottomSheet("""),
('곡 정보 한꺼번에 정리',
"""      onCleanSongs: () {
        Navigator.pop(ctx);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCleanScreen()));
      },""",
"""      onCleanSongs: () => openPage(ctx, MaterialPageRoute(builder: (_) => const BulkCleanScreen())),"""),
('앨범 사진 한꺼번에 찾기',
"""      onFindArt: () {
        Navigator.pop(ctx);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkArtScreen()));
      },""",
"""      onFindArt: () => openPage(ctx, MaterialPageRoute(builder: (_) => const BulkArtScreen())),"""),
('설정',
"""      onSettings: () {
        Navigator.pop(ctx);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },""",
"""      onSettings: () => openPage(
        ctx,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const SettingsScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),"""),
('설정 도움말',
"""      onHelp: () {
        Navigator.pop(ctx);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen()));
      },""",
"""      onHelp: () => openPage(ctx, MaterialPageRoute(builder: (_) => const SettingsHelpScreen())),"""),
('아침 알람',
"""      onAlarm: () {
        Navigator.pop(ctx);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()));
      },""",
"""      onAlarm: () => openPage(ctx, MaterialPageRoute(builder: (_) => const AlarmScreen())),"""),
]

if 'Future<void> openPage(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)
ok = True
for name, old, new in R:
    n = src.count(old)
    if n != 1:
        print(f'❌ {name}: 찾을 코드를 {"못 찾았어요" if n == 0 else f"{n}곳에서 찾았어요"}'); ok = False
    else:
        src = src.replace(old, new); print(f'✔ {name}')
if not ok:
    print('아무것도 저장하지 않았어요'); sys.exit(1)
out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('저장했어요:', PATH)
