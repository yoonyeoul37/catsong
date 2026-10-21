# -*- coding: utf-8 -*-
# 위쪽 동그란 버튼 줄이기: 다크 모드 → ⋮ 메뉴 안으로 / 음악 화면 전원 → ⋮ 메뉴 '종료'로
import os, sys

HOME = os.path.join('lib', 'screens', 'home_screen.dart')
MENU = os.path.join('lib', 'widgets', 'more_menu_sheet.dart')

HOME_EDITS = [
    ('홈·음악: 다크 모드 버튼 빼기',
     "          _AppBarCircleButton(\n"
     "            onTap: () {\n"
     "              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
     "              context.read<ThemeProvider>().setDarkMode(!isDarkMode);\n"
     "            },\n"
     "            icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,\n"
     "            baseColor: baseColor,\n"
     "          ),\n"
     "          const SizedBox(width: 8),\n",
     "          // (다크 모드는 ⋮ 메뉴 안으로)\n"),
    ('음악 화면: 전원 버튼 빼기 (홈은 그대로)',
     "          _AppBarCircleButton(\n"
     "            onTap: () {\n"
     "              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
     "              _showExitConfirmDialog(context);\n"
     "            },\n"
     "            icon: Icons.power_settings_new_rounded,\n"
     "            baseColor: baseColor,\n"
     "          ),\n"
     "          const SizedBox(width: 8),\n",
     "          // 종료: 홈에서만 버튼 · 음악 화면은 ⋮ 메뉴 '종료'\n"
     "          if (!_showMusicLibrary) ...[\n"
     "            _AppBarCircleButton(\n"
     "              onTap: () {\n"
     "                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
     "                _showExitConfirmDialog(context);\n"
     "              },\n"
     "              icon: Icons.power_settings_new_rounded,\n"
     "              baseColor: baseColor,\n"
     "            ),\n"
     "            const SizedBox(width: 8),\n"
     "          ],\n"),
    ('음악 화면 ⋮ 메뉴에 종료 넘기기',
     "              showMoreMenuSheet(context);\n",
     "              showMoreMenuSheet(context,\n"
     "                  onExit: _showMusicLibrary ? () => _showExitConfirmDialog(context) : null);\n"),
]

