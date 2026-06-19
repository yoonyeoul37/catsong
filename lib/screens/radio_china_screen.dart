import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import 'radio_player_screen.dart';

class RadioChinaScreen extends StatelessWidget {
  const RadioChinaScreen({super.key});

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
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 22),
        ),
        title: const Text(
          '🇨🇳 중국 라디오',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _chinaStations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final station = _chinaStations[index];
          final rs = _toRadioStation(station);
          final current = radioProvider.currentStation;
          final isPlaying = current?.name == station.name && radioProvider.isPlaying;
          return _StationTile(
            station: station,
            isPlaying: isPlaying,
            radioStation: rs,
            stationList: _chinaStations.map(_toRadioStation).toList(),
            stationIndex: index,
          );
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

  static RadioStation _toRadioStation(_CStation s) {
    return RadioStation.fromJson({
      'stationuuid': 'cn_${s.name.hashCode.abs()}',
      'name': s.name,
      'url': s.streamUrl,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': '',
      'country': 'China',
      'countrycode': 'CN',
      'codec': '',
      'bitrate': 0,
      'hls': 1,
      'votes': 0,
      'lastcheckok': 1,
    });
  }
}

class _StationTile extends StatelessWidget {
  final _CStation station;
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

    return Material(
      color: isPlaying ? primaryColor.withOpacity(0.12) : AppTheme.cardColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPlaying ? primaryColor : primaryColor.withOpacity(0.08),
              width: isPlaying ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🇨🇳', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        color: isPlaying ? primaryColor : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      station.nameKr,
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                const Icon(Icons.graphic_eq, color: Colors.redAccent, size: 24)
              else
                Icon(Icons.play_circle_outline, color: AppTheme.textHint, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CStation {
  final String name;
  final String nameKr;
  final String streamUrl;

  const _CStation({
    required this.name,
    required this.nameKr,
    required this.streamUrl,
  });
}

const _chinaStations = <_CStation>[
  // ══════ CNR 중앙인민방송 ══════
  _CStation(name: '中国之声', nameKr: 'CNR-1 종합뉴스', streamUrl: 'https://ngcdn001.cnr.cn/live/zgzs/index.m3u8'),
  _CStation(name: '经济之声', nameKr: 'CNR-2 경제', streamUrl: 'https://ngcdn002.cnr.cn/live/jjzs/index.m3u8'),
  _CStation(name: '音乐之声', nameKr: 'CNR-3 음악', streamUrl: 'https://ngcdn003.cnr.cn/live/yyzs/index.m3u8'),
  _CStation(name: '经典音乐广播', nameKr: 'CNR-4 클래식', streamUrl: 'https://ngcdn004.cnr.cn/live/dszs/index.m3u8'),
  _CStation(name: '民族之声', nameKr: 'CNR-8 민족', streamUrl: 'https://ngcdn009.cnr.cn/live/mzzs/index.m3u8'),
  _CStation(name: '中国交通广播', nameKr: 'CNR 교통', streamUrl: 'https://ngcdn016.cnr.cn/live/gsgljtgb/index.m3u8'),
  _CStation(name: '中国乡村之声', nameKr: 'CNR 농촌', streamUrl: 'https://ngcdn017.cnr.cn/live/xczs/index.m3u8'),
  _CStation(name: '华夏之声', nameKr: 'CNR 화하', streamUrl: 'https://ngcdn007.cnr.cn/live/hxzs/index.m3u8'),
  _CStation(name: '香港之声', nameKr: 'CNR 홍콩', streamUrl: 'https://ngcdn008.cnr.cn/live/xgzs/index.m3u8'),
  _CStation(name: '环球资讯广播', nameKr: 'CRI 환구자문', streamUrl: 'https://cnlive.cnr.cn/hls/huanqiuzixunguangbo.m3u8'),
];