# -*- coding: utf-8 -*-
# 아침 알람 고치기 3: 알람으로 켜질 때 첫인삿말 "안녕하세요"가 잠깐 나오던 것 막기
# 왜: 안드로이드가 앱을 켜는 순서가 폰마다 달라서, "알람 때문에 켜졌다"는 신호가 인삿말보다 늦게 올 때가 있음
# 고친 방법: 인삿말을 틀기 전에 "지금 화면이 알람으로 열렸는지" 폰에 직접 물어보고, 알람이면 인삿말 없이 바로 알람 화면
# (apply_alarm_fix2.py 까지 실행한 뒤에)
import os, sys, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')
MAIN = os.path.join(LIB, 'main.dart')
SERVICE = os.path.join(LIB, 'services', 'alarm_service.dart')

KT_EDITS = [
    ('MainActivity: 지금 화면이 알람으로 열렸는지',
     "                    \"takeLaunchAlarm\" -> {\n",
     "                    \"isAlarmIntent\" -> {\n"
     "                        // 지금 화면이 알람(전체 화면 알림)으로 열렸는지\n"
     "                        result.success(intent?.action == \"kr.ssing.catsong.ALARM\")\n"
     "                    }\n"
     "                    \"takeLaunchAlarm\" -> {\n"),
    ('MainActivity: 알람 끝나면 표시 지우기',
     "                        AlarmReceiver.cancelNotification(this@MainActivity)\n"
     "                        showOverLock(false)\n",
     "                        AlarmReceiver.cancelNotification(this@MainActivity)\n"
     "                        intent?.setAction(android.content.Intent.ACTION_MAIN) // 알람 표시 지우기\n"
     "                        showOverLock(false)\n"),
]

SERVICE_EDITS = [
    ('알람: 폰에 직접 물어보기',
     "  /// 알람 화면 띄우기 (화면이 아직 준비 안 됐으면 조금 기다렸다가)\n",
     "  /// 지금 화면이 알람으로 열렸는지 폰에 직접 물어보기 (신호가 늦게 와도 확실하게)\n"
     "  static Future<bool> isAlarmIntent() async {\n"
     "    try {\n"
     "      return await _ch.invokeMethod('isAlarmIntent') == true;\n"
     "    } catch (_) {\n"
     "      return false;\n"
     "    }\n"
     "  }\n"
     "\n"
     "  /// 알람 화면 띄우기 (화면이 아직 준비 안 됐으면 조금 기다렸다가)\n"),
]

MAIN_EDITS = [
    ('main: 인삿말 전에 알람인지 확인',
     "    if (AlarmService.launchedByAlarm) return; // 알람 때는 첫인사 안 함\n",
     "    if (AlarmService.launchedByAlarm) return; // 알람 때는 첫인사 안 함\n"
     "    // 알람으로 열린 화면인지 폰에 한 번 더 확인 → 알람이면 인삿말 없이 바로 알람 화면\n"
     "    if (await AlarmService.isAlarmIntent()) {\n"
     "      AlarmService.showRing();\n"
     "      return;\n"
     "    }\n"
     "    if (!mounted || AlarmService.launchedByAlarm) return;\n"),
]

MARK = 'isAlarmIntent'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    hits = glob.glob(os.path.join(ROOT, 'android', 'app', 'src', 'main', 'kotlin', '**', 'MainActivity.kt'),
                     recursive=True)
    if len(hits) != 1:
        print('❌ MainActivity.kt 를 못 찾았어요 (android/app/src/main/kotlin 안)')
        sys.exit(1)
    act = hits[0]
    for p in (MAIN, SERVICE):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(SERVICE, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((act, KT_EDITS), (SERVICE, SERVICE_EDITS), (MAIN, MAIN_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. 앱을 완전히 끄고 flutter run 으로 다시 켠 뒤, 알람을 한 번 더 저장해 주세요.')


if __name__ == '__main__':
    main()
