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
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) =>
          fallback ?? Container(width: width, height: height, color: const Color(0xFF2A2A2A)),
      errorWidget: (_, __, ___) =>
          fallback ?? Container(width: width, height: height, color: const Color(0xFF2A2A2A)),
    );
  }
  return Image.asset(path, fit: fit, width: width, height: height);
}

/// 앱 켤 때 미리 꺼내두기 (재생화면 들어갈 때 바로 뜨게)
void precacheParanPhoto(String path, BuildContext context) {
  if (_isOnline(path)) {
    final name = path.substring('assets/'.length).replaceAll('.png', '.jpg');
    precacheImage(CachedNetworkImageProvider('$_paranBase/$name'), context);
  }
}