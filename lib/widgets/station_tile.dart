import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import 'station_logo.dart';
import '../screens/radio_player_screen.dart';

class StationTile extends StatelessWidget {
  final RadioStation station;
  const StationTile({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.fixedAccent;
    final radioProvider = context.watch<RadioProvider>();
    final isPlaying =
        radioProvider.currentStation?.stationUuid == station.stationUuid;
    final isFav = radioProvider.isFavorite(station.stationUuid);

    return InkWell(
      onTap: () {
        context.read<RadioProvider>().playStation(station);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RadioPlayerScreen(station: station),
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
                      color: isPlaying ? accent : Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (station.country != null) station.country!,
                      if (station.bitrate != null && station.bitrate! > 0)
                        '${station.bitrate} kbps',
                    ].join(' · '),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.32), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (isPlaying)
              const Icon(Icons.graphic_eq, color: accent, size: 22)
            else
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? accent : Colors.white.withOpacity(0.25),
                  size: 21,
                ),
                onPressed: () =>
                    radioProvider.toggleFavorite(station),
              ),
          ],
        ),
      ),
    );
  }
}