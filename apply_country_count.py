# 라디오 나라 고르기 화면에 나라 수 넣기 (B안)
# 맨 위: 국가 선택 · 128개 나라 / 대륙 줄: 아시아 26 (연한 숫자)
# 바꾸는 파일: radio_home_screen.dart, 번역 파일 16개(app_*.arb — '개 나라' 번역)
import os, sys
EDITS = [("맨 위 '국가 선택' 옆에 전체 나라 수", '                    Text(\n                      AppLocalizations.of(context)!.radioSelectCountry,\n                      style: TextStyle(\n                        color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.65),\n                        fontSize: 12,\n                        fontWeight: FontWeight.w700,\n                        letterSpacing: 2,\n                      ),\n                    ),\n', "                    // 국가 선택 · 128개 나라 (나라 수는 목록을 세서 → 나라를 늘리면 저절로 바뀜)\n                    Row(\n                      crossAxisAlignment: CrossAxisAlignment.baseline,\n                      textBaseline: TextBaseline.alphabetic,\n                      children: [\n                        Text(\n                          AppLocalizations.of(context)!.radioSelectCountry,\n                          style: TextStyle(\n                            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.65),\n                            fontSize: 12,\n                            fontWeight: FontWeight.w700,\n                            letterSpacing: 2,\n                          ),\n                        ),\n                        const SizedBox(width: 6),\n                        Flexible(\n                          child: Text(\n                            '· ${AppLocalizations.of(context)!.countryTotal(countries.length)}',\n                            maxLines: 1,\n                            overflow: TextOverflow.ellipsis,\n                            style: TextStyle(\n                              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),\n                              fontSize: 12,\n                              fontWeight: FontWeight.w600,\n                            ),\n                          ),\n                        ),\n                      ],\n                    ),\n"), ('대륙 이름 옆에 나라 수', '              const SizedBox(width: 10),\n              Expanded(\n                child: Container(\n                  height: 0.5,\n', "              // 이 대륙 나라 수 (맨 위 '내 나라' 카드로 간 나라도 포함)\n              const SizedBox(width: 6),\n              Text(\n                '${countries.where((c) => c.continent == continent).length}',\n                style: TextStyle(\n                  color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.3),\n                  fontSize: 11.5,\n                  fontWeight: FontWeight.w600,\n                ),\n              ),\n              const SizedBox(width: 10),\n              Expanded(\n                child: Container(\n                  height: 0.5,\n")]
ARB = {'ko': '  "countryTotal": "{count}개 나라",\n  "@countryTotal": {"placeholders": {"count": {"type": "int"}}},', 'en': '  "countryTotal": "{count} countries",', 'ja': '  "countryTotal": "{count}か国",', 'zh': '  "countryTotal": "{count}个国家",', 'zh_Hant': '  "countryTotal": "{count} 個國家",', 'de': '  "countryTotal": "{count} Länder",', 'es': '  "countryTotal": "{count} países",', 'fr': '  "countryTotal": "{count} pays",', 'it': '  "countryTotal": "{count} paesi",', 'pt': '  "countryTotal": "{count} países",', 'pl': '  "countryTotal": "{count} krajów",', 'ru': '  "countryTotal": "{count} стран",', 'tr': '  "countryTotal": "{count} ülke",', 'id': '  "countryTotal": "{count} negara",', 'vi': '  "countryTotal": "{count} quốc gia",', 'th': '  "countryTotal": "{count} ประเทศ",'}
LANG_FILE = {'ko': 'app_ko.arb', 'en': 'app_en.arb', 'ja': 'app_ja.arb', 'zh': 'app_zh.arb', 'zh_Hant': 'app_zh_Hant.arb',
             'de': 'app_de.arb', 'es': 'app_es.arb', 'fr': 'app_fr.arb', 'it': 'app_it.arb', 'pt': 'app_pt.arb',
             'pl': 'app_pl.arb', 'ru': 'app_ru.arb', 'tr': 'app_tr.arb', 'id': 'app_id.arb', 'vi': 'app_vi.arb', 'th': 'app_th.arb'}
HOME = 'lib/screens/radio_home_screen.dart'

def load(path):
    raw = open(path, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw

def main():
    if not os.path.exists(HOME):
        print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
    t, crlf = load(HOME)
    if 'countryTotal' in t:
        print('이미 적용돼 있어요'); return
    out = {}
    ok = True
    for label, old, new in EDITS:
        c = t.count(old)
        if c == 1:
            t = t.replace(old, new); print(f'✔ radio_home_screen.dart: {label}')
        else:
            print(f'❌ radio_home_screen.dart: {label} — 찾을 곳을 못 찾았어요 ({c}곳)'); ok = False
    out[HOME] = (t, crlf)
    for lang, fn in LANG_FILE.items():
        path = f'lib/l10n/{fn}'
        if not os.path.exists(path):
            print(f'❌ {fn} 파일이 없어요'); ok = False; continue
        a, acrlf = load(path)
        lines = a.split('\n')
        idx = [i for i, l in enumerate(lines) if l.startswith('  "radioSelectCountry":')]
        if len(idx) != 1 or '"countryTotal"' in a:
            print(f'❌ {fn}: 넣을 자리(radioSelectCountry)를 못 찾았어요'); ok = False; continue
        lines.insert(idx[0] + 1, ARB[lang])
        out[path] = ('\n'.join(lines), acrlf)
        print(f'✔ {fn}: 나라 수 번역')
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요'); sys.exit(1)
    for path, (s, c) in out.items():
        open(path, 'wb').write((s.replace('\n', '\r\n') if c else s).encode('utf-8'))
    print('\n완료!')

main()
