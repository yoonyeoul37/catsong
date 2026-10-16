import 'package:flutter/material.dart';
import '../utils/paran_photo.dart';

/// 방송 사진이 없을 때 기본 그림: 지금 시간대 라디오 사진 (홈 '최근에 들었어요' 카드와 같은 4장)
/// 아침 5~11시 · 낮 11~17시 · 저녁 17~22시 · 밤 22~5시
String radioSlotImage([DateTime? t]) {
  final h = (t ?? DateTime.now()).hour;
  final slot = h >= 5 && h < 11
      ? 'morning'
      : h >= 11 && h < 17
      ? 'day'
      : h >= 17 && h < 22
      ? 'evening'
      : 'night';
  return 'assets/radio_media_$slot.jpg';
}

class RadioMoodPlaceholder extends StatelessWidget {
  final double height;
  const RadioMoodPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        radioSlotImage(),
        fit: BoxFit.cover,
        cacheWidth: screenPhotoWidth(context), // 화면 크기만큼만 풀기 (화질은 그대로)
        gaplessPlayback: true, // 시간대가 바뀔 때 깜빡이지 않게
        // 혹시 시간대 사진을 못 불러오면 예전 기본 사진
        errorBuilder: (_, __, ___) => Image.asset('assets/radio_mood_bg.jpg', fit: BoxFit.cover),
      ),
    );
  }
}