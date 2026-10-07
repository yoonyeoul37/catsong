import 'equalizer_screen.dart';
import 'package:flutter/material.dart';
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
import 'bulk_clean_screen.dart';
import 'bulk_art_screen.dart';
import 'player_screen.dart' show showPlayerStyleMenu;

// 화면 공통 색 (베이지 바탕 · 흰 카드 · 먹색 글자)
Color _sBg(bool d) => d ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
Color _sCard(bool d) => d ? const Color(0xFF26221C) : const Color(0xFFFFFFFF);
Color _sText(bool d) => d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color _sTextSub(bool d) => d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
Color _sTextHint(bool d) => d ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
Color _sBorder(bool d) => d ? const Color(0xFF3A342B) : const Color(0xFFEEE9DF);
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
          _buildSection(l.themeColor),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _buildTile(
              context,
              icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              title: l.darkMode,
              subtitle: themeProvider.isDarkMode ? l.darkModeOn : l.darkModeOff,
              onTap: () => themeProvider.setDarkMode(!themeProvider.isDarkMode),
              primaryColor: primaryColor,
              isFirst: true,
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (v) => themeProvider.setDarkMode(v),
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _buildTile(
              context,
              icon: themeProvider.voiceGreetingEnabled ? Icons.record_voice_over : Icons.voice_over_off,
              title: '음성 안내',
              subtitle: themeProvider.voiceGreetingEnabled ? l.darkModeOn : l.darkModeOff,
              onTap: () => themeProvider.setVoiceGreetingEnabled(!themeProvider.voiceGreetingEnabled),
              primaryColor: primaryColor,
              trailing: Switch(
                value: themeProvider.voiceGreetingEnabled,
                onChanged: (v) => themeProvider.setVoiceGreetingEnabled(v),
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          // 완료 효과음: 수정·삭제·저장할 때 물방울 소리 (진동 모드면 진동)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _buildTile(
              context,
              icon: themeProvider.feedbackSoundEnabled ? Icons.water_drop : Icons.water_drop_outlined,
              title: '효과음',
              subtitle: themeProvider.feedbackSoundEnabled ? l.darkModeOn : l.darkModeOff,
              onTap: () => themeProvider.setFeedbackSoundEnabled(!themeProvider.feedbackSoundEnabled),
              primaryColor: primaryColor,
              trailing: Switch(
                value: themeProvider.feedbackSoundEnabled,
                onChanged: (v) => themeProvider.setFeedbackSoundEnabled(v),
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          _buildTile(context, icon: Icons.palette_outlined, title: '포인트 색', subtitle: context.watch<ThemeProvider>().pointColorName, onTap: () => _showColorPicker(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.text_fields, title: l.textSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.font_download_outlined, title: l.fontChange, onTap: () => _showFontDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.style, title: l.playerStyle, onTap: () => _showPlayerStyleDialog(context), primaryColor: primaryColor, isLast: true),
          // ───── 음악 관리 (홈 ⋮ 메뉴에서 옮겨옴) ─────
          _buildSection('음악 관리'),
          _buildTile(context, icon: Icons.auto_awesome_outlined, title: '곡 정보 한꺼번에 정리',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCleanScreen())),
              primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.photo_library_outlined, title: '앨범 사진 한꺼번에 찾기',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkArtScreen())),
              primaryColor: primaryColor, isLast: true),
          _buildSection(l.equalizer),
          _buildTile(context, icon: Icons.equalizer, title: l.equalizer, onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const EqualizerScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child), transitionDuration: const Duration(milliseconds: 250))), primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: _isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off, title: l.flashlight, subtitle: _isFlashlightOn ? l.on : l.off, onTap: () => _toggleFlashlight(context), primaryColor: primaryColor,
              trailing: Switch(value: _isFlashlightOn, onChanged: (_) => _toggleFlashlight(context), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.emergency, title: l.sos, subtitle: _isSosOn ? l.sosWorking : l.sos, onTap: () => _toggleSOS(context), primaryColor: primaryColor,
              trailing: Switch(value: _isSosOn, onChanged: (_) => _toggleSOS(context), activeColor: Colors.redAccent, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone, onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const RingtoneScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child), transitionDuration: const Duration(milliseconds: 250))), primaryColor: primaryColor, isLast: true),
          _buildSection(l.widget),
          _buildTile(context, icon: Icons.widgets_outlined, title: l.widget, onTap: () async {
            const platform = MethodChannel('kr.ssing.catsong/media');
            try { await platform.invokeMethod('requestWidgetAdd'); } catch (e) {}
          }, primaryColor: primaryColor, isFirst: true, isLast: true),
          _buildSection(l.version),
          FutureBuilder<String>(
            future: _getAppVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '';
              return _buildTile(context, icon: Icons.verified_outlined, title: l.version, onTap: () {}, primaryColor: primaryColor, isFirst: true,
                  trailing: Text(version, style: const TextStyle(color: AppTheme.fixedAccent, fontSize: 12, fontWeight: FontWeight.w600)));
            },
          ),
          _buildTile(context, icon: Icons.card_giftcard_outlined, title: l.promoCode, onTap: () => _showPromoCodeDialog(context), primaryColor: primaryColor),
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
                Container(height: 0.5, margin: const EdgeInsets.only(left: 50), color: _sBorder(isDarkMode)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                // 한 줄로: 아이콘 · 이름 ········ 작은 회색 글자 · 스위치/›
                child: Row(children: [
                  Icon(icon, color: _sTextHint(isDarkMode), size: 20),
                  const SizedBox(width: 14),
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

  Future<void> _showPromoCodeDialog(BuildContext context) async {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final controller = TextEditingController();
    const accent = AppTheme.fixedAccent;
    final prefs = await SharedPreferences.getInstance();
    final isUnlocked = prefs.getBool('promo_unlocked') ?? false;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _sBg(isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.card_giftcard, color: accent, size: 20), const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.promoCode, style: TextStyle(color: _sText(isDarkMode), fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            if (isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.verified, color: accent, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.promoUnlocked, style: TextStyle(color: _sText(isDarkMode), fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(AppLocalizations.of(context)!.close),
                  )),
            ] else ...[
              Text(AppLocalizations.of(context)!.promoEnter, style: TextStyle(color: _sTextSub(isDarkMode), fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller, autofocus: true, textAlign: TextAlign.center,
                style: TextStyle(color: _sText(isDarkMode), fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(filled: true, fillColor: _sInputBg(isDarkMode), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(foregroundColor: _sTextHint(isDarkMode), side: BorderSide(color: _sBorder(isDarkMode)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.cancel),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text == '37258') {
                      await prefs.setBool('promo_unlocked', true);
                      Navigator.pop(ctx);
                      showParanToast(context, AppLocalizations.of(context)!.promoUnlocked);
                    } else {
                      showParanToast(context, AppLocalizations.of(context)!.promoInvalid, error: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ]),
        ),
      ),
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