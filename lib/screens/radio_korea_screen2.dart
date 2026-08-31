import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import 'radio_player_screen.dart';
import '../l10n/app_localizations.dart';

enum _ViewMode { all, broadcaster, region, recent }

class RadioKoreaScreen extends StatefulWidget {
  const RadioKoreaScreen({super.key});

  @override
  State<RadioKoreaScreen> createState() => _RadioKoreaScreenState();
}

class _RadioKoreaScreenState extends State<RadioKoreaScreen> {
  _ViewMode _mode = _ViewMode.all;

  static const Map<String, Color> _regionColors = {
    '수도권': Color(0xFF14356B),
    '부산/경남': Color(0xFF0D4C6E),
    '대구/경북': Color(0xFF7A1F1F),
    '광주/전남': Color(0xFF1E4A2E),
    '전북': Color(0xFF4A1E5C),
    '대전/충남': Color(0xFF6B4A1E),
    '충북': Color(0xFF2E5C5C),
    '강원': Color(0xFF3A2E5C),
    '제주': Color(0xFF1E5C4A),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final radio = context.read<RadioProvider>();
      for (final station in koreanStations) {
        if (station.broadcaster == 'KBS' &&
            station.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
          radio.fetchScheduleByUrl(station.name, station.streamUrl);
        }
      }
      radio.fetchMbcSchedule('MBC 표준FM');
      radio.fetchMbcSchedule('MBC FM4U');
      radio.fetchSbsSchedule('SBS 파워FM');
      radio.fetchSbsSchedule('SBS 러브FM');
      radio.fetchJsonSchedule('CBS 음악FM');
      radio.fetchJsonSchedule('CBS 표준FM');
      radio.fetchKfnSchedule();
      radio.fetchEbsBandiSchedule();
    });
  }

  static RadioStation _toRadioStation(_KStation ks) {
    return RadioStation.fromJson({
      'stationuuid': 'kr_${ks.name.hashCode.abs()}',
      'name': ks.name,
      'url': ks.streamUrl,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': ks.frequency,
      'country': 'South Korea',
      'countrycode': 'KR',
      'codec': '',
      'bitrate': 0,
      'hls': 1,
      'votes': 0,
      'lastcheckok': 1,
    });
  }

  Widget _toggleButton(String label, _ViewMode mode) {
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
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0D2E2C) : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllList(BuildContext context, RadioProvider radioProvider) {
    final radioStations = koreanStations.map((ks) => _toRadioStation(ks)).toList();
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: koreanStations.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.1)),
      itemBuilder: (context, i) {
        final ks = koreanStations[i];
        final current = radioProvider.currentStation;
        final isPlaying = current?.name == ks.name && radioProvider.isPlaying;
        return _StationTile(
          station: ks,
          isPlaying: isPlaying,
          radioStation: radioStations[i],
          stationList: radioStations,
          stationIndex: i,
        );
      },
    );
  }

  Widget _buildBroadcasterGrid(BuildContext context, RadioProvider radioProvider) {
    return _BroadcasterGridScreen(radioProvider: radioProvider);
  }

  Widget _buildRecentList(BuildContext context, RadioProvider radioProvider) {
    final recent = radioProvider.recentlyListened;
    if (recent.isEmpty) {
      return Center(
        child: Text(
          '최근 들은 방송이 없어요',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: recent.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.1)),
      itemBuilder: (context, i) {
        final station = recent[i];
        final lastListened = station.lastListened;
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final timeStr = lastListened != null
            ? '${lastListened.year}.${lastListened.month.toString().padLeft(2, '0')}.${lastListened.day.toString().padLeft(2, '0')}(${weekdays[lastListened.weekday - 1]}) ${lastListened.hour.toString().padLeft(2, '0')}:${lastListened.minute.toString().padLeft(2, '0')}'
            : '';
        final isPlaying = radioProvider.currentStation?.stationUuid == station.stationUuid && radioProvider.isPlaying;
        return InkWell(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(station: station),
                transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 250),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPlaying ? primaryColorOf(context) : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color primaryColorOf(BuildContext context) => Theme.of(context).colorScheme.primary;

  Widget _buildRegionGrid(BuildContext context) {
    const regionList = [
      '수도권', '부산/경남', '대구/경북', '광주/전남',
      '전북', '대전/충남', '충북', '강원', '제주',
    ];
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: regionList.length,
      itemBuilder: (context, index) {
        final region = regionList[index];
        final count = koreanStations.where((s) => s.region == region).length;
        return GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            final stations = koreanStations.where((s) => s.region == region).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _BroadcasterStationList(broadcaster: region, stations: stations),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: _regionColors[region] ?? Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  region,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('$count개 채널',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF17140F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '\u201C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.radioKoreaSlogan,
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _toggleButton('전체', _ViewMode.all),
                  _toggleButton('방송사별', _ViewMode.broadcaster),
                  _toggleButton('지역별', _ViewMode.region),
                  _toggleButton('최근청취', _ViewMode.recent),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: switch (_mode) {
          _ViewMode.all => _buildAllList(context, radioProvider),
          _ViewMode.broadcaster => _buildBroadcasterGrid(context, radioProvider),
          _ViewMode.region => _buildRegionGrid(context),
          _ViewMode.recent => _buildRecentList(context, radioProvider),
        },
      ),
      bottomNavigationBar: radioProvider.currentStation != null
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
  final _KStation station;
  final bool isPlaying;
  final RadioStation radioStation;
  final List<RadioStation> stationList;
  final int stationIndex;

  const _StationTile({
    required this.station,
    required this.isPlaying,
    required this.radioStation,
    required this.stationList,
    required this.stationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: isPlaying ? primaryColor.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(
                station: radioStation,
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying ? primaryColor : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  station.broadcaster,
                  style: TextStyle(
                    color: isPlaying ? Colors.black : Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        color: isPlaying ? primaryColor : Colors.white,
                        fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (ctx) {
                        final isKbs = station.broadcaster == 'KBS';
                        const mbcNames = ['MBC 표준FM', 'MBC FM4U'];
                        const sbsNames = ['SBS 파워FM', 'SBS 러브FM'];
                        final isMbc = mbcNames.contains(station.name);
                        final isSbs = sbsNames.contains(station.name);
                        final radio = ctx.watch<RadioProvider>();
                        final hasJsonSchedule = radio.nowPlayingFor(station.name) != null && !isKbs && !isMbc && !isSbs;
                        if (!isKbs && !isMbc && !isSbs && !hasJsonSchedule) {
                          return Text(
                            station.frequency.isNotEmpty
                                ? station.frequency
                                : '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          );
                        }
                        final nowPlaying = radio.nowPlayingFor(station.name);
                        final program = radio.currentProgramFor(station.name);
                        final start = program?['program_planned_start_time'] as String? ?? '';
                        final end = program?['program_planned_end_time'] as String? ?? '';
                        final sbsTitle = program?['title'] as String?;
                        final displayNowPlaying = nowPlaying ?? sbsTitle;
                        String _fmt(String t) {
                          final cleaned = t.replaceAll(':', '');
                          if (cleaned.length >= 12) {
                            final hhmm = cleaned.substring(8, 12);
                            int h = int.tryParse(hhmm.substring(0, 2)) ?? 0;
                            final m = hhmm.substring(2, 4);
                            if (h >= 24) h -= 24;
                            return '${h.toString().padLeft(2, '0')}:$m';
                          }
                          if (cleaned.length < 4) return t;
                          int h = int.tryParse(cleaned.substring(0, 2)) ?? 0;
                          final m = cleaned.substring(2, 4);
                          if (h >= 24) h -= 24;
                          return '${h.toString().padLeft(2, '0')}:$m';
                        }
                        final isMbcStation = mbcNames.contains(station.name);
                        final isSbsStation = sbsNames.contains(station.name);
                        String? rawStart;
                        String? rawEnd;
                        if (isMbcStation) {
                          final mbcS = program?['StartTime'];
                          final mbcE = program?['EndTime'];
                          rawStart = mbcS?.toString();
                          rawEnd = mbcE?.toString();
                        } else if (isSbsStation) {
                          rawStart = program?['start_time'] as String?;
                          rawEnd = program?['end_time'] as String?;
                        } else if (hasJsonSchedule) {
                          rawStart = program?['start_time'] as String?;
                          rawEnd = program?['end_time'] as String?;
                        } else {
                          rawStart = start.isEmpty ? null : start;
                          rawEnd = end.isEmpty ? null : end;
                        }
                        String _fmtSbs(String t) {
                          if (t.length >= 5) {
                            final h = int.tryParse(t.split(':')[0]) ?? 0;
                            final m = t.split(':')[1];
                            return '${h >= 24 ? h - 24 : h}:$m';
                          }
                          return t;
                        }
                        final timeStr = rawStart != null && rawEnd != null
                            ? isSbsStation
                            ? '${_fmtSbs(rawStart)}~${_fmtSbs(rawEnd)}'
                            : isMbcStation
                            ? '${_fmt(rawStart)}~${_fmt(rawEnd)}'
                            : hasJsonSchedule
                            ? '$rawStart~$rawEnd'
                            : '${_fmt(rawStart)}~${_fmt(rawEnd)}'
                            : '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayNowPlaying != null && displayNowPlaying.isNotEmpty)
                              Text(
                                displayNowPlaying,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              [
                                if (station.frequency.isNotEmpty) station.frequency,
                                if (timeStr.isNotEmpty) timeStr,
                              ].join(' · '),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                _PlayingBars(color: primaryColor)
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    final wasFav = context.read<RadioProvider>().isFavorite(radioStation.stationUuid);
                    context.read<RadioProvider>().toggleFavorite(radioStation);
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
                  child: Icon(
                    context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.35),
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KStation {
  final String name;
  final String region;
  final String broadcaster;
  final String subLabel;
  final String frequency;
  final String streamUrl;

  const _KStation({
    required this.name,
    required this.region,
    required this.broadcaster,
    this.subLabel = '',
    this.frequency = '',
    required this.streamUrl,
  });
}

const koreanStations = <_KStation>[
  _KStation(name: 'KBS Classic FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '93.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/24'),
  _KStation(name: 'KBS Cool FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '89.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/25'),
  _KStation(name: 'KBS 제1라디오', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '97.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/21'),
  _KStation(name: 'KBS 해피FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '106.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/22'),
  _KStation(name: 'KBS 3라디오', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '104.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/23'),
  _KStation(name: 'MBC 표준FM', region: '수도권', broadcaster: 'MBC', subLabel: '서울', frequency: '95.9 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/mbcsfm.pls'),
  _KStation(name: 'MBC FM4U', region: '수도권', broadcaster: 'MBC', subLabel: '서울', frequency: '91.9 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/mbcfm.pls'),
  _KStation(name: 'MBC 올댓뮤직', region: '수도권', broadcaster: 'MBC', subLabel: '서울', frequency: '', streamUrl: 'http://serpent0.duckdns.org:8088/mbcatm.pls'),
  _KStation(name: 'SBS 파워FM', region: '수도권', broadcaster: 'SBS', subLabel: '서울', frequency: '107.7 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/sbsfm.pls'),
  _KStation(name: 'SBS 러브FM', region: '수도권', broadcaster: 'SBS', subLabel: '서울', frequency: '103.5 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/sbs2fm.pls'),
  _KStation(name: 'CBS 음악FM', region: '수도권', broadcaster: 'CBS', subLabel: '서울', frequency: '93.9 MHz', streamUrl: 'https://m-aac.cbs.co.kr/mweb_cbs939/_definst_/cbs939.stream/playlist.m3u8'),
  _KStation(name: 'CBS 표준FM', region: '수도권', broadcaster: 'CBS', subLabel: '서울', frequency: '98.1 MHz', streamUrl: 'https://m-aac.cbs.co.kr/mweb_cbs981/_definst_/cbs981.stream/playlist.m3u8'),
  _KStation(name: 'YTN 라디오', region: '수도권', broadcaster: 'YTN', subLabel: '서울', frequency: '94.5 MHz', streamUrl: 'https://radiolive.ytn.co.kr/radio/_definst_/20211118_fmlive/playlist.m3u8'),
  _KStation(name: 'TBS FM', region: '수도권', broadcaster: 'TBS', subLabel: '서울', frequency: '95.1 MHz', streamUrl: 'https://cdnfm.tbs.seoul.kr/tbs/_definst_/tbs_fm_web_360.smil/chunklist.m3u8'),
  _KStation(name: 'TBS eFM', region: '수도권', broadcaster: 'TBS', subLabel: '서울', frequency: '101.3 MHz', streamUrl: 'https://cdnefm.tbs.seoul.kr/tbs/_definst_/tbs_efm_web_360.smil/chunklist.m3u8'),
  _KStation(name: 'EBS FM', region: '수도권', broadcaster: 'EBS', subLabel: '서울', frequency: '104.5 MHz', streamUrl: 'https://ebsonair.ebs.co.kr/fmradiofamilypc/familypc1m/playlist.m3u8'),
  _KStation(name: 'EBS 반디', region: '수도권', broadcaster: 'EBS', subLabel: '외국어', frequency: '', streamUrl: 'https://ebsonair.ebs.co.kr/cloud1/iradio/playlist.m3u8'),
  _KStation(name: 'OBS 라디오', region: '수도권', broadcaster: 'OBS', subLabel: '경기', frequency: '90.1 MHz', streamUrl: 'https://vod3.obs.co.kr:444/live/obsstream1/radio.stream/playlist.m3u8'),
  _KStation(name: '경인방송', region: '수도권', broadcaster: 'OBS', subLabel: '인천', frequency: '90.7 MHz', streamUrl: 'https://stream.ifm.kr/live/aod1/playlist.m3u8'),
  _KStation(name: 'CPBC 가톨릭', region: '수도권', broadcaster: 'CPBC', subLabel: '서울', frequency: '101.7 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/cpbc.pls'),
  _KStation(name: 'FEBC 극동방송', region: '수도권', broadcaster: 'FEBC', subLabel: '서울', frequency: '106.9 MHz', streamUrl: 'http://mlive2.febc.net:1935/live/seoulfm/playlist.m3u8'),
  _KStation(name: 'BBS 불교방송', region: '수도권', broadcaster: 'BBS', subLabel: '서울', frequency: '101.9 MHz', streamUrl: 'https://bbslive.clouducs.com/bbsradio-mlive/radio.stream/playlist.m3u8'),
  _KStation(name: '국악FM', region: '수도권', broadcaster: '국악방송', subLabel: '서울', frequency: '99.1 MHz', streamUrl: 'http://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8'),
  _KStation(name: '국방FM', region: '수도권', broadcaster: '국방FM', subLabel: '서울', frequency: '100.5 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/gbfm.pls'),
  _KStation(name: 'TBN 경인교통', region: '수도권', broadcaster: 'TBN', subLabel: '경기', frequency: '99.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gyeongin/myStream/playlist.m3u8'),
  _KStation(name: '부산MBC 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '부산', frequency: '95.9 MHz', streamUrl: 'https://stream.bsmbc.com/live/BusanMBC_AM_onairstream.sbhhqc/playlist.m3u8'),
  _KStation(name: '부산MBC FM4U', region: '부산/경남', broadcaster: 'MBC', subLabel: '부산', frequency: '88.9 MHz', streamUrl: 'https://stream.bsmbc.com/live/mp4:BusanMBC.Live-FM-0415/playlist.m3u8'),
  _KStation(name: '울산MBC 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '울산', frequency: '97.5 MHz', streamUrl: 'https://5ddfd163bd00d.streamlock.net/STDFM/STDFM/playlist.m3u8'),
  _KStation(name: 'MBC경남 표준FM', region: '부산/경남', broadcaster: 'MBC', subLabel: '창원', frequency: '97.9 MHz', streamUrl: 'https://624a79c87201d.streamlock.net/MBCFM/TV2.stream/playlist.m3u8'),
  _KStation(name: 'KBS 부산 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '103.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_21'),
  _KStation(name: 'KBS 부산 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_22'),
  _KStation(name: 'KBS 부산 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '92.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_24'),
  _KStation(name: 'KBS 창원 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_21'),
  _KStation(name: 'KBS 창원 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '106.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_22'),
  _KStation(name: 'KBS 창원 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '93.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_24'),
  _KStation(name: 'KBS 진주 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '진주', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/21_21'),
  _KStation(name: 'BeFM', region: '부산/경남', broadcaster: 'BeFM', subLabel: '부산', frequency: '90.5 MHz', streamUrl: 'http://befm905.live.smilecdn.com:1935/befm905_live/live/playlist.m3u8'),
  _KStation(name: 'TBN 울산교통', region: '부산/경남', broadcaster: 'TBN', subLabel: '울산', frequency: '98.7 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/ulsan/myStream/playlist.m3u8'),
  _KStation(name: 'KBS 대구 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '101.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_21'),
  _KStation(name: 'KBS 대구 해피FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '96.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_22'),
  _KStation(name: 'KBS 대구 1FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_24'),
  _KStation(name: 'KBS 안동 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '안동', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/31_21'),
  _KStation(name: 'KBS 포항 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '포항', frequency: '95.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/32_21'),
  _KStation(name: '안동MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '97.7 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/amlive/playlist.m3u8'),
  _KStation(name: '안동MBC FM4U', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '103.1 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/fmlive/playlist.m3u8'),
  _KStation(name: '대구MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '대구', frequency: '95.7 MHz', streamUrl: 'https://5ee1ec6f32118.streamlock.net/amradio/am/playlist.m3u8'),
  _KStation(name: '포항MBC 표준FM', region: '대구/경북', broadcaster: 'MBC', subLabel: '포항', frequency: '104.3 MHz', streamUrl: 'http://stream.yubinet.com:1935/live/_definst_/Radio_Am/playlist.m3u8'),
  _KStation(name: '광주MBC 표준FM', region: '광주/전남', broadcaster: 'MBC', subLabel: '광주', frequency: '97.9 MHz', streamUrl: 'https://media.kjmbc.co.kr/hls/amlive/GWANGJU-MBC-AM/playlist.m3u8'),
  _KStation(name: '광주MBC FM4U', region: '광주/전남', broadcaster: 'MBC', subLabel: '광주', frequency: '89.5 MHz', streamUrl: 'https://media.kjmbc.co.kr/hls/fmlive/GWANGJU-MBC-FM/playlist.m3u8'),
  _KStation(name: '목포MBC 표준FM', region: '광주/전남', broadcaster: 'MBC', subLabel: '목포', frequency: '97.9 MHz', streamUrl: 'https://vod.mpmbc.co.kr/live/encoder-am/playlist.m3u8'),
  _KStation(name: 'KBS 광주 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_21'),
  _KStation(name: 'KBS 광주 해피FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '100.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_22'),
  _KStation(name: 'KBS 광주 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '93.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_24'),
  _KStation(name: 'KBS 목포 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '105.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_21'),
  _KStation(name: 'KBS 목포 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '101.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_24'),
  _KStation(name: 'KBS 순천 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '순천', frequency: '95.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/43_21'),
  _KStation(name: 'KBS 전주 1라디오', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '96.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_21'),
  _KStation(name: 'KBS 전주 해피FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_22'),
  _KStation(name: 'KBS 전주 1FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '93.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_24'),
  _KStation(name: 'JTV 매직FM', region: '전북', broadcaster: 'JTV', subLabel: '전주', frequency: '99.1 MHz', streamUrl: 'https://61ff3340258d2.streamlock.net/jtv_radio/myStream/chunklist_w111659793.m3u8'),
  _KStation(name: '대전MBC 표준FM', region: '대전/충남', broadcaster: 'MBC', subLabel: '대전', frequency: '99.5 MHz', streamUrl: 'https://ns1.tjmbc.co.kr/live_am/live_am.stream/playlist.m3u8'),
  _KStation(name: 'KBS 대전 1라디오', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '94.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_21'),
  _KStation(name: 'KBS 대전 해피FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_22'),
  _KStation(name: 'KBS 대전 1FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '99.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_24'),
  _KStation(name: 'KBS 청주 1라디오', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '89.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_21'),
  _KStation(name: 'KBS 청주 해피FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '99.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_22'),
  _KStation(name: 'KBS 청주 1FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_24'),
  _KStation(name: 'MBC충북 표준FM', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '93.3 MHz', streamUrl: 'http://211.33.246.4:32954/radio_stfm/myStream.sdp/chunklist_w392819215.m3u8'),
  _KStation(name: 'MBC충북 FM4U', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '96.7 MHz', streamUrl: 'http://211.33.246.4:32954/radio_fm/myStream.sdp/chunklist_w348337231.m3u8'),
  _KStation(name: '춘천MBC 표준FM', region: '강원', broadcaster: 'MBC', subLabel: '춘천', frequency: '92.3 MHz', streamUrl: 'https://stream.chmbc.co.kr/live_radio/fm2/playlist.m3u8'),
  _KStation(name: '춘천MBC FM4U', region: '강원', broadcaster: 'MBC', subLabel: '춘천', frequency: '97.9 MHz', streamUrl: 'https://stream.chmbc.co.kr/live_radio2/fm1/playlist.m3u8'),
  _KStation(name: 'KBS 춘천 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '99.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_21'),
  _KStation(name: 'KBS 춘천 해피FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_22'),
  _KStation(name: 'KBS 춘천 1FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_24'),
  _KStation(name: 'KBS 강릉 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '98.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_21'),
  _KStation(name: 'KBS 강릉 1FM', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_24'),
  _KStation(name: 'KBS 원주 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_21'),
  _KStation(name: 'KBS 원주 1FM', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_24'),
  _KStation(name: '제주MBC 표준FM', region: '제주', broadcaster: 'MBC', subLabel: '제주', frequency: '97.9 MHz', streamUrl: 'https://wowza.jejumbc.com/live/_definst_/mp3:radio1/playlist.m3u8'),
  _KStation(name: '제주MBC FM4U', region: '제주', broadcaster: 'MBC', subLabel: '제주', frequency: '89.9 MHz', streamUrl: 'https://wowza.jejumbc.com/live/_definst_/mp3:radio2/playlist.m3u8'),
  _KStation(name: 'KBS 제주 1라디오', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '93.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_21'),
  _KStation(name: 'KBS 제주 해피FM', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_22'),
  _KStation(name: 'KBS 제주 1FM', region: '제주', broadcaster: 'KBS', subLabel: '제주', frequency: '96.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/90_24'),
];

class _PlayingBars extends StatefulWidget {
  final Color color;
  const _PlayingBars({required this.color});

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
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════
// 방송사별 카드 격자 화면
// ══════════════════════════════════════════
class _BroadcasterGridScreen extends StatelessWidget {
  final RadioProvider radioProvider;
  const _BroadcasterGridScreen({required this.radioProvider});

  static const _order = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS', '기타'];

  static const Map<String, Color> _cardColors = {
    'KBS': Color(0xFF14356B),
    'MBC': Color(0xFF4A1E5C),
    'SBS': Color(0xFF7A1F1F),
    'EBS': Color(0xFF0D4C6E),
    'CBS': Color(0xFF1E4A2E),
  };

  Map<String, List<_KStation>> _grouped() {
    final Map<String, List<_KStation>> map = {};
    for (final s in koreanStations) {
      final key = ['KBS', 'MBC', 'SBS', 'EBS', 'CBS'].contains(s.broadcaster)
          ? s.broadcaster
          : '기타';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    final keys = _order.where((k) => grouped.containsKey(k)).toList();

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final stations = grouped[key]!;
        return GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _BroadcasterStationList(broadcaster: key, stations: stations),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: _cardColors[key] ?? Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stations.length}개 채널',
                  style: TextStyle(
                    color: Colors.white.withOpacity(_cardColors.containsKey(key) ? 0.7 : 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════
// 방송사 하나의 전국 채널 리스트 화면
// ══════════════════════════════════════════
class _BroadcasterStationList extends StatelessWidget {
  final String broadcaster;
  final List<_KStation> stations;
  const _BroadcasterStationList({required this.broadcaster, required this.stations});

  static RadioStation _toRadioStation(_KStation ks) {
    return RadioStation.fromJson({
      'stationuuid': 'kr_${ks.name.hashCode.abs()}',
      'name': ks.name,
      'url': ks.streamUrl,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': ks.frequency,
      'country': 'South Korea',
      'countrycode': 'KR',
      'codec': '',
      'bitrate': 0,
      'hls': 1,
      'votes': 0,
      'lastcheckok': 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final radioStations = stations.map((ks) => _toRadioStation(ks)).toList();
    final radioProvider = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D2E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: Text(broadcaster,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
          itemCount: stations.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          itemBuilder: (context, i) {
            final ks = stations[i];
            final current = radioProvider.currentStation;
            final isPlaying = current?.name == ks.name && radioProvider.isPlaying;
            return _StationTile(
              station: ks,
              isPlaying: isPlaying,
              radioStation: radioStations[i],
              stationList: radioStations,
              stationIndex: i,
            );
          },
        ),
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    );
  }
}