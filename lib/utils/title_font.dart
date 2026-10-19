import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/locale_holder.dart';

/// 제목 글꼴 (도현) — 도현에 없는 글자를 쓰는 언어(베트남어)는 굵은 기본 글꼴로
/// (ư·ơ·ậ 같은 글자만 다른 글꼴로 바뀌어 섞여 보이는 것 막기)
TextStyle titleFont({Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, List<Shadow>? shadows}) {
  if (const ['vi', 'ru', 'tr', 'pl', 'uk', 'ro', 'cs', 'hu', 'hi', 'ar', 'ur'].any(tr.localeName.startsWith)) { // 도현 글꼴에 없는 글자 (ư · я · ş · ł …)
    return TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: letterSpacing, shadows: shadows);
  }
  return GoogleFonts.doHyeon(
      color: color, fontSize: fontSize, fontWeight: fontWeight, letterSpacing: letterSpacing, shadows: shadows);
}
