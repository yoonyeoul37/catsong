import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import 'radio_player_screen.dart';
import '../l10n/app_localizations.dart';

class RadioKoreaScreen extends StatefulWidget {
  const RadioKoreaScreen({super.key});

  @override
  State<RadioKoreaScreen> createState() => _RadioKoreaScreenState();
}

class _RadioKoreaScreenState extends State<RadioKoreaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _regions = [
    '전체',
    '수도권',
    '부산/경남',
    '대구/경북',
    '광주/전남',
    '전북',
    '대전/충남',
    '충북',
    '강원',
    '제주',
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _regions.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('한국 라디오 initState 실행됨');
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _regionLabel(BuildContext context, String region) {
    final l = AppLocalizations.of(context)!;
    switch (region) {
      case '전체': return l.regionAll;
      case '수도권': return l.regionCapital;
      case '부산/경남': return l.regionBusanGyeongnam;
      case '대구/경북': return l.regionDaeguGyeongbuk;
      case '광주/전남': return l.regionGwangjuJeonnam;
      case '전북': return l.regionJeonbuk;
      case '대전/충남': return l.regionDaejeonChungnam;
      case '충북': return l.regionChungbuk;
      case '강원': return l.regionGangwon;
      case '제주': return l.regionJeju;
      default: return region;
    }
  }

  List<_KStation> _filtered(String region) {
    Iterable<_KStation> list = region == '전체'
        ? koreanStations
        : koreanStations.where((s) => s.region == region);
    if (_query.isNotEmpty) {
      list = list.where((s) => s.name.toLowerCase().contains(_query.toLowerCase()));
    }
    return list.toList();
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();

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
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.fixedAccent,
                indicatorWeight: 2,
                labelColor: AppTheme.fixedAccent,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                labelStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13.5),
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                tabs: _regions.map((r) => Tab(text: _regionLabel(context, r))).toList(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.search,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 19),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.4), size: 17),
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
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _regions.map((region) {
          final stations = _filtered(region);
          if (stations.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.radioNoStationsFound,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 14)),
            );
          }
          final radioStations =
          stations.map((ks) => _toRadioStation(ks)).toList();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 90),
            itemCount: stations.length + 1,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.white.withOpacity(0.16), indent: 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                  child: Row(
                    children: [
                      const Text('🇰🇷', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.radioPopularCount(stations.length),
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12.5),
                      ),
                    ],
                  ),
                );
              }
              final i = index - 1;
              final ks = stations[i];
              final current = radioProvider.currentStation;
              final isPlaying =
                  current?.name == ks.name && radioProvider.isPlaying;
              return _StationTile(
                station: ks,
                isPlaying: isPlaying,
                radioStation: radioStations[i],
                stationList: radioStations,
                stationIndex: i,
              );
            },
          );
        }).toList(),
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

  static const Map<String, Color> _colors = {
    'KBS': Color(0xFF1565C0),
    'MBC': Color(0xFF6A1B9A),
    'SBS': Color(0xFFB71C1C),
    'CBS': Color(0xFF1B5E20),
    'EBS': Color(0xFF0277BD),
    'YTN': Color(0xFF880E4F),
    'TBS': Color(0xFF004D40),
    'TBN': Color(0xFF2E7D32),
    'OBS': Color(0xFF0D47A1),
    'CPBC': Color(0xFF6D4C41),
    'BeFM': Color(0xFFE65100),
    'JTV': Color(0xFF00695C),
  };

  Color _brandColor(String bc) =>
      _colors[bc] ?? const Color(0xFF37474F);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _brandColor(station.broadcaster).withOpacity(0.85),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    station.broadcaster,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (station.subLabel.isNotEmpty)
                    Text(
                      station.subLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                      ),
                    ),
                ],
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
                      color: isPlaying ? AppTheme.fixedAccent : Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
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
                      final hasJsonSchedule = radio.nowPlayingFor(station.name) != null;
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
                        if (t.length < 4) return t;
                        int h = int.tryParse(t.substring(0, 2)) ?? 0;
                        final m = t.substring(2, 4);
                        if (h >= 24) h -= 24;
                        return '$h:$m';
                      }
                      final isMbcStation = mbcNames.contains(station.name);
                      final isSbsStation = sbsNames.contains(station.name);
                      String? rawStart;
                      String? rawEnd;
                      if (isMbcStation) {
                        rawStart = program?['StartTime'] as String?;
                        rawEnd = program?['EndTime'] as String?;
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
                                color: Colors.white.withOpacity(0.65),
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
                              color: Colors.white.withOpacity(0.32),
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
              _PlayingBars()
            else
              Icon(Icons.play_circle_outline,
                  color: Colors.white.withOpacity(0.25), size: 23),
          ],
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
  _KStation(name: 'KBS 해피FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '104.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/22'),
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
  _KStation(name: '국악FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '99.1 MHz', streamUrl: 'http://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8'),
  _KStation(name: '국방FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '100.5 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/gbfm.pls'),
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