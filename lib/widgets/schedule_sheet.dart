import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({super.key});

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  TimeOfDay? _selectedTime;
  RadioStation? _selectedStation;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final schedules = radioProvider.schedules;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    // 채널 목록: 현재 큐 또는 최근 청취
    final stationList = radioProvider.currentQueue.isNotEmpty
        ? radioProvider.currentQueue
        : radioProvider.recentlyListened;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
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
                child: Icon(Icons.schedule,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.radioScheduleChannelSwitch,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.radioMaxSchedules(schedules.length),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 현재 예약 목록
          if (schedules.isNotEmpty) ...[
            ...List.generate(schedules.length, (i) {
              final s = schedules[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: s.triggered
                      ? primaryColor.withOpacity(0.15)
                      : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: s.triggered
                        ? primaryColor.withOpacity(0.4)
                        : primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.triggered ? Icons.check_circle : Icons.schedule,
                      color: s.triggered
                          ? primaryColor
                          : AppTheme.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.timeString,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward,
                        color: AppTheme.textHint, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.station.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => radioProvider.removeSchedule(i),
                      child: const Icon(Icons.close,
                          color: Colors.redAccent, size: 18),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // 새 예약 추가
          if (schedules.length < 5) ...[
            // 시간 선택
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: primaryColor,
                          surface: AppTheme.surfaceVariant,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time,
                        color: _selectedTime != null
                            ? primaryColor
                            : AppTheme.textHint,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime != null
                          ? _formatTime(_selectedTime!)
                          : AppLocalizations.of(context)!.radioSelectTime,
                      style: TextStyle(
                        color: _selectedTime != null
                            ? primaryColor
                            : AppTheme.textHint,
                        fontSize: 15,
                        fontWeight: _selectedTime != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 채널 선택
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: primaryColor.withOpacity(0.15)),
              ),
              child: stationList.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(AppLocalizations.of(context)!.radioPlayFirst,
                      style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 13)),
                ),
              )
                  : SizedBox(
                height: 200,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  itemCount: stationList.length,
                  itemBuilder: (context, index) {
                    final station = stationList[index];
                    final isSelected =
                        _selectedStation?.name == station.name;
                    return GestureDetector(
                      onTap: () => setState(
                              () => _selectedStation = station),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        margin:
                        const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? primaryColor
                                  : AppTheme.textHint,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Builder(builder: (ctx) {
                                    final nowPlaying = context.read<RadioProvider>().nowPlayingFor(station.name);
                                    if (nowPlaying == null || nowPlaying.isEmpty) return const SizedBox.shrink();
                                    return Text(
                                      nowPlaying,
                                      style: TextStyle(
                                        color: primaryColor.withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => _ScheduleListBottomSheet(
                                    stationName: station.name,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.format_list_bulleted,
                                  color: AppTheme.textHint,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 예약 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTime != null &&
                    _selectedStation != null
                    ? () {
                  radioProvider.addSchedule(
                      _selectedTime!, _selectedStation!);
                  setState(() {
                    _selectedTime = null;
                    _selectedStation = null;
                  });

                  final overlay = Overlay.of(context);
                  final entry = OverlayEntry(
                    builder: (_) => Positioned(
                      bottom: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration:
                          const Duration(milliseconds: 300),
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
                              borderRadius:
                              BorderRadius.circular(30),
                              border: Border.all(
                                  color: primaryColor
                                      .withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule,
                                    color: primaryColor,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.radioScheduleSetToast,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      decoration:
                                      TextDecoration.none),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  overlay.insert(entry);
                  Future.delayed(const Duration(seconds: 2),
                          () => entry.remove());
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.cardColor,
                  disabledForegroundColor: AppTheme.textHint,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(AppLocalizations.of(context)!.radioSetSchedule,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],

          // 전체 취소
          if (schedules.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  radioProvider.clearSchedules();
                },
                icon: const Icon(Icons.close, size: 18),
                label: Text(AppLocalizations.of(context)!.radioCancelAllSchedules),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $h:$m';
  }
}
class _ScheduleListBottomSheet extends StatelessWidget {
  final String stationName;
  const _ScheduleListBottomSheet({required this.stationName});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final schedules = radioProvider.scheduleList;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewPadding.bottom),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.format_list_bulleted, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.radioScheduleTitle(stationName),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: schedules.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(AppLocalizations.of(context)!.radioLoadingSchedule,
                    style: const TextStyle(color: Colors.white54)),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final s = schedules[index];
                String title = s['program_title'] as String? ?? '';
                String start = s['program_planned_start_time'] as String? ?? '';
                String end = s['program_planned_end_time'] as String? ?? '';
                if (title.isEmpty) title = s['Title'] as String? ?? '';
                if (start.isEmpty) start = s['StartTime'] as String? ?? '';
                if (end.isEmpty) end = s['EndTime'] as String? ?? '';
                if (title.isEmpty) title = s['title'] as String? ?? '';
                if (start.isEmpty) { start = s['start_time'] as String? ?? ''; end = s['end_time'] as String? ?? ''; }

                String fmt(String t) {
                  if (t.contains(':')) {
                    final parts = t.split(':');
                    int h = int.tryParse(parts[0]) ?? 0;
                    if (h >= 24) h -= 24;
                    return '$h:${parts[1]}';
                  }
                  if (t.length < 4) return t;
                  int h = int.tryParse(t.substring(0, 2)) ?? 0;
                  if (h >= 24) h -= 24;
                  return '$h:${t.substring(2, 4)}';
                }

                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    // 시작 시간으로 예약
                    if (start.isEmpty) return;
                    int h, m;
                    if (start.contains(':')) {
                      final parts = start.split(':');
                      h = int.tryParse(parts[0]) ?? 0;
                      m = int.tryParse(parts[1]) ?? 0;
                    } else {
                      h = int.tryParse(start.substring(0, 2)) ?? 0;
                      m = int.tryParse(start.substring(2, 4)) ?? 0;
                    }
                    if (h >= 24) h -= 24;
                    final station = radioProvider.recentlyListened
                        .firstWhere((s) => s.name == stationName, orElse: () => radioProvider.currentStation!);
                    radioProvider.addSchedule(TimeOfDay(hour: h, minute: m), station);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!.radioScheduleCompleteToast(title, fmt(start))),
                      backgroundColor: primaryColor,
                    ));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(fmt(start),
                              style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Icon(Icons.alarm_add, color: primaryColor.withOpacity(0.6), size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}