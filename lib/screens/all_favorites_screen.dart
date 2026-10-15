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
import '../utils/nature_sound_catalog.dart';

class AllFavoritesScreen extends StatefulWidget {
  const AllFavoritesScreen({super.key});

  @override
  State<AllFavoritesScreen> createState() => _AllFavoritesScreenState();
}

class _AllFavoritesScreenState extends State<AllFavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _natureFavorites = {};

  // 자연소리 화면과 같은 목록(nature_sound_catalog)에서 가져오기
  // → 클라우드 주소·새로 생긴 소리(잔잔한 파도 등)가 자동으로 같이 따라와요
  static const _categoryColors = <String, Color>{
    '파도소리': Color(0xFF4A7BA6),
    '빗소리': Color(0xFF3E5A78),
    '새소리': Color(0xFF5C7A5E),
    '모닥불': Color(0xFFC97B4A),
    '시냇물': Color(0xFF2C6BB3),
  };
  static final _natureSoundData = <Map<String, dynamic>>[
    for (final s in natureSoundCatalog)
      if (s.isReady)
        {
          'name': s.name,
          'icon': s.icon,
          'color': _categoryColors[s.category] ?? const Color(0xFF3E9C7E),
          'description': s.description,
          'assetPath': s.assetPath,
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
    // 고른 탭: 포인트 색 말고 먹색(다크는 크림색)으로 고정
    final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);

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
          labelColor: ink,
          unselectedLabelColor: baseColor.withOpacity(0.45),
          // 밑줄: 둥근 모서리 없이 반듯한 직선 (먹색, 두께 2)
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: ink, width: 2),
          ),
          // 탭을 누르거나 밀 때 포인트 색 배경(물결)이 번지지 않게
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            Tab(text: '음악($musicFavCount)'),
            Tab(text: '라디오($radioFavCount)'),
            Tab(text: '자연소리(${natureFavList.length})'),
            const Tab(text: '휴식 · 집중(0)'),
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
                itemBuilder: (context, index) => StationTile(station: favorites[index], openedFromList: false),
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
                      Icon(CupertinoIcons.heart_fill, color: const Color(0xFFE05A4F), size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
          _emptyState(baseColor, '휴식 · 집중 기능은 준비중이에요'),
        ],
      ),
    );
  }
}