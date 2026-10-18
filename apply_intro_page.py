# -*- coding: utf-8 -*-
# 파란소리 소개
#  ① ⋮ 메뉴 설명 '어떤 앱인지 알려드려요.' → '파란소리에 담긴 이야기를 만나보세요' (16개 언어, 앱 이름은 각 파일 appName)
#  ② 소개 페이지 맨 위: 소리 막대 빼고 → 앱 아이콘 + '파란소리'(도현) / 아래 한 줄 설명
#  ③ 맨 아래 서명 옆 소리 막대도 → 작은 앱 아이콘 (소리 막대 코드는 지움)
#  ④ 하단 시스템 바(◁ ○ |||) 자리를 따로 띠로 나눠서 글이 그 아래로 안 지나가게
import os, re, sys, glob

INTRO = os.path.join('lib', 'screens', 'paran_intro_screen.dart')
L10N = os.path.join('lib', 'l10n')

# {n} = 그 언어 파일의 appName
DESC = {
    'ko': '파란소리에 담긴 이야기를 만나보세요',
    'en': 'Discover the story behind {n}',
    'ja': '{n}に込められたストーリーをご覧ください',
    'zh': '来看看{n}背后的故事',
    'zh_hant': '來看看{n}背後的故事',
    'de': 'Entdecke die Geschichte hinter {n}',
    'es': 'Descubre la historia detrás de {n}',
    'fr': "Découvrez l'histoire derrière {n}",
    'pt': 'Conheça a história por trás do {n}',
    'it': 'Scopri la storia dietro {n}',
    'ru': 'Узнайте историю {n}',
    'tr': "{n}'nin hikâyesini keşfedin",
    'pl': 'Poznaj historię aplikacji {n}',
    'id': 'Temukan cerita di balik {n}',
    'vi': 'Khám phá câu chuyện đằng sau {n}',
    'th': 'มาฟังเรื่องราวเบื้องหลัง {n}',
    'hi': '{n} के पीछे की कहानी जानें',
}

def lang_key(fname):
    loc = fname[len('app_'):-len('.arb')]
    low = loc.lower()
    if low.startswith('zh'):
        return 'zh_hant' if any(x in low for x in ('hant', 'tw', 'hk')) else 'zh'
    if low.startswith('in'):
        return 'id'
    return low.split('_')[0]

INTRO_EDITS = [
    ('글꼴(도현) 불러오기',
     "import '../utils/point_color.dart';\n",
     "import '../utils/point_color.dart';\nimport '../utils/title_font.dart';\n"),
    ('안 쓰는 dart:math 지우기',
     "import 'dart:math' as math;\n\n",
     ""),
    ('맨 위: 아이콘 + 파란소리(도현) / 설명',
     """                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: ink, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
                                  ),
                                  const SizedBox(width: 7),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: _Bars(color: point, height: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(t.tagline, style: TextStyle(color: soft, fontSize: 13.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
""",
     """                          // 홈 로고와 같은 짜임: 앱 아이콘 + 파란소리(도현) / 아래 설명 한 줄
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset('assets/logo_icon.png',
                                    width: 50, height: 50, filterQuality: FilterQuality.medium),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleFont(color: ink, fontSize: 30, letterSpacing: -0.5)),
                                    const SizedBox(height: 1),
                                    Text(t.tagline,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: soft, fontSize: 13.5, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
"""),
    ('맨 아래 서명: 소리 막대 → 작은 앱 아이콘',
     """                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(t.sign,
                                style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _Bars(color: point, height: 12),
                            ),
                          ],
                        ),
""",
     """                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.asset('assets/logo_icon.png',
                                  width: 20, height: 20, filterQuality: FilterQuality.medium),
                            ),
                            const SizedBox(width: 7),
                            Text(t.sign,
                                style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          ],
                        ),
"""),
    ('마무리 띠: 아래 여백은 시스템 바 띠가 맡음',
     "                    padding: EdgeInsets.fromLTRB(28, 30, 28, 28 + MediaQuery.paddingOf(context).bottom),\n",
     "                    padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),\n"),
    ('하단 시스템 바 자리를 따로 띠로 (글이 아래로 안 지나가게)',
     """      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
""",
     """      child: Scaffold(
        backgroundColor: bg,
        // 하단 시스템 바(◁ ○ |||) 자리: 마무리 띠와 같은 색으로 따로 두기 → 글이 그 밑으로 안 지나감
        bottomNavigationBar: Container(color: band, height: MediaQuery.paddingOf(context).bottom),
        body: Stack(
"""),
]
BARS = ("/// 로고 옆 작은 소리 막대 (천천히 물결처럼 움직임)\n", "/// 외국용 이름 칸: 파란 + 소리 (blue + sound)")

