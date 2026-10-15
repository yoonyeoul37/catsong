import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/logo_eq_bars.dart';
import '../l10n/locale_holder.dart';

class SleepFocusScreen extends StatefulWidget {
  const SleepFocusScreen({super.key});

  @override
  State<SleepFocusScreen> createState() => _SleepFocusScreenState();
}

class _SleepFocusScreenState extends State<SleepFocusScreen> {
  /// 칸 이름 (저장은 한국어 그대로, 화면엔 언어에 맞게)
  static String _catLabel(String c) => switch (c) {
        '전체' => tr.all,
        '휴식' => tr.restLabel,
        '집중' => tr.focusLabel,
        '백색소음' => tr.whiteNoise,
        '기타' => tr.categoryEtc,
        _ => c,
      };
  String _selectedCategory = '전체';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);

    final categories = ['전체', '휴식', '집중', '백색소음', '기타'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: baseColor, size: 20),
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
        ),
        toolbarHeight: 64,
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: tr.restLabel,
                        style: GoogleFonts.doHyeon(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : baseColor, fontSize: 19),
                      ),
                      TextSpan(
                        text: tr.focusTitlePart,
                        style: GoogleFonts.doHyeon(
                            color: baseColor, fontSize: 19),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: LogoEqBars(),
                ),
              ],
            ),
            const SizedBox(height: 0),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                tr.restFocusSub,
                maxLines: 1,
                style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11.5),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            setState(() => _selectedCategory = category);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDarkMode ? Colors.white : const Color(0xFF17140F))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _catLabel(category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDarkMode ? const Color(0xFF24221F) : Colors.white)
                                    : baseColor.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nightlight_round,
                          size: 56, color: baseColor.withOpacity(0.25)),
                      const SizedBox(height: 16),
                      Text(
                        tr.comingSoonTitle,
                        style: TextStyle(
                          color: baseColor.withOpacity(0.55),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr.comingSoonCategory(_catLabel(_selectedCategory)),
                        style: TextStyle(
                          color: baseColor.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}