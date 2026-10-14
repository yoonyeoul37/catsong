import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/greeting_images.dart';
import 'utils/widget_go.dart';
import 'utils/paran_photo.dart';
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
import 'providers/start_screen_provider.dart';
import 'providers/sound_mix_provider.dart';
import 'providers/recent_content_provider.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';
import 'services/headset_resume.dart';
import 'widgets/photo_dialog.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_holder.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

late AudioHandler globalAudioHandler;
late BaseAudioHandler radioAudioHandler;

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // 사진 기억 창고: 기본 100MB → 50MB (램이 적은 폰에서 꺼지는 것 줄이기)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
  // 시작 화면을 최소 1.2초는 보여주기 (너무 빨리 지나가지 않게)
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  Future.delayed(const Duration(milliseconds: 600), FlutterNativeSplash.remove);
  MediaKit.ensureInitialized();

  // 오류 기록 (Firebase Crashlytics): 앱이 튕기거나 빨간 오류 화면이 뜨면 자동으로 기록
  try {
    await Firebase.initializeApp();
    // 디버깅(flutter run) 중 오류는 안 보내고, 스토어에서 받은 앱 오류만 기록
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    // 화면 경고는 "튕김"이 아니라 "일반 오류"로 기록 (진짜 튕김만 비정상 종료로 집계)
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase 시작 오류: $e');
  }


  final playerProvider = PlayerProvider();
  final musicProvider = MusicProvider();
  final recentContentProvider = RecentContentProvider();
  final soundMixProvider = SoundMixProvider();
  playerProvider.onSongPlayed = (song) {
    musicProvider.addToRecent(song);
    recentContentProvider.addMusic(song);
  };
  playerProvider.onNaturePlayed = (assetPath, displayName) {
    recentContentProvider.addNature(assetPath, displayName);
  };

  final simpleHandler = SimpleAudioHandler(playerProvider);
  globalAudioHandler = await AudioService.init(
    builder: () => simpleHandler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'kr.ssing.catsong.audio',
      androidNotificationChannelName: '파란소리',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: null,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: false, // 끝나면 알림을 남기지 않고 지움
      
      preloadArtwork: false,
    ),
  );
  playerProvider.setAudioHandler(globalAudioHandler);
  soundMixProvider.attachPlayerProvider(playerProvider);
  radioAudioHandler = simpleHandler;

  // RadioProvider 생성 + 음악/라디오 상호 정지 연결
  final radioProvider = RadioProvider()
    ..onStationPlayed = ((station) => recentContentProvider.addRadio(station))
    ..setAudioHandler(radioAudioHandler);

  radioProvider.setOnStopMusic(() async {
    await playerProvider.player.stop();
    playerProvider.clearNatureSoundState();
    playerProvider.clearCurrentSong();
    await WakelockPlus.disable();
  });

  playerProvider.setOnStopRadio(() async {
    await radioProvider.stopRadioAndClear();
  });
  playerProvider.setOnStopMixMusic(() {
    soundMixProvider.stopAll();
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

  HeadsetResume.init(playerProvider, radioProvider); // 이어폰 연결하면 이어서 듣기
  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것
  LyricsProvider.shared.attachWidget(playerProvider); // 위젯에 지금 가사 한 줄
  // 앱이 꺼져 있을 때 위젯 재생을 눌렀으면 (화면 없이 엔진만 켜짐) → 마지막에 듣던 것 바로
  try {
    final sp = await SharedPreferences.getInstance();
    final at = sp.getInt('widget_play_at') ?? 0;
    final kind = sp.getString('widget_play_kind') ?? ''; // 아래 버튼 (음악·라디오·자연)
    if (at > 0) await sp.remove('widget_play_at');
    if (kind.isNotEmpty) await sp.remove('widget_play_kind');
    if (at > 0 && DateTime.now().millisecondsSinceEpoch - at < 15000) {
      WidgetGo.launched = true; // 나중에 앱을 열어도 인삿말 목소리 안 함
      if (musicProvider.songs.isEmpty) musicProvider.initialize(); // 곡 목록 (화면이 없어서 여기서)
      if (kind.isNotEmpty) {
        HeadsetResume.widgetPlayKind(kind);
      } else {
        HeadsetResume.widgetPlay();
      }
    }
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // 상단 아이콘 색은 화면마다 정함 (여기서 흰색으로 정하면 첫인사 때 잠깐 하얗게 보였음)
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // 기다리지 않기: 위젯으로 화면 없이 깨어나면 대답이 안 와서 앱이 여기서 영원히 멈췄음
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final videoProvider = VideoProvider()
    ..setOnStopRadio(() async => await radioProvider.stopRadio())
    ..setOnStopMusic(() async => await playerProvider.player.stop());

  await AlarmService.init(); // 아침 알람 (알람 때문에 켜졌는지도 확인)
  await initGreetingScene(); // 첫인사·끝인사 오늘 장면 (지난번과 다르게)
  await WidgetGo.loadLaunch(); // 홈 위젯 바로가기로 켜졌는지


  runApp(MyApp(
    playerProvider: playerProvider,
    musicProvider: musicProvider,
    radioProvider: radioProvider,
    videoProvider: videoProvider,
    recentContentProvider: recentContentProvider,
    soundMixProvider: soundMixProvider,
  ));
}

class MyApp extends StatelessWidget {
  final PlayerProvider playerProvider;
  final MusicProvider musicProvider;
  final RadioProvider radioProvider;
  final VideoProvider videoProvider;
  final RecentContentProvider recentContentProvider;
  final SoundMixProvider soundMixProvider;
  const MyApp({
    super.key,
    required this.playerProvider,
    required this.musicProvider,
    required this.radioProvider,
    required this.videoProvider,
    required this.recentContentProvider,
    required this.soundMixProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: musicProvider),
        ChangeNotifierProvider.value(value: playerProvider),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider.value(value: LyricsProvider.shared),
        ChangeNotifierProvider.value(value: videoProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: radioProvider),
        ChangeNotifierProvider(create: (_) => StartScreenProvider()),
        ChangeNotifierProvider.value(value: recentContentProvider),
        ChangeNotifierProvider.value(value: soundMixProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: AlarmService.navKey, // 알람 화면 띄우기용
            title: '파란소리',
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
              textTheme: themeProvider.fontFamily == 'default'
                  ? AppTheme.buildTheme(themeProvider.primaryColor)
                      .textTheme
                      .apply(fontFamily: 'SpoqaHanSansNeo')
                  : AppTheme.buildTheme(themeProvider.primaryColor)
                      .textTheme
                      .apply(fontFamily: themeProvider.getTextTheme().bodyLarge?.fontFamily),
              // 제목 줄이 화면을 다시 그릴 때마다 시스템 바 색을 덮어쓰므로, 라이트/다크에 맞는 값을 쥐여준다
              appBarTheme: AppTheme.buildTheme(themeProvider.primaryColor)
                  .appBarTheme
                  .copyWith(systemOverlayStyle: themeProvider.systemBarStyle),
              // ⋮ 메뉴 공통 모양: 둥근 카드 + 부드러운 그림자 (다크면 어두운 카드)
              popupMenuTheme: PopupMenuThemeData(
                color: themeProvider.isDarkMode ? const Color(0xFF32302C) : Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 10,
                shadowColor: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.5 : 0.18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: TextStyle(
                  color: themeProvider.isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),
                  fontSize: 14,
                ),
                // 새 방식 메뉴도 글자색이 배경과 겹치지 않게
                labelTextStyle: WidgetStatePropertyAll(TextStyle(
                  color: themeProvider.isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),
                  fontSize: 14,
                )),
              ),
            ),
            builder: (context, child) {
              AppLocale.current = AppLocalizations.of(context);
              debugPrint('=== 화면 크기: ${MediaQuery.of(context).size} ===');
              // 폭이 좁은 폰(엑스커버 등)은 글자를 폭에 맞춰 살짝 줄이기 → A24와 같은 비율 (최대 15%)
              final fit = (MediaQuery.of(context).size.width / 400).clamp(0.85, 1.0);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.textScale * fit),
                  boldText: false,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.dynamicBackgroundGradient(
                        themeProvider.primaryColor),
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

class _AppInitializerState extends State<AppInitializer> with WidgetsBindingObserver {
  bool _showWelcome = false;
  // 알람이나 홈 위젯 바로가기로 켜졌으면 첫인사 없이 바로
  bool _showIntro = !AlarmService.launchedByAlarm && WidgetGo.target.value == null;
  bool _introCleared = false; // 첫인사 사진을 램에서 비웠는지

  AudioPlayer? _welcomePlayer; // 첫인사 전용 작은 재생기
  VoidCallback? _welcomeCleanup;

  Future<void> _checkAndShowWelcome() async {
    if (AlarmService.launchedByAlarm) return; // 알람 때는 첫인사 안 함
    // 알람으로 열린 화면인지 폰에 한 번 더 확인 → 알람이면 인삿말 없이 바로 알람 화면
    if (await AlarmService.isAlarmIntent()) {
      AlarmService.showRing();
      return;
    }
    if (!mounted || AlarmService.launchedByAlarm) return;
    if (WidgetGo.launched || WidgetGo.target.value != null) return; // 위젯으로 켜졌으면 인삿말 없이
    if (!context.read<ThemeProvider>().voiceGreetingEnabled) return;
    final langCode = Localizations.localeOf(context).languageCode;
    final welcomeAsset = langCode == 'ko' ? 'assets/welcome_ko_v4.mp3' : null;
    if (welcomeAsset == null) return;

    // 소리 주도권(오디오 포커스)은 안 가져감 → 라디오·음악과 부딪히지 않게
    final p = AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
    _welcomePlayer = p;

    // 인삿말 도중에 라디오나 음악을 틀면 → 인삿말 바로 멈추고 정리
    final radio = context.read<RadioProvider>();
    final music = context.read<PlayerProvider>();
    void stopIfOther() {
      if (radio.isPlaying || radio.isLoading || music.isPlaying) _stopWelcome();
    }
    radio.addListener(stopIfOther);
    music.addListener(stopIfOther);
    _welcomeCleanup = () {
      radio.removeListener(stopIfOther);
      music.removeListener(stopIfOther);
    };

    // 인삿말이 끝나면 바로 정리
    p.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _stopWelcome();
    });
    try {
      await p.setAsset(welcomeAsset);
      // 준비하는 사이에 멈췄거나 위젯으로 켜졌으면 재생 안 함
      if (_welcomePlayer == p && !AlarmService.launchedByAlarm && !WidgetGo.launched) {
        p.play();
      } else {
        _stopWelcome();
      }
    } catch (_) {
      _stopWelcome();
    }
  }

  /// 위젯 바로가기로 들어오면 첫인사(사진·목소리)를 바로 끄고 그 화면으로
  void _onWidgetGoIntro() {
    if (WidgetGo.target.value == null || !mounted) return;
    WidgetGo.launched = true;
    _stopWelcome();
    if (_showIntro) setState(() => _showIntro = false);
  }

  /// 첫인사 멈추고 재생기 정리
  void _stopWelcome() {
    final p = _welcomePlayer;
    if (p == null) return;
    _welcomePlayer = null;
    _welcomeCleanup?.call();
    _welcomeCleanup = null;
    p.stop().whenComplete(() => p.dispose());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AlarmService.onRingStart = _stopWelcome; // 알람이 울리면 첫인삿말 바로 멈춤
    WidgetGo.target.addListener(_onWidgetGoIntro); // 첫인사 중에 위젯 바로가기 → 첫인사 끄기
    if (AlarmService.launchedByAlarm) {
      WidgetsBinding.instance.addPostFrameCallback((_) => AlarmService.showRing());
    }
    // (첫인사 시간은 사진이 화면에 뜬 뒤부터 _IntroView가 잼)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndShowWelcome();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 홈 사진: 홈 카드와 같은 크기(600)로 미리 준비해야 바로 뜸 (크기가 다르면 다시 읽어서 깜빡임)
      for (final path in [
        'assets/music_bg.jpg',
        'assets/radio_bg.jpg',
        'assets/nature_bg.jpg',
        'assets/sleep_bg.jpg',
      ]) {
        precacheImage(ResizeImage(AssetImage(path), width: 600), context);
      }
      // 잠시 쉬어가요 사진도 같은 크기(400)로 미리
      for (final path in [
        'assets/rest_wave.jpg',
        'assets/rest_rain.jpg',
        'assets/rest_bird.jpg',
        'assets/rest_fire.jpg',
        'assets/rest_stream.jpg',
        'assets/rest_radio.jpg',
      ]) {
        precacheImage(ResizeImage(AssetImage(path), width: 400), context, onError: (_, __) {});
      }
      precacheImage(farewellImage(context), context,
          onError: (_, __) {}); // 미리 받기 실패해도 조용히
      // 잠시 쉬어가요 라디오 사진(썸네일 10장)을 미리 받아두기
      for (var i = 1; i <= 10; i++) {
        precacheImage(
          CachedNetworkImageProvider(
              'https://files.ssing.kr/app-images/rest_radio_${i}_thumb.jpg'),
          context,
          onError: (_, __) {}, // 미리 받기 실패해도 조용히
        );
      }
      SharedPreferences.getInstance().then((prefs) {
        final bg = prefs.getString('nightBgPath');
        if (bg != null && mounted) precacheParanPhoto(bg, context);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final musicProvider = context.read<MusicProvider>();
      if (musicProvider.songs.isEmpty) {
        await musicProvider.initialize();
        context
            .read<PlaylistProvider>()
            .restorePlaylistSongs(musicProvider.allSongs);
      }
      // (배터리 창은 처음에 안 띄움 → 이어폰 이어서 듣기·아침 알람 켤 때만 물어봄)
      if (!AlarmService.launchedByAlarm) {
        await _checkAndRequestReview();
        await _checkForUpdate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AlarmService.onRingStart = null;
    WidgetGo.target.removeListener(_onWidgetGoIntro);
    _stopWelcome();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      // 이미 다운로드가 끝나있는데 설치(재시작)만 안 된 경우 - 바로 안내
      if (info.installStatus == InstallStatus.downloaded) {
        _showUpdateReadySnackbar();
        return;
      }
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        InAppUpdate.installUpdateListener.listen((status) {
          if (status == InstallStatus.downloaded && mounted) {
            _showUpdateReadySnackbar();
          }
        });
        await InAppUpdate.startFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('업데이트 확인 오류: $e');
    }
  }

  /// 업데이트 완료 창 (아침 사진 + 워터마크)
  Future<void> _showUpdateReadySnackbar() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final restart = await showPhotoDialog(
      context,
      image: 'assets/update_banner.jpg',
      title: l.updateReadyTitle,
      message: l.updateReadyMessage,
      primary: l.updateReadyButton,
      secondary: l.updateReadyLater,
      primaryIcon: Icons.refresh_rounded,
      barrierDismissible: false,
    );
    if (restart) InAppUpdate.completeFlexibleUpdate();
  }

  // (예전 업데이트 창 — 코드 정리할 때 지우기)
  void _oldUpdateReadySnackbar() {
    if (!mounted) return;
    const accent = AppTheme.fixedAccent;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.system_update, color: accent, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(ctx)!.updateReadyTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(ctx)!.updateReadyMessage,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    InAppUpdate.completeFlexibleUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    AppLocalizations.of(ctx)!.updateReadyButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black38,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(AppLocalizations.of(ctx)!.updateReadyLater, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  /// 리뷰 부탁 창 (오후 사진 + 별 5개 + 워터마크)
  Future<void> _showReviewDialog() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final go = await showPhotoDialog(
      context,
      image: 'assets/review_banner.jpg',
      title: l.reviewTitle,
      message: l.reviewMessage,
      primary: l.reviewButton,
      secondary: l.reviewLater,
      stars: true,
      barrierDismissible: false,
    );
    await prefs.setInt('last_review_request', DateTime.now().millisecondsSinceEpoch);
    if (go) {
      try {
        await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong'),
            mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  // (예전 리뷰 창 — 코드 정리할 때 지우기)
  Future<void> _oldReviewDialog() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final prefs = await SharedPreferences.getInstance();
    final l = AppLocalizations.of(context)!;

    const accent = AppTheme.fixedAccent;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F7DE8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                l.reviewTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
              const SizedBox(height: 8),
              Text(
                l.reviewMessage,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.star_rounded,
                        color: Color(0xFFF5B83D), size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await prefs.setInt('last_review_request',
                        DateTime.now().millisecondsSinceEpoch);
                    final uri = Uri.parse(
                        'https://play.google.com/store/apps/details?id=kr.ssing.catsong');
                    try {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (e) {}
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2F7DE8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l.reviewButton,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    prefs.setInt('last_review_request',
                        DateTime.now().millisecondsSinceEpoch);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black38,
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
    if (_showIntro) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        // 상단 아이콘 색을 홈과 같게 (넘어갈 때 하얗다 검게 바뀌지 않게)
        value: context.watch<ThemeProvider>().systemBarStyle,
        child: GestureDetector(
        onTap: () => setState(() => _showIntro = false),
        child: Scaffold(
          // 시작 화면과 같은 색 (라이트 크림 · 다크 진한 갈색) → 넘어갈 때 번쩍이지 않게
          backgroundColor: context.watch<ThemeProvider>().isDarkMode
              ? const Color(0xFF24221F)
              : const Color(0xFFF4EFE5),
          body: _IntroView(
            path: introAssetPath(context),
            onDone: () {
              if (mounted) setState(() => _showIntro = false);
            },
            // 새 사진(글자 없음)은 한국어만 → 'Paransori'를 코드로 얹기
            showTitle: greetingHasTitle(context),
          ),
        ),
        ),
      );
    }
    // 첫인사가 끝나면 사진은 다시 안 쓰니까 램에서만 비우기 (화면이 바뀐 뒤에)
    if (!_introCleared) {
      _introCleared = true;
      final introPath = introAssetPath(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => AssetImage(introPath).evict());
    }
    return const HomeScreen();
  }
}

/// 첫인사 화면: 사진이 아주 천천히 다가오고, 'Paransori'가 아래에서 떠오르며 나타남
class _IntroView extends StatefulWidget {
  final String path;
  final bool showTitle;
  final VoidCallback onDone;
  const _IntroView({required this.path, required this.showTitle, required this.onDone});

  @override
  State<_IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<_IntroView> with TickerProviderStateMixin {
  // 전체 4.5초: 사진이 올라옴(0~1.8초) → 글자(1.3~2.5초) → 소리 파형(1.9초~)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
  // 파형이 다 자란 뒤 숨 쉬듯 살짝 움직이기
  late final AnimationController _p =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false;
  // 켤 때마다 인사말 한 줄을 무작위로
  final String _line = _greetingLines[Random().nextInt(5)];
  String get _greet {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final i = _greetingLines.indexOf(_line);
    return ko ? _line : _greetingLinesEn[i];
  }

  // 소리 파형: 막대 20개 높이 · 색 (홈 카드 색: 살구 → 보라 → 흰 → 연두 → 살구)
  static const _barH = <int>[4, 7, 11, 16, 10, 20, 14, 24, 18, 12, 22, 15, 9, 17, 11, 6, 13, 8, 5, 4];
  static const _barColors = <Color>[Color(0xFFFF9A70), Color(0xFFEE978B), Color(0xFFDE94A6), Color(0xFFCD91C1), Color(0xFFBC8EDC), Color(0xFFB492F1), Color(0xFFC5AAF4), Color(0xFFD5C2F7), Color(0xFFE6DBFA), Color(0xFFF7F3FD), Color(0xFFF2FAF3), Color(0xFFD9F0DA), Color(0xFFBFE6C1), Color(0xFFA6DCA9), Color(0xFF8CD290), Color(0xFF99C786), Color(0xFFB3BC80), Color(0xFFCCB17B), Color(0xFFE6A575), Color(0xFFFF9A70)];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // 사진을 다 불러온 다음에 시작 (불러오는 동안 시간이 흘러가지 않게)
    precacheImage(AssetImage(widget.path), context).whenComplete(() {
      if (!mounted) return;
      _c.forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) _p.repeat(); // 끝인사와 같은 숨 쉬기 (1.1초마다 한 번)
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _p.dispose();
    super.dispose();
  }

  // 0~4.5초 중 [from]~[to]초 구간의 진행(0~1)
  double _seg(double from, double to, Curve curve) {
    final sec = _c.value * 4.5;
    final v = ((sec - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: Listenable.merge([_c, _p]),
      builder: (context, _) {
        // 사진: 아래에서 올라오며 나타나고(1.8초), 그다음 아주 천천히 다가오기
        final rise = _seg(0, 1.8, Curves.easeOutCubic);
        final zoom = _seg(1.8, 4.5, Curves.easeOut);
        final photoScale = 1.08 - 0.08 * rise + 0.05 * zoom;
        // 글자: 1.3초부터 떠오르며 글자 사이가 모임
        final t = _seg(1.3, 2.5, Curves.easeOutCubic);
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: rise,
              child: Transform.translate(
                offset: Offset(0, h * 0.03 * (1 - rise)), // 사진이 크게 시작해서 3%까지는 위가 안 비어요
                child: Transform.scale(
                  scale: photoScale,
                  child: Image.asset(widget.path, fit: BoxFit.cover), // 화면 꽉 채우기
                ),
              ),
            ),
            if (widget.showTitle)
              Positioned(
                left: 0,
                right: 0,
                top: h * 0.13, // 사람·소품과 안 겹치게 위쪽 빈 곳
                child: Column(
                  children: [
                    Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - t)),
                        child: Text(
                          'Paransori',
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.noScaling, // 글자 크기 설정과 상관없이 고정
                          style: GoogleFonts.quicksand( // 홈 로고와 같은 글꼴
                            color: const Color(0xFF17140F),
                            fontSize: 34,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5 + 3.5 * (1 - t),
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.55),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 소리 파형: 가운데서 양쪽으로 자라고, 다 자라면 살짝 숨 쉬듯
                    SizedBox(
                      height: 34,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _barH.length; i++) ...[
                            if (i > 0) const SizedBox(width: 3.5),
                            Builder(builder: (_) {
                              final d = (i - 10) * (i - 10) * 0.006; // 가운데부터
                              final g = _seg(1.9 + d, 2.5 + d, Curves.easeOutBack);
                              final phase = ((_p.value + i * 0.07) % 1.0);
                              final breathe = 1 - 0.45 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                              final bh = (2 + (_barH[i] * 1.25 - 2) * g) * (_p.isAnimating ? breathe : 1);
                              return Container(
                                width: 3,
                                height: bh.clamp(2.0, 40.0),
                                decoration: BoxDecoration(
                                  // 낮 버전: 끝인사와 같은 색을 조금 진하게 (밝은 사진 위에서 보이게)
                                  // 연한 첫인사 사진에 어울리게: 파스텔에 먹색 살짝 + 조금 투명하게
                                  // 'Paransori' 글자와 같은 먹색 한 가지로 (사진과 안 튀게)
                                  color: const Color(0xFF17140F).withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 인사말 한 줄 (끝인사 한 줄과 같은 자리·크기)
                    Builder(builder: (_) {
                      final s = _seg(2.4, 3.2, Curves.easeOutCubic);
                      return Opacity(
                        opacity: s,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - s)),
                          child: Text(
                            _greet,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF17140F).withOpacity(0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 첫인사 인사말 (켤 때마다 하나씩 무작위) — 번역할 때 일본어·중국어 추가
const _greetingLines = <String>[
  '오늘도 좋은 소리와 함께해요',
  '반가워요, 잠시 쉬어가요',
  '편안한 하루 되세요',
  '오늘 하루도 반가워요',
  '마음이 쉬어가는 곳, 파란소리',
];
const _greetingLinesEn = <String>[
  'Welcome back',
  'Good sounds, good day',
  'Take a moment for yourself',
  'Your sounds are waiting',
  'Relax and listen',
];

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
  final paint = Paint()
  ..color = color.withOpacity(0.20)
  ..style = PaintingStyle.fill;

  final path = Path();
  path.moveTo(0, size.height * 0.6);
  for (double x = 0; x <= size.width; x++) {
  final y = size.height * 0.6 +
  20 * sin((x / size.width) * 3.14159 * 3) +
  10 * sin((x / size.width) * 3.14159 * 6);
  path.lineTo(x, y);
  }
  path.lineTo(size.width, size.height);
  path.lineTo(0, size.height);
  path.close();
  canvas.drawPath(path, paint);

  final paint2 = Paint()
  ..color = color.withOpacity(0.12)
  ..style = PaintingStyle.fill;

  final path2 = Path();
  path2.moveTo(0, size.height * 0.4);
  for (double x = 0; x <= size.width; x++) {
  final y = size.height * 0.4 +
  15 * sin((x / size.width) * 3.14159 * 4 + 1) +
  8 * sin((x / size.width) * 3.14159 * 7 + 2);
  path2.lineTo(x, y);
  }
  path2.lineTo(size.width, size.height);
  path2.lineTo(0, size.height);
  path2.close();
  canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
  }
