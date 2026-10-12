# -*- coding: utf-8 -*-
# 홈: '오늘은 이 곡 어때요' 뒤에 통통 튀는 물음표 + 로고 글자색을 먹색/크림색으로
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('home_screen.dart')
if not path:
    print('❌ lib 폴더에서 home_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if 'class _BounceQ' in s and 'final logoInk' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

old = """                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
"""
new = """                if (title == '오늘은 이 곡 어때요')
                  // 큰 물음표가 통통 튀기
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 2),
                      _BounceQ(color: accent),
                    ],
                  )
                else
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
"""
rep('오늘의 곡 제목 뒤에 물음표', old, new)

# 로고 글자색: 검정/흰색 → 먹색/크림색 (로고 부분만)
rep('로고 색 정하기',
    "    final logoBarColor = isBluePoint ? const Color(0xFF2F7DE8) : pointColor;\n",
    "    final logoBarColor = isBluePoint ? const Color(0xFF2F7DE8) : pointColor;\n"
    "    // 로고 글자: 순검정·순흰색 대신 먹색 / 크림색 (화면 톤과 맞게)\n"
    "    final logoInk = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n")

a = s.find("      title: _isSearching\n          ? _buildSearchField()")
b = s.find("child: _LogoEqBars(color: logoBarColor),", a if a >= 0 else 0)
if a >= 0 and b > a:
    part = s[a:b]
    n = part.count('baseColor')
    if n >= 4:
        s = s[:a] + part.replace('baseColor', 'logoInk') + s[b:]
        print('✔ 로고 글자색 먹색/크림색 (' + str(n) + '군데)')
    else:
        print('❌ 로고 글자색 — 코드를 못 찾았어요')
        ok = False
else:
    print('❌ 로고 글자색 — 코드를 못 찾았어요')
    ok = False

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

s = s.rstrip('\n') + """

/// 통통 튀는 큰 물음표: 두 번 톡톡 튀고 잠깐 쉬기를 반복
class _BounceQ extends StatefulWidget {
  final Color color;
  const _BounceQ({required this.color});

  @override
  State<_BounceQ> createState() => _BounceQState();
}

class _BounceQState extends State<_BounceQ> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 0~1 시간 → 위로 뜨는 높이(0~1)
  double _hop(double t) {
    if (t < 0.22) return math.sin(t / 0.22 * math.pi);              // 첫 번째 큰 톡
    if (t < 0.38) return 0.45 * math.sin((t - 0.22) / 0.16 * math.pi); // 두 번째 작은 톡
    return 0;                                                       // 쉬기
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final h = _hop(_c.value);
        // 바닥에 닿는 순간 살짝 납작하게
        final land = (h < 0.08 && _c.value < 0.4) ? 0.08 - h : 0.0;
        return Transform.translate(
          offset: Offset(0, -7 * h),
          child: Transform.scale(
            scaleX: 1 + land * 1.6,
            scaleY: 1 - land * 1.6,
            alignment: Alignment.bottomCenter,
            child: Text('?',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 19,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                )),
          ),
        );
      },
    );
  }
}
"""
print('✔ 통통 튀는 물음표 만들기')

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
