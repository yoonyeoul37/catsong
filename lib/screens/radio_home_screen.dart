import 'dart:ui' show PlatformDispatcher, ImageFilter;
import 'package:flutter/material.dart';
import '../utils/title_font.dart';
import '../utils/device_country.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../providers/theme_provider.dart';
import 'nature_sounds_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/logo_shine.dart';
import 'radio_broadcaster_screen.dart';
import 'radio_search_screen.dart';
import 'radio_favorites_screen.dart';
import 'radio_korea_screen2.dart';
import 'radio_country_stations_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../l10n/locale_holder.dart';


/// 라디오 진입 시 호출. 내 폰의 국가 설정에 맞는 방송국 목록이 있으면
/// 국가 선택 화면을 건너뛰고 바로 그 나라로 들어가고, 없으면 국가 선택 화면으로 간다.
Future<void> pushRadioEntry(BuildContext context, {bool instant = false}) {
  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
  final deviceCode = DeviceCountry.radioCountry(); // 앱 언어의 나라 (독일어 → 독일)
  RadioCountry? matched;
  if (deviceCode != null) {
    for (final c in RadioCountry.supported) {
      if (c.code == deviceCode) {
        matched = c;
        break;
      }
    }
  }

  Widget screen;
  if (matched != null) {
    context.read<RadioProvider>().selectCountry(matched);
    screen = matched.code == 'KR'
        ? const RadioKoreaScreen()
        : RadioCountryStationsScreen(country: matched);
  } else {
    screen = const RadioHomeScreen();
  }

  return Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: radioTextScaler(context),
        ),
        child: screen,
      ),
      transitionsBuilder: instant
          ? (context, animation, secondaryAnimation, child) => child
          : (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
      transitionDuration: instant ? Duration.zero : const Duration(milliseconds: 250),
      reverseTransitionDuration: instant ? Duration.zero : const Duration(milliseconds: 250),
    ),
  );
}

class RadioHomeScreen extends StatefulWidget {
  const RadioHomeScreen({super.key});

  @override
  State<RadioHomeScreen> createState() => _RadioHomeScreenState();
}

class _RadioHomeScreenState extends State<RadioHomeScreen> {
  // ── 나라 검색 ──
  final TextEditingController _search = TextEditingController();
  String _query = '';

