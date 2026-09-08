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
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';

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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);

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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        systemOverlayStyle: isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios,
              color: baseColor, size: 22),
        ),
        title: Text(
          widget.broadcaster.name,
          style: TextStyle(
              color: baseColor,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: stations.isEmpty
          ? Center(
        child: _timedOut
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: baseColor.withOpacity(0.38), size: 48),
            const SizedBox(height: 16),
            Text(
              '채널을 찾을 수 없습니다',
              style: TextStyle(
                  color: baseColor.withOpacity(0.7),
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 방송사를 선택해 주세요',
              style: TextStyle(
                  color: baseColor.withOpacity(0.38), fontSize: 13),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 18),
            Text('채널 목록을 불러오는 중...',
                style: TextStyle(
                    color: baseColor.withOpacity(0.7),
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
              style: TextStyle(
                  color: baseColor.withOpacity(0.38), fontSize: 14),
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0);

    return Material(
      color: cardColor,
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
                  : baseColor.withOpacity(0.08),
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
                            : baseColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (station.bitrate != null && station.bitrate! > 0)
                      Text(
                        '${station.bitrate} kbps',
                        style: TextStyle(
                            color: baseColor.withOpacity(0.38), fontSize: 12),
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

    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return IconButton(
      icon: Icon(
        isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
        color: isFav ? primaryColor : baseColor.withOpacity(0.4),
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