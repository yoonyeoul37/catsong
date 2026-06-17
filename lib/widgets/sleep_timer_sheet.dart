import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';

class SleepTimerSheet extends StatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int _selectedMinutes = 30;

  static const _quickOptions = [
    _QuickOption('15분', 15),
    _QuickOption('30분', 30),
    _QuickOption('1시간', 60),
    _QuickOption('2시간', 120),
    _QuickOption('3시간', 180),
    _QuickOption('4시간', 240),
    _QuickOption('5시간', 300),
    _QuickOption('6시간', 360),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final sleep = radioProvider.sleepRemaining;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return ColoredBox(
      color: AppTheme.surfaceVariant,
      child: Container(
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

            // 남은 시간 표시 (B안 - 미니멀 큰 숫자)
            if (radioProvider.isSleepTimerActive && sleep != null) ...[
              // 남은 시간 레이블
              const Text(
                '남은 시간',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              // 큰 숫자 (MM:SS 형식)
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
              Text(
                '후 자동 종료',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              // 구분선
              const Divider(color: Color(0xFF1e1e1e)),
              const SizedBox(height: 12),
              // 취소 버튼 (텍스트만)
              GestureDetector(
                onTap: () {
                  context.read<RadioProvider>().cancelSleepTimer();
                  Navigator.pop(context);
                },
                child: const Center(
                  child: Text(
                    '× 타이머 취소',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // B안: 슬라이더 + 4열 그리드
              // 현재 선택값 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131313),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatSelected(_selectedMinutes),
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
                      '후 자동 종료',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 슬라이더
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
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
                  children: const [
                    Text('15분', style: TextStyle(color: Color(0xFF333333), fontSize: 10)),
                    Text('2시간', style: TextStyle(color: Color(0xFF333333), fontSize: 10)),
                    Text('4시간', style: TextStyle(color: Color(0xFF333333), fontSize: 10)),
                    Text('6시간', style: TextStyle(color: Color(0xFF333333), fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 퀵 선택 4열 그리드
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.8,
                children: _quickOptions.map((opt) {
                  final isSelected = _selectedMinutes == opt.minutes;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = opt.minutes),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withOpacity(0.12)
                            : const Color(0xFF131313),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor.withOpacity(0.4)
                              : const Color(0xFF252525),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            color: isSelected ? primaryColor : AppTheme.textHint,
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

              // 설정 버튼
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
                                    '${_formatSelected(_selectedMinutes)} 후 자동으로 꺼집니다',
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
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSelected(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }

  // MM:SS 형식
  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

class _QuickOption {
  final String label;
  final int minutes;
  const _QuickOption(this.label, this.minutes);
}