# -*- coding: utf-8 -*-
# 홈 '잠시 쉬어가요' 라디오: 국악 빼고 주요 방송(KBS·MBC·SBS 서울) + CBS 음악FM 중 하루에 하나
# 라디오 '지금 듣기 좋은'(지금 시간대 추천 3개)와 안 겹치게
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')

OLD_IMPORT = "import 'radio_korea_screen2.dart' show niceKoreanStationNow, koreanRadioStations, koreanStationDesc;"
NEW_IMPORT = "import 'radio_korea_screen2.dart' show niceKoreanStationNow, koreanRadioStations, koreanStationDesc, niceDefaults;"

OLD_BLOCK_START = "    // 편안한 라디오: 하루에 하나씩 돌아가며 (보이는 이름, 방송국 이름, 주파수, 주소)\n"
OLD_BLOCK_END = "      'votes': 0,\n    });\n"

NEW_BLOCK = """    // 편안한 라디오: 주요 방송(KBS·MBC·SBS 서울) + CBS 음악FM 중 하루에 하나 (국악 뺌)
    // 라디오 '지금 듣기 좋은'(지금 시간대 추천 3개)와 안 겹치게 빼고 고르기
    const restRadioNames = [
      'KBS Classic FM', 'KBS 제1라디오', 'KBS 해피FM', 'KBS Cool FM',
      'MBC 표준FM', 'MBC FM4U', 'MBC 올댓뮤직',
      'SBS 파워FM', 'SBS 러브FM',
      'CBS 음악FM',
    ];
    final restHour = now.hour;
    final restSlot = (restHour >= 5 && restHour < 11)
        ? 0
        : (restHour >= 11 && restHour < 17)
            ? 1
            : (restHour >= 17 && restHour < 22)
                ? 2
                : 3;
    final restPool = restRadioNames.where((n) => !niceDefaults[restSlot].contains(n)).toList();
    final restName = restPool[daySeed % restPool.length];
    final allKr = koreanRadioStations();
    final restStation = allKr.firstWhere((s) => s.name == restName, orElse: () => allKr.first);
"""

OLD_LABEL = """        Localizations.localeOf(context).languageCode == 'ko'
            ? todayRadio.$1
            : (const {'KBS 클래식FM': 'KBS Classic FM', '국악FM': 'Gugak FM', 'CBS 음악FM': 'CBS Music FM'}[todayRadio.$1] ?? todayRadio.$2),"""
NEW_LABEL = """        Localizations.localeOf(context).languageCode == 'ko'
            ? (const {'KBS Classic FM': 'KBS 클래식FM', 'KBS Cool FM': 'KBS 쿨FM'}[restName] ?? restName)
            : (const {
                'KBS 제1라디오': 'KBS Radio 1',
                'KBS 해피FM': 'KBS Happy FM',
                'MBC 표준FM': 'MBC Standard FM',
                'MBC 올댓뮤직': 'MBC All That Music',
                'SBS 파워FM': 'SBS Power FM',
                'SBS 러브FM': 'SBS Love FM',
                'CBS 음악FM': 'CBS Music FM',
              }[restName] ?? restName),"""


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if 'restRadioNames' in text:
        print('이미 적용돼 있어요')
        return

    # 1) import
    if text.count(OLD_IMPORT) != 1:
        print('❌ radio_korea_screen2 import 줄을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(OLD_IMPORT, NEW_IMPORT)
    print('✔ niceDefaults 가져오기')

    # 2) 라디오 고르는 부분
    s = text.find(OLD_BLOCK_START)
    if s < 0 or text.count(OLD_BLOCK_START) != 1:
        print('❌ 편안한 라디오 시작 부분을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    e = text.find(OLD_BLOCK_END, s)
    if e < 0 or 'todayRadio' not in text[s:e]:
        print('❌ 편안한 라디오 끝 부분을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text[:s] + NEW_BLOCK + text[e + len(OLD_BLOCK_END):]
    print('✔ 국악 빼고 주요 방송 + CBS 음악FM 중에서 고르기 (지금 듣기 좋은 방송은 빼기)')

    # 3) 카드 글자
    if text.count(OLD_LABEL) != 1:
        print('❌ 카드 이름 부분을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(OLD_LABEL, NEW_LABEL)
    print('✔ 카드 이름 (한국어 / 해외)')

    if 'todayRadio' in text:
        print('❌ 예전 코드(todayRadio)가 남아 있어요 — 아무것도 저장 안 했어요')
        sys.exit(1)

    if crlf:
        text = text.replace('\n', '\r\n')
    with open(PATH, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요:', PATH)


main()
