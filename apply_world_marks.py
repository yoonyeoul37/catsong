# -*- coding: utf-8 -*-
# 해외 라디오 목록 작은 표시: 현지 시각 · HQ · 이름 속 주파수
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'radio_country_stations_screen.dart'), recursive=True)
if not hits:
    print('❌ radio_country_stations_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_freqFromName' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

freq_fn = r"""/// 이름 속 주파수 찾기 ('Power 98.7 FM' → 'FM 98.7', 'AM 1010 News' → 'AM 1010')
String? _freqFromName(String name) {
  String? check(String band, String num) {
    final v = double.tryParse(num.replaceAll(',', '.'));
    if (v == null) return null;
    if (band == 'FM' && v >= 76 && v <= 108) return 'FM ${num.replaceAll(',', '.')}';
    if (band == 'AM' && v >= 520 && v <= 1710 && v == v.roundToDouble()) return 'AM ${v.toInt()}';
    return null;
  }

  final a = RegExp(r'\b(FM|AM)\s*(\d{2,4}(?:[.,]\d{1,2})?)\b', caseSensitive: false).firstMatch(name);
  if (a != null) {
    final r = check(a.group(1)!.toUpperCase(), a.group(2)!);
    if (r != null) return r;
  }
  final b = RegExp(r'\b(\d{2,4}(?:[.,]\d{1,2})?)\s*(FM|AM|MHz)\b', caseSensitive: false).firstMatch(name);
  if (b != null) {
    final unit = b.group(2)!.toUpperCase();
    return check(unit == 'AM' ? 'AM' : 'FM', b.group(1)!);
  }
  return null;
}

class _StationTile extends StatelessWidget {"""

edits = [
('시계 불러오기',
"import 'dart:math' as math;\n",
"import 'dart:async';\nimport 'dart:math' as math;\n"),
('시계 칸',
"  bool get _isTrend => _chip == 'pop' && _sub == _popTrend;\n",
"""  bool get _isTrend => _chip == 'pop' && _sub == _popTrend;
  Timer? _clock; // 현지 시각을 계속 맞춤
"""),
('시계 켜기',
"""    _loadChip();
""",
"""    _loadChip();
    if (_localTimeText(widget.country.code) != null) {
      _clock = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) setState(() {});
      });
    }
"""),
('시계 끄기',
"""    _listCtrl.dispose();
""",
"""    _listCtrl.dispose();
    _clock?.cancel();
"""),
('현지 시각 값',
"""    final head = again.isEmpty ? 0 : 1;
""",
"""    final head = again.isEmpty ? 0 : 1;
    final localTime = _localTimeText(widget.country.code);
"""),
('개수 줄 (시작)',
"""                        Text(
                          _isTrend""",
"""                        Expanded(
                          child: Text(
                          _isTrend"""),
('개수 줄 (끝) + 현지 시각',
"""                          style: TextStyle(
                              color: baseColor.withOpacity(0.35), fontSize: 12.5),
                        ),
                      ],""",
"""                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: baseColor.withOpacity(0.35), fontSize: 12.5),
                        ),
                        ),
                        // 그 나라 지금 시각 (오른쪽 끝)
                        if (localTime != null) ...[
                          const SizedBox(width: 10),
                          Text(localTime,
                              style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 12.5)),
                        ],
                      ],"""),
('주파수 (방송 정보 → 없으면 이름에서)',
"""                      final freq = station.frequency;
                      final hasFreq = freq != null &&
                          freq.isNotEmpty &&
                          freq != 'null';
""",
"""                      final rawFreq = station.frequency;
                      final band = (rawFreq != null && rawFreq.isNotEmpty && rawFreq != 'null')
                          ? 'FM $rawFreq'
                          : _freqFromName(station.name);
"""),
('주파수 표시',
"""                      } else if (hasFreq) {
                        sub = [
                          'FM $freq',""",
"""                      } else if (band != null) {
                        sub = [
                          band,"""),
('HQ 표시',
"""                      if (sub.isEmpty) return const SizedBox.shrink();
                      return Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.5), fontSize: 12),
                      );""",
"""                      // 음질 좋은 방송 (192kbps 이상)
                      final hq = (station.bitrate ?? 0) >= 192;
                      if (sub.isEmpty && !hq) return const SizedBox.shrink();
                      return Row(
                        children: [
                          if (hq) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
                              ),
                              child: Text('HQ',
                                  style: TextStyle(
                                      color: baseColor.withOpacity(0.55),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      height: 1.2)),
                            ),
                            if (sub.isNotEmpty) const SizedBox(width: 6),
                          ],
                          if (sub.isNotEmpty)
                            Flexible(
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.5), fontSize: 12),
                              ),
                            ),
                        ],
                      );"""),
('이름 속 주파수 찾기', "class _StationTile extends StatelessWidget {", freq_fn),
]

for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

shutil.copy(path, path + '.bak5')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak5)')
