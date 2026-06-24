import 'dart:ui' show PlatformDispatcher, ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    context.read<RadioProvider>().selectCountry(country);
    final screen = country.code == 'KR'
        ? RadioKoreaScreen()
        : RadioCountryStationsScreen(country: country);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final countries = _sortedCountries;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '\u201C',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.radioOnAirTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
              const TextSpan(
                text: ' \u201D',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RadioFavoritesScreen()));
            },
            icon: Icon(CupertinoIcons.heart, color: Colors.white60, size: 21),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const _RecentSection(),
            const SizedBox(height: 36),
            Text(
              AppLocalizations.of(context)!.radioSelectCountry,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            ...List.generate(countries.length, (index) {
              final country = countries[index];
              return Column(
                children: [
                  _CountryListTile(
                    country: country,
                    onTap: () => _onCountryTap(context, country),
                  ),
                  if (index != countries.length - 1)
                    Divider(height: 1, color: Colors.white.withOpacity(0.16), indent: 48),
                ],
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? const SafeArea(top: false, child: RadioMiniPlayer())
          : null,
    );
  }
}

class _CountryListTile extends StatelessWidget {
  final RadioCountry country;
  final VoidCallback onTap;
  const _CountryListTile({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.04),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    country.code == 'KR'
                        ? '${koreanStations.length}${AppLocalizations.of(context)!.radioChannelCount}'
                        : AppLocalizations.of(context)!.radioPopular200,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.25), size: 20),
          ],
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
        if (radioProvider.nowPlayingFor(station.name) == null &&
            !radioProvider.hasAttemptedSchedule(station.name)) {
          radioProvider.markScheduleAttempted(station.name);
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
        Text(
          AppLocalizations.of(context)!.radioRecentListening,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recent.length > 10 ? 10 : recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final station = recent[index];
              final time = station.lastListened;
              final timeStr = time != null
                  ? '${time.month}/${time.day}, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : '';

              return GestureDetector(
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  context.read<RadioProvider>().playStation(station);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.radio, color: Colors.white60, size: 13),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  station.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Builder(builder: (ctx) {
                            final nowPlaying = radioProvider.nowPlayingFor(station.name);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (nowPlaying != null && nowPlaying.isNotEmpty)
                                  Text(
                                    nowPlaying,
                                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (timeStr.isNotEmpty)
                                  Text(
                                    timeStr,
                                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}