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
import '../l10n/app_localizations.dart';

class RadioCountryStationsScreen extends StatefulWidget {
  final RadioCountry country;
  const RadioCountryStationsScreen({super.key, required this.country});

  @override
  State<RadioCountryStationsScreen> createState() =>
      _RadioCountryStationsScreenState();
}

class _RadioCountryStationsScreenState
    extends State<RadioCountryStationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioProvider>().fetchTopStations(widget.country.code);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sloganFor(BuildContext context, String countryCode) {
    switch (countryCode) {
      case 'US': return 'The Voice of Freedom';
      case 'JP': return '日常に寄り添う小さな癒し';
      case 'TW': return '流淌在島嶼的歌';
      case 'CN': return '遼闊大地之聲';
      case 'HK': return '乘上城市的節奏';
      case 'GB': return 'Where Tradition Meets the Present';
      case 'VN': return 'Giai điệu sông Mekong';
      default: return widget.country.displayName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final allStations = radioProvider.countryStations;
    final stations = _query.isEmpty
        ? allStations
        : allStations
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final isLoading = radioProvider.isLoadingCountryStations;
    final current = radioProvider.currentStation;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '\u201C',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: _sloganFor(context, widget.country.code),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                ),
              ),
              const TextSpan(
                text: ' \u201D',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14.5),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withOpacity(0.4), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 18),
                  Text(AppLocalizations.of(context)!.radioLoadingPopular,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 14)),
                ],
              ),
            )
                : stations.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      color: Colors.white.withOpacity(0.25), size: 44),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.radioNoStationsFound,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 15)),
                ],
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
                  child: Row(
                    children: [
                      Text(widget.country.flag, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.radioPopularCount(stations.length),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding:
                    EdgeInsets.fromLTRB(24, 0, 24, 80 + MediaQuery.of(context).viewPadding.bottom),
                    itemCount: stations.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.white.withOpacity(0.16)),
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(
              station: station,
              stationList: stationList,
              currentIndex: stationIndex,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },
      splashColor: Colors.white.withOpacity(0.04),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            StationLogo(
                logoUrl: station.logoUrl,
                name: station.name,
                size: 46),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: TextStyle(
                      color: isPlaying ? Colors.white : Colors.white60,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (station.bitrate != null &&
                          station.bitrate! > 0)
                        '${station.bitrate} kbps',
                      if (station.country != null &&
                          station.country!.isNotEmpty)
                        station.country!,
                    ].join('  ·  '),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.32), fontSize: 11.5),
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
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  color: context
                      .watch<RadioProvider>()
                      .isFavorite(station.stationUuid)
                      ? Colors.white
                      : Colors.white.withOpacity(0.25),
                  size: 21,
                ),
                onPressed: () => context
                    .read<RadioProvider>()
                    .toggleFavorite(station),
              ),
          ],
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
        duration: Duration(milliseconds: 1000 + i * 300),
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
              decoration: const BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          );
        }),
      ),
    );
  }
}