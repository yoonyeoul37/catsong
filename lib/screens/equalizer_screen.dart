import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_effects.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/action_feedback.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 이퀄라이저 화면 — 값은 SoundEffects가 들고 있어서 화면을 닫아도 계속 적용·저장돼요
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  static Color _point = const Color(0xFF2589E8); // 포인트 색 (그릴 때마다 설정 색으로)

  String _formatFreq(int mHz) {
    final hz = mHz ~/ 1000; // 안드로이드는 밀리헤르츠로 줌
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    return '$hz';
  }

  @override
  Widget build(BuildContext context) {
    final fx = SoundEffects.instance;
    final l = AppLocalizations.of(context)!;
    final c = _EqPal.of(context);
    _point = context.watch<ThemeProvider>().primaryColor;

    Widget card(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) => Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: padding,
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
          child: child,
        );

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        // 위 시계·배터리 + 아래 시스템 아이콘이 바탕색에서도 잘 보이게
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: c.dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: c.dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: c.bg,
          systemNavigationBarIconBrightness: c.dark ? Brightness.light : Brightness.dark,
        ),
        title: Text(l.equalizer,
            style: TextStyle(color: c.ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.ink, size: 20),
        ),
      ),
      // 버튼은 맨 아래에 모아서: 초기화(흰) · 지금 설정 저장(먹색)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      fx.reset();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.card,
                      foregroundColor: c.ink,
                      side: BorderSide(color: c.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l.reset, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: fx.ready ? () => _askSave(context, fx) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.ink,
                      foregroundColor: c.bg,
                      disabledBackgroundColor: c.ink.withOpacity(0.4),
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('지금 설정 저장', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: fx,
        builder: (context, _) {
          if (!fx.ready) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('노래를 한 번 재생하면 이퀄라이저를 쓸 수 있어요',
                    textAlign: TextAlign.center, style: TextStyle(color: c.sub)),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───── 내 설정 (저장한 것) ─────
                if (fx.custom.isNotEmpty) ...[
                  _title(c, '내 설정'),
                  card(Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final p in fx.custom)
                        _chip(c, p.name, fx.label == p.name, () => fx.useCustom(p),
                            onLong: () => _askDelete(context, fx, p)),
                    ],
                  )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Text('길게 누르면 지울 수 있어요', style: TextStyle(color: c.sub, fontSize: 11.5)),
                  ),
                ],

                // ───── 추천 설정 ─────
                if (fx.devicePresets.isNotEmpty) ...[
                  _title(c, l.preset),
                  card(Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < fx.devicePresets.length; i++)
                        _chip(c, fx.devicePresets[i], fx.label == fx.devicePresets[i], () => fx.useDevicePreset(i)),
                    ],
                  )),
                ],

                // ───── 직접 맞추기 ─────
                _title(c, '직접 맞추기'),
                card(
                  SizedBox(
                    height: 240,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(fx.bands.length, (i) {
                        final level = fx.bands[i];
                        return Column(
                          children: [
                            Text('${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',
                                style: TextStyle(color: _point, fontSize: 11, fontWeight: FontWeight.w700)),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: _sliderTheme(context, c),
                                  child: Slider(
                                    value: level.clamp(fx.minLevel, fx.maxLevel).toDouble(),
                                    min: fx.minLevel.toDouble(),
                                    max: fx.maxLevel.toDouble(),
                                    onChanged: (v) => fx.setBand(i, v.toInt()),
                                  ),
                                ),
                              ),
                            ),
                            Text(i < fx.freqs.length ? _formatFreq(fx.freqs[i]) : '',
                                style: TextStyle(color: c.sub, fontSize: 10.5)),
                          ],
                        );
                      }),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                ),

                // ───── 저음 강화 · 공간감 ─────
                _title(c, '효과'),
                card(Column(
                  children: [
                    _strength(context, c, Icons.speaker_outlined, l.bassBooster, l.enhancesBass, fx.bass, fx.setBass),
                    Divider(color: c.line, height: 20),
                    _strength(context, c, Icons.surround_sound_outlined, l.virtualizer, l.surroundEffect, fx.virt,
                        fx.setVirt),
                  ],
                )),
                // (울림은 폰마다 효과가 없거나 달라서 뺌 — 공간감으로 대신)
              ],
            ),
          );
        },
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context, _EqPal c) => SliderTheme.of(context).copyWith(
        activeTrackColor: _point,
        inactiveTrackColor: c.line,
        thumbColor: _point,
        overlayColor: _point.withOpacity(0.1),
        trackHeight: 3,
      );

  /// 작은 회색 소제목
  Widget _title(_EqPal c, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(text, style: TextStyle(color: c.sub, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  /// 고르는 칸 (고르면 먹색으로 채움 — 녹음 탭 칸과 같은 모양)
  Widget _chip(_EqPal c, String label, bool selected, VoidCallback onTap, {VoidCallback? onLong}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: onLong,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? c.bg : c.sub,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }

  Widget _strength(BuildContext context, _EqPal c, IconData icon, String title, String desc, int value,
      Future<void> Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: c.sub, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: c.ink, fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${(value / 10).toStringAsFixed(0)}%',
                style: TextStyle(color: _point, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(desc, style: TextStyle(color: c.sub, fontSize: 11.5)),
        ),
        SliderTheme(
          data: _sliderTheme(context, c),
          child: Slider(
            value: value.toDouble().clamp(0.0, 1000.0),
            min: 0,
            max: 1000,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
      ],
    );
  }

  /// 지금 설정을 이름 붙여 저장
  void _askSave(BuildContext context, SoundEffects fx) async {
    final name = await showParanInput(
      context,
      title: '지금 설정 저장',
      initial: '내 설정 ${fx.custom.length + 1}',
      hint: '예) 출근길, 잠잘 때',
    );
    if (name == null || !context.mounted) return;
    fx.saveCustom(name);
    showActionFeedback(context, type: ActionFeedbackType.saved);
  }

  void _askDelete(BuildContext context, SoundEffects fx, FxPreset p) async {
    HapticFeedback.mediumImpact();
    final ok = await showParanConfirm(
      context,
      title: '"${p.name}"을 지울까요?',
      confirmLabel: '지우기',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    fx.deleteCustom(p);
    showActionFeedback(context, type: ActionFeedbackType.deleted);
  }
}

/// 화면 공통 색 (베이지 바탕 · 흰 카드 · 먹색)
class _EqPal {
  final bool dark;
  final Color bg, card, ink, sub, line;
  const _EqPal(this.dark, this.bg, this.card, this.ink, this.sub, this.line);
  static _EqPal of(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDarkMode;
    return d
        ? const _EqPal(true, Color(0xFF24221F), Color(0xFF32302C), Color(0xFFF3EFE7), Color(0xFFB8B0A2), Color(0xFF4A4640))
        : const _EqPal(false, Color(0xFFF4EFE5), Colors.white, Color(0xFF17140F), Color(0xFF8A8378), Color(0xFFE2DACB));
  }
}