import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.titleDisplay);
    _artistController = TextEditingController(text: widget.song.artistDisplay);
    _albumController = TextEditingController(text: widget.song.albumDisplay);
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
            const SizedBox(height: 32),
            _buildTextField('제목', _titleController, Icons.title, baseColor, isDarkMode),
            const SizedBox(height: 16),
            _buildTextField('아티스트', _artistController, Icons.person, baseColor, isDarkMode),
            const SizedBox(height: 16),
            _buildTextField('앨범', _albumController, Icons.album, baseColor, isDarkMode),
            const SizedBox(height: 32),
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
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.songSaved;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFEDE7DA),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}