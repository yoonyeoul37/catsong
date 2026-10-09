# 설정: 위쪽 카드 3개 (켜지면 먹색 + "사용 중" + ⓘ 설명) / 줄 설정에 회색 설명 한 줄
import os, sys

PATH = os.path.join('lib', 'screens', 'settings_screen.dart')

QUICK_OLD_START = "  /// 자주 켜고 끄는 3칸 (누르면 바로 켜짐/꺼짐)\n"
QUICK_OLD_END = "  /// 포인트 색: 이름 + 아래 동그라미 10개"

QUICK_NEW = r'''  /// 자주 켜고 끄는 3칸 (누르면 바로 켜짐/꺼짐, 켜지면 카드 전체 먹색 · ⓘ 누르면 설명)
  Widget _quickTiles(ThemeProvider t) {
    final d = t.isDarkMode;
    Widget tile(IconData icon, String label, String info, bool on, VoidCallback onTap) {
      final bg = on ? _sText(d) : _sCard(d); // 켜지면 먹색 (다크 모드는 크림색)
      final fg = on ? _sBg(d) : _sText(d);
      final sub = on ? _sBg(d).withOpacity(0.7) : _sTextHint(d);
      return Expanded(
        child: GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 11),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: on ? _sBg(d).withOpacity(0.14) : _sIconBg(d),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 16, color: on ? fg : _sTextSub(d)),
                    ),
                    const Spacer(),
                    // ⓘ 누르면 무슨 기능인지 설명
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showQuickInfo(label, info, d),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                        child: Icon(Icons.info_outline_rounded, size: 16, color: sub),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(on ? '사용 중' : '꺼짐',
                    style: TextStyle(
                        color: on ? fg : _sTextHint(d),
                        fontSize: 11,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          tile(Icons.dark_mode_outlined, '다크 모드', '화면을 어둡게 바꿔요.\n밤에 눈이 편해요.', t.isDarkMode,
              () => t.setDarkMode(!t.isDarkMode)),
          const SizedBox(width: 8),
          tile(
              Icons.water_drop_outlined,
              '효과음',
              '수정·저장·삭제가 끝나면 물방울 소리로 알려줘요.\n진동 모드면 진동, 무음이면 조용해요.',
              t.feedbackSoundEnabled,
              () => t.setFeedbackSoundEnabled(!t.feedbackSoundEnabled)),
          const SizedBox(width: 8),
          tile(Icons.record_voice_over_outlined, '음성 안내', '앱을 켜고 끌 때\n짧은 인사말이 나와요.', t.voiceGreetingEnabled,
              () => t.setVoiceGreetingEnabled(!t.voiceGreetingEnabled)),
        ],
      ),
    );
  }

  /// 카드 ⓘ: 기능 설명 창
  void _showQuickInfo(String title, String info, bool d) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    showParanSheet(
      context,
      title: title,
      builder: (ctx, setSheet) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(info, style: TextStyle(color: _sTextSub(d), fontSize: 14, height: 1.6)),
      ),
    );
  }

'''

