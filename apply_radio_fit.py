# 라디오 재생 화면: 폰 크기에 맞춰 한 화면에 (작은 폰도 재생 버튼이 항상 보이게)
#  - 스크롤 없앰 → 위 버튼이 상태바(시계·배터리) 위로 안 올라감
#  - 남는 공간에 맞춰 사진만 줄어듦 (큰 폰은 지금 그대로)
# 실행: python apply_radio_fit.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'radio_player_screen.dart')
DONE_MARK = '스크롤 없이 한 화면에'

EDITS = [
    ("스크롤 없애고 한 화면에 (위 버튼은 상태바 아래 고정)",
     """          LayoutBuilder(builder: (context, constraints) {
            final h = constraints.maxHeight;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SafeArea(""",
     """          LayoutBuilder(builder: (context, constraints) {
            final h = constraints.maxHeight;
            // 스크롤 없이 한 화면에: 위 버튼은 상태바 아래 고정, 재생 버튼은 항상 화면 안
            // (작은 폰에서는 사진만 남는 공간만큼 줄어듦 · 큰 폰은 그대로)
            return SizedBox(
              height: h,
              child: SafeArea("""),

    ("사진 칸: 남는 공간만큼만 (최대는 지금 크기)",
     """                      Builder(builder: (ctx) {
                        final programImage = radioProvider.currentProgram?['image'] as String?;""",
     """                      Flexible(child: LayoutBuilder(builder: (ctx, box) {
                        // 큰 폰: 지금처럼 화면의 28% · 작은 폰: 남는 공간만큼 줄이기
                        final imgH = box.maxHeight < h * 0.28 ? box.maxHeight : h * 0.28;
                        final programImage = radioProvider.currentProgram?['image'] as String?;"""),

    ("사진 높이를 줄어든 크기로",
     """                              scheduleLoading
                                  ? Container(
                                width: double.infinity,
                                height: h * 0.28,""",
     """                              scheduleLoading
                                  ? Container(
                                width: double.infinity,
                                height: imgH,"""),
    ("방송 사진 높이",
     """                                programImage,
                                width: double.infinity,
                                height: h * 0.28,
                                fit: BoxFit.cover,
                                errorBuilder: (errCtx, err, stack) =>
                                    RadioMoodPlaceholder(height: (h * 0.24).clamp(120.0, 220.0)),
                              )
                                  : RadioMoodPlaceholder(height: h * 0.28),""",
     """                                programImage,
                                width: double.infinity,
                                height: imgH,
                                fit: BoxFit.cover,
                                errorBuilder: (errCtx, err, stack) => RadioMoodPlaceholder(height: imgH),
                              )
                                  : RadioMoodPlaceholder(height: imgH),"""),
    ("사진 칸 닫기",
     """                        );
                      }),

                      SizedBox(height: (h * 0.02).clamp(8.0, 16.0)),""",
     """                        );
                      })),

                      SizedBox(height: (h * 0.02).clamp(8.0, 16.0)),"""),

    ("방송 소개 글은 3줄까지 (작은 폰에서 버튼을 밀어내지 않게)",
     """                                  radioProvider.descriptionFor(current.name)!,
                                  style: TextStyle(color: baseColor.withOpacity(0.75), fontSize: 13, height: 1.5),""",
     """                                  radioProvider.descriptionFor(current.name)!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: baseColor.withOpacity(0.75), fontSize: 13, height: 1.5),"""),
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
