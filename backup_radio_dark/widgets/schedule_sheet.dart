import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'action_feedback.dart';
import 'paran_toast.dart';
import 'paran_dialog.dart';
import 'package:flutter/services.dart';

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({super.key});

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  TimeOfDay? _selectedTime;
  RadioStation? _selectedStation;

  // 화면 공통 색
  static const _bg = Color(0xFFF4EFE5);
  static const _ink = Color(0xFF17140F);
  static const _sub = Color(0xFF8A8378);
  static const _line = Color(0xFFE2DACB);

  void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  /// 지금부터 그 시간까지 남은 시간 ("2시간 뒤", "35분 뒤")
  String _until(TimeOfDay t) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    final d = target.difference(now);
    if (d.inMinutes < 60) return '${d.inMinutes}분 뒤';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h시간 뒤' : '$h시간 $m분 뒤';
  }

  TimeOfDay _after(int minutes) {
    final t = DateTime.now().add(Duration(minutes: minutes));
    return TimeOfDay(hour: t.hour, minute: t.minute);
  }

  Future<void> _pickTime() async {
    _vib();
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _ink, onPrimary: _bg, surface: _bg, onSurface: _ink),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Widget _step(int n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),
              child: Text('$n', style: const TextStyle(color: _bg, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _quick(String label, TimeOfDay t) {
    final on = _selectedTime == t;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _vib();
          setState(() => _selectedTime = on ? null : t); // 다시 누르면 선택 풀기
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? _ink : _bg, borderRadius: BorderRadius.circular(10)),
          child: Text(label,
              style: TextStyle(color: on ? _bg : const Color(0xFF5A5348), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final schedules = radioProvider.schedules;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final stationList = radioProvider.currentQueue.isNotEmpty
        ? radioProvider.currentQueue
        : radioProvider.recentlyListened;
    final canAdd = schedules.length < 5;

    Widget section(String text, {Widget? right}) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            children: [
              Expanded(child: Text(text, style: const TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600))),
              if (right != null) right,
            ],
          ),
        );

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            // 위: 제목 · 개수
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text('예약',
                        style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
                  Text('${schedules.length} / 5', style: const TextStyle(color: _sub, fontSize: 12.5)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text('정한 시간이 되면 그 방송으로 바꿔줘요', style: TextStyle(color: _sub, fontSize: 12.5)),
            ),

            // ───── 내 예약 ─────
            if (schedules.isNotEmpty) ...[
              section('내 예약',
                  right: GestureDetector(
                    onTap: () async {
                      final ok = await showParanConfirm(context,
                          title: '예약을 전부 취소할까요?', confirmLabel: '전체 취소', danger: true);
                      if (!ok || !context.mounted) return;
                      radioProvider.clearSchedules();
                      showActionFeedback(context, type: ActionFeedbackType.deleted, message: '예약을 취소했어요');
                    },
                    child: const Text('전체 취소',
                        style: TextStyle(color: Color(0xFFE05A4F), fontSize: 12, fontWeight: FontWeight.w600)),
                  )),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    for (var i = 0; i < schedules.length; i++) ...[
                      if (i > 0) Container(height: 0.5, color: const Color(0xFFEEE9DF)),
                      Opacity(
                        opacity: schedules[i].triggered ? 0.45 : 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 68,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(schedules[i].time.period == DayPeriod.am ? '오전' : '오후',
                                        style: const TextStyle(color: _sub, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                    Text(
                                        '${schedules[i].time.hourOfPeriod == 0 ? 12 : schedules[i].time.hourOfPeriod}:${schedules[i].time.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(schedules[i].station.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(schedules[i].triggered ? '바꿨어요 ✓' : _until(schedules[i].time),
                                        style: const TextStyle(color: _sub, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _vib();
                                  radioProvider.removeSchedule(i);
                                },
                                icon: const Icon(Icons.close_rounded, color: Color(0xFFB5AC9C), size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ───── 새 예약 (1 시간 → 2 방송) ─────
            if (canAdd) ...[
              section('새 예약'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _step(1, '몇 시에?'),
                    // 시간 칸: 누르면 시계로 직접 맞추기
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedTime != null ? _formatTime(_selectedTime!) : '시간 고르기',
                                style: TextStyle(
                                  color: _selectedTime != null ? _ink : _sub,
                                  fontSize: _selectedTime != null ? 22 : 15,
                                  fontWeight: _selectedTime != null ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(Icons.schedule_rounded, color: _sub, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _quick('30분 뒤', _after(30)),
                        const SizedBox(width: 6),
                        _quick('1시간 뒤', _after(60)),
                        const SizedBox(width: 6),
                        _quick('아침 7시', const TimeOfDay(hour: 7, minute: 0)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _step(2, '어떤 방송?'),
                    if (stationList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(AppLocalizations.of(context)!.radioPlayFirst,
                            style: const TextStyle(color: _sub, fontSize: 12.5)),
                      )
                    else
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: stationList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            final st = stationList[i];
                            final on = _selectedStation?.name == st.name;
                            return GestureDetector(
                              onTap: () {
                                _vib();
                                setState(() => _selectedStation = on ? null : st); // 다시 누르면 선택 풀기
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: on ? _ink : _bg, borderRadius: BorderRadius.circular(12)),
                                child: Text(st.name,
                                    style: TextStyle(
                                        color: on ? Colors.white : const Color(0xFF5A5348),
                                        fontSize: 12.5,
                                        fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                              ),
                            );
                          },
                        ),
                      ),
                    // 편성표에서 프로그램으로 고르기 (방송을 먼저 고르면)
                    if (stationList.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          final st = _selectedStation ?? stationList.first;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => _ScheduleListBottomSheet(stationName: st.name),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(Icons.format_list_bulleted_rounded, color: _sub, size: 16),
                              SizedBox(width: 5),
                              Text('편성표에서 프로그램으로 고르기',
                                  style: TextStyle(color: _sub, fontSize: 12, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedTime != null && _selectedStation != null
                      ? () {
                          _vib();
                          radioProvider.addSchedule(_selectedTime!, _selectedStation!);
                          setState(() {
                            _selectedTime = null;
                            _selectedStation = null;
                          });
                          showActionFeedback(context,
                              type: ActionFeedbackType.saved, message: '예약했어요', icon: Icons.schedule_rounded);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: _bg,
                    disabledBackgroundColor: _ink.withOpacity(0.25),
                    disabledForegroundColor: _bg,
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('예약하기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 14, 4, 0),
                child: Text('예약은 5개까지예요. 지난 예약을 지우면 새로 넣을 수 있어요',
                    style: TextStyle(color: _sub, fontSize: 12.5)),
              ),
          ],
        ),
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
    const primaryColor = Color(0xFF17140F); // 먹색 (다른 창과 통일)
    final radioProvider = context.watch<RadioProvider>();
    final schedules = radioProvider.scheduleList;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4EFE5), // 베이지 (다른 고르는 창과 같게)
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2DACB),
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
                      color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(color: Colors.black45)),
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
                    showParanToast(context, AppLocalizations.of(context)!.radioScheduleCompleteToast(title, fmt(start)));
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
                              style: const TextStyle(color: Colors.black45, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(color: Colors.black87, fontSize: 14),
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