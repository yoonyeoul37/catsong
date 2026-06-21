import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class SleepTimerSheet extends StatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int _selectedMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final primaryColor = AppTheme.fixedAccent;
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

    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                color: Colors.black12,
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
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bedtime_outlined,
                      color: primaryColor, size: 20),
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
              const Divider(color: Color(0xFFE5E5E5)),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatSelected(l, _selectedMinutes),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.radioAfterEnd,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: primaryColor.withOpacity(0.15),
                  thumbColor: primaryColor,
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _selectedMinutes.toDouble(),
                  min: 15,
                  max: 360,
                  divisions: 23,
                  onChanged: (v) => setState(() => _selectedMinutes = v.toInt()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.sleepMinuteUnit(15), style: const TextStyle(color: Colors.black38, fontSize: 10)),
                    Text(l.sleepHourUnit(2), style: const TextStyle(color: Colors.black38, fontSize: 10)),
                    Text(l.sleepHourUnit(4), style: const TextStyle(color: Colors.black38, fontSize: 10)),
                    Text(l.sleepHourUnit(6), style: const TextStyle(color: Colors.black38, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.8,
                children: quickOptions.map((opt) {
                  final isSelected = _selectedMinutes == opt.minutes;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = opt.minutes),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withOpacity(0.10)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor.withOpacity(0.4)
                              : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            color: isSelected ? primaryColor : Colors.black54,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<RadioProvider>().setSleepTimer(
                      Duration(minutes: _selectedMinutes),
                    );
                    Navigator.pop(context);
                    final overlay = Overlay.of(context);
                    final entry = OverlayEntry(
                      builder: (_) => Positioned(
                        bottom: 120, left: 0, right: 0,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bedtime, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    l.sleepAutoStopToast(_formatSelected(l, _selectedMinutes)),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    overlay.insert(entry);
                    Future.delayed(const Duration(seconds: 2), () => entry.remove());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l.set, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ],
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