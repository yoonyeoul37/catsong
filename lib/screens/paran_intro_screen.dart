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
class ParanIntroScreen extends StatelessWidget {
  const ParanIntroScreen({super.key});

  static const _heroPhoto = 'assets/rest_wave.jpg';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = _IntroText.of(_langIndex());
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // 위는 사진이라 흰 아이콘
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: band,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            SingleChildScrollView(
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

  /// 폰 언어 → 0 한국어 · 1 영어 · 2 일본어 · 3 번체 · 4 간체
  static int _langIndex() {
    final n = AppLocale.current?.localeName ?? 'ko';
    if (n.startsWith('ko')) return 0;
    if (n.startsWith('ja')) return 2;
    if (n.startsWith('zh')) {
      return (n.contains('Hant') || n.contains('TW') || n.contains('HK')) ? 3 : 4;
    }
    return 1;
  }
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
// 글 (5개 언어) — 새 언어를 넣을 때 여기에 하나 더 추가
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

  static _IntroText of(int lang) => switch (lang) {
        0 => _ko,
        2 => _ja,
        3 => _tw,
        4 => _cn,
        _ => _en,
      };

  // ── 한국어 (한국용) ──
  static const _ko = _IntroText(
    title: '파란소리',
    tagline: 'Paransori — 일상에 맑음을 더하다.',
    question: '소리에도 색이 있다면,\n어떤 색일까요?',
    poem: '파란 하늘처럼 맑고,\n시원한 바람처럼 상쾌하고,\n잔잔한 바다처럼 편안한 소리.',
    started: '파란소리는 그런 소리를 담고 싶은\n마음에서 시작되었습니다.',
    nameLabel: '이름 이야기',
    nameStory: "'파란소리'라는 이름에는 맑은 하늘과 푸른 바다가 주는 청량함, 시원한 바람이 전하는 상쾌함, "
        '그리고 자연 속에서 느끼는 편안함을 담았습니다.',
    showHangul: false,
    everydayTitle: '소리와 함께하는 일상',
    moments: '바쁜 하루 중 잠시 쉬어가고 싶을 때,\n좋아하는 음악이 생각날 때,\n새로운 라디오 방송을 만나고 싶을 때,\n'
        '자연의 소리와 함께 조용한 시간을 보내고 싶을 때.',
    everyday1: '파란소리는 일상의 다양한 순간에 가볍게 함께하고 싶습니다.',
    everyday2: '음악 한 곡, 익숙한 라디오 방송, 잔잔한 빗소리 하나가 평범한 하루를 조금 더 기분 좋게 만들어 줄 수 있으니까요. '
        '그래서 파란소리는 복잡하지 않고, 누구나 쉽고 즐겁게 사용할 수 있는 공간을 만들어가고 있습니다.',
    soundsTitle: '파란소리에서 만나는 소리',
    features: [
      ('나만의 음악', '휴대폰에 저장된 음악을 느긋하게 감상하며, 좋아하는 노래로 나만의 시간을 채워보세요.'),
      ('세계의 라디오', '다양한 나라의 라디오 방송을 들으며 새로운 음악과 이야기, 세상의 소리를 만나보세요.'),
      ('자연의 소리', '빗소리, 바람 소리, 숲의 소리 등 자연이 들려주는 편안한 소리를 즐겨보세요.'),
      ('휴식과 집중', '잠들기 전 조용한 시간부터 집중이 필요한 순간까지, 지금 나에게 어울리는 소리를 찾아보세요.'),
      ('나만의 소리 조합', '좋아하는 소리들을 함께 재생하며 나만의 분위기를 만들어보세요.'),
      ('아침 알람', '좋아하는 노래, 라디오, 자연의 소리로 기분 좋게 하루를 시작해 보세요.'),
    ],
    wishTitle: '파란소리가 전하고 싶은 마음',
    wish1: '좋아하는 소리를 듣는 시간은 생각보다 우리 가까이에 있습니다. '
        '아침을 시작할 때도, 일하는 중에도, 하루를 마무리하는 조용한 밤에도.',
    wish2: '한국에서 시작된 파란소리가 이제 세계 여러 곳의 사람들과 함께하며, '
        '저마다의 일상에 작은 즐거움과 여유를 더할 수 있기를 바랍니다.',
    closing1: '언제 어디서나 편안하게 찾을 수 있는 소리의 공간.',
    closing2: '당신의 하루가 조금 더 맑아지도록.',
    sign: '파란소리, Paransori.',
    version: '버전',
  );

  // ── 영어 (외국용) ──
  static const _en = _IntroText(
    title: 'Paransori',
    tagline: 'Adding clarity to your everyday.',
    question: 'If sound had a color,\nwhat would it be?',
    poem: 'Clear as a blue sky,\nfresh as a cool breeze,\ncalm as a gentle sea.',
    started: '',
    nameLabel: 'About the name',
    nameStory: "Paransori comes from two Korean words, 'paran' and 'sori'. 'Paran' means blue, bringing to mind "
        "clear skies and the deep blue sea. 'Sori' means sound. The name carries our wish to share, through sound, "
        'the freshness of a clear sky, the coolness of a gentle breeze, and the comfort we feel in nature.',
    showHangul: true,
    everydayTitle: 'Sound in your everyday',
    moments: 'When you need a short break in a busy day,\nwhen a favorite song comes to mind,\n'
        'when you want to discover a new radio station,\nwhen you want a quiet moment with the sounds of nature.',
    everyday1: 'Paransori hopes to be there, lightly, in all the different moments of your day.',
    everyday2: 'A single song, a familiar radio show, the soft patter of rain — any of these can make an ordinary day '
        "a little brighter. That's why we're building a space that's simple, easy and enjoyable for everyone.",
    soundsTitle: "Sounds you'll find in Paransori",
    features: [
      ('Your music', 'Relax with the music saved on your phone and fill your time with the songs you love.'),
      ('World radio', 'Tune in to stations from many countries and discover new music, stories and sounds from around the world.'),
      ('Sounds of nature', 'Enjoy the soothing sounds of nature — rain, wind, the forest and more.'),
      ('Rest & focus', 'From quiet moments before sleep to times when you need to focus, find the sound that suits you right now.'),
      ('Your own sound mix', "Play your favorite sounds together and create a mood that's all yours."),
      ('Morning alarm', 'Start your day on a good note with your favorite song, radio or the sounds of nature.'),
    ],
    wishTitle: 'What Paransori hopes to share',
    wish1: 'Time spent listening to the sounds you love is closer than you think — as your morning begins, '
        'while you work, and on quiet nights as the day winds down.',
    wish2: 'Paransori began in Korea and now joins people all around the world. '
        'We hope it adds a little joy and ease to each of your days.',
    closing1: 'A space for sound you can turn to anytime, anywhere.',
    closing2: 'So your day can be a little clearer.',
    sign: 'Paransori.',
    version: 'Version',
  );

  // ── 일본어 (외국용) ──
  static const _ja = _IntroText(
    title: 'Paransori',
    tagline: '毎日に、澄んだひとときを。',
    question: '音にも色があるとしたら、\nどんな色でしょう？',
    poem: '青空のように澄んでいて、\n涼しい風のように爽やかで、\n穏やかな海のようにやすらぐ音。',
    started: '',
    nameLabel: '名前の由来',
    nameStory: 'Paransori（파란소리）は、韓国語の「パラン（파란）」と「ソリ（소리）」から生まれた名前です。'
        '「パラン」は青を意味し、澄んだ空と青い海を思わせます。「ソリ」は私たちが耳にする音のことです。'
        'この名前には、澄んだ空の清々しさ、涼しい風の爽やかさ、そして自然の中で感じるやすらぎを、音で届けたいという想いが込められています。',
    showHangul: true,
    everydayTitle: '音とともにある毎日',
    moments: '忙しい一日の中で、少しひと息つきたいとき、\n好きな音楽を聴きたくなったとき、\n'
        '新しいラジオ番組に出会いたいとき、\n自然の音とともに静かな時間を過ごしたいとき。',
    everyday1: 'Paransoriは、毎日のさまざまな瞬間に、気軽に寄り添いたいと思っています。',
    everyday2: '一曲の音楽、聴き慣れたラジオ番組、静かな雨音ひとつが、いつもの一日を少しだけ心地よくしてくれるから。'
        'だからParansoriは、複雑ではなく、誰もが簡単に楽しく使える場所を目指しています。',
    soundsTitle: 'Paransoriで出会える音',
    features: [
      ('自分だけの音楽', 'スマホに保存した音楽をゆったりと楽しみ、好きな曲で自分だけの時間を満たしましょう。'),
      ('世界のラジオ', 'さまざまな国のラジオ番組を聴きながら、新しい音楽や物語、世界の音に出会いましょう。'),
      ('自然の音', '雨音、風の音、森の音など、自然が聞かせてくれるやすらぎの音を楽しみましょう。'),
      ('休息と集中', '眠る前の静かな時間から集中したいときまで、今の自分に合う音を見つけましょう。'),
      ('自分だけのサウンドミックス', '好きな音を一緒に流して、自分だけの雰囲気をつくりましょう。'),
      ('朝のアラーム', '好きな曲やラジオ、自然の音で、気持ちよく一日を始めましょう。'),
    ],
    wishTitle: 'Paransoriが伝えたい想い',
    wish1: '好きな音を聴く時間は、思っているよりもずっと身近にあります。'
        '朝を迎えるときも、仕事の合間にも、一日を締めくくる静かな夜にも。',
    wish2: '韓国で生まれたParansoriが、いま世界のさまざまな場所の人々とともに、'
        'それぞれの毎日に小さな楽しさとゆとりを添えられたらうれしいです。',
    closing1: 'いつでも、どこでも、気軽に立ち寄れる音の場所。',
    closing2: 'あなたの一日が、もう少し澄みわたりますように。',
    sign: 'Paransori.',
    version: 'バージョン',
  );

  // ── 중국어 번체 (외국용) ──
  static const _tw = _IntroText(
    title: 'Paransori',
    tagline: '為日常增添一份清澈。',
    question: '如果聲音也有顏色，\n會是什麼顏色呢？',
    poem: '像藍天一樣清澈，\n像涼風一樣清爽，\n像平靜的大海一樣安寧的聲音。',
    started: '',
    nameLabel: '名字的由來',
    nameStory: 'Paransori（파란소리）這個名字來自韓語中的「파란（Paran）」和「소리（Sori）」。'
        '「Paran」意為藍色，讓人聯想到晴朗的天空和蔚藍的大海；「Sori」則是我們所聽到的聲音。'
        '這個名字承載著我們的心願：用聲音傳遞晴空的清爽、涼風的舒暢，以及置身大自然時的安寧。',
    showHangul: true,
    everydayTitle: '與聲音相伴的日常',
    moments: '在忙碌的一天中想稍作休息時，\n想起喜歡的音樂時，\n想遇見新的電台節目時，\n想與大自然的聲音一起度過安靜時光時。',
    everyday1: 'Paransori 希望在日常的各種時刻，輕鬆地陪伴在你身邊。',
    everyday2: '因為一首歌、一檔熟悉的電台節目、一陣輕柔的雨聲，都能讓平凡的一天變得更美好一些。'
        '所以 Paransori 一直努力打造一個簡單、人人都能輕鬆愉快使用的空間。',
    soundsTitle: '在 Paransori 遇見的聲音',
    features: [
      ('我的音樂', '悠閒地欣賞手機裡儲存的音樂，用喜歡的歌曲填滿屬於自己的時光。'),
      ('世界電台', '收聽來自各個國家的電台節目，遇見新的音樂、故事和世界的聲音。'),
      ('大自然的聲音', '雨聲、風聲、森林的聲音……盡情享受大自然帶來的舒緩聲音。'),
      ('休息與專注', '從睡前的安靜時光到需要專注的時刻，找到此刻最適合你的聲音。'),
      ('我的聲音組合', '將喜歡的聲音一起播放，營造屬於自己的氛圍。'),
      ('早晨鬧鐘', '用喜歡的歌曲、電台或大自然的聲音，愉快地開始新的一天。'),
    ],
    wishTitle: 'Paransori 想傳達的心意',
    wish1: '聆聽喜歡的聲音的時光，其實比想像中更近。無論是開始早晨時、工作時，還是結束一天的安靜夜晚。',
    wish2: '從韓國出發的 Paransori，如今與世界各地的人們相伴，希望能為每個人的日常增添一點小小的快樂與從容。',
    closing1: '一個隨時隨地都能輕鬆找到的聲音空間。',
    closing2: '願你的一天，更清澈一些。',
    sign: 'Paransori.',
    version: '版本',
  );

  // ── 중국어 간체 (외국용) ──
  static const _cn = _IntroText(
    title: 'Paransori',
    tagline: '为日常增添一份清澈。',
    question: '如果声音也有颜色，\n会是什么颜色呢？',
    poem: '像蓝天一样清澈，\n像凉风一样清爽，\n像平静的大海一样安宁的声音。',
    started: '',
    nameLabel: '名字的由来',
    nameStory: 'Paransori（파란소리）这个名字来自韩语中的“파란（Paran）”和“소리（Sori）”。'
        '“Paran”意为蓝色，让人联想到晴朗的天空和蔚蓝的大海；“Sori”则是我们所听到的声音。'
        '这个名字承载着我们的心愿：用声音传递晴空的清爽、凉风的舒畅，以及置身大自然时的安宁。',
    showHangul: true,
    everydayTitle: '与声音相伴的日常',
    moments: '在忙碌的一天中想稍作休息时，\n想起喜欢的音乐时，\n想遇见新的电台节目时，\n想与大自然的声音一起度过安静时光时。',
    everyday1: 'Paransori 希望在日常的各种时刻，轻松地陪伴在你身边。',
    everyday2: '因为一首歌、一档熟悉的电台节目、一阵轻柔的雨声，都能让平凡的一天变得更美好一些。'
        '所以 Paransori 一直努力打造一个简单、人人都能轻松愉快使用的空间。',
    soundsTitle: '在 Paransori 遇见的声音',
    features: [
      ('我的音乐', '悠闲地欣赏手机里保存的音乐，用喜欢的歌曲填满属于自己的时光。'),
      ('世界电台', '收听来自各个国家的电台节目，遇见新的音乐、故事和世界的声音。'),
      ('大自然的声音', '雨声、风声、森林的声音……尽情享受大自然带来的舒缓声音。'),
      ('休息与专注', '从睡前的安静时光到需要专注的时刻，找到此刻最适合你的声音。'),
      ('我的声音组合', '将喜欢的声音一起播放，营造属于自己的氛围。'),
      ('早晨闹钟', '用喜欢的歌曲、电台或大自然的声音，愉快地开始新的一天。'),
    ],
    wishTitle: 'Paransori 想传达的心意',
    wish1: '聆听喜欢的声音的时光，其实比想象中更近。无论是开始早晨时、工作时，还是结束一天的安静夜晚。',
    wish2: '从韩国出发的 Paransori，如今与世界各地的人们相伴，希望能为每个人的日常增添一点小小的快乐与从容。',
    closing1: '一个随时随地都能轻松找到的声音空间。',
    closing2: '愿你的一天，更清澈一些。',
    sign: 'Paransori.',
    version: '版本',
  );
}

/// ⋮ 메뉴의 '파란소리 소개' 줄 글자 (5개 언어)
(String, String) paranIntroMenuText() => switch (ParanIntroScreen._langIndex()) {
      0 => ('파란소리 소개', '어떤 앱인지 알려드려요.'),
      2 => ('Paransoriについて', 'どんなアプリかご紹介します。'),
      3 => ('關於 Paransori', '認識這款應用程式。'),
      4 => ('关于 Paransori', '了解这款应用。'),
      _ => ('About Paransori', 'Get to know the app.'),
    };
