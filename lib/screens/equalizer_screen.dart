import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_effects.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// 이퀄라이저 화면 — 값은 SoundEffects가 들고 있어서 화면을 닫아도 계속 적용·저장돼요
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  static const _accent = AppTheme.fixedAccent;

  String _formatFreq(int mHz) {
    final hz = mHz ~/ 1000; // 안드로이드는 밀리헤르츠로 줌
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    return '$hz';
  }

  @override
  Widget build(BuildContext context) {
    final fx = SoundEffects.instance;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(l.equalizer,
            style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: _accent, size: 20),
        ),
      ),
      // 초기화: 스크롤과 상관없이 맨 아래 고정 (시스템 바 위에 딱 붙게)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              fx.reset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(l.reset, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: fx,
        builder: (context, _) {
          if (!fx.ready) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('노래를 한 번 재생하면 이퀄라이저를 쓸 수 있어요',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black45)),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───── 내 설정 ─────
                _title('내 설정'),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _chip('＋ 지금 설정 저장', false, () => _askSave(context, fx), outlined: true),
                      for (final p in fx.custom)
                        _chip(p.name, fx.label == p.name, () => fx.useCustom(p),
                            onLong: () => _askDelete(context, fx, p)),
                    ],
                  ),
                ),
                if (fx.custom.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text('길게 누르면 지울 수 있어요', style: TextStyle(color: Colors.black38, fontSize: 11)),
                  ),

                // ───── 기본 프리셋 ─────
                if (fx.devicePresets.isNotEmpty) ...[
                  _title(l.preset),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (var i = 0; i < fx.devicePresets.length; i++)
                          _chip(fx.devicePresets[i], fx.label == fx.devicePresets[i], () => fx.useDevicePreset(i)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFEDEDED)),

                // ───── 밴드 ─────
                SizedBox(
                  height: 270,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(fx.bands.length, (i) {
                        final level = fx.bands[i];
                        return Column(
                          children: [
                            Text('${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',
                                style: const TextStyle(color: _accent, fontSize: 11)),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: _sliderTheme(context),
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
                                style: const TextStyle(color: Colors.black45, fontSize: 10)),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFEDEDED)),

                // ───── 저음 강화 · 공간감 ─────
                _strength(context, Icons.speaker, l.bassBooster, l.enhancesBass, fx.bass, fx.setBass),
                _strength(context, Icons.surround_sound, l.virtualizer, l.surroundEffect, fx.virt, fx.setVirt),

                // ───── 울림 (리버브) ─────
                if (fx.reverbSupported) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                    child: Row(
                      children: const [
                        Icon(Icons.account_balance_outlined, color: _accent, size: 16),
                        SizedBox(width: 6),
                        Text('울림',
                            style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('방이나 공연장에서 듣는 것처럼 소리가 퍼져요',
                        style: TextStyle(color: Colors.black45, fontSize: 11)),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (var i = 0; i < SoundEffects.reverbNames.length; i++)
                          _chip(SoundEffects.reverbNames[i], fx.reverb == i, () => fx.setReverb(i)),
                      ],
                    ),
                  ),
                ],

                // (초기화 버튼은 화면 맨 아래에 고정)
              ],
            ),
          );
        },
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) => SliderTheme.of(context).copyWith(
    activeTrackColor: _accent,
    inactiveTrackColor: _accent.withOpacity(0.15),
    thumbColor: _accent,
    overlayColor: _accent.withOpacity(0.1),
  );

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(text,
        style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap, {VoidCallback? onLong, bool outlined = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLong,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent : (outlined ? Colors.white : const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _accent : (outlined ? _accent.withOpacity(0.5) : const Color(0xFFE5E5E5)),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : (outlined ? _accent : Colors.black54),
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      ),
    );
  }

  Widget _strength(BuildContext context, IconData icon, String title, String desc, int value,
      Future<void> Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(value / 10).toStringAsFixed(0)}%',
                  style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.black45, fontSize: 11)),
          SliderTheme(
            data: _sliderTheme(context),
            child: Slider(
              value: value.toDouble().clamp(0.0, 1000.0),
              min: 0,
              max: 1000,
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
        ],
      ),
    );
  }

  /// 지금 설정을 이름 붙여 저장
  void _askSave(BuildContext context, SoundEffects fx) {
    final ctrl = TextEditingController(text: '내 설정 ${fx.custom.length + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('지금 설정 저장', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예) 출근길, 잠잘 때'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) fx.saveCustom(name);
              Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  void _askDelete(BuildContext context, SoundEffects fx, FxPreset p) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${p.name}"을 지울까요?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              fx.deleteCustom(p);
              Navigator.pop(ctx);
            },
            child: const Text('지우기', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}