# 동영상 목록: 새로 찍은(아직 안 본) 영상에 NEW 표시
# 실행: python apply_video_new.py   (mp3_player_new 폴더에서)
import os, sys

DONE_MARK = 'videoSeenUris'

FILES = {
    os.path.join('lib', 'providers', 'video_provider.dart'): [
        ("저장 도구 불러오기",
         "import 'package:permission_handler/permission_handler.dart';",
         "import 'package:permission_handler/permission_handler.dart';\n"
         "import 'package:shared_preferences/shared_preferences.dart';"),

        ("본 영상 목록 칸",
         "  List<Video> _videos = [];",
         "  List<Video> _videos = [];\n"
         "  Set<String>? _seen; // 열어본(또는 처음부터 있던) 영상"),

        ("새 영상인지 / 봤다고 표시하기",
         "  bool get permissionDenied => _permissionDenied;",
         """  bool get permissionDenied => _permissionDenied;

  // 새로 찍은 영상인지 (아직 안 열어본 것)
  bool isNew(String uri) => _seen != null && !_seen!.contains(uri);

  // 열어보면 NEW 지우기
  Future<void> markSeen(String uri) async {
    if (_seen == null || _seen!.contains(uri)) return;
    _seen!.add(uri);
    notifyListeners();
    (await SharedPreferences.getInstance()).setStringList('videoSeenUris', _seen!.toList());
  }"""),

        ("목록 불러올 때 본 영상 목록도 불러오기",
         "      _videos = foundVideos;",
         """      _videos = foundVideos;
      // NEW 표시: 맨 처음엔 지금 있는 영상 모두 '본 것'으로 (전부 NEW 뜨지 않게)
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('videoSeenUris');
      if (saved == null) {
        _seen = foundVideos.map((v) => v.uri).toSet();
        await prefs.setStringList('videoSeenUris', _seen!.toList());
      } else {
        _seen = saved.toSet();
      }"""),
    ],

    os.path.join('lib', 'screens', 'video_screen.dart'): [
        ("영상 누르면 NEW 지우기",
         """        _channel.invokeMethod('vibrate');
        await Navigator.push(""",
         """        _channel.invokeMethod('vibrate');
        context.read<VideoProvider>().markSeen(widget.video.uri); // 열어보면 NEW 지우기
        await Navigator.push("""),

        ("썸네일 왼쪽 위에 NEW (재생 시간 표와 같은 모양)",
         "                    // 이어보기: 어디까지 봤는지 얇은 막대 (포인트색)",
         """                    // 새로 찍은(아직 안 본) 영상: 왼쪽 위 NEW
                    if (ctx.watch<VideoProvider>().isNew(widget.video.uri))
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                          ),
                        ),
                      ),
                    // 이어보기: 어디까지 봤는지 얇은 막대 (포인트색)"""),
    ],
}


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def main():
    results = {}
    num = 0
    for path, edits in FILES.items():
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path)
            print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
            sys.exit(1)
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        if path.endswith('video_provider.dart') and DONE_MARK in text:
            print('이미 적용돼 있어요. 바꿀 게 없어요.')
            return
        before = balance(text)
        print(f'[{os.path.basename(path)}]')
        for name, old, new in edits:
            num += 1
            n = text.count(old)
            if n != 1:
                print(f'❌ {num}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
                print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
                sys.exit(1)
            text = text.replace(old, new)
            print(f'✔ {num}. {name}')
        if balance(text) != before:
            print(f'❌ {os.path.basename(path)} 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
            sys.exit(1)
        if crlf:
            text = text.replace('\n', '\r\n')
        results[path] = text

    # 두 파일 다 문제없을 때만 저장
    for path, text in results.items():
        open(path, 'wb').write(text.encode('utf-8'))
    print(f'완료! {num}군데 바꿨어요.')


main()
