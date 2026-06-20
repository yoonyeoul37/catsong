import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_logo.dart';
import 'radio_player_screen.dart';
import 'radio_country_stations_screen.dart';

class RadioCountryStationsScreen extends StatefulWidget {
  final RadioCountry country;
  const RadioCountryStationsScreen({super.key, required this.country});

  @override
  State<RadioCountryStationsScreen> createState() =>
      _RadioCountryStationsScreenState();
}

class _RadioCountryStationsScreenState
    extends State<RadioCountryStationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioProvider>().fetchTopStations(widget.country.code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final stations = radioProvider.countryStations;
    final isLoading = radioProvider.isLoadingCountryStations;
    final current = radioProvider.currentStation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 22),
        ),
        title: Text(
          '${widget.country.flag} ${widget.country.displayName}',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 18),
            const Text('인기 방송을 불러오는 중...',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 15)),
          ],
        ),
      )
          : stations.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: AppTheme.textHint, size: 48),
            SizedBox(height: 16),
            Text('방송을 찾을 수 없습니다',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16)),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              '인기 방송 ${stations.length}개',
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding:
              EdgeInsets.fromLTRB(16, 0, 16, 80 + MediaQuery.of(context).viewPadding.bottom),
              itemCount: stations.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final station = stations[index];
                final isPlaying = current?.stationUuid ==
                    station.stationUuid;
                return _StationTile(
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

class _StationTile extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final List<RadioStation> stationList;
  final int stationIndex;

  const _StationTile({
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
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (station.bitrate != null &&
                            station.bitrate! > 0)
                          '${station.bitrate} kbps',
                        if (station.country != null &&
                            station.country!.isNotEmpty)
                          station.country!,
                      ].join('  ·  '),
                      style: const TextStyle(
                          color: AppTheme.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                _PlayingBars()
              else
                IconButton(
                  icon: Icon(
                    context
                        .watch<RadioProvider>()
                        .isFavorite(station.stationUuid)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: context
                        .watch<RadioProvider>()
                        .isFavorite(station.stationUuid)
                        ? primaryColor
                        : AppTheme.textHint,
                    size: 22,
                  ),
                  onPressed: () => context
                      .read<RadioProvider>()
                      .toggleFavorite(station),
                ),
            ],
          ),
        ),
      ),
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