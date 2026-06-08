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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.settings,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionCard(
            context,
            title: AppLocalizations.of(context)!.themeColor,
            icon: Icons.brush,
            primaryColor: primaryColor,
            children: [
              _buildTile(
                context,
                icon: Icons.palette_outlined,
                title: AppLocalizations.of(context)!.themeColor,
                subtitle: AppLocalizations.of(context)!.themeColor,
                onTap: () => _showColorPicker(context),
                primaryColor: primaryColor,
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.text_fields,
                title: AppLocalizations.of(context)!.textSize,
                subtitle: AppLocalizations.of(context)!.textSize,
                onTap: () => _showTextSizeDialog(context),
                primaryColor: primaryColor,
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.font_download_outlined,
                title: AppLocalizations.of(context)!.fontChange,
                subtitle: AppLocalizations.of(context)!.fontChange,
                onTap: () => _showFontDialog(context),
                primaryColor: primaryColor,
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.style,
                title: AppLocalizations.of(context)!.playerStyle,
                subtitle: AppLocalizations.of(context)!.playerStyle,
                onTap: () => _showPlayerStyleDialog(context),
                primaryColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: AppLocalizations.of(context)!.equalizer,
            icon: Icons.tune,
            primaryColor: primaryColor,
            children: [
              _buildTile(
                context,
                icon: Icons.equalizer,
                title: AppLocalizations.of(context)!.equalizer,
                subtitle: AppLocalizations.of(context)!.equalizer,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EqualizerScreen()),
                ),
                primaryColor: primaryColor,
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: _isFlashlightOn
                    ? Icons.flashlight_on
                    : Icons.flashlight_off,
                title: AppLocalizations.of(context)!.flashlight,
                subtitle: _isFlashlightOn
                    ? AppLocalizations.of(context)!.on
                    : AppLocalizations.of(context)!.off,
                onTap: () => _toggleFlashlight(context),
                primaryColor: primaryColor,
                trailing: Switch(
                  value: _isFlashlightOn,
                  onChanged: (_) => _toggleFlashlight(context),
                  activeColor: primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.emergency,
                title: AppLocalizations.of(context)!.sos,
                subtitle: _isSosOn
                    ? AppLocalizations.of(context)!.sosWorking
                    : AppLocalizations.of(context)!.sos,
                onTap: () => _toggleSOS(context),
                primaryColor: primaryColor,
                trailing: Switch(
                  value: _isSosOn,
                  onChanged: (_) => _toggleSOS(context),
                  activeColor: Colors.redAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.music_note_outlined,
                title: AppLocalizations.of(context)!.ringtone,
                subtitle: AppLocalizations.of(context)!.ringtone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RingtoneScreen()),
                ),
                primaryColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: AppLocalizations.of(context)!.widget,
            icon: Icons.home_outlined,
            primaryColor: primaryColor,
            children: [
              _buildTile(
                context,
                icon: Icons.widgets_outlined,
                title: AppLocalizations.of(context)!.widget,
                subtitle: AppLocalizations.of(context)!.widget,
                onTap: () async {
                  final platform = MethodChannel('com.example.mp3_player/media');
                  try {
                    await platform.invokeMethod('requestWidgetAdd');
                  } catch (e) {}
                },
                primaryColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: AppLocalizations.of(context)!.version,
            icon: Icons.info_outline,
            primaryColor: primaryColor,
            children: [
              _buildTile(
                context,
                icon: Icons.verified_outlined,
                title: AppLocalizations.of(context)!.version,
                subtitle: 'v1.0.0',
                onTap: () {},
                primaryColor: primaryColor,
                trailing: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('v1.0.0',
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.card_giftcard_outlined,
                title: AppLocalizations.of(context)!.promoCode,
                subtitle: AppLocalizations.of(context)!.promoCode,
                onTap: () => _showPromoCodeDialog(context),
                primaryColor: primaryColor,
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: AppLocalizations.of(context)!.privacyPolicy,
                subtitle: AppLocalizations.of(context)!.privacyPolicy,
                onTap: () => _launchUrl(
                    AppLocalizations.of(context)!.privacyPolicyUrl),
                primaryColor: primaryColor,
              ),
              _buildTileDivider(),
              _buildTile(
                context,
                icon: Icons.description_outlined,
                title: AppLocalizations.of(context)!.termsOfService,
                subtitle: AppLocalizations.of(context)!.termsOfService,
                onTap: () => _launchUrl(
                    AppLocalizations.of(context)!.termsOfServiceUrl),
                primaryColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('KNEXM.Co.,LTD',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color primaryColor,
        required List<Widget> children,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 14),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required Color primaryColor,
        Widget? trailing,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios,
                    color: AppTheme.textHint.withOpacity(0.5), size: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildTileDivider() {
    return const Divider(
      color: AppTheme.divider,
      height: 1,
      indent: 68,
      endIndent: 0,
    );
  }

  Future<void> _toggleFlashlight(BuildContext context) async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
        setState(() => _isFlashlightOn = false);
      } else {
        if (_isSosOn) {
          setState(() => _isSosOn = false);
          await TorchLight.disableTorch();
          await Future.delayed(const Duration(milliseconds: 200));
        }
        await TorchLight.enableTorch();
        setState(() => _isFlashlightOn = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.flashlightError}: $e'),
          backgroundColor: AppTheme.surfaceVariant,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleSOS(BuildContext context) async {
    if (_isSosOn) {
      setState(() => _isSosOn = false);
      await TorchLight.disableTorch();
    } else {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
        setState(() => _isFlashlightOn = false);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      setState(() => _isSosOn = true);
      _startSOS();
    }
  }

  Future<void> _startSOS() async {
    final sosPattern = [
      200, 200, 200, 200, 200, 400,
      600, 200, 600, 200, 600, 400,
      200, 200, 200, 200, 200, 800,
    ];
    while (_isSosOn && mounted) {
      for (int i = 0; i < sosPattern.length; i++) {
        if (!_isSosOn || !mounted) break;
        if (i % 2 == 0) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
        await Future.delayed(Duration(milliseconds: sosPattern[i]));
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
        backgroundColor: AppTheme.surfaceVariant,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.promoCode,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              if (isUnlocked) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 40),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.promoUnlocked,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ),
              ] else ...[
                Text(AppLocalizations.of(context)!.promoEnter,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textHint,
                          side: const BorderSide(color: AppTheme.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (controller.text == '37258') {
                            await prefs.setBool('promo_unlocked', true);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.promoUnlocked),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.promoInvalid),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context)!.confirm,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerStyleDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    int currentStyle = prefs.getInt('albumArtStyle') ?? 1;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final styles = [
      {'id': 1, 'name': 'CD Rotation', 'icon': Icons.album, 'desc': 'Classic CD rotation animation'},
      {'id': 2, 'name': 'Cassette Tape', 'icon': Icons.settings_input_composite, 'desc': 'Retro cassette tape style'},
      {'id': 3, 'name': 'Album Art Card', 'icon': Icons.image, 'desc': 'Simple album art card style'},
      {'id': 4, 'name': 'Waveform Visualizer', 'icon': Icons.graphic_eq, 'desc': 'Sound wave animation'},
      {'id': 5, 'name': 'Gradient', 'icon': Icons.gradient, 'desc': 'Album art color gradient background'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceVariant,
          title: Row(
            children: [
              Icon(Icons.style, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playerStyle,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = currentStyle == style['id'];
                return InkWell(
                  onTap: () async {
                    currentStyle = style['id'] as int;
                    await prefs.setInt('albumArtStyle', currentStyle);
                    setDialogState(() {});
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.15)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(style['icon'] as IconData,
                            color: isSelected
                                ? primaryColor
                                : AppTheme.textHint,
                            size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(style['name'] as String,
                                  style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              Text(style['desc'] as String,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.close,
                  style: TextStyle(color: primaryColor)),
            ),
          ],
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
          backgroundColor: AppTheme.surfaceVariant,
          title: Row(
            children: [
              Icon(Icons.font_download, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.fontChange,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ThemeProvider.availableFonts.length,
              itemBuilder: (context, index) {
                final font = ThemeProvider.availableFonts[index];
                final isSelected = themeProvider.fontFamily == font['key'];
                return InkWell(
                  onTap: () {
                    themeProvider.setFontFamily(font['key']!);
                    setDialogState(() {});
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.15)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.font_download,
                            color: isSelected
                                ? primaryColor
                                : AppTheme.textHint,
                            size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(font['name']!,
                              style: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.close,
                  style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  void _showColorPicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    Color pickerColor = themeProvider.primaryColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.surfaceVariant,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.themeColor,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) {
                    setDialogState(() => pickerColor = color);
                  },
                  colorPickerWidth: 280,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  labelTypes: const [],
                  pickerAreaBorderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    const Color(0xFFD4AF37),
                    const Color(0xFFB76E79),
                    const Color(0xFF2196F3),
                    const Color(0xFF9C27B0),
                    const Color(0xFF4CAF50),
                    const Color(0xFFF44336),
                    const Color(0xFFFF9800),
                    const Color(0xFF00BCD4),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFFF69B4),
                  ].map((color) {
                    final isSelected = pickerColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => pickerColor = color);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8)
                          ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                            color: Colors.black, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textHint,
                          side: const BorderSide(color: AppTheme.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          themeProvider.setPrimaryColor(pickerColor);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pickerColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context)!.apply,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
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
          backgroundColor: AppTheme.surfaceVariant,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.textSize,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.preview,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16 * themeProvider.textScale,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: themeProvider.textScale,
                  min: 1.13,
                  max: 2.0,
                  divisions: 10,
                  label: '${(themeProvider.textScale * 100).toInt()}%',
                  onChanged: (value) {
                    themeProvider.setTextScale(value);
                    setDialogState(() {});
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.small,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          '${(themeProvider.textScale * 100).toInt()}%',
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(AppLocalizations.of(context)!.large,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          themeProvider.setTextScale(1.13);
                          setDialogState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textHint,
                          side: const BorderSide(color: AppTheme.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child:
                        Text(AppLocalizations.of(context)!.defaultValue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context)!.close),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}