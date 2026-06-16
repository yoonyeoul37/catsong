import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import 'radio_player_screen.dart';

class RadioKoreaScreen extends StatefulWidget {
  const RadioKoreaScreen({super.key});

  @override
  State<RadioKoreaScreen> createState() => _RadioKoreaScreenState();
}

class _RadioKoreaScreenState extends State<RadioKoreaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      final radio = context.read<RadioProvider>();
      for (final station in _koreanStations) {
        if (station.broadcaster == 'KBS' &&
            station.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {
          radio.fetchScheduleByUrl(station.name, station.streamUrl);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_KStation> _filtered(String region) {
    if (region == '전체') return _koreanStations;
    return _koreanStations.where((s) => s.region == region).toList();
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 22),
        ),
        title: const Text(
          '한국 라디오',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: AppTheme.textHint,
          labelStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabAlignment: TabAlignment.start,
          tabs: _regions.map((r) => Tab(text: r)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _regions.map((region) {
          final stations = _filtered(region);
          if (stations.isEmpty) {
            return const Center(
              child: Text('준비 중입니다',
                  style: TextStyle(
                      color: AppTheme.textHint, fontSize: 15)),
            );
          }
          final radioStations =
          stations.map((ks) => _toRadioStation(ks)).toList();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: stations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ks = stations[index];
              final current = radioProvider.currentStation;
              final isPlaying =
                  current?.name == ks.name && radioProvider.isPlaying;
              return _StationTile(
                station: ks,
                isPlaying: isPlaying,
                radioStation: radioStations[index],
                stationList: radioStations,
                stationIndex: index,
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

    return Material(
      color: isPlaying
          ? primaryColor.withOpacity(0.12)
          : AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RadioPlayerScreen(
                station: radioStation,
                stationList: stationList,
                currentIndex: stationIndex,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _brandColor(station.broadcaster),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      station.broadcaster,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (station.subLabel.isNotEmpty)
                      Text(
                        station.subLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(
                      builder: (ctx) {
                        final isKbs = station.broadcaster == 'KBS' &&
                            station.streamUrl.contains('cfpwwwapi.kbs.co.kr');
                        if (!isKbs) {
                          return Text(
                            station.frequency.isNotEmpty
                                ? station.frequency
                                : '',
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          );
                        }
                        final radio = ctx.watch<RadioProvider>();
                        final nowPlaying = radio.nowPlayingFor(station.name);
                        final program = radio.currentProgramFor(station.name);
                        final start = program?['program_planned_start_time'] as String? ?? '';
                        final end = program?['program_planned_end_time'] as String? ?? '';
                        // 시간 포맷: 15:00~17:00
                        String _fmt(String t) {
                          if (t.length < 4) return t;
                          int h = int.tryParse(t.substring(0, 2)) ?? 0;
                          final m = t.substring(2, 4);
                          if (h >= 24) h -= 24;
                          return '$h:$m';
                        }
                        final timeStr = start.isNotEmpty && end.isNotEmpty
                            ? '${_fmt(start)}~${_fmt(end)}'
                            : '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nowPlaying != null && nowPlaying.isNotEmpty)
                              Text(
                                nowPlaying,
                                style: TextStyle(
                                  color: primaryColor.withOpacity(0.9),
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
                              style: const TextStyle(
                                color: AppTheme.textHint,
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
                    color: AppTheme.textHint, size: 24),
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

const _koreanStations = <_KStation>[
  // ══════ 수도권 ══════
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
  _KStation(name: 'YTN 라디오', region: '수도권', broadcaster: 'YTN', subLabel: '서울', frequency: '94.5 MHz', streamUrl: 'https://radiolive.ytn.co.kr/radio/_definst_/20211118_fmlive/playlist.m3u8'),
  _KStation(name: 'TBS FM', region: '수도권', broadcaster: 'TBS', subLabel: '서울', frequency: '95.1 MHz', streamUrl: 'https://cdnfm.tbs.seoul.kr/tbs/_definst_/tbs_fm_web_360.smil/chunklist.m3u8'),
  _KStation(name: 'TBS eFM', region: '수도권', broadcaster: 'TBS', subLabel: '서울', frequency: '101.3 MHz', streamUrl: 'https://cdnefm.tbs.seoul.kr/tbs/_definst_/tbs_efm_web_360.smil/chunklist.m3u8'),
  _KStation(name: 'EBS FM', region: '수도권', broadcaster: 'EBS', subLabel: '서울', frequency: '104.5 MHz', streamUrl: 'https://ebsonair.ebs.co.kr/fmradiofamilypc/familypc1m/playlist.m3u8'),
  _KStation(name: 'OBS 라디오', region: '수도권', broadcaster: 'OBS', subLabel: '경기', frequency: '90.1 MHz', streamUrl: 'https://vod3.obs.co.kr:444/live/obsstream1/radio.stream/playlist.m3u8'),
  _KStation(name: '경인방송', region: '수도권', broadcaster: 'OBS', subLabel: '인천', frequency: '90.7 MHz', streamUrl: 'https://stream.ifm.kr/live/aod1/playlist.m3u8'),
  _KStation(name: 'CPBC 가톨릭', region: '수도권', broadcaster: 'CPBC', subLabel: '서울', frequency: '101.7 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/cpbc.pls'),
  _KStation(name: '국악FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '99.1 MHz', streamUrl: 'http://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8'),
  _KStation(name: '국방FM', region: '수도권', broadcaster: 'KBS', subLabel: '서울', frequency: '100.5 MHz', streamUrl: 'http://serpent0.duckdns.org:8088/gbfm.pls'),
  _KStation(name: 'TBN 경인교통', region: '수도권', broadcaster: 'TBN', subLabel: '경기', frequency: '99.9 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/gyeongin/myStream/playlist.m3u8'),
  // ══════ 부산/경남 ══════
  _KStation(name: 'KBS 부산 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '103.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_21'),
  _KStation(name: 'KBS 부산 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_22'),
  _KStation(name: 'KBS 부산 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '부산', frequency: '92.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/10_24'),
  _KStation(name: 'KBS 창원 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_21'),
  _KStation(name: 'KBS 창원 해피FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '106.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_22'),
  _KStation(name: 'KBS 창원 1FM', region: '부산/경남', broadcaster: 'KBS', subLabel: '창원', frequency: '93.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/20_24'),
  _KStation(name: 'KBS 진주 1라디오', region: '부산/경남', broadcaster: 'KBS', subLabel: '진주', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/21_21'),
  _KStation(name: 'BeFM', region: '부산/경남', broadcaster: 'BeFM', subLabel: '부산', frequency: '90.5 MHz', streamUrl: 'http://befm905.live.smilecdn.com:1935/befm905_live/live/playlist.m3u8'),
  _KStation(name: 'TBN 울산교통', region: '부산/경남', broadcaster: 'TBN', subLabel: '울산', frequency: '98.7 MHz', streamUrl: 'http://radio2.tbn.or.kr:1935/ulsan/myStream/playlist.m3u8'),
  // ══════ 대구/경북 ══════
  _KStation(name: 'KBS 대구 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '101.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_21'),
  _KStation(name: 'KBS 대구 해피FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '96.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_22'),
  _KStation(name: 'KBS 대구 1FM', region: '대구/경북', broadcaster: 'KBS', subLabel: '대구', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/30_24'),
  _KStation(name: 'KBS 안동 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '안동', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/31_21'),
  _KStation(name: 'KBS 포항 1라디오', region: '대구/경북', broadcaster: 'KBS', subLabel: '포항', frequency: '95.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/32_21'),
  _KStation(name: '안동MBC AM', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '729 kHz', streamUrl: 'http://andong.webcasting.co.kr:1935/live/amlive/playlist.m3u8'),
  _KStation(name: '안동MBC FM4U', region: '대구/경북', broadcaster: 'MBC', subLabel: '안동', frequency: '97.7 MHz', streamUrl: 'https://live.andongmbc.co.kr/live/fmlive/playlist.m3u8'),
  // ══════ 광주/전남 ══════
  _KStation(name: 'KBS 광주 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '90.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_21'),
  _KStation(name: 'KBS 광주 해피FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '100.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_22'),
  _KStation(name: 'KBS 광주 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '광주', frequency: '93.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/40_24'),
  _KStation(name: 'KBS 목포 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '105.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_21'),
  _KStation(name: 'KBS 목포 1FM', region: '광주/전남', broadcaster: 'KBS', subLabel: '목포', frequency: '101.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/41_24'),
  _KStation(name: 'KBS 순천 1라디오', region: '광주/전남', broadcaster: 'KBS', subLabel: '순천', frequency: '95.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/43_21'),
  // ══════ 전북 ══════
  _KStation(name: 'KBS 전주 1라디오', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '96.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_21'),
  _KStation(name: 'KBS 전주 해피FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_22'),
  _KStation(name: 'KBS 전주 1FM', region: '전북', broadcaster: 'KBS', subLabel: '전주', frequency: '93.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/50_24'),
  _KStation(name: 'JTV 매직FM', region: '전북', broadcaster: 'JTV', subLabel: '전주', frequency: '99.1 MHz', streamUrl: 'https://61ff3340258d2.streamlock.net/jtv_radio/myStream/chunklist_w111659793.m3u8'),
  // ══════ 대전/충남 ══════
  _KStation(name: 'KBS 대전 1라디오', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '94.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_21'),
  _KStation(name: 'KBS 대전 해피FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_22'),
  _KStation(name: 'KBS 대전 1FM', region: '대전/충남', broadcaster: 'KBS', subLabel: '대전', frequency: '99.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/60_24'),
  // ══════ 충북 ══════
  _KStation(name: 'KBS 청주 1라디오', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '89.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_21'),
  _KStation(name: 'KBS 청주 해피FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '99.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_22'),
  _KStation(name: 'KBS 청주 1FM', region: '충북', broadcaster: 'KBS', subLabel: '청주', frequency: '91.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/70_24'),
  _KStation(name: 'MBC충북 표준FM', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '93.3 MHz', streamUrl: 'http://211.33.246.4:32954/radio_stfm/myStream.sdp/chunklist_w392819215.m3u8'),
  _KStation(name: 'MBC충북 FM4U', region: '충북', broadcaster: 'MBC', subLabel: '충북', frequency: '96.7 MHz', streamUrl: 'http://211.33.246.4:32954/radio_fm/myStream.sdp/chunklist_w348337231.m3u8'),
  // ══════ 강원 ══════
  _KStation(name: 'KBS 춘천 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '99.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_21'),
  _KStation(name: 'KBS 춘천 해피FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '98.7 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_22'),
  _KStation(name: 'KBS 춘천 1FM', region: '강원', broadcaster: 'KBS', subLabel: '춘천', frequency: '91.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/80_24'),
  _KStation(name: 'KBS 강릉 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '98.9 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_21'),
  _KStation(name: 'KBS 강릉 1FM', region: '강원', broadcaster: 'KBS', subLabel: '강릉', frequency: '90.3 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/81_24'),
  _KStation(name: 'KBS 원주 1라디오', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '97.1 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_21'),
  _KStation(name: 'KBS 원주 1FM', region: '강원', broadcaster: 'KBS', subLabel: '원주', frequency: '100.5 MHz', streamUrl: 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/82_24'),
  // ══════ 제주 ══════
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