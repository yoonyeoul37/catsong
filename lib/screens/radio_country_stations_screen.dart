import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/radio_station.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_logo.dart';
import '../widgets/heart_pop.dart';
import '../widgets/radio_dice.dart';
import 'radio_saved_songs_screen.dart';
import 'radio_player_screen.dart';
import 'radio_home_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../l10n/locale_holder.dart';

class RadioCountryStationsScreen extends StatefulWidget {
  final RadioCountry country;
  const RadioCountryStationsScreen({super.key, required this.country});

  @override
  State<RadioCountryStationsScreen> createState() =>
      _RadioCountryStationsScreenState();
}

enum _ViewMode { all, broadcaster, region, recent, favorite, saved }

class _RadioCountryStationsScreenState
    extends State<RadioCountryStationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _ViewMode _mode = _ViewMode.all;
  bool _showSearch = false; // 돋보기 눌렀을 때만 검색칸 보이기
  String? _worldDiceChoice; // 주사위로 나온 방송 (사진 카드에 그대로)
  // 칩: 인기 · 장르 · 지역 · 언어
  String _chip = 'pop';
  String? _sub;
  final ScrollController _listCtrl = ScrollController();
  // 주사위: 처음 소개 팝업 · NEW 표시
  bool _diceIntro = false;
  bool _diceNew = false;
  // 인기 칩 안 두 탭 · 이 나라에서 마지막으로 고른 칩
  static const String _popMost = '많이 듣는', _popTrend = '요즘 뜨는';
  String? _savedChip;
  bool get _isTrend => _chip == 'pop' && _sub == _popTrend;
  Timer? _clock; // 현지 시각을 계속 맞춤
  /// 현지 시각 글자 (이 값만 바뀌어서 목록 전체가 다시 그려지지 않게)
  final ValueNotifier<String?> _timeNow = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioProvider>().fetchTopStations(widget.country.code);
    });
    _loadDiceFlags();
    _loadChip();
    if (_localTimeText(widget.country.code) != null) {
      _timeNow.value = _localTimeText(widget.country.code);
      _clock = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) _timeNow.value = _localTimeText(widget.country.code);
      });
    }
    // 목록 끝에 가까워지면 다음 200개
    _listCtrl.addListener(() {
      if (!_listCtrl.hasClients || _isTrend) return;
      final p = _listCtrl.position;
      if (p.pixels > p.maxScrollExtent - 600) {
        context.read<RadioProvider>().fetchMoreCountryStations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listCtrl.dispose();
    _clock?.cancel();
    _timeNow.dispose();
    super.dispose();
  }

  Widget _buildModeBody(BuildContext context, RadioProvider radioProvider,
      List<RadioStation> allStations, Color baseColor, bool isDarkMode, Color primaryColor) {
    if (_mode == _ViewMode.saved) return const RadioSavedSongsList();
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
        final st = _stateOf(s);
        if (st.isEmpty) continue;
        grouped.putIfAbsent(st, () => []).add(s);
      }
      final keys = grouped.keys.toList()..sort();
      if (keys.isEmpty) {
        return Center(
          child: Text(tr.noRegionStations,
              style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 14)),
        );
      }
      return _buildGroupGrid(context, keys, grouped, baseColor, isDarkMode);
    } else if (_mode == _ViewMode.favorite) {
      // 즐겨찾기: 모든 나라 것 전부
      final favs = radioProvider.favorites;
      if (favs.isEmpty) {
        return Center(
          child: Text(tr.favAddHint,
              style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 14)),
        );
      }
      final current = radioProvider.currentStation;
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 80 + MediaQuery.of(context).padding.bottom),
        itemCount: favs.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: baseColor.withOpacity(0.16)),
        itemBuilder: (context, index) {
          final station = favs[index];
          final isPlaying = current?.stationUuid == station.stationUuid;
          return _StationTile(
            station: station,
            isPlaying: isPlaying,
            stationList: favs,
            stationIndex: index,
          );
        },
      );
    } else {
      final recent = radioProvider.recentlyListened
          .where((s) => s.countryCode == widget.country.code)
          .toList();
      if (recent.isEmpty) {
        return Center(
          child: Text(tr.noRecentStations,
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
                  tr.channelsCount(list.length),
                  style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Text(
                  key == '기타' ? tr.categoryEtc : key,
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

  // ── 장르: 라디오 정보의 태그를 알기 쉬운 이름으로 묶기 ──
  static const List<(String, List<String>)> _genreMap = [
    ('뉴스', ['news']),
    ('토크', ['talk']),
    ('스포츠', ['sport']),
    ('팝', ['pop']),
    ('인기곡', ['hits', 'top 40', 'top40', 'chart']),
    ('록', ['rock']),
    ('재즈', ['jazz']),
    ('클래식', ['classical', 'orchestra', 'opera']),
    ('댄스·일렉', ['dance', 'edm', 'electronic', 'house', 'techno', 'trance']),
    ('힙합', ['hip hop', 'hiphop', 'hip-hop', 'rap']),
    ('R&B·소울', ['r&b', 'rnb', 'soul']),
    ('라틴', ['latin', 'salsa', 'reggaeton', 'bachata', 'cumbia']),
    ('컨트리', ['country']),
    ('올디스', ['oldies', '60s', '70s', '80s', '90s', 'retro']),
    ('라운지', ['lounge', 'chill', 'ambient', 'easy listening']),
    ('포크', ['folk']),
    ('블루스', ['blues']),
    ('레게', ['reggae']),
    ('메탈', ['metal']),
    ('종교', ['religio', 'christian', 'gospel', 'catholic', 'islam', 'quran', 'worship']),
    ('어린이', ['kids', 'children']),
    ('볼리우드', ['bollywood']),
    ('세르타네주', ['sertanejo']),
    ('K-POP', ['kpop', 'k-pop']),
    ('J-POP', ['jpop', 'j-pop', 'anime']),
  ];

  Set<String> _genresOf(RadioStation s) {
    final tags = (s.tags ?? '')
        .toLowerCase()
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final out = <String>{};
    if (tags.isEmpty) return out;
    for (final g in _genreMap) {
      if (tags.any((t) => g.$2.any((k) => t.contains(k)))) out.add(g.$1);
    }
    return out;
  }

  static const Map<String, String> _langKo = {
    'english': '영어', 'spanish': '스페인어', 'portuguese': '포르투갈어', 'french': '프랑스어',
    'german': '독일어', 'italian': '이탈리아어', 'hindi': '힌디어', 'tamil': '타밀어',
    'telugu': '텔루구어', 'malayalam': '말라얄람어', 'bengali': '벵골어', 'marathi': '마라티어',
    'kannada': '칸나다어', 'punjabi': '펀자브어', 'gujarati': '구자라트어', 'urdu': '우르두어',
    'japanese': '일본어', 'chinese': '중국어', 'mandarin': '중국어', 'cantonese': '광둥어',
    'korean': '한국어', 'vietnamese': '베트남어', 'thai': '태국어', 'indonesian': '인도네시아어',
    'malay': '말레이어', 'javanese': '자바어', 'arabic': '아랍어', 'russian': '러시아어',
    'ukrainian': '우크라이나어', 'dutch': '네덜란드어', 'catalan': '카탈루냐어', 'basque': '바스크어',
    'galician': '갈리시아어', 'swiss german': '스위스 독일어', 'romansh': '로망슈어', 'turkish': '터키어',
    'polish': '폴란드어', 'swedish': '스웨덴어', 'welsh': '웨일스어', 'irish': '아일랜드어',
    'filipino': '필리핀어', 'tagalog': '타갈로그어', 'persian': '페르시아어', 'hebrew': '히브리어',
    'greek': '그리스어',
  };

  String _langName(String raw) {
    final k = raw.toLowerCase().trim();
    if (k.isEmpty) return '';
    final loc = tr.localeName;
    final map = loc.startsWith('ko')
        ? _langKo
        : loc.startsWith('ja')
            ? _langJa
            : loc == 'zh_Hant'
                ? _langZhHant
                : loc.startsWith('zh')
                    ? _langZh
                    : const <String, String>{};
    return map[k] ?? (k[0].toUpperCase() + k.substring(1));
  }

  static const Map<String, String> _langJa = {
    'english': '英語', 'spanish': 'スペイン語', 'portuguese': 'ポルトガル語', 'french': 'フランス語',
    'german': 'ドイツ語', 'italian': 'イタリア語', 'hindi': 'ヒンディー語', 'tamil': 'タミル語',
    'telugu': 'テルグ語', 'malayalam': 'マラヤーラム語', 'bengali': 'ベンガル語', 'marathi': 'マラーティー語',
    'kannada': 'カンナダ語', 'punjabi': 'パンジャーブ語', 'gujarati': 'グジャラート語', 'urdu': 'ウルドゥー語',
    'japanese': '日本語', 'chinese': '中国語', 'mandarin': '中国語', 'cantonese': '広東語',
    'korean': '韓国語', 'vietnamese': 'ベトナム語', 'thai': 'タイ語', 'indonesian': 'インドネシア語',
    'malay': 'マレー語', 'javanese': 'ジャワ語', 'arabic': 'アラビア語', 'russian': 'ロシア語',
    'ukrainian': 'ウクライナ語', 'dutch': 'オランダ語', 'catalan': 'カタルーニャ語', 'basque': 'バスク語',
    'galician': 'ガリシア語', 'swiss german': 'スイスドイツ語', 'romansh': 'ロマンシュ語', 'turkish': 'トルコ語',
    'polish': 'ポーランド語', 'swedish': 'スウェーデン語', 'welsh': 'ウェールズ語', 'irish': 'アイルランド語',
    'filipino': 'フィリピン語', 'tagalog': 'タガログ語', 'persian': 'ペルシャ語', 'hebrew': 'ヘブライ語',
    'greek': 'ギリシャ語',
  };

  static const Map<String, String> _langZh = {
    'english': '英语', 'spanish': '西班牙语', 'portuguese': '葡萄牙语', 'french': '法语',
    'german': '德语', 'italian': '意大利语', 'hindi': '印地语', 'tamil': '泰米尔语',
    'telugu': '泰卢固语', 'malayalam': '马拉雅拉姆语', 'bengali': '孟加拉语', 'marathi': '马拉地语',
    'kannada': '卡纳达语', 'punjabi': '旁遮普语', 'gujarati': '古吉拉特语', 'urdu': '乌尔都语',
    'japanese': '日语', 'chinese': '中文', 'mandarin': '普通话', 'cantonese': '粤语',
    'korean': '韩语', 'vietnamese': '越南语', 'thai': '泰语', 'indonesian': '印尼语',
    'malay': '马来语', 'javanese': '爪哇语', 'arabic': '阿拉伯语', 'russian': '俄语',
    'ukrainian': '乌克兰语', 'dutch': '荷兰语', 'catalan': '加泰罗尼亚语', 'basque': '巴斯克语',
    'galician': '加利西亚语', 'swiss german': '瑞士德语', 'romansh': '罗曼什语', 'turkish': '土耳其语',
    'polish': '波兰语', 'swedish': '瑞典语', 'welsh': '威尔士语', 'irish': '爱尔兰语',
    'filipino': '菲律宾语', 'tagalog': '他加禄语', 'persian': '波斯语', 'hebrew': '希伯来语',
    'greek': '希腊语',
  };

  static const Map<String, String> _langZhHant = {
    'english': '英語', 'spanish': '西班牙語', 'portuguese': '葡萄牙語', 'french': '法語',
    'german': '德語', 'italian': '義大利語', 'hindi': '印地語', 'tamil': '坦米爾語',
    'telugu': '泰盧固語', 'malayalam': '馬拉雅拉姆語', 'bengali': '孟加拉語', 'marathi': '馬拉地語',
    'kannada': '卡納達語', 'punjabi': '旁遮普語', 'gujarati': '古吉拉特語', 'urdu': '烏爾都語',
    'japanese': '日語', 'chinese': '中文', 'mandarin': '國語', 'cantonese': '粵語',
    'korean': '韓語', 'vietnamese': '越南語', 'thai': '泰語', 'indonesian': '印尼語',
    'malay': '馬來語', 'javanese': '爪哇語', 'arabic': '阿拉伯語', 'russian': '俄語',
    'ukrainian': '烏克蘭語', 'dutch': '荷蘭語', 'catalan': '加泰隆尼亞語', 'basque': '巴斯克語',
    'galician': '加利西亞語', 'swiss german': '瑞士德語', 'romansh': '羅曼什語', 'turkish': '土耳其語',
    'polish': '波蘭語', 'swedish': '瑞典語', 'welsh': '威爾斯語', 'irish': '愛爾蘭語',
    'filipino': '菲律賓語', 'tagalog': '他加祿語', 'persian': '波斯語', 'hebrew': '希伯來語',
    'greek': '希臘語',
  };

  /// 칩 아래 글자 (저장은 한국어 그대로, 화면엔 언어에 맞게)
  String _subLabel(String v) => switch (v) {
        _popMost => tr.popMost,
        _popTrend => tr.popTrend,
        '즐겨찾기' => tr.favorites,
        '최근청취' => tr.recentListened,
        '저장한 곡' => tr.savedSongs,
        '뉴스' => tr.genreNews,
        '토크' => tr.genreTalk,
        '스포츠' => tr.genreSports,
        '팝' => tr.genrePop,
        '인기곡' => tr.genreHits,
        '록' => tr.genreRock,
        '재즈' => tr.genreJazz,
        '클래식' => tr.genreClassical,
        '댄스·일렉' => tr.genreDance,
        '힙합' => tr.genreHiphop,
        'R&B·소울' => tr.genreRnb,
        '라틴' => tr.genreLatin,
        '컨트리' => tr.genreCountry,
        '올디스' => tr.genreOldies,
        '라운지' => tr.genreLounge,
        '포크' => tr.genreFolk,
        '블루스' => tr.genreBlues,
        '레게' => tr.genreReggae,
        '메탈' => tr.genreMetal,
        '종교' => tr.genreReligious,
        '어린이' => tr.genreKids,
        '볼리우드' => tr.genreBollywood,
        '세르타네주' => tr.genreSertanejo,
        _ => v,
      };

  /// 방송국 지역 이름을 하나로 맞추기 (대소문자·띄어쓰기·미국 주 약자)
  String _stateOf(RadioStation s) => RadioProvider.normState(s.state ?? '', widget.country.code);

  /// 칩마다 고를 항목 (이름, 방송 수) — 자료가 충분한 나라만
  List<(String, int)> _optionsFor(String chip, List<RadioStation> all, RadioProvider radio) {
    // 지역: 서버가 알려준 이 나라 지역 전부 (방송 많은 순)
    if (chip == 'region' && radio.countryStates.length >= 2) {
      final l = radio.countryStates.entries.map((e) => (e.key, e.value)).toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));
      return l.take(100).toList();
    }
    final counts = <String, int>{};
    void add(String k) {
      if (k.isNotEmpty) counts[k] = (counts[k] ?? 0) + 1;
    }

    var withInfo = 0;
    for (final s in all) {
      if (chip == 'genre') {
        for (final g in _genresOf(s)) {
          add(g);
        }
      } else if (chip == 'region') {
        final st = _stateOf(s);
        if (st.isNotEmpty) {
          withInfo++;
          add(st);
        }
      } else if (chip == 'lang') {
        add(_langName(radio.languageOf(s.stationUuid)));
      }
    }
    final min = chip == 'region' ? 3 : 5;
    final list = counts.entries.where((e) => e.value >= min).map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    if (chip == 'genre' && list.length < 3) return const [];
    if (chip == 'region' && _chip != 'region' &&
        (list.length < 2 || (withInfo < 20 && withInfo < all.length * 0.3))) return const [];
    if (chip == 'lang' && list.length < 2) return const [];
    return list.take(chip == 'region' ? 30 : 10).toList();
  }

  bool _matches(RadioStation s, RadioProvider radio) {
    final sub = _sub;
    if (_chip == 'pop' || sub == null) return true;
    if (_chip == 'genre') return _genresOf(s).contains(sub);
    if (_chip == 'region') return _stateOf(s) == sub;
    return _langName(radio.languageOf(s.stationUuid)) == sub;
  }

  static String _fmtNum(int n) =>
      n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  // '내 라디오' 아래 탭: 즐겨찾기 · 최근청취 · 저장한 곡
  static const List<(String, _ViewMode)> _mineTabs = [
    ('즐겨찾기', _ViewMode.favorite),
    ('최근청취', _ViewMode.recent),
    ('저장한 곡', _ViewMode.saved),
  ];

  /// 글자 탭 한 줄 (고른 것만 진하게 + 밑줄) + 점으로 나눈 아래 탭
  /// 번역해서 글자가 길어져도 줄바꿈 없이 옆으로 밀어서 보게 함
  Widget _chipBar(List<RadioStation> all, RadioProvider radio, Color baseColor, bool isDarkMode) {
    final opts = <String, List<(String, int)>>{
      'genre': _optionsFor('genre', all, radio),
      'region': _optionsFor('region', all, radio),
      'lang': _optionsFor('lang', all, radio),
    };
    final names = {'mine': tr.myRadio, 'pop': tr.popularTab, 'genre': tr.genreTab, 'region': tr.regionTab, 'lang': tr.languageTab};
    final chips = ['mine', 'pop', for (final k in ['genre', 'region', 'lang']) if (opts[k]!.isNotEmpty) k];
    final popOpts = _hasTrend(all, radio) ? const [(_popMost, 0), (_popTrend, 0)] : const <(String, int)>[];
    final code = widget.country.code;
    final mineCounts = [
      radio.favorites.length,
      radio.recentlyListened.where((s) => s.countryCode == code).length,
      radio.savedSongs.length,
    ];
    final List<(String, int)> cur = _chip == 'mine'
        ? [for (var i = 0; i < _mineTabs.length; i++) (_mineTabs[i].$1, mineCounts[i])]
        : _chip == 'pop'
            ? popOpts
            : (opts[_chip] ?? const <(String, int)>[]);
    final selSub = _chip == 'mine'
        ? _mineTabs.firstWhere((t) => t.$2 == _mode, orElse: () => _mineTabs.first).$1
        : _chip == 'pop'
            ? (_sub ?? _popMost)
            : _sub;

    void toTop() {
      if (_listCtrl.hasClients) _listCtrl.jumpTo(0);
    }

    void pickChip(String c) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      setState(() {
        _chip = c;
        if (c == 'mine') {
          _mode = _ViewMode.favorite;
          _sub = null;
        } else {
          _mode = _ViewMode.all;
          final o = opts[c] ?? const <(String, int)>[];
          _sub = o.isEmpty ? null : o.first.$1;
        }
        _savedChip = null;
      });
      if (c != 'mine') _saveChip();
      toTop();
    }

    void pickSub(String name) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      setState(() {
        if (_chip == 'mine') {
          _mode = _mineTabs.firstWhere((t) => t.$1 == name).$2;
        } else {
          _sub = name;
        }
        _savedChip = null;
      });
      if (_chip != 'mine') _saveChip();
      toTop();
    }

    final dim = baseColor.withOpacity(0.38);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 위 줄: 글자 탭
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pickChip(c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 22),
                      padding: const EdgeInsets.only(top: 6, bottom: 9),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _chip == c ? baseColor : Colors.transparent, width: 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c == 'mine') ...[
                            Icon(_chip == c ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                size: 14, color: _chip == c ? baseColor : dim),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            names[c]!,
                            softWrap: false,
                            style: TextStyle(
                              color: _chip == c ? baseColor : dim,
                              fontSize: 15,
                              fontWeight: _chip == c ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 아래 줄: 점(·)으로만 나눈 가벼운 탭
        if (cur.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < cur.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(color: baseColor.withOpacity(0.25), shape: BoxShape.circle),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pickSub(cur[i].$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: _subLabel(cur[i].$1)),
                          if (cur[i].$2 > 0)
                            TextSpan(
                              text: ' ${cur[i].$2}',
                              style: TextStyle(
                                  fontSize: 11, color: baseColor.withOpacity(0.35), fontWeight: FontWeight.w500),
                            ),
                        ]),
                        softWrap: false,
                        style: TextStyle(
                          color: selSub == cur[i].$1 ? baseColor : baseColor.withOpacity(0.42),
                          fontSize: 13,
                          fontWeight: selSub == cur[i].$1 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
      ],
    );
  }

  // ── 인기 칩 안: 많이 듣는 · 요즘 뜨는 ──
  bool _hasTrend(List<RadioStation> all, RadioProvider radio) =>
      all.where((s) => radio.trendOf(s.stationUuid) > 0).length >= 5;

  // ── 나라마다 마지막으로 고른 칩 기억 ──
  String get _chipKey => 'radioChip_${widget.country.code}';

  Future<void> _loadChip() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_chipKey);
    if (v != null && mounted) setState(() => _savedChip = v);
  }

  void _saveChip() {
    final v = '$_chip|${_sub ?? ''}';
    SharedPreferences.getInstance().then((p) => p.setString(_chipKey, v));
  }

  /// 방송을 불러온 뒤 한 번: 저장해 둔 칩이 이 나라에 있으면 다시 골라 줌
  void _restoreChip(List<RadioStation> all, RadioProvider radio) {
    final v = _savedChip;
    if (v == null) return;
    _savedChip = null;
    final i = v.indexOf('|');
    final chip = i < 0 ? v : v.substring(0, i);
    final sub = i < 0 ? '' : v.substring(i + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (chip == 'pop') {
        if (sub == _popTrend && _hasTrend(all, radio)) setState(() => _sub = _popTrend);
        return;
      }
      final opts = _optionsFor(chip, all, radio);
      if (opts.isEmpty) return;
      setState(() {
        _chip = chip;
        _sub = opts.any((o) => o.$1 == sub) ? sub : opts.first.$1;
      });
    });
  }

  // ───── 맨 위 사진 카드 (한국 라디오와 같은 모양) ─────
  Widget _worldHero(BuildContext context, RadioProvider radio, List<RadioStation> all) {
    final code = widget.country.code;
    final curUuid = radio.currentStation?.stationUuid;
    RadioStation? pick;
    String why;
    // ① 주사위로 고른 방송
    if (_worldDiceChoice != null) {
      for (final st in [...all, if (radio.currentStation != null) radio.currentStation!]) {
        if (st.stationUuid == _worldDiceChoice) {
          pick = st;
          break;
        }
      }
    }
    if (pick != null) {
      why = tr.heroDicePick;
    } else {
      why = tr.heroTopN(1);
      // ② 이 나라에서 들었던 방송 (지금 듣는 건 빼기)
      for (final r in radio.recentlyListened) {
        if (r.countryCode == code && r.stationUuid != curUuid) {
          pick = r;
          why = tr.heroRecent;
          break;
        }
      }
      // ③ 인기 1위
      if (pick == null) {
        for (final st in all) {
          if (st.stationUuid != curUuid) {
            pick = st;
            break;
          }
        }
        pick ??= all.first;
        why = tr.heroTopN(all.indexOf(pick) <= 0 ? 1 : all.indexOf(pick) + 1);
      }
    }
    final st = pick!;
    // 사진·이름표: 그 나라 현지 시간 기준
    final h = _localHour(code) ?? DateTime.now().hour;
    final slot = h >= 5 && h < 11 ? 0 : h >= 11 && h < 17 ? 1 : h >= 17 && h < 22 ? 2 : 3;
    final slotName = [tr.slotMorning, tr.slotDay, tr.slotEvening, tr.slotNight];
    const photos = [
      'assets/radio_hero_morning.jpg',
      'assets/radio_hero_day.jpg',
      'assets/radio_hero_evening.jpg',
      'assets/radio_hero_night.jpg',
    ];
    final cname = widget.country.displayName;
    final last = cname.isEmpty ? 0 : cname.codeUnitAt(cname.length - 1);
    final hangul = last >= 0xAC00 && last <= 0xD7A3;
    final josa = hangul ? (((last - 0xAC00) % 28) != 0 ? '은' : '는') : '';
    final label = why == tr.heroDicePick
        ? why
        : tr.localeName.startsWith('ko')
            ? '지금 $cname$josa ${slotName[slot]} · $why'
            : tr.heroNowIn(cname, slotName[slot], why);
    final sub = [
      if (st.state?.trim().isNotEmpty ?? false) st.state!.trim(),
      ..._genresOf(st).take(1).map(_subLabel),
    ].join(' · ');
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    const ink = Color(0xFF17140F);
    void open() {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      final list = all.any((x) => x.stationUuid == st.stationUuid) ? all : [st, ...all];
      final i = math.max(0, list.indexWhere((x) => x.stationUuid == st.stationUuid));
      context.read<RadioProvider>().setQueue(list, i);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => RadioPlayerScreen(station: st, stationList: list, currentIndex: i),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: GestureDetector(
        onTap: open,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ink.withOpacity(isDark ? 0.45 : 0.13),
                blurRadius: 20,
                spreadRadius: -3,
                offset: const Offset(0, 10),
              ),
              BoxShadow(color: ink.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 68, // 사진은 글자 띠 위에만
                  child: Image.asset(
                    photos[slot],
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),
                  ),
                ),
                // 사진 아래 크림 띠
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
                    color: const Color(0xFFFBF8F2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                              const SizedBox(height: 1),
                              Text(st.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                              if (sub.isNotEmpty)
                                Text(sub,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(color: ink.withOpacity(0.62), fontSize: 12)),
                            ],
                          ),
                        ),
                        // 🎲 주사위
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openWorldDice(all),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Color(0xFFEDE7DA), shape: BoxShape.circle),
                            child: const RollDiceIcon(size: 21, color: ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ▶ 듣기
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFF4EFE5), size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 맨 위 '다시 듣기': 이 나라에서 최근 들은 방송 + 즐겨찾기 ──
  List<RadioStation> _againList(RadioProvider radio) {
    final code = widget.country.code;
    final seen = <String>{};
    return [
      ...radio.recentlyListened.where((s) => s.countryCode == code),
      ...radio.favorites.where((s) => s.countryCode == code),
    ].where((s) => seen.add(s.stationUuid)).take(12).toList();
  }

  Widget _againRow(List<RadioStation> list, RadioProvider radio, Color baseColor) {
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final cur = radio.currentStation?.stationUuid;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.dailyListenAgain,
              style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 62 + MediaQuery.textScalerOf(context).scale(16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final s = list[i];
                final on = s.stationUuid == cur;
                return GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    radio.setQueue(list, i);
                    // 처음 누르면 바로 재생, 듣는 중인 방송을 또 누르면 상세 화면
                    if (!on) {
                      radio.playStation(s);
                      return;
                    }
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => RadioPlayerScreen(station: s, stationList: list, currentIndex: i),
                        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 54,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: on ? accent : Colors.transparent, width: 2),
                          ),
                          child: StationLogo(logoUrl: s.logoUrl, name: s.name, size: 46),
                        ),
                        const SizedBox(height: 5),
                        Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: on ? accent : baseColor.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: baseColor.withOpacity(0.16)),
        ],
      ),
    );
  }

  /// 목록 맨 아래: 다음 방송 불러오는 중
  Widget _loadMoreRow(Color baseColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: baseColor.withOpacity(0.35)),
          ),
          const SizedBox(width: 8),
          Text(tr.loadingMoreStations, style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 12)),
        ],
      ),
    );
  }

  // ── 해외 라디오 주사위: 이 나라 인기 음악 방송 중 하나 ──
  static const Set<String> _notMusic = {'뉴스', '토크', '스포츠', '종교', '어린이'};

  List<DiceStation> _worldDicePool(List<RadioStation> all) {
    final music = <RadioStation>[], plain = <RadioStation>[];
    for (final s in all.take(400)) {
      final g = _genresOf(s);
      if (g.any(_notMusic.contains)) continue; // 뉴스·토크·종교 등은 빼기
      (g.isEmpty ? plain : music).add(s);
    }
    var list = music.take(150).toList();
    if (list.length < 10) list = [...list, ...plain].take(150).toList(); // 장르 정보가 적은 나라
    final c = widget.country;
    final time = _localTimeText(c.code);
    return [
      for (final s in list)
        DiceStation(
          station: s,
          badge: c.flag,
          badgeSize: 20,
          frequency: [
            (s.state?.trim().isNotEmpty ?? false) ? s.state!.trim() : c.displayName,
            if (time != null) time,
          ].join(' · '),
          programLabel: tr.nowPlayingSong,
          emptyProgram: tr.noSongInfoYet,
          program: (r) =>
              r.currentStation?.stationUuid == s.stationUuid ? (r.streamTitle ?? '').trim() : '',
        ),
    ];
  }

  // 소개 팝업은 한 번만 (한국 라디오와 같이 씀) · NEW는 7일 안에 3번 던질 때까지
  Future<void> _loadDiceFlags() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    var first = p.getInt('worldDiceNewFrom');
    if (first == null) {
      first = now;
      await p.setInt('worldDiceNewFrom', now);
    }
    final count = p.getInt('worldDiceCount') ?? 0;
    final days = (now - first) / 86400000;
    if (!mounted) return;
    setState(() {
      _diceNew = count < 3 && days < 7;
      _diceIntro = !(p.getBool('radioDiceIntroSeen') ?? false);
    });
  }

  Future<void> _diceUsed() async {
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt('worldDiceCount') ?? 0) + 1;
    await p.setInt('worldDiceCount', count);
    await p.setBool('radioDiceIntroSeen', true);
    if (!mounted) return;
    setState(() {
      _diceIntro = false;
      if (count >= 3) _diceNew = false;
    });
  }

  Future<void> _closeDiceIntro() async {
    setState(() => _diceIntro = false);
    final p = await SharedPreferences.getInstance();
    await p.setBool('radioDiceIntroSeen', true);
  }

  Future<void> _openWorldDice(List<RadioStation> all) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    _diceUsed();
    final pool = _worldDicePool(all);
    if (pool.isEmpty) return;
    final list = [for (final d in pool) d.station];
    await showRadioDice(context, pool, onOpen: (st) {
      if (!mounted) return;
      final i = math.max(0, list.indexWhere((x) => x.stationUuid == st.stationUuid));
      context.read<RadioProvider>().setQueue(list, i);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => RadioPlayerScreen(station: st, stationList: list, currentIndex: i),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    });
    // 판이 닫히면: 주사위로 나와서 듣는 방송을 카드에 그대로
    if (!mounted) return;
    final cur = context.read<RadioProvider>().currentStation;
    if (cur != null && cur.countryCode == widget.country.code) {
      setState(() => _worldDiceChoice = cur.stationUuid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final allStations = radioProvider.countryStations;
    var stations = allStations
        .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
        .where((s) => _matches(s, radioProvider))
        .toList();
    // 요즘 뜨는: 최근 이틀 사이 듣는 사람이 많이 늘어난 순
    if (_isTrend) {
      stations = stations.where((s) => radioProvider.trendOf(s.stationUuid) > 0).toList()
        ..sort((a, b) => radioProvider.trendOf(b.stationUuid).compareTo(radioProvider.trendOf(a.stationUuid)));
    }
    // 지역을 고르면 그 지역 방송을 서버에서 따로 불러오기
    final regionSub = (_chip == 'region' && radioProvider.countryStates.isNotEmpty) ? _sub : null;
    if (regionSub != null && !radioProvider.stateTried(regionSub)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<RadioProvider>().fetchStateStations(regionSub);
      });
    }
    // 찾는 방송이 적게 보이면 다음 방송을 자동으로 더 불러오기 (2000개까지)
    if ((_query.isNotEmpty || _chip != 'pop') &&
        regionSub == null &&
        stations.length < 20 &&
        radioProvider.countryHasMore &&
        !radioProvider.isLoadingMoreCountry &&
        allStations.length < 2000) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<RadioProvider>().fetchMoreCountryStations();
      });
    }
    final isLoading = radioProvider.isLoadingCountryStations ||
        (stations.isEmpty && regionSub != null && radioProvider.isStateLoading(regionSub));
    final current = radioProvider.currentStation;
    if (!isLoading && allStations.isNotEmpty) _restoreChip(allStations, radioProvider);
    final again = (_chip == 'pop' && !_isTrend && _query.isEmpty)
        ? _againList(radioProvider)
        : const <RadioStation>[];
    // 사진 카드: '인기(많이 듣는)'에서만, 검색 중이 아닐 때
    final showHero = _chip == 'pop' && !_isTrend && _query.isEmpty && allStations.isNotEmpty && !isLoading;
    final head = (showHero ? 1 : 0) + (again.isEmpty ? 0 : 1);
    final localTime = _localTimeText(widget.country.code);
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);

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
          systemNavigationBarColor: Color(0xFFEDE7DA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 상세페이지에서 돌아와도 하단 시스템바 색을 항상 다시 맞춤
      value: context.watch<ThemeProvider>().systemBarStyle,
      child: Scaffold(
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
              color: baseColor, size: 18),
        ),
        // 나라 이름 (누르면 나라 고르기) — 긴 이름은 … 로 줄임
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.country.displayName,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: baseColor.withOpacity(0.5)),
            ],
          ),
        ),
        actions: [
          // 주사위는 맨 위 사진 카드 안으로 옮김
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
            icon: Icon(_showSearch ? Icons.close : Icons.search,
                color: baseColor, size: 20),
          ),
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: Icon(Icons.home_rounded, color: baseColor, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
      SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showSearch) Padding(
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
                    autofocus: true,
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
            const SizedBox(height: 2),
            _chipBar(allStations, radioProvider, baseColor, isDarkMode),
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
                        Expanded(
                          child: Text(
                          _isTrend
                              ? tr.trendingSort
                              : _chip == 'pop' && _query.isEmpty
                              ? tr.stationsPopular(_fmtNum(radioProvider.getCountryStationCount(widget.country.code) ?? stations.length))
                              : tr.countStr(_fmtNum(stations.length)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: baseColor.withOpacity(0.35), fontSize: 12.5),
                        ),
                        ),
                        // 그 나라 지금 시각 (오른쪽 끝)
                        if (localTime != null) ...[
                          const SizedBox(width: 10),
                          ValueListenableBuilder<String?>(
                            valueListenable: _timeNow,
                            builder: (_, t, __) => Text(t ?? localTime,
                                style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 12.5)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: _listCtrl,
                      padding:
                      EdgeInsets.fromLTRB(24, 0, 24, 80 + MediaQuery.of(context).padding.bottom),
                      itemCount: head + stations.length + (radioProvider.countryHasMore && !_isTrend ? 1 : 0),
                      separatorBuilder: (_, i) => i < head
                          ? const SizedBox.shrink()
                          : Divider(height: 1, color: baseColor.withOpacity(0.16)),
                      itemBuilder: (context, index) {
                        if (showHero && index == 0) return _worldHero(context, radioProvider, allStations);
                        if (index < head) return _againRow(again, radioProvider, baseColor);
                        index -= head;
                        if (index >= stations.length) return _loadMoreRow(baseColor);
                        final station = stations[index];
                        final isPlaying = current?.stationUuid ==
                            station.stationUuid;
                        return _StationTile(
                          key: ValueKey('$_chip|$_sub|${station.stationUuid}'),
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
          // 처음 들어왔을 때 한 번: 주사위 소개 (방송을 다 불러온 뒤)
          if (_diceIntro && !isLoading && allStations.isNotEmpty && _mode == _ViewMode.all)
            Positioned.fill(
              child: RadioDiceIntro(
                onThrow: () => _openWorldDice(allStations),
                onClose: _closeDiceIntro,
              ),
            ),
        ],
      ),
      bottomNavigationBar: current != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
    ),
    );
  }
}

