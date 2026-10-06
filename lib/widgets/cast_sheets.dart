import 'package:flutter/material.dart';
import '../services/cast_service.dart';
import 'paran_toast.dart';
import 'paran_dialog.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// ── TV 창 색 (라이트: 베이지 · 다크: 어두운 갈색) — 창을 열 때 다크 모드인지 맞춤 ──
bool _tvDark = false;
Color get _cBg => _tvDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
Color get _cCard => _tvDark ? const Color(0xFF332E26) : Colors.white;
Color get _cInk => _tvDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color get _cSub => _tvDark ? const Color(0xFFA29A8B) : const Color(0xFF8A857B);
Color get _cMuted => _tvDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
Color get _cLine => _tvDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);


/// TV 찾아서 고르기 (라디오 화면에서 사용)
/// onPick: 고른 TV로 보내기 → 성공하면 true
void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick}) {
  _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      Future<List<CastDevice>> search = CastService.instance.discover();
      return StatefulBuilder(builder: (ctx, setSheet) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            decoration: BoxDecoration(color: _cBg, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: _cLine, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                // 제목 + ✕
                Row(
                  children: [
                    Expanded(
                      child: Text('TV로 듣기',
                          style: TextStyle(color: _cInk, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    ),
                    ParanCloseX(onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<List<CastDevice>>(
                  future: search,
                  builder: (_, snap) {
                    // ① 찾는 중
                    if (snap.connectionState != ConnectionState.done) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _cSub),
                            ),
                            const SizedBox(width: 10),
                            Text('같은 와이파이의 TV를 찾고 있어요', style: TextStyle(color: _cSub, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    final devices = snap.data ?? [];
                    // ③ 못 찾음
                    if (devices.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TV를 못 찾았어요',
                                style: TextStyle(color: _cInk, fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('TV가 켜져 있고 같은 와이파이인지 확인해 주세요',
                                style: TextStyle(color: _cSub, fontSize: 12.5, height: 1.5)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                setSheet(() => search = CastService.instance.discover());
                              },
                              child: Text('다시 찾기',
                                  style: TextStyle(
                                      color: _cInk,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      );
                    }
                    // ② 찾음: 줄 목록
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final d in devices)
                          InkWell(
                            onTap: () async {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              Navigator.pop(ctx);
                              final ok = await onPick(d);
                              if (!ok && context.mounted) {
                                showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cLine, width: 0.5))),
                              child: Row(
                                children: [
                                  Icon(d.kind == CastKind.google ? Icons.cast_rounded : Icons.tv_rounded,
                                      color: _cSub, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(d.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: _cInk, fontSize: 14.5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              Icon(Icons.wifi_rounded, color: _cSub, size: 14),
                              const SizedBox(width: 6),
                              Text('같은 와이파이의 TV만 보여요', style: TextStyle(color: _cSub, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

/// TV로 듣는 중: 일시정지 / 연결 끊기
void showCastControlSheet(BuildContext context, {String? nowPlaying}) {
  _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AnimatedBuilder(
      animation: CastService.instance,
      builder: (ctx, _) {
        final cast = CastService.instance;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            decoration: BoxDecoration(color: _cBg, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: _cLine, borderRadius: BorderRadius.circular(2)),
                ),
                Align(alignment: Alignment.centerRight, child: ParanCloseX(onTap: () => Navigator.pop(ctx))),
                // 가운데: TV · 이름 · 지금 나오는 것
                Icon(Icons.tv_rounded, color: _cInk, size: 44),
                const SizedBox(height: 6),
                Text(cast.device?.name ?? 'TV',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cInk, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text(
                  nowPlaying ?? (cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _cSub, fontSize: 12.5),
                ),
                const SizedBox(height: 20),
                // 먹색 ⏯ 하나
                GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    cast.tvPlaying ? cast.pause() : cast.play();
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: _cInk, shape: BoxShape.circle),
                    child: Icon(cast.tvPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _cBg, size: 32),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.pop(ctx);
                    await cast.disconnect();
                  },
                  child: Text('연결 끊기',
                      style: TextStyle(color: _cSub, fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}