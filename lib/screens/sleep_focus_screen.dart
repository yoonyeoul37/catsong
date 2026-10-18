import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../utils/title_font.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/logo_shine.dart';
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
        centerTitle: true,
        // 라디오·자연·휴식 같은 위쪽: 앱 아이콘 + 제목 / 설명
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 + 제목(회색 빛) / 아래 설명 — 홈 로고와 같은 짜임 (해외는 그 나라 말)
            Flexible(child: MenuTitle(title: tr.catRest, sub: tr.catRestSub, isDark: isDarkMode)),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
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