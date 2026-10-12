# -*- coding: utf-8 -*-
# 강조 색상 카드: 앱 켤 때 한 번만 돌기 + 영어 화면이면 영어 문구
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

EDITS = [
    # ── 앱 켤 때 한 번만 돌기 ──
    ("앱 켤 때 한 번만 돌기",
     "  @override\n  void initState() {\n    super.initState();\n    Future.delayed(const Duration(milliseconds: 1500), () {\n      if (mounted) _c.forward();\n    });\n  }",
     "  static bool _spun = false; // 앱 한 번 켤 때 한 번만 (음악 탭 갔다 와도 다시 안 돎)\n\n  @override\n  void initState() {\n    super.initState();\n    if (_spun) return;\n    _spun = true;\n    Future.delayed(const Duration(milliseconds: 1500), () {\n      if (mounted) _c.forward();\n    });\n  }"),
    # ── 카드 ──
    ("카드: 언어 확인",
     "  Widget _buildColorTip(bool isDark) {\n",
     "  Widget _buildColorTip(bool isDark) {\n    final isKo = Localizations.localeOf(context).languageCode == 'ko';\n"),
    ("카드: 강조 색상",
     "                Text('강조 색상',\n                    maxLines: 1,",
     "                Text(isKo ? '강조 색상' : 'Accent color',\n                    maxLines: 1,"),
    ("카드: 나만의 색으로 꾸며보세요",
     "Text('나만의 색으로 꾸며보세요',",
     "Text(isKo ? '나만의 색으로 꾸며보세요' : 'Make it your color',"),
    ("카드: 10가지 색",
     "Text('숲 · 노을 · 벚꽃 등 10가지 색',",
     "Text(isKo ? '숲 · 노을 · 벚꽃 등 10가지 색' : '10 colors like Forest, Sunset, Blossom',"),
    ("카드: 꾸미기 버튼",
     "child: Text('꾸미기', style:",
     "child: Text(isKo ? '꾸미기' : 'Try it', style:"),
    # ── 색 고르는 창 ──
    ("창: 언어 확인",
     "    final sheetBg = dark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);\n    await showParanSheet(\n      context,\n      title: '강조 색상',",
     "    final sheetBg = dark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);\n    final isKo = Localizations.localeOf(context).languageCode == 'ko';\n    await showParanSheet(\n      context,\n      title: isKo ? '강조 색상' : 'Accent color',"),
    ("창: 강조 색상",
     "              Text('강조 색상',\n                  style: TextStyle(color: label,",
     "              Text(isKo ? '강조 색상' : 'Accent color',\n                  style: TextStyle(color: label,"),
    ("창: 오늘 기분에 어울리는 색은?",
     "Text('오늘 기분에 어울리는 색은?',",
     "Text(isKo ? '오늘 기분에 어울리는 색은?' : 'What color fits your mood today?',"),
    ("창: 색 이름",
     "                  Text(name,\n                      maxLines: 1,",
     "                  Text(isKo ? name : (_colorNameEn[name] ?? name),\n                      maxLines: 1,"),
    ("창: 설정 안내",
     "child: Text('설정 → 꾸미기 → 강조 색상에서\\n다시 변경할 수 있습니다.',",
     "child: Text(isKo ? '설정 → 꾸미기 → 강조 색상에서\\n다시 변경할 수 있습니다.' : 'You can change it again\\nanytime in Settings.',"),
    ("창: 완료 버튼",
     "child: const Text('완료', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),",
     "child: Text(isKo ? '완료' : 'Done', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),"),
    ("색 이름 영어",
     "/// 강조 색상 10가지를 한 바퀴로 (가운데는 카드 색 구멍)\n",
     "/// 강조 색상 이름 (영어 화면용)\nconst Map<String, String> _colorNameEn = {\n  '파란소리': 'Paransori', '숲': 'Forest', '노을': 'Sunset', '라벤더': 'Lavender', '먹색': 'Ink',\n  '벚꽃': 'Blossom', '바다': 'Ocean', '햇살': 'Sunlight', '와인': 'Wine', '밤하늘': 'Night sky',\n};\n\n/// 강조 색상 10가지를 한 바퀴로 (가운데는 카드 색 구멍)\n"),
]

p = find('home_screen.dart')
if not p:
    print('❌ home_screen.dart 파일을 못 찾았어요'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')
if '_colorNameEn' in t:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for name, a, b in EDITS:
    if t.count(a) == 1:
        t = t.replace(a, b); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % t.count(a))
if ok and not all(t.count(x) == t.count(y) for x, y in ('()', '{}', '[]')):
    ok = False; print('❌ 괄호 개수가 안 맞아요')
if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
shutil.copyfile(p, p + '.bak')
if crlf:
    t = t.replace('\n', '\r\n')
open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
