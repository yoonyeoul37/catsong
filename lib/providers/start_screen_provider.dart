import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱을 켰을 때 가장 먼저 보여줄 화면.
/// null 이면 기본 대시보드(카드 4개 화면)를 보여준다.
enum StartScreenType { music, radio, nature, sleep }

class StartScreenProvider extends ChangeNotifier {
  StartScreenType? _startScreen;
  static const _prefsKey = 'start_screen_type';

  StartScreenType? get startScreen => _startScreen;

  StartScreenProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _startScreen = StartScreenType.values.firstWhere(
            (e) => e.name == saved,
        orElse: () => StartScreenType.music,
      );
      notifyListeners();
    }
  }

  Future<void> setStartScreen(StartScreenType? type) async {
    _startScreen = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (type == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, type.name);
    }
  }
}