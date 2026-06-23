import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_tile.dart';

class RadioSearchScreen extends StatefulWidget {
  const RadioSearchScreen({super.key});

  @override
  State<RadioSearchScreen> createState() => _RadioSearchScreenState();
}

class _RadioSearchScreenState extends State<RadioSearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    context.read<RadioProvider>().clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor  = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 17),
          decoration: const InputDecoration(
            hintText: '방송국 이름으로 검색...',
            hintStyle: TextStyle(
                color: AppTheme.textHint, fontSize: 17),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {});
            context.read<RadioProvider>().searchStations(value);
          },
        ),
      ),
      body: _ctrl.text.length < 2
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search,
                size: 64,
                color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('방송국 이름을 입력해 주세요',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15)),
          ],
        ),
      )
          : radioProvider.isSearching
          ? Center(
          child: const CircularProgressIndicator(
              color: Colors.white60))
          : radioProvider.searchResults.isEmpty
          ? Center(
        child: Text(
          '"${_ctrl.text}" 검색 결과가 없습니다',
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            16, 8, 16, 80),
        itemCount:
        radioProvider.searchResults.length,
        itemBuilder: (context, index) => StationTile(
          station:
          radioProvider.searchResults[index],
        ),
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