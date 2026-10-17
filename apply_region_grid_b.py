# -*- coding: utf-8 -*-
# 라디오 → 지역별: 칸 디자인 B안 (방송사별과 같은 모양: 지역 색 + 큰 아이콘) — 이전 칸 디자인은 지우고 바꿈
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_region_grid_b.py
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
E = json.loads('[["lib/screens/radio_korea_screen2.dart", "지역마다 아이콘", "    \'제주\': Color(0xFF1E5C4A),\\n  };\\n", "    \'제주\': Color(0xFF1E5C4A),\\n  };\\n\\n  /// 지역마다 아이콘 (방송사별 칸과 같은 모양: 큰 아이콘을 은은하게)\\n  static const Map<String, IconData> _regionIcons = {\\n    \'수도권\': Icons.location_city_rounded,\\n    \'강원\': Icons.terrain_rounded,\\n    \'대전/충남\': Icons.science_rounded,\\n    \'충북\': Icons.water_rounded,\\n    \'대구/경북\': Icons.account_balance_rounded,\\n    \'전북\': Icons.eco_rounded,\\n    \'광주/전남\': Icons.local_florist_rounded,\\n    \'부산/경남\': Icons.waves_rounded,\\n    \'제주\': Icons.beach_access_rounded,\\n  };\\n"], ["lib/screens/radio_korea_screen2.dart", "지역별 칸 디자인 B안 (방송사별과 같은 모양) — 이전 칸 디자인은 지움", "          child: Container(\\n            decoration: BoxDecoration(\\n              color: _regionColors[region] ?? baseColor.withOpacity(0.06),\\n              borderRadius: BorderRadius.circular(16),\\n              boxShadow: [\\n                BoxShadow(\\n                  color: Colors.black.withOpacity(0.25),\\n                  blurRadius: 12,\\n                  offset: const Offset(0, 6),\\n                ),\\n              ],\\n            ),\\n            alignment: Alignment.center,\\n            child: Column(\\n              mainAxisSize: MainAxisSize.min,\\n              children: [\\n                Text(\\n                  _regionLabel(region),\\n                  textAlign: TextAlign.center,\\n                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),\\n                ),\\n                const SizedBox(height: 4),\\n                Text(tr.channelsCount(count),\\n                    style: const TextStyle(color: Colors.white70, fontSize: 11)),\\n              ],\\n            ),\\n          ),\\n", "          // B안 (방송사별과 같은 모양): 지역 색 바탕(살짝 그라데이션) + 오른쪽 위 큰 아이콘(은은하게) + 왼쪽 위 작은 아이콘 + 왼쪽 아래 이름·채널 수\\n          child: Container(\\n            clipBehavior: Clip.antiAlias,\\n            decoration: BoxDecoration(\\n              gradient: LinearGradient(\\n                begin: Alignment.topLeft,\\n                end: Alignment.bottomRight,\\n                colors: [\\n                  _regionColors[region] ?? const Color(0xFF3A342A),\\n                  (_regionColors[region] ?? const Color(0xFF3A342A)).withOpacity(0.8),\\n                ],\\n              ),\\n              borderRadius: BorderRadius.circular(18),\\n              boxShadow: [\\n                BoxShadow(\\n                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.18),\\n                  blurRadius: 12,\\n                  offset: const Offset(0, 6),\\n                ),\\n              ],\\n            ),\\n            child: Stack(\\n              children: [\\n                // 오른쪽 위 큰 아이콘 (배경 무늬처럼 은은하게, 칸 밖으로 살짝 잘리게)\\n                Positioned(\\n                  right: -14,\\n                  top: -8,\\n                  child: Icon(_regionIcons[region] ?? Icons.place_rounded,\\n                      size: 92, color: Colors.white.withOpacity(0.14)),\\n                ),\\n                Padding(\\n                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),\\n                  child: Column(\\n                    crossAxisAlignment: CrossAxisAlignment.start,\\n                    children: [\\n                      Icon(_regionIcons[region] ?? Icons.place_rounded,\\n                          size: 18, color: Colors.white.withOpacity(0.9)),\\n                      // 이름·채널 수: 남은 높이를 다 쓰고, 길거나 글자를 크게 해도 칸 안에 맞게 살짝 작게\\n                      Expanded(\\n                        child: FittedBox(\\n                          fit: BoxFit.scaleDown,\\n                          alignment: Alignment.bottomLeft,\\n                          child: Column(\\n                            mainAxisSize: MainAxisSize.min,\\n                            crossAxisAlignment: CrossAxisAlignment.start,\\n                            children: [\\n                              Text(\\n                                _regionLabel(region),\\n                                maxLines: 1,\\n                                style: const TextStyle(\\n                                  color: Colors.white,\\n                                  fontSize: 18,\\n                                  fontWeight: FontWeight.w800,\\n                                  letterSpacing: -0.3,\\n                                ),\\n                              ),\\n                              const SizedBox(height: 2),\\n                              Text(\\n                                tr.channelsCount(count),\\n                                maxLines: 1,\\n                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11.5),\\n                              ),\\n                            ],\\n                          ),\\n                        ),\\n                      ),\\n                    ],\\n                  ),\\n                ),\\n              ],\\n            ),\\n          ),\\n"], ["lib/screens/radio_korea_screen2.dart", "Paransori 카드 모서리·그림자를 새 칸과 맞추기", "        decoration: BoxDecoration(\\n          color: bg,\\n          borderRadius: BorderRadius.circular(16),\\n          boxShadow: [\\n            BoxShadow(\\n              color: Colors.black.withOpacity(0.25),\\n              blurRadius: 12,\\n              offset: const Offset(0, 6),\\n            ),\\n          ],\\n        ),", "        decoration: BoxDecoration(\\n          color: bg,\\n          borderRadius: BorderRadius.circular(18), // 지역 칸과 같은 모서리·그림자\\n          boxShadow: [\\n            BoxShadow(\\n              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.18),\\n              blurRadius: 12,\\n              offset: const Offset(0, 6),\\n            ),\\n          ],\\n        ),"], ["lib/screens/radio_korea_screen2.dart", "Paransori 카드 왼쪽 여백을 새 칸과 맞추기", "        padding: const EdgeInsets.symmetric(horizontal: 16),\\n        alignment: Alignment.centerLeft,", "        padding: const EdgeInsets.symmetric(horizontal: 14),\\n        alignment: Alignment.centerLeft,"]]')
NEW = json.loads('{}')


def main():
    files = sorted({e[0] for e in E})
    texts, crlf = {}, {}
    for p in files:
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[p] = '\r\n' in raw
        texts[p] = raw.replace('\r\n', '\n')
    if "_regionIcons" in texts['lib/screens/radio_korea_screen2.dart']:
        print('이미 적용돼 있어요'); return
    ok = True
    for p, name, old, new in E:
        n = texts[p].count(old)
        if n == 1:
            texts[p] = texts[p].replace(old, new); print(f'✔ {os.path.basename(p)} - {name}')
        else:
            print(f'❌ {os.path.basename(p)} - {name} (찾을 코드가 {n}군데)'); ok = False
    for p in NEW:
        if os.path.exists(p):
            print(f'❌ {p} 가 이미 있어요 (덮어쓰지 않음)'); ok = False
    if not ok:
        print('\n❌ 문제가 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for p in files:
        t = texts[p].replace('\n', '\r\n') if crlf[p] else texts[p]
        open(p, 'wb').write(t.encode('utf-8'))
    for p, t in NEW.items():
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'wb').write(t.replace('\n', '\r\n').encode('utf-8'))
        print(f'✔ 새 파일 {p}')
    print('\n완료! flutter run 해 주세요.')


main()
