import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _paranBase =
    'https://files.ssing.kr/app-images';

// 이 이름으로 시작하는 사진은 수파베이스에서 가져온다
const _onlinePrefixes = [
  'spring_', 'summer_', 'autumn_', 'winter_',
  'mood_', 'animal_', 'etc_', 'love_',
  'nature_wave_bg', 'nature_rain_bg', 'nature_bird_bg',
  'nature_fire_bg', 'nature_stream_bg',
  'wave', 'rain', 'bird2', 'stream2',
  'rest_radio_',
  'paranphoto/', // 파란포토 새 사진 (app-images/paranphoto)
];

bool _isOnline(String path) {
  if (!path.startsWith('assets/')) return false;
  final name = path.substring('assets/'.length);
  return _onlinePrefixes.any((p) => name.startsWith(p));
}

/// 그 폰의 화면 가로 크기(실제 점 개수)만큼만 사진을 풀기
/// → 화질은 그대로, 램은 아끼기 (화면이 작은 폰은 더 작게)
int screenPhotoWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
  return w.round().clamp(480, 1440);
}

/// 파란포토 사진 그리기 (수파베이스 사진은 한 번 받으면 휴대폰에 저장됨)
Widget paranPhoto(String path,
    {BoxFit fit = BoxFit.cover, double? width, double? height, bool thumb = false, Widget? fallback}) {
  return Builder(builder: (context) {
    final cw = thumb ? 400 : screenPhotoWidth(context);
    if (_isOnline(path)) {
      final name = path.substring('assets/'.length).replaceAll('.png', thumb ? '_thumb.jpg' : '.jpg');
      return CachedNetworkImage(
        imageUrl: '$_paranBase/$name',
        fit: fit,
        width: width,
        height: height,
        useOldImageOnUrlChange: true,
        memCacheWidth: cw, // 화면 크기만큼만 램에 올리기 (모양은 그대로)
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) =>
        fallback ?? Container(width: width, height: height, color: const Color(0xFF2A2A2A)),
        errorWidget: (_, __, ___) =>
        fallback ?? Container(width: width, height: height, color: const Color(0xFF2A2A2A)),
        errorListener: (_) {}, // 서버가 잠깐 늦어도 오류로 보고하지 않기 (회색 칸 → 다음에 다시 받음)
      );
    }
    return Image.asset(path, fit: fit, width: width, height: height, cacheWidth: cw); // 화면 크기만큼만
  });
}

/// 앱 켤 때 미리 꺼내두기 (재생화면 들어갈 때 바로 뜨게)
/// 보여줄 때와 같은 크기로 미리 풀어둬야 큰 원본이 램에 따로 안 남아요
void precacheParanPhoto(String path, BuildContext context) {
  if (_isOnline(path)) {
    final name = path.substring('assets/'.length).replaceAll('.png', '.jpg');
    precacheImage(
        ResizeImage(CachedNetworkImageProvider('$_paranBase/$name'), width: screenPhotoWidth(context)),
        context,
        onError: (_, __) {}); // 미리 받기 실패해도 조용히
  }
}


/// 파란포토 사진 목록 — R2(app-images/paranphoto/list.json)에서 받아 씀
///  · 사진 추가: R2 app-images/paranphoto 에 번호.jpg + 번호_thumb.jpg 올리고 list.json에 번호만 추가 (앱 업데이트 필요 없음)
///  · list.json 모양: {"파란포토": ["001", "002"]}  (묶음을 더 만들면 사진 고르기 창에 카테고리 칩이 생김)
///                    또는 그냥 ["001", "002"]
///  · 인터넷이 안 되면 마지막으로 받은 목록 → 그것도 없으면 앱 안 기본 목록(001~010)
class ParanPhotoList {
  static const _url = '$_paranBase/paranphoto/list.json';
  static const _prefKey = 'paranPhotoListJson';
  static Map<String, List<String>>? _list;
  static bool _fetched = false;

  /// 지금 쓸 목록 (받은 게 없으면 앱 안 기본 목록)
  static Map<String, List<String>> of(Map<String, List<String>> builtin) => _list ?? builtin;

  static Map<String, List<String>>? _parse(String body) {
    try {
      final j = jsonDecode(body);
      String path(Object? n) {
        final v = n is int ? n.toString().padLeft(3, '0') : n.toString().trim();
        return 'assets/paranphoto/$v.png';
      }
      final out = <String, List<String>>{};
      if (j is List) {
        final l = [for (final n in j) path(n)];
        if (l.isNotEmpty) out['파란포토'] = l;
      } else if (j is Map) {
        j.forEach((k, v) {
          if (v is List && v.isNotEmpty) out[k.toString()] = [for (final n in v) path(n)];
        });
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null; // 목록 파일이 잘못돼도 앱은 그대로 (기본 목록)
    }
  }

  /// 지난번에 받은 목록 먼저 (재생 화면 설정 불러올 때)
  static void readCache(SharedPreferences prefs) {
    if (_list != null) return;
    final s = prefs.getString(_prefKey);
    if (s != null) _list = _parse(s);
  }

  /// 새 목록 받기 (앱 켜고 한 번만) — 목록이 바뀌었으면 true
  static Future<bool> refresh() async {
    if (_fetched) return false;
    _fetched = true;
    try {
      // 한 시간마다 주소를 살짝 바꿔서 예전 목록이 캐시에 남아 있지 않게
      final hour = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
      final r = await http.get(Uri.parse('$_url?h=$hour')).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) {
        _fetched = false;
        return false;
      }
      final body = utf8.decode(r.bodyBytes);
      final parsed = _parse(body);
      if (parsed == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final changed = prefs.getString(_prefKey) != body || _list == null;
      await prefs.setString(_prefKey, body);
      _list = parsed;
      return changed;
    } catch (_) {
      _fetched = false; // 다음에 재생 화면 열 때 다시
      return false;
    }
  }
}
