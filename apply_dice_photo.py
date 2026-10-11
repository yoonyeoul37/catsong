# -*- coding: utf-8 -*-
# 한국 라디오 주사위: 결과 카드 로고 칸에 지금 방송 사진 (없으면 지금처럼 KBS·MBC 글자)
import sys, glob, os, shutil

def find(name):
    hits = glob.glob(os.path.join('lib', '**', name), recursive=True)
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

dice = [
('사진 칸 추가',
"  final String emptyProgram; // 정보가 없을 때\n",
"""  final String emptyProgram; // 정보가 없을 때
  /// 로고 칸에 넣을 사진 주소 (없으면 '' → 글자)
  final String Function(RadioProvider radio)? image;
"""),
('사진 받기',
"    this.emptyProgram = '편성 정보가 없어요',\n",
"""    this.emptyProgram = '편성 정보가 없어요',
    this.image,
"""),
('사진 주소 꺼내기',
"    final program = item.program(radio);\n",
"""    final program = item.program(radio);
    final img = (item.image?.call(radio) ?? '').trim();
"""),
('로고 칸에 사진',
"""                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.lerp(Colors.white, point, 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(item.badge,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(color: point, fontSize: item.badgeSize, fontWeight: FontWeight.w800)),
                        ),""",
"""                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Color.lerp(Colors.white, point, 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // 방송 사진이 있으면 사진, 없거나 못 불러오면 글자
                          child: Builder(builder: (_) {
                            final badgeText = Text(item.badge,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(color: point, fontSize: item.badgeSize, fontWeight: FontWeight.w800));
                            if (img.isEmpty) return badgeText;
                            return Image.network(
                              img,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              frameBuilder: (_, child, frame, sync) => sync
                                  ? child
                                  : AnimatedOpacity(
                                      opacity: frame == null ? 0 : 1,
                                      duration: const Duration(milliseconds: 250),
                                      child: child,
                                    ),
                              errorBuilder: (_, __, ___) => badgeText,
                            );
                          }),
                        ),"""),
]

korea = [
('지금 방송 사진 넘기기',
"              badge: ks.broadcaster,\n",
"""              badge: ks.broadcaster,
              image: (r) => (r.currentProgramFor(ks.name)?['image'] ?? '').toString(),
"""),
]

jobs = [
    prepare(find('radio_dice.dart'), dice, 'item.image?.call'),
    prepare(find('radio_korea_screen2.dart'), korea, 'currentProgramFor(ks.name)?[\'image\']'),
]
for r in jobs:   # 둘 다 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak2' if 'korea' in path else path + '.bak3')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝!')
