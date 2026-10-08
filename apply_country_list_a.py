# -*- coding: utf-8 -*-
# 라디오 국가 목록 A안: 맨 위 "내 나라" 먹색 카드 + 대륙 이름 글자만(가는 선) + 아주 연한 구분선
import os, re, sys
P = os.path.join('lib', 'screens', 'radio_home_screen.dart')
if not os.path.exists(P):
    sys.exit('❌ radio_home_screen.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_MyCountryCard' in s:
    sys.exit('이미 적용돼 있어요.')

def rep(pattern, new, name, regex=False):
    global s
    if regex:
        m = list(re.finditer(pattern, s, re.S))
        if len(m) != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({len(m)}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s[:m[0].start()] + new + s[m[0].end():]
    else:
        n = s.count(pattern)
        if n != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s.replace(pattern, new)
    print(f'✔ {name}')

# 1) 대륙 이름: 한국어 화면이면 한글로
rep("""    final widgets = <Widget>[];
    for (final continent in sorted) {
      final group = countries.where((c) => c.continent == continent).toList();
      if (group.isEmpty) continue;
""", """    // 한국어 화면이면 대륙 이름도 한글로
    const continentLabelsKo = {
      'ASIA': '아시아',
      'EUROPE': '유럽',
      'NORTH_AMERICA': '북아메리카',
      'SOUTH_AMERICA': '남아메리카',
      'MIDDLE_EAST': '중동',
      'AFRICA': '아프리카',
      'OCEANIA': '오세아니아',
    };
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    final widgets = <Widget>[];

    // 맨 위: 내 나라 먹색 카드 (아래 목록에선 빼서 두 번 안 나오게)
    RadioCountry? myCountry;
    for (final c in countries) {
      if (c.code == deviceCountryCode) {
        myCountry = c;
        break;
      }
    }
    if (myCountry != null) {
      final mine = myCountry;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _MyCountryCard(country: mine, onTap: () => _onCountryTap(context, mine)),
      ));
    }

    for (final continent in sorted) {
      final group = countries.where((c) => c.continent == continent && c.code != myCountry?.code).toList();
      if (group.isEmpty) continue;
""", '대륙 이름·내 나라 카드')

# 2) 대륙 머리: 회색 알약 빼고 글자 + 가는 선
rep(r"""              Container\(
                padding: const EdgeInsets\.symmetric\(horizontal: 10, vertical: 4\),
                decoration: BoxDecoration\(
                  color: \(isDarkMode \? Colors\.white : Colors\.black\)\.withOpacity\(0\.08\),
                  borderRadius: BorderRadius\.circular\(6\),
                \),
                child: Text\(
                  continentLabels\[continent\] \?\? continent,
                  style: TextStyle\(
                    color: \(isDarkMode \? Colors\.white : Colors\.black\)\.withOpacity\(0\.5\),
                    fontSize: 11,
                    fontWeight: FontWeight\.w700,
                    letterSpacing: 1\.5,
                  \),
                \),
              \),""",
"""              Text(
                (isKo ? continentLabelsKo[continent] : continentLabels[continent]) ?? continent,
                style: TextStyle(
                  color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.45),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: isKo ? 0 : 1.2,
                ),
              ),""", '대륙 머리', regex=True)

# 3) 구분선 아주 연하게
rep("Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.16), indent: 48),",
    "Divider(height: 1, thickness: 0.6, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.07), indent: 48),",
    '구분선')

# 4) 내 나라 카드 부품
rep("class _CountryListTile extends StatelessWidget {",
"""/// 맨 위 "내 나라" 먹색 카드 (다크 모드는 크림색) — 설정 화면 맨 위 카드와 한 세트
class _MyCountryCard extends StatelessWidget {
  final RadioCountry country;
  final VoidCallback onTap;
  const _MyCountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final l = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    String count;
    if (country.code == 'KR') {
      count = '${koreanStations.length}${l.radioChannelCount}';
    } else {
      final n = context.watch<RadioProvider>().getCountryStationCount(country.code);
      count = n != null ? '$n${l.radioChannelCount}' : l.radioPopular200;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isKo ? '내 나라' : 'My country',
                        style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(country.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 1),
                    Text(count, style: TextStyle(color: fg.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryListTile extends StatelessWidget {""", '내 나라 카드 부품')

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)
print('\n✅ 끝! 국가 목록이 A안으로 바뀌었어요.')