// ── 현지 시각 (시간대가 하나인 나라만. 여러 시간대 나라는 안 보여줌) ──
const Map<String, double> _utcFixed = {
  'JP': 9, 'KR': 9, 'CN': 8, 'TW': 8, 'HK': 8, 'SG': 8, 'MY': 8, 'PH': 8, 'MN': 8,
  'TH': 7, 'VN': 7, 'KH': 7, 'LA': 7, 'MM': 6.5, 'BD': 6, 'NP': 5.75, 'IN': 5.5, 'LK': 5.5,
  'PK': 5, 'UZ': 5, 'KZ': 5, 'AE': 4, 'AZ': 4, 'AM': 4, 'GE': 4, 'IR': 3.5,
  'SA': 3, 'IQ': 3, 'JO': 3, 'TR': 3, 'KE': 3, 'ET': 3, 'TZ': 3, 'UG': 3, 'MG': 3,
  'ZA': 2, 'ZW': 2, 'MZ': 2, 'NG': 1, 'CM': 1, 'TN': 1, 'GH': 0, 'SN': 0, 'IS': 0,
  'AR': -3, 'UY': -3, 'VE': -4, 'BO': -4, 'DO': -4, 'PR': -4, 'TT': -4,
  'CO': -5, 'PE': -5, 'EC': -5, 'PA': -5, 'JM': -5,
  'GT': -6, 'HN': -6, 'NI': -6, 'SV': -6, 'CR': -6, 'PG': 10, 'FJ': 12,
};
// 유럽: 3월 마지막 일요일 ~ 10월 마지막 일요일은 한 시간 빠름
const Map<String, double> _utcEu = {
  'GB': 0, 'IE': 0, 'PT': 0,
  'ES': 1, 'FR': 1, 'DE': 1, 'IT': 1, 'NL': 1, 'BE': 1, 'LU': 1, 'CH': 1, 'AT': 1,
  'SE': 1, 'NO': 1, 'DK': 1, 'PL': 1, 'CZ': 1, 'SK': 1, 'HU': 1, 'HR': 1, 'SI': 1,
  'RS': 1, 'BA': 1, 'ME': 1, 'MK': 1, 'AL': 1, 'MT': 1,
  'FI': 2, 'EE': 2, 'LV': 2, 'LT': 2, 'RO': 2, 'BG': 2, 'GR': 2, 'CY': 2, 'UA': 2,
};

