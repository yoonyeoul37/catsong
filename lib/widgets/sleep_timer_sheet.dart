import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  static const _options = [
    _Option('15분', Duration(minutes: 15)),
    _Option('30분', Duration(minutes: 30)),
    _Option('45분', Duration(minutes: 45)),
    _Option('1시간', Duration(hours: 1)),
    _Option('1시간 30분', Duration(hours: 1, minutes: 30)),
    _Option('2시간', Duration(hours: 2)),
    _Option('3시간', Duration(hours: 3)),
    _Option('4시간', Duration(hours: 4)),
    _Option('5시간', Duration(hours: 5)),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final sleep = radioProvider.sleepRemaining;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 타이틀
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bedtime_outlined,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('수면 타이머',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    radioProvider.isSleepTimerActive
                        ? '타이머가 작동 중입니다'
                        : '선택한 시간 후 자동으로 꺼집니다',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 남은 시간 표시 (타이머 작동 중일 때)
          if (radioProvider.isSleepTimerActive && sleep != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _formatRemaining(sleep),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '후 자동 종료',
                    style: TextStyle(
                        color: primaryColor.withOpacity(0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<RadioProvider>().cancelSleepTimer();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('타이머 취소'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            // 시간 선택 버튼들
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _options.map((opt) {
                return GestureDetector(
                  onTap: () {
                    context
                        .read<RadioProvider>()
                        .setSleepTimer(opt.duration);
                    Navigator.pop(context);
                    final overlay = Overlay.of(context);
                    final entry = OverlayEntry(
                      builder: (_) => Positioned(
                        bottom: 120,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: child,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bedtime,
                                      color: primaryColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${opt.label} 후 자동으로 꺼집니다',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        decoration: TextDecoration.none),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    overlay.insert(entry);
                    Future.delayed(
                        const Duration(seconds: 2), () => entry.remove());
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 78) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: primaryColor.withOpacity(0.15)),
                    ),
                    child: Center(
                      child: Text(
                        opt.label,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}시간 ${m}분 ${s}초';
    if (m > 0) return '${m}분 ${s}초';
    return '${s}초';
  }
}

class _Option {
  final String label;
  final Duration duration;
  const _Option(this.label, this.duration);
}