# -*- coding: utf-8 -*-
# 해외 라디오: 현지 시각이 바뀔 때 '시간 글자'만 다시 그리기 (목록 전체를 20초마다 다시 그리지 않게)
import sys, glob, os, shutil

NAME = 'radio_country_stations_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_timeNow' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('시간 글자 따로 알리는 칸',
"  Timer? _clock; // 현지 시각을 계속 맞춤\n",
"""  Timer? _clock; // 현지 시각을 계속 맞춤
  /// 현지 시각 글자 (이 값만 바뀌어서 목록 전체가 다시 그려지지 않게)
  final ValueNotifier<String?> _timeNow = ValueNotifier<String?>(null);
"""),
('20초마다: 시간 글자만 바꾸기',
"""      _clock = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) setState(() {});
      });""",
"""      _timeNow.value = _localTimeText(widget.country.code);
      _clock = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) _timeNow.value = _localTimeText(widget.country.code);
      });"""),
('화면 닫을 때 정리',
"    _clock?.cancel();\n",
"    _clock?.cancel();\n    _timeNow.dispose();\n"),
('시간 표시: 글자만 다시 그리기',
"""                          Text(localTime,
                              style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 12.5)),""",
"""                          ValueListenableBuilder<String?>(
                            valueListenable: _timeNow,
                            builder: (_, t, __) => Text(t ?? localTime,
                                style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 12.5)),
                          ),"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')
shutil.copy(path, path + '.bak_clock')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_clock)')
