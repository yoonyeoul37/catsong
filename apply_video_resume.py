# 동영상 이어보기 + 썸네일 아래 진행 막대 (video_screen.dart)
# 실행: python apply_video_resume.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
DONE_MARK = 'class VideoResume'

EDITS = [
    ("필요한 도구 불러오기",
     "import 'package:share_plus/share_plus.dart';",
     "import 'package:share_plus/share_plus.dart';\nimport 'dart:async';\nimport 'package:shared_preferences/shared_preferences.dart';"),

    ("멈춘 곳 기억하는 칸 만들기",
     "// 동영상 공유 (10분 넘으면 카톡 안내 먼저)",
     """// 이어보기: 동영상마다 멈춘 곳 기억 (폰에 저장 + 바로 쓰게 메모리에도)
class VideoResume {
  static final Map<String, int> _mem = {};
  static String _key(String uri) => 'videoPos_$uri';

  static Future<int> get(String uri) async {
    if (_mem.containsKey(uri)) return _mem[uri]!;
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(_key(uri)) ?? 0;
    _mem[uri] = v;
    return v;
  }

  static Future<void> save(String uri, int posMs, int durMs) async {
    // 처음 5초 안이거나 거의 끝까지 봤으면 기억 지우기 (다음엔 처음부터)
    final done = durMs <= 0 || posMs < 5000 || posMs > durMs - 10000 || posMs > durMs * 0.95;
    _mem[uri] = done ? 0 : posMs;
    final p = await SharedPreferences.getInstance();
    if (done) {
      await p.remove(_key(uri));
    } else {
      await p.setInt(_key(uri), posMs);
    }
  }
}

// 동영상 공유 (10분 넘으면 카톡 안내 먼저)"""),

    ("목록 칸: 진행 정도 저장 칸",
     "  Uint8List? _thumbnail;",
     "  Uint8List? _thumbnail;\n  double _progress = 0; // 이어보기 진행 막대 (0~1)"),

    ("목록 칸: 처음 열 때 진행 정도 불러오기",
     """    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {""",
     """    _loadThumbnail();
    _loadResume();
  }

  // 어디까지 봤는지 불러와서 막대 길이 정하기
  Future<void> _loadResume() async {
    final pos = await VideoResume.get(widget.video.uri);
    final dur = widget.video.duration;
    final p = (pos > 0 && dur > 0) ? (pos / dur).clamp(0.0, 1.0).toDouble() : 0.0;
    if (mounted && p != _progress) setState(() => _progress = p);
  }

  Future<void> _loadThumbnail() async {"""),

    ("목록 칸: 재생 화면에서 돌아오면 막대 새로 고치기",
     """      onTap: () {
        _channel.invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(video: widget.video),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },""",
     """      onTap: () async {
        _channel.invokeMethod('vibrate');
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(video: widget.video),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
        if (mounted) _loadResume(); // 돌아오면 막대 새로
      },"""),

    ("썸네일 맨 아래 얇은 진행 막대 (포인트색)",
     """                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],""",
     """                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    // 이어보기: 어디까지 봤는지 얇은 막대 (포인트색)
                    if (_progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 3,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                  ],"""),

    ("재생 화면: 5초마다 저장할 시계 칸",
     """  ChewieController? _chewieController;

  @override
  void initState() {""",
     """  ChewieController? _chewieController;
  Timer? _saveTimer; // 5초마다 어디까지 봤는지 저장

  @override
  void initState() {"""),

    ("재생 화면: 멈췄던 곳부터 시작",
     """    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,""",
     """    await _videoPlayerController.initialize();
    // 이어보기: 멈췄던 곳부터
    final resumeMs = await VideoResume.get(widget.video.uri);
    if (!mounted) return;

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      startAt: resumeMs > 0 ? Duration(milliseconds: resumeMs) : null,"""),

    ("재생 화면: 5초마다 + 나갈 때 멈춘 곳 저장",
     """    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();""",
     """    setState(() {});
    // 5초마다 어디까지 봤는지 기억 (앱이 갑자기 꺼져도)
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
  }

  void _savePosition() {
    final v = _videoPlayerController.value;
    if (!v.isInitialized) return;
    VideoResume.save(widget.video.uri, v.position.inMilliseconds, v.duration.inMilliseconds);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    try {
      _savePosition(); // 나갈 때 멈춘 곳 기억
    } catch (_) {}
    _videoPlayerController.dispose();"""),
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
