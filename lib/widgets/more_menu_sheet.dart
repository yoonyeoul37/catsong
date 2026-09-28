import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../screens/settings_screen.dart';

const String _kStoreUrl =
    'https://play.google.com/store/apps/details?id=kr.ssing.catsong';

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
    }) {
  final isDarkMode = context.read<ThemeProvider>().isDarkMode;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73000000),
    builder: (ctx) => _MoreMenuSheet(
      isDarkMode: isDarkMode,
      shareSubtitle: shareSubtitle,
      hasHomepage: stationHomepage != null && stationHomepage.isNotEmpty,
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
    bars: Color(0x522F7DE8),
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
    bars: Color(0x576FB0FF),
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

  const _MoreMenuSheet({
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
                _MenuCard(
                  p: p,
                  icon: Icons.share_outlined,
                  title: '친구에게 공유하기',
                  subtitle: shareSubtitle,
                  onTap: onShare,
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  p: p,
                  icon: Icons.star_outline_rounded,
                  title: '앱 평가하기',
                  subtitle: '좋은 평가가 큰 힘이 됩니다.',
                  onTap: onRate,
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  p: p,
                  icon: Icons.settings_outlined,
                  title: '설정',
                  subtitle: '앱 환경을 설정해요.',
                  onTap: onSettings,
                ),
                if (hasHomepage) ...[
                  const SizedBox(height: 12),
                  _MenuCard(
                    p: p,
                    icon: Icons.language_rounded,
                    title: '방송국 홈페이지',
                    subtitle: '공식 홈페이지로 이동해요.',
                    onTap: onHomepage,
                  ),
                ],
                const SizedBox(height: 18),
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
                child: Icon(Icons.close_rounded, size: 16, color: p.closeIcon),
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
  final IconData icon;
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
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: radius,
        border: Border.all(color: p.cardBorder, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.iconBg,
                  ),
                  child: Icon(icon, size: 21, color: p.accent),
                ),
                const SizedBox(width: 14),
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.desc, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 22, color: p.chevron),
              ],
            ),
          ),
        ),
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
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.brandBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.cardBorder, width: 0.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PARANSORI',
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '오늘도 파란소리와 함께',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.title,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '당신의 하루에 편안한 소리를 더합니다.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.desc, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (showBars) ...[
                const SizedBox(width: 12),
                _SoundBars(color: p.bars),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SoundBars extends StatelessWidget {
  final Color color;
  const _SoundBars({required this.color});

  static const List<double> _heights = [
    10.0, 18.0, 28.0, 16.0, 34.0, 22.0, 30.0, 14.0, 20.0,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < _heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: 3,
              height: _heights[i],
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}