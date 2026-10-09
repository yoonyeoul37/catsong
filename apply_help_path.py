# -*- coding: utf-8 -*-
# 설정 도움말 · 동영상 권한 화면에 "직접 찾아갈 때" 전체 경로 적기
# (apply_help.py 를 먼저 실행한 뒤에 실행)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HELP = os.path.join(ROOT, 'lib', 'screens', 'settings_help_screen.dart')
VIDEO = os.path.join(ROOT, 'lib', 'screens', 'video_screen.dart')

HELP_EDITS = [
    ('도움말: 경로 칸 추가',
     "  final String? note;\n"
     "  const _HelpTopic(this.icon, this.title, this.when, this.android, {this.ios, this.note});\n",
     "  final String? note;\n"
     "  final String path; // 직접 찾아갈 때 (안드로이드)\n"
     "  final String? iosPath; // 직접 찾아갈 때 (아이폰)\n"
     "  const _HelpTopic(this.icon, this.title, this.when, this.android,\n"
     "      {this.ios, this.note, required this.path, this.iosPath});\n"),
    ('도움말: 음악·동영상 경로',
     "    note: '돌아오면 바로 목록이 나와요',\n  ),\n",
     "    note: '돌아오면 바로 목록이 나와요',\n"
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 권한 → 음악 및 오디오 / 사진 및 동영상',\n"
     "    iosPath: '설정 → 파란소리 → 미디어 및 Apple Music · 사진',\n"
     "  ),\n"),
    ('도움말: 배터리 경로',
     "    note: '폰마다 \"최적화 안 함\"이라고 나올 수도 있어요',\n  ),\n",
     "    note: '폰마다 \"최적화 안 함\"이라고 나올 수도 있어요',\n"
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 배터리 → 제한 없음',\n"
     "  ),\n"),
    ('도움말: 알림 경로',
     "    ios: ['아래 설정 열기 누르기', '알림 누르기', '알림 허용 켜기'],\n  ),\n",
     "    ios: ['아래 설정 열기 누르기', '알림 누르기', '알림 허용 켜기'],\n"
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 알림 → 알림 허용',\n"
     "    iosPath: '설정 → 파란소리 → 알림 → 알림 허용',\n"
     "  ),\n"),
    ('도움말: 벨소리 경로',
     "    ['아래 설정 열기 누르기', '시스템 설정 변경(설정 변경) 누르기', '허용 켜기'],\n  ),\n",
     "    ['아래 설정 열기 누르기', '시스템 설정 변경(설정 변경) 누르기', '허용 켜기'],\n"
     "    path: '설정 → 애플리케이션(앱) → 파란소리 → 시스템 설정 변경 → 허용',\n"
     "  ),\n"),
    ('도움말: 경로를 작은 회색 칸으로 보여주기',
     "                    const SizedBox(height: 6),\n"
     "                    // 먹색 버튼: 이 앱 설정 화면 바로 열기\n",
     "                    // 직접 찾아갈 때 전체 경로 (폰 회사마다 메뉴 이름이 조금 달라요)\n"
     "                    Container(\n"
     "                      width: double.infinity,\n"
     "                      margin: const EdgeInsets.only(top: 4, bottom: 4),\n"
     "                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),\n"
     "                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),\n"
     "                      child: Column(\n"
     "                        crossAxisAlignment: CrossAxisAlignment.start,\n"
     "                        children: [\n"
     "                          Text('직접 찾아갈 때',\n"
     "                              style: TextStyle(color: hint, fontSize: 11, fontWeight: FontWeight.w600)),\n"
     "                          const SizedBox(height: 3),\n"
     "                          Text(isIos ? (t.iosPath ?? t.path) : t.path,\n"
     "                              style: TextStyle(color: sub, fontSize: 12, height: 1.45)),\n"
     "                        ],\n"
     "                      ),\n"
     "                    ),\n"
     "                    const SizedBox(height: 6),\n"
     "                    // 먹색 버튼: 이 앱 설정 화면 바로 열기\n"),
]

VIDEO_EDITS = [
    ('동영상 권한: 직접 찾아갈 때 경로',
     "                  step(3, '허용 고르고 돌아오기', note: '돌아오면 바로 목록이 나와요'),\n",
     "                  step(3, '허용 고르고 돌아오기', note: '돌아오면 바로 목록이 나와요'),\n"
     "                  // 버튼 대신 직접 찾아갈 때 (폰 회사마다 메뉴 이름이 조금 달라요)\n"
     "                  Padding(\n"
     "                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),\n"
     "                    child: Text('직접 찾아갈 때: 설정 → 애플리케이션(앱) → 파란소리 → 권한 → 사진 및 동영상',\n"
     "                        textAlign: TextAlign.center,\n"
     "                        style: TextStyle(color: hint, fontSize: 11.5, height: 1.5)),\n"
     "                  ),\n"),
]

MARK = 'iosPath'


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
    for p in (HELP, VIDEO):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '(apply_help.py 를 먼저 실행해 주세요)')
            sys.exit(1)
    if MARK in open(HELP, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((HELP, HELP_EDITS), (VIDEO, VIDEO_EDITS)):
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
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
