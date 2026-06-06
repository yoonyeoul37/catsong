import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class EditSongScreen extends StatefulWidget {
  final Song song;
  const EditSongScreen({super.key, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('곡 정보 편집',
            style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveSong(context),
            child: Text('저장',
                style: TextStyle(
                    color: primaryColor,
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
                    AppTheme.surfaceVariant,
                    primaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.music_note, color: primaryColor, size: 50),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField('제목', _titleController, Icons.title, primaryColor),
            const SizedBox(height: 16),
            _buildTextField('아티스트', _artistController, Icons.person, primaryColor),
            const SizedBox(height: 16),
            _buildTextField('앨범', _albumController, Icons.album, primaryColor),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveSong(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('저장',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon, Color primaryColor) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: primaryColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
      ),
    );
  }

  Future<void> _saveSong(BuildContext context) async {
    final musicProvider = context.read<MusicProvider>();
    await musicProvider.updateSongInfo(
      widget.song,
      title: _titleController.text,
      artist: _artistController.text,
      album: _albumController.text,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('곡 정보가 저장되었습니다'),
        backgroundColor: AppTheme.surfaceVariant,
        duration: Duration(seconds: 2),
      ),
    );
  }
}