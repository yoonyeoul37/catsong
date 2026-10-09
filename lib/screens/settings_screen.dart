import 'equalizer_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'ringtone_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/paran_toast.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/action_feedback.dart';
import 'bulk_clean_screen.dart';
import 'bulk_art_screen.dart';
import 'player_screen.dart' show showPlayerStyleMenu;
import '../utils/home_card_pref.dart';
import 'settings_help_screen.dart';
import '../services/loudness.dart';

// 화면 공통 색 (베이지 바탕 · 흰 카드 · 먹색 글자)
Color _sBg(bool d) => d ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
Color _sCard(bool d) => d ? const Color(0xFF32302C) : const Color(0xFFFFFFFF);
Color _sText(bool d) => d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color _sTextSub(bool d) => d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
Color _sTextHint(bool d) => d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
Color _sBorder(bool d) => d ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
Color _sIconBg(bool d) => d ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5);
/// 메뉴와 같은 아이콘 베이지 칸
Widget _iconBox(IconData icon, bool d) => Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: _sIconBg(d), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 17, color: _sTextSub(d)),
    );
Color _sInputBg(bool d) => d ? Colors.white.withOpacity(0.06) : const Color(0xFFEEEAE0);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFlashlightOn = false;
  bool _isSosOn = false;

  @override
  void initState() {
    super.initState();
    HomeCardPref.load();
  }

  @override
  void dispose() {
    _isSosOn = false;
    TorchLight.disableTorch();
    super.dispose();
  }

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}';
  }

  String _getFontName(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'default': return l.fontDefault;
      case 'noto_sans': return l.fontNotoSans;
      case 'jua': return l.fontJua;
      case 'gaegu': return l.fontGaegu;
      case 'nanum_gothic': return l.fontNanumGothic;
      case 'do_hyeon': return l.fontDoHyeon;
      case 'cute_font': return l.fontCuteFont;
      case 'stylish': return l.fontStylish;
      case 'sunflower': return l.fontSunflower;
      case 'hi_melody': return l.fontHiMelody;
      case 'poor_story': return l.fontPoorStory;
      case 'east_sea_dokdo': return l.fontEastSeaDokdo;
      case 'nanum_brush': return l.fontNanumBrush;
      case 'nanum_myeongjo': return l.fontNanumMyeongjo;
      case 'black_and_white': return l.fontBlackAndWhite;
      case 'gowun_dodum': return l.fontGowunDodum;
      case 'gowun_batang': return l.fontGowunBatang;
      case 'nanum_pen': return l.fontNanumPen;
      case 'single_day': return l.fontSingleDay;
      case 'yeon_sung': return l.fontYeonSung;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l = AppLocalizations.of(context)!;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: _sBg(isDarkMode),
      appBar: AppBar(
        backgroundColor: _sBg(isDarkMode),
        elevation: 0,
        title: Text(l.settings, style: TextStyle(color: _sText(isDarkMode), fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.fixedAccent, size: 20),
        ),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _sBorder(isDarkMode))),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // ── 맨 위: Paransori 카드 + 자주 켜고 끄는 3칸 ──
          _heroCard(isDarkMode),
          Consumer<ThemeProvider>(builder: (context, t, _) => _quickTiles(t)),
          // ── 꾸미기 ──
          _buildSection('꾸미기'),
          Consumer<ThemeProvider>(builder: (context, t, _) => _pointColorTile(t)),
          _buildTile(context, icon: Icons.style_outlined, title: l.playerStyle, onTap: () => _showPlayerStyleDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.font_download_outlined, title: l.fontChange, onTap: () => _showFontDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.text_fields, title: l.textSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor),
          ValueListenableBuilder<bool>(
            valueListenable: HomeCardPref.on,
            builder: (context, on, _) => _buildTile(context,
                icon: Icons.view_agenda_outlined,
                title: '홈 추천 카드',
                onTap: () => HomeCardPref.setOn(!on),
                primaryColor: primaryColor,
                isLast: true,
                trailing: Switch(value: on, onChanged: (v) => HomeCardPref.setOn(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          ),
          // ── 음악 관리 ──
          _buildSection('음악 관리'),
          _buildTile(context, icon: Icons.auto_awesome_outlined, title: '곡 정보 한꺼번에 정리',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCleanScreen())),
              primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.photo_library_outlined, title: '앨범 사진 한꺼번에 찾기',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkArtScreen())),
              primaryColor: primaryColor, isLast: true),
          // ── 도구 ──
          _buildSection('도구'),
          _buildTile(context, icon: Icons.equalizer, title: l.equalizer, onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const EqualizerScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child), transitionDuration: const Duration(milliseconds: 250))), primaryColor: primaryColor, isFirst: true),
          // 곡마다 소리 크기 맞추기 (큰 곡만 조금 줄여서 비슷하게)
          ValueListenableBuilder<bool>(
            valueListenable: Loudness.enabled,
            builder: (context, on, _) => _buildTile(context,
                icon: Icons.graphic_eq_rounded,
                title: '곡마다 소리 크기 맞추기',
                onTap: () => Loudness.setEnabled(!on),
                primaryColor: primaryColor,
                trailing: Switch(value: on, onChanged: (v) => Loudness.setEnabled(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          ),
          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone, onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const RingtoneScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child), transitionDuration: const Duration(milliseconds: 250))), primaryColor: primaryColor),
          _buildTile(context, icon: _isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off, title: l.flashlight, subtitle: _isFlashlightOn ? l.on : l.off, onTap: () => _toggleFlashlight(context), primaryColor: primaryColor,
              trailing: Switch(value: _isFlashlightOn, onChanged: (_) => _toggleFlashlight(context), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.emergency, title: l.sos, subtitle: _isSosOn ? l.sosWorking : l.sos, onTap: () => _toggleSOS(context), primaryColor: primaryColor,
              trailing: Switch(value: _isSosOn, onChanged: (_) => _toggleSOS(context), activeColor: Colors.redAccent, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.widgets_outlined, title: l.widget, onTap: () async {
            const platform = MethodChannel('kr.ssing.catsong/media');
            try { await platform.invokeMethod('requestWidgetAdd'); } catch (e) {}
          }, primaryColor: primaryColor, isLast: true),
          // ── 기타 ──
          _buildSection('기타'),
          _buildTile(context, icon: Icons.help_outline_rounded, title: '설정 도움말',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen())),
              primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.card_giftcard_outlined, title: l.promoCode, onTap: () async {
            await _showPromoCodeDialog(context);
            if (mounted) setState(() {}); // 맨 위 카드 글자도 바로 바뀌게
          }, primaryColor: primaryColor),
          _buildTile(context, icon: Icons.star_outline, title: l.rateApp, onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=kr.ssing.catsong'), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.privacy_tip_outlined, title: l.privacyPolicy, onTap: () => _launchUrl(l.privacyPolicyUrl), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.description_outlined, title: l.termsOfService, onTap: () => _launchUrl(l.termsOfServiceUrl), primaryColor: primaryColor, isLast: true),
          const SizedBox(height: 24),
          Center(child: Text('KNEXM.Co.,LTD', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
          const SizedBox(height: 8),
        ],
      ),
      ),
    );
  }

  // ───────── B안 부품 ─────────

  /// 버전 + 광고 제거 여부
  Future<(String, bool)> _heroInfo() async {
    final v = await _getAppVersion();
    final p = await SharedPreferences.getInstance();
    return (v, p.getBool('promo_unlocked') ?? false);
  }

  /// 맨 위 먹색 Paransori 카드 (다크 모드는 크림색) — 누르면 프로모션 코드
  Widget _heroCard(bool isDark) {
    final bg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    return FutureBuilder<(String, bool)>(
      future: _heroInfo(),
      builder: (context, snap) {
        final v = snap.data?.$1 ?? '';
        final noAd = snap.data?.$2 ?? false;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await _showPromoCodeDialog(context);
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                  text: 'Paran',
                                  style: TextStyle(color: isDark ? const Color(0xFF2589E8) : const Color(0xFF7FB8F0))),
                              const TextSpan(text: 'sori'),
                            ]),
                            style: GoogleFonts.quicksand(
                                color: fg, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${noAd ? '광고 없이 듣고 계세요' : '음악 · 라디오 · 자연'}${v.isEmpty ? '' : '  ·  $v'}',
                            style: TextStyle(color: fg.withOpacity(0.65), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 자주 켜고 끄는 3칸 (누르면 바로 켜짐/꺼짐)
  Widget _quickTiles(ThemeProvider t) {
    final d = t.isDarkMode;
    Widget tile(IconData icon, String label, bool on, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
              decoration: BoxDecoration(color: _sCard(d), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: on ? _sText(d) : _sIconBg(d),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: on ? _sBg(d) : _sTextSub(d)),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _sText(d), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(on ? '켜짐' : '꺼짐', style: TextStyle(color: _sTextHint(d), fontSize: 11)),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          tile(Icons.dark_mode_outlined, '다크 모드', t.isDarkMode, () => t.setDarkMode(!t.isDarkMode)),
          const SizedBox(width: 8),
          tile(Icons.water_drop_outlined, '효과음', t.feedbackSoundEnabled,
              () => t.setFeedbackSoundEnabled(!t.feedbackSoundEnabled)),
          const SizedBox(width: 8),
          tile(Icons.record_voice_over_outlined, '음성 안내', t.voiceGreetingEnabled,
              () => t.setVoiceGreetingEnabled(!t.voiceGreetingEnabled)),
        ],
      ),
    );
  }

  /// 포인트 색: 이름 + 아래 동그라미 10개 (누르면 바로 바뀜, 폰 크기에 맞춰 한 줄)
  Widget _pointColorTile(ThemeProvider t) {
    final d = t.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: _sCard(d),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(Icons.palette_outlined, d),
              const SizedBox(width: 12),
              Expanded(child: Text('포인트 색', style: TextStyle(color: _sText(d), fontSize: 14.5))),
              Text(t.pointColorName ?? '', style: TextStyle(color: _sTextHint(d), fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Row(
              children: [
                for (var i = 0; i < ThemeProvider.pointColors.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 28),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              t.setPrimaryColor(ThemeProvider.pointColors[i].$2);
                            },
                            child: Builder(builder: (_) {
                              final c = ThemeProvider.pointColors[i].$2;
                              final on = t.primaryColor.value == c.value;
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: on ? _sCard(d) : c,
                                  border: on ? Border.all(color: _sText(d), width: 2) : null,
                                ),
                                padding: on ? const EdgeInsets.all(3) : EdgeInsets.zero,
                                child: on
                                    ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c))
                                    : null,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    // 작은 회색 소제목 (다른 화면과 같은 모양)
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Text(title,
          style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTile(BuildContext context, {
    required IconData icon, required String title, String? subtitle,
    required VoidCallback onTap, required Color primaryColor,
    Widget? trailing, bool isFirst = false, bool isLast = false,
  }) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    // 같은 묶음은 흰 카드 하나로 (위·아래 끝만 둥글게)
    const r = Radius.circular(16);
    final radius = BorderRadius.vertical(top: isFirst ? r : Radius.zero, bottom: isLast ? r : Radius.zero);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: _sCard(isDarkMode), borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFirst)
                Container(height: 0.5, margin: const EdgeInsets.only(left: 58), color: _sBorder(isDarkMode)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                // 한 줄로: 아이콘 · 이름 ········ 작은 회색 글자 · 스위치/›
                child: Row(children: [
                  _iconBox(icon, isDarkMode),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _sText(isDarkMode), fontSize: 14.5)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5)),
                    ),
                  ],
                  const SizedBox(width: 6),
                  trailing ?? Icon(Icons.chevron_right_rounded, color: _sTextHint(isDarkMode), size: 20),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFlashlight(BuildContext context) async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
        setState(() => _isFlashlightOn = false);
      } else {
        if (_isSosOn) { setState(() => _isSosOn = false); await TorchLight.disableTorch(); await Future.delayed(const Duration(milliseconds: 200)); }
        await TorchLight.enableTorch();
        setState(() => _isFlashlightOn = true);
      }
    } catch (e) {
      showParanToast(context, AppLocalizations.of(context)!.flashlightError, error: true);
    }
  }

  Future<void> _toggleSOS(BuildContext context) async {
    if (_isSosOn) {
      setState(() => _isSosOn = false);
      await TorchLight.disableTorch();
    } else {
      if (_isFlashlightOn) { await TorchLight.disableTorch(); setState(() => _isFlashlightOn = false); await Future.delayed(const Duration(milliseconds: 200)); }
      setState(() => _isSosOn = true);
      _startSOS();
    }
  }

  Future<void> _startSOS() async {
    final p = [200, 200, 200, 200, 200, 400, 600, 200, 600, 200, 600, 400, 200, 200, 200, 200, 200, 800];
    while (_isSosOn && mounted) {
      for (int i = 0; i < p.length; i++) {
        if (!_isSosOn || !mounted) break;
        if (i % 2 == 0) { await TorchLight.enableTorch(); } else { await TorchLight.disableTorch(); }
        await Future.delayed(Duration(milliseconds: p[i]));
      }
    }
    if (mounted) await TorchLight.disableTorch();
  }

  /// 프로모션 코드 — 아래에서 올라오는 베이지 카드 (입력 → 틀리면 빨간 안내 → 성공하면 혜택 카드)
  Future<void> _showPromoCodeDialog(BuildContext context) async {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    var unlocked = prefs.getBool('promo_unlocked') ?? false;
    var error = false;
    if (!context.mounted) return;

    final ink = _sText(isDarkMode);
    final btnText = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    const red = Color(0xFFD84A3A);


    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _sBg(isDarkMode),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> apply() async {
          if (controller.text.trim() == '37258') {
            await prefs.setBool('promo_unlocked', true);
            // 창 닫고 가운데 알림 (다른 알림처럼 팝 → 옆으로 슝)
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              showActionFeedback(context, type: ActionFeedbackType.saved, message: '광고가 제거됐어요');
            }
          } else {
            setSheet(() => error = true);
          }
        }

        final empty = controller.text.trim().isEmpty;

        // 먹색 큰 버튼 (비어 있으면 흐리게)
        Widget bigButton(String label, VoidCallback? onTap) => SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: btnText,
                  disabledBackgroundColor: _sBorder(isDarkMode),
                  disabledForegroundColor: _sTextHint(isDarkMode),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
            );

        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 10, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 손잡이
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: _sBorder(isDarkMode), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // 제목 + ✕
              Row(
                children: [
                  Expanded(
                    child: unlocked
                        ? const SizedBox.shrink()
                        : Text(l.promoCode,
                            style: TextStyle(
                                color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: _sTextHint(isDarkMode), size: 22),
                  ),
                ],
              ),
              if (unlocked) ...[
                // ── 성공 (잡지 느낌: 작은 PARANSORI + 큰 글씨 두 줄) ──
                Text('PARANSORI',
                    style: TextStyle(
                        color: _sTextHint(isDarkMode),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text('광고 없이\n듣고 계세요',
                          style: TextStyle(
                              color: ink,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              letterSpacing: -0.5)),
                    ),
                    // 오른쪽 작은 그림 (리본 레코드판 = 선물)
                    Image.asset('assets/promo_thumb.webp', width: 116, height: 116, cacheWidth: 348),
                  ],
                ),
                const SizedBox(height: 10),
                Text('프로모션 코드 혜택이 계속 적용돼요',
                    style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5)),
                const SizedBox(height: 20),
                Divider(height: 1, thickness: 1, color: _sBorder(isDarkMode)),
                const SizedBox(height: 16),
                bigButton(l.confirm, () => Navigator.pop(ctx)),
              ] else ...[
                // ── 입력 ──
                Text(l.promoEnter, style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5)),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: _sCard(isDarkMode),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: error ? red : Colors.transparent, width: 1.5),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setSheet(() => error = false),
                          onSubmitted: (_) => apply(),
                          style: TextStyle(
                              color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 2),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '코드 입력',
                            hintStyle: TextStyle(
                                color: _sTextHint(isDarkMode).withOpacity(0.6),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0),
                          ),
                        ),
                      ),
                      // 붙여넣기 (복사해서 오는 경우가 많아서)
                      TextButton(
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          final t = (data?.text ?? '').trim();
                          if (t.isEmpty) return;
                          controller.text = t;
                          controller.selection = TextSelection.collapsed(offset: t.length);
                          setSheet(() => error = false);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _sBg(isDarkMode),
                          foregroundColor: _sTextSub(isDarkMode),
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        child: const Text('붙여넣기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                if (error) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: red, size: 15),
                      const SizedBox(width: 5),
                      Text(l.promoInvalid, style: const TextStyle(color: red, fontSize: 12)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                bigButton(l.confirm, empty ? null : apply),
              ],
            ],
          ),
        );
      }),
    );
  }


  void _showPlayerStyleDialog(BuildContext context) {
    showPlayerStyleMenu(context); // 재생화면 ⋮ 메뉴와 같은 스타일 창 (시디롬·파란포토·앨범)
  }

  void _showFontDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showParanSheet(
      context,
      title: AppLocalizations.of(context)!.fontChange,
      builder: (ctx, setSheet) => ParanCard(
        children: [
          for (final font in ThemeProvider.availableFonts)
            ParanRow(
              icon: Icons.font_download_outlined,
              title: _getFontName(context, font['key']!),
              selected: themeProvider.fontFamily == font['key'],
              onTap: () {
                themeProvider.setFontFamily(font['key']!);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (e) { await launchUrl(uri, mode: LaunchMode.inAppWebView); }
  }

  void _showColorPicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    showParanSheet(
      context,
      title: '포인트 색',
      builder: (ctx, setSheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text('체크·스위치·막대 같은 작은 곳의 색이 바뀌어요',
                style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5)),
          ),
          ParanCard(
            children: [
              for (final c in ThemeProvider.pointColors)
                InkWell(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    themeProvider.setPrimaryColor(c.$2);
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Container(width: 22, height: 22, decoration: BoxDecoration(color: c.$2, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(c.$1,
                              style: TextStyle(
                                color: _sText(isDarkMode),
                                fontSize: 14.5,
                                fontWeight: themeProvider.primaryColor.value == c.$2.value
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                        ),
                        if (themeProvider.primaryColor.value == c.$2.value)
                          Icon(Icons.check_circle_rounded, color: c.$2, size: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTextSizeDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final themeProvider = context.read<ThemeProvider>();
    const accent = AppTheme.fixedAccent;
    showParanSheet(
      context,
      title: AppLocalizations.of(context)!.textSize,
      builder: (ctx, setSheet) => Column(
        children: [
          // 미리보기
          ParanCard(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppLocalizations.of(context)!.preview,
                  style: TextStyle(color: _sText(isDarkMode), fontSize: 16 * themeProvider.textScale)),
            ],
          ),
          ParanCard(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  inactiveTrackColor: accent.withOpacity(0.2),
                  thumbColor: accent,
                ),
                child: Slider(
                  value: themeProvider.textScale.clamp(1.0, 1.5),
                  min: 1.0,
                  max: 1.5,
                  divisions: 10,
                  label: '${(themeProvider.textScale * 100).toInt()}%',
                  onChanged: (value) {
                    themeProvider.setTextScale(value);
                    setSheet(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(AppLocalizations.of(context)!.small, style: TextStyle(color: _sTextSub(isDarkMode), fontSize: 12)),
                  Text('${(themeProvider.textScale * 100).toInt()}%',
                      style: const TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(AppLocalizations.of(context)!.large, style: TextStyle(color: _sTextSub(isDarkMode), fontSize: 12)),
                ]),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                themeProvider.setTextScale(1.13);
                setSheet(() {});
              },
              style: TextButton.styleFrom(foregroundColor: accent),
              child: Text(AppLocalizations.of(context)!.defaultValue,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}