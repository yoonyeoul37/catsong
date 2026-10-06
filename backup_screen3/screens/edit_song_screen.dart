import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  /// 🔍 인터넷에서 정확한 정보 찾기 → 후보 중에서 고르기
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
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
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
              Text('이 곡이 맞나요?', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('맞는 곡을 고르면 제목·가수·앨범·앨범 사진이 채워져요',
                  style: TextStyle(color: sub, fontSize: 12.5)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final r = results[i];
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
                  child: const Text('맞는 곡이 없어요'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _titleController.text = picked.title;
      _artistController.text = picked.artist;
      _albumController.text = picked.album;
      _pickedArt = picked.artUrl;
    });
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.editSong,
            style: TextStyle(color: baseColor, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: _accent, size: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveSong(context),
            child: Text(AppLocalizations.of(context)!.save,
                style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 앨범 사진: 고른 사진 → 원래 앨범 사진 → 없으면 음표
            if (_pickedArt != null || widget.song.albumArt != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _pickedArt != null
                    ? Image.network(_pickedArt!, width: 120, height: 120, fit: BoxFit.cover)
                    : Image.memory(Uint8List.fromList(widget.song.albumArt!),
                    width: 120, height: 120, fit: BoxFit.cover),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                      _accent.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.music_note, color: _accent, size: 50),
                ),
              ),
            const SizedBox(height: 24),
            // ✨ 자동 정리 안내 (정리할 게 있을 때만)
            if (_canClean) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(isDarkMode ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: _accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _cleanedOn ? '제목·가수를 자동으로 정리했어요' : '원래 제목·가수예요',
                        style: TextStyle(color: baseColor.withOpacity(0.8), fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleClean,
                      style: TextButton.styleFrom(foregroundColor: _accent),
                      child: Text(_cleanedOn ? '원래대로' : '다시 정리',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),
            _buildTextField('제목', _titleController, Icons.title, baseColor, isDarkMode),
            const SizedBox(height: 16),
            _buildTextField('아티스트', _artistController, Icons.person, baseColor, isDarkMode),
            const SizedBox(height: 16),
            _buildTextField('앨범', _albumController, Icons.album, baseColor, isDarkMode),
            const SizedBox(height: 24),
            // 🔍 인터넷에서 정확한 정보·앨범 사진 찾기
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _searching ? null : _lookup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: BorderSide(color: _accent.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: _searching
                    ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                    : const Icon(Icons.travel_explore, size: 20),
                label: Text(_searching ? '찾는 중…' : '인터넷에서 정확한 정보 찾기',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveSong(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(AppLocalizations.of(context)!.save,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      Color baseColor, bool isDarkMode) {
    return TextField(
      controller: controller,
      style: TextStyle(color: baseColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: baseColor.withOpacity(0.54)),
        prefixIcon: Icon(icon, color: _accent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.white24 : const Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
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