# -*- coding: utf-8 -*-
# 안 나오는 해외 방송 → 같은 나라 비슷한 장르 인기 방송으로 넘기기
import sys, glob, os, shutil

def find(name):
    hits = glob.glob(os.path.join('lib', '**', name), recursive=True)
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

prov = [
('상태 바뀔 때 확인',
"""  void _setPlayerState(RadioPlayerState state) {
    _playerState = state;
    notifyListeners();
  }""",
"""  void _setPlayerState(RadioPlayerState state) {
    _playerState = state;
    if (state == RadioPlayerState.error) {
      _onStationFailed();
    } else if (state == RadioPlayerState.loading) {
      _similar = null;
    }
    notifyListeners();
  }

  // ── 안 나오는 방송 → 비슷한 방송 추천 (해외 방송만) ──
  final Set<String> _failedToday = {}; // 오늘 안 나왔던 방송은 추천 안 함
  String _failedDay = '';
  RadioStation? _similar;
  RadioStation? get similarStation => _playerState == RadioPlayerState.error ? _similar : null;

  static Set<String> _tagSet(RadioStation s) => (s.tags ?? '')
      .toLowerCase()
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet();

  void _onStationFailed() {
    final cur = _currentStation;
    _similar = null;
    if (cur == null) return;
    final now = DateTime.now();
    final day = '${now.year}-${now.month}-${now.day}';
    if (day != _failedDay) {
      _failedDay = day;
      _failedToday.clear();
    }
    _failedToday.add(cur.stationUuid);
    final code = cur.countryCode ?? '';
    if (code.isEmpty || code.toUpperCase() == 'KR') return;
    // 같은 나라 목록 (인기순) 에서 장르가 가장 많이 겹치는 방송, 같으면 더 인기 있는 쪽
    final pool = (_countryCode == code && _countryStations.isNotEmpty) ? _countryStations : _currentQueue;
    final tags = _tagSet(cur);
    var best = -1;
    for (final s in pool.take(400)) {
      if (s.stationUuid == cur.stationUuid || _failedToday.contains(s.stationUuid)) continue;
      if ((s.countryCode ?? code) != code) continue;
      final score = _tagSet(s).intersection(tags).length;
      if (score > best) {
        best = score;
        _similar = s;
      }
    }
  }

  /// '비슷한 방송 듣기' 누르면
  Future<void> playSimilar() async {
    final s = similarStation;
    if (s == null) return;
    final i = _currentQueue.indexWhere((x) => x.stationUuid == s.stationUuid);
    if (i >= 0) _currentQueueIndex = i;
    await playStation(s);
  }"""),
]

player = [
('오류 글자 아래 버튼',
"""                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
""",
"""                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      // 안 나오는 해외 방송: 같은 나라 비슷한 방송으로
                      if (isError && radioProvider.similarStation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              radioProvider.playSimilar();
                            },
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primaryColor.withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.skip_next_rounded, size: 18, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '비슷한 방송 듣기 · ${radioProvider.similarStation!.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
"""),
]

mini = [
('안 나올 때 글자',
"""                                    isLoading
                                        ? '접속 중...'
                                        : isPlaying""",
"""                                    isLoading
                                        ? '접속 중...'
                                        : radioProvider.playerState == RadioPlayerState.error
                                        ? '나오지 않아요'
                                        : isPlaying"""),
('비슷한 방송 듣기',
"""                                  if (isPlaying || radioProvider.currentStation != null) ...[""",
"""                                  // 안 나오는 해외 방송 → 같은 나라 비슷한 방송
                                  if (radioProvider.similarStation != null) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                        radioProvider.playSimilar();
                                      },
                                      child: Text('비슷한 방송 듣기 ›',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                  if (isPlaying || radioProvider.currentStation != null) ...["""),
]

jobs = [
    prepare(find('radio_provider.dart'), prov, '_onStationFailed'),
    prepare(find('radio_player_screen.dart'), player, 'playSimilar'),
    prepare(find('radio_mini_player.dart'), mini, 'playSimilar'),
]
for r in jobs:   # 모두 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak7')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak7)')
