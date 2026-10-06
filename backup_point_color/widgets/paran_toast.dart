import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 파란소리 하단 알림 (오류·안내·되돌리기용) — 앱 전체가 같은 모양
/// - 안내: showParanToast(context, '마이크 권한이 필요해요');
/// - 오류: showParanToast(context, 'TV로 보내지 못했어요', error: true);
/// - 되돌리기: showParanToast(context, '37곡을 정리했어요', actionLabel: '되돌리기', onAction: () {...});
void showParanToast(
  BuildContext context,
  String message, {
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  var isDark = false;
  try {
    isDark = context.read<ThemeProvider>().isDarkMode;
  } catch (_) {}
  const blue = Color(0xFF2589E8);
  const red = Color(0xFFE05A4F);
  final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.fromLTRB(16, 12, actionLabel != null ? 6 : 16, 12),
      elevation: 6,
      backgroundColor: isDark ? const Color(0xFF2A251E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      // 버튼이 있으면 누를 시간을 넉넉하게
      duration: duration ?? Duration(seconds: actionLabel != null ? 8 : 3),
      content: Row(
        children: [
          Icon(error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: error ? red : blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500, height: 1.35)),
          ),
        ],
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, textColor: blue, onPressed: onAction ?? () {}),
    ));
}
