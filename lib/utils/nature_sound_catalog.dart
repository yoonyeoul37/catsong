import 'package:flutter/material.dart';
import '../l10n/locale_holder.dart';

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

// ── 화면에 보일 자연소리 이름·설명 (저장·찾기는 한국어 이름 그대로) ──
String natureName(String ko) => _natureText(ko, 0) ?? ko;
String natureDesc(String koName, String koDesc) => _natureText(koName, 1) ?? koDesc;

String? _natureText(String ko, int i) {
  final loc = tr.localeName;
  if (loc.startsWith('ko')) return null;
  final m = loc.startsWith('ja')
      ? _natureJa
      : loc == 'zh_Hant'
          ? _natureZhHant
          : loc.startsWith('zh')
              ? _natureZh
              : _natureEn;
  return m[ko]?[i];
}

const _natureEn = <String, List<String>>{
  '파도소리': ['Ocean waves', 'Steady waves calm your mind and help you rest and sleep deeply'],
  '잔잔한 파도': ['Gentle waves', 'Soft, gentle waves rolling in for a peaceful rest'],
  '갈매기와 파도': ['Seagulls and waves', 'Waves with seagull calls for a lively beach mood'],
  '바위에 부딪히는 파도': ['Waves on rocks', 'Waves crashing hard against rocks for a dynamic sea'],
  '멀리서 들리는 갈매기': ['Distant seagulls', 'A quiet shore with seagulls softly calling far away'],
  '거친 파도': ['Rough waves', 'Powerful waves rolling in and breaking'],
  '빗소리': ['Rain', 'Steady rain helps you focus and soothes an anxious mind'],
  '창문에 떨어지는 비': ['Rain on the window', 'Soft rain tapping on the window to help you fall asleep'],
  '숲속의 비와 새소리': ['Forest rain and birds', 'Rain in the forest blended with birdsong to calm your mind'],
  '숲속의 거센 밤비': ['Heavy night rain', 'Heavy rain falling in a forest at night for deep relaxation'],
  '새소리': ['Birdsong', 'Clear birdsong eases stress and lifts your mood'],
  '뻐꾸기와 숲속 새소리': ['Cuckoo and forest birds', 'Forest birdsong with a cuckoo for a fresh morning'],
  '모닥불': ['Campfire', 'Crackling firewood creates a cozy mood for deep relaxation'],
  '시냇물': ['Stream', 'A babbling stream calms your mind and quiets busy thoughts'],
  '잔잔한 강물': ['Calm river', 'A wide river flowing calmly for a peaceful rest'],
};

const _natureJa = <String, List<String>>{
  '파도소리': ['波の音', '規則的な波の音が心を落ち着かせ、深い休息と眠りを助けます'],
  '잔잔한 파도': ['穏やかな波', 'やさしく穏やかに寄せる波の音で、ゆったり休めます'],
  '갈매기와 파도': ['カモメと波', 'カモメの鳴き声と波の音で、生き生きとした海辺の雰囲気を'],
  '바위에 부딪히는 파도': ['岩に砕ける波', '岩に激しくぶつかって砕ける波の音で、力強い海を感じて'],
  '멀리서 들리는 갈매기': ['遠くのカモメ', '静かな海辺で遠くから聞こえるカモメの声で、穏やかな休息を'],
  '거친 파도': ['荒波', '荒々しく寄せては砕ける波の音で、力強い海を感じて'],
  '빗소리': ['雨の音', '一定の雨音が集中力を高め、不安な心を落ち着かせます'],
  '창문에 떨어지는 비': ['窓に落ちる雨', '窓をたたくやさしい雨音で、心地よく眠りましょう'],
  '숲속의 비와 새소리': ['森の雨と鳥の声', '森に降る雨音と鳥のさえずりが心を和ませます'],
  '숲속의 거센 밤비': ['森に降る夜の強い雨', '夜の森に激しく降る雨音で、没入感のある休息を'],
  '새소리': ['鳥のさえずり', '澄んだ鳥の声がストレスを和らげ、爽やかな気分にします'],
  '뻐꾸기와 숲속 새소리': ['カッコウと森の鳥', 'カッコウの声が響く森の鳥のさえずりで、爽やかな朝を'],
  '모닥불': ['焚き火', 'パチパチと薪が燃える音が、心地よい雰囲気で深いリラックスへ'],
  '시냇물': ['小川のせせらぎ', 'さらさら流れる小川の音が心を落ち着かせ、雑念を減らします'],
  '잔잔한 강물': ['穏やかな川', '広い川が静かに流れる音で、ゆったり休めます'],
};

