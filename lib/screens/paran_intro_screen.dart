import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_holder.dart';
import '../providers/theme_provider.dart';
import '../utils/point_color.dart';

/// 파란소리 소개 화면 (홈 ⋮ 메뉴 → 파란소리 소개)
/// 글은 5개 언어(한국어 · 영어 · 일본어 · 번체 · 간체)로 이 파일 안에 있어요.
/// 한국어 폰은 한국용 글, 나머지는 외국용 글('파란 + 소리' 뜻풀이)이 나와요.
class ParanIntroScreen extends StatefulWidget {
  const ParanIntroScreen({super.key});

  @override
  State<ParanIntroScreen> createState() => _ParanIntroScreenState();
}

class _ParanIntroScreenState extends State<ParanIntroScreen> {
  // 사진을 지나 위로 올렸는지 → 상태바 자리를 바탕색으로 가리고 아이콘을 어둡게
  final _covered = ValueNotifier(false);

  @override
  void dispose() {
    _covered.dispose();
    super.dispose();
  }

  static const _heroPhoto = 'assets/rest_wave.jpg';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = _IntroText.fromTr(); // 글은 번역 파일 (intro…)
    final point = pointColorOf(context);

    // ── 화면 공통 색 (곡 정보 수정 화면 등과 같은 베이지 · 흰 카드 · 먹색) ──
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF32302C) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final body = isDark ? const Color(0xFFDCD5C8) : const Color(0xFF3A342B);
    final soft = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);
    final sub = isDark ? const Color(0xFF9C9486) : const Color(0xFF8A8378);
    final line = isDark ? const Color(0xFF433F39) : const Color(0xFFEFE8DB);
    final band = isDark ? const Color(0xFF2C2A26) : const Color(0xFFEDE5D6);

    final top = MediaQuery.paddingOf(context).top;
    const heroH = 230.0;

    TextStyle bodyStyle([Color? c]) => TextStyle(color: c ?? body, fontSize: 14.5, height: 1.75);

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 34, bottom: 6),
          child: Text(text,
              style: TextStyle(
                  color: point, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
        );
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text,
              style: TextStyle(
                  color: ink, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.35)),
        );
    Widget para(String text, {Color? color, double gap = 12}) => Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Text(text, style: bodyStyle(color)),
        );

    return ValueListenableBuilder<bool>(
      valueListenable: _covered,
      builder: (context, covered, _) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // 사진 위는 흰 아이콘 · 사진을 지나면 (라이트 모드) 어두운 아이콘
        statusBarIconBrightness: covered && !isDark ? Brightness.dark : Brightness.light,
        statusBarBrightness: covered && !isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: band,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                final c = n.metrics.pixels > heroH - top - 8;
                if (c != _covered.value) _covered.value = c;
                return false;
              },
              child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 맨 위 사진 + 로고 ──
                  SizedBox(
                    height: heroH + top,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isDark
                            ? ColorFiltered(colorFilter: _kDarkPhotoFilter, child: Image.asset(_heroPhoto, fit: BoxFit.cover))
                            : Image.asset(_heroPhoto, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.18), bg.withOpacity(0), bg],
                              stops: const [0, 0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 14,
                          child: Column(
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
                        ),
                      ],
                    ),
                  ),

                  // ── 첫 인사 (시처럼 가운데) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // 화면 폭 전체 → 글이 가운데로
                      children: [
                        Text(t.question,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, height: 1.5)),
                        const SizedBox(height: 12),
                        Text(t.poem,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: soft, fontSize: 14.5, height: 1.9)),
                        if (t.started.isNotEmpty) ...[
                          Center(
                            child: Container(
                              width: 26,
                              height: 2,
                              margin: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                  color: point.withOpacity(0.5), borderRadius: BorderRadius.circular(1)),
                            ),
                          ),
                          Text(t.started, textAlign: TextAlign.center, style: bodyStyle()),
                        ] else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 이름 이야기 (외국용은 '파란 + 소리' 뜻풀이) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.nameLabel,
                                  style: TextStyle(color: point, fontSize: 12.5, fontWeight: FontWeight.w700)),
                              if (t.showHangul) ...[
                                const SizedBox(height: 12),
                                _HangulName(ink: ink, sub: sub, point: point),
                              ],
                              const SizedBox(height: 10),
                              Text(t.nameStory, style: TextStyle(color: soft, fontSize: 13.5, height: 1.75)),
                            ],
                          ),
                        ),

                        // ── 소리와 함께하는 일상 ──
                        label('EVERYDAY'),
                        heading(t.everydayTitle),
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.only(left: 14),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: point.withOpacity(0.35), width: 2)),
                          ),
                          child: Text(t.moments, style: TextStyle(color: soft, fontSize: 14, height: 1.85)),
                        ),
                        para(t.everyday1),
                        para(t.everyday2, color: soft, gap: 0),

                        // ── 파란소리에서 만나는 소리 ──
                        label('SOUNDS'),
                        heading(t.soundsTitle),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
                          child: Column(
                            children: [
                              for (var i = 0; i < t.features.length; i++)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    border: i == t.features.length - 1
                                        ? null
                                        : Border(bottom: BorderSide(color: line, width: 0.8)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: point.withOpacity(isDark ? 0.16 : 0.10),
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        child: Icon(_featureIcons[i], color: point, size: 19),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.features[i].$1,
                                                style: TextStyle(
                                                    color: ink, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                                            const SizedBox(height: 3),
                                            Text(t.features[i].$2,
                                                style: TextStyle(color: sub, fontSize: 13, height: 1.6)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ── 파란소리가 전하고 싶은 마음 ──
                        label('OUR WISH'),
                        heading(t.wishTitle),
                        para(t.wish1),
                        para(t.wish2, color: soft, gap: 0),
                        const SizedBox(height: 34),
                      ],
                    ),
                  ),

                  // ── 마무리 띠 ──
                  Container(
                    width: double.infinity,
                    color: band,
                    padding: EdgeInsets.fromLTRB(28, 30, 28, 28 + MediaQuery.paddingOf(context).bottom),
                    child: Column(
                      children: [
                        Text(t.closing1,
                            textAlign: TextAlign.center, style: TextStyle(color: body, fontSize: 14, height: 1.8)),
                        Text(t.closing2,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.8)),
                        const SizedBox(height: 16),
                        Row(
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
                        const SizedBox(height: 12),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snap) => Text(
                            snap.hasData ? 'KNEXM · ${t.version} ${snap.data!.version}' : 'KNEXM',
                            style: TextStyle(color: sub, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),

            // ── 사진을 지나 올리면 상태바 자리를 바탕색으로 (글이 시계·배터리와 안 겹치게) ──
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: top,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: covered ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: ColoredBox(color: bg),
                ),
              ),
            ),

            // ── 뒤로 (사진 위에 떠 있는 동그란 버튼) ──
            Positioned(
              left: 12,
              top: top + 8,
              child: Material(
                color: Colors.black.withOpacity(0.22),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.pop(context);
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  static const _featureIcons = [
    Icons.music_note_rounded,
    Icons.public_rounded,
    Icons.eco_rounded,
    Icons.nightlight_round,
    Icons.tune_rounded,
    Icons.alarm_rounded,
  ];

}

// 다크 모드 사진 필터 (홈 화면 사진과 같은 값: 72% 밝기 · 45% 채도)
const ColorFilter _kDarkPhotoFilter = ColorFilter.matrix(<double>[
  0.4082, 0.2832, 0.0286, 0, 0,
  0.0842, 0.6072, 0.0286, 0, 0,
  0.0842, 0.2832, 0.3526, 0, 0,
  0, 0, 0, 1, 0,
]);

/// 로고 옆 작은 소리 막대 (천천히 물결처럼 움직임)
class _Bars extends StatefulWidget {
  final Color color;
  final double height;
  const _Bars({required this.color, required this.height});

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> with SingleTickerProviderStateMixin {
  static const _ratios = [0.45, 0.8, 1.0, 0.62];
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 폰에서 "애니메이션 줄이기"를 켜 두면 멈춘 모양 그대로
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

  @override
  Widget build(BuildContext context) {
    final w = widget.height >= 16 ? 3.5 : 3.0;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _ratios.length; i++) ...[
              if (i > 0) SizedBox(width: w * 0.7),
              Container(
                width: w,
                height: widget.height *
                    (_c.isAnimating
                        ? (0.35 + 0.65 * (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi + i * 1.1)))
                            .clamp(0.3, 1.0)
                        : _ratios[i]),
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(w)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 외국용 이름 칸: 파란 + 소리 (blue + sound)
class _HangulName extends StatelessWidget {
  final Color ink, sub, point;
  const _HangulName({required this.ink, required this.sub, required this.point});

  @override
  Widget build(BuildContext context) {
    Widget part(String ko, String roman, String mean, Color c) => Column(
          children: [
            Text(ko, style: TextStyle(color: c, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(roman, style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text(mean, style: TextStyle(color: sub, fontSize: 11.5)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        part('파란', 'paran', 'blue', point),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('+', style: TextStyle(color: sub, fontSize: 22, fontWeight: FontWeight.w300)),
        ),
        part('소리', 'sori', 'sound', ink),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 글 — 번역 파일(intro…)에서 가져옴 (새 언어는 번역 파일에만 추가)
// ─────────────────────────────────────────────────────────────
class _IntroText {
  final String title, tagline, question, poem, started;
  final String nameLabel, nameStory;
  final bool showHangul;
  final String everydayTitle, moments, everyday1, everyday2;
  final String soundsTitle;
  final List<(String, String)> features; // 순서: 음악 · 라디오 · 자연 · 휴식 · 조합 · 알람
  final String wishTitle, wish1, wish2;
  final String closing1, closing2, sign, version;

  const _IntroText({
    required this.title,
    required this.tagline,
    required this.question,
    required this.poem,
    required this.started,
    required this.nameLabel,
    required this.nameStory,
    required this.showHangul,
    required this.everydayTitle,
    required this.moments,
    required this.everyday1,
    required this.everyday2,
    required this.soundsTitle,
    required this.features,
    required this.wishTitle,
    required this.wish1,
    required this.wish2,
    required this.closing1,
    required this.closing2,
    required this.sign,
    required this.version,
  });

  /// 번역 파일(intro…)에서 글 가져오기 — 이름 풀이(파란+소리)는 한국어가 아닐 때만
  static _IntroText fromTr() {
    final l = tr;
    return _IntroText(
      title: l.introTitle,
      tagline: l.introTagline,
      question: l.introQuestion,
      poem: l.introPoem,
      nameLabel: l.introNameLabel,
      nameStory: l.introNameStory,
      started: l.localeName.startsWith('ko') ? l.introStarted : '', // 이 줄은 한국용 글에만
      showHangul: !l.localeName.startsWith('ko'),
      everydayTitle: l.introEverydayTitle,
      moments: l.introMoments,
      everyday1: l.introEveryday1,
      everyday2: l.introEveryday2,
      soundsTitle: l.introSoundsTitle,
      features: [
        (l.introFeature1Title, l.introFeature1Desc),
        (l.introFeature2Title, l.introFeature2Desc),
        (l.introFeature3Title, l.introFeature3Desc),
        (l.introFeature4Title, l.introFeature4Desc),
        (l.introFeature5Title, l.introFeature5Desc),
        (l.introFeature6Title, l.introFeature6Desc),
      ],
      wishTitle: l.introWishTitle,
      wish1: l.introWish1,
      wish2: l.introWish2,
      closing1: l.introClosing1,
      closing2: l.introClosing2,
      sign: l.introSign,
      version: l.introVersion,
    );
  }
}

/// ⋮ 메뉴의 '파란소리 소개' 줄 글자 (5개 언어)
(String, String) paranIntroMenuText() => (tr.introMenuTitle, tr.introMenuDesc);