MENU_EDITS = [
    ('달·전원 아이콘',
     "class _LineIcon extends StatelessWidget {",
     "// 다크 모드: 달 / 종료: 전원\n"
     "const String _kIconMoon = '<path d=\"M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z\"/>';\n"
     "const String _kIconPower =\n"
     "    '<path d=\"M18.36 6.64a9 9 0 1 1-12.73 0\"/><line x1=\"12\" y1=\"2\" x2=\"12\" y2=\"12\"/>';\n\n"
     "class _LineIcon extends StatelessWidget {"),
    ('메뉴 열 때 종료 받기',
     "      bool showSongTools = false, // 홈에서만: 곡 정보 한꺼번에 정리\n    }) {\n",
     "      bool showSongTools = false, // 홈에서만: 곡 정보 한꺼번에 정리\n"
     "      VoidCallback? onExit, // 있으면 맨 아래 '종료' 줄 (음악 화면)\n    }) {\n"),
    ('메뉴 다시 열 때도 종료 그대로',
     "      showSongTools: showSongTools,\n    );\n  }\n",
     "      showSongTools: showSongTools,\n      onExit: onExit,\n    );\n  }\n"),
    ('시트에 종료 넘기기',
     "      showSongTools: showSongTools,\n      onCleanSongs:",
     "      showSongTools: showSongTools,\n"
     "      onExit: onExit == null\n"
     "          ? null\n"
     "          : () {\n"
     "              Navigator.pop(ctx);\n"
     "              onExit();\n"
     "            },\n"
     "      onCleanSongs:"),
    ('시트 칸 추가',
     "  final VoidCallback onFindArt;\n\n  const _MoreMenuSheet({\n",
     "  final VoidCallback onFindArt;\n  final VoidCallback? onExit;\n\n  const _MoreMenuSheet({\n    this.onExit,\n"),
    ('다크 모드 바꾸면 메뉴 색도 바로 바뀌게',
     "    final p = isDarkMode ? _Pal.dark : _Pal.light;\n",
     "    final dark = context.watch<ThemeProvider>().isDarkMode; // 메뉴 안에서 바꿔도 바로\n"
     "    final p = dark ? _Pal.dark : _Pal.light;\n"),
    ('다크 모드 줄 (설정 위)',
     "                  _MenuCard(\n"
     "                    p: p,\n"
     "                    icon: _kIconGear,\n",
     "                  // 다크 모드: 누르면 바로 켜고 끄기 (메뉴는 그대로)\n"
     "                  _MenuCard(\n"
     "                    p: p,\n"
     "                    icon: _kIconMoon,\n"
     "                    title: tr.darkMode,\n"
     "                    subtitle: tr.darkModeInfo,\n"
     "                    onTap: () => context.read<ThemeProvider>().setDarkMode(!dark),\n"
     "                    trailing: _MiniToggle(on: dark, p: p),\n"
     "                  ),\n"
     "                  _MenuCard(\n"
     "                    p: p,\n"
     "                    icon: _kIconGear,\n"),
    ('종료 줄 (맨 아래)',
     "                      onTap: onHomepage,\n"
     "                    ),\n"
     "                ]),\n",
     "                      onTap: onHomepage,\n"
     "                    ),\n"
     "                  if (onExit != null)\n"
     "                    _MenuCard(\n"
     "                      p: p,\n"
     "                      icon: _kIconPower,\n"
     "                      title: tr.exit,\n"
     "                      subtitle: '',\n"
     "                      onTap: onExit!,\n"
     "                    ),\n"
     "                ]),\n"),
    ('줄 오른쪽에 화살표 대신 다른 것 넣을 수 있게',
     "  final bool dot; // 안 열어본 새 항목 표시\n",
     "  final bool dot; // 안 열어본 새 항목 표시\n"
     "  final Widget? trailing; // 있으면 › 대신 (다크 모드 켜짐 표시)\n"),
    ('줄 칸 추가',
     "    this.dot = false,\n  });\n",
     "    this.dot = false,\n    this.trailing,\n  });\n"),
    ('설명이 없으면 한 줄로',
     "                    const SizedBox(height: 2),\n"
     "                    Text(\n"
     "                      subtitle,\n"
     "                      maxLines: 1,\n"
     "                      overflow: TextOverflow.ellipsis,\n"
     "                      style: TextStyle(color: p.desc, fontSize: 11.5),\n"
     "                    ),\n"
     "                  ],\n"
     "                ),\n"
     "              ),\n"
     "              const SizedBox(width: 8),\n"
     "              if (dot) ...[\n",
     "                    if (subtitle.isNotEmpty) ...[\n"
     "                      const SizedBox(height: 2),\n"
     "                      Text(\n"
     "                        subtitle,\n"
     "                        maxLines: 1,\n"
     "                        overflow: TextOverflow.ellipsis,\n"
     "                        style: TextStyle(color: p.desc, fontSize: 11.5),\n"
     "                      ),\n"
     "                    ],\n"
     "                  ],\n"
     "                ),\n"
     "              ),\n"
     "              const SizedBox(width: 8),\n"
     "              if (dot) ...[\n"),
    ('› 자리에 켜짐 표시',
     "              Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, // 아랍어에선 < 방향\n"
     "                  child: _LineIcon(_kIconChevron, size: 18, color: p.chevron, stroke: 2.0)),\n"
     "            ],\n"
     "          ),\n"
     "        ),\n"
     "      ),\n"
     "    );\n"
     "  }\n"
     "}\n",
     "              trailing ??\n"
     "                  Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, // 아랍어에선 < 방향\n"
     "                      child: _LineIcon(_kIconChevron, size: 18, color: p.chevron, stroke: 2.0)),\n"
     "            ],\n"
     "          ),\n"
     "        ),\n"
     "      ),\n"
     "    );\n"
     "  }\n"
     "}\n\n"
     "/// 작은 켜기·끄기 표시 (설정 화면 칸처럼 켜지면 먹색, 다크 모드는 크림색)\n"
     "class _MiniToggle extends StatelessWidget {\n"
     "  final bool on;\n"
     "  final _Pal p;\n"
     "  const _MiniToggle({required this.on, required this.p});\n\n"
     "  @override\n"
     "  Widget build(BuildContext context) {\n"
     "    return AnimatedContainer(\n"
     "      duration: const Duration(milliseconds: 180),\n"
     "      width: 38,\n"
     "      height: 22,\n"
     "      padding: const EdgeInsets.all(3),\n"
     "      alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,\n"
     "      decoration: BoxDecoration(\n"
     "        color: on ? p.title : p.chevron.withOpacity(0.45),\n"
     "        borderRadius: BorderRadius.circular(11),\n"
     "      ),\n"
     "      child: Container(\n"
     "        width: 16,\n"
     "        height: 16,\n"
     "        decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),\n"
     "      ),\n"
     "    );\n"
     "  }\n"
     "}\n"),
]


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def edit(path, edits):
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
    return path, text, crlf


def main():
    menu, _ = load(MENU)
    if '_MiniToggle' in menu:
        print('이미 적용돼 있어요')
        return
    out = [edit(HOME, HOME_EDITS), edit(MENU, MENU_EDITS)]
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('✔ 저장했어요')


main()
