# -*- coding: utf-8 -*-
# 파란소리 소개를 잘 보이게: ① 홈 로고 누르면 소개 화면 ② 홈 '오늘의 팁'에 "왜 이름이 Paransori일까요?" 한 장 (16개 언어)
import os, re, sys, json
sys.stdout.reconfigure(encoding='utf-8')
H = os.path.join('lib', 'screens', 'home_screen.dart')
D = os.path.join('lib', 'l10n')

T = {  # 제목 · 설명 · 버튼
 'ko': ("왜 이름이 'Paransori'일까요?", "이름에 담긴 이야기를 들려드려요", "보기"),
 'en': ('Why "Paransori"?', "The story behind our name", "View"),
 'ja': ("なぜ「Paransori」なの？", "名前にこめた想いをご紹介します", "見る"),
 'zh': ("为什么叫“Paransori”？", "来看看名字背后的故事", "查看"),
 'zh_Hant': ("為什麼叫「Paransori」？", "來看看名字背後的故事", "查看"),
 'de': ("Warum „Paransori“?", "Die Geschichte hinter unserem Namen", "Ansehen"),
 'es': ('¿Por qué "Paransori"?', "La historia detrás de nuestro nombre", "Ver"),
 'fr': ("Pourquoi « Paransori » ?", "L’histoire de notre nom", "Voir"),
 'it': ('Perché "Paransori"?', "La storia dietro il nostro nome", "Vedi"),
 'pt': ('Por que "Paransori"?', "A história por trás do nosso nome", "Ver"),
 'pl': ("Dlaczego „Paransori”?", "Historia naszej nazwy", "Zobacz"),
 'ru': ("Почему «Paransori»?", "История нашего названия", "Открыть"),
 'tr': ('Neden "Paransori"?', "Adımızın ardındaki hikâye", "Gör"),
 'id': ('Kenapa "Paransori"?', "Kisah di balik nama kami", "Lihat"),
 'vi': ('Vì sao là "Paransori"?', "Câu chuyện đằng sau cái tên", "Xem"),
 'th': ('ทำไมถึงชื่อ "Paransori"?', "เรื่องราวเบื้องหลังชื่อของเรา", "ดู"),
}

if not os.path.exists(H):
    print('❌ 파일을 못 찾았어요:', H); sys.exit(1)
raw = open(H, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_openIntro' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ('소개 화면 불러오기',
  "import '../widgets/more_menu_sheet.dart';\n",
  "import '../widgets/more_menu_sheet.dart';\nimport 'paran_intro_screen.dart';\n"),
 ('팁에 이름 이야기 한 장 + 소개 열기',
  """    (tr.homeTipSleepTitle, tr.homeTipSleepSub),
  ];
""",
  """    (tr.homeTipSleepTitle, tr.homeTipSleepSub),
    (tr.homeTipNameTitle, tr.homeTipNameSub), // 왜 이름이 Paransori일까요? → 소개 화면
  ];

  /// 파란소리 소개 화면 열기 (홈 로고 누르기 · 이름 팁 '보기')
  void _openIntro() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ParanIntroScreen()));
  }
"""),
 ("팁 버튼: 알람은 '설정', 이름 팁은 '보기'",
  """      action: i == 1 ? tr.set : null,
      onAction: i == 1
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()))
          : null,""",
  """      action: i == 1 ? tr.set : (i == 5 ? tr.homeTipNameAction : null),
      onAction: i == 1
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()))
          : (i == 5 ? _openIntro : null),"""),
 ('홈 로고 누르면 소개 (시작)',
  """          : Builder(builder: (ctx) {
        final isKorean""",
  """          // 로고(아이콘 + 파란소리)를 누르면 파란소리 소개
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openIntro,
              child: Builder(builder: (ctx) {
        final isKorean"""),
 ('홈 로고 누르면 소개 (끝)',
  """      }),
      actions: [""",
  """      })),
      actions: ["""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)

# 번역 파일: homeTipSleepSub 줄 다음에 3줄 넣기
arb_out = {}
for lang, (t1, t2, t3) in T.items():
    p = os.path.join(D, f'app_{lang}.arb')
    if not os.path.exists(p):
        print(f'❌ {p} 파일이 없어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    a = open(p, 'rb').read().decode('utf-8')
    if '"homeTipNameTitle"' in a:
        continue
    nl = '\r\n' if '\r\n' in a else '\n'
    m = re.search(r'^([ \t]*)"homeTipSleepSub"\s*:\s*"(?:[^"\\]|\\.)*",[ \t]*\r?\n', a, re.M)
    if not m:
        print(f'❌ {lang}: homeTipSleepSub 줄을 못 찾았어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    ind = m.group(1)
    add = ''.join(f'{ind}"{k}": {json.dumps(v, ensure_ascii=False)},{nl}' for k, v in
                  [('homeTipNameTitle', t1), ('homeTipNameSub', t2), ('homeTipNameAction', t3)])
    a2 = a[:m.end()] + add + a[m.end():]
    try:
        j = json.loads(a2)
        assert j['homeTipNameTitle'] == t1 and j['homeTipNameAction'] == t3
    except Exception:
        print(f'❌ {lang}: 넣은 뒤 파일 확인 실패. 아무것도 저장 안 했어요.'); sys.exit(1)
    arb_out[p] = a2
    print('✔ 번역', lang)

if crlf: s = s.replace('\n', '\r\n')
open(H, 'wb').write(s.encode('utf-8'))
for p, a2 in arb_out.items():
    open(p, 'wb').write(a2.encode('utf-8'))
print('저장했어요.')
