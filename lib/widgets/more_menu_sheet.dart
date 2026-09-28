import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../screens/settings_screen.dart';

const String _kStoreUrl =
    'https://play.google.com/store/apps/details?id=kr.ssing.catsong';

const List<Shadow> _kTextShadow = [
  Shadow(color: Color(0x59143C8C), blurRadius: 8, offset: Offset(0, 2)),
];

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
    barrierColor: Colors.black.withOpacity(0.45),
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
    final d = isDarkMode;
    // 그림처럼 크기가 정해진 화면이라, 글자 크기 확대는 조금만 허용한다.
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: d
                ? const [Color(0xFF18232F), Color(0xFF111A23)]
                : const [Color(0xFFF9FCFF), Color(0xFFEEF5FD)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 30,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: d
                                  ? const Color(0x33FFFFFF)
                                  : const Color(0xFFB4CBE7),
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: d
                                  ? const Color(0x1FFFFFFF)
                                  : const Color(0xFFE3ECF7),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: d
                                  ? Colors.white70
                                  : const Color(0xFF5F7FA9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(builder: (context, c) {
                      final w = c.maxWidth;
                      const gap = 12.0;
                      final leftW = (w - gap) * 0.618;
                      final rightW = w - gap - leftW;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 232,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: leftW,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 150,
                                        child: _ShareCard(
                                          dark: d,
                                          subtitle: shareSubtitle,
                                          onTap: onShare,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 70,
                                        child: _SettingsCard(
                                            dark: d, onTap: onSettings),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: gap),
                                SizedBox(
                                  width: rightW,
                                  height: 232,
                                  child: _RateCard(dark: d, onTap: onRate),
                                ),
                              ],
                            ),
                          ),
                          if (hasHomepage) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 52,
                              child: _HomepageBar(dark: d, onTap: onHomepage),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(height: 128, child: _BrandCard(dark: d)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ① 친구에게 공유하기 : 큰 카드, 오른쪽 위만 크게 둥근 잎사귀 모양
// ─────────────────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final bool dark;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareCard({
    required this.dark,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : const Color(0xFF0F2A52);
    final subColor = dark ? const Color(0x99FFFFFF) : const Color(0xFF6B7C93);
    final pillBg = dark ? const Color(0x333B8BEB) : const Color(0xFFDCEBFD);
    final pillFg = dark ? const Color(0xFF8DBFFF) : const Color(0xFF2A6FD6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(62),
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF223449), Color(0xFF1B2B3E), Color(0xFF162535)]
                : const [Color(0xFFFFFFFF), Color(0xFFE9F4FE), Color(0xFFCDE4FB)],
            stops: const [0.0, 0.52, 1.0],
          ),
          border: Border.all(
            color: dark ? const Color(0x1FFFFFFF) : const Color(0x334690E6),
          ),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x59000000) : const Color(0x212F73DE),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ShareDecoPainter(dark: dark)),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF55A2F4), Color(0xFF2C6FDC)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x612F73DE),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -math.pi / 6,
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '친구에게 공유하기',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '공유하기',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: pillFg,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 12, color: pillFg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ② 앱 평가하기 : 세로로 긴 아치 카드, 큰 별과 별점 말풍선
// ─────────────────────────────────────────────────────────────
class _RateCard extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;

  const _RateCard({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : const Color(0xFF0F2A52);
    final subColor = dark ? const Color(0x99FFFFFF) : const Color(0xFF6B7C93);
    final bubbleBg = dark ? const Color(0xFF2B3440) : Colors.white;
    final pillBg = dark ? const Color(0x33FFC940) : const Color(0xFFFFF0C7);
    final pillFg = dark ? const Color(0xFFFFD36B) : const Color(0xFFB27604);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(66),
            topRight: Radius.circular(66),
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [
              Color(0xFF3A3018),
              Color(0xFF262A2D),
              Color(0xFF1E2630),
              Color(0xFF1A2430),
            ]
                : const [
              Color(0xFFFFF3D2),
              Color(0xFFFFFBEF),
              Color(0xFFFFFFFF),
              Color(0xFFEDF5FE),
            ],
            stops: const [0.0, 0.28, 0.52, 1.0],
          ),
          border: Border.all(
            color: dark ? const Color(0x40F5B028) : const Color(0x52F5B028),
          ),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x59000000) : const Color(0x29F5AA1E),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 별 뒤의 은은한 빛
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFCE48)
                              .withOpacity(dark ? 0.30 : 0.42),
                          const Color(0x00FFCE48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _RateDecoPainter(dark: dark)),
            ),
            // 큰 별
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE485), Color(0xFFFFAE1A)],
                  ).createShader(rect),
                  child: const Icon(Icons.star_rounded,
                      size: 54, color: Colors.white),
                ),
              ),
            ),
            // 별점 말풍선
            Positioned(
              top: 78,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -3,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                            width: 8, height: 8, color: bubbleBg),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bubbleBg,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: dark
                                ? const Color(0x33000000)
                                : const Color(0x211E4682),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                              (i) => Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                            child: const Icon(Icons.star_rounded,
                                size: 12, color: Color(0xFFFFB81F)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 112,
              left: 0,
              right: 0,
              child: Text(
                '앱 평가하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: titleColor,
                ),
              ),
            ),
            Positioned(
              top: 135,
              left: 0,
              right: 0,
              child: Text(
                '좋은 평가가\n큰 힘이 됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.45, color: subColor),
              ),
            ),
            Positioned(
              top: 172,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '평가하기',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: pillFg,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12, color: pillFg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ③ 설정 : 얇은 가로 바, 차분한 유리 느낌
// ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;

  const _SettingsCard({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : const Color(0xFF0F2A52);
    final subColor = dark ? const Color(0x99FFFFFF) : const Color(0xFF7A8BA0);
    final chevronBg = dark ? const Color(0x1FFFFFFF) : const Color(0xFFEAF1F9);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF212C38), Color(0xFF1A232D)]
                : const [Color(0xEBFFFFFF), Color(0xEBEEF4FB)],
          ),
          border: Border.all(
            color: dark ? const Color(0x1FFFFFFF) : const Color(0xFFDCE6F2),
          ),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x40000000) : const Color(0x123C5A82),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RingsPainter(dark: dark)),
            ),
            Positioned(
              left: 14,
              top: 13,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9DB4D3), Color(0xFF5F7FA9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x525F7FA9),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              left: 66,
              top: 0,
              bottom: 0,
              right: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '앱 환경을 설정해요',
                      style: TextStyle(fontSize: 10.5, color: subColor),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 20,
              child: Container(
                width: 26,
                height: 26,
                decoration:
                BoxDecoration(shape: BoxShape.circle, color: chevronBg),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: dark ? Colors.white70 : const Color(0xFF5F7FA9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// (라디오 재생 화면에서만) 방송국 홈페이지 한 줄
// ─────────────────────────────────────────────────────────────
class _HomepageBar extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;

  const _HomepageBar({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : const Color(0xFF0F2A52);
    final subColor = dark ? const Color(0x99FFFFFF) : const Color(0xFF7A8BA0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: dark ? const Color(0xFF1E2833) : const Color(0xF2FFFFFF),
          border: Border.all(
            color: dark ? const Color(0x1FFFFFFF) : const Color(0xFFDCE6F2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF55A2F4), Color(0xFF2C6FDC)],
                ),
              ),
              child: const Icon(Icons.language_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '방송국 홈페이지',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '공식 홈페이지로 이동해요',
                    style: TextStyle(fontSize: 10.5, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 16,
                color: dark ? Colors.white54 : const Color(0xFF5F7FA9)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ④ 파란소리 브랜드 : 노을 하늘, 바다, 헤드폰
// ─────────────────────────────────────────────────────────────
class _BrandCard extends StatelessWidget {
  final bool dark;

  const _BrandCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [
            Color(0xFF1F62BE),
            Color(0xFF2F7BD3),
            Color(0xFF5B9DE2),
            Color(0xFF9CC8F0),
          ]
              : const [
            Color(0xFF2A7DE6),
            Color(0xFF4C98F0),
            Color(0xFF7FBBF6),
            Color(0xFFC9E5FB),
          ],
          stops: const [0.0, 0.48, 0.76, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x472A7DE6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        // 오른쪽 헤드폰과 겹치지 않게 글자 영역 폭을 제한한다.
        final textW = math.max(120.0, w - 18 - 22 - 92 - 8);
        return Stack(
          children: [
            // 노을 빛
            const Positioned(
              right: 18,
              top: 34,
              width: 150,
              height: 150,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xEBFFF6DE),
                      Color(0x80FFEEC4),
                      Color(0x00FFEEC4),
                    ],
                    stops: [0.0, 0.45, 0.96],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _BrandScenePainter(dark: dark)),
            ),
            Positioned(
              right: 22,
              bottom: 20,
              width: 92,
              height: 88,
              child: CustomPaint(painter: _HeadphonesPainter()),
            ),
            const Positioned(
              right: 16,
              top: 14,
              child: Icon(Icons.music_note_rounded,
                  size: 22, color: Colors.white),
            ),
            Positioned(
              left: 18,
              top: 15,
              width: textW,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '오늘도',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xF0FFFFFF),
                      shadows: _kTextShadow,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    '파란소리와 함께',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Colors.white,
                      shadows: _kTextShadow,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '좋은 음악이 있는 일상을 만들어가요.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xF0FFFFFF),
                      shadows: _kTextShadow,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 18,
              bottom: 11,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '파란소리',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: _kTextShadow,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'paransori',
                    style: TextStyle(
                      fontSize: 7.5,
                      letterSpacing: 2.6,
                      color: Color(0xE0FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// 배경 그래픽 (CustomPainter)
// ═════════════════════════════════════════════════════════════

void _drawDashed(
    Canvas canvas, Path path, Paint paint, double dash, double gap) {
  for (final metric in path.computeMetrics()) {
    double d = 0;
    while (d < metric.length) {
      final end = math.min(d + dash, metric.length);
      canvas.drawPath(metric.extractPath(d, end), paint);
      d += dash + gap;
    }
  }
}

/// 공유 카드: 아래 물결, 날아가는 점선 궤적, 하트, 반짝이
class _ShareDecoPainter extends CustomPainter {
  final bool dark;

  _ShareDecoPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 214.0, size.height / 150.0);

    final wave1 = Paint()
      ..color = const Color(0xFF5AA0F0).withOpacity(dark ? 0.16 : 0.15);
    final wave2 = Paint()
      ..color = const Color(0xFF5AA0F0).withOpacity(dark ? 0.12 : 0.13);

    final p1 = Path()
      ..moveTo(0, 122)
      ..cubicTo(36, 104, 78, 136, 118, 118)
      ..cubicTo(158, 100, 188, 114, 214, 106)
      ..lineTo(214, 150)
      ..lineTo(0, 150)
      ..close();
    canvas.drawPath(p1, wave1);

    final p2 = Path()
      ..moveTo(0, 134)
      ..cubicTo(44, 120, 92, 146, 140, 130)
      ..cubicTo(176, 118, 198, 126, 214, 122)
      ..lineTo(214, 150)
      ..lineTo(0, 150)
      ..close();
    canvas.drawPath(p2, wave2);

    // 점선 궤적
    final trail = Path()
      ..moveTo(22, 44)
      ..cubicTo(58, 14, 104, 58, 152, 30);
    _drawDashed(
      canvas,
      trail,
      Paint()
        ..color = const Color(0xFF2F73DE).withOpacity(dark ? 0.6 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
      3,
      5,
    );

    // 하트
    final heart = Path()
      ..moveTo(104, 25.5)
      ..cubicTo(102.4, 23.2, 99, 23.6, 98.4, 26.3)
      ..cubicTo(97.9, 28.7, 100.7, 30.5, 104, 33)
      ..cubicTo(107.3, 30.5, 110.1, 28.7, 109.6, 26.3)
      ..cubicTo(109, 23.6, 105.6, 23.2, 104, 25.5)
      ..close();
    canvas.drawPath(heart, Paint()..color = const Color(0xFF7DB6F5));

    // 반짝이
    final sp = Paint()
      ..color = const Color(0xFF5AA0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(150, 16), const Offset(147, 12), sp);
    canvas.drawLine(const Offset(158, 10), const Offset(158, 5), sp);
    canvas.drawLine(const Offset(143, 24), const Offset(138, 22), sp);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShareDecoPainter old) => old.dark != dark;
}

/// 평가 카드: 아래 물결, 별 주변 반짝이
class _RateDecoPainter extends CustomPainter {
  final bool dark;

  _RateDecoPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 132.0, size.height / 232.0);

    final wave = Path()
      ..moveTo(0, 214)
      ..cubicTo(26, 202, 52, 224, 82, 210)
      ..cubicTo(104, 200, 120, 204, 132, 200)
      ..lineTo(132, 232)
      ..lineTo(0, 232)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..color = const Color(0xFF64A5F0).withOpacity(dark ? 0.16 : 0.17),
    );

    final sp = Paint()
      ..color = const Color(0xFFFFBE3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(24, 30), const Offset(19, 25), sp);
    canvas.drawLine(const Offset(20, 42), const Offset(13, 42), sp);
    canvas.drawLine(const Offset(110, 30), const Offset(115, 24), sp);
    canvas.drawLine(const Offset(114, 40), const Offset(121, 39), sp);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RateDecoPainter old) => old.dark != dark;
}

/// 설정 카드: 오른쪽에 퍼지는 은은한 동심원
class _RingsPainter extends CustomPainter {
  final bool dark;

  _RingsPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = dark ? const Color(0x0FFFFFFF) : const Color(0x297896BE);
    final c = Offset(size.width - 18, size.height / 2);
    for (final r in const [18.0, 30.0, 42.0, 54.0]) {
      canvas.drawCircle(c, r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.dark != dark;
}

/// 브랜드 카드: 구름, 바다, 물결, 햇빛 반사
class _BrandScenePainter extends CustomPainter {
  final bool dark;

  _BrandScenePainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 358.0, size.height / 128.0);

    void cloud(double tx, double ty, double s, double opacity) {
      final p = Path()
        ..moveTo(0, 12)
        ..cubicTo(0, 6, 5, 3, 10, 5)
        ..cubicTo(12, 0, 20, 0, 22, 5)
        ..cubicTo(28, 3, 34, 7, 32, 12)
        ..close();
      canvas.save();
      canvas.translate(tx, ty);
      canvas.scale(s);
      canvas.drawPath(p, Paint()..color = Colors.white.withOpacity(opacity));
      canvas.restore();
    }

    cloud(262, 20, 1.6, 0.9);
    cloud(10, 80, 1.2, 0.5);

    // 바다
    final seaRect = Rect.fromLTWH(0, 90, 358, 38);
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF3F86D6), Color(0xFF2A6CC0)]
              : const [Color(0xFF63AEF3), Color(0xFF3B8AE4)],
        ).createShader(seaRect),
    );

    // 물결선
    void waveLine(double y, double opacity) {
      final p = Path()..moveTo(0, y);
      double x = 0;
      bool up = true;
      while (x < 360) {
        p.quadraticBezierTo(x + 9, up ? y - 4 : y + 4, x + 18, y);
        x += 18;
        up = !up;
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    waveLine(100, 0.5);
    waveLine(113, 0.3);

    // 햇빛 반사
    final shimmer = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(244, 108), const Offset(266, 108), shimmer);
    canvas.drawLine(const Offset(256, 114), const Offset(290, 114), shimmer);
    canvas.drawLine(const Offset(248, 120), const Offset(274, 120), shimmer);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandScenePainter old) => old.dark != dark;
}

/// 브랜드 카드의 헤드폰
class _HeadphonesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 92.0, size.height / 88.0);

    final band = Path()
      ..moveTo(15, 46)
      ..cubicTo(15, 8, 77, 8, 77, 46);
    final leftCup = RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 40, 24, 38), const Radius.circular(12));
    final rightCup = RRect.fromRectAndRadius(
        Rect.fromLTWH(65, 40, 24, 38), const Radius.circular(12));

    // 그림자
    final shadowFill = Paint()
      ..color = const Color(0x40143C82)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final shadowStroke = Paint()
      ..color = const Color(0x40143C82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(band, shadowStroke);
    canvas.drawRRect(leftCup, shadowFill);
    canvas.drawRRect(rightCup, shadowFill);
    canvas.restore();

    // 바다에 비친 빛
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(46, 83), width: 80, height: 8),
      Paint()..color = Colors.white.withOpacity(0.35),
    );

    // 본체
    canvas.drawPath(
      band,
      Paint()
        ..color = const Color(0xFFEAF4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    final cupPaint = Paint()..color = const Color(0xFFF4F9FF);
    canvas.drawRRect(leftCup, cupPaint);
    canvas.drawRRect(rightCup, cupPaint);
    final inner = Paint()..color = const Color(0xFF8FC0F4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(7, 47, 14, 24), const Radius.circular(7)),
      inner,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(71, 47, 14, 24), const Radius.circular(7)),
      inner,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}