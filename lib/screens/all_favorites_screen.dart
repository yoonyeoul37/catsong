import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/radio_provider.dart';
import '../providers/music_provider.dart';
import '../widgets/station_tile.dart';
import 'favorites_screen.dart';
import 'nature_sound_detail_screen.dart';

class AllFavoritesScreen extends StatefulWidget {
  const AllFavoritesScreen({super.key});

  @override
  State<AllFavoritesScreen> createState() => _AllFavoritesScreenState();
}

class _AllFavoritesScreenState extends State<AllFavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _natureFavorites = {};

  static const _natureSoundData = <Map<String, dynamic>>[
    {
      'name': '파도소리',
      'icon': Icons.waves,
      'color': Color(0xFF4A7BA6),
      'description': '규칙적인 파도 소리는 마음을 차분히 가라앉혀 깊은 휴식과 수면에 도움을 줘요',
      'assetPath': 'assets/wave_sound.mp3',
    },
    {
      'name': '빗소리',
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF3E5A78),
      'description': '일정한 빗소리는 집중력을 높이고 불안한 마음을 편안하게 다독여줘요',
      'assetPath': 'assets/rain_sound.mp3',
    },
    {
      'name': '새소리',
      'icon': Icons.forest_outlined,
      'color': Color(0xFF5C7A5E),
      'description': '청아한 새소리는 스트레스를 줄이고 상쾌한 기분을 만들어줘요',
      'assetPath': 'assets/bird_sound.mp3',
    },
    {
      'name': '모닥불',
      'icon': Icons.local_fire_department_outlined,
      'color': Color(0xFFC97B4A),
      'description': '타닥타닥 장작 타는 소리는 아늑하고 포근한 분위기를 만들어줘요',
      'assetPath': 'assets/campfire_sound.mp3',
    },
    {
      'name': '시냇물',
      'icon': Icons.water_outlined,
      'color': Color(0xFF2C6BB3),
      'description': '졸졸 흐르는 시냇물 소리는 마음을 편안하게 이완시켜줘요',
      'assetPath': 'assets/stream_sound.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNatureFavorites();
  }

  Future<void> _loadNatureFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('nature_favorites') ?? [];
    if (mounted) setState(() => _natureFavorites = favs.toSet());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _emptyState(Color baseColor, String message) {
    return Center(
      child: Text(message, style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);

    final natureFavList =
    _natureSoundData.where((s) => _natureFavorites.contains(s['name'])).toList();
    final musicFavCount = context.watch<MusicProvider>().favorites.length;
    final radioFavCount = context.watch<RadioProvider>().favorites.length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('즐겨찾기',
            style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          labelColor: primaryColor,
          unselectedLabelColor: baseColor.withOpacity(0.45),
          indicatorColor: primaryColor,
          tabs: [
            Tab(text: '음악($musicFavCount)'),
            Tab(text: '라디오($radioFavCount)'),
            Tab(text: '자연소리(${natureFavList.length})'),
            const Tab(text: '수면 · 집중(0)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const FavoritesScreen(showHeader: false),
          Consumer<RadioProvider>(
            builder: (context, radioProvider, _) {
              final favorites = radioProvider.favorites;
              if (favorites.isEmpty) {
                return _emptyState(baseColor, '즐겨찾는 라디오가 없어요');
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                itemCount: favorites.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: baseColor.withOpacity(0.12)),
                itemBuilder: (context, index) => StationTile(station: favorites[index]),
              );
            },
          ),
          natureFavList.isEmpty
              ? _emptyState(baseColor, '즐겨찾는 자연소리가 없어요')
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: natureFavList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final sound = natureFavList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NatureSoundDetailScreen(
                        name: sound['name'],
                        icon: sound['icon'],
                        description: sound['description'],
                        assetPath: sound['assetPath'],
                        color: sound['color'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: sound['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(sound['icon'], color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sound['name'],
                                style: TextStyle(
                                    color: baseColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(sound['description'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.45), fontSize: 11.5)),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.heart_fill, color: primaryColor, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
          _emptyState(baseColor, '수면 · 집중 기능은 준비중이에요'),
        ],
      ),
    );
  }
}