# -*- coding: utf-8 -*-
# 위쪽 버튼 규칙 맞추기 (라디오·팟캐스트·자연·믹스) + 음악 '통화녹음' → 탭 '녹음'
#  - 다크 모드 버튼은 빼고 ⋮ 메뉴 안으로 (apply_top_buttons.py 먼저)
#  - 종료 버튼은 홈에만, 다른 화면은 ⋮ 메뉴 '종료'
import os, sys

def J(*p):
    return os.path.join(*p)

DARK_RP = (
    "                                _FloatButton(\n"
    "                                  onTap: () {\n"
    "                                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "                                    context.read<ThemeProvider>().setDarkMode(!isDarkMode);\n"
    "                                  },\n"
    "                                  child: Icon(\n"
    "                                    isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,\n"
    "                                    color: baseColor,\n"
    "                                    size: 16,\n"
    "                                  ),\n"
    "                                ),\n"
    "                                const SizedBox(width: 10),\n")

JOBS = {
    J('lib', 'screens', 'radio_player_screen.dart'): [
        ('국내 라디오 재생: 다크 모드 버튼 빼기', DARK_RP, ''),
    ],
    J('lib', 'widgets', 'overseas_radio_view.dart'): [
        ('해외 라디오 재생: 위쪽 종료 버튼 빼기',
         "                                // 전원: 종료 확인창\n"
         "                                if (onExit != null)\n"
         "                                  IconButton(\n"
         "                                    onPressed: onExit,\n"
         "                                    icon: const Icon(Icons.power_settings_new_rounded,\n"
         "                                        color: Color(0xFFE8877E), size: 20),\n"
         "                                  ),\n",
         "                                // (종료는 ⋮ 메뉴 안으로)\n"),
        ('해외 라디오 재생: ⋮ 메뉴에 종료',
         "                                      stationHomepage: station.homepage,\n"
         "                                    );\n",
         "                                      stationHomepage: station.homepage,\n"
         "                                      onExit: onExit,\n"
         "                                    );\n"),
    ],
    J('lib', 'podcast', 'podcast_screens.dart'): [
        ('팟캐스트 재생: 다크 모드 버튼 빼기',
         "                      _PodFloat(\n"
         "                        onTap: () {\n"
         "                          _buzz();\n"
         "                          context.read<ThemeProvider>().setDarkMode(!dark);\n"
         "                        },\n"
         "                        child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,\n"
         "                            color: _baseOf(dark), size: 13),\n"
         "                      ),\n"
         "                      const SizedBox(width: 10),\n",
         ''),
    ],
    J('lib', 'screens', 'nature_sound_detail_screen.dart'): [
        ('자연 상세: 다크 모드 버튼 빼기',
         "                        GestureDetector(\n"
         "                          onTap: () {\n"
         "                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
         "                            context.read<ThemeProvider>().setDarkMode(!isDarkMode);\n"
         "                          },\n"
         "                          child: Container(\n"
         "                            width: 29,\n"
         "                            height: 29,\n"
         "                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.38), shape: BoxShape.circle),\n"
         "                            child: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,\n"
         "                                color: Colors.white, size: 13),\n"
         "                          ),\n"
         "                        ),\n"
         "                        const SizedBox(width: 8),\n",
         ''),
        ('자연 상세: ⋮ 메뉴에 종료',
         "                              shareText: tr.natureShareText,\n"
         "                            );\n",
         "                              shareText: tr.natureShareText,\n"
         "                              onExit: () => _showExitConfirmDialog(context),\n"
         "                            );\n"),
        ('자연 상세: 위쪽 종료 버튼 빼기',
         "                        const SizedBox(width: 8),\n"
         "                        GestureDetector(\n"
         "                          onTap: () => _showExitConfirmDialog(context),\n"
         "                          child: Container(\n"
         "                            width: 29,\n"
         "                            height: 29,\n"
         "                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.38), shape: BoxShape.circle),\n"
         "                            child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 13),\n"
         "                          ),\n"
         "                        ),\n",
         ''),
    ],
    J('lib', 'screens', 'sound_mix_screen.dart'): [
        ('사운드 믹스: ⋮ 메뉴 불러오기',
         "import '../widgets/paran_dialog.dart';\n",
         "import '../widgets/paran_dialog.dart';\nimport '../widgets/more_menu_sheet.dart';\n"),
        ('사운드 믹스: 다크 모드·설정·종료 → ⋮ 하나로',
         "          _iconBtn(\n"
         "            icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,\n"
         "            baseColor: baseColor,\n"
         "            onTap: () {\n"
         "              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
         "              context.read<ThemeProvider>().setDarkMode(!isDarkMode);\n"
         "            },\n"
         "          ),\n"
         "          const SizedBox(width: 6),\n"
         "          _iconBtn(\n"
         "            icon: Icons.settings_outlined,\n"
         "            baseColor: baseColor,\n"
         "            onTap: () {\n"
         "              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
         "              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));\n"
         "            },\n"
         "          ),\n"
         "          const SizedBox(width: 6),\n"
         "          _iconBtn(\n"
         "            icon: Icons.power_settings_new_rounded,\n"
         "            baseColor: baseColor,\n"
         "            onTap: () => _showExitConfirmDialog(context),\n"
         "          ),\n",
         "          // 다크 모드·설정·종료는 ⋮ 메뉴 안에\n"
         "          _iconBtn(\n"
         "            icon: Icons.more_vert,\n"
         "            baseColor: baseColor,\n"
         "            onTap: () {\n"
         "              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
         "              showMoreMenuSheet(context, onExit: () => _showExitConfirmDialog(context));\n"
         "            },\n"
         "          ),\n"),
    ],
    J('lib', 'screens', 'home_screen.dart'): [
        ('음악: 통화녹음 칩 → 탭 \'녹음\' (전체·즐겨찾기·최근 옆)',
         "                    Theme.of(context).colorScheme.primary,\n"
         "                  ),\n"
         "                        ],\n"
         "                      ),\n"
         "                    ),\n"
         "                  ),\n"
         "                  // 녹음 (일반 음악과 따로) — 아이폰은 다른 앱 파일을 못 읽어서 안드로이드만\n",
         "                    Theme.of(context).colorScheme.primary,\n"
         "                  ),\n"
         "                  // 녹음: 다른 탭과 같은 모양 (일반 음악과 따로 · 안드로이드만)\n"
         "                  if (Platform.isAndroid)\n"
         "                    _buildFilterTab(\n"
         "                      AppLocalizations.of(context)!.recordings,\n"
         "                      _showCalls,\n"
         "                          () => setState(() {\n"
         "                        _showFavorites = false;\n"
         "                        _showRecent = false;\n"
         "                        _showCalls = true;\n"
         "                      }),\n"
         "                      Theme.of(context).colorScheme.primary,\n"
         "                    ),\n"
         "                        ],\n"
         "                      ),\n"
         "                    ),\n"
         "                  ),\n"),
        ('음악: 오른쪽 끝 통화녹음 칩 지우기',
         "                  if (Platform.isAndroid) const SizedBox(width: 10), // 통화녹음은 오른쪽 끝으로\n"
         "                  // 통화녹음: 탭이 아니라 \"다른 곳으로 가는\" 작은 버튼 (안드로이드만)\n"
         "                  if (Platform.isAndroid)\n"
         "                    Padding(\n"
         "                      padding: const EdgeInsets.only(bottom: 8),\n"
         "                      child: GestureDetector(\n"
         "                        onTap: () {\n"
         "                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
         "                          setState(() {\n"
         "                            _showFavorites = false;\n"
         "                            _showRecent = false;\n"
         "                            _showCalls = true;\n"
         "                          });\n"
         "                        },\n"
         "                        child: Container(\n"
         "                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),\n"
         "                          decoration: BoxDecoration(\n"
         "                            borderRadius: BorderRadius.circular(14),\n"
         "                            border: Border.all(color: baseColor.withOpacity(0.18), width: 0.8),\n"
         "                          ),\n"
         "                          child: Text(tr.callRecordingsChip,\n"
         "                              style: TextStyle(color: baseColor.withOpacity(0.65), fontSize: 12)),\n"
         "                        ),\n"
         "                      ),\n"
         "                    ),\n",
         ''),
    ],
}


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def main():
    menu = J('lib', 'widgets', 'more_menu_sheet.dart')
    if not os.path.exists(menu) or 'VoidCallback? onExit' not in load(menu)[0]:
        print('❌ apply_top_buttons.py 를 먼저 돌려 주세요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    mix = J('lib', 'screens', 'sound_mix_screen.dart')
    if os.path.exists(mix) and "import '../widgets/more_menu_sheet.dart';" in load(mix)[0]:
        print('이미 적용돼 있어요')
        return
    out = []
    for path, edits in JOBS.items():
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        text, crlf = load(path)
        for name, old, new in edits:
            n = text.count(old)
            if n != 1:
                print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
                sys.exit(1)
            text = text.replace(old, new)
            print('✔', name)
        out.append((path, text, crlf))
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('✔ 저장했어요 (%d개 파일)' % len(out))


main()