DateTime _lastSundayUtc(int y, int m) {
  final last = DateTime.utc(y, m + 1, 0); // 그 달 마지막 날
  return DateTime.utc(y, m, last.day - (last.weekday % 7), 1);
}

/// '현지 오후 3:12' (모르는 나라는 null)
String? _localTimeText(String code) {
  final now = DateTime.now().toUtc();
  var off = _utcFixed[code];
  if (off == null) {
    final eu = _utcEu[code];
    if (eu == null) return null;
    final summer = !now.isBefore(_lastSundayUtc(now.year, 3)) && now.isBefore(_lastSundayUtc(now.year, 10));
    off = eu + (summer ? 1 : 0);
  }
  final t = now.add(Duration(minutes: (off * 60).round()));
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return tr.localTime(tr.timeAmPm(t.hour < 12 ? tr.am : tr.pm, '$h12:${t.minute.toString().padLeft(2, '0')}'));
}

/// 현지 시각의 '시' (모르는 나라는 null) — 사진 카드 아침·낮·저녁·밤용
int? _localHour(String code) {
  final now = DateTime.now().toUtc();
  var off = _utcFixed[code];
  if (off == null) {
    final eu = _utcEu[code];
    if (eu == null) return null;
    final summer = !now.isBefore(_lastSundayUtc(now.year, 3)) && now.isBefore(_lastSundayUtc(now.year, 10));
    off = eu + (summer ? 1 : 0);
  }
  return now.add(Duration(minutes: (off * 60).round())).hour;
}

