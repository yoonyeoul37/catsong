# -*- coding: utf-8 -*-
# 휴대폰 뒤로가기 정리
#  1) 라디오 나라 바꾸기: 나라 화면이 계속 쌓이던 것 → 고르면 이전 나라 화면은 지우기 (뒤로가기 한 번에 홈)
#  2) 국내 라디오 방송 화면을 미니플레이어·홈에서 열었을 때: 휴대폰 뒤로가기도 위쪽 ∨ 버튼처럼 목록으로
#  3) 자연소리 화면을 홈에서 열었을 때: 휴대폰 뒤로가기도 위쪽 < 버튼처럼 자연소리 목록으로
import os, sys

def J(*p):
    return os.path.join(*p)

RADIO_HOME = J('lib', 'screens', 'radio_home_screen.dart')
RADIO_PLAYER = J('lib', 'screens', 'radio_player_screen.dart')
NATURE = J('lib', 'screens', 'nature_sound_detail_screen.dart')

RADIO_LIST_CODE = (
    "                                  final country = radioProvider.selectedCountry;\n"
    "                                  // 한국 방송이면 항상 한국 목록으로\n"
    "                                  final Widget listScreen = current.countryCode == 'KR'\n"
    "                                      ? const RadioKoreaScreen()\n"
    "                                      : country == null\n"
    "                                          ? const RadioHomeScreen()\n"
    "                                          : country.code == 'KR'\n"
    "                                              ? const RadioKoreaScreen()\n"
    "                                              : RadioCountryStationsScreen(country: country);\n"
    "                                  Navigator.of(context).pushReplacement(\n"
    "                                    PageRouteBuilder(\n"
    "                                      pageBuilder: (context, animation, secondaryAnimation) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: radioTextScaler(context)), child: listScreen), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n"
    "                                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>\n"
    "                                          FadeTransition(opacity: animation, child: child),\n"
    "                                      transitionDuration: const Duration(milliseconds: 250),\n"
    "                                    ),\n"
    "                                  );\n")

NATURE_LIST_CODE = (
    "                              Navigator.of(context).pushReplacement(\n"
    "                                PageRouteBuilder(\n"
    "                                  pageBuilder: (context, animation, secondaryAnimation) =>\n"
    "                                      const NatureSoundsScreen(),\n"
    "                                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>\n"
    "                                      FadeTransition(opacity: animation, child: child),\n"
    "                                  transitionDuration: const Duration(milliseconds: 250),\n"
    "                                ),\n"
    "                              );\n")

JOBS = {
    RADIO_HOME: [
        ('라디오 나라 고르기: 이전 나라 화면 지우기',
         "    Navigator.push(\n"
         "      context,\n"
         "      PageRouteBuilder(\n"
         "        pageBuilder: (context, animation, secondaryAnimation) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: radioTextScaler(context)), child: screen), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n",
         "    // 나라를 고르면 그 위에 쌓인 라디오 화면(이전 나라·나라 고르기)은 지우고 홈 바로 위에\n"
         "    // → 나라를 여러 번 바꿔도 뒤로가기 한 번에 홈으로\n"
         "    Navigator.pushAndRemoveUntil(\n"
         "      context,\n"
         "      PageRouteBuilder(\n"
         "        pageBuilder: (context, animation, secondaryAnimation) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: radioTextScaler(context)), child: screen), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)\n"),
        ('라디오 나라 고르기: 끝',
         "        transitionDuration: const Duration(milliseconds: 250),\n"
         "      ),\n"
         "    );\n"
         "  }\n"
         "\n"
         "  @override\n"
         "  Widget build(BuildContext context) {\n"
         "    final primaryColor = Theme.of(context).colorScheme.primary;\n",
         "        transitionDuration: const Duration(milliseconds: 250),\n"
         "      ),\n"
         "      (route) => route.isFirst,\n"
         "    );\n"
         "  }\n"
         "\n"
         "  @override\n"
         "  Widget build(BuildContext context) {\n"
         "    final primaryColor = Theme.of(context).colorScheme.primary;\n"),
    ],
    RADIO_PLAYER: [
        ('국내 방송 화면: 위쪽 ∨ 버튼은 목록 가기 함수로',
         RADIO_LIST_CODE,
         "                                  goToList();\n"),
        ('국내 방송 화면: 휴대폰 뒤로가기도 같게 (시작)',
         "    return Scaffold(\n"
         "      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),\n"
         "      bottomNavigationBar: GestureDetector(\n",
         "    // 목록이 아닌 곳(미니플레이어·홈)에서 열었으면 → 목록 화면으로 (위쪽 ∨ 버튼과 휴대폰 뒤로가기 같게)\n"
         "    void goToList() {\n"
         + RADIO_LIST_CODE.replace("                                  ", "      ") +
         "    }\n\n"
         "    return PopScope(\n"
         "      canPop: widget.openedFromList,\n"
         "      onPopInvokedWithResult: (didPop, _) {\n"
         "        if (!didPop) goToList();\n"
         "      },\n"
         "      child: Scaffold(\n"
         "      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),\n"
         "      bottomNavigationBar: GestureDetector(\n"),
        ('국내 방송 화면: 휴대폰 뒤로가기도 같게 (끝)',
         "                  context.read<RadioProvider>().playStation(list[newIdx]);\n"
         "                }\n"
         "              },\n"
         "            ),\n"
         "          ),\n"
         "\n"
         "        ],\n"
         "      ),\n"
         "    );\n"
         "  }\n"
         "}\n",
         "                  context.read<RadioProvider>().playStation(list[newIdx]);\n"
         "                }\n"
         "              },\n"
         "            ),\n"
         "          ),\n"
         "\n"
         "        ],\n"
         "      ),\n"
         "    ),\n"
         "    );\n"
         "  }\n"
         "}\n"),
    ],
    NATURE: [
        ('자연 화면: 위쪽 < 버튼은 목록 가기 함수로',
         NATURE_LIST_CODE,
         "                              goToList();\n"),
        ('자연 화면: 휴대폰 뒤로가기도 같게 (시작)',
         "    return Scaffold(\n"
         "      backgroundColor: currentColor,\n",
         "    // 홈에서 열었으면 → 자연소리 목록으로 (위쪽 < 버튼과 휴대폰 뒤로가기 같게)\n"
         "    void goToList() {\n"
         + NATURE_LIST_CODE.replace("                              ", "      ") +
         "    }\n\n"
         "    return PopScope(\n"
         "      canPop: widget.openedFromList,\n"
         "      onPopInvokedWithResult: (didPop, _) {\n"
         "        if (!didPop) goToList();\n"
         "      },\n"
         "      child: Scaffold(\n"
         "      backgroundColor: currentColor,\n"),
    ],
}


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def main():
    if 'pushAndRemoveUntil' in load(RADIO_HOME)[0] if os.path.exists(RADIO_HOME) else False:
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
        if path == NATURE:
            # 파일 맨 끝: Scaffold 닫는 곳에 하나 더
            tail = "      ),\n    );\n  }\n}"
            body = text.rstrip('\n')
            if not body.endswith(tail):
                print('❌ 자연 화면 끝부분을 못 찾았어요 — 아무것도 저장 안 했어요')
                sys.exit(1)
            text = body[:-len(tail)] + "      ),\n    ),\n    );\n  }\n}\n"
            print('✔ 자연 화면: 휴대폰 뒤로가기도 같게 (끝)')
        out.append((path, text, crlf))
    for path, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('✔ 저장했어요 (%d개 파일)' % len(out))


main()
