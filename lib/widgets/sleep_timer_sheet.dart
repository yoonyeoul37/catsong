import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  static const _options = [
    _Option('15분',       Duration(minutes: 15)),
    _Option('30분',       Duration(minutes: 30)),
    _Option('45분',       Duration(minutes: 45)),
    _Option('1시간',      Duration(hours: 1)),
    _Option('1시간 30분', Duration(hours: 1, minutes: 30)),
    _Option('2시간',      Duration(hours: 2)),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor  = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final sleep         = radioProvider.sleepRemaining;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.bedtime_outlined,
                  color: primaryColor, size: 22),
              const SizedBox(width: 10),
              const Text('수면 타이머',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '선택한 시간 후 자동으로 라디오를 끕니다',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: _options.map((opt) {
              final isSelected = sleep != null &&
                  sleep.inSeconds == opt.duration.inSeconds;
              return Material(
                color: isSelected
                    ? primaryColor
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context
                        .read<RadioProvider>()
                        .setSleepTimer(opt.duration);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${opt.label} 후 자동으로 꺼집니다',
                            style:
                            const TextStyle(fontSize: 14)),
                        backgroundColor:
                        AppTheme.surfaceVariant,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Center(
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (radioProvider.isSleepTimerActive) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                context
                    .read<RadioProvider>()
                    .cancelSleepTimer();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close,
                  color: Colors.redAccent, size: 18),
              label: const Text('타이머 취소',
                  style: TextStyle(
                      color: Colors.redAccent, fontSize: 15)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Option {
  final String   label;
  final Duration duration;
  const _Option(this.label, this.duration);
}