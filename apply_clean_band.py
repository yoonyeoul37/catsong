# -*- coding: utf-8 -*-
# 홈 '곡 정리' 카드도 오늘의 카드와 같은 베이지 띠로 (예전 먹색 카드)
import sys, glob, os, shutil

hits = [h for h in glob.glob(os.path.join('lib', '**', 'home_screen.dart'), recursive=True)
        if os.path.basename(h) == 'home_screen.dart']
if not hits:
    print('❌ home_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if "'곡 정리'," in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('색: 베이지 띠',
"""    // 밝은 화면: 먹색 바 / 다크 화면: 크림색 바 (배경과 반대라 또렷하게)
    final card = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final ink = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final sub = isDark ? const Color(0xFF8A8378) : const Color(0xFFA29A8B);
    final bg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);""",
"""    // 오늘의 카드와 같은 띠: 바탕보다 한 톤 진한 베이지 (다크는 바탕보다 한 톤 밝게)
    final card = isDark ? const Color(0xFF302D29) : const Color(0xFFDDD4C3);
    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF746C60);
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5); // [정리하기] 버튼 글자색
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8
        ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
        : point;"""),
('모양: 양옆 끝까지 꽉 찬 띠',
"""      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('곡 제목 $n개를 깔끔하게',""",
"""      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      decoration: BoxDecoration(color: card),
      child: Row(
        children: [
          // 왼쪽 그림 (오늘의 카드와 같은 크기의 흰 칸)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3631) : const Color(0x8CFFFFFF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.auto_fix_high_rounded, size: 19, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('곡 정리',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 1),
                Text('곡 제목 $n개를 깔끔하게',"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

shutil.copy(path, path + '.bak_clean')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_clean)')
