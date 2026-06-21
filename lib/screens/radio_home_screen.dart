import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import 'radio_broadcaster_screen.dart';
import 'radio_search_screen.dart';
import 'radio_favorites_screen.dart';
import 'radio_korea_screen2.dart';
import 'radio_country_stations_screen.dart';
import '../l10n/app_localizations.dart';


class RadioHomeScreen extends StatelessWidget {
  const RadioHomeScreen({super.key});

  List<RadioCountry> get _sortedCountries {
    final deviceCountryCode = PlatformDispatcher.instance.locale.countryCode;
    final list = List<RadioCountry>.from(RadioCountry.supported);
    if (deviceCountryCode != null) {
      final myIndex = list.indexWhere((c) => c.code == deviceCountryCode);
      if (myIndex > 0) {
        final myCountry = list.removeAt(myIndex);
        list.insert(0, myCountry);
      }
    }
    return list;
  }

  void _onCountryTap(BuildContext context, RadioCountry country) {
    context.read<RadioProvider>().selectCountry(country);
    if (country.code == 'KR') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RadioKoreaScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RadioCountryStationsScreen(country: country)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 22),
        ),
        title: Row(
          children: [
            Icon(Icons.radio_outlined, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.radioTitle, style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RadioSearchScreen())),
            icon: const Icon(Icons.search, color: AppTheme.textPrimary, size: 26),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RadioFavoritesScreen())),
            icon: Icon(Icons.favorite, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _RecentSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: _SectionHeader(title: AppLocalizations.of(context)!.radioSelectCountry),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.9,
                ),
                itemCount: _sortedCountries.length,
                itemBuilder: (context, index) {
                  final country = _sortedCountries[index];
                  return _CountryCard(country: country, onTap: () => _onCountryTap(context, country));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? const SafeArea(top: false, child: RadioMiniPlayer())
          : null,
    );
  }
}

class _CountryCard extends StatelessWidget {
  final RadioCountry country;
  final VoidCallback onTap;
  const _CountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.12), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(country.displayName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    country.code == 'KR'
                        ? '${koreanStations.length}${AppLocalizations.of(context)!.radioChannelCount}'
                        : AppLocalizations.of(context)!.radioPopular200,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final recent = radioProvider.recentlyListened;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (recent.isEmpty) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final station in recent.take(10)) {
        if (radioProvider.nowPlayingFor(station.name) == null) {
          final streamUrl = station.streamUrl;
          if (streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
            radioProvider.fetchScheduleByUrl(station.name, streamUrl);
          } else if (station.name == 'MBC 표준FM' || station.name == 'MBC FM4U') {
            radioProvider.fetchMbcSchedule(station.name);
          } else if (station.name == 'SBS 파워FM' || station.name == 'SBS 러브FM') {
            radioProvider.fetchSbsSchedule(station.name);
          } else if (station.name.contains('KBS')) {
            radioProvider.fetchSchedule(station.name);
          }
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: _SectionHeader(title: AppLocalizations.of(context)!.radioRecentListening),
        ),
        SizedBox(
          height: 105,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recent.length > 10 ? 10 : recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final station = recent[index];
              final time = station.lastListened;
              final timeStr = time != null
                  ? '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : '';

              return GestureDetector(
                onTap: () => context.read<RadioProvider>().playStation(station),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.radio, color: primaryColor, size: 13),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              station.name,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (ctx) {
                        final nowPlaying = radioProvider.nowPlayingFor(station.name);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nowPlaying != null && nowPlaying.isNotEmpty)
                              Text(
                                nowPlaying,
                                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── 섹션 헤더 (D안: 구분선 가운데 텍스트) ──
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16, height: 1,
          color: const Color(0xFF2a2a2a),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF1e1e1e),
          ),
        ),
      ],
    );
  }
}