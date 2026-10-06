import 'dart:typed_data';
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
                    // 큰 버튼: 먹색 고정 (다크 모드는 크림색) · 삭제처럼 위험한 건 빨강
                    backgroundColor: danger ? _kRed : p.ink,
                    foregroundColor: danger ? Colors.white : p.sheet,
                    elevation: 6,
                    shadowColor: danger ? _kRed.withOpacity(0.4) : Colors.black.withOpacity(0.25),
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
      cursorColor: p.ink, // 먹색 버튼과 맞춤
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
          borderSide: BorderSide(color: p.ink, width: 1.5), // 먹색 버튼과 맞춤
        ),
      ),
    ),
  );
  final text = ctrl.text.trim();
  return r == 1 && text.isNotEmpty ? text : null;
}

// ───────────────────────── 고르는 창 ─────────────────────────

/// 고르는 창 (아래에서 올라오는 베이지 카드 + 손잡이 + 제목 + 내용 + 닫기)
/// builder 안에서 setSheet(() {}) 를 부르면 창 안이 다시 그려져요
Future<T?> showParanSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext ctx, StateSetter setSheet) builder,
  Widget? header, // 제목 대신 넣을 머리 (곡 정보처럼 사진+제목)
  String closeLabel = '닫기',
}) {
  final p = _Pal.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(22)),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
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
              const SizedBox(height: 14),
              header ??
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(title,
                        style: TextStyle(color: p.ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
              Flexible(child: SingleChildScrollView(child: builder(ctx, setSheet))),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: p.sub),
                  child: Text(closeLabel, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 고르는 창 안의 흰 카드 (줄 사이 얇은 선)
class ParanCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  const ParanCard({super.key, required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding,
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0 && padding == null) Container(height: 0.5, margin: const EdgeInsets.only(left: 46), color: p.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 카드 안의 한 줄 (아이콘 · 글자 · 오른쪽 작은 글씨 · 고르면 파란 ✓)
class ParanRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? trailingText;
  final bool selected;
  final bool accent; // 글자를 파랗게 (예: 새로 만들기)
  final bool danger; // 빨갛게 (예: 삭제)
  final VoidCallback? onTap; // 없으면 흐리게 (누를 수 없음)
  const ParanRow({
    super.key,
    this.icon,
    required this.title,
    this.trailingText,
    this.selected = false,
    this.accent = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
      onTap: onTap == null
          ? null
          : () {
              _vib();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              // 아이콘은 차분한 회색 (새로 만들기만 파랑, 삭제는 빨강)
              SizedBox(width: 22, child: Icon(icon, color: danger ? _kRed : (accent ? _kBlue : p.sub), size: 20)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: danger ? _kRed : (accent || selected ? _kBlue : p.ink),
                    fontSize: 14,
                    fontWeight: accent || selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(trailingText!, style: TextStyle(color: p.sub, fontSize: 12.5)),
            ],
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: _kBlue, size: 20),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

/// 정보 한 줄 (왼쪽 이름 · 오른쪽 값) — 곡 정보 등
class ParanInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const ParanInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: Text(label, style: TextStyle(color: p.sub, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: p.ink, fontSize: 13.5, height: 1.4))),
        ],
      ),
    );
  }
}

/// 고르는 창 안의 큰 파란 버튼 (확인창 버튼과 같은 모양)
class ParanBigButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const ParanBigButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            _vib();
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            // 큰 버튼: 먹색 고정 (다크 모드는 크림색)
            backgroundColor: p.ink,
            foregroundColor: p.sheet,
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// 이미 만들어진 내용(배속·수면 타이머 등)을 베이지 카드 틀에 넣기
class ParanSheetFrame extends StatelessWidget {
  final Widget child;
  const ParanSheetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// 곡 정보 창 머리 (앨범 사진 + 제목 + 가수)
class ParanSongHeader extends StatelessWidget {
  final List<int>? art;
  final String title;
  final String subtitle;
  const ParanSongHeader({super.key, this.art, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: art != null
                  ? Image.memory(Uint8List.fromList(art!), fit: BoxFit.cover)
                  : Container(
                      color: _kBlue.withOpacity(0.15),
                      child: const Icon(Icons.music_note_rounded, color: _kBlue, size: 26),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.sub, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
