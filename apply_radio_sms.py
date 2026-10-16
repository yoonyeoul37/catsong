# -*- coding: utf-8 -*-
# 라디오 상세화면: 지금 프로그램 줄 오른쪽에 문자 참여 칩(#8910 등) → 누르면 요금 안내 + 문자 보내기
# 실행: python apply_radio_sms.py
import os, sys

EDITS = {
    'radio_player_screen.dart': [('    final line = isDark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);\n\n    final now = DateTime.now();\n    final nowM = _ScheduleListSheet._wrap(now.hour * 60 + now.minute);', '    final line = isDark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);\n    final sms = _smsNumbers[radioProvider.currentStation?.name]; // 문자 참여 번호 (없으면 칩 안 보임)\n\n    final now = DateTime.now();\n    final nowM = _ScheduleListSheet._wrap(now.hour * 60 + now.minute);'), ('              Text(tr.minutesLeft(end - nowM), style: TextStyle(color: muted, fontSize: 11.5)),\n            ],', "              Text(tr.minutesLeft(end - nowM), style: TextStyle(color: muted, fontSize: 11.5)),\n              if (sms != null) ...[\n                const SizedBox(width: 10),\n                // 문자 참여: 작은 테두리 칩 → 누르면 요금 안내 + 문자 보내기\n                GestureDetector(\n                  behavior: HitTestBehavior.opaque,\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    _showSmsSheet(context, sms);\n                  },\n                  child: Container(\n                    height: 22,\n                    padding: const EdgeInsets.symmetric(horizontal: 8),\n                    decoration: BoxDecoration(\n                      border: Border.all(color: line),\n                      borderRadius: BorderRadius.circular(999),\n                    ),\n                    child: Row(\n                      mainAxisSize: MainAxisSize.min,\n                      children: [\n                        Icon(Icons.sms_outlined, size: 12, color: muted),\n                        const SizedBox(width: 4),\n                        Text(sms, style: TextStyle(color: strong, fontSize: 11, fontWeight: FontWeight.w700)),\n                      ],\n                    ),\n                  ),\n                ),\n              ],\n            ],"), ('class _NowProgramStrip extends StatefulWidget {', "// ── 라디오 문자 참여 번호 (방송국 공식 페이지·여러 자료에서 같은 번호 확인한 곳만, 2026-10) ──\n// 확실하지 않은 곳(경인방송·국악FM·TBN·KBS 3라디오·국방FM)은 일부러 비워 둠 → 칩 안 보임\nconst _smsNumbers = {\n  'KBS 제1라디오': '#9730',\n  'KBS 해피FM': '#1061',\n  'KBS Classic FM': '#9310',\n  'KBS Cool FM': '#8910',\n  'MBC 표준FM': '#8001',\n  'MBC FM4U': '#8000',\n  'SBS 러브FM': '#1035',\n  'SBS 파워FM': '#1077',\n  'EBS FM': '#1045',\n  'CBS 표준FM': '#1212',\n  'CBS 음악FM': '#9390',\n  'YTN 라디오': '#0945',\n  'TBS FM': '#0951',\n  'TBS eFM': '#1013',\n  'OBS 라디오': '#0999',\n  'CPBC 가톨릭': '#1053',\n  'FEBC 극동방송': '#1069',\n  'FEBC 극동방송 AM': '#1069',\n  'BBS 불교방송': '#2842',\n};\n\n/// 문자 참여 안내 (아래에서 올라오는 베이지 카드 + ✕) → [문자 보내기] 누르면 문자 앱이 번호 채워진 채로 열림\nvoid _showSmsSheet(BuildContext context, String number) {\n  final l = Localizations.localeOf(context);\n  final k = l.languageCode == 'zh'\n      ? ((l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'tw' : 'cn')\n      : l.languageCode;\n  const texts = {\n    'ko': ['문자로 사연 보내기', '이 번호로 문자를 보내면 방송에 사연이나 신청곡을 보낼 수 있어요.', '짧은 문자 50원 · 긴 문자·사진 100원의 정보이용료가 붙어요.', '문자 보내기'],\n    'en': ['Text the show', 'Send a text to this number to share a story or request a song.', 'An information fee applies: 50 KRW for short texts, 100 KRW for long texts or photos.', 'Send text'],\n    'ja': ['メッセージで参加', 'この番号にメッセージを送ると、番組にお便りやリクエストを送れます。', '情報利用料がかかります（短文50ウォン・長文/写真100ウォン）。', 'メッセージを送る'],\n    'tw': ['傳簡訊參與', '傳簡訊到這個號碼，就能向節目分享故事或點歌。', '需支付資訊使用費（短訊50韓元・長訊/照片100韓元）。', '傳送簡訊'],\n    'cn': ['发短信参与', '发短信到这个号码，就能向节目分享故事或点歌。', '需支付信息使用费（短信50韩元・长信/图片100韩元）。', '发送短信'],\n  };\n  final t = texts[k] ?? texts['ko']!;\n  final isDark = context.read<ThemeProvider>().isDarkMode;\n  final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);\n  final strong = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n  final muted = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);\n  showModalBottomSheet(\n    context: context,\n    backgroundColor: Colors.transparent,\n    builder: (sheetCtx) => Container(\n      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),\n      child: SafeArea(\n        top: false,\n        child: Padding(\n          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            crossAxisAlignment: CrossAxisAlignment.start,\n            children: [\n              Align(\n                alignment: Alignment.centerRight,\n                child: GestureDetector(\n                  behavior: HitTestBehavior.opaque,\n                  onTap: () => Navigator.pop(sheetCtx),\n                  child: SizedBox(width: 36, height: 36, child: Icon(Icons.close_rounded, size: 20, color: muted)),\n                ),\n              ),\n              Row(\n                children: [\n                  Icon(Icons.sms_outlined, size: 18, color: strong),\n                  const SizedBox(width: 8),\n                  Expanded(\n                    child: Text(t[0], style: TextStyle(color: strong, fontSize: 16, fontWeight: FontWeight.w800)),\n                  ),\n                ],\n              ),\n              const SizedBox(height: 14),\n              Text(number,\n                  style: TextStyle(color: strong, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5)),\n              const SizedBox(height: 8),\n              Text(t[1], style: TextStyle(color: muted, fontSize: 13, height: 1.5)),\n              const SizedBox(height: 4),\n              Text(t[2], style: TextStyle(color: muted.withOpacity(0.8), fontSize: 12, height: 1.5)),\n              const SizedBox(height: 18),\n              SizedBox(\n                width: double.infinity,\n                height: 48,\n                child: Material(\n                  color: strong, // 큰 버튼은 먹색 (다크는 크림색)\n                  borderRadius: BorderRadius.circular(14),\n                  child: InkWell(\n                    borderRadius: BorderRadius.circular(14),\n                    onTap: () async {\n                      Navigator.pop(sheetCtx);\n                      await launchUrl(Uri(scheme: 'sms', path: number));\n                    },\n                    child: Center(\n                      child: Text(t[3],\n                          style: TextStyle(color: bg, fontSize: 14.5, fontWeight: FontWeight.w800)),\n                    ),\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n    ),\n  );\n}\n\nclass _NowProgramStrip extends StatefulWidget {")],
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