const _natureZh = <String, List<String>>{
  '파도소리': ['海浪声', '有节奏的海浪声让心情平静，帮助深度休息和睡眠'],
  '잔잔한 파도': ['平静的海浪', '轻柔平静的海浪声，助你安心休息'],
  '갈매기와 파도': ['海鸥与海浪', '海鸥鸣叫与海浪声交织，感受生动的海滩氛围'],
  '바위에 부딪히는 파도': ['拍打岩石的海浪', '猛烈拍打岩石的海浪声，感受大海的力量'],
  '멀리서 들리는 갈매기': ['远处的海鸥', '宁静海边远处传来的海鸥声，带来平静的休息'],
  '거친 파도': ['汹涌的海浪', '汹涌拍岸的海浪声，感受有力的大海'],
  '빗소리': ['雨声', '稳定的雨声提升专注力，抚平不安的心情'],
  '창문에 떨어지는 비': ['窗上的雨', '轻敲窗户的柔和雨声，助你安然入睡'],
  '숲속의 비와 새소리': ['林中雨声与鸟鸣', '林中雨声与鸟鸣交织，让心情放松'],
  '숲속의 거센 밤비': ['林中夜晚的大雨', '深夜林中倾盆而下的雨声，带来沉浸式休息'],
  '새소리': ['鸟鸣', '清脆的鸟鸣减轻压力，带来清爽心情'],
  '뻐꾸기와 숲속 새소리': ['布谷鸟与林中鸟鸣', '伴着布谷鸟声的林中鸟鸣，感受清爽的早晨'],
  '모닥불': ['篝火', '噼啪作响的柴火声营造温馨氛围，帮助深度放松'],
  '시냇물': ['溪流', '潺潺溪水声让心情平静，减少杂念'],
  '잔잔한 강물': ['平静的河流', '宽阔河流平静流淌的声音，助你安心休息'],
};

const _natureZhHant = <String, List<String>>{
  '파도소리': ['海浪聲', '有節奏的海浪聲讓心情平靜，幫助深度休息和睡眠'],
  '잔잔한 파도': ['平靜的海浪', '輕柔平靜的海浪聲，助你安心休息'],
  '갈매기와 파도': ['海鷗與海浪', '海鷗鳴叫與海浪聲交織，感受生動的海灘氛圍'],
  '바위에 부딪히는 파도': ['拍打岩石的海浪', '猛烈拍打岩石的海浪聲，感受大海的力量'],
  '멀리서 들리는 갈매기': ['遠處的海鷗', '寧靜海邊遠處傳來的海鷗聲，帶來平靜的休息'],
  '거친 파도': ['洶湧的海浪', '洶湧拍岸的海浪聲，感受有力的大海'],
  '빗소리': ['雨聲', '穩定的雨聲提升專注力，撫平不安的心情'],
  '창문에 떨어지는 비': ['窗上的雨', '輕敲窗戶的柔和雨聲，助你安然入睡'],
  '숲속의 비와 새소리': ['林中雨聲與鳥鳴', '林中雨聲與鳥鳴交織，讓心情放鬆'],
  '숲속의 거센 밤비': ['林中夜晚的大雨', '深夜林中傾盆而下的雨聲，帶來沉浸式休息'],
  '새소리': ['鳥鳴', '清脆的鳥鳴減輕壓力，帶來清爽心情'],
  '뻐꾸기와 숲속 새소리': ['布穀鳥與林中鳥鳴', '伴著布穀鳥聲的林中鳥鳴，感受清爽的早晨'],
  '모닥불': ['營火', '劈啪作響的柴火聲營造溫馨氛圍，幫助深度放鬆'],
  '시냇물': ['溪流', '潺潺溪水聲讓心情平靜，減少雜念'],
  '잔잔한 강물': ['平靜的河流', '寬闊河流平靜流淌的聲音，助你安心休息'],
};

