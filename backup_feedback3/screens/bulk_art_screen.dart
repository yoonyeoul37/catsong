import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../services/music_lookup.dart';

/// 앨범 사진 한꺼번에 찾기: 앨범 사진 없는 곡마다 인터넷에서 후보를 찾아 보여주고, 체크한 곡만 넣음
class BulkArtScreen extends StatefulWidget {
  const BulkArtScreen({super.key});

  @override
  State<BulkArtScreen> createState() => _BulkArtScreenState();
}

class _ArtItem {
  final Song song;
  List<LookupResult> results = [];
  LookupResult? pick; // 고른 후보
  bool searched = false; // 찾기 끝났는지
  bool checked = false;
  _ArtItem(this.song);
}

class _BulkArtScreenState extends State<BulkArtScreen> {
  static const _blue = Color(0xFF2589E8);
  List<_ArtItem> _items = [];
  bool _ready = false;
  bool _searchingAll = false;
  bool _working = false;
  int _done = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true; // 화면 닫으면 찾기 멈춤
    super.dispose();
  }

  /// 비교용: 소문자 + 공백·기호·괄호 내용 빼기
  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\(\[].*?[\)\]]'), '')
      .replaceAll(RegExp(r'[^0-9a-z가-힣ぁ-んァ-ン一-龥]'), '');

  /// 제목이 거의 같으면 "맞는 곡"으로 보고 미리 체크
  bool _looksSame(Song s, LookupResult r) {
    final a = _norm(s.titleDisplay), b = _norm(r.title);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  void _scan(MusicProvider music) {
    _items = [
      for (final s in music.allSongs)
        if (s.albumArt == null && !music.isCallRecordingPath(s.uri)) _ArtItem(s),
    ];
    _ready = true;
    if (_items.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _searchAll());
  }

  /// 한 번에 3곡씩 천천히 찾기 (너무 빨리 많이 물어보면 막힐 수 있어서)
  Future<void> _searchAll() async {
    if (_searchingAll) return;
    setState(() => _searchingAll = true);
    final queue = List<_ArtItem>.from(_items);
    Future<void> worker() async {
      while (queue.isNotEmpty && !_disposed) {
        final it = queue.removeAt(0);
        final res = await lookupSong(it.song.titleDisplay, it.song.artistDisplay);
        if (_disposed) return;
        it.results = res.take(5).toList();
        it.pick = it.results.isNotEmpty ? it.results.first : null;
        it.checked = it.pick != null && _looksSame(it.song, it.pick!);
        it.searched = true;
        if (mounted) setState(() {});
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    await Future.wait([worker(), worker(), worker()]);
    if (mounted) setState(() => _searchingAll = false);
  }

  int get _checkedCount => _items.where((e) => e.checked && e.pick != null).length;
  int get _searchedCount => _items.where((e) => e.searched).length;

  /// 다른 후보 고르기
  Future<void> _choose(_ArtItem it, bool isDark, Color ink, Color sub) async {
    if (it.results.isEmpty) return;
    final picked = await showModalBottomSheet<LookupResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF26221C) : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.song.titleDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('맞는 앨범 사진을 골라주세요', style: TextStyle(color: sub, fontSize: 12.5)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: it.results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final r = it.results[i];
                    final selected = identical(r, it.pick);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx, r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(r.thumbUrl, width: 52, height: 52, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(width: 52, height: 52, color: sub.withOpacity(0.2))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('${r.artist} · ${r.album}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: sub, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            if (selected) const Icon(Icons.check_circle, color: _blue, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: sub),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      it.pick = picked;
      it.checked = true;
    });
  }

  Future<void> _apply() async {
    final targets = _items.where((e) => e.checked && e.pick != null).toList();
    if (targets.isEmpty || _working) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final music = context.read<MusicProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _working = true;
      _done = 0;
    });
    var ok = 0;
    for (final it in targets) {
      final bytes = await downloadArt(it.pick!.artUrl);
      if (bytes != null) {
        await music.setCustomArt(it.song, bytes);
        // 앨범 이름이 비어 있으면 같이 채우기 (제목·가수는 그대로)
        final album = it.song.albumDisplay;
        if (album.isEmpty || album.contains('알 수 없') || album.toLowerCase().contains('unknown')) {
          await music.updateSongInfo(it.song, album: it.pick!.album);
        }
        ok++;
      }
      if (!mounted) return;
      setState(() => _done++);
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('$ok곡에 앨범 사진을 넣었어요')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF26221C) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final music = context.watch<MusicProvider>();

    AppBar bar({List<Widget>? actions}) => AppBar(
      backgroundColor: bg,
      elevation: 0,
      leading: IconButton(
        onPressed: _working ? null : () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),
      ),
      title: Text('앨범 사진 한꺼번에 찾기',
          style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
      actions: actions,
    );

    // 곡 정보를 아직 읽는 중이면 기다리기
    if (music.isLoading || music.metaLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: bar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)),
              const SizedBox(height: 16),
              Text('곡 정보를 읽는 중이에요', style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('잠시만 기다려 주세요', style: TextStyle(color: sub, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    if (!_ready) _scan(music);

    final found = _items.where((e) => e.pick != null).toList();
    final allChecked = found.isNotEmpty && found.every((e) => e.checked);

    return Scaffold(
      backgroundColor: bg,
      appBar: bar(actions: [
        if (found.isNotEmpty && !_working)
          TextButton(
            onPressed: () => setState(() {
              for (final e in found) {
                e.checked = !allChecked;
              }
            }),
            style: TextButton.styleFrom(foregroundColor: _blue),
            child: Text(allChecked ? '전체 해제' : '전체 선택',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
      ]),
      body: _items.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, color: _blue, size: 40),
            const SizedBox(height: 14),
            Text('앨범 사진이 없는 곡이 없어요',
                style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('모든 곡에 앨범 사진이 있어요', style: TextStyle(color: sub, fontSize: 13)),
          ],
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                if (_searchingAll)
                  const SizedBox(
                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
                else
                  const Icon(Icons.travel_explore, color: _blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _searchingAll
                        ? '인터넷에서 찾는 중… $_searchedCount / ${_items.length}'
                        : '앨범 사진 없는 곡 ${_items.length}개 · 찾은 곡 ${found.length}개',
                    style: TextStyle(color: sub, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final it = _items[i];
                final p = it.pick;
                return Material(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: (_working || p == null) ? null : () => setState(() => it.checked = !it.checked),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: it.checked,
                            activeColor: _blue,
                            onChanged: (_working || p == null)
                                ? null
                                : (v) => setState(() => it.checked = v ?? false),
                          ),
                          // 찾은 앨범 사진
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: p != null
                                  ? Image.network(p.thumbUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: sub.withOpacity(0.2)))
                                  : Container(
                                color: sub.withOpacity(0.15),
                                alignment: Alignment.center,
                                child: it.searched
                                    ? Icon(Icons.music_off_outlined, color: sub, size: 20)
                                    : const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _blue)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.song.titleDisplay,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                  p != null
                                      ? '${p.artist} · ${p.album}'
                                      : (it.searched ? '인터넷에서 못 찾았어요' : '찾는 중…'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: sub, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          // 다른 후보 고르기
                          if (it.results.length > 1)
                            IconButton(
                              onPressed: _working ? null : () => _choose(it, isDark, ink, sub),
                              icon: Icon(Icons.swap_horiz_rounded, color: sub, size: 22),
                              tooltip: '다른 후보',
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_checkedCount == 0 || _working) ? null : _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _blue.withOpacity(0.4),
                disabledForegroundColor: Colors.white,
                elevation: 6,
                shadowColor: _blue.withOpacity(0.45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _working ? '넣는 중… $_done / $_checkedCount' : '$_checkedCount곡에 앨범 사진 넣기',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}