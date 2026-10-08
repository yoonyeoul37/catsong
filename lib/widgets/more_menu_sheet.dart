import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/bulk_clean_screen.dart';
import '../screens/bulk_art_screen.dart';

const String _kStoreUrl =
    'https://play.google.com/store/apps/details?id=kr.ssing.catsong';

// ─────────────────────────────────────────────────────────────
// 가는 선 아이콘 (시안과 같은 모양). 색은 그릴 때 정한다.
// ─────────────────────────────────────────────────────────────
const String _kIconShare =
    '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/>'
    '<circle cx="18" cy="19" r="3"/>'
    '<line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/>'
    '<line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/>';
const String _kIconStar =
    '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 '
    '5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>';
const String _kIconGear =
    '<circle cx="12" cy="12" r="3"/>'
    '<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>';
const String _kIconGlobe =
    '<circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>'
    '<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>';
const String _kIconChevron = '<polyline points="9 18 15 12 9 6"/>';
const String _kIconImage =
    '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>'
    '<polyline points="21 15 16 10 5 21"/>';
const String _kIconSparkle =
    '<path d="M12 3l1.9 5.8L20 10.7l-5.8 1.9L12 18.4l-1.9-5.8L4 10.7l6.1-1.9z"/>'
    '<path d="M19 3v4M17 5h4"/>';
const String _kIconClose =
    '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>';

class _LineIcon extends StatelessWidget {
  final String body;
  final double size;
  final Color color;
  final double stroke;

