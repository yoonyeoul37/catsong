# -*- coding: utf-8 -*-
# 1) 시작 화면 색: 검정 → 라이트는 크림색, 다크는 진한 갈색 (첫인사 바탕도 같은 색으로 맞춤)
# 2) 앱이 꺼져 있을 때 위젯 재생: 재생을 시작하고 바로 바탕화면으로 돌아가기
# 실행한 뒤:  dart run flutter_native_splash:create  →  flutter run
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if '_backup_widget' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.exists('pubspec.yaml') or not os.path.isdir('lib'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
if 'icon_background_color: "#F4EFE5"' in open('pubspec.yaml', encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)

writes = {}
ok = True
def edit(path, pairs):
    global ok
    if not path:
        print('❌ 파일을 못 찾았어요'); ok = False; return
    src, crlf = writes[path] if path in writes else load(path)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

edit('pubspec.yaml', [
    ('시작 화면 색 (안드로이드 11 이하)',
     '  color: "#17140F"                  # 다크/라이트 상관없이 어두운 바탕 (첫인사 사진과 자연스럽게)\n'
     '  color_dark: "#17140F"\n',
     '  color: "#F4EFE5"                  # 라이트: 앱과 같은 크림색 (첫인사 바탕도 같은 색)\n'
     '  color_dark: "#24221F"             # 다크: 앱과 같은 진한 갈색\n'),
    ('시작 화면 색 (안드로이드 12 이상)',
     '    color: "#17140F"\n'
     '    color_dark: "#17140F"\n',
     '    color: "#F4EFE5"\n'
     '    color_dark: "#24221F"\n'),
    ('아이콘 동그라미 배경도 같은 색',
     '    icon_background_color: "#17140F"       # 동그라미 배경을 바탕색과 같게 (잘린 티 안 나게)\n'
     '    icon_background_color_dark: "#17140F"',
     '    icon_background_color: "#F4EFE5"       # 동그라미 배경을 바탕색과 같게 (잘린 티 안 나게)\n'
     '    icon_background_color_dark: "#24221F"'),
])

edit(find('main.dart', 'lib'), [
    ('첫인사 바탕도 시작 화면과 같은 색 (번쩍임 없이)',
     '        child: Scaffold(\n          backgroundColor: Colors.black,\n          body: _IntroView(',
     '        child: Scaffold(\n'
     '          // 시작 화면과 같은 색 (라이트 크림 · 다크 진한 갈색) → 넘어갈 때 번쩍이지 않게\n'
     '          backgroundColor: context.watch<ThemeProvider>().isDarkMode\n'
     '              ? const Color(0xFF24221F)\n'
     '              : const Color(0xFFF4EFE5),\n'
     '          body: _IntroView('),
])

edit(find('MainActivity.kt', 'android'), [
    ('바탕화면으로 돌아가기',
     '                "takeWidgetGo" -> {\n',
     '                "moveToBack" -> {\n'
     '                    // 위젯 재생으로 켜졌을 때: 재생 시작 후 바탕화면으로 (음악은 계속)\n'
     '                    moveTaskToBack(true)\n'
     '                    result.success(true)\n'
     '                }\n'
     '                "takeWidgetGo" -> {\n'),
])

edit(find('home_screen.dart', 'lib'), [
    ('위젯 재생으로 켜졌으면 재생 후 바탕화면으로',
     "      case 'resume':\n        await HeadsetResume.widgetPlay(); // 위젯 재생: 마지막에 듣던 것\n        break;\n",
     "      case 'resume':\n        await HeadsetResume.widgetPlay(); // 위젯 재생: 마지막에 듣던 것\n"
     "        // 재생이 시작되면 바탕화면으로 돌아가기 (위젯에서 누른 그대로, 음악은 계속)\n"
     "        await Future.delayed(const Duration(milliseconds: 400));\n"
     "        try {\n"
     "          await const MethodChannel('kr.ssing.catsong/media').invokeMethod('moveToBack');\n"
     "        } catch (_) {}\n"
     "        break;\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_widget7')
for p, (src, crlf) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 — 이제 시작 화면을 새로 만들어야 해요:  dart run flutter_native_splash:create')
