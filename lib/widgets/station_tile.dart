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
    final primaryColor  = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final isPlaying     =
        radioProvider.currentStation?.stationUuid == station.stationUuid;
    final isFav         = radioProvider.isFavorite(station.stationUuid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isPlaying
            ? primaryColor.withOpacity(0.12)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.read<RadioProvider>().playStation(station);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadioPlayerScreen(station: station),
              ),
            );
          },
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPlaying
                    ? primaryColor
                    : primaryColor.withOpacity(0.08),
                width: isPlaying ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                StationLogo(
                    logoUrl: station.logoUrl,
                    name: station.name,
                    size: 46),
                const SizedBox(width: 12),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        [
                          if (station.country != null) station.country!,
                          if (station.bitrate != null)
                            '${station.bitrate} kbps',
                        ].join(' · '),
                        style: const TextStyle(
                            color: AppTheme.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? primaryColor : AppTheme.iconColor,
                    size: 20,
                  ),
                  onPressed: () =>
                      radioProvider.toggleFavorite(station),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}