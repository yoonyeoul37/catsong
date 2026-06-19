import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_country.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import 'radio_channel_screen.dart';

class RadioBroadcasterScreen extends StatelessWidget {
  final RadioCountry country;
  const RadioBroadcasterScreen({super.key, required this.country});

  static const Map<String, Color> _brandColors = {
    'KBS':    Color(0xFF1565C0),
    'MBC':    Color(0xFF6A1B9A),
    'SBS':    Color(0xFFB71C1C),
    'CBS':    Color(0xFF1B5E20),
    'EBS':    Color(0xFF0277BD),
    'TBS':    Color(0xFF004D40),
    'YTN':    Color(0xFF880E4F),
    'OBS':    Color(0xFF0D47A1),
    'TBN':    Color(0xFF2E7D32),
    'GUGAK':  Color(0xFF4E342E),
    'BEFM':   Color(0xFFE65100),
    'BBS':    Color(0xFF795548),
    'AFN':    Color(0xFF263238),
    'BSOD':   Color(0xFF37474F),
    'NPR':    Color(0xFF3E2723),
    'ESPN':   Color(0xFFC62828),
    'BBC':    Color(0xFF880E4F),
    'VOA':    Color(0xFF1A237E),
    'CNN':    Color(0xFFB71C1C),
    'FOX':    Color(0xFF0D47A1),
    'JAZZ':   Color(0xFF4A148C),
    'CLASSI': Color(0xFF1B5E20),
    'NHK':    Color(0xFF212121),
    'JWAVE':  Color(0xFF4A148C),
    'FM802':  Color(0xFF1A237E),
    'RTHK':   Color(0xFF33691E),
    'RTI':    Color(0xFF006064),
    'ICRT':   Color(0xFFBF360C),
    'BCC':    Color(0xFF37474F),
  };

  Color _brandColor(String id) {
    // 지역 MBC 는 MBC 색상
    if (id.startsWith('MBC')) return _brandColors['MBC'] ?? const Color(0xFF6A1B9A);
    // 지역 TBN 은 TBN 색상
    if (id.startsWith('TBN')) return _brandColors['TBN'] ?? const Color(0xFF2E7D32);
    return _brandColors[id] ?? const Color(0xFF37474F);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final broadcasters = country.broadcasters;

    // 카테고리별 그룹화
    final categories = <String, List<RadioBroadcaster>>{};
    for (final b in broadcasters) {
      final cat = b.category.isEmpty ? '방송사' : b.category;
      categories.putIfAbsent(cat, () => []);
      categories[cat]!.add(b);
    }

    // 위젯 리스트 생성
    final widgets = <Widget>[];
    for (final entry in categories.entries) {
      // 카테고리 헤더
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.value.length}',
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

      // 방송사 타일들
      for (final broadcaster in entry.value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 5),
            child: _BroadcasterTile(
              broadcaster: broadcaster,
              color: _brandColor(broadcaster.id),
              country: country,
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 22),
        ),
        title: Row(
          children: [
            Text(country.flag,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              country.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 80 + MediaQuery.of(context).viewPadding.bottom),
        children: widgets,
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

class _BroadcasterTile extends StatelessWidget {
  final RadioBroadcaster broadcaster;
  final Color color;
  final RadioCountry country;
  const _BroadcasterTile({
    required this.broadcaster,
    required this.color,
    required this.country,
  });

  String _displayLabel(String id) {
    // 지역 MBC 는 짧은 라벨
    if (id.startsWith('MBC_')) return 'MBC';
    if (id.startsWith('TBN_')) return 'TBN';
    if (id.length > 3) return id.substring(0, 3);
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RadioChannelScreen(
                broadcaster: broadcaster,
                country: country,
              ),
            ),
          );
        },
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryColor.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    _displayLabel(broadcaster.id),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  broadcaster.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}