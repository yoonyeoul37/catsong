# -*- coding: utf-8 -*-
# 홈 '잠시 쉬어가요': 새 미니어처 사진 6장 + 유리 띠 + 도현 글꼴 한 줄
import sys, glob, os, shutil

NAME = 'home_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'assets/rest_wave.jpg' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)
need = ['rest_wave', 'rest_rain', 'rest_bird', 'rest_fire', 'rest_stream', 'rest_radio']
missing = [n + '.jpg' for n in need if not os.path.exists(f'assets/{n}.jpg')]
if missing:
    print('❌ assets 폴더에 사진이 없어요: ' + ', '.join(missing)); sys.exit(1)

edits = [
('자연소리 사진 → 새 사진',
"""      switch (s.category) {
        case '파도소리':
          const waves = [
            'assets/nature_wave_bg.png',
            'assets/wave2.png',
            'assets/wave3.png',
            'assets/wave4.png',
            'assets/wave5.png',
            'assets/wave6.png',
          ];
          return waves[s.name.hashCode.abs() % waves.length];
        case '빗소리':
          return 'assets/nature_rain_bg.png';
        case '새소리':
          return 'assets/nature_bird_bg.png';
        case '모닥불':
          return 'assets/nature_fire_bg.png';
        case '시냇물':
          return 'assets/nature_stream_bg.png';
        default:
          return 'assets/nature_wave_bg.png';
      }""",
"""      // 잠시 쉬어가요 전용 작은 사진 (재생 화면 배경은 그대로)
      switch (s.category) {
        case '파도소리':
          return 'assets/rest_wave.jpg';
        case '빗소리':
          return 'assets/rest_rain.jpg';
        case '새소리':
          return 'assets/rest_bird.jpg';
        case '모닥불':
          return 'assets/rest_fire.jpg';
        case '시냇물':
          return 'assets/rest_stream.jpg';
        default:
          return 'assets/rest_wave.jpg';
      }"""),
('라디오 칸: 이모지 빼고 새 사진',
"""        '📻 ${todayRadio.$1}',
        // 라디오 사진 10장 중 하루에 한 장
        'assets/rest_radio_${(daySeed % 10) + 1}.png',""",
"""        todayRadio.$1,
        'assets/rest_radio.jpg',"""),
('카드 그림자 가볍게 (위 카드와 같게)',
"""                            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.24),
                            blurRadius: 22,
                            offset: const Offset(0, 10),""",
"""                            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.14),
                            blurRadius: 16,
                            offset: const Offset(0, 6),"""),
('사진 위 어두운 칸 없애기',
"""                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.12),
                                  ],
                                  stops: const [0.55, 1.0],
                                ),
                              ),
                            ),
""", ""),
('글자: 유리 띠 + 도현 한 줄',
"""                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.08),
                                      border: Border(
                                        top: BorderSide(color: Colors.white.withOpacity(0.16)),
                                      ),
                                    ),
                                    child: Text(item.$1,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.9),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.7),
                                                blurRadius: 14,
                                                offset: const Offset(0, 2),
                                              ),
                                            ])),""",
"""                                    padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
                                    // 유리 띠 (위 카드와 같은 모양, 어두운 사진에서도 읽히게 조금 더 진하게)
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBF8F2).withOpacity(0.78),
                                      border: Border(
                                        top: BorderSide(color: Colors.white.withOpacity(0.6)),
                                      ),
                                    ),
                                    child: Text(item.$1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.doHyeon( // 로고와 같은 글꼴
                                            color: const Color(0xFF17140F),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w400)),"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')
shutil.copy(path, path + '.bak_rest')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_rest)')
