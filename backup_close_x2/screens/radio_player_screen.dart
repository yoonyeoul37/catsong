import 'dart:math';
import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/greeting_images.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sleep_timer_sheet.dart';
import '../widgets/schedule_sheet.dart';
import '../widgets/fm_tuner_dial.dart';
import '../widgets/global_radio_dial.dart';
import '../widgets/simple_radio_dial.dart';
import '../widgets/frequency_ruler.dart';
import '../widgets/radio_mood_placeholder.dart';
import '../widgets/overseas_radio_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/equalizer_animation.dart';
import '../l10n/app_localizations.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart' show globalAudioHandler;
import '../providers/player_provider.dart' show SimpleAudioHandler;
import '../providers/theme_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'nature_sounds_screen.dart';
import 'settings_screen.dart';
import '../widgets/seasonal_effect.dart';
import '../widgets/more_menu_sheet.dart';
import '../models/radio_country.dart';
import 'radio_korea_screen2.dart';
import 'radio_country_stations_screen.dart';
import 'radio_home_screen.dart';
import '../services/cast_service.dart';
import '../widgets/cast_sheets.dart';
import '../widgets/exit_confirm_dialog.dart';
import '../widgets/paran_toast.dart';
import '../widgets/action_feedback.dart';

double? _parseFrequency(String? freq) {
  if (freq == null || freq.isEmpty) return null;
  final match = RegExp(r'(\d+\.?\d*)').firstMatch(freq);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

bool _isKoreanStation(String countryCode) => countryCode == 'KR';

// ── 라디오 창 색 (라이트: 베이지 · 다크: 어두운 갈색) — 창을 그릴 때마다 다크 모드인지 맞춤 ──
bool _rdDark = false;
Color get _rBg => _rdDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
Color get _rCard => _rdDark ? const Color(0xFF332E26) : Colors.white;
Color get _rInk => _rdDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color get _rSub => _rdDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
Color get _rMuted => _rdDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
Color get _rLine => _rdDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);

class RadioPlayerScreen extends StatefulWidget {
  final RadioStation station;
  final List<RadioStation>? stationList;
  final int? currentIndex;
  final bool openedFromList;
  const RadioPlayerScreen({
    super.key,
    required this.station,
    this.stationList,
    this.currentIndex,
    this.openedFromList = true,
  });

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _dialCtrl;   // 다이얼 포인터 진입 애니메이션
  late AnimationController _pulseCtrl;  // ON AIR 펄스
  late AnimationController _rotCtrl;   // 안쪽 원 회전
  late int _currentIdx;
  bool _scheduleTimedOut = false;

  void _onCastChanged() {
    if (mounted) setState(() {});
  }

