# -*- coding: utf-8 -*-
# 재생화면 위쪽 줄: 파란포토일 때 사진 아이콘을 TV 아이콘 옆에 (사진 · TV · ⋮)
# 세 아이콘 크기·칸을 똑같이 맞추고, 가운데 Paransori가 화면 정중앙에 오게
# 사진 위에 떠 있던 동그란 사진 버튼은 위쪽 줄로 옮겨서 뺌
import os, sys

P = "lib/screens/player_screen.dart"

EDITS = [
    # 1) 왼쪽 빈칸: 오른쪽 아이콘 수만큼 (가운데 정렬 유지)
("""          const SizedBox(width: 40), // 오른쪽 TV 버튼 폭만큼 비워서 가운데 워터마크 정렬 유지""",
"""          // 오른쪽 아이콘(36씩) 폭에 맞춰 비워서 가운데 워터마크가 화면 정중앙에 오게 (왼쪽 ⌄는 48)
          SizedBox(width: (_albumArtStyle == 6 ? 36.0 * 3 : 36.0 * 2) - 48),"""),

    # 2) TV 아이콘 앞에 사진 아이콘 (파란포토일 때만)
("""          AnimatedBuilder(
            animation: CastService.instance,
            builder: (context, _) {
              final cast = CastService.instance;
              return GestureDetector(""",
"""          // 파란포토 사진 고르기 (파란포토 스타일일 때만, 열려 있으면 하늘색)
          if (_albumArtStyle == 6)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                final open = !_showNightPicker;
                setState(() => _showNightPicker = open);
                SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', open));
              },
              child: SizedBox(
                width: 36,
                height: 40,
                child: Icon(
                  Icons.photo_outlined,
                  color: _showNightPicker ? const Color(0xFF7FB8F0) : baseColor,
                  size: 20,
                ),
              ),
            ),
          AnimatedBuilder(
            animation: CastService.instance,
            builder: (context, _) {
              final cast = CastService.instance;
              return GestureDetector("""),

    # 3) TV 아이콘 크기·칸 맞추기
("""                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    cast.isConnected ? Icons.cast_connected : Icons.cast,
                    color: cast.isConnected ? const Color(0xFF7FB8F0) : baseColor,
                    size: 22,
                  ),
                ),""",
"""                child: SizedBox(
                  width: 36,
                  height: 40,
                  child: Icon(
                    cast.isConnected ? Icons.cast_connected : Icons.cast,
                    color: cast.isConnected ? const Color(0xFF7FB8F0) : baseColor,
                    size: 20,
                  ),
                ),"""),

    # 4) ⋮ 크기·칸 맞추기
("""            child: Padding(
              // 왼쪽 ⌄ 버튼과 폭을 똑같이(48) 맞춰서 가운데 워터마크가 화면 정중앙에 오게
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.more_vert, color: baseColor),""",
"""            child: SizedBox(
              // 사진·TV 아이콘과 같은 칸(36)
              width: 36,
              height: 40,
              child: Center(
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.more_vert, color: baseColor, size: 20),"""),
("""                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }""",
"""                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }"""),

    # 5) 사진 위에 떠 있던 동그란 사진 버튼 빼기 (위쪽 줄 아이콘으로 옮김)
("""    if (!_showNightPicker) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() => _showNightPicker = true);
              SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', true));
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Icon(Icons.photo_outlined, color: Colors.white, size: 18),
            ),
          ),
        ),
      );
    }""",
"""    // 닫혀 있을 때: 아무것도 안 띄움 (위쪽 줄 사진 아이콘으로 열기)
    if (!_showNightPicker) return const SizedBox.shrink();"""),
]

if not os.path.exists(P):
    print("❌ player_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)")
    sys.exit(1)
raw = open(P, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
t = raw.replace("\r\n", "\n")
ok, done = True, 0
for i, (old, new) in enumerate(EDITS, 1):
    c = t.count(old)
    if new in t:
        print(f"✔ player_screen.dart ({i}) - 이미 적용돼 있어요")
    elif c == 1:
        t = t.replace(old, new)
        print(f"✔ player_screen.dart ({i})")
        done += 1
    else:
        print(f"❌ player_screen.dart ({i}) - 고칠 곳을 못 찾았어요 ({c}곳)")
        ok = False
if not ok:
    print("\n❌ 문제가 있어서 아무것도 저장하지 않았어요")
    sys.exit(1)
if done == 0:
    print("\n이미 적용돼 있어요")
    sys.exit(0)
out = t.replace("\n", "\r\n") if crlf else t
open(P, "wb").write(out.encode("utf-8"))
print(f"\n✔ 모두 저장했어요 ({done}곳)")
