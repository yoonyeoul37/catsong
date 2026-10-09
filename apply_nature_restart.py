# -*- coding: utf-8 -*-
# 자연소리 섞기: 앱을 다시 켜면 꺼진 상태로 시작
# - 지난번에 섞은 소리·크기는 기억 → 섞기 창 위에 "지난번 ○○과 함께 [다시 켜기]" 한 번에 켜기
# - "모두 끄기"를 눌러도 지난번 섞기는 남아 있음
# - 창 안 노래 제목 앞 이모지(🎵) 빼기
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
FILE = os.path.join(ROOT, 'lib', 'services', 'nature_overlay.dart')

EDITS = [
    ('지난번 섞기 기억할 자리',
     "  final Map<String, double> _vol = {for (final k in SoundMixProvider.natureAssets.keys) k: 0.0};\n",
     "  final Map<String, double> _vol = {for (final k in SoundMixProvider.natureAssets.keys) k: 0.0};\n"
     "  // 지난번에 섞은 크기 (앱을 다시 켜면 _vol은 0으로 시작하고, 여기서 한 번에 다시 켜기)\n"
     "  final Map<String, double> _last = {};\n"),
    ('지난번 섞기 요약·다시 켜기',
     "  /// 받침 있으면 '과', 없으면 '와' (예: 빗소리와 / 모닥불과)\n",
     "  /// 지금 꺼져 있고, 지난번에 섞은 게 있으면 true → 창에 [다시 켜기]\n"
     "  bool get hasLast => !anyOn && _last.values.any((v) => v > 0);\n"
     "\n"
     "  /// 예: \"빗소리\" / \"빗소리 외 1개\"\n"
     "  String get lastSummary {\n"
     "    final on = [for (final e in _last.entries) if (e.value > 0) variantOf(e.key)];\n"
     "    if (on.isEmpty) return '';\n"
     "    if (on.length == 1) return on.first;\n"
     "    return '${on.first} 외 ${on.length - 1}개';\n"
     "  }\n"
     "\n"
     "  /// 지난번 섞기 그대로 다시 켜기\n"
     "  Future<void> restoreLast() async {\n"
     "    _last.forEach((k, v) {\n"
     "      if (_vol.containsKey(k)) _vol[k] = v;\n"
     "    });\n"
     "    notifyListeners();\n"
     "    await _applyAll();\n"
     "  }\n"
     "\n"
     "  /// 받침 있으면 '과', 없으면 '와' (예: 빗소리와 / 모닥불과)\n"),
    ('앱 켤 때: 꺼진 채로 시작 (크기는 지난번으로 기억만)',
     "        m.forEach((k, v) {\n"
     "          if (_vol.containsKey(k) && v is num) _vol[k] = v.toDouble();\n"
     "        });\n",
     "        // 앱을 다시 켜면 갑자기 소리가 나지 않게 꺼진 채로 시작 → 창에서 [다시 켜기]\n"
     "        m.forEach((k, v) {\n"
     "          if (_vol.containsKey(k) && v is num) _last[k] = v.toDouble();\n"
     "        });\n"),
    ('저장: 다 끈 상태는 저장 안 함 (지난번 섞기 남기기)',
     "    final prefs = await SharedPreferences.getInstance();\n"
     "    await prefs.setString('music_nature_volumes', jsonEncode(_vol));\n",
     "    final prefs = await SharedPreferences.getInstance();\n"
     "    // 하나라도 켜져 있을 때만 \"지난번 섞기\"로 저장 (모두 끄기 해도 지난번은 남게)\n"
     "    if (anyOn) {\n"
     "      _last\n"
     "        ..clear()\n"
     "        ..addAll(_vol);\n"
     "      await prefs.setString('music_nature_volumes', jsonEncode(_vol));\n"
     "    }\n"),
    ('창: 노래 제목 앞 이모지 빼기',
     "                          const TextSpan(text: '🎵 '),\n",
     ""),
    ('창: 지난번 섞기 [다시 켜기] 카드',
     "              Container(\n"
     "                padding: const EdgeInsets.symmetric(vertical: 4),\n"
     "                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),\n",
     "              // 지난번 섞기 다시 켜기 (꺼져 있을 때만)\n"
     "              if (o.hasLast)\n"
     "                Container(\n"
     "                  margin: const EdgeInsets.only(bottom: 10),\n"
     "                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),\n"
     "                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),\n"
     "                  child: Row(\n"
     "                    children: [\n"
     "                      const Icon(Icons.history_rounded, size: 20, color: Color(0xFF8A857B)),\n"
     "                      const SizedBox(width: 10),\n"
     "                      Expanded(\n"
     "                        child: Column(\n"
     "                          crossAxisAlignment: CrossAxisAlignment.start,\n"
     "                          children: [\n"
     "                            const Text('지난번 섞기',\n"
     "                                style: TextStyle(color: Color(0xFF8A857B), fontSize: 11.5)),\n"
     "                            const SizedBox(height: 2),\n"
     "                            Text(o.lastSummary,\n"
     "                                maxLines: 1,\n"
     "                                overflow: TextOverflow.ellipsis,\n"
     "                                style: const TextStyle(\n"
     "                                    color: Color(0xFF17140F), fontSize: 14, fontWeight: FontWeight.w600)),\n"
     "                          ],\n"
     "                        ),\n"
     "                      ),\n"
     "                      const SizedBox(width: 8),\n"
     "                      SizedBox(\n"
     "                        height: 36,\n"
     "                        child: ElevatedButton(\n"
     "                          onPressed: () {\n"
     "                            HapticFeedback.selectionClick();\n"
     "                            o.restoreLast();\n"
     "                          },\n"
     "                          style: ElevatedButton.styleFrom(\n"
     "                            backgroundColor: const Color(0xFF17140F),\n"
     "                            foregroundColor: const Color(0xFFF4EFE5),\n"
     "                            elevation: 0,\n"
     "                            padding: const EdgeInsets.symmetric(horizontal: 14),\n"
     "                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n"
     "                          ),\n"
     "                          child: const Text('다시 켜기',\n"
     "                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),\n"
     "                        ),\n"
     "                      ),\n"
     "                    ],\n"
     "                  ),\n"
     "                ),\n"
     "              Container(\n"
     "                padding: const EdgeInsets.symmetric(vertical: 4),\n"
     "                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),\n"),
]

MARK = 'restoreLast()'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    if not os.path.exists(FILE):
        print('❌ 파일을 못 찾았어요:', FILE)
        sys.exit(1)
    raw = open(FILE, 'rb').read().decode('utf-8')
    if MARK in raw:
        print('이미 적용돼 있어요')
        return
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    before = balanced(text)
    ok = True
    for name, old, new in EDITS:
        if text.count(old) != 1:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    if before and not balanced(text):
        print('❌ 괄호가 안 맞아요')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    if crlf:
        text = text.replace('\n', '\r\n')
    open(FILE, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