/// 이름 속 주파수 찾기 ('Power 98.7 FM' → 'FM 98.7', 'AM 1010 News' → 'AM 1010')
String? _freqFromName(String name) {
  String? check(String band, String num) {
    final v = double.tryParse(num.replaceAll(',', '.'));
    if (v == null) return null;
    if (band == 'FM' && v >= 76 && v <= 108) return 'FM ${num.replaceAll(',', '.')}';
    if (band == 'AM' && v >= 520 && v <= 1710 && v == v.roundToDouble()) return 'AM ${v.toInt()}';
    return null;
  }

  final a = RegExp(r'\b(FM|AM)\s*(\d{2,4}(?:[.,]\d{1,2})?)\b', caseSensitive: false).firstMatch(name);
  if (a != null) {
    final r = check(a.group(1)!.toUpperCase(), a.group(2)!);
    if (r != null) return r;
  }
  final b = RegExp(r'\b(\d{2,4}(?:[.,]\d{1,2})?)\s*(FM|AM|MHz)\b', caseSensitive: false).firstMatch(name);
  if (b != null) {
    final unit = b.group(2)!.toUpperCase();
    return check(unit == 'AM' ? 'AM' : 'FM', b.group(1)!);
  }
  return null;
}

class _StationTile extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final List<RadioStation> stationList;
  final int stationIndex;

  const _StationTile({
    super.key,
    required this.station,
    required this.isPlaying,
    required this.stationList,
    required this.stationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return _RiseIn(child: Container(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          final radio = context.read<RadioProvider>();
          radio.setQueue(stationList, stationIndex);
          // 처음 누르면 바로 재생만 (화면 안 바뀜)
          if (!isPlaying) {
            radio.playStation(station);
            return;
          }
          // 이미 재생 중인 방송국을 한 번 더 누르면 상세페이지로
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
              Stack(
                alignment: Alignment.center,
                children: [
                  StationLogo(
                      logoUrl: station.logoUrl,
                      name: station.name,
                      size: 46),
                  if (isPlaying)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(46 * 0.2),
                      ),
                      alignment: Alignment.center,
                      child: _PlayingBars(),
                    ),
                ],
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
                        color: isPlaying
                            ? (context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                                ? const Color(0xFF2F7DE8)
                                : context.watch<ThemeProvider>().primaryColor)
                            : baseColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Builder(builder: (context) {
                      // 두 번째 줄: 지금 방송 → 주파수 → 국가 순서로 있는 것만
                      final nowPlaying = context
                          .watch<RadioProvider>()
                          .nowPlayingFor(station.name);
                      final rawFreq = station.frequency;
                      final band = (rawFreq != null && rawFreq.isNotEmpty && rawFreq != 'null')
                          ? 'FM $rawFreq'
                          : _freqFromName(station.name);
                      final String sub;
                      if (nowPlaying != null && nowPlaying.isNotEmpty) {
                        sub = nowPlaying;
                      } else if (band != null) {
                        sub = [
                          band,
                          if (station.country != null && station.country!.isNotEmpty)
                            station.country!,
                        ].join(' · ');
                      } else {
                        // 장르 · 국가 (예: "Jazz · United Kingdom")
                        sub = [
                          if (station.genre.isNotEmpty) station.genre,
                          if (station.country != null && station.country!.isNotEmpty)
                            station.country!,
                        ].join(' · ');
                      }
                      // 음질 좋은 방송 (192kbps 이상)
                      final hq = (station.bitrate ?? 0) >= 192;
                      if (sub.isEmpty && !hq) return const SizedBox.shrink();
                      return Row(
                        children: [
                          if (hq) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
                              ),
                              child: Text('HQ',
                                  style: TextStyle(
                                      color: baseColor.withOpacity(0.55),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      height: 1.2)),
                            ),
                            if (sub.isNotEmpty) const SizedBox(width: 6),
                          ],
                          if (sub.isNotEmpty)
                            Flexible(
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.5), fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              IconButton(
                  icon: HeartPop(
                    on: context.watch<RadioProvider>().isFavorite(station.stationUuid),
                    child: Icon(
                      context
                          .watch<RadioProvider>()
                          .isFavorite(station.stationUuid)
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color: context
                          .watch<RadioProvider>()
                          .isFavorite(station.stationUuid)
                          ? const Color(0xFFE05A4F)
                          : baseColor.withOpacity(0.25),
                      size: 21,
                    ),
                  ),
                  onPressed: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate').catchError((_) {});
                    final radioProvider = context.read<RadioProvider>();
                    final wasFav = radioProvider.isFavorite(station.stationUuid);
                    // (하트가 바로 바뀌어서 따로 알림 없음)
                    Future.microtask(() => radioProvider.toggleFavorite(station));
                  },
                ),
            ],
          ),
        ),
      ),
    ));
  }
}

