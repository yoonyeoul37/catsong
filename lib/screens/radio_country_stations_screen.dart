import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_logo.dart';
import 'radio_player_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class RadioCountryStationsScreen extends StatefulWidget {
  final RadioCountry country;
  const RadioCountryStationsScreen({super.key, required this.country});

  @override
  State<RadioCountryStationsScreen> createState() =>
      _RadioCountryStationsScreenState();
}

enum _ViewMode { all, broadcaster, region, recent }

class _RadioCountryStationsScreenState
    extends State<RadioCountryStationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _ViewMode _mode = _ViewMode.all;

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

  Widget _toggleButton(String label, _ViewMode mode, Color baseColor, bool isDarkMode) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? (isDarkMode ? Colors.white : const Color(0xFF17140F)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (isDarkMode ? const Color(0xFF17140F) : Colors.white)
                  : baseColor.withOpacity(0.6),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBody(BuildContext context, RadioProvider radioProvider,
      List<RadioStation> allStations, Color baseColor, bool isDarkMode, Color primaryColor) {
    if (_mode == _ViewMode.broadcaster) {
      final Map<String, List<RadioStation>> grouped = {};
      for (final s in allStations) {
        final key = (s.broadcaster != null && s.broadcaster!.isNotEmpty) ? s.broadcaster! : '기타';
        grouped.putIfAbsent(key, () => []).add(s);
      }
      final keys = grouped.keys.toList()..sort((a, b) => a == '기타' ? 1 : (b == '기타' ? -1 : a.compareTo(b)));
      return _buildGroupGrid(context, keys, grouped, baseColor, isDarkMode);
    } else if (_mode == _ViewMode.region) {
      final Map<String, List<RadioStation>> grouped = {};
      for (final s in allStations) {
        if (s.state == null || s.state!.trim().isEmpty) continue;
        grouped.putIfAbsent(s.state!.trim(), () => []).add(s);
      }
      final keys = grouped.keys.toList()..sort();
      if (keys.isEmpty) {
        return Center(
          child: Text('지역 정보가 있는 방송국이 없어요',
              style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 14)),
        );
      }
      return _buildGroupGrid(context, keys, grouped, baseColor, isDarkMode);
    } else {
      final recent = radioProvider.recentlyListened
          .where((s) => s.countryCode == widget.country.code)
          .toList();
      if (recent.isEmpty) {
        return Center(
          child: Text('최근 들은 방송이 없어요',
              style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 14)),
        );
      }
      final current = radioProvider.currentStation;
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 80 + MediaQuery.of(context).padding.bottom),
        itemCount: recent.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: baseColor.withOpacity(0.16)),
        itemBuilder: (context, index) {
          final station = recent[index];
          final isPlaying = current?.stationUuid == station.stationUuid;
          return _StationTile(
            station: station,
            isPlaying: isPlaying,
            stationList: recent,
            stationIndex: index,
          );
        },
      );
    }
  }

  Widget _buildGroupGrid(BuildContext context, List<String> keys,
      Map<String, List<RadioStation>> grouped, Color baseColor, bool isDarkMode) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 80 + MediaQuery.of(context).padding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final list = grouped[key]!;
        return GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _GroupedStationListScreen(title: key, stations: list),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${list.length}개 채널',
                  style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Text(
                  key,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
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
      case 'PH': return 'Tunog ng mga Isla';
      case 'DE': return 'Klänge aus dem Herzen Europas';
      case 'FR': return 'Les mélodies de la vie';
      case 'TH': return 'เสียงแห่งสยาม';
      case 'ID': return 'Irama Nusantara';
      case 'IN': return 'भारत की धुन';
      case 'ES': return 'Ritmos del alma';
      case 'IT': return 'La musica della vita';
      case 'BR': return 'O som do Brasil';
      case 'CA': return 'Voices Across the North';
      case 'AU': return 'Sounds Down Under';
      case 'MX': return 'El ritmo de México';
      case 'TR': return 'Anadolu\'nun sesi';
      case 'NL': return 'Klanken van de Lage Landen';
      case 'SE': return 'Ljud från Norden';
      case 'PL': return 'Dźwięki Wisły';
      case 'AR': return 'El tango del alma';
      case 'CO': return 'Ritmos de Colombia';
      case 'NZ': return 'Echoes of Aotearoa';
      case 'MY': return 'Irama Malaysia';
      case 'SG': return 'The Lion City Vibes';
      case 'RU': return 'Звуки России';
      case 'ZA': return 'Sounds of the Rainbow Nation';
      case 'PK': return 'دھنیں پاکستان';
      case 'BD': return 'বাংলার সুর';
      case 'LK': return 'ලංකාවේ හඬ';
      case 'NP': return 'हिमालयको धुन';
      case 'MM': return 'မြန်မာ့အသံ';
      case 'KH': return 'សំឡេងអង្គរ';
      case 'AT': return 'Klänge der Alpen';
      case 'CH': return 'Stimmen der Schweiz';
      case 'BE': return 'Klanken van België';
      case 'PT': return 'Sons de Portugal';
      case 'GR': return 'Ήχοι της Ελλάδας';
      case 'IE': return 'Sounds of the Emerald Isle';
      case 'NO': return 'Lyder fra fjordene';
      case 'DK': return 'Lyde fra Danmark';
      case 'FI': return 'Suomen äänet';
      case 'CZ': return 'Zvuky Čech';
      case 'RO': return 'Sunetele României';
      case 'UA': return 'Звуки України';
      case 'EG': return 'أصوات النيل';
      case 'SA': return 'أصوات الجزيرة';
      case 'AE': return 'أصوات الخليج';
      case 'NG': return 'Sounds of Naija';
      case 'KE': return 'Sauti za Kenya';
      case 'CL': return 'Sonidos de Chile';
      case 'PE': return 'Sonidos del Perú';
      case 'VE': return 'Ritmos de Venezuela';
      case 'CU': return 'Ritmos de Cuba';
      case 'JM': return 'Riddims of Jamaica';
      case 'IQ': return 'أصوات بلاد الرافدين';
      case 'IR': return 'آوای ایران';
      case 'IL': return 'קולות ישראל';
      case 'MN': return 'Монгол нутгийн аялгуу';
      case 'UZ': return 'O\'zbekiston ovozlari';
      case 'KZ': return 'Қазақстан дыбыстары';
      case 'LA': return 'ສຽງແຫ່ງລາວ';
      case 'HU': return 'A Duna hangjai';
      case 'HR': return 'Zvuci Jadrana';
      case 'RS': return 'Звуци Србије';
      case 'BG': return 'Звуците на България';
      case 'SK': return 'Zvuky Slovenska';
      case 'LT': return 'Lietuvos garsai';
      case 'LV': return 'Latvijas skaņas';
      case 'EE': return 'Eesti helid';
      case 'IS': return 'Hljóð Íslands';
      case 'GH': return 'Sounds of Ghana';
      case 'TZ': return 'Sauti za Tanzania';
      case 'MA': return 'أصوات المغرب';
      case 'TN': return 'أصوات تونس';
      case 'ET': return 'የኢትዮጵያ ድምፅ';
      case 'UG': return 'Amaloboozi ga Uganda';
      case 'EC': return 'Sonidos del Ecuador';
      case 'BO': return 'Sonidos de Bolivia';
      case 'PY': return 'Sonidos del Paraguay';
      case 'UY': return 'Sonidos del Uruguay';
      case 'PA': return 'Sonidos de Panamá';
      case 'CR': return 'Sonidos de Costa Rica';
      case 'DO': return 'Ritmos Dominicanos';
      case 'TT': return 'Sounds of Trinidad';
      case 'HT': return 'Sons d\'Haïti';
      case 'FJ': return 'Sounds of the Pacific';
      case 'PG': return 'Voices of Papua';
      case 'JO': return 'أصوات الأردن';
      case 'LB': return 'أصوات لبنان';
      case 'GE': return 'საქართველოს ხმა';
      case 'AM': return 'Հայաստանի ձայն';
      case 'AZ': return 'Azərbaycan səsləri';
      case 'SI': return 'Zvoki Slovenije';
      case 'AL': return 'Tingujt e Shqipërisë';
      case 'MK': return 'Звуци на Македонија';
      case 'ME': return 'Zvuci Crne Gore';
      case 'BA': return 'Zvuci Bosne';
      case 'MT': return 'Sounds of Malta';
      case 'LU': return 'Kleng vum Grand-Duché';
      case 'CY': return 'Ήχοι της Κύπρου';
      case 'CM': return 'Sons du Cameroun';
      case 'SN': return 'Sons du Sénégal';
      case 'ZW': return 'Sounds of Zimbabwe';
      case 'MZ': return 'Sons de Moçambique';
      case 'MG': return 'Sons de Madagascar';
      case 'GT': return 'Sonidos de Guatemala';
      case 'HN': return 'Sonidos de Honduras';
      case 'NI': return 'Sonidos de Nicaragua';
      case 'SV': return 'Sonidos de El Salvador';
      case 'PR': return 'Sonidos de Puerto Rico';
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
      extendBody: false,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
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
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios,
              color: baseColor, size: 20),
        ),
        title: Builder(builder: (ctx) {
          final isKorean = Localizations.localeOf(context).languageCode == 'ko';
          if (isKorean) {
            return Image.asset(
              'assets/home_logo.png',
              height: 44,
              width: 88,
              fit: BoxFit.fill,
            );
          }
          return Text(
            'Paransori',
            style: TextStyle(
              color: baseColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
            ),
          );
        }),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: baseColor.withOpacity(0.08)),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: baseColor, fontSize: 14.5),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      hintStyle: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 14.5),
                      prefixIcon: Icon(Icons.search, color: baseColor.withOpacity(0.4), size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.close, color: baseColor.withOpacity(0.4), size: 18),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _toggleButton('전체', _ViewMode.all, baseColor, isDarkMode),
                    _toggleButton('지역별', _ViewMode.region, baseColor, isDarkMode),
                    _toggleButton('최근청취', _ViewMode.recent, baseColor, isDarkMode),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _mode != _ViewMode.all
                  ? _buildModeBody(context, radioProvider, allStations, baseColor, isDarkMode, primaryColor)
                  : isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 18),
                    Text(AppLocalizations.of(context)!.radioLoadingPopular,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.4), fontSize: 14)),
                  ],
                ),
              )
                  : stations.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        color: baseColor.withOpacity(0.25), size: 44),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.radioNoStationsFound,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.4),
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
                              color: baseColor.withOpacity(0.35), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding:
                      EdgeInsets.fromLTRB(24, 0, 24, 80 + MediaQuery.of(context).padding.bottom),
                      itemCount: stations.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: baseColor.withOpacity(0.16)),
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
      ),
      bottomNavigationBar: current != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
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
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return Container(
      color: isPlaying ? baseColor.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          context.read<RadioProvider>().setQueue(stationList, stationIndex);
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
        splashColor: baseColor.withOpacity(0.04),
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
                        color: baseColor,
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
                          color: baseColor.withOpacity(0.55), fontSize: 11.5),
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
                        ? Colors.redAccent
                        : baseColor.withOpacity(0.25),
                    size: 21,
                  ),
                  onPressed: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate').catchError((_) {});
                    final wasFav = context.read<RadioProvider>().isFavorite(station.stationUuid);
                    context.read<RadioProvider>().toggleFavorite(station);
                    final overlay = Overlay.of(context);
                    final entry = OverlayEntry(
                      builder: (_) => Positioned(
                        bottom: 500, left: 0, right: 0,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    wasFav ? CupertinoIcons.heart : CupertinoIcons.heart_fill,
                                    color: wasFav ? Colors.black38 : Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    wasFav
                                        ? AppLocalizations.of(context)!.radioRemovedFromFavorites
                                        : AppLocalizations.of(context)!.radioAddedToFavoritesToast,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    overlay.insert(entry);
                    Future.delayed(const Duration(seconds: 2), () => entry.remove());
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupedStationListScreen extends StatelessWidget {
  final String title;
  final List<RadioStation> stations;
  const _GroupedStationListScreen({required this.title, required this.stations});

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
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
        elevation: 0,
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
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
          itemCount: stations.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: baseColor.withOpacity(0.16)),
          itemBuilder: (context, i) {
            final station = stations[i];
            final isPlaying = current?.stationUuid == station.stationUuid;
            return _StationTile(
              station: station,
              isPlaying: isPlaying,
              stationList: stations,
              stationIndex: i,
            );
          },
        ),
      ),
      bottomNavigationBar: current != null
          ? Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          );
        }),
      ),
    );
  }
}