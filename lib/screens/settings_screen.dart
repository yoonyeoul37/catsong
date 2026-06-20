import 'equalizer_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'ringtone_screen.dart';
import '../l10n/app_localizations.dart';

// 설정 화면 전용 색상 상수
const _sBg = Color(0xFFF7F5F0);
const _sCard = Color(0xFFFFFFFF);
const _sText = Color(0xFF111111);
const _sTextSub = Color(0xFF666666);
const _sTextHint = Color(0xFF999999);
const _sBorder = Color(0xFFE8E4DA);
const _sInputBg = Color(0xFFEEEAE0);

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
    return Scaffold(
      backgroundColor: _sBg,
      appBar: AppBar(
        backgroundColor: _sBg,
        elevation: 0,
        title: Text(l.settings, style: const TextStyle(color: _sText, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: primaryColor, size: 20),
        ),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _sBorder)),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
        children: [
          _buildSection(l.themeColor),
          _buildTile(context, icon: Icons.palette_outlined, title: l.themeColor, onTap: () => _showColorPicker(context), primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.text_fields, title: l.textSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.font_download_outlined, title: l.fontChange, onTap: () => _showFontDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.style, title: l.playerStyle, onTap: () => _showPlayerStyleDialog(context), primaryColor: primaryColor, isLast: true),
          _buildSection(l.equalizer),
          _buildTile(context, icon: Icons.equalizer, title: l.equalizer, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EqualizerScreen())), primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: _isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off, title: l.flashlight, subtitle: _isFlashlightOn ? l.on : l.off, onTap: () => _toggleFlashlight(context), primaryColor: primaryColor,
              trailing: Switch(value: _isFlashlightOn, onChanged: (_) => _toggleFlashlight(context), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.emergency, title: l.sos, subtitle: _isSosOn ? l.sosWorking : l.sos, onTap: () => _toggleSOS(context), primaryColor: primaryColor,
              trailing: Switch(value: _isSosOn, onChanged: (_) => _toggleSOS(context), activeColor: Colors.redAccent, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RingtoneScreen())), primaryColor: primaryColor, isLast: true),
          _buildSection(l.widget),
          _buildTile(context, icon: Icons.widgets_outlined, title: l.widget, onTap: () async {
            const platform = MethodChannel('kr.ssing.catsong/media');
            try { await platform.invokeMethod('requestWidgetAdd'); } catch (e) {}
          }, primaryColor: primaryColor, isFirst: true, isLast: true),
          _buildSection(l.version),
          _buildTile(context, icon: Icons.verified_outlined, title: l.version, onTap: () {}, primaryColor: primaryColor, isFirst: true,
              trailing: Text('v1.0.0', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600))),
          _buildTile(context, icon: Icons.card_giftcard_outlined, title: l.promoCode, onTap: () => _showPromoCodeDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.privacy_tip_outlined, title: l.privacyPolicy, onTap: () => _launchUrl(l.privacyPolicyUrl), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.description_outlined, title: l.termsOfService, onTap: () => _launchUrl(l.termsOfServiceUrl), primaryColor: primaryColor, isLast: true),
          const SizedBox(height: 24),
          Center(child: Text('KNEXM.Co.,LTD', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF232016), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }

  Widget _buildTile(BuildContext context, {
    required IconData icon, required String title, String? subtitle,
    required VoidCallback onTap, required Color primaryColor,
    Widget? trailing, bool isFirst = false, bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _sCard,
        border: Border(
          top: isFirst ? const BorderSide(color: _sBorder) : BorderSide.none,
          bottom: const BorderSide(color: _sBorder),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(children: [
            Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: _sText, fontSize: 14)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: _sTextHint, fontSize: 12)),
              ],
            ])),
            trailing ?? const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ]),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.flashlightError}: $e'), backgroundColor: Colors.grey[800], duration: const Duration(seconds: 2)));
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
    final controller = TextEditingController();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final prefs = await SharedPreferences.getInstance();
    final isUnlocked = prefs.getBool('promo_unlocked') ?? false;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _sBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.card_giftcard, color: primaryColor, size: 20), const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.promoCode, style: const TextStyle(color: _sText, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            if (isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.promoUnlocked, style: const TextStyle(color: _sText, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(AppLocalizations.of(context)!.close),
                  )),
            ] else ...[
              Text(AppLocalizations.of(context)!.promoEnter, style: const TextStyle(color: _sTextSub, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller, autofocus: true, textAlign: TextAlign.center,
                style: const TextStyle(color: _sText, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(filled: true, fillColor: _sInputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(foregroundColor: _sTextHint, side: const BorderSide(color: _sBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.cancel),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text == '37258') {
                      await prefs.setBool('promo_unlocked', true);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.promoUnlocked), backgroundColor: Colors.green, duration: const Duration(seconds: 3)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.promoInvalid), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 2)));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  void _showPlayerStyleDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    int currentStyle = prefs.getInt('albumArtStyle') ?? 1;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l = AppLocalizations.of(context)!;
    final styles = [
      {'id': 1, 'name': l.styleCD, 'icon': Icons.album, 'desc': l.styleCDDesc},
      {'id': 2, 'name': l.styleCassette, 'icon': Icons.settings_input_composite, 'desc': l.styleCassetteDesc},
      {'id': 3, 'name': l.styleCard, 'icon': Icons.image, 'desc': l.styleCardDesc},
      {'id': 4, 'name': l.styleVisualizer, 'icon': Icons.graphic_eq, 'desc': l.styleVisualizerDesc},
      {'id': 5, 'name': l.styleGradient, 'icon': Icons.gradient, 'desc': l.styleGradientDesc},
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _sBg,
          title: Row(children: [
            Icon(Icons.style, color: primaryColor, size: 20), const SizedBox(width: 8),
            Text(l.playerStyle, style: const TextStyle(color: _sText, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: SizedBox(width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = currentStyle == style['id'];
                return InkWell(
                  onTap: () async { currentStyle = style['id'] as int; await prefs.setInt('albumArtStyle', currentStyle); setDialogState(() {}); Navigator.pop(ctx); },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.1) : _sInputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? primaryColor : Colors.transparent),
                    ),
                    child: Row(children: [
                      Icon(style['icon'] as IconData, color: isSelected ? primaryColor : _sTextHint, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(style['name'] as String, style: TextStyle(color: isSelected ? primaryColor : _sText, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        Text(style['desc'] as String, style: const TextStyle(color: _sTextSub, fontSize: 11)),
                      ])),
                      if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close, style: TextStyle(color: primaryColor)))],
        ),
      ),
    );
  }

  void _showFontDialog(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _sBg,
          title: Row(children: [
            Icon(Icons.font_download, color: primaryColor, size: 20), const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.fontChange, style: const TextStyle(color: _sText, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: SizedBox(width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ThemeProvider.availableFonts.length,
              itemBuilder: (context, index) {
                final font = ThemeProvider.availableFonts[index];
                final isSelected = themeProvider.fontFamily == font['key'];
                return InkWell(
                  onTap: () { themeProvider.setFontFamily(font['key']!); setDialogState(() {}); Navigator.pop(ctx); },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.1) : _sInputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? primaryColor : Colors.transparent),
                    ),
                    child: Row(children: [
                      Icon(Icons.font_download, color: isSelected ? primaryColor : _sTextHint, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_getFontName(context, font['key']!), style: TextStyle(color: isSelected ? primaryColor : _sText, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                      if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.close, style: TextStyle(color: primaryColor)))],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (e) { await launchUrl(uri, mode: LaunchMode.inAppWebView); }
  }

  void _showColorPicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    Color pickerColor = themeProvider.primaryColor;
    final hexController = TextEditingController(
      text: '#${pickerColor.value.toRadixString(16).substring(2).toUpperCase()}',
    );
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: _sBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(Icons.palette, color: primaryColor, size: 20), const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.themeColor, style: const TextStyle(color: _sText, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) {
                    setDialogState(() {
                      pickerColor = color;
                      hexController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                    });
                  },
                  colorPickerWidth: 280, pickerAreaHeightPercent: 0.7,
                  enableAlpha: false, displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue, labelTypes: const [],
                  pickerAreaBorderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: _sInputBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 20, height: 20, decoration: BoxDecoration(color: pickerColor, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
                    const SizedBox(width: 8),
                    SizedBox(width: 110,
                      child: TextField(
                        controller: hexController,
                        style: const TextStyle(color: _sText, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                        cursorColor: _sText,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                        onSubmitted: (value) {
                          try {
                            final hex = value.replaceAll('#', '').trim();
                            if (hex.length == 6) {
                              final color = Color(int.parse('FF$hex', radix: 16));
                              setDialogState(() { pickerColor = color; hexController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}'; });
                            }
                          } catch (e) {}
                        },
                      ),
                    ),
                  ]),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    const Color(0xFFD4AF37), const Color(0xFFB76E79), const Color(0xFF2196F3),
                    const Color(0xFF9C27B0), const Color(0xFF4CAF50), const Color(0xFFF44336),
                    const Color(0xFFFF9800), const Color(0xFF00BCD4), const Color(0xFFFFFFFF),
                    const Color(0xFFFF69B4),
                  ].map((color) {
                    final isSelected = pickerColor == color;
                    return GestureDetector(
                      onTap: () { setDialogState(() { pickerColor = color; hexController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}'; }); },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? const Color(0xFF888888) : _sBorder, width: isSelected ? 3 : 1),
                          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)] : null,
                        ),
                        child: isSelected ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(foregroundColor: _sTextSub, side: const BorderSide(color: _sBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      // hex 코드 입력값도 반영
                      try {
                        final hex = hexController.text.replaceAll('#', '').trim();
                        if (hex.length == 6) {
                          pickerColor = Color(int.parse('FF$hex', radix: 16));
                        }
                      } catch (e) {}
                      themeProvider.setPrimaryColor(pickerColor);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pickerColor,
                      foregroundColor: pickerColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.apply, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showTextSizeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: _sBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(Icons.text_fields, color: primaryColor, size: 20), const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.textSize, style: const TextStyle(color: _sText, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _sInputBg, borderRadius: BorderRadius.circular(12)),
                child: Text(AppLocalizations.of(context)!.preview, style: TextStyle(color: _sText, fontSize: 16 * themeProvider.textScale)),
              ),
              const SizedBox(height: 16),
              Slider(
                value: themeProvider.textScale.clamp(1.0, 2.0), min: 1.0, max: 2.0, divisions: 10,
                label: '${(themeProvider.textScale * 100).toInt()}%',
                onChanged: (value) { themeProvider.setTextScale(value); setDialogState(() {}); },
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(AppLocalizations.of(context)!.small, style: const TextStyle(color: _sTextSub, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${(themeProvider.textScale * 100).toInt()}%', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Text(AppLocalizations.of(context)!.large, style: const TextStyle(color: _sTextSub, fontSize: 12)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () { themeProvider.setTextScale(1.13); setDialogState(() {}); },
                  style: OutlinedButton.styleFrom(foregroundColor: _sTextSub, side: const BorderSide(color: _sBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.defaultValue),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.close),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}