import 'package:flutter/material.dart';
import '../services/cast_service.dart';
import 'paran_toast.dart';
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
            margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: BoxDecoration(
              color: _cBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: FutureBuilder<List<CastDevice>>(
              future: search,
              builder: (ctx, snap) {
                final title = Row(
                  children: [
                    Icon(Icons.cast, color: _cInk, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('TV로 듣기',
                          style: TextStyle(color: _cInk, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: _cSub),
                    ),
                  ],
                );
                if (snap.connectionState != ConnectionState.done) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    title,
                    SizedBox(height: 18),
                    CircularProgressIndicator(color: _cInk),
                    SizedBox(height: 12),
                    Text('같은 와이파이에 있는 TV를 찾고 있어요',
                        style: TextStyle(color: _cSub, fontSize: 13)),
                    SizedBox(height: 18),
                  ]);
                }
                final devices = snap.data ?? [];
                if (devices.isEmpty) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    title,
                    SizedBox(height: 14),
                    Text('TV를 못 찾았어요.\nTV가 켜져 있고 폰과 같은 와이파이인지 확인해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _cMuted, fontSize: 13, height: 1.5)),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setSheet(() => search = CastService.instance.discover()),
                      child: Text('다시 찾기', style: TextStyle(color: _cInk)),
                    ),
                  ]);
                }
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  title,
                  SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: _cCard, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      for (final d in devices)
                        ListTile(
                          leading: Icon(d.kind == CastKind.google ? Icons.cast : Icons.tv,
                              color: _cInk),
                          title: Text(d.name, style: TextStyle(color: _cInk)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final ok = await onPick(d);
                            if (!ok && context.mounted) {
                              showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);
                            }
                          },
                        ),
                    ]),
                  ),
                  SizedBox(height: 6),
                ]);
              },
            ),
          ),
        );
      });
    },
  );
}

/// TV로 듣는 중: 일시정지 / 연결 끊기
void showCastControlSheet(BuildContext context) {
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
            margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: _cBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cast_connected, color: _cInk, size: 30),
                SizedBox(height: 8),
                Text(cast.device?.name ?? 'TV',
                    style: TextStyle(color: _cInk, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text(cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지',
                    style: TextStyle(color: _cSub, fontSize: 12.5)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => cast.tvPlaying ? cast.pause() : cast.play(),
                        icon: Icon(cast.tvPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(cast.tvPlaying ? '일시정지' : '재생'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cInk,
                          foregroundColor: _cBg,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await cast.disconnect();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cMuted,
                          side: BorderSide(color: _cLine),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('연결 끊기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}