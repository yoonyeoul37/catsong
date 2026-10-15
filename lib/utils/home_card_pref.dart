import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 홈 곡 목록 맨 위 "오늘의 카드" 설정 (홈 화면과 설정 화면이 같이 씀)
class HomeCardPref {
  static final on = ValueNotifier<bool>(true); // 설정 스위치
  static final hiddenToday = ValueNotifier<bool>(false); // 오늘 ✕로 닫았는지
  static bool _loaded = false;

  static String _day(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    on.value = p.getBool('homeCardOn') ?? true;
    hiddenToday.value = p.getString('homeCardHiddenDay') == _day(DateTime.now());
  }

  static Future<void> setOn(bool v) async {
    on.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('homeCardOn', v);
    if (v) {
      hiddenToday.value = false;
      await p.remove('homeCardHiddenDay');
    }
  }

  /// 오늘만 닫기. 사흘 연달아 닫았으면 true (아예 끌지 한 번만 물어보기)
  static Future<bool> closeToday() async {
    hiddenToday.value = true;
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final yesterday = _day(now.subtract(const Duration(days: 1)));
    final last = p.getString('homeCardHiddenDay');
    final streak = last == yesterday ? (p.getInt('homeCardCloseStreak') ?? 0) + 1 : 1;
    await p.setString('homeCardHiddenDay', _day(now));
    await p.setInt('homeCardCloseStreak', streak);
    if (streak >= 3 && !(p.getBool('homeCardAskedOff') ?? false)) {
      await p.setBool('homeCardAskedOff', true);
      return true;
    }
    return false;
  }
}

/// 메인 홈 맨 위 카드 (나만의 색·라디오·팁) 켜기/끄기 — 홈 화면과 설정 화면이 같이 씀
class MainCardPref {
  static final on = ValueNotifier<bool>(true);
  static final reopened = ValueNotifier<int>(0); // 다시 켤 때마다 +1 → 홈이 닫은 카드 다시 불러오기
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    on.value = p.getBool('mainCardOn') ?? true;
  }

  static Future<void> setOn(bool v) async {
    on.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('mainCardOn', v);
    if (v) {
      // 다시 켜면 오늘 닫은 카드와 나만의 색 카드도 다시 나오게
      await p.remove('main_card_closed_day');
      await p.remove('main_card_closed');
      await p.remove('color_tip_hide_until');
      await p.remove('color_tip_closed');
      await p.remove('color_tip_done');
      reopened.value++;
    }
  }
}
