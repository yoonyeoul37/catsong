# -*- coding: utf-8 -*-
# 라디오 '지역별' 마지막 빈칸에 Paransori 브랜드 카드 (전국 N개 채널을 한곳에서) → 누르면 파란소리 소개
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_region_brand.py
import os, sys, json

PATH = 'lib/screens/radio_korea_screen2.dart'
EDITS = json.loads(r"""[["소개 화면 · 포인트 색 import", "import '../l10n/locale_holder.dart';\n", "import '../l10n/locale_holder.dart';\nimport '../utils/point_color.dart';\nimport 'paran_intro_screen.dart';\n"], ["브랜드 카드 추가", "  Widget _buildRegionGrid(BuildContext context) {", "  /// 지역별 마지막 빈칸: Paransori 브랜드 카드 (⋮ 메뉴 아래 먹색 카드와 한 세트) → 누르면 파란소리 소개\n  Widget _regionBrandCard(BuildContext context, bool isDarkMode) {\n    // 라이트: 먹색 카드 · 크림 글자 / 다크: 크림 카드 · 먹색 글자 (바탕과 반대)\n    final bg = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final fg = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);\n    final blue = pointColorOf(context, onDark: !isDarkMode);\n    final n = koreanStations.length;\n    final l = Localizations.localeOf(context);\n    final k = l.languageCode == 'zh'\n        ? ((l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'tw' : 'cn')\n        : l.languageCode;\n    final line = switch (k) {\n      'ko' => '전국 $n개 채널을\\n한곳에서',\n      'ja' => '全国$n局を\\nひとつの場所で',\n      'tw' => '全國$n個電台\\n盡在一處',\n      'cn' => '全国$n个电台\\n尽在一处',\n      _ => '$n stations,\\nall in one place',\n    };\n    return GestureDetector(\n      onTap: () {\n        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n        Navigator.push(context, MaterialPageRoute(builder: (_) => const ParanIntroScreen()));\n      },\n      child: Container(\n        padding: const EdgeInsets.symmetric(horizontal: 16),\n        alignment: Alignment.centerLeft,\n        decoration: BoxDecoration(\n          color: bg,\n          borderRadius: BorderRadius.circular(16),\n          boxShadow: [\n            BoxShadow(\n              color: Colors.black.withOpacity(0.25),\n              blurRadius: 12,\n              offset: const Offset(0, 6),\n            ),\n          ],\n        ),\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Row(\n              mainAxisSize: MainAxisSize.min,\n              crossAxisAlignment: CrossAxisAlignment.end,\n              children: [\n                Text.rich(\n                  TextSpan(children: [\n                    TextSpan(text: 'Paran', style: TextStyle(color: blue)),\n                    const TextSpan(text: 'sori'),\n                  ]),\n                  textScaler: TextScaler.noScaling,\n                  style: GoogleFonts.quicksand(\n                      color: fg, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.1),\n                ),\n                const SizedBox(width: 6),\n                // 작은 소리 막대 (로고 느낌)\n                Padding(\n                  padding: const EdgeInsets.only(bottom: 3),\n                  child: Row(\n                    mainAxisSize: MainAxisSize.min,\n                    crossAxisAlignment: CrossAxisAlignment.end,\n                    children: [\n                      for (final (i, h) in const [5.0, 9.0, 12.0, 7.0].indexed) ...[\n                        if (i > 0) const SizedBox(width: 2),\n                        Container(\n                          width: 2.5,\n                          height: h,\n                          decoration: BoxDecoration(\n                              color: blue.withOpacity(0.85), borderRadius: BorderRadius.circular(2)),\n                        ),\n                      ],\n                    ],\n                  ),\n                ),\n              ],\n            ),\n            const SizedBox(height: 7),\n            Text(\n              line,\n              maxLines: 2,\n              overflow: TextOverflow.ellipsis,\n              textScaler: TextScaler.noScaling,\n              style: TextStyle(\n                  color: fg.withOpacity(0.72), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.4),\n            ),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildRegionGrid(BuildContext context) {"], ["지역 9칸 + 마지막 브랜드 칸", "      itemCount: regionList.length,\n      itemBuilder: (context, index) {\n        final region = regionList[index];", "      itemCount: regionList.length + 1, // 9개 지역 + 마지막 빈칸에 브랜드 카드\n      itemBuilder: (context, index) {\n        if (index == regionList.length) return _regionBrandCard(context, isDarkMode);\n        final region = regionList[index];"]]""")

def main():
    if not os.path.exists(PATH):
        print('❌ 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
    if not os.path.exists('lib/screens/paran_intro_screen.dart'):
        print('❌ paran_intro_screen.dart가 없어요 (파란소리 소개를 먼저 넣어야 해요). 아무것도 바꾸지 않았어요.'); sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if 'Widget _regionBrandCard(' in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n == 1:
            s = s.replace(old, new); print('✔ radio_korea_screen2.dart -', name)
        else:
            print(f'❌ radio_korea_screen2.dart - {name} (찾을 코드가 {n}군데)'); ok = False
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('\n완료! 지역별 마지막 칸에 Paransori 카드가 생겼어요.')

if __name__ == '__main__':
    main()
