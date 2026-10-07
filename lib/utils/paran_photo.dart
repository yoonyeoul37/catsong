import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

const _paranBase =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images';

// 이 이름으로 시작하는 사진은 수파베이스에서 가져온다
const _onlinePrefixes = [
  'spring_', 'summer_', 'autumn_', 'winter_',
  'mood_', 'animal_', 'etc_', 'love_',
  'nature_wave_bg', 'nature_rain_bg', 'nature_bird_bg',
  'nature_fire_bg', 'nature_stream_bg',
  'wave', 'rain', 'bird2', 'stream2',
  'rest_radio_',
];

bool _isOnline(String path) {
  if (!path.startsWith('assets/')) return false;
  final name = path.substring('assets/'.length);
  return _onlinePrefixes.any((p) => name.startsWith(p));
}

/// 파란포토 사진 그리기 (수파베이스 사진은 한 번 받으면 휴대폰에 저장됨)
Widget paranPhoto(String path,
    {BoxFit fit = BoxFit.cover, double? width, double? height, bool thumb = false, Widget? fallback}) {
  if (_isOnline(path)) {
    final name = path.substring('assets/'.length).replaceAll('.png', thumb ? '_thumb.jpg' : '.jpg');
    return CachedNetworkImage(
      imageUrl: '$_paranBase/$name',
      fit: fit,
      width: width,
      height: height,
      useOldImageOnUrlChange: true,
      memCacheWidth: thumb ? 400 : 1080, // 화면 크기만큼만 램에 올리기 (모양은 그대로)
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) =>
          fallback ?? Container(width: width, height: height, color: const Color(0xFF2A2A2A)),
      errorWidget: (_, __, ___) =>
          fallback ?? Container(width: width, height: height, color: const Color(0xFF2A2A2A)),
      errorListener: (_) {}, // 서버가 잠깐 늦어도 오류로 보고하지 않기 (회색 칸 → 다음에 다시 받음)
    );
  }
  return Image.asset(path, fit: fit, width: width, height: height,
      cacheWidth: thumb ? 400 : 1080); // 화면 크기만큼만
}

/// 앱 켤 때 미리 꺼내두기 (재생화면 들어갈 때 바로 뜨게)
void precacheParanPhoto(String path, BuildContext context) {
  if (_isOnline(path)) {
    final name = path.substring('assets/'.length).replaceAll('.png', '.jpg');
    precacheImage(CachedNetworkImageProvider('$_paranBase/$name'), context,
        onError: (_, __) {}); // 미리 받기 실패해도 조용히
  }
}