# -*- coding: utf-8 -*-
# 배터리 창: 처음 설치할 때 X → 이어폰 이어서 듣기 / 아침 알람 켤 때만 (기능마다 한 번)
import os, sys

def find(name, sub):
    p = os.path.join('lib', sub, name)
    if os.path.exists(p): return p
    for root, _, files in os.walk('lib'):
        if name in files: return os.path.join(root, name)
    return None

FILES = {
    'main.dart': find('main.dart', ''),
    'headset_resume.dart': find('headset_resume.dart', 'services'),
    'settings_screen.dart': find('settings_screen.dart', 'screens'),
    'alarm_screen.dart': find('alarm_screen.dart', 'screens'),
}

EDITS = {
'main.dart': [
('처음 켤 때 배터리 창 빼기',
"""      // 권한 허용 후 배터리 최적화 요청
      if (musicProvider.hasPermission) {
        await Future.delayed(const Duration(seconds: 1));
        await _checkBatteryOptimization();
      } else {
        // 권한 변경 감지 후 배터리 최적화 요청
        musicProvider.addListener(() async {
          if (musicProvider.hasPermission) {
            await Future.delayed(const Duration(seconds: 1));
            await _checkBatteryOptimization();
          }
        });
      }
""",
"""      // (배터리 창은 처음에 안 띄움 → 이어폰 이어서 듣기·아침 알람 켤 때만 물어봄)
"""),
('안 쓰는 배터리 함수 빼기',
"""  Future<void> _checkBatteryOptimization() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('battery_opt_asked') ?? false;
    if (asked) return;
    try {
      const platform = MethodChannel('kr.ssing.catsong/media');
      final isOptimized = await platform.invokeMethod('isBatteryOptimized');
      if (isOptimized == true && mounted) {
        await platform.invokeMethod('requestBatteryOptimization');
        await prefs.setBool('battery_opt_asked', true);
      }
    } catch (e) {
      debugPrint('배터리 최적화 확인 오류: $e');
    }
  }

""", ""),
],
'headset_resume.dart': [
('화면 도구 불러오기',
"""import 'package:flutter/foundation.dart';
""",
"""import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext;
import '../widgets/paran_dialog.dart';
"""),
('배터리 묻기 함수',
"""  static Future<void> setMode(int m) async {""",
"""  /// 배터리 사용 "제한 없음" 부탁 — 필요한 기능을 켤 때만, 기능마다 한 번만
  /// (이미 제한 없음이면 안 물어봄)
  static Future<void> askBattery(BuildContext context, String key, String why) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool('battery_ask_$key') ?? false) return;
      final optimized = await _ch.invokeMethod('isBatteryOptimized');
      if (optimized != true || !context.mounted) return;
      await p.setBool('battery_ask_$key', true);
      final go = await showParanConfirm(
        context,
        title: '배터리 사용을 "제한 없음"으로',
        message: why,
        confirmLabel: '허용하기',
        cancelLabel: '나중에',
      );
      if (go) await _ch.invokeMethod('requestBatteryOptimization');
    } catch (_) {}
  }

  static Future<void> setMode(int m) async {"""),
],
'settings_screen.dart': [
('이어폰 이어서 듣기 켤 때 묻기',
"""                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    HeadsetResume.setMode(i);
                    Navigator.pop(ctx);
                  },""",
"""                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    HeadsetResume.setMode(i);
                    Navigator.pop(ctx);
                    // 켤 때만 배터리 부탁 (한 번만)
                    if (i > 0) {
                      HeadsetResume.askBattery(context, 'headset',
                          '폰이 오래 쉬고 있을 때도 이어폰 연결을 바로 알아차리려면 배터리 사용을 "제한 없음"으로 해 주세요.\\n허용 안 해도 쓸 수 있지만, 가끔 늦거나 안 될 수 있어요.');
                    }
                  },"""),
],
'alarm_screen.dart': [
('불러오기',
"""import '../services/alarm_service.dart';
""",
"""import '../services/alarm_service.dart';
import '../services/headset_resume.dart';
"""),
('알람 켤 때 묻기',
"""        if (go) AlarmService.openFullScreenSettings();
      }
    }""",
"""        if (go) AlarmService.openFullScreenSettings();
      }
      // 배터리 사용 "제한 없음" 부탁 (한 번만)
      if (mounted) {
        await HeadsetResume.askBattery(context, 'alarm',
            '정해진 시간에 알람 곡을 틀려면 배터리 사용을 "제한 없음"으로 해 주는 게 좋아요.\\n허용 안 해도 대부분 잘 울리지만, 일부 폰은 절전 때문에 늦을 수 있어요.');
      }
    }"""),
],
}

if FILES['headset_resume.dart'] and 'askBattery(' in open(FILES['headset_resume.dart'], encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
results = {}
for fname, edits in EDITS.items():
    path = FILES[fname]
    if not path:
        ok = False; print('❌', fname, '파일을 못 찾음'); continue
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    src = raw.replace('\r\n', '\n')
    for name, old, new in edits:
        n = src.count(old)
        if n == 1:
            src = src.replace(old, new); print('✔', fname, '-', name)
        else:
            ok = False; print('❌', fname, '-', name, '(못 찾음)' if n == 0 else f'({n}곳)')
    for a, b in ('()', '[]', '{}'):
        if src.count(a) != src.count(b):
            ok = False; print('❌', fname, '괄호 개수가 안 맞아요', a, b)
    results[path] = (src, crlf)

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

for path, (src, crlf) in results.items():
    out = src.replace('\n', '\r\n') if crlf else src
    open(path, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (4개 파일)')