EDITS = [
    ('줄 설정: 설명 칸 받기',
     "    required IconData icon, required String title, String? subtitle,\n",
     "    required IconData icon, required String title, String? subtitle, String? desc,\n"),
    ('줄 설정: 설명 있으면 위아래 여백 조금 줄이기',
     "                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),\n                // 한 줄로",
     "                padding: EdgeInsets.symmetric(horizontal: 16, vertical: desc != null ? 11 : 14),\n                // 한 줄로"),
    ('줄 설정: 제목 아래 회색 설명 한 줄',
     "                  Expanded(\n"
     "                    child: Text(title,\n"
     "                        maxLines: 1,\n"
     "                        overflow: TextOverflow.ellipsis,\n"
     "                        style: TextStyle(color: _sText(isDarkMode), fontSize: 14.5)),\n"
     "                  ),\n",
     "                  Expanded(\n"
     "                    child: Column(\n"
     "                      crossAxisAlignment: CrossAxisAlignment.start,\n"
     "                      mainAxisSize: MainAxisSize.min,\n"
     "                      children: [\n"
     "                        Text(title,\n"
     "                            maxLines: 1,\n"
     "                            overflow: TextOverflow.ellipsis,\n"
     "                            style: TextStyle(color: _sText(isDarkMode), fontSize: 14.5)),\n"
     "                        if (desc != null) ...[\n"
     "                          const SizedBox(height: 2),\n"
     "                          Text(desc,\n"
     "                              maxLines: 1,\n"
     "                              overflow: TextOverflow.ellipsis,\n"
     "                              style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 11.5)),\n"
     "                        ],\n"
     "                      ],\n"
     "                    ),\n"
     "                  ),\n"),
    ('설명: 재생화면 스타일', "title: l.playerStyle, onTap:", "title: l.playerStyle, desc: '시디롬·파란포토·앨범 중에서 골라요', onTap:"),
    ('설명: 텍스트 변경', "title: l.fontChange, onTap:", "title: l.fontChange, desc: '앱 글꼴을 바꿔요', onTap:"),
    ('설명: 텍스트 크기', "title: l.textSize, onTap:", "title: l.textSize, desc: '앱 글자 크기를 키우거나 줄여요', onTap:"),
    ('설명: 홈 추천 카드', "                title: '홈 추천 카드',\n",
     "                title: '홈 추천 카드',\n                desc: '홈 맨 위에 날마다 바뀌는 카드',\n"),
    ('설명: 곡 정보 한꺼번에 정리', "title: '곡 정보 한꺼번에 정리',\n", "title: '곡 정보 한꺼번에 정리', desc: '제목·가수 이름을 깔끔하게 정리해요',\n"),
    ('설명: 앨범 사진 한꺼번에 찾기', "title: '앨범 사진 한꺼번에 찾기',\n", "title: '앨범 사진 한꺼번에 찾기', desc: '사진 없는 곡에 앨범 사진을 찾아 넣어요',\n"),
    ('설명: 이퀄라이저', "title: l.equalizer, onTap:", "title: l.equalizer, desc: '저음·고음 같은 소리 색을 맞춰요', onTap:"),
    ('설명: 곡마다 소리 크기 맞추기', "                title: '곡마다 소리 크기 맞추기',\n",
     "                title: '곡마다 소리 크기 맞추기',\n                desc: '유난히 큰 곡을 줄여 비슷하게 들려요',\n"),
    ('설명: 이어폰 연결하면 이어서 듣기', "                title: '이어폰 연결하면 이어서 듣기',\n",
     "                title: '이어폰 연결하면 이어서 듣기',\n                desc: '이어폰을 연결하면 듣던 걸 다시 틀어요',\n"),
    ('설명: 벨소리', "title: l.ringtone, onTap:", "title: l.ringtone, desc: '노래로 전화 벨소리를 만들어요', onTap:"),
    ('설명: 손전등', "title: l.flashlight, subtitle:", "title: l.flashlight, desc: '휴대폰 플래시를 켜요', subtitle:"),
    ('설명: SOS', "title: l.sos, subtitle:", "title: l.sos, desc: '플래시로 구조 신호를 깜빡여요', subtitle:"),
    ('설명: 위젯', "title: l.widget, onTap:", "title: l.widget, desc: '홈 화면에 파란소리 위젯을 놓아요', onTap:"),
    ('설명: 설정 도움말', "title: '설정 도움말',\n", "title: '설정 도움말', desc: '권한·배터리·알림 설정 방법',\n"),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        print('   프로젝트 맨 바깥 폴더(mp3_player_new)에서 실행해 주세요.')
        sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    t = raw.replace('\r\n', '\n')
    if '_showQuickInfo' in t:
        print('이미 적용돼 있어요')
        return
    ok = True
    a = t.find(QUICK_OLD_START)
    b = t.find(QUICK_OLD_END, a + 1) if a >= 0 else -1
    if a < 0 or b < 0:
        print('❌ 위쪽 카드 3개 바꾸기')
        ok = False
    else:
        t = t[:a] + QUICK_NEW + t[b:]
        print('✔ 위쪽 카드 3개 바꾸기 (먹색 + 사용 중 + ⓘ)')
    for name, old, new in EDITS:
        if t.count(old) != 1:
            print('❌', name)
            ok = False
            continue
        t = t.replace(old, new)
        print('✔', name)
    if not ok:
        print('\n못 찾은 곳이 있어서 아무것도 저장하지 않았어요.')
        sys.exit(1)
    if t.count('{') != t.count('}') or t.count('(') != t.count(')') or t.count('[') != t.count(']'):
        print('❌ 괄호 짝이 안 맞아요. 저장하지 않았어요.')
        sys.exit(1)
    if crlf:
        t = t.replace('\n', '\r\n')
    open(PATH, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요.')

main()
