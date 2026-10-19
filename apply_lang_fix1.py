# -*- coding: utf-8 -*-
# 새 언어 폰 확인 1차 고침
#  ① 곡 목록 '새로 들어온 곡'·초성 머리글: 글자가 크면 아래가 잘림 → 칸에 맞게 살짝 줄여서 다 보이게
#  ② 홈 '이 소리들 어때요?' 제목: 길면 넘침(헝가리어) → 한 줄에 맞게 살짝 줄이기
#  ③ 헝가리어 문구 짧게: 제목·색 카드
import os, sys, re, json
sys.stdout.reconfigure(encoding='utf-8')

def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)

H = os.path.join('lib', 'screens', 'home_screen.dart')
HU = os.path.join('lib', 'l10n', 'app_hu.arb')
for p in (H, HU):
    if not os.path.exists(p): fail('파일을 못 찾았어요: ' + p)

raw = open(H, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n')
if '// 글자가 크면 칸에 맞게 살짝 줄임 (아래 잘림 막기)' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ("'새로 들어온 곡' 머리글 잘림",
  """        child: Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 7,""",
  """        child: Align(
          alignment: Alignment.bottomLeft,
          child: FittedBox( // 글자가 크면 칸에 맞게 살짝 줄임 (아래 잘림 막기)
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 7,"""),
 ("'새로 들어온 곡' 머리글 닫기",
  """              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 목록 안 초성 머리글""",
  """              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// 목록 안 초성 머리글"""),
 ("초성 머리글 잘림",
  """        child: Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                group,""",
  """        child: Align(
          alignment: Alignment.bottomLeft,
          child: FittedBox( // 글자가 크면 칸에 맞게 살짝 줄임
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                group,"""),
 ("초성 머리글 닫기",
  """              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  bool _isSelectionMode = false;""",
  """              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
  bool _isSelectionMode = false;"""),
 ("홈 소리 제목 넘침",
  """              Builder(builder: (_) {
                final h = tr.homeSoundsHeader;""",
  """              Flexible(child: FittedBox( // 긴 언어(헝가리어 등)는 한 줄에 맞게 살짝 줄임
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Builder(builder: (_) {
                final h = tr.homeSoundsHeader;"""),
 ("홈 소리 제목 닫기",
  """                          color: pointColorOf(context), fontSize: 20, height: 1.0, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              }),
            ],
          ),""",
  """                          color: pointColorOf(context), fontSize: 20, height: 1.0, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              }),
              )),
            ],
          ),"""),
]
o = s
for name, old, new in edits:
    n = s.count(old)
    if n != 1: fail(f'{name} — 찾을 코드를 못 찾았어요 ({n}곳)')
    s = s.replace(old, new); print('✔ home_screen.dart ·', name)
for a, b in ['()', '[]', '{}']:
    if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'괄호 {a}{b} 짝이 안 맞아요')

# 헝가리어 문구
hraw = open(HU, 'rb').read().decode('utf-8'); hs = hraw
hu_new = {
    'homeSoundsHeader': 'Milyenek ezek a hangok?',
    'homeColorTitle': 'Válassz színt',
    'homeColorAction': 'Mehet',
}
for k, v in hu_new.items():
    pat = re.compile(r'("' + k + r'"\s*:\s*)"(?:[^"\\]|\\.)*"')
    if len(pat.findall(hs)) != 1: fail(f'app_hu.arb · {k} 를 못 찾았어요')
    hs = pat.sub(lambda m: m.group(1) + json.dumps(v, ensure_ascii=False), hs)
    print('✔ app_hu.arb ·', k, '→', v)
try: json.loads(hs)
except Exception as e: fail(f'app_hu.arb JSON 오류: {e}')

open(H, 'wb').write((s.replace('\n', '\r\n') if crlf else s).encode('utf-8'))
open(HU, 'wb').write(hs.encode('utf-8'))
print('저장했어요.')
