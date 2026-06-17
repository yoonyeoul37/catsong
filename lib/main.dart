import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/lyrics_provider.dart';
import 'providers/video_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/radio_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

late AudioHandler globalAudioHandler;
late BaseAudioHandler radioAudioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final playerProvider = PlayerProvider();
  final musicProvider = MusicProvider();
  playerProvider.onSongPlayed = (song) {
    musicProvider.addToRecent(song);
  };

  final simpleHandler = SimpleAudioHandler(playerProvider);
  globalAudioHandler = await AudioService.init(
    builder: () => simpleHandler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'kr.ssing.catsong.audio',
      androidNotificationChannelName: 'MP3 Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
  playerProvider.setAudioHandler(globalAudioHandler);
  radioAudioHandler = simpleHandler;

  // RadioProvider 생성 + 음악/라디오 상호 정지 연결
  final radioProvider = RadioProvider()
    ..setAudioHandler(radioAudioHandler);

  radioProvider.setOnStopMusic(() async {
    await playerProvider.player.stop();
    await WakelockPlus.disable();
  });

  playerProvider.setOnStopRadio(() async {
    await radioProvider.stopRadio();
  });

  simpleHandler.onRadioPlay = () {
    radioProvider.togglePlayPause();
  };
  simpleHandler.onRadioPause = () {
    radioProvider.togglePlayPause();
  };

  simpleHandler.onRadioNext = () {
    final radio = radioProvider;
    final queue = radio.currentQueue;
    final idx = radio.currentQueueIndex;
    if (queue.isNotEmpty && idx < queue.length - 1) {
      radio.setQueue(queue, idx + 1);
      radio.playStation(queue[idx + 1]);
    } else if (queue.isNotEmpty) {
      radio.setQueue(queue, 0);
      radio.playStation(queue[0]);
    }
  };
  simpleHandler.onRadioPrevious = () {
    final radio = radioProvider;
    final queue = radio.currentQueue;
    final idx = radio.currentQueueIndex;
    if (queue.isNotEmpty && idx > 0) {
      radio.setQueue(queue, idx - 1);
      radio.playStation(queue[idx - 1]);
    } else if (queue.isNotEmpty) {
      radio.setQueue(queue, queue.length - 1);
      radio.playStation(queue[queue.length - 1]);
    }
  };

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

  runApp(MyApp(
    playerProvider: playerProvider,
    musicProvider: musicProvider,
    radioProvider: radioProvider,
  ));
}

class MyApp extends StatelessWidget {
  final PlayerProvider playerProvider;
  final MusicProvider musicProvider;
  final RadioProvider radioProvider;
  const MyApp({
    super.key,
    required this.playerProvider,
    required this.musicProvider,
    required this.radioProvider,
  });

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
        ChangeNotifierProvider.value(value: radioProvider),
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
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.backgroundGradient,
                  ),
                  child: child!,
                ),
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
        context
            .read<PlaylistProvider>()
            .restorePlaylistSongs(musicProvider.allSongs);
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
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                child: const Icon(Icons.music_note,
                    color: Colors.black, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                l.reviewTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l.reviewMessage,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                        (i) => Icon(Icons.star_rounded,
                        color: primaryColor, size: 28)),
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
                  child: Text(l.reviewButton,
                      style: const TextStyle(
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
                  child: Text(l.reviewLater,
                      style: const TextStyle(fontSize: 13)),
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