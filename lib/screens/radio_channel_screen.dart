import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_logo.dart';
import 'radio_player_screen.dart';

class RadioChannelScreen extends StatefulWidget {
  final RadioBroadcaster broadcaster;
  final RadioCountry country;
  const RadioChannelScreen({
    super.key,
    required this.broadcaster,
    required this.country,
  });

  @override
  State<RadioChannelScreen> createState() => _RadioChannelScreenState();
}

class _RadioChannelScreenState extends State<RadioChannelScreen> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioProvider>().selectBroadcaster(widget.broadcaster);
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final stations = radioProvider.broadcasterStations;
    final current = radioProvider.currentStation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 22),
        ),
        title: Text(
          widget.broadcaster.name,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: stations.isEmpty
          ? Center(
        child: _timedOut
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: AppTheme.textHint, size: 48),
            SizedBox(height: 16),
            Text(
              '채널을 찾을 수 없습니다',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '다른 방송사를 선택해 주세요',
              style: TextStyle(
                  color: AppTheme.textHint, fontSize: 13),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 18),
            const Text('채널 목록을 불러오는 중...',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15)),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              '${stations.length}개 채널',
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 80 + MediaQuery.of(context).viewPadding.bottom),
              itemCount: stations.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final station = stations[index];
                final isPlaying =
                    current?.stationUuid == station.stationUuid;
                return _ChannelTile(
                  station: station,
                  isPlaying: isPlaying,
                  stationList: stations,
                  stationIndex: index,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: current != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final List<RadioStation> stationList;
  final int stationIndex;

  const _ChannelTile({
    required this.station,
    required this.isPlaying,
    required this.stationList,
    required this.stationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RadioPlayerScreen(
                station: station,
                stationList: stationList,
                currentIndex: stationIndex,
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isPlaying
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.13),
                primaryColor.withOpacity(0.03),
              ],
            )
                : null,
            border: Border.all(
              color: isPlaying
                  ? primaryColor.withOpacity(0.15)
                  : primaryColor.withOpacity(0.08),
              width: 1,
            ),
          ),
          foregroundDecoration: isPlaying
              ? BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(
              top: BorderSide(
                color: primaryColor.withOpacity(0.8),
                width: 1.5,
              ),
            ),
          )
              : null,
          child: Row(
            children: [
              StationLogo(
                  logoUrl: station.logoUrl,
                  name: station.name,
                  size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        color: isPlaying
                            ? primaryColor
                            : AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (station.bitrate != null && station.bitrate! > 0)
                      Text(
                        '${station.bitrate} kbps',
                        style: const TextStyle(
                            color: AppTheme.textHint, fontSize: 12),
                      ),
                    Builder(
                      builder: (context) {
                        final nowPlaying = context
                            .watch<RadioProvider>()
                            .nowPlayingFor(station.name);
                        if (nowPlaying == null || nowPlaying.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '지금: $nowPlaying',
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                _PlayingBars()
              else
                _FavoriteBtn(station: station),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteBtn extends StatelessWidget {
  final RadioStation station;
  const _FavoriteBtn({required this.station});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isFav = context
        .watch<RadioProvider>()
        .isFavorite(station.stationUuid);

    return IconButton(
      icon: Icon(
        isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
        color: isFav ? primaryColor : AppTheme.iconColor,
        size: 22,
      ),
      onPressed: () =>
          context.read<RadioProvider>().toggleFavorite(station),
    );
  }
}

class _PlayingBars extends StatefulWidget {
  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 380 + i * 130),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 22,
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, __) => Container(
              width: 4,
              height: 6 + _ctrls[i].value * 14,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}