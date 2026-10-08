# 동영상 "소리만 듣기" (화면 꺼도·다른 앱 켜도 소리 계속) — video_screen.dart
# 실행: python apply_video_audio_only.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
DONE_MARK = 'videoAudioOnly'

EDITS = [
    ("재생 화면: 앱 나감/화면 꺼짐 알아채기",
     "class _VideoPlayerScreenState extends State<VideoPlayerScreen> {",
     "class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {"),

    ("소리만 듣기 켜짐/꺼짐 칸",
     "  Timer? _saveTimer; // 5초마다 어디까지 봤는지 저장",
     "  Timer? _saveTimer; // 5초마다 어디까지 봤는지 저장\n  bool _audioOnly = false; // 소리만 듣기 (화면 꺼도 계속)"),

    ("화면 열 때 알아채기 시작",
     """  void initState() {
    super.initState();
    _initPlayer();
  }""",
     """  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }"""),

    ("앱을 나가도 바로 멈추지 않게",
     """    _videoPlayerController = VideoPlayerController.file(
      File(widget.video.uri),
    );""",
     """    _videoPlayerController = VideoPlayerController.file(
      File(widget.video.uri),
      // 앱을 나가도 멈추지 않게 (멈출지는 소리만 듣기 설정으로 직접 정함)
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    );"""),

    ("소리만 듣기 설정 불러오기",
     """    await _videoPlayerController.initialize();
    // 이어보기: 멈췄던 곳부터""",
     """    await _videoPlayerController.initialize();
    // 소리만 듣기 설정 불러오기 (한 번 켜면 다음 영상도 그대로)
    _audioOnly = (await SharedPreferences.getInstance()).getBool('videoAudioOnly') ?? false;
    // 이어보기: 멈췄던 곳부터"""),

    ("앱 나가거나 화면 꺼질 때: 꺼져 있으면 멈추기",
     """  void _savePosition() {""",
     """  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_videoPlayerController.value.isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // 소리만 듣기 꺼져 있으면 원래처럼 멈추기
      if (!_audioOnly) {
        _videoPlayerController.pause();
        _savePosition();
      }
    }
  }

  void _savePosition() {"""),

    ("화면 닫을 때 알아채기 끝",
     """  void dispose() {
    _saveTimer?.cancel();""",
     """  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();"""),

    ("⋮ 메뉴 칸: 켜져 있으면 오른쪽에 ✓",
     """              PopupMenuItem<String> item(IconData icon, String label, String value, {bool danger = false}) =>""",
     """              PopupMenuItem<String> item(IconData icon, String label, String value, {bool danger = false, bool on = false}) =>"""),

    ("⋮ 메뉴 칸: ✓ 표시 그리기",
     """                        Text(label,
                            style: TextStyle(
                                color: danger ? red : const Color(0xFFF3EFE7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],""",
     """                        Text(label,
                            style: TextStyle(
                                color: danger ? red : const Color(0xFFF3EFE7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        if (on) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.check_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                        ],
                      ],"""),

    ("⋮ 메뉴에 소리만 듣기 넣기 (공유하기 아래)",
     """                item(Icons.ios_share_rounded, '공유하기', 'share'),""",
     """                item(Icons.ios_share_rounded, '공유하기', 'share'),
                item(Icons.headphones_rounded, '소리만 듣기', 'audioOnly', on: _audioOnly),"""),

    ("소리만 듣기 눌렀을 때 켜기/끄기 + 안내",
     """              if (value == 'share') {
                await shareVideo(context, widget.video);
                return;
              }""",
     """              if (value == 'share') {
                await shareVideo(context, widget.video);
                return;
              }
              if (value == 'audioOnly') {
                setState(() => _audioOnly = !_audioOnly);
                (await SharedPreferences.getInstance()).setBool('videoAudioOnly', _audioOnly);
                if (context.mounted) {
                  showParanToast(context, _audioOnly ? '화면을 꺼도 소리가 계속 나와요' : '앱을 나가면 멈춰요');
                }
                return;
              }"""),
]


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if DONE_MARK in text:
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    before = balance(text)
    for i, (name, old, new) in enumerate(EDITS, 1):
        n = text.count(old)
        if n != 1:
            print(f'❌ {i}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
            print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
            sys.exit(1)
        text = text.replace(old, new)
        print(f'✔ {i}. {name}')

    if balance(text) != before:
        print('❌ 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
        sys.exit(1)

    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print(f'완료! {len(EDITS)}군데 바꿨어요.')


main()
