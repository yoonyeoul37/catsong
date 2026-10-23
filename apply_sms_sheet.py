# -*- coding: utf-8 -*-
# 문자 참여 안내창 → 2안
#  위: 제목 + 안내 한 줄 (오른쪽 ✕)
#  가운데: 얇은 선 사이 한 줄 — 동그라미 안 종이비행기 + 큰 번호 + '방송 이름 · 프로그램 이름'
#  아래: 정보이용료 한 줄 + 검은 [문자 보내기] (그대로)
import os, sys

RP = os.path.join('lib', 'screens', 'radio_player_screen.dart')

EDITS = {
    RP: [
        (
"""  final muted = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(""",
"""  final muted = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);
  final line = isDark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB); // 아래 줄 진행 막대와 같은 연한 선
  // 번호 밑 작은 글자: 어느 방송·프로그램에 보내는지 (예: KBS 제1라디오 · 전격시사)
  final radio = context.read<RadioProvider>();
  final where = [
    radio.currentStation?.name ?? '',
    (radio.currentProgram?['title'] ?? '').toString().trim(),
  ].where((s) => s.isNotEmpty).join(' · ');
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(""",
        ),
        (
"""          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(sheetCtx),
                  child: SizedBox(width: 36, height: 36, child: Icon(Icons.close_rounded, size: 20, color: muted)),
                ),
              ),
              Row(
                children: [
                  Icon(CupertinoIcons.paperplane, size: 18, color: strong), // 아래 줄 '문자 참여'와 같은 종이비행기
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t[0], style: TextStyle(color: strong, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(number,
                  style: TextStyle(color: strong, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(t[1], style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 4),
              Text(t[2], style: TextStyle(color: muted.withOpacity(0.8), fontSize: 12, height: 1.5)),
              const SizedBox(height: 18),""",
"""          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 위: 제목 + 안내 한 줄 / 오른쪽 ✕
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t[0], style: TextStyle(color: strong, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(t[1], style: TextStyle(color: muted, fontSize: 13, height: 1.45)),
                      ],
                    ),
                  ),
                  // ✕: 누르는 자리는 넓게, 보이는 위치는 글자 오른쪽 끝에 맞춤
                  Transform.translate(
                    offset: const Offset(8, -6),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(sheetCtx),
                      child: SizedBox(width: 36, height: 36, child: Icon(Icons.close_rounded, size: 20, color: muted)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 가운데: 얇은 선 사이 한 줄 — 종이비행기 + 번호 + 어느 방송인지
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: line), bottom: BorderSide(color: line)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: line)),
                      child: Icon(CupertinoIcons.paperplane, size: 17, color: strong),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(number,
                              style: TextStyle(color: strong, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          if (where.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(where,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: muted.withOpacity(0.8), fontSize: 11.5)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 아래: 정보이용료 한 줄
              Text(t[2], style: TextStyle(color: muted.withOpacity(0.8), fontSize: 12, height: 1.5)),
              const SizedBox(height: 16),""",
        ),
    ],
}

MARK = (RP, 'final where = [')


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    if os.path.exists(MARK[0]):
        with open(MARK[0], 'rb') as f:
            if MARK[1].encode() in f.read():
                print('이미 적용돼 있어요')
                return
    out = {}
    ok = True
    for rel, pairs in EDITS.items():
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(rel, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[rel] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for rel, text in out.items():
        with open(rel, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
