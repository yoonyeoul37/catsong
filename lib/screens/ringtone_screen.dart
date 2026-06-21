import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class RingtoneScreen extends StatefulWidget {
  final Song? initialSong;
  const RingtoneScreen({super.key, this.initialSong});

  @override
  State<RingtoneScreen> createState() => _RingtoneScreenState();
}

class _RingtoneScreenState extends State<RingtoneScreen> {
  static const _channel = MethodChannel('kr.ssing.catsong/media');
  static const _accent = AppTheme.fixedAccent;
  Song? _selectedSong;
  double _startValue = 0.0;
  double _endValue = 30.0;
  bool _isProcessing = false;
  bool _isPlaying = false;
  final AudioPlayer _previewPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if (widget.initialSong != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedSong = widget.initialSong;
          _startValue = 0.0;
          _endValue = (widget.initialSong!.duration / 1000).clamp(0, 60).toDouble();
        });
      });
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreview() async {
    if (_selectedSong?.uri == null) return;
    if (_isPlaying) {
      await _previewPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      await _previewPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(_selectedSong!.uri!)),
      );
      await _previewPlayer.seek(Duration(seconds: _startValue.toInt()));
      await _previewPlayer.play();
      setState(() => _isPlaying = true);

      _previewPlayer.positionStream.listen((position) {
        if (position.inSeconds >= _endValue.toInt()) {
          _previewPlayer.stop();
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final songs = musicProvider.allSongs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.ringtone,
            style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: _accent, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.selectSong,
                style: const TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Song>(
                  value: _selectedSong,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(AppLocalizations.of(context)!.searchHint,
                        style: const TextStyle(color: Colors.black38)),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: songs.map((song) {
                    return DropdownMenuItem<Song>(
                      value: song,
                      child: Text(song.titleDisplay,
                          style: const TextStyle(color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (song) {
                    setState(() {
                      _selectedSong = song;
                      _startValue = 0.0;
                      _endValue = song != null
                          ? (song.duration / 1000).clamp(0, 60).toDouble()
                          : 30.0;
                      _isPlaying = false;
                    });
                    _previewPlayer.stop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedSong != null) ...[
              Text(AppLocalizations.of(context)!.selectRange,
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),

              Row(
                children: [
                  SizedBox(
                      width: 50,
                      child: Text(AppLocalizations.of(context)!.start,
                          style: const TextStyle(color: Colors.black54))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accent,
                        inactiveTrackColor: _accent.withOpacity(0.15),
                        thumbColor: _accent,
                        overlayColor: _accent.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _startValue,
                        min: 0,
                        max: (_selectedSong!.duration / 1000).toDouble(),
                        onChanged: (value) {
                          if (value < _endValue) {
                            setState(() => _startValue = value);
                            _previewPlayer.stop();
                            setState(() => _isPlaying = false);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                      width: 50,
                      child: Text(_formatTime(_startValue.toInt()),
                          style: const TextStyle(color: Colors.black54))),
                ],
              ),

              Row(
                children: [
                  SizedBox(
                      width: 50,
                      child: Text(AppLocalizations.of(context)!.end,
                          style: const TextStyle(color: Colors.black54))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accent,
                        inactiveTrackColor: _accent.withOpacity(0.15),
                        thumbColor: _accent,
                        overlayColor: _accent.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _endValue,
                        min: 0,
                        max: (_selectedSong!.duration / 1000).toDouble(),
                        onChanged: (value) {
                          if (value > _startValue) {
                            setState(() => _endValue = value);
                            _previewPlayer.stop();
                            setState(() => _isPlaying = false);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                      width: 50,
                      child: Text(_formatTime(_endValue.toInt()),
                          style: const TextStyle(color: Colors.black54))),
                ],
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.rangeFormat(
                    _formatTime(_startValue.toInt()),
                    _formatTime(_endValue.toInt()),
                    (_endValue - _startValue).toInt(),
                  ),
                  style: const TextStyle(color: _accent, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: _togglePreview,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _isPlaying ? AppLocalizations.of(context)!.playing : AppLocalizations.of(context)!.preview,
                    style: const TextStyle(color: _accent, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _setRingtone(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalizations.of(context)!.setRingtone,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _setRingtone(BuildContext context) async {
    if (_selectedSong?.uri == null) return;
    await _previewPlayer.stop();
    setState(() {
      _isProcessing = true;
      _isPlaying = false;
    });
    try {
      final result = await _channel.invokeMethod('trimAndSetRingtone', {
        'path': _selectedSong!.uri,
        'startMs': (_startValue * 1000).toInt(),
        'endMs': (_endValue * 1000).toInt(),
      });
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.ringtoneSet),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.ringtoneFailed),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}