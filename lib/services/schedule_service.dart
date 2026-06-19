import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService {
  static const _url =
      'https://raw.githubusercontent.com/yoonyeoul37/catsong/main/assets/schedule.json';
  static const _cacheKey = 'cached_schedule_json';

  Map<String, dynamic> _scheduleData = {};

  Future<void> loadSchedule() async {
    try {
      final response = await http.get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = response.body;
        _scheduleData = jsonDecode(json);
        // 캐시 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, json);
        debugPrint('편성표 로드 성공');
      }
    } catch (e) {
      debugPrint('편성표 로드 실패, 캐시 사용: $e');
      // 캐시에서 불러오기
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          _scheduleData = jsonDecode(cached);
          debugPrint('캐시 편성표 로드 성공');
        }
      } catch (e2) {
        debugPrint('캐시 로드 실패: $e2');
      }
    }
  }

  // 현재 방송 중인 프로그램 찾기
  Map<String, dynamic>? getCurrentProgram(String stationName) {
    try {
      final stationData = _scheduleData[stationName];
      if (stationData == null) return null;

      final now = DateTime.now();
      final dayKey = _getDayKey(now.weekday);
      final programs = stationData[dayKey] as List<dynamic>?;
      if (programs == null || programs.isEmpty) {
        // 주말 데이터 없으면 weekday 사용
        final weekday = stationData['weekday'] as List<dynamic>?;
        if (weekday == null) return null;
        return _findCurrentProgram(weekday, now);
      }
      return _findCurrentProgram(programs, now);
    } catch (e) {
      debugPrint('getCurrentProgram 오류: $e');
      return null;
    }
  }

  Map<String, dynamic>? _findCurrentProgram(
      List<dynamic> programs, DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;

    for (final p in programs) {
      final start = _timeToMinutes(p['start'] as String);
      final end = _timeToMinutes(p['end'] as String);

      // 자정 넘는 경우 처리
      if (end < start) {
        if (currentMinutes >= start || currentMinutes < end) {
          return Map<String, dynamic>.from(p);
        }
      } else {
        if (currentMinutes >= start && currentMinutes < end) {
          return Map<String, dynamic>.from(p);
        }
      }
    }
    return null;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  String _getDayKey(int weekday) {
    if (weekday == 5) return 'friday';
    if (weekday == 6) return 'saturday';
    if (weekday == 7) return 'sunday';
    return 'weekday';
  }

  // 전체 편성표 가져오기
  List<Map<String, dynamic>> getScheduleList(String stationName) {
    try {
      final stationData = _scheduleData[stationName];
      if (stationData == null) return [];
      final now = DateTime.now();
      final dayKey = _getDayKey(now.weekday);
      final programs = stationData[dayKey] as List<dynamic>?;
      if (programs == null || programs.isEmpty) {
        return List<Map<String, dynamic>>.from(
            (stationData['weekday'] as List<dynamic>? ?? [])
                .map((e) => Map<String, dynamic>.from(e)));
      }
      return List<Map<String, dynamic>>.from(
          programs.map((e) => Map<String, dynamic>.from(e)));
    } catch (e) {
      return [];
    }
  }

  bool hasSchedule(String stationName) {
    return _scheduleData.containsKey(stationName);
  }
}