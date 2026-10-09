import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'photo_dialog.dart' show ParanBanner;

/// 종료 확인창 (홈·음악·라디오·자연소리 공통)
/// 위: 그림(아래로 스며듦) + 경계 가운데 Paransori / 가운데: "종료하시겠어요?" / 아래: 계속 듣기 · 종료
/// 종료를 누르면 true
Future<bool> showExitConfirm(BuildContext context) async {
  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
  final isDark = context.read<ThemeProvider>().isDarkMode;
  final l = AppLocalizations.of(context)!;
  final primary = Theme.of(context).colorScheme.primary;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final bg = isDark ? const Color(0xFF2B2926) : Colors.white;
      final titleColor = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
      final subColor = isDark ? const Color(0xFFB8B0A2) : const Color(0xFFA39C90);
      return Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그림 + 경계 가운데 Paransori (업데이트·리뷰 창과 같은 부품)
            ParanBanner(
              image: isDark ? 'assets/exit_banner_night.jpg' : 'assets/exit_banner.jpg',
              bg: bg,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: Column(
                children: [
                  // 질문은 크고 굵게
                  Text(
                    '종료하시겠어요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: titleColor, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 6),
                  // 인사는 작고 연하게
                  Text(
                    l.musicExitConfirmMessage.replaceAll('.', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subColor, fontSize: 12.5),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              Navigator.pop(ctx, false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF5A5348),
                              backgroundColor: isDark ? const Color(0xFF353330) : Colors.white,
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2DACB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              // 살짝 떠 보이게 연한 그림자
                              elevation: 3,
                              shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
                            ),
                            child: Text(l.radioExitKeepListening, style: const TextStyle(fontSize: 14.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              Navigator.pop(ctx, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              // 파란빛 그림자로 떠 보이게
                              elevation: 6,
                              shadowColor: primary.withOpacity(0.45),
                            ),
                            child: Text(l.radioExitConfirmButton,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  return ok == true;
}