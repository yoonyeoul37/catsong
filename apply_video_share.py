# 동영상 공유하기 + 10분 넘는 영상 안내 (video_screen.dart)
# 실행: python apply_video_share.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
DONE_MARK = 'Future<void> shareVideo('

EDITS = [
    ("share_plus 불러오기",
     "import 'dart:typed_data';",
     "import 'dart:typed_data';\nimport 'package:share_plus/share_plus.dart';"),

    ("공유 함수 (10분 넘으면 안내 먼저)",
     "class VideoScreen extends StatefulWidget {",
     """// 동영상 공유 (10분 넘으면 카톡 안내 먼저)
Future<void> shareVideo(BuildContext context, Video video) async {
  if (video.duration > 10 * 60 * 1000) {
    final ok = await showParanConfirm(
      context,
      title: '긴 동영상이에요',
      message: '10분이 넘는 영상은 카카오톡으로 안 보내질 수 있어요.\\n구글 드라이브나 메일로 보내면 잘 가요.',
      confirmLabel: '보내기',
    );
    if (!ok || !context.mounted) return;
  }
  try {
    await Share.shareXFiles([XFile(video.uri)], text: video.titleDisplay);
  } catch (e) {
    debugPrint('동영상 공유 오류: $e');
  }
}

class VideoScreen extends StatefulWidget {"""),

    ("목록 꾹 창 맨 위에 공유하기",
     """                    children: [
                      action(Icons.edit_outlined, AppLocalizations.of(context)!.rename, ink, bg,""",
     """                    children: [
                      action(Icons.ios_share_rounded, '공유하기', ink, bg,
                          isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348),
                          () => shareVideo(context, widget.video)),
                      Divider(height: 1, thickness: 1, color: line),
                      action(Icons.edit_outlined, AppLocalizations.of(context)!.rename, ink, bg,"""),

    ("재생 화면 ⋮ 맨 위에 공유하기",
     """              return [
                item(Icons.edit_outlined, AppLocalizations.of(context)!.rename, 'rename'),""",
     """              return [
                item(Icons.ios_share_rounded, '공유하기', 'share'),
                item(Icons.edit_outlined, AppLocalizations.of(context)!.rename, 'rename'),"""),

    ("⋮ 공유하기 눌렀을 때 동작",
     """            onSelected: (value) async {
              if (value == 'rename') {""",
     """            onSelected: (value) async {
              if (value == 'share') {
                await shareVideo(context, widget.video);
                return;
              }
              if (value == 'rename') {"""),
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
