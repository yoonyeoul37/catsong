import 'package:flutter/material.dart';
import '../services/cast_service.dart';

/// TV 찾아서 고르기 (라디오 화면에서 사용)
/// onPick: 고른 TV로 보내기 → 성공하면 true
void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      Future<List<CastDevice>> search = CastService.instance.discover();
      return StatefulBuilder(builder: (ctx, setSheet) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: FutureBuilder<List<CastDevice>>(
              future: search,
              builder: (ctx, snap) {
                final title = Row(
                  children: [
                    const Icon(Icons.cast, color: Color(0xFF2589E8), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('TV로 듣기',
                          style: TextStyle(color: Color(0xFF17140F), fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.black45),
                    ),
                  ],
                );
                if (snap.connectionState != ConnectionState.done) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    title,
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(color: Color(0xFF2589E8)),
                    const SizedBox(height: 12),
                    const Text('같은 와이파이에 있는 TV를 찾고 있어요',
                        style: TextStyle(color: Color(0xFF8A857B), fontSize: 13)),
                    const SizedBox(height: 18),
                  ]);
                }
                final devices = snap.data ?? [];
                if (devices.isEmpty) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    title,
                    const SizedBox(height: 14),
                    const Text('TV를 못 찾았어요.\nTV가 켜져 있고 폰과 같은 와이파이인지 확인해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF5A5348), fontSize: 13, height: 1.5)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setSheet(() => search = CastService.instance.discover()),
                      child: const Text('다시 찾기', style: TextStyle(color: Color(0xFF2589E8))),
                    ),
                  ]);
                }
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  title,
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      for (final d in devices)
                        ListTile(
                          leading: Icon(d.kind == CastKind.google ? Icons.cast : Icons.tv,
                              color: const Color(0xFF2589E8)),
                          title: Text(d.name, style: const TextStyle(color: Color(0xFF17140F))),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final ok = await onPick(d);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('TV로 보내지 못했어요. 다시 시도해 주세요.'),
                              ));
                            }
                          },
                        ),
                    ]),
                  ),
                  const SizedBox(height: 6),
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
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cast_connected, color: Color(0xFF2589E8), size: 30),
                const SizedBox(height: 8),
                Text(cast.device?.name ?? 'TV',
                    style: const TextStyle(color: Color(0xFF17140F), fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지',
                    style: const TextStyle(color: Color(0xFF8A857B), fontSize: 12.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => cast.tvPlaying ? cast.pause() : cast.play(),
                        icon: Icon(cast.tvPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(cast.tvPlaying ? '일시정지' : '재생'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2589E8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await cast.disconnect();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5A5348),
                          side: const BorderSide(color: Color(0xFFE2DACB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('연결 끊기'),
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