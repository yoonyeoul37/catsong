import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SleepFocusScreen extends StatefulWidget {
  const SleepFocusScreen({super.key});

  @override
  State<SleepFocusScreen> createState() => _SleepFocusScreenState();
}

class _SleepFocusScreenState extends State<SleepFocusScreen> {
  String _selectedCategory = '전체';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);

    final categories = ['전체', '수면', '명상', '백색소음', '기타'];

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
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '수면',
                    style: GoogleFonts.doHyeon(
                        color: const Color(0xFF2F7DE8), fontSize: 19),
                  ),
                  TextSpan(
                    text: ' · 명상',
                    style: GoogleFonts.doHyeon(
                        color: baseColor, fontSize: 19),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            Text(
              '편안한 소리로 잠들고, 마음을 가다듬어보세요',
              style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11.5),
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
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDarkMode ? const Color(0xFF17140F) : Colors.white)
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
                        '준비중입니다',
                        style: TextStyle(
                          color: baseColor.withOpacity(0.55),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_selectedCategory 콘텐츠를 곧 만나보실 수 있어요',
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