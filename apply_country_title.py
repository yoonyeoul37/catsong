# -*- coding: utf-8 -*-
# 나라별 라디오 화면: 회색 '나라 선택' 상자 없애고 → 위쪽 'Radio' 아래 설명 자리에 '🇺🇸 USA ▾'
#  (위쪽 로고 전체를 누르면 나라 고르기로) — 다른 화면 서브 문구는 그대로
import os, sys

WIDGET = os.path.join('lib', 'widgets', 'logo_shine.dart')
COUNTRY = os.path.join('lib', 'screens', 'radio_country_stations_screen.dart')

W_EDITS = [
    ('MenuTitle: 설명 자리에 다른 것(나라) 넣기 · 누르기 받기',
     """  final bool isDark;
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark});
""",
     """  final bool isDark;
  final Widget? subWidget; // 설명 글 대신 넣을 것 (나라별 라디오: 국기 + 나라 ▾)
  final VoidCallback? onTap; // 누르면 (나라별 라디오: 나라 고르기)
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark, this.subWidget, this.onTap});
"""),
    ('MenuTitle: 누르기',
     """    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
""",
     """    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
"""),
    ('MenuTitle: 설명 자리',
     """              // 설명 한 줄: 긴 언어는 넘치지 않게 살짝 작아짐
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  shortSub,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(color: base.withOpacity(0.5), fontSize: 11.5, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
""",
     """              // 설명 한 줄 (또는 넣어 준 것): 긴 언어는 넘치지 않게 살짝 작아짐
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: subWidget ??
                    Text(
                      shortSub,
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(color: base.withOpacity(0.5), fontSize: 11.5, height: 1.2),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: row);
  }
}
"""),
]

C_EDITS = [
    ('위쪽 설명 자리에 국기 + 나라 ▾ (누르면 나라 고르기)',
     "            Flexible(child: MenuTitle(title: tr.catRadio, sub: tr.catRadioSub, isDark: isDarkMode)),\n",
     """            Flexible(
              child: MenuTitle(
                title: tr.catRadio,
                sub: tr.catRadioSub,
                isDark: isDarkMode,
                // 이 화면은 설명 대신 '지금 보는 나라' — 누르면 나라 고르기
                subWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.country.flag,
                        textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 12, height: 1.2)),
                    const SizedBox(width: 4),
                    Text(widget.country.displayName,
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.6), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: baseColor.withOpacity(0.5)),
                  ],
                ),
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
                  );
                },
              ),
            ),
"""),
]
BOX = ("            // 나라 선택 상자 (국내 라디오 상자와 같은 모양) — 누르면 나라 고르기\n", "            if (_showSearch) Padding(\n")

def load(p):
    raw = open(p, 'rb').read()
    crlf = b'\r\n' in raw
    return raw.decode('utf-8').replace('\r\n', '\n'), crlf

def apply(t, edits, ok):
    for name, old, new in edits:
        n = t.count(old)
        if n == 1:
            t = t.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok[0] = False
    return t

def main():
    for p in (WIDGET, COUNTRY):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    w, wc = load(WIDGET); c, cc = load(COUNTRY)
    if 'subWidget' in w and 'subWidget: Row(' in c:
        print('이미 적용돼 있어요'); return 0
    ok = [True]
    w = apply(w, W_EDITS, ok)
    c = apply(c, C_EDITS, ok)
    s = c.find(BOX[0]); e = c.find(BOX[1])
    if s != -1 and e != -1 and s < e:
        c = c[:s] + c[e:]; print('✔ 회색 나라 선택 상자 지우기')
    else:
        print('❌ 회색 나라 선택 상자 지우기'); ok[0] = False
    for name, t in (('logo_shine.dart', w), ('radio_country_stations_screen.dart', c)):
        for o, cl in ['()', '[]', '{}']:
            if t.count(o) != t.count(cl):
                print('❌', name, ': 괄호 개수가 안 맞아요', o, cl); ok[0] = False
    if not ok[0]:
        print('\n아무것도 저장하지 않았어요.'); return 1
    for p, t, crlf in ((WIDGET, w, wc), (COUNTRY, c, cc)):
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요 (2개 파일)')
    return 0

if __name__ == '__main__':
    sys.exit(main())
