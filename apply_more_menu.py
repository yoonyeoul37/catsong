# -*- coding: utf-8 -*-
# 홈 ⋮ 메뉴 다듬기: 흰 카드 하나로 묶기(연한 구분선) · 아이콘 베이지 칸 · 먹색 Paransori 카드
import os, re, sys
P = os.path.join('lib', 'widgets', 'more_menu_sheet.dart')
if not os.path.exists(P):
    sys.exit('❌ more_menu_sheet.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_MenuGroup' in s:
    sys.exit('이미 적용돼 있어요.')

def rep(pattern, new, name, regex=False):
    global s
    if regex:
        m = list(re.finditer(pattern, s, re.S))
        if len(m) != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({len(m)}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s[:m[0].start()] + new + s[m[0].end():]
    else:
        n = s.count(pattern)
        if n != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s.replace(pattern, new)
    print(f'✔ {name}')

# 1) 글꼴
rep("import 'package:flutter_svg/flutter_svg.dart';\n",
    "import 'package:flutter_svg/flutter_svg.dart';\nimport 'package:google_fonts/google_fonts.dart';\n", '불러오기')

# 2) 메뉴 목록: 흰 카드 하나로 묶기
GROUP = r"""_TopBar(p: p),
                _MenuGroup(p: p, children: [
                  if (showSongTools) ...[
                    _MenuCard(
                      p: p,
                      icon: _kIconSparkle,
                      title: '곡 정보 한꺼번에 정리',
                      subtitle: '지저분한 제목·가수를 깔끔하게 정리해요.',
                      onTap: onCleanSongs,
                    ),
                    _MenuCard(
                      p: p,
                      icon: _kIconImage,
                      title: '앨범 사진 한꺼번에 찾기',
                      subtitle: '앨범 사진 없는 곡에 사진을 넣어요.',
                      onTap: onFindArt,
                    ),
                  ],
                  _MenuCard(
                    p: p,
                    icon: _kIconShare,
                    title: '친구에게 공유하기',
                    subtitle: shareSubtitle,
                    onTap: onShare,
                  ),
                  _MenuCard(
                    p: p,
                    icon: _kIconStar,
                    title: '앱 평가하기',
                    subtitle: '좋은 평가가 큰 힘이 됩니다.',
                    onTap: onRate,
                  ),
                  _MenuCard(
                    p: p,
                    icon: _kIconGear,
                    title: '설정',
                    subtitle: '앱 환경을 설정해요.',
                    onTap: onSettings,
                  ),
                  if (hasHomepage)
                    _MenuCard(
                      p: p,
                      icon: _kIconGlobe,
                      title: '방송국 홈페이지',
                      subtitle: '공식 홈페이지로 이동해요.',
                      onTap: onHomepage,
                    ),
                ]),
                const SizedBox(height: 12),
                _BrandCard(p: p),"""
rep(r"_TopBar\(p: p\),\n.*?const SizedBox\(height: 18\),\n\s*_BrandCard\(p: p\),", GROUP, '흰 카드 하나로', regex=True)

# 3) 줄 하나: 카드 껍데기 없이 + 아이콘 베이지 칸
ROW = r"""  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          alignment: Alignment.center,
          child: Row(
            children: [
              // 아이콘 베이지 칸 (다른 메뉴들과 같은 모양)
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.sheet,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _LineIcon(icon, size: 18, color: p.closeIcon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.desc, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _LineIcon(_kIconChevron, size: 18, color: p.chevron, stroke: 2.0),
            ],
          ),
        ),
      ),
    );
  }
}

// 흰 카드 하나에 줄들을 묶기 (줄 사이 아주 연한 구분선)
class _MenuGroup extends StatelessWidget {
  final _Pal p;
  final List<Widget> children;
  const _MenuGroup({required this.p, required this.children});

  @override
  Widget build(BuildContext context) {
    // 구분선: 아주 연하게 (라이트는 베이지 살짝, 다크는 흰색 살짝)
    final line = p.sheet.computeLuminance() > 0.5 ? const Color(0x0D3C2D14) : const Color(0x0DFFFFFF);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.cardBorder, width: 0.6),
        boxShadow: [BoxShadow(color: p.cardShadow, blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 0.6, margin: const EdgeInsets.only(left: 60), color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}
"""
rep(r"  @override\n  Widget build\(BuildContext context\) \{\n    final radius = BorderRadius\.circular\(18\);\n.*?\n  \}\n\}\n", ROW, '줄 모양', regex=True)

# 4) 브랜드 칸 → 먹색 Paransori 카드 (설정 화면과 한 세트)
BRAND = r"""        // 먹색 카드 (다크 모드는 크림색) — 설정 화면 맨 위 카드와 한 세트
        final dark = p.sheet.computeLuminance() < 0.5;
        final bg = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
        final fg = dark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
        final blue = dark ? const Color(0xFF2589E8) : const Color(0xFF7FB8F0);
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
          ),
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
                      style: GoogleFonts.quicksand(
                          color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '오늘도 파란소리와 함께',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '당신의 하루에 편안한 소리를 더합니다.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg.withOpacity(0.65), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (showBars) ...[
                const SizedBox(width: 12),
                _SoundBars(color: blue.withOpacity(0.8)),
              ],
            ],
          ),
        );"""
rep(r"        return Container\(\n          width: double\.infinity,\n          constraints: const BoxConstraints\(minHeight: 96\),.*?\n        \);(?=\n      \},\n    \);\n  \}\n\}\n\nclass _SoundBars)", BRAND, '브랜드 카드', regex=True)

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)
print('\n✅ 끝! 메뉴가 흰 카드 하나 + 먹색 Paransori 카드로 바뀌었어요.')
