import 'package:flutter/material.dart';

class RadioMoodPlaceholder extends StatelessWidget {
  final double height;
  const RadioMoodPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        'assets/radio_mood_bg.jpg',
        fit: BoxFit.cover,
      ),
    );
  }
}