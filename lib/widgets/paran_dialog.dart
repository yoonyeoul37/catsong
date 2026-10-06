import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 파란소리 확인창·입력창 (아래에서 올라오는 카드) — 앱 전체가 같은 모양
///
/// 확인:  if (await showParanConfirm(context, title: '이 곡을 삭제할까요?', confirmLabel: '삭제', danger: true)) { ... }
/// 입력:  final name = await showParanInput(context, title: '재생목록 이름', initial: '...');
/// 고르기: final pick = await showParanChoice(context, ...);  // 0 = 취소, 1 = 큰 버튼, 2 = 작은 빨간 글씨

const _kBlue = Color(0xFF2589E8);
const _kRed = Color(0xFFE05A4F);

class _Pal {
  final Color sheet, card, ink, sub, line;
  const _Pal(this.sheet, this.card, this.ink, this.sub, this.line);
  static _Pal of(BuildContext context) {
    var dark = false;
    try {
      dark = context.read<ThemeProvider>().isDarkMode;
    } catch (_) {}
    return dark
        ? const _Pal(Color(0xFF26221C), Color(0xFF332E26), Color(0xFFF3EFE7), Color(0xFFA29A8B), Color(0x22FFFFFF))
        : const _Pal(Color(0xFFF4EFE5), Colors.white, Color(0xFF17140F), Color(0xFF8A8378), Color(0xFFE2DACB));
  }
}

void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

/// 공통 카드 틀 (손잡이 + 제목 + 설명 + 내용 + 큰 버튼 + 취소)
Future<int?> _paranSheet(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  required String confirmLabel,
  bool danger = false,
  String cancelLabel = '취소',
  String? extraLabel, // 작은 빨간 글씨 버튼 (예: 영구 삭제)
  bool Function()? canConfirm,
}) {
  final p = _Pal.of(context);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      // 키보드가 올라오면 카드도 같이 올라가게
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(color: p.ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(message, style: TextStyle(color: p.sub, fontSize: 13.5, height: 1.5)),
              ],
              if (body != null) ...[
                const SizedBox(height: 14),
                body,
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (canConfirm != null && !canConfirm()) return;
                    _vib();
                    Navigator.pop(ctx, 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger ? _kRed : _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: (danger ? _kRed : _kBlue).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(confirmLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              if (extraLabel != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 2),
                    style: TextButton.styleFrom(foregroundColor: _kRed),
                    child: Text(extraLabel, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, 0),
                  style: TextButton.styleFrom(foregroundColor: p.sub),
                  child: Text(cancelLabel, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 확인창: 큰 버튼을 누르면 true
Future<bool> showParanConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool danger = false,
  String cancelLabel = '취소',
}) async {
  final r = await _paranSheet(context,
      title: title, message: message, confirmLabel: confirmLabel, danger: danger, cancelLabel: cancelLabel);
  return r == 1;
}

/// 고르기 창: 0 = 취소, 1 = 큰 버튼, 2 = 작은 빨간 글씨
Future<int> showParanChoice(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  required String extraLabel,
  bool danger = false,
}) async {
  final r = await _paranSheet(context,
      title: title, message: message, confirmLabel: confirmLabel, danger: danger, extraLabel: extraLabel);
  return r ?? 0;
}

/// 입력창: 저장을 누르면 적은 글자(앞뒤 띄어쓰기 뺀 것), 취소면 null
Future<String?> showParanInput(
  BuildContext context, {
  required String title,
  String? message,
  String initial = '',
  String? hint,
  String confirmLabel = '저장',
}) async {
  final p = _Pal.of(context);
  final ctrl = TextEditingController(text: initial);
  ctrl.selection = TextSelection(baseOffset: 0, extentOffset: initial.length); // 바로 고쳐 쓰기 쉽게 전체 선택
  final r = await _paranSheet(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    canConfirm: () => ctrl.text.trim().isNotEmpty,
    body: TextField(
      controller: ctrl,
      autofocus: true,
      style: TextStyle(color: p.ink, fontSize: 15),
      cursorColor: _kBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.sub),
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
    ),
  );
  final text = ctrl.text.trim();
  return r == 1 && text.isNotEmpty ? text : null;
}
