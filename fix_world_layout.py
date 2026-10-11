# -*- coding: utf-8 -*-
# 고침: 화면 정리 스크립트가 지워 버린 함수들(요즘 뜨는 · 칩 기억 · 다시 듣기) 다시 넣기
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'radio_country_stations_screen.dart'), recursive=True)
if not hits:
    print('❌ radio_country_stations_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'Widget _againRow(' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)
FUNCS = r"""  // ── 인기 칩 안: 많이 듣는 · 요즘 뜨는 ──
  bool _hasTrend(List<RadioStation> all, RadioProvider radio) =>
      all.where((s) => radio.trendOf(s.stationUuid) > 0).length >= 5;

  // ── 나라마다 마지막으로 고른 칩 기억 ──
  String get _chipKey => 'radioChip_${widget.country.code}';

  Future<void> _loadChip() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_chipKey);
    if (v != null && mounted) setState(() => _savedChip = v);
  }

  void _saveChip() {
    final v = '$_chip|${_sub ?? ''}';
    SharedPreferences.getInstance().then((p) => p.setString(_chipKey, v));
  }

  /// 방송을 불러온 뒤 한 번: 저장해 둔 칩이 이 나라에 있으면 다시 골라 줌
  void _restoreChip(List<RadioStation> all, RadioProvider radio) {
    final v = _savedChip;
    if (v == null) return;
    _savedChip = null;
    final i = v.indexOf('|');
    final chip = i < 0 ? v : v.substring(0, i);
    final sub = i < 0 ? '' : v.substring(i + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (chip == 'pop') {
        if (sub == _popTrend && _hasTrend(all, radio)) setState(() => _sub = _popTrend);
        return;
      }
      final opts = _optionsFor(chip, all, radio);
      if (opts.isEmpty) return;
      setState(() {
        _chip = chip;
        _sub = opts.any((o) => o.$1 == sub) ? sub : opts.first.$1;
      });
    });
  }

  // ── 맨 위 '다시 듣기': 이 나라에서 최근 들은 방송 + 즐겨찾기 ──
  List<RadioStation> _againList(RadioProvider radio) {
    final code = widget.country.code;
    final seen = <String>{};
    return [
      ...radio.recentlyListened.where((s) => s.countryCode == code),
      ...radio.favorites.where((s) => s.countryCode == code),
    ].where((s) => seen.add(s.stationUuid)).take(12).toList();
  }

  Widget _againRow(List<RadioStation> list, RadioProvider radio, Color baseColor) {
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final cur = radio.currentStation?.stationUuid;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('다시 듣기',
              style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final s = list[i];
                final on = s.stationUuid == cur;
                return GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    radio.setQueue(list, i);
                    // 처음 누르면 바로 재생, 듣는 중인 방송을 또 누르면 상세 화면
                    if (!on) {
                      radio.playStation(s);
                      return;
                    }
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => RadioPlayerScreen(station: s, stationList: list, currentIndex: i),
                        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 54,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: on ? accent : Colors.transparent, width: 2),
                          ),
                          child: StationLogo(logoUrl: s.logoUrl, name: s.name, size: 46),
                        ),
                        const SizedBox(height: 5),
                        Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: on ? accent : baseColor.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: baseColor.withOpacity(0.16)),
        ],
      ),
    );
  }

  /// 목록 맨 아래: 다음 방송 불러오는 중"""
anchor = "  /// 목록 맨 아래: 다음 방송 불러오는 중"
n = s.count(anchor)
if n != 1:
    print(f'❌ 넣을 자리를 {n}개 찾았어요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
s = s.replace(anchor, FUNCS)
print('✔ 요즘 뜨는 · 칩 기억 · 다시 듣기 함수 다시 넣음')
shutil.copy(path, path + '.bak9')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak9)')
