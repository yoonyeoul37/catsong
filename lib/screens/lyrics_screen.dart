import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    lyricsProvider.updateCurrentLine(playerProvider.position);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (lyricsProvider.lyrics.isNotEmpty && _scrollController.hasClients) {
        final index = lyricsProvider.currentLineIndex;
        const itemHeight = 56.0;
        final offset = (index * itemHeight) -
            (_scrollController.position.viewportDimension / 2) +
            itemHeight / 2;
        _scrollController.animateTo(
          offset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(AppLocalizations.of(context)!.lyrics,
            style: const TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final song = playerProvider.currentSong;
              if (song != null) {
                lyricsProvider.fetchLyrics(
                    song.titleDisplay, song.artistDisplay);
              }
            },
            icon: Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: _buildBody(lyricsProvider, playerProvider, primaryColor),
    );
  }

  Widget _buildBody(LyricsProvider lyricsProvider, PlayerProvider playerProvider, Color primaryColor) {
    if (lyricsProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.lyricsLoading,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (!lyricsProvider.hasLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined,
                size: 72, color: primaryColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              lyricsProvider.errorMessage.isEmpty
                  ? AppLocalizations.of(context)!.lyricsSearchPrompt
                  : lyricsProvider.errorMessage,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final song = playerProvider.currentSong;
                if (song != null) {
                  lyricsProvider.fetchLyrics(
                      song.titleDisplay, song.artistDisplay);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(AppLocalizations.of(context)!.lyricsSearchButton,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (lyricsProvider.lyrics.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        itemCount: lyricsProvider.lyrics.length,
        itemBuilder: (context, index) {
          final isCurrentLine = index == lyricsProvider.currentLineIndex;
          return GestureDetector(
            onTap: () {
              playerProvider.seekTo(lyricsProvider.lyrics[index].time);
            },
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                lyricsProvider.lyrics[index].text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCurrentLine ? primaryColor : AppTheme.textSecondary,
                  fontSize: isCurrentLine ? 18 : 15,
                  fontWeight: isCurrentLine
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        lyricsProvider.plainLyrics,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          height: 2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}