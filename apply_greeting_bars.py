# -*- coding: utf-8 -*-
# 첫인사·끝인사 소리 막대 맞추기 + 첫인사 랜덤 인사말 한 줄
import os, sys, shutil

def find(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

JOBS = {}

# ───────── main.dart (첫인사) ─────────
JOBS['main.dart'] = [
('첫인사 - 숨 쉬기를 끝인사와 같은 방식으로',
"""        if (mounted) _p.repeat(reverse: true);""",
"""        if (mounted) _p.repeat(); // 끝인사와 같은 숨 쉬기 (1.1초마다 한 번)"""),
('첫인사 - 랜덤 인사말 고르기',
"""  bool _started = false;

  // 소리 파형: 막대 20개 높이""",
"""  bool _started = false;
  // 켤 때마다 인사말 한 줄을 무작위로
  final String _line = _greetingLines[Random().nextInt(5)];
  String get _greet {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final i = _greetingLines.indexOf(_line);
    return ko ? _line : _greetingLinesEn[i];
  }

  // 소리 파형: 막대 20개 높이"""),
('첫인사 - 막대 색 (낮 버전: 같은 색을 조금 진하게)',
"""                                  color: Color.lerp(_barColors[i], const Color(0xFF17140F), 0.45),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],""",
"""                                  // 낮 버전: 끝인사와 같은 색을 조금 진하게 (밝은 사진 위에서 보이게)
                                  color: Color.lerp(_barColors[i], const Color(0xFF17140F), 0.35),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],"""),
('첫인사 - 막대 아래 인사말 한 줄',
"""                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );""",
"""                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 인사말 한 줄 (끝인사 한 줄과 같은 자리·크기)
                    Builder(builder: (_) {
                      final s = _seg(2.4, 3.2, Curves.easeOutCubic);
                      return Opacity(
                        opacity: s,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - s)),
                          child: Text(
                            _greet,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF17140F).withOpacity(0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        );"""),
('첫인사 - 인사말 목록 추가',
"""class _WavePainter extends CustomPainter {""",
"""/// 첫인사 인사말 (켤 때마다 하나씩 무작위) — 번역할 때 일본어·중국어 추가
const _greetingLines = <String>[
  '오늘도 좋은 소리와 함께해요',
  '반가워요, 잠시 쉬어가요',
  '편안한 하루 되세요',
  '오늘 하루도 반가워요',
  '마음이 쉬어가는 곳, 파란소리',
];
const _greetingLinesEn = <String>[
  'Welcome back',
  'Good sounds, good day',
  'Take a moment for yourself',
  'Your sounds are waiting',
  'Relax and listen',
];

class _WavePainter extends CustomPainter {"""),
]

# ───────── farewell_title.dart (끝인사) ─────────
JOBS['farewell_title.dart'] = [
('끝인사 - 막대를 가운데 기준으로 (첫인사와 같게)',
"""                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,""",
"""                          mainAxisAlignment: MainAxisAlignment.center,"""),
('끝인사 - 막대 색 (밤 버전: 같은 색 그대로 밝게 + 그림자)',
"""                                    decoration: BoxDecoration(
                                      color: _barColors[i],
                                      borderRadius: BorderRadius.circular(3),
                                    ),""",
"""                                    decoration: BoxDecoration(
                                      // 밤 버전: 첫인사와 같은 색을 밝게 (어두운 사진 위에서 보이게)
                                      color: _barColors[i],
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),"""),
]

MARK = {'main.dart': '_greetingLinesEn', 'farewell_title.dart': '밤 버전: 첫인사와 같은 색'}

results = {}
all_ok = True
already = 0
for name, edits in JOBS.items():
    p = find(name)
    if not p:
        print('❌ lib 폴더에서 %s 를 못 찾았어요' % name)
        all_ok = False
        continue
    src, crlf = load(p)
    if MARK[name] in src:
        print('%s: 이미 적용돼 있어요' % name)
        already += 1
        continue
    for label, old, new in edits:
        if src.count(old) != 1:
            print('❌ %s (찾은 개수 %d)' % (label, src.count(old)))
            all_ok = False
            continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    results[name] = (p, src, crlf)

if already == len(JOBS):
    sys.exit(0)
if not all_ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요')
    sys.exit(1)
for name, (p, src, crlf) in results.items():
    shutil.copyfile(p, p + '.bak')
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
    print('저장했어요: %s (원본은 .bak)' % p)