def load(p):
    raw = open(p, 'rb').read()
    crlf = b'\r\n' in raw
    return raw.decode('utf-8').replace('\r\n', '\n'), crlf

def main():
    if not os.path.exists(INTRO):
        print('❌ 파일을 못 찾았어요:', INTRO, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    arbs = sorted(glob.glob(os.path.join(L10N, 'app_*.arb')))
    if not arbs:
        print('❌ 번역 파일(lib/l10n/app_*.arb)을 못 찾았어요'); return 1
    t, tc = load(INTRO)
    done_intro = "bottomNavigationBar: Container(color: band" in t
    ok = True
    out = {}
    # ① 번역
    for p in arbs:
        a, ac = load(p)
        fn = os.path.basename(p)
        key = lang_key(fn)
        if key not in DESC:
            print('❌', fn, ': 이 언어 문장이 없어요'); ok = False; continue
        m = re.search(r'"appName"\s*:\s*"((?:[^"\\]|\\.)*)"', a)
        name = m.group(1) if m else 'Paransori'
        new = DESC[key].replace('{n}', name).replace('"', '\\"')
        pat = r'("introMenuDesc"\s*:\s*")((?:[^"\\]|\\.)*)(")'
        found = re.findall(pat, a)
        if len(found) != 1:
            print('❌', fn, ': introMenuDesc 줄을 못 찾았어요 (찾은 개수: %d)' % len(found)); ok = False; continue
        if found[0][1] == new:
            print('✔', fn, '(이미 바뀌어 있음)'); continue
        a = re.sub(pat, lambda mm: mm.group(1) + new + mm.group(3), a)
        out[p] = (a, ac)
        print('✔', fn, ':', new)
    # ②③④ 소개 페이지
    if done_intro:
        print('✔ paran_intro_screen.dart (이미 바뀌어 있음)')
    else:
        for name, old, new in INTRO_EDITS:
            n = t.count(old)
            if n == 1:
                t = t.replace(old, new); print('✔', name)
            else:
                print('❌', name, '(찾은 개수: %d)' % n); ok = False
        s = t.find(BARS[0]); e = t.find(BARS[1])
        if s != -1 and e != -1 and s < e:
            t = t[:s] + t[e:]; print('✔ 안 쓰는 소리 막대 코드(_Bars) 지우기')
        else:
            print('❌ 소리 막대 코드(_Bars) 지우기'); ok = False
        if '_Bars' in t or 'math.' in t:
            print('❌ 소리 막대나 math가 아직 남아 있어요'); ok = False
        for o, c in ['()', '[]', '{}']:
            if t.count(o) != t.count(c):
                print('❌ 괄호 개수가 안 맞아요', o, c); ok = False
        out[INTRO] = (t, tc)
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if not out:
        print('이미 적용돼 있어요'); return 0
    for p, (x, crlf) in out.items():
        if crlf: x = x.replace('\n', '\r\n')
        open(p, 'wb').write(x.encode('utf-8'))
    print('\n저장했어요 (%d개 파일)' % len(out))
    return 0

if __name__ == '__main__':
    sys.exit(main())
