import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 포인트 색 꺼내기 — 앱 어디서든 이것 하나만 쓰기 (화면마다 파랑이 달라지지 않게)
/// - 기본(파란소리)이면: 밝은 바탕 #2F7DE8 (로고 파랑) / 어두운 바탕 #6FB0FF
/// - 다른 색이면: 그 색 그대로 (어두운 바탕에서 너무 어두운 색이면 살짝 밝게)
/// - onDark: 바탕이 어두운지 직접 정할 때 (예: 먹색 미니플레이어 = true, 흰 알림 = false)
///   안 정하면 다크 모드인지로 정함
Color pointColorOf(BuildContext context, {bool? onDark}) {
  Theme.of(context); // 색이 바뀌면 다시 그리기
  ThemeProvider? t;
  try {
    t = Provider.of<ThemeProvider>(context, listen: false);
  } catch (_) {}
  final dark = onDark ?? (t?.isDarkMode ?? false);
  final p = t?.primaryColor ?? const Color(0xFF2589E8);
  if (p.value == 0xFF2589E8) {
    return dark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8);
  }
  if (dark && p.computeLuminance() < 0.08) return Color.lerp(p, Colors.white, 0.45)!;
  return p;
}