/// 방송 줄이 화면에 나타날 때 살포시 떠오르게 (곡 목록 song_list_tile.dart 와 같은 움직임)
class _RiseIn extends StatefulWidget {
  final Widget child;
  const _RiseIn({required this.child});

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late Animation<Offset> _slide;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;
  ScrollPosition? _pos;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    final curve = _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);
    // 처음 그려진 뒤: 화면에 보이는 줄은 바로 떠오르기
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(first: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.maybeOf(context)?.position;
    if (!identical(p, _pos)) {
      _pos?.removeListener(_check);
      _pos = p;
      if (!_started) _pos?.addListener(_check);
    }
  }

  @override
  void didUpdateWidget(covariant _RiseIn old) {
    super.didUpdateWidget(old);
    // 목록이 바뀌어 줄이 스크롤 없이 화면에 들어온 경우도 챙기기
    if (!_started) WidgetsBinding.instance.addPostFrameCallback((_) => _check(first: true));
  }

  /// 줄이 실제로 화면 안에 들어왔는지 보고 시작
  void _check({bool first = false}) {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final vp = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (vp is! RenderBox || !vp.hasSize) {
      _start(animate: true);
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: vp).dy;
    final h = vp.size.height;
    if (top + box.size.height <= 0 || top >= h) return; // 아직 화면 밖
    // 아래에서 들어오면 아래→위로, 위에서 들어오면 위→아래로 살포시
    final fromTop = !first && top <= h * 0.5;
    if (fromTop) {
      setState(() => _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(_curve));
    }
    _start(animate: true);
  }

  void _start({required bool animate}) {
    _started = true;
    _pos?.removeListener(_check);
    if (animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
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
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);

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
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// 상단바에 쓰는 작은 이퀄라이저 막대 (은은하게 움직임)
class _LogoEqBars extends StatefulWidget {
  const _LogoEqBars();

  @override
  State<_LogoEqBars> createState() => _LogoEqBarsState();
}

class _LogoEqBarsState extends State<_LogoEqBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = context.watch<ThemeProvider>().primaryColor;
    final eqColor = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final t = _c.value * 2 * math.pi + i * 1.3;
              final v = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t));
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: Container(
                  width: 3,
                  height: 14 * v,
                  decoration: BoxDecoration(
                    color: eqColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}