  /// TV로 듣기 버튼: 연결 중이면 조작 창, 아니면 TV 고르기
  void _onRadioCastTap(RadioStation station, RadioProvider radio) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final cast = CastService.instance;
    if (cast.isConnected) {
      showCastControlSheet(context);
      return;
    }
    final url = radio.lastPlayStationId == station.stationUuid ? radio.lastPlayUrl : null;
    if (url == null) {
      showParanToast(context, '방송이 나오고 있을 때 TV로 보낼 수 있어요');
      return;
    }
    showCastPickerSheet(context, onPick: (d) async {
      final ok = await cast.connectRadio(
        d,
        key: 'radio:${station.stationUuid}',
        url: url,
        headers: radio.castHeadersFor(station),
        title: station.name,
        subtitle: station.country ?? '',
        logoUrl: station.logoUrl,
      );
      if (ok && radio.isPlaying) radio.togglePlayPause(); // 폰 소리는 멈춤
      return ok;
    });
  }

  /// 종료 확인창 → 작별 인사 → 종료 (해외 라디오 화면에서 사용)
  Future<void> _confirmExit(BuildContext context) async {
    // 새 종료창 (사진 + 큰 질문) — 홈·음악·라디오·자연소리 공통
    if (await showExitConfirm(context) && context.mounted) _showFarewellAndExit(context);
  }

  // (예전 종료창 — 코드 정리할 때 지우기)
  Future<void> _oldConfirmExit(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(ctx)!.radioExitConfirmTitle,
                style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(ctx)!.radioExitConfirmMessage,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx, false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(ctx)!.radioExitKeepListening),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(ctx)!.radioExitConfirmButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    _showFarewellAndExit(context);
  }

  void _showFarewellAndExit(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    late final String smallText;
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        smallText = '파란소리와 함께한 시간,\n즐거우셨나요?\n\n언제든 다시 찾아오시면,\n좋은 소리로 맞아드릴게요.\n안녕히 가세요!';
        farewellAsset = 'assets/farewell_ko_v4.mp3';
        break;
      case 'ja':
        smallText = 'Paransoriと過ごした時間、\n楽しんでいただけましたか?\n\nいつでもまた遊びに来てください、\n素敵な音でお迎えします。\nまた会いましょう!';
        farewellAsset = 'assets/farewell_ja.mp3';
        break;
      case 'zh':
        smallText = '与Paransori相伴的时光，\n您开心吗?\n\n欢迎随时回来，\n我们会用美好的声音迎接您。\n再见啦!';
        farewellAsset = 'assets/farewell_zh.mp3';
        break;
      default:
        smallText = 'Did you enjoy your time\nwith Paransori?\n\nCome back anytime — we\'ll\nwelcome you with great sounds again.\nGoodbye, and see you soon!';
        farewellAsset = 'assets/farewell_en.mp3';
    }
    if (context.read<ThemeProvider>().voiceGreetingEnabled) {
      final farewellPlayer = AudioPlayer();
      farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
    }
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.05, end: 0.85),
            duration: const Duration(milliseconds: 11000),
            curve: Curves.easeIn,
            builder: (_, darkValue, __) => Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(farewellImageUrl(context)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(darkValue),
                    BlendMode.darken,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 8000), () async {
      late OverlayEntry fadeOutEntry;
      fadeOutEntry = OverlayEntry(
        builder: (_) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      );
      overlay.insert(fadeOutEntry);

      await context.read<RadioProvider>().stopRadio();
      final handler = globalAudioHandler;
      if (handler is SimpleAudioHandler) {
        handler.setRadioMode(false);
        handler.playbackState.add(PlaybackState());
        handler.mediaItem.add(null);
        await handler.stop();
      }

      await Future.delayed(const Duration(milliseconds: 900));
      entry.remove();
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('closeApp');
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _scheduleTimedOut = true);
    });
    // TV 상태가 바뀌면 화면도 바로 다시 그리기
    CastService.instance.addListener(_onCastChanged);
    Future.delayed(Duration.zero, () {
    });
    _dialCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _currentIdx = widget.currentIndex ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final radio = context.read<RadioProvider>();
      if (widget.stationList != null && widget.currentIndex != null) {
        radio.setQueue(widget.stationList!, widget.currentIndex!);
      }
      if (radio.currentStation?.name != widget.station.name) {
        radio.playStation(widget.station);
      } else if (!radio.isPlaying && !radio.isLoading) {
        radio.playStation(widget.station);
      }
      final streamUrl = widget.station.streamUrl;
      final stationName = widget.station.name;
      if (streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
        radio.fetchScheduleByUrl(stationName, streamUrl);
      } else if (stationName == 'MBC 표준FM' || stationName == 'MBC FM4U') {
        radio.fetchMbcSchedule(stationName);
      } else if (stationName == 'SBS 파워FM' || stationName == 'SBS 러브FM') {
        radio.fetchSbsSchedule(stationName);
      } else if (stationName == 'BBS 불교방송') {
        radio.fetchBbsSchedule();
      } else if (stationName.contains('KBS')) {
        radio.fetchSchedule(stationName);
      }
      // CBS 등 JSON 편성표는 playStation에서 처리하므로 여기서 호출 안 함
    });
  }

  @override
  void dispose() {
    CastService.instance.removeListener(_onCastChanged);
    _dialCtrl.dispose();
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  // KBS/MBC/SBS 한국 방송만 편성표 지원
  bool _isKoreanBroadcast(String name) {
    final lower = name.toLowerCase();
    return lower.contains('kbs') ||
        name.contains('MBC') ||
        name.contains('SBS') ||
        name.contains('CBS') ||
        name == '국방FM' ||
        name == 'EBS 반디' ||
        name == 'EBS FM' ||
        name == 'BBS 불교방송';
  }

  String _getBroadcaster(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kbs')) return 'KBS';
    if (lower.contains('mbc')) return 'MBC';
    if (lower.contains('sbs')) return 'SBS';
    if (lower.contains('cbs')) return 'CBS';
    if (lower.contains('ebs')) return 'EBS';
    if (lower.contains('ytn')) return 'YTN';
    if (lower.contains('tbs')) return 'TBS';
    if (lower.contains('tbn')) return 'TBN';
    if (lower.contains('obs')) return 'OBS';
    if (lower.contains('cpbc')) return 'CPBC';
    if (lower.contains('befm')) return 'BeFM';
    if (lower.contains('jtv')) return 'JTV';
    if (lower.contains('arirang')) return 'Arirang';
    if (lower.contains('gugak') || lower.contains('국악')) return '국악FM';
    if (lower.contains('국방')) return '국방FM';
    return '';
  }

  Color _brandColor(String bc) {
    const colors = {
      'KBS': Color(0xFF1565C0),
      'MBC': Color(0xFF6A1B9A),
      'SBS': Color(0xFFB71C1C),
      'CBS': Color(0xFF1B5E20),
      'EBS': Color(0xFF0277BD),
      'YTN': Color(0xFF880E4F),
      'TBS': Color(0xFF004D40),
      'TBN': Color(0xFF2E7D32),
      'OBS': Color(0xFF0D47A1),
      'CPBC': Color(0xFF6D4C41),
      'BeFM': Color(0xFFE65100),
      'JTV': Color(0xFF00695C),
    };
    return colors[bc] ?? const Color(0xFF37474F);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF17140F),
          systemNavigationBarIconBrightness: Brightness.light,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFEDE7DA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });
    final state = radioProvider.playerState;
    final current = radioProvider.currentStation ??
        (widget.stationList != null && _currentIdx < widget.stationList!.length
            ? widget.stationList![_currentIdx]
            : widget.station);
    // TV로 듣는 중이면 재생 버튼·이퀄라이저는 TV 상태를 따름
    final isPlaying = CastService.instance.isConnected
        ? CastService.instance.tvPlaying
        : state == RadioPlayerState.playing;
    final isLoading = state == RadioPlayerState.loading;
    final isError = state == RadioPlayerState.error;
    final sleep = radioProvider.sleepRemaining;

    // 재생 중이면 안쪽 원 회전
    if (isPlaying) {
      _rotCtrl.repeat();
    } else {
      _rotCtrl.stop();
    }
    final broadcaster = _getBroadcaster(current.name);
    final bcColor = _brandColor(broadcaster);
    final freq = current.frequency ?? '';

    // TV로 듣는 중이면: 방송이 바뀌면 TV로 새 방송을 보내고, 폰 소리는 멈춤
    final cast = CastService.instance;
    if (cast.isConnected) {
      final key = 'radio:${current.stationUuid}';
      final url = radioProvider.lastPlayStationId == current.stationUuid ? radioProvider.lastPlayUrl : null;
      final needNew = cast.currentUri != key && url != null;
      if (needNew || radioProvider.isPlaying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (radioProvider.isPlaying) radioProvider.togglePlayPause();
          if (needNew) {
            cast.castRadio(
              key: key,
              url: url!,
              headers: radioProvider.castHeadersFor(current),
              title: current.name,
              subtitle: current.country ?? '',
              logoUrl: current.logoUrl,
            );
          }
        });
      }
    }

    // 해외 방송국은 애플뮤직 스타일 화면으로 (한국은 기존 화면 그대로)
    if (current.countryCode != 'KR') {
      return OverseasRadioView(
        station: current,
        openedFromList: widget.openedFromList,
        onExit: () => _confirmExit(context),
        onCast: () => _onRadioCastTap(current, radioProvider),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA),
      bottomNavigationBar: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final list = widget.stationList;
          if (list == null) return;
          if (details.primaryVelocity! < -300) {
            final newIdx = _currentIdx < list.length - 1 ? _currentIdx + 1 : 0;
            setState(() => _currentIdx = newIdx);
            context.read<RadioProvider>().setQueue(list, newIdx);
            context.read<RadioProvider>().playStation(list[newIdx]);
          } else if (details.primaryVelocity! > 300) {
            final newIdx = _currentIdx > 0 ? _currentIdx - 1 : list.length - 1;
            setState(() => _currentIdx = newIdx);
            context.read<RadioProvider>().setQueue(list, newIdx);
            context.read<RadioProvider>().playStation(list[newIdx]);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 하단바: 바닥에 붙은 미니멀 (베이지 · 얇은 선)
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF17140F) : const Color(0xFFF4EFE5),
                border: Border(
                    top: BorderSide(
                        color: isDarkMode ? const Color(0xFF3A342B) : const Color(0xFFE2DACB), width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // 지금 프로그램 한 줄 (한국 방송일 때)
                  if (_isKoreanBroadcast(current.name)) const _NowProgramStrip(),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_isKoreanBroadcast(current.name))
                              _BottomBarItem(
                                icon: Icons.format_list_bulleted,
                                label: AppLocalizations.of(context)!.radioBroadcastSchedule,
                                hasIndicator: false,
                                primaryColor: primaryColor,
                                onTap: () {
                                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => _ScheduleListSheet(stationName: current.name),
                                  );
                                },
                              ),
                            _BottomBarItem(
                              icon: Icons.bedtime_outlined,
                              // 켜져 있으면 "수면" 대신 남은 시간 (예: 28분)
                              label: radioProvider.isSleepTimerActive && radioProvider.sleepRemaining != null
                                  ? '${radioProvider.sleepRemaining!.inMinutes + 1}분'
                                  : AppLocalizations.of(context)!.radioSleep,
                              hasIndicator: radioProvider.isSleepTimerActive,
                              primaryColor: primaryColor,
                              onTap: () {
                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  barrierColor: Colors.black.withOpacity(0.7),
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => const SleepTimerSheet(),
                                );
                              },
                            ),
                            _BottomBarItem(
                              icon: Icons.schedule,
                              label: AppLocalizations.of(context)!.radioSchedule,
                              hasIndicator: false,
                              badge: radioProvider.schedules.where((s) => !s.triggered).length, // 예약 개수
                              primaryColor: primaryColor,
                              onTap: () {
                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => const ScheduleSheet(),
                                );
                              },
                            ),
                            _BottomBarItem(
                              icon: CupertinoIcons.heart,
                              label: AppLocalizations.of(context)!.favorites,
                              hasIndicator: false,
                              primaryColor: primaryColor,
                              onTap: () {
                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => _FavoritesSheet(primaryColor: primaryColor),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: baseColor.withOpacity(0.12),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          // 새 종료창 (사진 + 큰 질문) — 홈·음악·라디오·자연소리 공통
                          if (await showExitConfirm(context) && context.mounted) _showFarewellAndExit(context);
                          return;
                          // ignore: dead_code
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLocalizations.of(ctx)!.radioExitConfirmTitle,
                                      style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(ctx)!.radioExitConfirmMessage,
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                              Navigator.pop(ctx, false);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.black54,
                                              side: const BorderSide(color: Color(0xFFE5E5E5)),
                                              padding: const EdgeInsets.symmetric(vertical: 13),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: Text(AppLocalizations.of(ctx)!.radioExitKeepListening),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                              Navigator.pop(ctx, true);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 13),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: Text(AppLocalizations.of(ctx)!.radioExitConfirmButton),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          if (confirmed != true) return;
                          _showFarewellAndExit(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.power_settings_new_rounded, color: baseColor.withOpacity(0.55), size: 22),
                              const SizedBox(height: 3),
                              Text(
                                AppLocalizations.of(context)!.exit,
                                style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 10.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final h = constraints.maxHeight;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // ── 상단 버튼: 뒤로가기 + 공유 + 즐겨찾기 ──
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FloatButton(
                              onTap: () {
                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                if (widget.openedFromList) {
                                  Navigator.pop(context);
                                } else {
                                  final country = radioProvider.selectedCountry;
                                  // 한국 방송이면 항상 한국 목록으로
                                  final Widget listScreen = current.countryCode == 'KR'
                                      ? const RadioKoreaScreen()
                                      : country == null
                                          ? const RadioHomeScreen()
                                          : country.code == 'KR'
                                              ? const RadioKoreaScreen()
                                              : RadioCountryStationsScreen(country: country);
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => listScreen,
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                          FadeTransition(opacity: animation, child: child),
                                      transitionDuration: const Duration(milliseconds: 250),
                                    ),
                                  );
                                }
                              },
                              child: Icon(Icons.expand_more, color: baseColor, size: 16),
                            ),
                            Row(
                              children: [
                                _FloatButton(
                                  onTap: () {
                                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                    final wasFav = radioProvider.isFavorite(current.stationUuid);
                                    // (하트가 바로 바뀌어서 따로 알림 없음)
                                    Future.microtask(() => radioProvider.toggleFavorite(current));
                                  },
                                  child: Icon(
                                    radioProvider.isFavorite(current.stationUuid) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                    color: radioProvider.isFavorite(current.stationUuid) ? baseColor : baseColor.withOpacity(0.6),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _FloatButton(
                                  onTap: () {
                                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                    context.read<ThemeProvider>().setDarkMode(!isDarkMode);
                                  },
                                  child: Icon(
                                    isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                    color: baseColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _FloatButton(
                                  onTap: () {
                                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                  child: Icon(Icons.home_rounded, color: baseColor, size: 16),
                                ),
                                const SizedBox(width: 10),
                                // TV로 듣기 (연결되면 파란색)
                                AnimatedBuilder(
                                  animation: CastService.instance,
                                  builder: (ctx, _) => _FloatButton(
                                    onTap: () => _onRadioCastTap(current, radioProvider),
                                    child: Icon(
                                      CastService.instance.isConnected ? Icons.cast_connected : Icons.cast,
                                      color: CastService.instance.isConnected ? const Color(0xFF2589E8) : baseColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Builder(builder: (ctx) {
                                  final homepage = radioProvider.homepageFor(current.name) ?? current.homepage;
                                  return _FloatButton(
                                    onTap: () {
                                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                      showMoreMenuSheet(
                                        context,
                                        shareText: '지금 ${current.name} 듣고 있어요! 파란소리에서 같이 들어요 🎧',
                                        shareSubtitle: '지금 듣는 방송을 소개해보세요.',
                                        stationHomepage: homepage,
                                      );
                                      return;
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        barrierColor: Colors.black.withOpacity(0.45),
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                        builder: (sheetCtx) {
                                          final sheetBg = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAFCFE);
                                          final cardBg = isDarkMode
                                              ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                              colors: [Color(0xFF22303F), Color(0xFF1A2632)])
                                              : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                              colors: [Colors.white, Color(0xFFEAF3FC)]);
                                          final cardBorder = isDarkMode ? Colors.white12 : const Color(0xFFE1EDF7);
                                          const navy = Color(0xFF15304D);
                                          final subColor = isDarkMode ? Colors.white60 : const Color(0xFF7891A8);

                                          Widget menuCard({
                                            required IconData icon,
                                            required String title,
                                            required String subtitle,
                                            required VoidCallback onTap,
                                          }) {
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: onTap,
                                                child: Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    gradient: cardBg,
                                                    border: Border.all(color: cardBorder),
                                                    borderRadius: BorderRadius.circular(18),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isDarkMode
                                                            ? Colors.black.withOpacity(0.35)
                                                            : const Color(0xFF2C6BB3).withOpacity(0.08),
                                                        blurRadius: 16,
                                                        offset: const Offset(0, 6),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        width: 44,
                                                        height: 44,
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                            colors: [Color(0xFF4A90D9), Color(0xFF2C6BB3)],
                                                          ),
                                                          borderRadius: BorderRadius.circular(14),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xFF2C6BB3).withOpacity(0.35),
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Icon(icon, color: Colors.white, size: 21),
                                                      ),
                                                      const SizedBox(height: 14),
                                                      Text(title,
                                                          style: TextStyle(
                                                              color: isDarkMode ? Colors.white : navy,
                                                              fontSize: 14.5,
                                                              fontWeight: FontWeight.w700)),
                                                      const SizedBox(height: 4),
                                                      Text(subtitle,
                                                          maxLines: 2,
                                                          style: TextStyle(color: subColor, fontSize: 11, height: 1.4)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          return SafeArea(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: sheetBg,
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                              ),
                                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 4,
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    decoration: BoxDecoration(
                                                      color: isDarkMode ? Colors.white24 : const Color(0xFFCBD9EC),
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: GestureDetector(
                                                      onTap: () => Navigator.pop(sheetCtx),
                                                      child: Container(
                                                        width: 30,
                                                        height: 30,
                                                        margin: const EdgeInsets.only(bottom: 8),
                                                        decoration: BoxDecoration(
                                                          color: isDarkMode ? Colors.white10 : const Color(0xFFF0F5FA),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(Icons.close,
                                                            size: 16, color: isDarkMode ? Colors.white70 : subColor),
                                                      ),
                                                    ),
                                                  ),
                                                  IntrinsicHeight(
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        menuCard(
                                                          icon: Icons.share_outlined,
                                                          title: '친구에게 공유하기',
                                                          subtitle: '지금 듣는 방송을\n친구에게 소개해보세요.',
                                                          onTap: () {
                                                            Navigator.pop(sheetCtx);
                                                            Share.share('지금 ${current.name} 듣고 있어요! 파란소리에서 같이 들어요 🎧\nhttps://play.google.com/store/apps/details?id=kr.ssing.catsong');
                                                          },
                                                        ),
                                                        const SizedBox(width: 12),
                                                        menuCard(
                                                          icon: Icons.star_border_rounded,
                                                          title: '앱 평가하기',
                                                          subtitle: '좋은 평가가\n큰 힘이 됩니다.',
                                                          onTap: () async {
                                                            Navigator.pop(sheetCtx);
                                                            final uri = Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong');
                                                            if (await canLaunchUrl(uri)) {
                                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  IntrinsicHeight(
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        menuCard(
                                                          icon: Icons.settings_outlined,
                                                          title: '설정',
                                                          subtitle: '앱 환경을\n설정할 수 있어요.',
                                                          onTap: () {
                                                            Navigator.pop(sheetCtx);
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                                            );
                                                          },
                                                        ),
                                                        if (homepage != null && homepage.isNotEmpty) ...[
                                                          const SizedBox(width: 12),
                                                          menuCard(
                                                            icon: Icons.home_outlined,
                                                            title: '방송국 바로가기',
                                                            subtitle: '방송국 홈페이지로\n이동해요.',
                                                            onTap: () async {
                                                              Navigator.pop(sheetCtx);
                                                              final uri = Uri.parse(homepage);
                                                              if (await canLaunchUrl(uri)) {
                                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Icon(Icons.more_vert, color: baseColor, size: 16),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: (h * 0.02).clamp(10.0, 24.0)),

                      // ── 이미지(있으면) 또는 방송국명 박스, 채널명·시간 오버레이 ──
                      Builder(builder: (ctx) {
                        final programImage = radioProvider.currentProgram?['image'] as String?;
                        final hasImage = programImage != null && programImage.isNotEmpty;
                        final scheduleLoading = !_scheduleTimedOut &&
                            radioProvider.scheduleList.isEmpty &&
                            radioProvider.currentProgram == null;
                        final timeStr = radioProvider.currentProgram != null
                            ? _ProgramCard.getTimeStr(radioProvider.currentProgram!, radioProvider)
                            : '';
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              scheduleLoading
                                  ? Container(
                                width: double.infinity,
                                height: h * 0.28,
                                color: isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA),
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: baseColor.withOpacity(0.24)),
                                ),
                              )
                                  : hasImage
                                  ? Image.network(
                                programImage,
                                width: double.infinity,
                                height: h * 0.28,
                                fit: BoxFit.cover,
                                errorBuilder: (errCtx, err, stack) =>
                                    RadioMoodPlaceholder(height: (h * 0.24).clamp(120.0, 220.0)),
                              )
                                  : RadioMoodPlaceholder(height: h * 0.28),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.75),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        current.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (timeStr.isNotEmpty)
                                        Transform.translate(
                                          offset: const Offset(0, 0),
                                          child: Text(
                                            timeStr,
                                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.0),
                                          ),
                                        ),
                                      Builder(builder: (ctx) {
                                        final smsNumber = radioProvider.smsNumberFor(current.name);
                                        if (smsNumber == null) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: GestureDetector(
                                            onTap: () async {
                                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                              final uri = Uri(scheme: 'sms', path: smsNumber);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri);
                                              }
                                            },
                                            child: Text(
                                              '문자 참여 #$smsNumber',
                                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: (h * 0.02).clamp(8.0, 16.0)),

                      if (_parseFrequency(freq) != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FrequencyRuler(
                            frequency: _parseFrequency(freq),
                            primaryColor: primaryColor,
                          ),
                        ),

                      // ── 편성표 (편성 정보가 있을 때만 자리를 차지하게, 높이도 화면 비율) ──
                      if (radioProvider.currentProgram != null)
                        SizedBox(
                          height: (h * 0.09).clamp(48.0, 68.0),
                          child: Center(
                            child: _ProgramCard(
                              program: radioProvider.currentProgram!,
                              primaryColor: primaryColor,
                              radioProvider: radioProvider,
                              freq: freq,
                            ),
                          ),
                        ),

                      if (radioProvider.currentProgram != null &&
                          radioProvider.scheduleList.isNotEmpty) ...[
                        SizedBox(height: (h * 0.005).clamp(2.0, 4.0)),
                        _NextProgramLine(
                          scheduleList: radioProvider.scheduleList,
                          currentProgram: radioProvider.currentProgram!,
                          radioProvider: radioProvider,
                        ),
                      ] else if (radioProvider.descriptionFor(current.name) != null) ...[
                        SizedBox(height: (h * 0.005).clamp(2.0, 4.0)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.podcasts, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  radioProvider.descriptionFor(current.name)!,
                                  style: TextStyle(color: baseColor.withOpacity(0.75), fontSize: 13, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: (h * 0.008).clamp(3.0, 8.0)),

                      // 해외·음악 화면과 같은 산 모양 (정지 중엔 낮게 멈춤)
                      SizedBox(height: (h * 0.008).clamp(3.0, 8.0)),
                      MountainEqBars(isPlaying: isPlaying, color: primaryColor),
                      const SizedBox(height: 6),

                      // ── 상태 뱃지 ──
                      // TV로 듣는 중이면 "OO에서 재생 중" (폰은 멈춰 있어도 '일시정지'로 안 보이게)
                      CastService.instance.isConnected
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2589E8).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2589E8).withOpacity(0.35)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.cast_connected, size: 14, color: Color(0xFF2589E8)),
                                const SizedBox(width: 6),
                                Text(
                                  CastService.instance.tvPlaying
                                      ? '${CastService.instance.device?.name ?? 'TV'}에서 재생 중'
                                      : 'TV에서 일시정지',
                                  style: const TextStyle(
                                      color: Color(0xFF2589E8), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ]),
                            )
                          : _StatusBadge(state: state),

                      if (isError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            radioProvider.errorMessage ?? AppLocalizations.of(context)!.radioPlaybackFailed,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),

                      SizedBox(height: (h * 0.02).clamp(8.0, 20.0)),

                      // ── 컨트롤 ──
                      _Controls(
                        isLoading: isLoading,
                        isError: isError,
                        isPlaying: isPlaying,
                        primaryColor: primaryColor,
                        currentIdx: _currentIdx,
                        stationList: widget.stationList,
                        radioProvider: radioProvider,
                        current: current,
                        onIndexChanged: (idx) => setState(() => _currentIdx = idx),
                      ),

                      SizedBox(height: h * 0.01),

                      if (sleep != null) _SleepTimerBadge(remaining: sleep),

                      SizedBox(height: h * 0.02),
                    ],
                  ),
                ),
              ),
            );
          }),
          // ── 스와이프 제스처 ──
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final list = widget.stationList;
                if (list == null) return;
                if (details.primaryVelocity! < -300) {
                  final newIdx = _currentIdx < list.length - 1 ? _currentIdx + 1 : 0;
                  setState(() => _currentIdx = newIdx);
                  context.read<RadioProvider>().setQueue(list, newIdx);
                  context.read<RadioProvider>().playStation(list[newIdx]);
                } else if (details.primaryVelocity! > 300) {
                  final newIdx = _currentIdx > 0 ? _currentIdx - 1 : list.length - 1;
                  setState(() => _currentIdx = newIdx);
                  context.read<RadioProvider>().setQueue(list, newIdx);
                  context.read<RadioProvider>().playStation(list[newIdx]);
                }
              },
            ),
          ),

        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// 다이얼 위젯
// ══════════════════════════════════════════
class _DialWidget extends StatelessWidget {
  final String broadcaster;
  final Color bcColor;
  final String freq;
  final bool isPlaying;
  final AnimationController pulseCtrl;
  final AnimationController dialCtrl;
  final AnimationController rotCtrl;
  final Color primaryColor;

  const _DialWidget({
    required this.broadcaster,
    required this.bcColor,
    required this.freq,
    required this.isPlaying,
    required this.pulseCtrl,
    required this.dialCtrl,
    required this.rotCtrl,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _DialPainter(bcColor: bcColor, primaryColor: primaryColor),
        child: Center(
          child: AnimatedBuilder(
            animation: rotCtrl,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 회전하는 원 테두리
                  Transform.rotate(
                    angle: rotCtrl.value * 2 * 3.14159,
                    child: CustomPaint(
                      size: const Size(150, 150),
                      painter: _InnerDialPainter(
                        bcColor: bcColor,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                  // 고정 텍스트 (역방향 회전으로 상쇄)
                  child!,
                ],
              );
            },
            child: Container(
              width: 150,
              height: 150,
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 브랜드명
                  Text(
                    broadcaster,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: broadcaster.length > 4 ? 18 : 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 재생 상태 점
                  AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (context, _) {
                      return Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? Color.lerp(primaryColor, primaryColor.withOpacity(0.3), pulseCtrl.value)!
                              : Colors.grey.shade800,
                          boxShadow: isPlaying
                              ? [BoxShadow(
                            color: primaryColor.withOpacity(0.5 * (1 - pulseCtrl.value)),
                            blurRadius: 8, spreadRadius: 2,
                          )]
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 다이얼 배경 CustomPainter (눈금 + 외곽 링 + 황금 포인터)
// 안쪽 원 회전 Painter (눈금 + 그라디언트 링)
class _InnerDialPainter extends CustomPainter {
  final Color bcColor;
  final Color primaryColor;
  const _InnerDialPainter({required this.bcColor, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // 배경 원 (그라디언트)
    final bgRect = Rect.fromCircle(center: center, radius: r);
    final bgGrad = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 1.0,
      colors: [
        Color.lerp(bcColor, Color.lerp(primaryColor, const Color(0xFF2a2a2a), 0.6)!, 0.5)!,
        Color.lerp(primaryColor, const Color(0xFF1a1a1a), 0.78)!,
        Color.lerp(primaryColor, const Color(0xFF0d0d0d), 0.85)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(center, r, Paint()..shader = bgGrad.createShader(bgRect));

    // 안쪽 원 그림자
    final shadowD = Paint()
      ..color = Color.lerp(primaryColor, const Color(0xFF050505), 0.85)!
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(4, 4), r, shadowD);
    final shadowL = Paint()
      ..color = Color.lerp(primaryColor, const Color(0xFF252525), 0.65)!
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center - const Offset(4, 4), r, shadowL);
    canvas.drawCircle(center, r, Paint()..shader = bgGrad.createShader(bgRect));

    // 테두리
    canvas.drawCircle(center, r - 1,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // 작은 장식 눈금 (안쪽 원 테두리)
    const tickCount = 16;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * 3.14159;
      final isMajor = i % 4 == 0;
      final tickLen = isMajor ? 7.0 : 4.0;
      final brightness = (cos(angle) * 0.5 + 0.5);
      final tickColor = Color.lerp(
        Color.lerp(primaryColor, const Color(0xFF151515), 0.8)!,
        Color.lerp(primaryColor, const Color(0xFF353535), 0.45)!,
        brightness,
      )!;
      final start = Offset(
        center.dx + (r - 2) * cos(angle),
        center.dy + (r - 2) * sin(angle),
      );
      final end = Offset(
        center.dx + (r - 2 - tickLen) * cos(angle),
        center.dy + (r - 2 - tickLen) * sin(angle),
      );
      canvas.drawLine(start, end,
          Paint()
            ..color = tickColor
            ..strokeWidth = isMajor ? 1.5 : 1.0
            ..strokeCap = StrokeCap.round);
    }

    // 브랜드 컬러 얇은 링 강조
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          bcColor.withOpacity(0.0),
          bcColor.withOpacity(0.4),
          bcColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bgRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, r - 3, ringPaint);
  }

  @override
  bool shouldRepaint(_InnerDialPainter old) => false;
}

class _DialPainter extends CustomPainter {
  final Color bcColor;
  final Color primaryColor;
  const _DialPainter({required this.bcColor, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR - 12;

    // ── 외곽 글로우 (브랜드 컬러)
    final glowPaint = Paint()
      ..color = bcColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, outerR - 2, glowPaint);

    // ── 어두운 그림자 (우하단)
    final shadowDark = Paint()
      ..color = Color.lerp(primaryColor, const Color(0xFF050505), 0.85)!
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center + const Offset(8, 8), outerR, shadowDark);

    // ── 밝은 그림자 (좌상단)
    final shadowLight = Paint()
      ..color = Color.lerp(primaryColor, const Color(0xFF252525), 0.65)!
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center - const Offset(8, 8), outerR, shadowLight);

    // ── 배경 원 (방사형 그라디언트로 입체감)
    final bgRect = Rect.fromCircle(center: center, radius: outerR);
    final bgGrad = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      radius: 1.0,
      colors: [
        Color.lerp(primaryColor, const Color(0xFF242424), 0.75)!,
        Color.lerp(primaryColor, const Color(0xFF161616), 0.82)!,
        Color.lerp(primaryColor, const Color(0xFF0e0e0e), 0.88)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(center, outerR,
        Paint()..shader = bgGrad.createShader(bgRect));

    // ── 테두리 링 (상단 밝고 하단 어두운 그라디언트)
    final rimRect = Rect.fromCircle(center: center, radius: outerR);
    final rimGrad = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: [
        Color.lerp(primaryColor, const Color(0xFF3a3a3a), 0.55)!,
        Color.lerp(primaryColor, const Color(0xFF1a1a1a), 0.78)!,
        Color.lerp(primaryColor, const Color(0xFF0a0a0a), 0.85)!,
        Color.lerp(primaryColor, const Color(0xFF1a1a1a), 0.78)!,
        Color.lerp(primaryColor, const Color(0xFF3a3a3a), 0.55)!,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    canvas.drawCircle(
      center, outerR,
      Paint()
        ..shader = rimGrad.createShader(rimRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── 눈금
    const tickCount = 24;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * pi - pi / 2;
      final isMajor = i % 6 == 0;
      final tickLen = isMajor ? 11.0 : 5.0;
      // 상단 쪽 눈금은 좀 더 밝게
      final brightness = (cos(angle + pi / 2) * 0.5 + 0.5);
      final tickColor = Color.lerp(
        Color.lerp(primaryColor, const Color(0xFF1a1a1a), 0.75)!,
        Color.lerp(primaryColor, const Color(0xFF444444), 0.4)!,
        brightness,
      )!;
      final start = Offset(
        center.dx + (outerR - 5) * cos(angle),
        center.dy + (outerR - 5) * sin(angle),
      );
      final end = Offset(
        center.dx + (outerR - 5 - tickLen) * cos(angle),
        center.dy + (outerR - 5 - tickLen) * sin(angle),
      );
      canvas.drawLine(start, end,
          Paint()
            ..color = tickColor
            ..strokeWidth = isMajor ? 2.0 : 1.0
            ..strokeCap = StrokeCap.round);
    }

    // 황금 포인터 (상단에서 살짝 오른쪽)
    const pointerAngle = -pi / 2 + 0.4; // 약 23도 오른쪽
    final pointerTip = Offset(
      center.dx + (outerR - 6) * cos(pointerAngle),
      center.dy + (outerR - 6) * sin(pointerAngle),
    );
    final pointerBase = Offset(
      center.dx + (innerR - 30) * cos(pointerAngle),
      center.dy + (innerR - 30) * sin(pointerAngle),
    );
    final pointerPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pointerBase, pointerTip, pointerPaint);

    // 포인터 글로우
    final pointerGlowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(pointerBase, pointerTip, pointerGlowPaint);

    // 포인터 끝 원
    canvas.drawCircle(pointerTip, 4,
        Paint()..color = primaryColor..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DialPainter old) => false;
}

// ══════════════════════════════════════════
// 편성표 카드
// ══════════════════════════════════════════
class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final Color primaryColor;
  final RadioProvider radioProvider;
  final String freq;

  static const _accent = Colors.white38;

  const _ProgramCard({
    required this.program,
    required this.primaryColor,
    required this.radioProvider,
    required this.freq,
  });

  static String getTimeStr(Map<String, dynamic> program, RadioProvider radioProvider) {
    final kbsStart = program['program_planned_start_time'] as String? ?? '';
    final kbsEnd = program['program_planned_end_time'] as String? ?? '';
    final mbcStart = (program['StartTime'] ?? '').toString();
    final mbcEnd = (program['EndTime'] ?? '').toString();
    final sbsStart = program['start_time'] as String? ?? '';
    final sbsEnd = program['end_time'] as String? ?? '';

    if (kbsStart.isNotEmpty && kbsEnd.isNotEmpty) {
      return '${radioProvider.formatScheduleTime(kbsStart)} ~ ${radioProvider.formatScheduleTime(kbsEnd)}';
    } else if (mbcStart.isNotEmpty && mbcEnd.isNotEmpty) {
      String fmt(String t) {
        if (t.contains(':')) {
          final parts = t.split(':');
          int h = int.tryParse(parts[0]) ?? 0;
          if (h >= 24) h -= 24;
          return '${h.toString().padLeft(2, '0')}:${parts[1]}';
        }
        if (t.length < 4) return t;
        int h = int.tryParse(t.substring(0, 2)) ?? 0;
        if (h >= 24) h -= 24;
        return '${h.toString().padLeft(2, '0')}:${t.substring(2, 4)}';
      }
      return '${fmt(mbcStart)} ~ ${fmt(mbcEnd)}';
    } else if (sbsStart.isNotEmpty && sbsEnd.isNotEmpty) {
      return '$sbsStart ~ $sbsEnd';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final title = program['program_title'] as String? ??
        program['Title'] as String? ??
        program['title'] as String? ?? '';

    return Column(
      children: [
        // 타이틀 + LIVE
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title.isNotEmpty ? title : '',
                style: TextStyle(
                  color: baseColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Builder(builder: (ctx) {
              final isRerun = program['is_rerun'] as bool? ?? false;
              final badgeColor = isRerun ? baseColor.withOpacity(0.6) : const Color(0xFFE8877E);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isRerun) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isRerun ? AppLocalizations.of(context)!.radioRerun : AppLocalizations.of(context)!.radioLive,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════
// 다음 방송 한 줄 표시
// ══════════════════════════════════════════
class _NextProgramLine extends StatefulWidget {
  final List<Map<String, dynamic>> scheduleList;
  final Map<String, dynamic> currentProgram;
  final RadioProvider radioProvider;

  const _NextProgramLine({
    required this.scheduleList,
    required this.currentProgram,
    required this.radioProvider,
  });

  @override
  State<_NextProgramLine> createState() => _NextProgramLineState();
}

class _NextProgramLineState extends State<_NextProgramLine> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _titleOf(Map<String, dynamic> p) {
    return p['program_title'] as String? ??
        p['Title'] as String? ??
        p['title'] as String? ??
        '';
  }

  String _startOf(Map<String, dynamic> p) {
    final a = p['program_planned_start_time'] as String? ?? '';
    if (a.isNotEmpty) return a;
    final b = p['StartTime']?.toString() ?? '';
    if (b.isNotEmpty) return b;
    return p['start_time'] as String? ?? '';
  }

  String _formatStart(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains(':')) return raw;
    if (raw.length >= 8) {
      // KBS 형식
      return widget.radioProvider.formatScheduleTime(raw);
    }
    if (raw.length == 4) {
      int h = int.tryParse(raw.substring(0, 2)) ?? 0;
      if (h >= 24) h -= 24;
      return '${h.toString().padLeft(2, '0')}:${raw.substring(2, 4)}';
    }
    return raw;
  }

  String _countdownStr(String startHHmm) {
    if (!startHHmm.contains(':')) return '';
    final isPM = startHHmm.contains('오후');
    final isAM = startHHmm.contains('오전');
    final cleaned = startHHmm.replaceAll('오전', '').replaceAll('오후', '').trim();
    final parts = cleaned.split(':');
    int h = int.tryParse(parts[0].trim()) ?? 0;
    final m = int.tryParse(parts[1].trim()) ?? 0;
    if (isPM && h != 12) h += 12;
    if (isAM && h == 12) h = 0;
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, h, m);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    final diff = target.difference(now);
    if (diff.isNegative) return '';
    final hh = diff.inHours.toString().padLeft(2, '0');
    final mm = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _titleOf(widget.currentProgram);
    final currentStart = _startOf(widget.currentProgram);
    int idx = widget.scheduleList.indexWhere(
          (p) => _titleOf(p) == currentTitle && _startOf(p) == currentStart,
    );
    if (idx < 0) {
      idx = widget.scheduleList.indexWhere((p) => _titleOf(p) == currentTitle);
    }
    if (idx < 0 || idx + 1 >= widget.scheduleList.length) return const SizedBox.shrink();
    final next = widget.scheduleList[idx + 1];
    final nextTitle = _titleOf(next);
    if (nextTitle.isEmpty) return const SizedBox.shrink();
    final nextStart = _formatStart(_startOf(next));
    final nextImage = next['image'] as String?;
    final countdown = _countdownStr(nextStart);

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: (nextImage != null && nextImage.isNotEmpty)
                ? Image.network(
              nextImage,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (errCtx, err, stack) => Container(
                width: 76,
                height: 76,
                color: baseColor.withOpacity(0.08),
                child: Icon(Icons.radio, color: baseColor.withOpacity(0.38), size: 28),
              ),
            )
                : Container(
              width: 76,
              height: 76,
              color: baseColor.withOpacity(0.08),
              child: Icon(Icons.radio, color: baseColor.withOpacity(0.38), size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextStart.isNotEmpty
                      ? '${AppLocalizations.of(context)!.radioNextProgram}  $nextStart'
                      : AppLocalizations.of(context)!.radioNextProgram,
                  style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  nextTitle,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (countdown.isNotEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, color: baseColor.withOpacity(0.24), size: 16),
                const SizedBox(height: 3),
                Text(
                  countdown,
                  style: TextStyle(
                    color: baseColor.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            )
          else
            Icon(Icons.schedule, color: baseColor.withOpacity(0.24), size: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// 상태 뱃지
// ══════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final RadioPlayerState state;
  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final mutedColor = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.6);
    String label;
    Color color;
    switch (state) {
      case RadioPlayerState.playing:
        return const SizedBox.shrink(); // 편성표 카드 안에 LIVE 표시
      case RadioPlayerState.loading:
        label = AppLocalizations.of(context)!.radioStatusConnecting;
        color = mutedColor;
        break;
      case RadioPlayerState.error:
        label = AppLocalizations.of(context)!.radioStatusFailed;
        color = Colors.redAccent;
        break;
      case RadioPlayerState.paused:
        label = AppLocalizations.of(context)!.radioStatusPaused;
        color = mutedColor;
        break;
      default:
        return const SizedBox(height: 28);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }
}

// ══════════════════════════════════════════
// 컨트롤
// ══════════════════════════════════════════
class _Controls extends StatelessWidget {
  final bool isLoading;
  final bool isError;
  final bool isPlaying;
  final Color primaryColor;
  final int currentIdx;
  final List<RadioStation>? stationList;
  final RadioProvider radioProvider;
  final RadioStation current;
  final ValueChanged<int> onIndexChanged;

  const _Controls({
    required this.isLoading,
    required this.isError,
    required this.isPlaying,
    required this.primaryColor,
    required this.currentIdx,
    required this.stationList,
    required this.radioProvider,
    required this.current,
    required this.onIndexChanged,
  });

  static const _accent = Color(0xB3FFFFFF); // Colors.white70과 동일

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이전
        GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            final list = stationList;
            if (list != null) {
              final newIdx = currentIdx > 0 ? currentIdx - 1 : list.length - 1;
              onIndexChanged(newIdx);
              radioProvider.setQueue(list, newIdx);
              radioProvider.playStation(list[newIdx]);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.skip_previous, color: context.watch<ThemeProvider>().isDarkMode ? const Color(0xFFC7C7C7) : Colors.black54, size: 24),
          ),
        ),
        const SizedBox(width: 30),
        // 재생/정지
        GestureDetector(
          onTap: isLoading
              ? null
              : () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            if (isError) {
              radioProvider.playStation(current);
            } else {
              final cast = CastService.instance;
              if (cast.isConnected) {
                cast.tvPlaying ? cast.pause() : cast.play(); // TV로 듣는 중이면 TV를 멈추고/재생
              } else {
                radioProvider.togglePlayPause();
              }
            }
          },
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
            child: isLoading
                ? const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
            )
                : Icon(
              isError ? Icons.refresh : (isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.black,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 30),
        // 다음
        GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            final list = stationList;
            if (list != null) {
              final newIdx = currentIdx < list.length - 1 ? currentIdx + 1 : 0;
              onIndexChanged(newIdx);
              radioProvider.setQueue(list, newIdx);
              radioProvider.playStation(list[newIdx]);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.skip_next, color: context.watch<ThemeProvider>().isDarkMode ? const Color(0xFFC7C7C7) : Colors.black54, size: 24),
          ),
        ),
      ],
    );
  }
}

// 뉴모피즘 버튼
// ── 플로팅 버튼 ──
class _FloatButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _FloatButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withOpacity(0.07),
          border: Border.all(color: baseColor.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── 하단 바 아이템 ──
class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasIndicator; // 켜져 있으면 진하게 (예: 수면 타이머)
  final Color primaryColor;
  final VoidCallback onTap;
  final int badge; // 작은 숫자 (예: 예약 2개)

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.hasIndicator,
    required this.primaryColor,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final strong = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final muted = isDark ? const Color(0xFFA29A8B) : const Color(0xFF5A5348);
    final on = hasIndicator;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: on ? strong : muted, size: 22),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                      color: on ? strong : muted,
                      fontSize: 10.5,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    )),
              ],
            ),
            if (badge > 0)
              Positioned(
                right: -7,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 15),
                  height: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: strong, borderRadius: BorderRadius.circular(8)),
                  child: Text('$badge',
                      style: TextStyle(
                          color: isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 하단바 위: 지금 프로그램 한 줄 (● 이름 · N분 남음 + 얇은 진행 막대)
class _NowProgramStrip extends StatefulWidget {
  const _NowProgramStrip();

  @override
  State<_NowProgramStrip> createState() => _NowProgramStripState();
}

class _NowProgramStripState extends State<_NowProgramStrip> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // 남은 시간이 맞게 30초마다 다시 그리기
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final strong = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final muted = isDark ? const Color(0xFFA29A8B) : const Color(0xFF5A5348);
    final line = isDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);

    final now = DateTime.now();
    final nowM = _ScheduleListSheet._wrap(now.hour * 60 + now.minute);
    String? title;
    int? start, end;
    for (final s in radioProvider.scheduleList) {
      final t = (s['program_title'] ?? s['Title'] ?? s['title'] ?? '').toString();
      final a = _ScheduleListSheet._mins((s['program_planned_start_time'] ?? s['StartTime'] ?? s['start_time'] ?? '').toString());
      if (t.isEmpty || a == null) continue;
      final b = _ScheduleListSheet._mins((s['program_planned_end_time'] ?? s['EndTime'] ?? s['end_time'] ?? '').toString()) ?? a + 60;
      final ws = _ScheduleListSheet._wrap(a);
      var we = _ScheduleListSheet._wrap(b);
      if (we <= ws) we += 1440;
      if (ws <= nowM && nowM < we) {
        title = t;
        start = ws;
        end = we;
        break;
      }
    }
    if (title == null || start == null || end == null) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFFFF6B5E), shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: strong, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('${end - nowM}분 남음', style: TextStyle(color: muted, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: ((nowM - start) / (end - start)).clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: line,
              color: strong,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeuButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;
  const _NeuButton({required this.size, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ══════════════════════════════════════════
// 수면 타이머 뱃지
// ══════════════════════════════════════════
// ══════════════════════════════════════════
// 즐겨찾기 바텀시트
// ══════════════════════════════════════════
class _FavoritesSheet extends StatelessWidget {
  final Color primaryColor;
  _FavoritesSheet({required this.primaryColor});

  
  /// 방송국 로고 (없으면 이름 앞 글자)
  Widget _logo(RadioStation s, {required bool onDark}) {
    final short = (s.broadcaster ?? s.name).replaceAll(' ', '');
    final label = short.length > 4 ? short.substring(0, 4) : short;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: onDark ? Colors.white : _rBg, borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (s.logoUrl != null && s.logoUrl!.isNotEmpty)
          ? Image.network(s.logoUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(label,
                  style: TextStyle(color: _rInk, fontSize: 10.5, fontWeight: FontWeight.w800)))
          : Text(label, style: TextStyle(color: _rInk, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _rdDark = context.watch<ThemeProvider>().isDarkMode; // 다크 모드 맞추기
    final radioProvider = context.watch<RadioProvider>();
    final favorites = radioProvider.favorites;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final curId = radioProvider.currentStation?.stationUuid;
    final current = favorites.where((s) => s.stationUuid == curId).toList();
    final others = favorites.where((s) => s.stationUuid != curId).toList();

    void vib() => MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

    return Container(
      decoration: BoxDecoration(
        color: _rBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: _rLine, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          SizedBox(height: 14),
          // 위: 제목 · 개수
          Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(AppLocalizations.of(context)!.favorites,
                      style: TextStyle(color: _rInk, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ),
                Text('${favorites.length}개', style: TextStyle(color: _rSub, fontSize: 12.5)),
              ],
            ),
          ),
          if (favorites.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.heart, size: 40, color: _rSub.withOpacity(0.5)),
                    SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.radioNoFavorites,
                        style: TextStyle(color: _rInk, fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(AppLocalizations.of(context)!.radioNoFavoritesDesc,
                        textAlign: TextAlign.center, style: TextStyle(color: _rSub, fontSize: 12.5)),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 지금 듣는 방송 (먹색 카드)
                    for (final s in current)
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _rInk, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            _logo(s, onDark: true),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                            width: 6,
                                            height: 6,
                                            decoration:
                                                BoxDecoration(color: Color(0xFFFF6B5E), shape: BoxShape.circle)),
                                        SizedBox(width: 5),
                                        Text('듣는 중',
                                            style: TextStyle(color: _rBg, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: _rBg, fontSize: 15, fontWeight: FontWeight.w700)),
                                  if ((radioProvider.nowPlayingFor(s.name) ?? '').isNotEmpty)
                                    Text(radioProvider.nowPlayingFor(s.name)!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: _rBg.withOpacity(0.65), fontSize: 11.5)),
                                ],
                              ),
                            ),
                            Icon(Icons.graphic_eq_rounded, color: Color(0xFF7FB8F0), size: 22),
                          ],
                        ),
                      ),
                    if (others.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
                        child: Text('눌러서 바로 듣기',
                            style: TextStyle(color: _rSub, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        decoration: BoxDecoration(color: _rCard, borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (var i = 0; i < others.length; i++) ...[
                              if (i > 0) Container(height: 0.5, margin: EdgeInsets.only(left: 68), color: _rLine),
                              // 왼쪽으로 밀면 즐겨찾기에서 빼기
                              Dismissible(
                                key: ValueKey('fav_${others[i].stationUuid}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Color(0xFFE05A4F),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  child: Icon(Icons.delete_outline_rounded, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  final st = others[i];
                                  showActionFeedback(context, type: ActionFeedbackType.deleted, message: '즐겨찾기에서 뺐어요');
                                  Future.microtask(() => radioProvider.toggleFavorite(st));
                                },
                                child: InkWell(
                                  onTap: () {
                                    vib();
                                    Navigator.pop(context);
                                    radioProvider.playStation(others[i]);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                                    child: Row(
                                      children: [
                                        _logo(others[i], onDark: false),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(others[i].name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: _rInk, fontSize: 14, fontWeight: FontWeight.w600)),
                                              if ((radioProvider.nowPlayingFor(others[i].name) ?? '').isNotEmpty)
                                                Text(radioProvider.nowPlayingFor(others[i].name)!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: _rSub, fontSize: 11.5)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(color: _rBg, shape: BoxShape.circle),
                                          child: Icon(Icons.play_arrow_rounded, color: _rInk, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text('왼쪽으로 밀면 즐겨찾기에서 빼요', style: TextStyle(color: _rSub, fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SleepTimerBadge extends StatelessWidget {
  final Duration remaining;
  const _SleepTimerBadge({required this.remaining});

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.fixedAccent;
    final l = AppLocalizations.of(context)!;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final timeText = h > 0
        ? l.sleepCountdownHMS(h, m, s)
        : m > 0
        ? l.sleepCountdownMS(m, s)
        : l.sleepCountdownS(s);

    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => context.read<RadioProvider>().cancelSleepTimer(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bedtime_outlined, color: baseColor.withOpacity(0.5), size: 13),
          const SizedBox(width: 6),
          Text(timeText, style: TextStyle(color: baseColor.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Text(AppLocalizations.of(context)!.radioAfterEnd, style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 11)),
          const SizedBox(width: 6),
          Icon(Icons.close, color: baseColor.withOpacity(0.35), size: 12),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// 편성표 시트 (기존 유지)
// ══════════════════════════════════════════
class _ScheduleListSheet extends StatelessWidget {
  final String stationName;
  _ScheduleListSheet({required this.stationName});

  
  /// 시간 글자 → 하루 중 몇 분 (14:00 → 840). 못 읽으면 null
  static int? _mins(String t) {
    t = t.trim();
    if (t.isEmpty) return null;
    int h, m;
    if (t.contains(':')) {
      final p = t.split(':');
      h = int.tryParse(p[0]) ?? -1;
      m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    } else {
      final d = t.replaceAll(RegExp(r'[^0-9]'), '');
      if (d.length >= 12 && d.startsWith('20')) {
        // 20231015160000 처럼 날짜가 붙은 것
        h = int.tryParse(d.substring(8, 10)) ?? -1;
        m = int.tryParse(d.substring(10, 12)) ?? 0;
      } else if (d.length >= 4) {
        h = int.tryParse(d.substring(0, 2)) ?? -1;
        m = int.tryParse(d.substring(2, 4)) ?? 0;
      } else {
        return null;
      }
    }
    if (h < 0) return null;
    if (h >= 24) h -= 24;
    return h * 60 + m;
  }

  static String _hm(int mins) {
    final x = mins % 1440;
    return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
  }

  /// 새벽(0~6시)은 하루의 맨 끝으로 (편성표 순서)
  static int _wrap(int mins) => mins < 360 ? mins + 1440 : mins;

  static String _part(int mins) {
    final h = (mins % 1440) ~/ 60;
    if (h < 6) return '새벽';
    if (h < 12) return '아침';
    if (h < 18) return '오후';
    return '저녁 · 밤';
  }

  @override
  Widget build(BuildContext context) {
    _rdDark = context.watch<ThemeProvider>().isDarkMode; // 다크 모드 맞추기
    final radioProvider = context.watch<RadioProvider>();
    final station = radioProvider.currentStation;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    // 편성표 정리: 제목 · 시작 · 끝
    final items = <({String title, int start, int end})>[];
    for (final s in radioProvider.scheduleList) {
      String title = (s['program_title'] ?? s['Title'] ?? s['title'] ?? '').toString();
      String st = (s['program_planned_start_time'] ?? s['StartTime'] ?? s['start_time'] ?? '').toString();
      String en = (s['program_planned_end_time'] ?? s['EndTime'] ?? s['end_time'] ?? '').toString();
      final a = _mins(st);
      if (title.isEmpty || a == null) continue;
      var b = _mins(en) ?? (a + 60);
      var ws = _wrap(a);
      var we = _wrap(b);
      if (we <= ws) we += 1440;
      items.add((title: title, start: ws, end: we));
    }
    items.sort((x, y) => x.start.compareTo(y.start));

    final now = DateTime.now();
    final nowM = _wrap(now.hour * 60 + now.minute);
    final current = items.where((e) => e.start <= nowM && nowM < e.end).toList();
    final cur = current.isEmpty ? null : current.first;
    final upcoming = items.where((e) => e.start > nowM).toList();
    final nextStart = upcoming.isEmpty ? null : upcoming.first.start;

    bool reserved(int mins) =>
        station != null &&
        radioProvider.schedules.any((s) =>
            s.time.hour == (mins % 1440) ~/ 60 &&
            s.time.minute == (mins % 1440) % 60 &&
            s.station.stationUuid == station.stationUuid);

    void reserve(int mins) {
      if (station == null || reserved(mins)) return;
      final before = radioProvider.schedules.length;
      radioProvider.addSchedule(TimeOfDay(hour: (mins % 1440) ~/ 60, minute: (mins % 1440) % 60), station);
      if (radioProvider.schedules.length > before) {
        showActionFeedback(context, type: ActionFeedbackType.saved, message: '예약했어요', icon: Icons.notifications_active_rounded);
      } else {
        showParanToast(context, '예약을 더 넣을 수 없어요. 예약 창에서 지난 예약을 지워주세요');
      }
    }

    // 목록: 시간대(아침·오후…)마다 작은 제목
    final rows = <Widget>[];
    String? lastPart;
    for (final e in items) {
      if (cur != null && e == cur) continue; // 지금 방송은 위 먹색 카드에
      final part = _part(e.start);
      if (part != lastPart) {
        rows.add(Padding(
          padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(part, style: TextStyle(color: _rSub, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ));
        lastPart = part;
      }
      final past = e.end <= nowM;
      final isNext = e.start == nextStart;
      final done = reserved(e.start);
      rows.add(Opacity(
        opacity: past ? 0.45 : 1,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 세로 줄 + 점 (타임라인)
              SizedBox(
                width: 16,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 1.5, color: _rLine),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: isNext ? _rInk : _rLine, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: Text(_hm(e.start),
                            style: TextStyle(
                                color: _rSub, fontSize: 12.5, fontFeatures: [FontFeature.tabularFigures()])),
                      ),
                      Expanded(
                        child: Text(e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _rInk, fontSize: 14, fontWeight: isNext ? FontWeight.w700 : FontWeight.w500)),
                      ),
                      if (isNext) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _rCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _rLine),
                          ),
                          child: Text('다음',
                              style: TextStyle(color: _rInk, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                      ],
                      // 🔔 이 시간에 예약 (지난 방송은 없음)
                      if (!past)
                        IconButton(
                          onPressed: () {
                            MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            reserve(e.start);
                          },
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            done ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                            color: done ? _rInk : _rSub,
                            size: 20,
                          ),
                        )
                      else
                        SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: _rBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: _rLine, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          SizedBox(height: 14),
          // 위: 방송국 + 오늘 날짜
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _rCard, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.radio_rounded, color: _rSub, size: 22),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.radioScheduleTitle(stationName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _rInk, fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('오늘 · ${now.month}월 ${now.day}일 ${['월', '화', '수', '목', '금', '토', '일'][now.weekday - 1]}요일',
                        style: TextStyle(color: _rSub, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(AppLocalizations.of(context)!.radioLoadingSchedule,
                    style: TextStyle(color: _rSub, fontSize: 13)),
              ),
            )
          else ...[
            // 지금 방송 중 (먹색 카드)
            if (cur != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(color: _rInk, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: Color(0xFFFF6B5E), shape: BoxShape.circle)),
                          SizedBox(width: 5),
                          Text('지금 방송 중',
                              style: TextStyle(color: _rBg, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(cur.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _rBg, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('${_hm(cur.start)} – ${_hm(cur.end)} · ${cur.end - nowM}분 남음',
                        style: TextStyle(color: _rBg.withOpacity(0.7), fontSize: 12)),
                    SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ((nowM - cur.start) / (cur.end - cur.start)).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        color: Color(0xFF7FB8F0),
                      ),
                    ),
                  ],
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 2),
                children: rows,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _FarewellTextPainter extends CustomPainter {
  final double opacity;
  final String smallText;
  _FarewellTextPainter({required this.opacity, required this.smallText});

  @override
  void paint(Canvas canvas, Size size) {
    final isMultiline = smallText.contains('\n');
    final smallPainter = TextPainter(
      text: TextSpan(
        text: smallText,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity * 0.85),
          fontSize: isMultiline ? 17 : 14,
          letterSpacing: isMultiline ? 0.2 : 5,
          fontWeight: FontWeight.w500,
          fontStyle: isMultiline ? FontStyle.normal : FontStyle.italic,
          height: 1.6,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    smallPainter.paint(canvas, Offset((size.width - smallPainter.width) / 2, 0));

    final bigPainter = TextPainter(
      text: TextSpan(
        text: 'Paransori',
        style: TextStyle(color: Colors.white.withOpacity(opacity), fontSize: 33, letterSpacing: 3, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bigPainter.paint(canvas, Offset((size.width - bigPainter.width) / 2, smallPainter.height + 12));
  }

  @override
  bool shouldRepaint(covariant _FarewellTextPainter oldDelegate) => oldDelegate.opacity != opacity;
}