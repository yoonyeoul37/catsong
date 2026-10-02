import 'package:flutter/material.dart';

/// 자연소리 전체 목록 — 여기에 한 줄 추가하면 자연소리 화면과 믹스에 둘 다 나와요.
/// category가 같은 것끼리 믹스에서 한 칸으로 묶이고, 그 칸의 첫 번째가 기본 소리예요.
class NatureSound {
  final String name;
  final String category;
  final IconData icon;
  final String emoji;
  final String description;
  final String? assetPath;
  const NatureSound({
    required this.name,
    required this.category,
    required this.icon,
    required this.emoji,
    required this.description,
    this.assetPath,
  });
  bool get isReady => assetPath != null;
}

const natureSoundCatalog = <NatureSound>[
  NatureSound(
    name: '파도소리',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '규칙적인 파도 소리는 마음을 차분히 가라앉혀 깊은 휴식과 수면에 도움을 줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_sound.mp3',
  ),
  NatureSound(
    name: '잔잔한 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '한결 부드럽고 잔잔하게 밀려오는 파도 소리로 편안한 휴식을 도와줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_calm_sound.mp3',
  ),
  NatureSound(
    name: '갈매기와 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '갈매기 울음소리가 어우러진 파도 소리로 생생한 해변 분위기를 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_seagull_sound.mp3',
  ),
  NatureSound(
    name: '바위에 부딪히는 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '바위에 세게 부딪히며 부서지는 파도 소리로 역동적인 바다를 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_rocks_sound.mp3',
  ),
  NatureSound(
    name: '멀리서 들리는 갈매기',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '고요한 바닷가, 멀리서 은은하게 들려오는 갈매기 소리로 차분한 휴식을 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_distant_seagull_sound.mp3',
  ),
  NatureSound(
    name: '거친 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '거칠게 밀려와 부서지는 파도 소리로 힘 있는 바다를 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_rough_sound.mp3',
  ),
  NatureSound(
    name: '빗소리',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '☔',
    description: '일정한 빗소리는 집중력을 높이고 불안한 마음을 편안하게 다독여줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_sound.mp3',
  ),
  NatureSound(
    name: '창문에 떨어지는 비',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '🪟',
    description: '창문을 두드리는 부드러운 빗소리로 편안하게 잠들어보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_window_sound.mp3',
  ),
  NatureSound(
    name: '숲속의 비와 새소리',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '🌲',
    description: '숲속에 내리는 빗소리와 새소리가 어우러져 마음을 편안하게 해줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_forest_sound.mp3',
  ),
  NatureSound(
    name: '숲속의 거센 밤비',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '🌙',
    description: '깊은 밤 숲속에 세차게 내리는 빗소리로 몰입감 있는 휴식을 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_night_forest_sound.mp3',
  ),
  NatureSound(
    name: '새소리',
    category: '새소리',
    icon: Icons.forest_outlined,
    emoji: '🐦',
    description: '청아한 새소리는 스트레스를 줄이고 상쾌한 기분을 만들어줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_sound.mp3',
  ),
  NatureSound(
    name: '뻐꾸기와 숲속 새소리',
    category: '새소리',
    icon: Icons.forest_outlined,
    emoji: '🌳',
    description: '뻐꾸기 소리가 어우러진 숲속의 새소리로 상쾌한 아침을 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_forest_cuckoo_sound.mp3',
  ),
  NatureSound(
    name: '모닥불',
    category: '모닥불',
    icon: Icons.local_fire_department_outlined,
    emoji: '🔥',
    description: '타닥타닥 장작 타는 소리는 아늑한 분위기로 깊은 이완을 도와줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/campfire_sound.mp3',
  ),
  NatureSound(
    name: '시냇물',
    category: '시냇물',
    icon: Icons.water_outlined,
    emoji: '💧',
    description: '졸졸 흐르는 시냇물 소리는 마음을 편안하게 하고 잡생각을 줄여줘요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_sound.mp3',
  ),
  NatureSound(
    name: '잔잔한 강물',
    category: '시냇물',
    icon: Icons.water_outlined,
    emoji: '🌊',
    description: '넓은 강물이 잔잔하게 흐르는 소리로 편안한 휴식을 느껴보세요',
    assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_river_sound.mp3',
  ),
];