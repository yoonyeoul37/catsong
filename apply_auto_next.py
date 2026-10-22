# -*- coding: utf-8 -*-
# 안드로이드 오토(차 화면) 라디오 재생 화면 둘째 줄: "지금 프로그램 · 다음 방송 12:00 다음 프로그램"
# 차에 연결돼 있을 때만 (폰만 쓸 때 알림창 · 위젯 글자는 지금 그대로)
import os, sys

RP = os.path.join('lib', 'providers', 'radio_provider.dart')

EDITS = {
    RP: [
        (
"""import '../services/headset_resume.dart' show HeadsetResume;""",
"""import '../services/headset_resume.dart' show HeadsetResume;
import '../services/car_browse.dart' show CarBrowse;""",
        ),
        (
"""  void _updateNotification(String stationName) {""",
"""  /// 차 화면 재생 화면 둘째 줄: "지금 프로그램 · 다음 방송 12:00 다음 프로그램"
  /// 차에 연결돼 있을 때만 (아니면 null → 지금 글자 그대로) — 앱 재생 화면 '다음 방송'과 같은 규칙
  /// (편성표에서 지금 방송 다음 칸 · 오늘 마지막이면 첫 칸)
  String? _carLine(String stationName, String nowTitle, String nowStart) {
    if (!CarBrowse.inCarRecently || nowTitle.isEmpty) return null;
    final list = _scheduleListMap[stationName];
    if (list == null || list.length < 2) return null;
    String titleOf(Map<String, dynamic> p) => (p['program_title'] ?? p['Title'] ?? p['title'] ?? '').toString();
    String startOf(Map<String, dynamic> p) {
      for (final k in ['program_planned_start_time', 'StartTime', 'start_time']) {
        final v = p[k]?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    var i = nowStart.isEmpty ? -1 : list.indexWhere((p) => titleOf(p) == nowTitle && startOf(p) == nowStart);
    if (i < 0) i = list.indexWhere((p) => titleOf(p) == nowTitle);
    if (i < 0) return null;
    final next = list[(i + 1) % list.length];
    final t = titleOf(next);
    if (t.isEmpty || t == nowTitle) return null;
    var s = startOf(next);
    if (!s.contains(':')) {
      if (s.length >= 4) {
        var h = int.tryParse(s.substring(0, 2)) ?? 0;
        if (h >= 24) h -= 24;
        s = '${h.toString().padLeft(2, '0')}:${s.substring(2, 4)}';
      } else {
        s = '';
      }
    }
    return '$nowTitle · ${tr.radioNextProgram} ${s.isEmpty ? '' : '$s '}$t';
  }

  void _updateNotification(String stationName) {""",
        ),
        (
"""    _simpleHandler?.setRadioMediaItem(
      title: stationName,
      artist: artist,
      url: _currentStation?.streamUrl ?? '',
    );""",
"""    _simpleHandler?.setRadioMediaItem(
      title: stationName,
      artist: _carLine(stationName, programTitle, start) ?? artist, // 차에선 다음 방송까지
      url: _currentStation?.streamUrl ?? '',
    );""",
        ),
        (
"""        _simpleHandler?.setRadioMediaItem(
          title: title,
          artist: programTitle,
          url: '',
        );""",
"""        _simpleHandler?.setRadioMediaItem(
          title: title,
          artist: _carLine(title, programTitle, '') ?? programTitle, // 차에선 다음 방송까지
          url: '',
        );""",
        ),
    ],
}

MARK = (RP, '_carLine(')


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    if os.path.exists(MARK[0]):
        with open(MARK[0], 'rb') as f:
            if MARK[1].encode() in f.read():
                print('이미 적용돼 있어요')
                return
    out = {}
    ok = True
    for rel, pairs in EDITS.items():
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(rel, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[rel] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for rel, text in out.items():
        with open(rel, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