const natureSoundCatalog = <NatureSound>[
  NatureSound(
    name: '파도소리',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '규칙적인 파도 소리는 마음을 차분히 가라앉혀 깊은 휴식과 수면에 도움을 줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/wave_sound.mp3',
  ),
  NatureSound(
    name: '잔잔한 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '한결 부드럽고 잔잔하게 밀려오는 파도 소리로 편안한 휴식을 도와줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/wave_calm_sound.mp3',
  ),
  NatureSound(
    name: '갈매기와 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '갈매기 울음소리가 어우러진 파도 소리로 생생한 해변 분위기를 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/wave_seagull_sound.mp3',
  ),
  NatureSound(
    name: '바위에 부딪히는 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '바위에 세게 부딪히며 부서지는 파도 소리로 역동적인 바다를 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/wave_rocks_sound.mp3',
  ),
  NatureSound(
    name: '멀리서 들리는 갈매기',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '고요한 바닷가, 멀리서 은은하게 들려오는 갈매기 소리로 차분한 휴식을 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/wave_distant_seagull_sound.mp3',
  ),
  NatureSound(
    name: '거친 파도',
    category: '파도소리',
    icon: Icons.waves,
    emoji: '🌊',
    description: '거칠게 밀려와 부서지는 파도 소리로 힘 있는 바다를 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/wave_rough_sound.mp3',
  ),
  NatureSound(
    name: '빗소리',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '☔',
    description: '일정한 빗소리는 집중력을 높이고 불안한 마음을 편안하게 다독여줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/rain_sound.mp3',
  ),
  NatureSound(
    name: '창문에 떨어지는 비',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '🪟',
    description: '창문을 두드리는 부드러운 빗소리로 편안하게 잠들어보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/rain_window_sound.mp3',
  ),
  NatureSound(
    name: '숲속의 비와 새소리',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '🌲',
    description: '숲속에 내리는 빗소리와 새소리가 어우러져 마음을 편안하게 해줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/rain_forest_sound.mp3',
  ),
  NatureSound(
    name: '숲속의 거센 밤비',
    category: '빗소리',
    icon: Icons.water_drop_outlined,
    emoji: '🌙',
    description: '깊은 밤 숲속에 세차게 내리는 빗소리로 몰입감 있는 휴식을 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/rain_night_forest_sound.mp3',
  ),
  NatureSound(
    name: '새소리',
    category: '새소리',
    icon: Icons.forest_outlined,
    emoji: '🐦',
    description: '청아한 새소리는 스트레스를 줄이고 상쾌한 기분을 만들어줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/bird_sound.mp3',
  ),
  NatureSound(
    name: '뻐꾸기와 숲속 새소리',
    category: '새소리',
    icon: Icons.forest_outlined,
    emoji: '🌳',
    description: '뻐꾸기 소리가 어우러진 숲속의 새소리로 상쾌한 아침을 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/bird_forest_cuckoo_sound.mp3',
  ),
  NatureSound(
    name: '모닥불',
    category: '모닥불',
    icon: Icons.local_fire_department_outlined,
    emoji: '🔥',
    description: '타닥타닥 장작 타는 소리는 아늑한 분위기로 깊은 이완을 도와줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/campfire_sound.mp3',
  ),
  NatureSound(
    name: '시냇물',
    category: '시냇물',
    icon: Icons.water_outlined,
    emoji: '💧',
    description: '졸졸 흐르는 시냇물 소리는 마음을 편안하게 하고 잡생각을 줄여줘요',
    assetPath: 'https://files.ssing.kr/nature-sounds/stream_sound.mp3',
  ),
  NatureSound(
    name: '잔잔한 강물',
    category: '시냇물',
    icon: Icons.water_outlined,
    emoji: '🌊',
    description: '넓은 강물이 잔잔하게 흐르는 소리로 편안한 휴식을 느껴보세요',
    assetPath: 'https://files.ssing.kr/nature-sounds/stream_river_sound.mp3',
  ),
];