# -*- coding: utf-8 -*-
# 라디오 방송 화면: 편성표 받기 전 설명 카드가 번쩍 보이던 것 고치기
#  - 편성표를 소리 연결 뒤가 아니라 틀자마자 받기 시작 (더 빨리 나옴)
#  - 받는 동안은 설명 카드 자리 비워 두기, 다 받았는데 편성표가 없으면 그때 바로 설명 카드
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python apply_radio_desc.py
import os, sys, json

FILES = {'radio': 'lib/providers/radio_provider.dart', 'screen': 'lib/screens/radio_player_screen.dart'}
EDITS = json.loads(r"""[["radio", "편성표 받는 중 표시 추가", "  final Map<String, List<Map<String, dynamic>>> _scheduleListMap = {};\n", "  final Map<String, List<Map<String, dynamic>>> _scheduleListMap = {};\n  final Set<String> _scheduleLoading = {}; // 지금 인터넷에서 편성표 받는 중인 방송\n  /// 편성표를 받는 중인지 (받는 동안은 설명 카드 안 보여 주기)\n  bool isScheduleLoading(String name) => _scheduleLoading.contains(name);\n"], ["radio", "틀자마자 편성표 받기 시작", "      final qIdx = _currentQueue.indexWhere((s) => s.name == station.name);\n      if (qIdx >= 0) _currentQueueIndex = qIdx;\n      notifyListeners();\n", "      final qIdx = _currentQueue.indexWhere((s) => s.name == station.name);\n      if (qIdx >= 0) _currentQueueIndex = qIdx;\n      _startSchedule(station); // 편성표는 소리 연결을 기다리지 않고 바로 받기 시작\n      notifyListeners();\n"], ["radio", "소리 연결 뒤에 받던 편성표 코드 빼기 (위로 옮김)", "      // JSON 편성표 확인 (KBS/MBC/SBS 아닌 경우만)\n      if (station.name == '국방FM') {\n        fetchKfnSchedule();\n      }\n      // KBS 편성표\n      if (station.broadcaster == null && station.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {\n        fetchScheduleByUrl(station.name, station.streamUrl);\n      } else if (station.name.contains('KBS')) {\n        fetchScheduleByUrl(station.name, station.streamUrl);\n      }\n      // MBC/SBS 편성표\n      if (station.name == 'MBC 표준FM' || station.name == 'MBC FM4U') {\n        fetchMbcSchedule(station.name);\n      }\n      if (station.name == 'SBS 파워FM' || station.name == 'SBS 러브FM') {\n        fetchSbsSchedule(station.name);\n      }\n      if (station.name == 'EBS 반디') {\n        fetchEbsBandiSchedule();\n      }\n      if (station.name == 'EBS FM') {\n        fetchEbsFmSchedule();\n      }\n      final isKbsMbcSbs = station.name.contains('KBS') ||\n          _mbcChannelTypes.containsKey(station.name) || // 서울 MBC만 (지역 MBC는 편성표 파일 사용)\n          station.name.contains('SBS');\n      if (!isKbsMbcSbs && _scheduleService.hasSchedule(station.name)) {\n        final program = _scheduleService.getCurrentProgram(station.name);\n        if (program != null) {\n          _currentProgramMap[station.name] = {\n            'program_title': program['title'],\n            'start_time': program['start'],\n            'end_time': program['end'],\n            'is_rerun': false,\n            'image': program['image'], // 편성표 파일에 사진이 있으면 (CBS)\n          };\n\n          _nowPlayingMap[station.name] = program['title'] as String? ?? '';\n          notifyListeners();\n        }\n        _scheduleListMap[station.name] =\n            _scheduleService.getScheduleList(station.name).map((p) => {\n              'program_title': p['title'],\n              'start_time': p['start'],\n              'end_time': p['end'],\n              'image': p['image'],\n            }).toList();\n        notifyListeners();\n      }\n", ""], ["radio", "편성표 받기 함수 추가", "  String _getReferer(RadioStation station) {\n", "  /// 편성표 받기 시작 (방송을 틀 때마다) — 받는 동안은 '받는 중'이라 화면에 설명 카드를 안 보여 줌\n  /// (예전엔 소리가 연결된 뒤에 받아서 그동안 설명 카드가 번쩍 보였음 → 이제는 틀자마자 받기 시작)\n  void _startSchedule(RadioStation station) {\n    final name = station.name;\n    final jobs = <Future<void>>[];\n    // JSON 편성표 확인 (KBS/MBC/SBS 아닌 경우만)\n    if (name == '국방FM') {\n      jobs.add(fetchKfnSchedule());\n    }\n    // KBS 편성표\n    if (station.broadcaster == null && station.streamUrl.contains('cfpwwwapi.kbs.co.kr')) {\n      jobs.add(fetchScheduleByUrl(name, station.streamUrl));\n    } else if (name.contains('KBS')) {\n      jobs.add(fetchScheduleByUrl(name, station.streamUrl));\n    }\n    // MBC/SBS 편성표\n    if (name == 'MBC 표준FM' || name == 'MBC FM4U') {\n      jobs.add(fetchMbcSchedule(name));\n    }\n    if (name == 'SBS 파워FM' || name == 'SBS 러브FM') {\n      jobs.add(fetchSbsSchedule(name));\n    }\n    if (name == 'EBS 반디') {\n      jobs.add(fetchEbsBandiSchedule());\n    }\n    if (name == 'EBS FM') {\n      jobs.add(fetchEbsFmSchedule());\n    }\n    final isKbsMbcSbs = name.contains('KBS') ||\n        _mbcChannelTypes.containsKey(name) || // 서울 MBC만 (지역 MBC는 편성표 파일 사용)\n        name.contains('SBS');\n    // 편성표 파일(schedule.json)에 있는 방송은 바로 채움\n    if (!isKbsMbcSbs && _scheduleService.hasSchedule(name)) {\n      final program = _scheduleService.getCurrentProgram(name);\n      if (program != null) {\n        _currentProgramMap[name] = {\n          'program_title': program['title'],\n          'start_time': program['start'],\n          'end_time': program['end'],\n          'is_rerun': false,\n          'image': program['image'], // 편성표 파일에 사진이 있으면 (CBS)\n        };\n        _nowPlayingMap[name] = program['title'] as String? ?? '';\n      }\n      _scheduleListMap[name] =\n          _scheduleService.getScheduleList(name).map((p) => {\n            'program_title': p['title'],\n            'start_time': p['start'],\n            'end_time': p['end'],\n            'image': p['image'],\n          }).toList();\n    }\n    // 인터넷에서 받는 편성표: 다 받을 때까지 '받는 중' → 끝나면 풀고 화면 다시 그리기\n    if (jobs.isEmpty) return;\n    _scheduleLoading.add(name);\n    () async {\n      try {\n        await Future.wait(jobs);\n      } catch (_) {}\n      _scheduleLoading.remove(name);\n      notifyListeners();\n    }();\n  }\n\n  String _getReferer(RadioStation station) {\n"], ["screen", "받는 중엔 설명 카드 안 보이게", "                      ] else if (radioProvider.descriptionFor(current.name) != null) ...[\n", "                      ] else if (radioProvider.currentStation != null &&\n                          !radioProvider.isScheduleLoading(current.name) && // 편성표 받는 중엔 비워 두기 (깜빡임 방지)\n                          radioProvider.descriptionFor(current.name) != null) ...[\n"]]""")

def main():
    texts, crlf = {}, {}
    for k, p in FILES.items():
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[k] = '\r\n' in raw
        texts[k] = raw.replace('\r\n', '\n')
    if 'void _startSchedule(' in texts['radio'] and 'isScheduleLoading(current.name)' in texts['screen']:
        print('이미 적용돼 있어요'); return
    ok = True
    for f, name, old, new in EDITS:
        n = texts[f].count(old)
        if n == 1:
            texts[f] = texts[f].replace(old, new)
            print(f'✔ {os.path.basename(FILES[f])} - {name}')
        else:
            print(f'❌ {os.path.basename(FILES[f])} - {name} (찾을 코드가 {n}군데)'); ok = False
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for k, p in FILES.items():
        t = texts[k].replace('\n', '\r\n') if crlf[k] else texts[k]
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n완료! 라디오 설명 카드 깜빡임을 고쳤어요.')

if __name__ == '__main__':
    main()
