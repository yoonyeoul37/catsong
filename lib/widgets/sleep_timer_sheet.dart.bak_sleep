import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'paran_toast.dart';
import 'paran_dialog.dart';
import '../providers/theme_provider.dart';

// ── 라디오 창 색 (라이트: 베이지 · 다크: 어두운 갈색) — 창을 그릴 때마다 다크 모드인지 맞춤 ──
bool _rdDark = false;
Color get _rBg => _rdDark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
Color get _rCard => _rdDark ? const Color(0xFF3E3B37) : Colors.white;
Color get _rInk => _rdDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color get _rSub => _rdDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
Color get _rMuted => _rdDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
Color get _rLine => _rdDark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);

class SleepTimerSheet extends StatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int _selectedMinutes = 30;
  Duration _wheelDuration = Duration(minutes: 30);

  @override
  Widget build(BuildContext context) {
    _rdDark = context.watch<ThemeProvider>().isDarkMode; // 다크 모드 맞추기
    final l = AppLocalizations.of(context)!;
    final primaryColor = _rInk; // 먹색 (다크는 크림색)
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
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: _rBg,
        systemNavigationBarIconBrightness: _rdDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _rBg, // 베이지 (다른 고르는 창과 같게)
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
                color: _rLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _rCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bedtime_outlined,
                      color: _rSub, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.sleepTimer,
                          style: TextStyle(
                            color: _rInk,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 2),
                      Text(
                        radioProvider.isSleepTimerActive
                            ? l.sleepTimerActiveDesc
                            : l.sleepTimerDesc,
                        style: TextStyle(
                            color: _rSub, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ParanCloseX(onTap: () => Navigator.pop(context)), // 닫기
              ],
            ),
            SizedBox(height: 20),

            if (radioProvider.isSleepTimerActive && sleep != null) ...[
              Text(
                l.remainingTime,
                style: TextStyle(
                  color: _rSub,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _formatCountdown(sleep),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                ),
              ),
              SizedBox(height: 6),
              Text('', style: TextStyle(fontSize: 0)),
              Text(
                l.radioAfterEnd,
                style: TextStyle(
                  color: _rSub,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: _rLine),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  context.read<RadioProvider>().cancelSleepTimer();
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(
                    l.cancelTimerX,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('몇 시간 몇 분 후 정지할까요?',
                  style: TextStyle(color: _rInk, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(height: 3),
              Text('끝나기 1분 전부터 천천히 작아져요', style: TextStyle(color: _rSub, fontSize: 12)),
              SizedBox(
                height: 180,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: _rdDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(color: _rInk, fontSize: 20),
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
              SizedBox(height: 16),

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
                    foregroundColor: _rBg,
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.25),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l.set, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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