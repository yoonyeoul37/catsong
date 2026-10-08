import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

/// 위에 사진(+ Paransori)이 들어간 알림창 (리뷰·업데이트 공통)
/// 큰 버튼을 누르면 true, "나중에"를 누르면 false
Future<bool> showPhotoDialog(
    BuildContext context, {
      required String image,
      required String title,
      required String message,
      required String primary,
      required String secondary,
      IconData? primaryIcon,
      bool stars = false,
      bool barrierDismissible = true,
    }) async {
  final isDark = context.read<ThemeProvider>().isDarkMode;
  final accent = Theme.of(context).colorScheme.primary;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final bg = isDark ? const Color(0xFF1F1B16) : Colors.white;
      final titleColor = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
      final subColor = isDark ? const Color(0xFFA29A8B) : const Color(0xFFA39C90);
      return Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParanBanner(image: image, bg: bg, isDark: isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              child: Column(
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: titleColor, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  if (stars) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                            (_) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(Icons.star_rounded, color: Color(0xFFF5B83D), size: 26),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subColor, fontSize: 12.5, height: 1.5)),
                  const SizedBox(height: 18),
                  // 큰 버튼 (살짝 떠 보이게)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: accent.withOpacity(0.45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (primaryIcon != null) ...[
                            Icon(primaryIcon, size: 19),
                            const SizedBox(width: 6),
                          ],
                          Text(primary, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  // 작은 "나중에"
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(foregroundColor: subColor),
                    child: Text(secondary, style: const TextStyle(fontSize: 13)),
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

/// 알림창 위 그림 + 그림과 글 사이 가운데 Paransori (종료·리뷰·업데이트 공통)
/// 그림 아래쪽이 창 바탕색으로 스며들어 경계가 안 보이고, 그 자리에 로고
class ParanBanner extends StatelessWidget {
final String image;
final Color bg; // 창 바탕색 (그림이 이 색으로 스며듦)
final bool isDark;
const ParanBanner({super.key, required this.image, required this.bg, this.isDark = false});

@override
Widget build(BuildContext context) {
return Column(
mainAxisSize: MainAxisSize.min,
children: [
AspectRatio(
aspectRatio: 2.2,
child: Stack(
fit: StackFit.expand,
children: [
// 새 그림은 가운데에 있어서 가운데 기준
Image.asset(image, fit: BoxFit.cover, alignment: Alignment.center),
// 아래 40%가 창 바탕색으로 스르륵
DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [bg.withOpacity(0), bg.withOpacity(0), bg],
stops: const [0.0, 0.6, 1.0],
),
),
),
],
),
),
// 경계 가운데 Paransori (그림 끝에 살짝 걸치게)
Transform.translate(
offset: const Offset(0, -8),
child: Text(
'Paransori',
style: GoogleFonts.quicksand(
color: isDark ? const Color(0xFF8A8378) : const Color(0xFFA39C90),
  fontSize: 12.5,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
),
),
),
],
);
}
}