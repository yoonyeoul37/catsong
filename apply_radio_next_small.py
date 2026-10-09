# 라디오 재생 화면: 세로가 짧은 폰은 "다음 프로그램" 카드를 숨기지 않고 작게
#  - 사진 76 → 46, 안쪽 여백 14 → 10 (큰 폰은 그대로)
# 실행: python apply_radio_next_small.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'radio_player_screen.dart')
DONE_MARK = '짧은 폰은 작은 카드로'

EDITS = [
    ("다음 프로그램 카드 다시 보이게 (짧은 폰은 작게)",
     """                        // 세로가 짧은 폰은 "다음 프로그램" 줄 숨겨서 사진 자리 더 주기
                        if (!compact) SizedBox(height: (h * 0.005).clamp(2.0, 4.0)),
                        if (!compact) _NextProgramLine(""",
     """                        SizedBox(height: (h * 0.005).clamp(2.0, 4.0)),
                        _NextProgramLine(
                          compact: compact, // 짧은 폰은 작은 카드로"""),

    ("카드: 작게 보일지 받기",
     """  final RadioProvider radioProvider;

  const _NextProgramLine({
    required this.scheduleList,
    required this.currentProgram,
    required this.radioProvider,
  });""",
     """  final RadioProvider radioProvider;
  final bool compact; // 세로가 짧은 폰이면 작은 카드

  const _NextProgramLine({
    required this.scheduleList,
    required this.currentProgram,
    required this.radioProvider,
    this.compact = false,
  });"""),

    ("카드 크기: 짧은 폰은 사진 46 · 여백 10",
     """    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),""",
     """    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final s = widget.compact ? 46.0 : 76.0; // 왼쪽 사진 크기
    final iconS = widget.compact ? 20.0 : 28.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 10 : 14),"""),

    ("카드 왼쪽 사진 크기 맞추기",
     """          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: (nextImage != null && nextImage.isNotEmpty)
                ? Image.network(
              nextImage,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (errCtx, err, stack) => Container(
                width: 76,
                height: 76,
                color: baseColor.withOpacity(0.08),
                child: Icon(Icons.radio, color: baseColor.withOpacity(0.38), size: 28),
              ),
            )
                : Container(
              width: 76,
              height: 76,
              color: baseColor.withOpacity(0.08),
              child: Icon(Icons.radio, color: baseColor.withOpacity(0.38), size: 28),
            ),
          ),""",
     """          ClipRRect(
            borderRadius: BorderRadius.circular(widget.compact ? 10 : 14),
            child: (nextImage != null && nextImage.isNotEmpty)
                ? Image.network(
              nextImage,
              width: s,
              height: s,
              fit: BoxFit.cover,
              errorBuilder: (errCtx, err, stack) => Container(
                width: s,
                height: s,
                color: baseColor.withOpacity(0.08),
                child: Icon(Icons.radio, color: baseColor.withOpacity(0.38), size: iconS),
              ),
            )
                : Container(
              width: s,
              height: s,
              color: baseColor.withOpacity(0.08),
              child: Icon(Icons.radio, color: baseColor.withOpacity(0.38), size: iconS),
            ),
          ),"""),
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