  // ── 마이크로 나라 찾기 (음악 검색칸과 같은 방식) ──
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available || !mounted) return;
    // 앱 언어에 맞춰 알아듣기
    final lang = Localizations.localeOf(context).languageCode;
    final localeId = switch (lang) {
      'ko' => 'ko_KR',
      'ja' => 'ja_JP',
      'zh' => Localizations.localeOf(context).scriptCode == 'Hant' ? 'zh_TW' : 'zh_CN',
      _ => (Localizations.localeOf(context).countryCode ?? '').isNotEmpty
          ? '${lang}_${Localizations.localeOf(context).countryCode}'
          : lang, // 독일어 de_DE 등 (나라 없으면 언어만)
    };
    setState(() => _isListening = true);
    _speech.listen(
      localeId: localeId,
      onResult: (result) {
        // "일본." 처럼 끝에 붙는 문장부호는 빼기
        final words = result.recognizedWords.replaceAll(RegExp(r'[.,!?。、]'), '').trim();
        _search.text = words;
        _search.selection = TextSelection.fromPosition(TextPosition(offset: words.length));
        if (mounted) setState(() => _query = words);
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _search.dispose();
    super.dispose();
  }

  /// 검색: 한글 이름 · 영어 이름 · 나라 코드 (띄어쓰기·대소문자 무시)
  bool _matches(RadioCountry c, String q) {
    String n(String v) => v.toLowerCase().replaceAll(' ', '');
    final k = n(q);
    if (k.isEmpty) return true;
    return n(c.displayName).contains(k) ||
        n(c.name).contains(k) ||
        n(_countryEn[c.code] ?? '').contains(k) ||
        n(_countryKoAlias[c.code] ?? '').contains(k) ||
        c.code.toLowerCase() == k;
  }

  Widget _searchField(bool isDark) {
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final hint = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 20, color: hint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              style: TextStyle(color: ink, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: tr.searchCountry,
                hintStyle: TextStyle(color: hint, fontSize: 15),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _search.clear();
                setState(() => _query = '');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.cancel_rounded, size: 18, color: hint),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleListening,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 20,
                  color: _isListening ? Colors.redAccent : hint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 검색 결과: 대륙 구분 없이 맞는 나라만
  List<Widget> _searchResults(List<RadioCountry> countries, bool isDark) {
    final found = countries.where((c) => _matches(c, _query)).toList();
    final base = isDark ? Colors.white : Colors.black;
    if (found.isEmpty) {
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      return [
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: base.withOpacity(0.25)),
              const SizedBox(height: 12),
              Text(tr.noCountryFound,
                  style: TextStyle(color: base.withOpacity(0.45), fontSize: 14)),
            ],
          ),
        ),
      ];
    }
    return [
      for (int i = 0; i < found.length; i++)
        Column(
          children: [
            _CountryListTile(country: found[i], onTap: () => _onCountryTap(context, found[i])),
            if (i != found.length - 1)
              Divider(height: 1, thickness: 0.6, color: base.withOpacity(0.07), indent: 48),
          ],
        ),
    ];
  }

  List<RadioCountry> get _sortedCountries {
    final deviceCountryCode = DeviceCountry.radioCountry(usePick: false);
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

  List<Widget> _buildCountryListByContinent(BuildContext context, List<RadioCountry> countries, bool isDarkMode) {
    final deviceCountryCode = DeviceCountry.radioCountry(usePick: false);
    const continentOrder = ['ASIA', 'EUROPE', 'NORTH_AMERICA', 'SOUTH_AMERICA', 'MIDDLE_EAST', 'AFRICA', 'OCEANIA'];
    const continentLabels = {
      'ASIA': 'Asia',
      'EUROPE': 'Europe',
      'NORTH_AMERICA': 'North America',
      'SOUTH_AMERICA': 'South America',
      'MIDDLE_EAST': 'Middle East',
      'AFRICA': 'Africa',
      'OCEANIA': 'Oceania',
    };

    // 유저 대륙을 맨 위로
    String? userContinent;
    if (deviceCountryCode != null) {
      final userCountry = countries.firstWhere(
            (c) => c.code == deviceCountryCode,
        orElse: () => countries.first,
      );
      userContinent = userCountry.continent;
    }

    final sorted = List<String>.from(continentOrder);
    if (userContinent != null && sorted.contains(userContinent)) {
      sorted.remove(userContinent);
      sorted.insert(0, userContinent);
    }

    // 한국어 화면이면 대륙 이름도 한글로
    const continentLabelsKo = {
      'ASIA': '아시아',
      'EUROPE': '유럽',
      'NORTH_AMERICA': '북아메리카',
      'SOUTH_AMERICA': '남아메리카',
      'MIDDLE_EAST': '중동',
      'AFRICA': '아프리카',
      'OCEANIA': '오세아니아',
    };
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    final widgets = <Widget>[];

    // 맨 위: 내 나라 먹색 카드 (아래 목록에선 빼서 두 번 안 나오게)
    RadioCountry? myCountry;
    for (final c in countries) {
      if (c.code == deviceCountryCode) {
        myCountry = c;
        break;
      }
    }
    if (myCountry != null) {
      final mine = myCountry;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _MyCountryCard(country: mine, onTap: () => _onCountryTap(context, mine)),
      ));
    }

    for (final continent in sorted) {
      final group = countries.where((c) => c.continent == continent && c.code != myCountry?.code).toList();
      if (group.isEmpty) continue;

      // 유저 나라를 해당 대륙 맨 위로
      if (deviceCountryCode != null) {
        final idx = group.indexWhere((c) => c.code == deviceCountryCode);
        if (idx > 0) {
          final my = group.removeAt(idx);
          group.insert(0, my);
        }
      }

      // 대륙 헤더
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Row(
            children: [
              Text(
                ({
                  'ASIA': tr.continentAsia,
                  'EUROPE': tr.continentEurope,
                  'NORTH_AMERICA': tr.continentNorthAmerica,
                  'SOUTH_AMERICA': tr.continentSouthAmerica,
                  'MIDDLE_EAST': tr.continentMiddleEast,
                  'AFRICA': tr.continentAfrica,
                  'OCEANIA': tr.continentOceania,
                }[continent] ?? (isKo ? continentLabelsKo[continent] : continentLabels[continent])) ?? continent,
                style: TextStyle(
                  color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.45),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: tr.localeName == 'en' ? 1.2 : 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 0.5,
                  color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      );

      // 나라 목록
      for (int i = 0; i < group.length; i++) {
        final country = group[i];
        widgets.add(
          Column(
            children: [
              _CountryListTile(
                country: country,
                onTap: () => _onCountryTap(context, country),
              ),
              if (i != group.length - 1)
                Divider(height: 1, thickness: 0.6, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.07), indent: 48),
            ],
          ),
        );
      }
    }
    return widgets;
  }

  void _onCountryTap(BuildContext context, RadioCountry country) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    context.read<RadioProvider>().selectCountry(country);
    DeviceCountry.rememberPick(country.code); // 다음에 홈 → 라디오도 이 나라로
    final screen = country.code == 'KR'
        ? RadioKoreaScreen()
        : RadioCountryStationsScreen(country: country);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: radioTextScaler(context)), child: screen), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final countries = _sortedCountries;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      radioProvider.fetchAllCountryCounts();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF24221F),
          systemNavigationBarIconBrightness: Brightness.light,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFF7F5F0),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
          icon: Icon(Icons.arrow_back_ios, color: isDarkMode ? Colors.white : Colors.black, size: 20),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 + 제목(회색 빛) / 아래 설명 — 홈 로고와 같은 짜임 (해외는 그 나라 말)
            Flexible(child: MenuTitle(title: tr.catRadio, sub: tr.catRadioSub, isDark: isDarkMode)),
          ],
        ),
        actions: [
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 나라 검색칸
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: _searchField(isDarkMode),
            ),
            Expanded(
              child: Builder(builder: (context) {
                final items = <Widget>[
                  if (_query.isEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.radioSelectCountry,
                      style: TextStyle(
                        color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._buildCountryListByContinent(context, countries, isDarkMode),
                  ] else
                    ..._searchResults(countries, isDarkMode),
                  const SizedBox(height: 80),
                ];
                // 음악 곡 목록처럼: 내리고 올릴 때 화면에 들어오는 줄이 옆에서 스르륵
                return ListView.builder(
                  key: ValueKey(_query), // 검색어 바뀌면 처음부터 다시 스르륵
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _Appear(child: items[i]),
                );
              }),
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

/// 맨 위 "내 나라" 먹색 카드 (다크 모드는 크림색) — 설정 화면 맨 위 카드와 한 세트
class _MyCountryCard extends StatelessWidget {
  final RadioCountry country;
  final VoidCallback onTap;
  const _MyCountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final l = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    String count;
    if (country.code == 'KR') {
      count = '${koreanStations.length}${l.radioChannelCount}';
    } else {
      final n = context.watch<RadioProvider>().getCountryStationCount(country.code);
      count = n != null ? '$n${l.radioChannelCount}' : l.radioPopular200;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.currentCountry,
                        style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(country.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 1),
                    Text(count, style: TextStyle(color: fg.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryListTile extends StatelessWidget {
  final RadioCountry country;
  final VoidCallback onTap;
  const _CountryListTile({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      splashColor: baseColor.withOpacity(0.04),
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
                    style: TextStyle(
                      color: baseColor,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Builder(builder: (ctx) {
                    if (country.code == 'KR') {
                      return Text(
                        '${koreanStations.length}${AppLocalizations.of(context)!.radioChannelCount}',
                        style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 12.5),
                      );
                    }
                    final count = ctx.watch<RadioProvider>().getCountryStationCount(country.code);
                    return Text(
                      count != null
                          ? '$count${AppLocalizations.of(context)!.radioChannelCount}'
                          : AppLocalizations.of(context)!.radioPopular200,
                      style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 12.5),
                    );
                  }),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: baseColor.withOpacity(0.25), size: 20),
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

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
            color: baseColor.withOpacity(0.65),
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
                        color: baseColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: baseColor.withOpacity(0.10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.radio, color: baseColor.withOpacity(0.6), size: 13),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  station.name,
                                  style: TextStyle(color: baseColor, fontSize: 13, fontWeight: FontWeight.w600),
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
                                    style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (timeStr.isNotEmpty)
                                  Text(
                                    timeStr,
                                    style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 10.5),
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

/// 음악 곡 목록과 같은 등장: 옆에서 살짝 밀려 들어오며 커지고 선명해짐
class _Appear extends StatelessWidget {
  final Widget child;
  const _Appear({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) => Transform.translate(
        offset: Offset((1 - v) * 24, 0),
        child: Transform.scale(
          scale: 0.95 + 0.05 * v,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
      ),
    );
  }
}

/// 나라 다른 한글 이름 (목록엔 안 보이고 검색에서만: '타이완' 쳐도 대만이 나오게)
const Map<String, String> _countryKoAlias = {
  'TW': '타이완', 'US': '미합중국 아메리카', 'GB': '잉글랜드 브리튼 영국',
  'TR': '튀르키예 터키', 'NL': '네덜란드 홀랜드', 'MM': '미얀마 버마',
  'AE': '아랍에미리트 두바이', 'CZ': '체코 체코공화국', 'NZ': '뉴질랜드',
};

/// 나라 영어 이름 (한국어 화면에서도 영어로 찾을 수 있게)
const Map<String, String> _countryEn = {
  'KR': 'Korea South Korea', 'JP': 'Japan', 'TW': 'Taiwan', 'CN': 'China', 'HK': 'Hong Kong',
  'VN': 'Vietnam', 'PH': 'Philippines', 'TH': 'Thailand', 'ID': 'Indonesia', 'IN': 'India',
  'MY': 'Malaysia', 'SG': 'Singapore', 'PK': 'Pakistan', 'BD': 'Bangladesh', 'LK': 'Sri Lanka',
  'NP': 'Nepal', 'MM': 'Myanmar', 'KH': 'Cambodia', 'MN': 'Mongolia', 'UZ': 'Uzbekistan',
  'KZ': 'Kazakhstan', 'LA': 'Laos', 'GE': 'Georgia', 'AM': 'Armenia', 'AZ': 'Azerbaijan',
  'GB': 'United Kingdom UK England Britain', 'DE': 'Germany', 'FR': 'France', 'ES': 'Spain', 'IT': 'Italy',
  'NL': 'Netherlands Holland', 'SE': 'Sweden', 'PL': 'Poland', 'RU': 'Russia', 'AT': 'Austria',
  'CH': 'Switzerland', 'BE': 'Belgium', 'PT': 'Portugal', 'GR': 'Greece', 'IE': 'Ireland',
  'NO': 'Norway', 'DK': 'Denmark', 'FI': 'Finland', 'CZ': 'Czech Czechia', 'RO': 'Romania',
  'UA': 'Ukraine', 'HU': 'Hungary', 'HR': 'Croatia', 'RS': 'Serbia', 'BG': 'Bulgaria',
  'SK': 'Slovakia', 'LT': 'Lithuania', 'LV': 'Latvia', 'EE': 'Estonia', 'IS': 'Iceland',
  'SI': 'Slovenia', 'AL': 'Albania', 'MK': 'North Macedonia', 'ME': 'Montenegro', 'BA': 'Bosnia Herzegovina',
  'MT': 'Malta', 'LU': 'Luxembourg', 'CY': 'Cyprus',
  'US': 'United States USA America', 'CA': 'Canada', 'MX': 'Mexico', 'CU': 'Cuba', 'JM': 'Jamaica',
  'DO': 'Dominican Republic', 'TT': 'Trinidad and Tobago', 'HT': 'Haiti', 'GT': 'Guatemala', 'HN': 'Honduras',
  'NI': 'Nicaragua', 'SV': 'El Salvador', 'PA': 'Panama', 'CR': 'Costa Rica', 'PR': 'Puerto Rico',
  'BR': 'Brazil', 'AR': 'Argentina', 'CO': 'Colombia', 'CL': 'Chile', 'PE': 'Peru',
  'VE': 'Venezuela', 'EC': 'Ecuador', 'BO': 'Bolivia', 'PY': 'Paraguay', 'UY': 'Uruguay',
  'TR': 'Turkey Turkiye', 'SA': 'Saudi Arabia', 'AE': 'United Arab Emirates UAE Dubai', 'IQ': 'Iraq', 'IR': 'Iran',
  'IL': 'Israel', 'EG': 'Egypt', 'JO': 'Jordan', 'LB': 'Lebanon',
  'ZA': 'South Africa', 'NG': 'Nigeria', 'KE': 'Kenya', 'GH': 'Ghana', 'TZ': 'Tanzania',
  'MA': 'Morocco', 'TN': 'Tunisia', 'ET': 'Ethiopia', 'UG': 'Uganda', 'CM': 'Cameroon',
  'SN': 'Senegal', 'ZW': 'Zimbabwe', 'MZ': 'Mozambique', 'MG': 'Madagascar',
  'AU': 'Australia', 'NZ': 'New Zealand', 'FJ': 'Fiji', 'PG': 'Papua New Guinea',
};
