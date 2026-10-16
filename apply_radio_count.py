# -*- coding: utf-8 -*-
# 메인 라디오 카드 왼쪽 위에 채널 수 알약 (한국어: 국내 개수 · 영어/일본어/번체/간체: 그 나라 채널 수)
# 실행: python apply_radio_count.py
import os, sys

EDITS = {
    'home_screen.dart': [('  // ───── 메인 홈 카드: 나만의 색 → 지금 방송 → 오늘의 팁', "  // ───── 메인 라디오 카드 왼쪽 위 채널 수 (한국어: 국내 방송 개수 · 다른 언어: 그 나라 채널 수) ─────\n  int? _radioCount; // 다른 나라 채널 수 (저장해 둔 값 → 새로 받은 값)\n  String? _radioCountFor; // 위 숫자가 어느 나라 것인지\n\n  static String _radioCountry(Locale l) => switch (l.languageCode) {\n        'ko' => 'KR',\n        'ja' => 'JP',\n        'zh' => (l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'TW' : 'CN',\n        _ => (l.countryCode ?? '').length == 2 ? l.countryCode!.toUpperCase() : 'US',\n      };\n\n  Future<void> _loadRadioCount(String code) async {\n    final radio = context.read<RadioProvider>();\n    final p = await SharedPreferences.getInstance();\n    final saved = p.getInt('radio_count_$code');\n    if (saved != null && mounted && _radioCountFor == code) setState(() => _radioCount = saved);\n    await radio.fetchAllCountryCounts(); // 이미 받아 뒀으면 바로 끝남\n    final n = radio.getCountryStationCount(code);\n    if (n != null && n > 0) {\n      await p.setInt('radio_count_$code', n);\n      if (mounted && _radioCountFor == code) setState(() => _radioCount = n);\n    }\n  }\n\n  Widget _radioCountChip(BuildContext context) {\n    final l = Localizations.localeOf(context);\n    final code = _radioCountry(l);\n    int? n;\n    if (code == 'KR') {\n      n = koreanRadioStations().length;\n    } else {\n      if (_radioCountFor != code) {\n        _radioCountFor = code;\n        _radioCount = null;\n        WidgetsBinding.instance.addPostFrameCallback((_) => _loadRadioCount(code));\n      }\n      n = _radioCount;\n    }\n    if (n == null || n <= 0) return const SizedBox.shrink();\n    final countText = n.toString().replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (_) => ',');\n    final unit = switch (l.languageCode) {\n      'ko' => '채널',\n      'ja' => '局',\n      'zh' => code == 'TW' ? '個電台' : '个电台',\n      _ => 'stations',\n    };\n    const ink = Color(0xFF17140F);\n    const red = Color(0xFFE5484D);\n    return Container(\n      height: 23,\n      padding: const EdgeInsets.symmetric(horizontal: 9),\n      decoration: BoxDecoration(color: Colors.white.withOpacity(0.62), borderRadius: BorderRadius.circular(999)),\n      child: Row(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n          Container(\n            width: 6,\n            height: 6,\n            decoration: BoxDecoration(\n              color: red,\n              shape: BoxShape.circle,\n              boxShadow: [BoxShadow(color: red.withOpacity(0.25), spreadRadius: 2.5)],\n            ),\n          ),\n          const SizedBox(width: 6),\n          Text(countText, style: GoogleFonts.quicksand(color: ink.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w700)),\n          const SizedBox(width: 3),\n          Text(unit, style: TextStyle(color: ink.withOpacity(0.78), fontSize: 10.5, fontWeight: FontWeight.w700)),\n        ],\n      ),\n    );\n  }\n\n  // ───── 메인 홈 카드: 나만의 색 → 지금 방송 → 오늘의 팁"), ("                        Positioned(\n                          top: 8,\n                          right: 8,\n                          child: GestureDetector(\n                            onTap: () {\n                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                              _handleStartScreenStarTap(context, c.type, c.title);", "                        // 라디오 카드: 하트와 마주 보는 왼쪽 위에 채널 수 알약\n                        if (c.type == StartScreenType.radio)\n                          Positioned(\n                            top: 8,\n                            left: 8,\n                            right: 39, // 하트 칸(23) + 사이 8 비우기\n                            height: 23,\n                            child: Align(\n                              alignment: Alignment.centerLeft,\n                              child: FittedBox(\n                                fit: BoxFit.scaleDown,\n                                child: MediaQuery.withClampedTextScaling(\n                                  maxScaleFactor: 1.15,\n                                  child: _radioCountChip(context),\n                                ),\n                              ),\n                            ),\n                          ),\n                        Positioned(\n                          top: 8,\n                          right: 8,\n                          child: GestureDetector(\n                            onTap: () {\n                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                              _handleStartScreenStarTap(context, c.type, c.title);")],
}


def find(name):
    for root, _, files in list(os.walk('tools')) + list(os.walk('lib')):
        if name in files:
            return os.path.join(root, name)
    return None


done = {}
total = 0
for name, edits in EDITS.items():
    p = find(name)
    if not p:
        print(f'❌ {name} 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(p, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    cnt = lambda x: [x.count(ch) - x.count(cl) for ch, cl in ('()', '{}', '[]')]
    before = cnt(t)
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if name.endswith('.py'):
        try:
            compile(t, p, 'exec')
        except SyntaxError as e:
            print(f'❌ {name} 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
    elif cnt(t) != before:  # 고치기 전과 괄호 짝이 같아야 함
        print(f'❌ {name} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    done[p] = (t, crlf, n)
    total += n

if total == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, (t, crlf, n) in done.items():
    if n:
        with open(p, 'w', encoding='utf-8', newline='') as f:
            f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
