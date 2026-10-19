# -*- coding: utf-8 -*-
# 메뉴 첫 화면 제목 아래 작은 영문 대문자 (C안): 라디오 → RADIO · 자연 → NATURE · 휴식·집중 → REST · FOCUS
# 홈 로고(파란소리 / PARANSORI)처럼 제목 폭에 맞춰 고르게 벌림 — 나라별 라디오(국기 + 나라 ▾)는 그대로
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'widgets', 'logo_shine.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_capsFor(' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ('불러오기',
  """import '../utils/title_font.dart';
""",
  """import '../utils/title_font.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/locale_holder.dart';
"""),
 ('메뉴마다 영문 대문자',
  """  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white : Colors.black;
    // 위쪽은 이름표라서""",
  """  /// 제목 아래 작은 영문 대문자 (홈 로고 PARANSORI처럼) — 제목이 이미 같은 영어면(Radio) PARANSORI
  String? _capsFor() {
    String? c;
    if (title == tr.catRadio) c = 'RADIO';
    if (title == tr.catNature) c = 'NATURE';
    if (title == tr.catRest) c = 'REST·FOCUS';
    if (c == null) return null;
    final plain = title.toUpperCase().replaceAll(RegExp(r'[\\s·・]'), '');
    return plain == c.replaceAll('·', '') ? 'PARANSORI' : c;
  }

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white : Colors.black;
    final caps = subWidget == null ? _capsFor() : null;
    // 위쪽은 이름표라서"""),
 ('제목 폭에 맞추기 (시작)',
  """        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [""",
  """        Flexible(
          child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: caps != null ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: ["""),
 ('설명 한 줄 → 영문 대문자',
  """              // 설명 한 줄 (또는 넣어 준 것): 긴 언어는 넘치지 않게 살짝 작아짐
              FittedBox(""",
  """              // C안: 작은 영문 대문자를 제목 폭에 맞춰 고르게 (홈 로고 PARANSORI와 같은 짜임)
              if (caps != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 1, right: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final ch in caps.split(''))
                        Text(ch,
                            textScaler: TextScaler.noScaling,
                            style: GoogleFonts.quicksand(
                                color: base.withOpacity(0.55),
                                fontSize: 9,
                                height: 1.0,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
              // 설명 한 줄 (또는 넣어 준 것): 긴 언어는 넘치지 않게 살짝 작아짐
              FittedBox("""),
 ('제목 폭에 맞추기 (끝)',
  """              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return row;""",
  """              ),
            ],
          ),
          ),
        ),
      ],
    );
    if (onTap == null) return row;"""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)
if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
