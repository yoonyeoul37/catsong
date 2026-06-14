import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/station_logo.dart';
import '../widgets/sleep_timer_sheet.dart';

class RadioPlayerScreen extends StatefulWidget {
  final RadioStation station;
  const RadioPlayerScreen({super.key, required this.station});

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioProvider>().playStation(widget.station);
    });
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
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
    final state = radioProvider.playerState;
    final current = radioProvider.currentStation ?? widget.station;
    final isPlaying = state == RadioPlayerState.playing;
    final isLoading = state == RadioPlayerState.loading;
    final isError = state == RadioPlayerState.error;
    final sleep = radioProvider.sleepRemaining;
    final broadcaster = _getBroadcaster(current.name);
    final bcColor = _brandColor(broadcaster);

    if (isPlaying) {
      _rotCtrl.repeat();
    } else {
      _rotCtrl.stop();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more,
              color: AppTheme.textPrimary, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'RADIO',
          style: TextStyle(
            color: AppTheme.textHint,
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.bedtime_outlined,
                    color: AppTheme.textPrimary, size: 24),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SleepTimerSheet(),
                ),
              ),
              if (radioProvider.isSleepTimerActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              radioProvider.isFavorite(current.stationUuid)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: radioProvider.isFavorite(current.stationUuid)
                  ? primaryColor
                  : AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: () {
              final wasFav =
              radioProvider.isFavorite(current.stationUuid);
              radioProvider.toggleFavorite(current);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    wasFav
                        ? '즐겨찾기에서 제거했습니다'
                        : '즐겨찾기에 추가했습니다',
                    style: const TextStyle(fontSize: 15),
                  ),
                  backgroundColor: AppTheme.surfaceVariant,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // 방송사 로고 (회전 디스크)
            RotationTransition(
              turns: _rotCtrl,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bcColor,
                  boxShadow: [
                    BoxShadow(
                      color: bcColor
                          .withOpacity(isPlaying ? 0.45 : 0.15),
                      blurRadius: 50,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: (current.logoUrl ?? '').isNotEmpty
                    ? ClipOval(
                  child: StationLogo(
                    logoUrl: current.logoUrl,
                    name: current.name,
                    size: 220,
                    fontSize: 42,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      broadcaster.isNotEmpty
                          ? broadcaster
                          : current.name
                          .substring(
                          0,
                          current.name.length > 4
                              ? 4
                              : current.name.length)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            // 채널 이름
            Text(
              current.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 방송사 + 국가 + 비트레이트
            Text(
              [
                if (broadcaster.isNotEmpty) broadcaster,
                if (current.country != null &&
                    current.country!.isNotEmpty)
                  current.country!,
                if (current.bitrate != null && current.bitrate! > 0)
                  '${current.bitrate} kbps',
              ].join('  ·  '),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const Spacer(flex: 1),

            // 상태 뱃지
            _StatusBadge(state: state),
            const SizedBox(height: 6),

            if (isError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  radioProvider.errorMessage ?? '재생에 실패했습니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13),
                ),
              ),

            const Spacer(flex: 2),

            // 재생 컨트롤
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 정지 버튼
                GestureDetector(
                  onTap: () {
                    radioProvider.stopRadio();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceVariant,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: const Icon(Icons.stop,
                        color: AppTheme.textSecondary, size: 26),
                  ),
                ),
                const SizedBox(width: 28),
                // 재생/일시정지 버튼
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () {
                    if (isError) {
                      radioProvider.playStation(current);
                    } else {
                      radioProvider.togglePlayPause();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                        : Icon(
                      isError
                          ? Icons.refresh
                          : (isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                // 즐겨찾기 버튼
                GestureDetector(
                  onTap: () {
                    radioProvider.toggleFavorite(current);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceVariant,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Icon(
                      radioProvider.isFavorite(current.stationUuid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                      radioProvider.isFavorite(current.stationUuid)
                          ? primaryColor
                          : AppTheme.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 1),

            if (sleep != null) _SleepTimerBadge(remaining: sleep),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RadioPlayerState state;
  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    String label;
    Color color;

    switch (state) {
      case RadioPlayerState.playing:
        label = '● LIVE';
        color = Colors.redAccent;
        break;
      case RadioPlayerState.loading:
        label = '접속 중...';
        color = primaryColor;
        break;
      case RadioPlayerState.error:
        label = '연결 실패';
        color = Colors.redAccent;
        break;
      case RadioPlayerState.paused:
        label = '일시정지';
        color = AppTheme.textHint;
        break;
      default:
        return const SizedBox(height: 28);
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8)),
    );
  }
}

class _SleepTimerBadge extends StatelessWidget {
  final Duration remaining;
  const _SleepTimerBadge({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final label = h > 0
        ? '${h}시간 ${m}분 후 종료'
        : m > 0
        ? '${m}분 ${s}초 후 종료'
        : '${s}초 후 종료';

    return GestureDetector(
      onTap: () => context.read<RadioProvider>().cancelSleepTimer(),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime, color: primaryColor, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style:
                TextStyle(color: primaryColor, fontSize: 13)),
            const SizedBox(width: 6),
            Icon(Icons.close, color: primaryColor, size: 13),
          ],
        ),
      ),
    );
  }
}