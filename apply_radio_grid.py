# -*- coding: utf-8 -*-
# 라디오 '방송사별' 칸 6개 → 10개 (TBN · 종교 방송 · 지역 민방 · 공동체 라디오 추가, 기타 33개 → 7개)
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_radio_grid.py
import os, sys, json

PATH = 'lib/screens/radio_korea_screen2.dart'
EDITS = json.loads(r"""[["칸 순서·색 10칸으로", "  static const _order = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS', '기타'];\n\n  static const Map<String, Color> _cardColors = {\n    'KBS': Color(0xFF14356B),\n    'MBC': Color(0xFF4A1E5C),\n    'SBS': Color(0xFF7A1F1F),\n    'EBS': Color(0xFF0D4C6E),\n    'CBS': Color(0xFF1E4A2E),\n  };\n", "  static const _order = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS', 'TBN', '종교', '지역민방', '공동체', '기타'];\n\n  static const Map<String, Color> _cardColors = {\n    'KBS': Color(0xFF14356B),\n    'MBC': Color(0xFF4A1E5C),\n    'SBS': Color(0xFF7A1F1F),\n    'EBS': Color(0xFF0D4C6E),\n    'CBS': Color(0xFF1E4A2E),\n    'TBN': Color(0xFF6B4A12), // 황토\n    '종교': Color(0xFF33405A), // 회청\n    '지역민방': Color(0xFF6A3B22), // 적갈\n    '공동체': Color(0xFF4A5320), // 올리브\n  };\n\n  /// 방송사 → 칸 (KBS·MBC·SBS·EBS·CBS는 그대로, 나머지는 묶음)\n  static String _keyOf(String broadcaster) => switch (broadcaster) {\n        'KBS' || 'MBC' || 'SBS' || 'EBS' || 'CBS' || 'TBN' => broadcaster,\n        'FEBC' || 'BBS' || 'CPBC' => '종교',\n        'TBC' || 'JTV' || 'OBS' => '지역민방', // OBS 칸에 경인방송도 같이 있음 (나중에 KNN·KBC·TJB 등도 여기로)\n        '공동체' => '공동체',\n        _ => '기타',\n      };\n\n  /// 칸 이름 (언어에 맞게) — 지역 칸에서 열 때는 지역 이름\n  static String gridLabel(BuildContext context, String key) => switch (key) {\n        '기타' => tr.categoryEtc,\n        '종교' => stationCategoryLabel(context, 3),\n        '공동체' => stationCategoryLabel(context, 6),\n        '지역민방' => _privateLabel(context),\n        _ => _RadioKoreaScreenState._regionLabel(key),\n      };\n\n  /// '지역 민방' (5개 언어)\n  static String _privateLabel(BuildContext context) {\n    final l = Localizations.localeOf(context);\n    final k = l.languageCode == 'zh'\n        ? ((l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'tw' : 'cn')\n        : l.languageCode;\n    return switch (k) {\n      'ko' => '지역 민방',\n      'ja' => '地方民放',\n      'tw' => '地方民營電台',\n      'cn' => '地方民营电台',\n      _ => 'Regional private',\n    };\n  }\n"], ["방송을 칸에 나누기", "      final key = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS'].contains(s.broadcaster)\n          ? s.broadcaster\n          : '기타';\n", "      final key = _keyOf(s.broadcaster);\n"], ["칸 이름 언어별로 (길면 살짝 줄여서 한 줄)", "                Text(\n                  key == '기타' ? tr.categoryEtc : key,\n                  style: const TextStyle(\n                    color: Colors.white,\n                    fontSize: 17,\n                    fontWeight: FontWeight.w700,\n                  ),\n                ),\n", "                Padding(\n                  padding: const EdgeInsets.symmetric(horizontal: 10),\n                  child: FittedBox(\n                    fit: BoxFit.scaleDown, // 'Community radio'처럼 길면 칸 안에 맞게 살짝 작게\n                    child: Text(\n                      gridLabel(context, key),\n                      maxLines: 1,\n                      style: const TextStyle(\n                        color: Colors.white,\n                        fontSize: 17,\n                        fontWeight: FontWeight.w700,\n                      ),\n                    ),\n                  ),\n                ),\n"], ["목록 화면 제목도 칸 이름과 같게", "        title: Text(broadcaster == '기타' ? tr.categoryEtc : _RadioKoreaScreenState._regionLabel(broadcaster),", "        title: Text(_BroadcasterGridScreen.gridLabel(context, broadcaster),"]]""")

def main():
    if not os.path.exists(PATH):
        print('❌ 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if "static String _keyOf(String broadcaster)" in s:
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
    print('\n완료! 방송사별 칸이 10개가 됐어요.')

if __name__ == '__main__':
    main()
