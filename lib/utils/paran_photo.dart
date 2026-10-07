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