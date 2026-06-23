import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'edit_song_screen.dart';
import 'lyrics_screen.dart';
import '../l10n/app_localizations.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _equalizerController;
  late List<AnimationController> _eqControllers;
  late List<Animation<double>> _eqAnimations;
  int _albumArtStyle = 1;
  Color _dominantColor = const Color(0xFF1A1A1A);
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startEqAnimations();

    _loadStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      final currentSong = playerProvider.currentSong;
      if (currentSong != null) {
        context.read<LyricsProvider>().fetchLyrics(
          currentSong.titleDisplay,
          currentSong.artistDisplay,
          filePath: currentSong.uri,
        );
        _extractColor(currentSong);
      }
      playerProvider.onSongChanged = (song) {
        _extractColor(song);
      };
    });
  }

  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = false;
    setState(() {
      _albumArtStyle = prefs.getInt('albumArtStyle') ?? 1;
      _showSwipeHint = !shown;
    });
    if (!shown) {
      await prefs.setBool('swipe_hint_shown', true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSwipeHint = false);
      });
    }
  }

  Future<void> _saveStyle(int style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('albumArtStyle', style);
  }

  Future<void> _extractColor(Song song) async {
    if (song.albumArt == null) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      setState(() => _dominantColor = Color.fromRGBO(
        (primaryColor.red * 0.7).toInt().clamp(60, 255),
        (primaryColor.green * 0.7).toInt().clamp(60, 255),
        (primaryColor.blue * 0.7).toInt().clamp(60, 255),
        1,
      ));
      return;
    }
    try {
      final codec = await instantiateImageCodec(
        Uint8List.fromList(song.albumArt!),
        targetWidth: 20,
        targetHeight: 20,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData();
      if (byteData != null) {
        int totalR = 0, totalG = 0, totalB = 0;
        int pixelCount = 0;
        for (int i = 0; i < byteData.lengthInBytes; i += 4) {
          totalR += byteData.getUint8(i);
          totalG += byteData.getUint8(i + 1);
          totalB += byteData.getUint8(i + 2);
          pixelCount++;
        }
        if (pixelCount > 0) {
          final r = (totalR / pixelCount).toInt();
          final g = (totalG / pixelCount).toInt();
          final b = (totalB / pixelCount).toInt();
          final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
          if (brightness < 30) {
            setState(() => _dominantColor = const Color(0xFF3D3D5C));
          } else {
            setState(() {
              _dominantColor = Color.fromRGBO(
                (r * 0.5).toInt(),
                (g * 0.5).toInt(),
                (b * 0.5).toInt(),
                1,
              );
            });
          }
        }
      }
    } catch (e) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      setState(() => _dominantColor = Color.fromRGBO(
        (primaryColor.red * 0.4).toInt(),
        (primaryColor.green * 0.4).toInt(),
        (primaryColor.blue * 0.4).toInt(),
        1,
      ));
    }
  }

  void _startEqAnimations() {
    final durations = [900, 1100, 800, 1300];
    final delays = [0, 200, 400, 100];
    _eqControllers = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[i]),
      );
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
    _eqAnimations = List.generate(4, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _eqControllers[i], curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _equalizerController.dispose();
    for (final c in _eqControllers) c.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final song = playerProvider.currentSong;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (song == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text('No song is playing',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final lyricsProvider = context.read<LyricsProvider>();
    final currentKey = '${song.titleDisplay}-${song.artistDisplay}';
    if (lyricsProvider.currentSongKey != currentKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lyricsProvider.clearLyrics();
        lyricsProvider.fetchLyrics(
          song.titleDisplay,
          song.artistDisplay,
          filePath: song.uri,
        );
      });
    }

    if (playerProvider.isPlaying) {
      _rotationController.repeat();
      _equalizerController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _equalizerController.stop();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -300) {
          playerProvider.playNext();
        } else if (details.primaryVelocity! > 300) {
          playerProvider.playPrevious();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            const SizedBox.shrink(),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildTopBar(context, playerProvider, primaryColor),
                            Expanded(flex: 4, child: _buildAlbumArt(song, primaryColor)),
                            _buildEqualizer(playerProvider, primaryColor),
                            _buildCurrentLyrics(playerProvider, primaryColor),
                            Expanded(
                              flex: 4,
                              child: _buildControls(
                                  context, playerProvider, musicProvider, song, primaryColor),
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
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    final song = playerProvider.currentSong;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppTheme.textPrimary, size: 30),
          ),
          Expanded(
            child: Center(
              child: Text(AppLocalizations.of(context)!.nowPlaying,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2)),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: AppTheme.fixedAccent, size: 18),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.editSong,
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'playlist',
                child: Row(
                  children: [
                    const Icon(Icons.playlist_add, color: AppTheme.fixedAccent, size: 18),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.addToPlaylist,
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'style',
                child: Row(
                  children: [
                    const Icon(Icons.style, color: AppTheme.fixedAccent, size: 18),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.playerStyle,
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (song == null) return;
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSongScreen(song: song),
                  ),
                );
              } else if (value == 'playlist') {
                _showAddToPlaylistDialog(context, song, primaryColor);
              } else if (value == 'style') {
                _showStyleDialog(context, primaryColor);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Song song, Color primaryColor) {
    switch (_albumArtStyle) {
      case 2: return _buildCassetteStyle(song, primaryColor);
      case 3: return _buildCardStyle(song, primaryColor);
      case 4: return _buildVisualizerStyle(song, primaryColor);
      case 5: return _buildGradientStyle(song, primaryColor);
      default: return _buildCDStyle(song, primaryColor);
    }
  }

  Widget _buildCDStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _dominantColor.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                  alignment: Alignment.center,
                  children: [
              ClipOval(
              child: song.albumArt != null
                  ? SizedBox.expand(
                      child: Image.memory(
                        Uint8List.fromList(song.albumArt!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _dominantColor,
                        _dominantColor.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/no_album.svg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
                  // 중앙 구멍
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dominantColor.withOpacity(0.9),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCassetteStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.6,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 20, left: 20, right: 20, bottom: 25,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.albumArt != null
                            ? Image.memory(
                          Uint8List.fromList(song.albumArt!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                            : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.surfaceVariant,
                                primaryColor.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.music_note,
                                color: primaryColor, size: 30),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8, left: 8, right: 8,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(left: 30, child: _buildReel(primaryColor, song)),
                    Positioned(right: 30, child: _buildReel(primaryColor, song)),
                    Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: primaryColor.withOpacity(0.5)),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      child: Text(
                        song.titleDisplay,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReel(Color primaryColor, Song song) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A2A),
              border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(6, (i) {
                  return Transform.rotate(
                    angle: i * 3.14159 / 3,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: primaryColor.withOpacity(0.4),
                    ),
                  );
                }),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            final scale = _rotationController.isAnimating ? 1.03 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: song.albumArt != null
                    ? Image.memory(
                  Uint8List.fromList(song.albumArt!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
                    : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.surfaceVariant,
                        primaryColor.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.music_note,
                        color: primaryColor.withOpacity(0.7), size: 80),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizerStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _equalizerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _VisualizerPainter(
                      progress: _equalizerController.value,
                      color: primaryColor,
                      isPlaying: _rotationController.isAnimating,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              ClipOval(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: song.albumArt != null
                      ? Image.memory(
                    Uint8List.fromList(song.albumArt!),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                      : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.surfaceVariant,
                          primaryColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.music_note,
                          color: primaryColor.withOpacity(0.7), size: 60),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.8),
                      primaryColor.withOpacity(0.3),
                      AppTheme.background,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (song.albumArt != null)
                        Opacity(
                          opacity: 0.3,
                          child: Image.memory(
                            Uint8List.fromList(song.albumArt!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            gaplessPlayback: true,
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (song.albumArt != null)
                            ClipOval(
                              child: Image.memory(
                                Uint8List.fromList(song.albumArt!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            )
                          else
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.3),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white, size: 60),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            song.titleDisplay,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizer(PlayerProvider playerProvider, Color primaryColor) {
    if (!playerProvider.isPlaying) return const SizedBox(height: 20);
    final minHeights = [6.0, 4.0, 8.0, 5.0];
    final maxHeights = [18.0, 16.0, 20.0, 14.0];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return AnimatedBuilder(
              animation: _eqAnimations[i],
              builder: (context, child) {
                final height = minHeights[i] +
                    (maxHeights[i] - minHeights[i]) * _eqAnimations[i].value;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 3,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentLyrics(PlayerProvider playerProvider, Color primaryColor) {
    final lyricsProvider = context.watch<LyricsProvider>();
    if (!lyricsProvider.hasLyrics || lyricsProvider.lyrics.isEmpty) {
      return const SizedBox(height: 36);
    }
    lyricsProvider.updateCurrentLine(playerProvider.position);
    final currentLine = lyricsProvider.lyrics[lyricsProvider.currentLineIndex];
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          currentLine.text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerProvider playerProvider,
      MusicProvider musicProvider, Song song, Color primaryColor) {
    final isFav = musicProvider.isFavorite(song.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.titleDisplay,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 0),
                    Text(song.artistDisplay,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  musicProvider.toggleFavorite(song);
                  final isFavNow = musicProvider.isFavorite(song.id);
                  final overlay = Overlay.of(context);
                  final entry = OverlayEntry(
                    builder: (context) => Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFavNow ? Icons.favorite : Icons.favorite_border,
                                  color: isFavNow ? Colors.redAccent : Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFavNow
                                      ? AppLocalizations.of(context)!.addedToFavorites
                                      : AppLocalizations.of(context)!.removedFromFavorites,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      decoration: TextDecoration.none),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  overlay.insert(entry);
                  Future.delayed(const Duration(seconds: 2), () => entry.remove());
                },
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white70,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.1),
            ),
            child: Slider(
              value: playerProvider.progress,
              onChanged: (value) {
                final position = Duration(
                  milliseconds:
                  (value * playerProvider.duration.inMilliseconds).toInt(),
                );
                playerProvider.seekTo(position);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(playerProvider.formatDuration(playerProvider.position),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              Text(playerProvider.formatDuration(playerProvider.duration),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => playerProvider.playPrevious(),
                icon: const Icon(Icons.skip_previous),
                color: AppTheme.textPrimary,
                iconSize: 36,
              ),
              GestureDetector(
                onTap: playerProvider.togglePlayPause,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: playerProvider.isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.black),
                  )
                      : Icon(
                    playerProvider.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => playerProvider.playNext(),
                icon: const Icon(Icons.skip_next),
                color: AppTheme.textPrimary,
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => playerProvider.toggleShuffle(),
                icon: Icon(Icons.shuffle,
                    color: playerProvider.isShuffled
                        ? Colors.white
                        : Colors.white60),
                iconSize: 22,
              ),
              IconButton(
                onPressed: () {
                  playerProvider.toggleLoopMode();
                  final mode = playerProvider.loopMode;
                  final label = mode == LoopMode.one
                      ? AppLocalizations.of(context)!.repeatOne
                      : mode == LoopMode.all
                          ? AppLocalizations.of(context)!.repeatAll
                          : AppLocalizations.of(context)!.noRepeat;
                  final overlay = Overlay.of(context);
                  final entry = OverlayEntry(
                    builder: (context) => Positioned(
                      bottom: 140,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.85 + (0.15 * value),
                                child: child,
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                                      color: mode == LoopMode.off
                                          ? Colors.white54
                                          : Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          decoration: TextDecoration.none),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  overlay.insert(entry);
                  Future.delayed(const Duration(milliseconds: 1200), () => entry.remove());
                },
                icon: Icon(
                    playerProvider.loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: playerProvider.loopMode != LoopMode.off
                        ? Colors.white
                        : Colors.white60),
                iconSize: 27,
              ),
              IconButton(
                onPressed: () => _showSleepTimerDialog(context, playerProvider, primaryColor),
                icon: Icon(Icons.bedtime,
                    color: playerProvider.isSleepTimerActive
                        ? Colors.white
                        : Colors.white60),
                iconSize: 22,
              ),
              IconButton(
                onPressed: () => _showSpeedDialog(context, playerProvider, primaryColor),
                icon: Icon(Icons.speed,
                    color: playerProvider.playbackSpeed != 1.0
                        ? Colors.white
                        : Colors.white60),
                iconSize: 22,
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LyricsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.lyrics_outlined, color: Colors.white60),
                iconSize: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song, Color primaryColor) {
    final playlistProvider = context.read<PlaylistProvider>();
    const accent = AppTheme.fixedAccent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.addToPlaylist,
            style: const TextStyle(color: Colors.black)),
        content: playlistProvider.playlists.isEmpty
            ? Text(AppLocalizations.of(context)!.noPlaylists,
            style: const TextStyle(color: Colors.black54))
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play, color: accent),
                title: Text(playlist.name,
                    style: const TextStyle(color: Colors.black)),
                subtitle: Text('${playlist.songCount} songs',
                    style: const TextStyle(color: Colors.black54)),
                onTap: () {
                  playlistProvider.addSongToPlaylist(playlist.id, song);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${playlist.name} ${AppLocalizations.of(context)!.addedToPlaylist}'),
                      backgroundColor: AppTheme.surfaceVariant,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SleepTimerDialog(playerProvider: playerProvider, primaryColor: AppTheme.fixedAccent),
    );
  }

  void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SpeedDialog(playerProvider: playerProvider, primaryColor: AppTheme.fixedAccent),
    );
  }

  void _showStyleDialog(BuildContext context, Color primaryColor) {
    const accent = AppTheme.fixedAccent;
    final styles = [
      {'id': 1, 'name': AppLocalizations.of(context)!.styleCD, 'icon': Icons.album, 'desc': AppLocalizations.of(context)!.styleCDDesc},
      {'id': 2, 'name': AppLocalizations.of(context)!.styleCassette, 'icon': Icons.settings_input_composite, 'desc': AppLocalizations.of(context)!.styleCassetteDesc},
      {'id': 3, 'name': AppLocalizations.of(context)!.styleCard, 'icon': Icons.image, 'desc': AppLocalizations.of(context)!.styleCardDesc},
      {'id': 4, 'name': AppLocalizations.of(context)!.styleVisualizer, 'icon': Icons.graphic_eq, 'desc': AppLocalizations.of(context)!.styleVisualizerDesc},
      {'id': 5, 'name': AppLocalizations.of(context)!.styleGradient, 'icon': Icons.gradient, 'desc': AppLocalizations.of(context)!.styleGradientDesc},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.style, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playerStyle,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = _albumArtStyle == style['id'];
                return InkWell(
                  onTap: () {
                    setState(() => _albumArtStyle = style['id'] as int);
                    _saveStyle(style['id'] as int);
                    setDialogState(() {});
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withOpacity(0.10) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(style['icon'] as IconData,
                            color: isSelected ? accent : Colors.black38, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(style['name'] as String,
                                  style: TextStyle(
                                      color: isSelected ? accent : Colors.black87,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              Text(style['desc'] as String,
                                  style: const TextStyle(color: Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: accent, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: accent)),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLoopModeDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
  const accent = AppTheme.fixedAccent;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.repeatMode,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildLoopOption(ctx,
              icon: Icons.arrow_forward,
              title: AppLocalizations.of(context)!.noRepeat,
              subtitle: AppLocalizations.of(context)!.noRepeat,
              isSelected: playerProvider.loopMode == LoopMode.off,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.off);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            _buildLoopOption(ctx,
              icon: Icons.repeat_one,
              title: AppLocalizations.of(context)!.repeatOne,
              subtitle: AppLocalizations.of(context)!.repeatOne,
              isSelected: playerProvider.loopMode == LoopMode.one,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.one);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            _buildLoopOption(ctx,
              icon: Icons.repeat,
              title: AppLocalizations.of(context)!.repeatAll,
              subtitle: AppLocalizations.of(context)!.repeatAll,
              isSelected: playerProvider.loopMode == LoopMode.all,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.all);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLoopOption(
    BuildContext ctx, {
      required IconData icon,
      required String title,
      required String subtitle,
      required bool isSelected,
      required Color primaryColor,
      required VoidCallback onTap,
    }) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.12) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isSelected ? primaryColor : Colors.black38, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isSelected ? primaryColor : Colors.black87,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: primaryColor, size: 20),
        ],
      ),
    ),
  );
}

class _SleepTimerDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SleepTimerDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<_SleepTimerDialog> {
  int selectedHours = 0;
  int selectedMinutes = 30;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.playerProvider.isSleepTimerActive &&
        widget.playerProvider.sleepTimerEnd != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final end = widget.playerProvider.sleepTimerEnd;
    if (end != null) {
      _remaining = end.difference(DateTime.now());
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final end = widget.playerProvider.sleepTimerEnd;
      if (end == null) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = end.difference(DateTime.now());
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Widget _quickButton(String label, int hours, int minutes, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        widget.playerProvider.setSleepTimer(
          Duration(hours: hours, minutes: minutes),
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.autoStopFormat(label),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    final l = AppLocalizations.of(context)!;
    final timeStr = hours > 0
        ? '$hours${l.hourWord} $minutes${l.minuteShort} $seconds${l.secondShort}'
        : '$minutes${l.minuteShort} $seconds${l.secondShort}';
    return '$timeStr ${l.autoStopCountdownSuffix}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.playerProvider.isSleepTimerActive;
    final primaryColor = AppTheme.fixedAccent;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.sleepTimer,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (!isActive) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickButton('15${AppLocalizations.of(context)!.minuteShort}', 0, 15, primaryColor),
                _quickButton('30${AppLocalizations.of(context)!.minuteShort}', 0, 30, primaryColor),
                _quickButton('1${AppLocalizations.of(context)!.hourWord}', 1, 0, primaryColor),
                _quickButton('2${AppLocalizations.of(context)!.hourWord}', 2, 0, primaryColor),
                _quickButton('3${AppLocalizations.of(context)!.hourWord}', 3, 0, primaryColor),
                _quickButton('4${AppLocalizations.of(context)!.hourWord}', 4, 0, primaryColor),
                _quickButton('5${AppLocalizations.of(context)!.hourWord}', 5, 0, primaryColor),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.timer, color: primaryColor, size: 32),
                  const SizedBox(height: 8),
                  Text(_formatRemaining(_remaining),
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.playerProvider.cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.timerCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${selectedHours > 0 ? '$selectedHours${AppLocalizations.of(context)!.hourWord} ' : ''}$selectedMinutes${AppLocalizations.of(context)!.minuteShort}',
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(AppLocalizations.of(context)!.minuteShort,
                      style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: primaryColor.withOpacity(0.15),
                      thumbColor: primaryColor,
                    ),
                    child: Slider(
                      value: selectedMinutes.toDouble(),
                      min: 0, max: 59, divisions: 59,
                      onChanged: (value) =>
                          setState(() => selectedMinutes = value.toInt()),
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text('$selectedMinutes',
                      style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(AppLocalizations.of(context)!.hourShort,
                      style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: primaryColor.withOpacity(0.15),
                      thumbColor: primaryColor,
                    ),
                    child: Slider(
                      value: selectedHours.toDouble(),
                      min: 0, max: 6, divisions: 6,
                      onChanged: (value) =>
                          setState(() => selectedHours = value.toInt()),
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text('$selectedHours',
                      style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black45,
                      side: const BorderSide(color: Color(0xFFE5E5E5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final total = selectedHours * 60 + selectedMinutes;
                      if (total > 0) {
                        widget.playerProvider.setSleepTimer(
                          Duration(hours: selectedHours, minutes: selectedMinutes),
                        );
                        Navigator.pop(context);
                        final timeLabel = '${selectedHours > 0 ? '$selectedHours${AppLocalizations.of(context)!.hourWord} ' : ''}$selectedMinutes${AppLocalizations.of(context)!.minuteShort}';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.autoStopFormat(timeLabel),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: primaryColor,
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.set,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeedDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SpeedDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends State<_SpeedDialog> {
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = widget.playerProvider.playbackSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.fixedAccent;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playbackSpeed,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${_speed.toStringAsFixed(2)}x',
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: primaryColor.withOpacity(0.15),
              thumbColor: primaryColor,
            ),
            child: Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) {
                setState(() => _speed = value);
                widget.playerProvider.setPlaybackSpeed(value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0].map((speed) {
              final isSelected = (_speed - speed).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  setState(() => _speed = speed);
                  widget.playerProvider.setPlaybackSpeed(speed);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? primaryColor : const Color(0xFFE5E5E5)),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _speed = 1.0);
                    widget.playerProvider.setPlaybackSpeed(1.0);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black45,
                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.defaultValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;

  _VisualizerPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const barCount = 40;

    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * 3.14159;
      final barHeight = isPlaying
          ? 10 + 20 * (0.5 + 0.5 * (i % 3 == 0 ? progress : (i % 3 == 1 ? (1 - progress) : 0.5)))
          : 5.0;

      final innerRadius = radius - barHeight;
      final outerRadius = radius;

      final start = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
}