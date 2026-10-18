# 국내 라디오 위쪽을 B안으로: 얇고 밝은 탭(바깥 둥글기 10) + 아래 '국가 선택 ··· 🇰🇷 한국 ▾' 한 줄
import sys

PATH = 'lib/screens/radio_korea_screen2.dart'
NAME = 'radio_korea_screen2.dart'

EDITS = [
# 1) 탭 버튼: 고른 칸은 밝은 색 + 살짝 그림자, 글자는 먹색
("탭 버튼 모양",
"""          decoration: BoxDecoration(
            color: selected ? (isDarkMode ? Colors.white : const Color(0xFF17140F)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),""",
"""          decoration: BoxDecoration(
            color: selected ? (isDarkMode ? const Color(0xFF45413B) : const Color(0xFFFBF8F2)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.08), blurRadius: 3, offset: const Offset(0, 1))]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),"""),
("탭 글자 색",
"""                color: selected
                    ? (isDarkMode ? const Color(0xFF24221F) : Colors.white)
                    : baseColor.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,""",
"""                color: selected
                    ? (isDarkMode ? Colors.white : const Color(0xFF17140F))
                    : baseColor.withOpacity(0.55),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,"""),
# 2) 위쪽 높이 줄이기
("위쪽 높이",
"""          preferredSize: const Size.fromHeight(102),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),""",
"""          preferredSize: const Size.fromHeight(86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),"""),
# 3) 탭 바깥 틀: 안쪽 여백 3, 높이 36, 둥글기 10
("탭 바깥 틀",
"""                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _toggleButton(tr.all,""",
"""                Container(
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10), // 아래 카드와 같은 둥글기
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _toggleButton(tr.all,"""),
# 4) 국가 선택: 회색 상자 → 한 줄 (왼쪽 '국가 선택', 오른쪽 국기·나라·▾)
("국가 선택 줄",
"""                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10), // 홈 카드·위 탭과 같은 둥글기
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? const Color(0x14FFFFFF)
                                : Colors.white.withOpacity(0.8),
                          ),
                          child: Icon(
                            Icons.public,
                            size: 16,
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                                ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
                                : context.watch<ThemeProvider>().primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(tr.selectCountryShort,
                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, color: baseColor, fontSize: 13, fontWeight: FontWeight.w700)),
                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: baseColor.withOpacity(0.18),
                        ),
                        const Text('🇰🇷', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(tr.countryKR,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, 
                                  color: baseColor.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: baseColor.withOpacity(0.5)),
                      ],
                    ),
                  ),
                ),""",
"""                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // 줄 어디를 눌러도 나라 고르기
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
                    );
                  },
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(tr.selectCountryShort,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  color: baseColor.withOpacity(0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),
                        ),
                        const Text('🇰🇷', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(tr.countryKR,
                            maxLines: 1,
                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: baseColor.withOpacity(0.45)),
                      ],
                    ),
                  ),
                ),"""),
]

with open(PATH, 'rb') as f:
    raw = f.read()
text = raw.decode('utf-8')
crlf = '\r\n' in text
nl = (lambda s: s.replace('\n', '\r\n')) if crlf else (lambda s: s)

if nl('preferredSize: const Size.fromHeight(86),') in text and nl('behavior: HitTestBehavior.opaque, // 줄 어디를 눌러도 나라 고르기') in text:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for label, old, new in EDITS:
    o, n = nl(old), nl(new)
    c = text.count(o)
    if c == 1:
        text = text.replace(o, n); print(f'✔ {label}')
    else:
        print(f'❌ {label} — 찾을 곳을 못 찾았어요 ({c}곳)'); ok = False

if not ok:
    print(f'\n❌ {NAME}: 못 찾은 곳이 있어서 아무것도 저장하지 않았어요'); sys.exit(1)

with open(PATH, 'wb') as f:
    f.write(text.encode('utf-8'))
print(f'\n완료! ({NAME})')
