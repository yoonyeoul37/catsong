import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/lyrics_provider.dart';
import 'providers/video_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

late AudioHandler globalAudioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final playerProvider = PlayerProvider();
  final musicProvider = MusicProvider();
  playerProvider.onSongPlayed = (song) {
    musicProvider.addToRecent(song);
  };

  globalAudioHandler = await AudioService.init(
    builder: () => SimpleAudioHandler(playerProvider),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.mp3_player.audio',
      androidNotificationChannelName: 'MP3 Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
  playerProvider.setAudioHandler(globalAudioHandler);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(playerProvider: playerProvider, musicProvider: musicProvider));
}

class MyApp extends StatelessWidget {
  final PlayerProvider playerProvider;
  final MusicProvider musicProvider;
  const MyApp({super.key, required this.playerProvider, required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: musicProvider),
        ChangeNotifierProvider.value(value: playerProvider),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => LyricsProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '캣송',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko'),
              Locale('en'),
              Locale('ja'),
              Locale('zh'),
            ],
            theme: AppTheme.buildTheme(themeProvider.primaryColor).copyWith(
              textTheme: AppTheme.buildTheme(themeProvider.primaryColor)
                  .textTheme
                  .merge(themeProvider.getTextTheme()),
            ),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.textScale),
                ),
                child: child!,
              );
            },
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final musicProvider = context.read<MusicProvider>();
      if (musicProvider.songs.isEmpty && !musicProvider.isLoading) {
        await musicProvider.initialize();
        context.read<PlaylistProvider>().restorePlaylistSongs(musicProvider.allSongs);
      }
      await _checkAndRequestReview();
    });
  }

  Future<void> _checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    final launchCount = (prefs.getInt('launch_count') ?? 0) + 1;
    await prefs.setInt('launch_count', launchCount);

    final lastRequest = prefs.getInt('last_review_request') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayMs = 24 * 60 * 60 * 1000;

    if (launchCount % 5 == 0 && (now - lastRequest) > oneDayMs) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await _showReviewDialog();
      }
    }
  }

  Future<void> _showReviewDialog() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final prefs = await SharedPreferences.getInstance();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.8),
                      primaryColor,
                    ],
                  ),
                ),
                child: const Icon(Icons.music_note, color: Colors.black, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                '캣송이 마음에 드시나요?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '별점을 남겨주시면\n앱 개선에 큰 도움이 됩니다 😊',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) =>
                    Icon(Icons.star_rounded, color: primaryColor, size: 28)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await prefs.setInt('last_review_request',
                        DateTime.now().millisecondsSinceEpoch);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('⭐ 평점 남기기',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    prefs.setInt('last_review_request',
                        DateTime.now().millisecondsSinceEpoch);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('나중에 할게요',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: const HomeScreen(),
    );
  }
}