  const _LineIcon(
      this.body, {
        required this.size,
        required this.color,
        this.stroke = 1.7,
      });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
          'stroke="#000000" stroke-width="$stroke" stroke-linecap="round" '
          'stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// 더보기(⋮) 메뉴 시트. 홈 / 자연소리 / 라디오 화면이 함께 쓴다.
///
/// [shareText]       : 친구에게 공유할 때 보낼 문구 (스토어 주소는 자동으로 붙는다)
/// [shareSubtitle]   : 공유 카드에 보이는 짧은 설명
/// [stationHomepage] : 라디오 재생 화면에서만 넘긴다. 주소가 있으면
///                     "방송국 홈페이지" 줄이 하나 더 나온다.
void showMoreMenuSheet(
    BuildContext context, {
      String shareText = '파란소리 앱으로 음악 들어요! 🎧',
      String shareSubtitle = '파란소리를 소개해보세요.',
      String? stationHomepage,
      bool showSongTools = false, // 홈에서만: 곡 정보 한꺼번에 정리
    }) {
  final isDarkMode = context.read<ThemeProvider>().isDarkMode;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73000000),
    builder: (ctx) => AnnotatedRegion<SystemUiOverlayStyle>(
      // 메뉴가 열려 있는 동안 하단 시스템바를 메뉴 색에 맞춤
      value: SystemUiOverlayStyle(
        systemNavigationBarColor:
            isDarkMode ? const Color(0xFF1F1B15) : const Color(0xFFF4EFE5),
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: _MoreMenuSheet(
      isDarkMode: isDarkMode,
      shareSubtitle: shareSubtitle,
      hasHomepage: stationHomepage != null && stationHomepage.isNotEmpty,
      showSongTools: showSongTools,
      onCleanSongs: () {
        Navigator.pop(ctx);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCleanScreen()));
      },
      onFindArt: () {
        Navigator.pop(ctx);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkArtScreen()));
      },
      onShare: () {
        Navigator.pop(ctx);
        Share.share('$shareText\n$_kStoreUrl');
      },
      onRate: () async {
        Navigator.pop(ctx);
        final uri = Uri.parse(_kStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      onSettings: () {
        Navigator.pop(ctx);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },
      onHomepage: () async {
        Navigator.pop(ctx);
        final url = stationHomepage;
        if (url == null || url.isEmpty) return;
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// 색 (라이트 / 다크)
// 베이지 + 흰색이 기본이고, 파랑은 아이콘·작은 글자·음파 막대에만 쓴다.
// ─────────────────────────────────────────────────────────────
class _Pal {
  final Color sheet;
  final Color card;
  final Color cardBorder;
  final Color cardShadow;
  final Color iconBg;
  final Color accent;
  final Color title;
  final Color desc;
  final Color chevron;
  final Color handle;
  final Color closeBg;
  final Color closeIcon;
  final Color brandBg;
  final Color bars;

  const _Pal({
    required this.sheet,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.iconBg,
    required this.accent,
    required this.title,
    required this.desc,
    required this.chevron,
    required this.handle,
    required this.closeBg,
    required this.closeIcon,
    required this.brandBg,
    required this.bars,
  });

  static const light = _Pal(
    sheet: Color(0xFFF4EFE5),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0x0F3C2D14),
    cardShadow: Color(0x1446371E),
    iconBg: Color(0x172F7DE8),
    accent: Color(0xFF2F7DE8),
    title: Color(0xFF1A1A1A),
    desc: Color(0xFF8A8378),
    chevron: Color(0xFFB9B2A5),
    handle: Color(0x2E3C2D14),
    closeBg: Color(0x123C2D14),
    closeIcon: Color(0xFF6E675B),
    brandBg: Color(0xFFF8F4EC),
    bars: Color(0x802F7DE8),
  );

  static const dark = _Pal(
    sheet: Color(0xFF1F1B15),
    card: Color(0xFF2A251D),
    cardBorder: Color(0x12FFFFFF),
    cardShadow: Color(0x59000000),
    iconBg: Color(0x1F6FB0FF),
    accent: Color(0xFF6FB0FF),
    title: Color(0xFFF3EFE7),
    desc: Color(0xFFA29A8B),
    chevron: Color(0xFF786F61),
    handle: Color(0x33FFFFFF),
    closeBg: Color(0x14FFFFFF),
    closeIcon: Color(0xFFB9B1A3),
    brandBg: Color(0xFF26221A),
    bars: Color(0x856FB0FF),
  );
}

// ─────────────────────────────────────────────────────────────
// 시트 전체
// ─────────────────────────────────────────────────────────────
class _MoreMenuSheet extends StatelessWidget {
  final bool isDarkMode;
  final String shareSubtitle;
  final bool hasHomepage;
  final VoidCallback onShare;
  final VoidCallback onRate;
  final VoidCallback onSettings;
  final VoidCallback onHomepage;
  final bool showSongTools;
  final VoidCallback onCleanSongs;
  final VoidCallback onFindArt;

  const _MoreMenuSheet({
    required this.showSongTools,
    required this.onCleanSongs,
    required this.onFindArt,
    required this.isDarkMode,
    required this.shareSubtitle,
    required this.hasHomepage,
    required this.onShare,
    required this.onRate,
    required this.onSettings,
    required this.onHomepage,
  });

  @override
  Widget build(BuildContext context) {
    final p = isDarkMode ? _Pal.dark : _Pal.light;
    // 글자 크기를 크게 해둔 폰에서도 카드가 깨지지 않게 조금만 허용한다.
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Container(
        decoration: BoxDecoration(
          color: p.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBar(p: p),
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
                _BrandCard(p: p),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 손잡이 + 닫기(X)
class _TopBar extends StatelessWidget {
  final _Pal p;
  const _TopBar({required this.p});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.closeBg,
                ),
                child: _LineIcon(_kIconClose, size: 15, color: p.closeIcon, stroke: 2.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 공유 / 평가 / 설정 카드
class _MenuCard extends StatelessWidget {
  final _Pal p;
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.p,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
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

// 브랜드 영역 (문구 + 아주 은은한 음파 막대)
class _BrandCard extends StatelessWidget {
  final _Pal p;
  const _BrandCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // 좁은 폰에서는 음파 막대를 빼서 글자가 잘리지 않게 한다.
        final showBars = c.maxWidth >= 300;
        // 먹색 카드 (다크 모드는 크림색) — 설정 화면 맨 위 카드와 한 세트
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
        );
      },
    );
  }
}

class _SoundBars extends StatefulWidget {
  final Color color;
  const _SoundBars({required this.color});

  @override
  State<_SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<_SoundBars>
    with SingleTickerProviderStateMixin {
  static const List<double> _heights = [
    10.0, 18.0, 28.0, 16.0, 34.0, 22.0, 30.0, 14.0, 20.0,
  ];

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 폰에서 "애니메이션 줄이기"를 켜둔 경우에는 움직이지 않는다.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _barHeight(int i) {
    final t = _c.value * 2 * math.pi + i * 0.85;
    final wave = 0.5 + 0.5 * math.sin(t);
    return (_heights[i] * (0.55 + 0.75 * wave)).clamp(6.0, 38.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < _heights.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Container(
                  width: 3,
                  height: _c.isAnimating ? _barHeight(i) : _heights[i],
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}