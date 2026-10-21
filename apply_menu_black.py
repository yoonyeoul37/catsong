# -*- coding: utf-8 -*-
# ⋮ 메뉴: 맨 위 소개 카드를 검정으로 + 아래 검정 브랜드 카드 빼기
# (예전 apply_menu_groups.py 를 이미 돌린 경우용)
import os, sys

MENU = os.path.join('lib', 'widgets', 'more_menu_sheet.dart')

INTRO_NEW = r'''// 파란소리 소개 — 맨 위 검정 카드 (예전 아래 브랜드 카드를 합침) · 누르면 소개 화면
class _IntroCard extends StatelessWidget {
  final _Pal p;
  final VoidCallback onTap;
  const _IntroCard({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 먹색 카드 (다크 모드는 크림색) — 설정 화면 맨 위 카드와 한 세트
    final dark = p.sheet.computeLuminance() < 0.5;
    final bg = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = dark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final blue = pointColorOf(context, onDark: !dark); // 카드는 바탕과 반대 색
    final (_, subtitle) = paranIntroMenuText();
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 12, 11),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Paran', style: TextStyle(color: blue)),
                        const TextSpan(text: 'sori'),
                      ]),
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.quicksand(
                          color: fg, fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg.withOpacity(0.65), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 작은 소리 막대 (움직임)
              SizedBox(
                height: 24,
                child: FittedBox(child: _SoundBars(color: blue.withOpacity(0.8))),
              ),
              const SizedBox(width: 6),
              Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, // 아랍어에선 < 방향
                  child: _LineIcon(_kIconChevron, size: 18, color: fg.withOpacity(0.5), stroke: 2.0)),
            ],
          ),
        ),
      ),
    );
  }
}

'''


def main():
    if not os.path.exists(MENU):
        print('❌ 파일을 못 찾았어요:', MENU, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    with open(MENU, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    if '예전 아래 브랜드 카드를 합침' in text:
        print('이미 적용돼 있어요')
        return
    if '_GroupCap' not in text:
        print('❌ apply_menu_groups.py 를 먼저 돌려 주세요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    old = "                const SizedBox(height: 12),\n                _BrandCard(p: p),\n"
    if text.count(old) != 1:
        print('❌ 아래 브랜드 카드 줄을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(old, "                const SizedBox(height: 4),\n")
    print('✔ 아래 브랜드 카드 빼기')
    a = text.find("// 파란소리 소개 — 다른 메뉴와 살짝 다르게")
    b = text.find("// 흰 카드 하나에 줄들을 묶기")
    if a < 0 or b < 0 or b < a:
        print('❌ 소개 카드 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text[:a] + INTRO_NEW + text[b:]
    print('✔ 맨 위 소개 카드 검정으로')
    a = text.find("// 브랜드 영역 (문구 + 아주 은은한 음파 막대)")
    b = text.find("class _SoundBars extends StatefulWidget")
    if a < 0 or b < 0 or b < a:
        print('❌ 브랜드 카드 모양 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text[:a] + "// 작은 소리 막대 (소개 카드)\n" + text[b:]
    print('✔ 쓰지 않는 브랜드 카드 모양 지우기')
    if crlf:
        text = text.replace('\n', '\r\n')
    with open(MENU, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요')


main()
