import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'paran_toast.dart';

class SleepTimerSheet extends StatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int _selectedMinutes = 30;
  Duration _wheelDuration = const Duration(minutes: 30);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const primaryColor = Color(0xFF17140F); // 먹색 (다른 창과 통일)
    final radioProvider = context.watch<RadioProvider>();
    final sleep = radioProvider.sleepRemaining;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final quickOptions = [
      _QuickOption(l.sleepMinuteUnit(15), 15),
      _QuickOption(l.sleepMinuteUnit(30), 30),
      _QuickOption(l.sleepHourUnit(1), 60),
      _QuickOption(l.sleepHourUnit(2), 120),
      _QuickOption(l.sleepHourUnit(3), 180),
      _QuickOption(l.sleepHourUnit(4), 240),
      _QuickOption(l.sleepHourUnit(5), 300),
      _QuickOption(l.sleepHourUnit(6), 360),
    ];

    // 창이 떠 있는 동안 아래 시스템 아이콘을 베이지 바탕에 맞게 (어두운 화면 위에서도 보이게)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFF4EFE5),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4EFE5), // 베이지 (다른 고르는 창과 같게)
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2DACB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bedtime_outlined,
                      color: Color(0xFF8A8378), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.sleepTimer,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        radioProvider.isSleepTimerActive
                            ? l.sleepTimerActiveDesc
                            : l.sleepTimerDesc,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (radioProvider.isSleepTimerActive && sleep != null) ...[
              Text(
                l.remainingTime,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatCountdown(sleep),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 6),
              const Text('', style: TextStyle(fontSize: 0)),
              Text(
                l.radioAfterEnd,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2DACB)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  context.read<RadioProvider>().cancelSleepTimer();
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(
                    l.cancelTimerX,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('몇 시간 몇 분 후 정지할까요?',
                  style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(
                height: 180,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: _wheelDuration,
                    onTimerDurationChanged: (d) {
                      _wheelDuration = d;
                      _selectedMinutes = d.inMinutes;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_wheelDuration.inMinutes <= 0) return;
                    _selectedMinutes = _wheelDuration.inMinutes;
                    context.read<RadioProvider>().setSleepTimer(
                      _wheelDuration,
                    );
                    Navigator.pop(context);
                    showParanToast(context, l.sleepAutoStopToast(_formatSelected(l, _selectedMinutes)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFFF4EFE5),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.25),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l.set, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSelected(AppLocalizations l, int minutes) {
    if (minutes < 60) return l.sleepMinuteUnit(minutes);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return l.sleepHourUnit(h);
    return l.sleepHourMinuteUnit(h, m);
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _QuickOption {
  final String label;
  final int minutes;
  const _QuickOption(this.label, this.minutes);
}