import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';
import '../providers/theme_provider.dart';

class RingtoneScreen extends StatefulWidget {
  final Song? initialSong;
  final bool trimMode; // true면 자르기 화면 (벨소리 대신 새 파일로 저장)
  final String? saveRelDir; // 자른 파일 저장 폴더 (녹음은 원래 녹음 폴더로)
  final String? saveBaseName; // 자른 파일 이름 (확장자 빼고)
  const RingtoneScreen(
      {super.key, this.initialSong, this.trimMode = false, this.saveRelDir, this.saveBaseName});

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
          // 자르기는 처음에 곡 전체, 벨소리는 최대 60초
          _endValue = widget.trimMode
              ? (widget.initialSong!.duration / 1000).toDouble()
              : (widget.initialSong!.duration / 1000).clamp(0, 60).toDouble();
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
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    // ── 화면 공통 모양 (베이지 바탕 · 흰 카드 · 먹색 큰 버튼) ──
    final bg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF26221C) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final line = isDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);
    const point = Color(0xFF2589E8); // 작은 포인트에만
    // 녹음처럼 음악 목록에 없는 곡을 자를 때도 선택 칸에 보이게 같이 넣기
    final songs = [
      ...musicProvider.allSongs,
      if (_selectedSong != null && !musicProvider.allSongs.contains(_selectedSong)) _selectedSong!,
    ];

    Widget section(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(text, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
        );
    Widget whiteCard(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) => Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
          child: child,
        );
    Widget timeChip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: point.withOpacity(isDark ? 0.18 : 0.08), borderRadius: BorderRadius.circular(12)),
          child: Text(t, style: const TextStyle(color: point, fontSize: 12.5, fontWeight: FontWeight.w700)),
        );
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: point,
      inactiveTrackColor: line,
      thumbColor: point,
      overlayColor: point.withOpacity(0.1),
      trackHeight: 3,
    );
    Widget rangeRow(String label, double value, ValueChanged<double> onChanged) => Row(
          children: [
            SizedBox(width: 40, child: Text(label, style: TextStyle(color: sub, fontSize: 13))),
            Expanded(
              child: SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: value,
                  min: 0,
                  max: (_selectedSong!.duration / 1000).toDouble(),
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(
                width: 44,
                child: Text(_formatTime(value.toInt()),
                    textAlign: TextAlign.right, style: TextStyle(color: ink, fontSize: 13))),
          ],
        );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        // 위 시계·배터리 + 아래 시스템 아이콘이 바탕색에서도 잘 보이게
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: Text(widget.trimMode ? '자르기' : AppLocalizations.of(context)!.ringtone,
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 20),
        ),
      ),
      // 버튼은 맨 아래에 모아서 (시스템 아이콘 위)
      bottomNavigationBar: _selectedSong == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 미리 듣기 (흰 버튼)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _togglePreview,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: card,
                          foregroundColor: ink,
                          side: BorderSide(color: line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
                        label: Text(_isPlaying ? AppLocalizations.of(context)!.playing : '미리 듣기',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 잘라서 저장 / 벨소리로 지정 (먹색 큰 버튼)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => widget.trimMode ? _trimAndSave(context) : _setRingtone(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ink,
                          foregroundColor: bg,
                          disabledBackgroundColor: ink.withOpacity(0.5),
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.25),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isProcessing
                            ? SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: bg))
                            : Icon(widget.trimMode ? Icons.content_cut_rounded : Icons.notifications_active_rounded,
                                size: 20),
                        label: Text(widget.trimMode ? '잘라서 저장' : '벨소리로 지정',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            section(AppLocalizations.of(context)!.selectSong),
            whiteCard(
              DropdownButtonHideUnderline(
                child: DropdownButton<Song>(
                  value: _selectedSong,
                  hint: Text(AppLocalizations.of(context)!.searchHint, style: TextStyle(color: sub)),
                  isExpanded: true,
                  dropdownColor: card,
                  borderRadius: BorderRadius.circular(14),
                  icon: Icon(Icons.expand_more_rounded, color: sub),
                  items: songs.map((song) {
                    return DropdownMenuItem<Song>(
                      value: song,
                      child: Text(song.titleDisplay,
                          style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (song) {
                    setState(() {
                      _selectedSong = song;
                      _startValue = 0.0;
                      _endValue = song != null
                          ? (widget.trimMode
                              ? (song.duration / 1000).toDouble()
                              : (song.duration / 1000).clamp(0, 60).toDouble())
                          : 30.0;
                      _isPlaying = false;
                    });
                    _previewPlayer.stop();
                  },
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            ),
            if (_selectedSong != null) ...[
              section(AppLocalizations.of(context)!.selectRange),
              whiteCard(
                Column(
                  children: [
                    rangeRow(AppLocalizations.of(context)!.start, _startValue, (value) {
                      if (value < _endValue) {
                        setState(() {
                          _startValue = value;
                          _isPlaying = false;
                        });
                        _previewPlayer.stop();
                      }
                    }),
                    rangeRow(AppLocalizations.of(context)!.end, _endValue, (value) {
                      if (value > _startValue) {
                        setState(() {
                          _endValue = value;
                          _isPlaying = false;
                        });
                        _previewPlayer.stop();
                      }
                    }),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        timeChip(_formatTime(_startValue.toInt())),
                        Text('${(_endValue - _startValue).toInt()}초',
                            style: TextStyle(color: sub, fontSize: 12.5)),
                        timeChip(_formatTime(_endValue.toInt())),
                      ],
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 14),
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

  /// 자르기: 고른 구간만 새 파일로 저장 (원본은 그대로)
  Future<void> _trimAndSave(BuildContext context) async {
    final uri = _selectedSong?.uri;
    if (uri == null) return;
    final ext = uri.split('.').last.toLowerCase();
    if (!['mp3', 'm4a', 'aac', 'mp4'].contains(ext)) {
      showParanToast(context, 'mp3, m4a 파일만 자를 수 있어요');
      return;
    }
    await _previewPlayer.stop();
    setState(() {
      _isProcessing = true;
      _isPlaying = false;
    });
    try {
      // 녹음 파일이면 어디서 자르든(녹음 탭·재생화면·곡 메뉴) 원래 녹음 폴더에 저장
      var relDir = widget.saveRelDir;
      var outBase = widget.saveBaseName;
      if (relDir == null && context.read<MusicProvider>().isCallRecordingPath(uri)) {
        relDir = uri.contains('/Voice Recorder/') ? 'Recordings/Voice Recorder' : 'Recordings/Call';
        final base = uri.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
        final m = RegExp(r'^(.*)(_\d{6}_\d{6})$').firstMatch(base);
        outBase = m != null ? '${m.group(1)} (자름)${m.group(2)}' : '$base (자름)';
      }
      final saved = await _channel.invokeMethod<String>('trimAndSave', {
        'relDir': relDir,
        'outBase': outBase,
        'path': uri,
        'startMs': (_startValue * 1000).toInt(),
        'endMs': (_endValue * 1000).toInt(),
      });
      if (!context.mounted) return;
      if (saved != null) {
        context.read<MusicProvider>().loadSongs(); // 목록에 새 파일이 보이게
        showActionFeedback(context, type: ActionFeedbackType.saved, message: '잘랐어요', icon: Icons.content_cut_rounded);
      } else {
        showParanToast(context, '자르기에 실패했어요', error: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      showParanToast(context, '자르기에 실패했어요', error: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
      if (result == 'ok' || result == true) {
        showActionFeedback(context,
            type: ActionFeedbackType.saved, message: '벨소리로 지정했어요', icon: Icons.notifications_active_rounded);
      } else if (result == 'permission') {
        // 허용 화면이 열렸어요 → 켜고 돌아와서 다시 누르면 됨
        showParanToast(context, '"시스템 설정 변경"을 허용으로 켜고 돌아와서 다시 눌러주세요',
            duration: const Duration(seconds: 5));
      } else {
        showParanToast(context, AppLocalizations.of(context)!.ringtoneFailed, error: true);
      }
    } catch (e) {
      showParanToast(context, '벨소리를 지정하지 못했어요', error: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}