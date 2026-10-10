import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/song_title_cleaner.dart';
import '../services/music_lookup.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';

class EditSongScreen extends StatefulWidget {
  final Song song;
  const EditSongScreen({super.key, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  static const _accent = AppTheme.fixedAccent;
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;

  // 자동 정리: 열자마자 제목·가수를 깨끗하게 채워두고, "원래대로"로 되돌릴 수 있게
  late final String _origTitle = widget.song.titleDisplay;
  late final String _origArtist = widget.song.artistDisplay;
  late SongClean _cleaned;
  bool _canClean = false; // 정리할 게 있었는지
  bool _cleanedOn = false; // 지금 칸에 정리된 값이 들어가 있는지

  // 인터넷에서 찾기
  bool _searching = false;
  String? _pickedArt; // 고른 앨범 사진 주소 (저장할 때 받아서 넣음)
  // 검색 결과 넣기 전 값 (되돌리기용: 제목·가수·앨범·사진)
  (String, String, String, String?)? _beforePick;

  /// 검색 결과 넣기 전으로 되돌리기
  void _undoPick() {
    final b = _beforePick;
    if (b == null) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    setState(() {
      _titleController.text = b.$1;
      _artistController.text = b.$2;
      _albumController.text = b.$3;
      _pickedArt = b.$4;
      _beforePick = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // 내 노래 목록에 있는 가수 이름들 → "노래 - 가수" 순서도 알아봄
    final known = context
        .read<MusicProvider>()
        .artists
        .map((x) => x.name.toLowerCase().trim())
        .where((n) => n.isNotEmpty && !n.contains('unknown') && n != '알 수 없는 아티스트')
        .toSet();
    _cleaned = SongTitleCleaner.clean(_origTitle, _origArtist, knownArtists: known);
    _canClean = _cleaned.title != _origTitle || _cleaned.artist != _origArtist;
    _cleanedOn = _canClean;
    _titleController = TextEditingController(text: _canClean ? _cleaned.title : _origTitle);
    _artistController = TextEditingController(text: _canClean ? _cleaned.artist : _origArtist);
    _albumController = TextEditingController(text: widget.song.albumDisplay);
  }

  void _toggleClean() {
    setState(() {
      _cleanedOn = !_cleanedOn;
      _titleController.text = _cleanedOn ? _cleaned.title : _origTitle;
      _artistController.text = _cleanedOn ? _cleaned.artist : _origArtist;
    });
  }

  /// 🔍 인터넷에서 정확한 정보 찾기 → 후보 중에서 고르기 (영어 제목·가수는 한글로 바꿔서 보여줌)
  Future<void> _lookup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _searching = true);
    final results = await lookupSong(_titleController.text, _artistController.text);
    if (!mounted) return;
    setState(() => _searching = false);
    if (results.isEmpty) {
      showParanToast(context, '인터넷에서 이 곡을 찾지 못했어요');
      return;
    }
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final hangul = RegExp(r'[가-힣]');

    // 위에서 4개까지 한글로 바꿔서 보여주기 (1초에 하나씩 쓱 바뀜)
    final shown = List<LookupResult>.from(results);
    StateSetter? sheetSet;
    var open = true;
    () async {
      for (var i = 0; i < shown.length && i < 4; i++) {
        if (!open) return;
        final k = await koreanize(shown[i]);
        if (!open) return;
        if (!identical(k, shown[i])) {
          shown[i] = k;
          try {
            sheetSet?.call(() {});
          } catch (_) {}
        }
      }
    }();

    final picked = await showModalBottomSheet<LookupResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        sheetSet = setSheet;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5), // 다른 고르는 창과 같은 베이지
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이 곡이 맞나요?', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('찾는 곡을 선택하면 제목·가수·앨범·앨범 사진이 채워져요',
                    style: TextStyle(color: sub, fontSize: 12.5)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final r = shown[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(ctx, r),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(r.thumbUrl,
                                    width: 52, height: 52, fit: BoxFit.cover,
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
                                    // 한글로 바꿨으면 원래 영어는 작게
                                    if (r.koreanized)
                                      Text('${r.origTitle ?? r.title} · ${r.origArtist ?? r.artist}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: sub.withOpacity(0.7), fontSize: 11)),
                                  ],
                                ),
                              ),
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
                    child: const Text('찾는 곡이 없어요'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
    open = false;
    sheetSet = null;
    if (picked == null || !mounted) return;
    setState(() {
      // 되돌리기용: 넣기 전 값 (여러 번 골라도 맨 처음 값으로)
      _beforePick ??= (_titleController.text, _artistController.text, _albumController.text, _pickedArt);
      // 제목: 지금 한글인데 고른 게 영어면 한글 그대로
      final curTitle = _titleController.text.trim();
      _titleController.text =
          (hangul.hasMatch(curTitle) && !hangul.hasMatch(picked.title)) ? curTitle : picked.title;
      // 가수: 지금 한글인데 고른 게 영어면 한글 그대로 (아이유 → IU 방지)
      final curArtist = _artistController.text.trim();
      final keepKorean =
          hangul.hasMatch(curArtist) && !hangul.hasMatch(picked.artist) && !curArtist.contains('알 수 없');
      _artistController.text = keepKorean ? curArtist : picked.artist;
      _albumController.text = picked.album;
      _pickedArt = picked.artUrl;
    });
    // 아래쪽 후보라 목록에서 못 바꿨으면 → 고른 다음 한글로 한 번 더 (Kim Hyun Sik → 김현식)
    if (!picked.koreanized &&
        (!hangul.hasMatch(_artistController.text) || !hangul.hasMatch(_titleController.text))) {
      final k = await koreanize(picked);
      if (!mounted || identical(k, picked)) return;
      setState(() {
        if (!hangul.hasMatch(_artistController.text)) _artistController.text = k.artist;
        if (!hangul.hasMatch(_titleController.text)) _titleController.text = k.title;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    // ── 화면 공통 모양 (베이지 바탕 · 흰 카드 · 먹색 큰 버튼) ──
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF32302C) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = isDark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);

    Widget section(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(text, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
        );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: Text(AppLocalizations.of(context)!.editSong,
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 20),
        ),
      ),
      // 버튼은 맨 아래에 모아서: 인터넷에서 찾기(흰) · 저장(먹색)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _searching ? null : _lookup,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: card,
                    foregroundColor: ink,
                    side: BorderSide(color: line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _searching
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ink))
                      : const Icon(Icons.travel_explore_rounded, size: 20),
                  label: Text(_searching ? '찾는 중…' : '인터넷에서 정확한 정보 찾기',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _saveSong(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: bg,
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(AppLocalizations.of(context)!.save,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 앨범 사진: 고른 사진 → 원래 앨범 사진 → 없으면 음표
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: _pickedArt != null
                      ? Image.network(_pickedArt!, fit: BoxFit.cover)
                      : widget.song.albumArt != null
                          ? Image.memory(Uint8List.fromList(widget.song.albumArt!), fit: BoxFit.cover)
                          : Container(
                              color: card,
                              child: Icon(Icons.music_note_rounded, color: sub, size: 46),
                            ),
                ),
              ),
            ),
            // ✨ 자동 정리 안내 (정리할 게 있을 때만)
            if (_canClean) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: sub, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _cleanedOn ? '제목·가수를 자동으로 정리했어요' : '원래 제목·가수예요',
                        style: TextStyle(color: ink, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleClean,
                      style: TextButton.styleFrom(foregroundColor: ink),
                      child: Text(_cleanedOn ? '원래대로' : '다시 정리',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
            // 검색 결과를 넣었으면: 안내 + 되돌리기 (자동 정리 카드와 같은 모양)
            if (_beforePick != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.travel_explore_rounded, color: sub, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('검색 결과를 넣었어요', style: TextStyle(color: ink, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: _undoPick,
                      style: TextButton.styleFrom(foregroundColor: ink),
                      child: const Text('되돌리기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
            section('곡 정보'),
            // 제목 · 아티스트 · 앨범을 흰 카드 하나에
            Container(
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _field('제목', _titleController, ink, sub),
                  Divider(height: 1, thickness: 0.5, indent: 16, color: line),
                  _field('아티스트', _artistController, ink, sub),
                  Divider(height: 1, thickness: 0.5, indent: 16, color: line),
                  _field('앨범', _albumController, ink, sub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 흰 카드 안 한 줄: 위에 작은 이름, 아래에 고칠 글자
  Widget _field(String label, TextEditingController controller, Color ink, Color sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: sub, fontSize: 12)),
          TextField(
            controller: controller,
            style: TextStyle(color: ink, fontSize: 15.5, fontWeight: FontWeight.w600),
            cursorColor: ink,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSong(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final musicProvider = context.read<MusicProvider>();
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final navigator = Navigator.of(context);
    await musicProvider.updateSongInfo(
      widget.song,
      title: _titleController.text,
      artist: _artistController.text,
      album: _albumController.text,
    );
    // 인터넷에서 고른 앨범 사진이 있으면 받아서 넣기
    if (_pickedArt != null) {
      final bytes = await downloadArt(_pickedArt!);
      if (bytes != null) await musicProvider.setCustomArt(widget.song, bytes);
    }
    if (!context.mounted) return;
    showActionFeedback(context, type: ActionFeedbackType.edited); // ✓ 수정했어요
    navigator.pop();
  }
}