import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../providers/theme_provider.dart';
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF17140F),
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
          icon: Icon(Icons.arrow_back_ios,
              color: baseColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: TextStyle(
              color: baseColor, fontSize: 17),
          decoration: InputDecoration(
            hintText: '방송국 이름으로 검색...',
            hintStyle: TextStyle(
                color: baseColor.withOpacity(0.38), fontSize: 17),
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
                color: baseColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('방송국 이름을 입력해 주세요',
                style: TextStyle(
                    color: baseColor.withOpacity(0.7),
                    fontSize: 15)),
          ],
        ),
      )
          : radioProvider.isSearching
          ? Center(
          child: CircularProgressIndicator(
              color: baseColor.withOpacity(0.6)))
          : radioProvider.searchResults.isEmpty
          ? Center(
        child: Text(
          '"${_ctrl.text}" 검색 결과가 없습니다',
          style: TextStyle(
              color: baseColor.withOpacity(0.7),
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