# 4×3 위젯에도 바로가기 4개 (음악 · 라디오 · 자연 · 수면) 넣기
# 순서: 사진 → 바로가기 4개 → 최근에 들은 것 3줄
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")
MAIN = os.path.join("android", "app", "src", "main")


def one(name):
    hits = []
    for d, dirs, files in os.walk(os.path.join(ROOT, MAIN)):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        if name in files:
            hits.append(os.path.normpath(os.path.join(d, name)))
    if len(hits) != 1:
        print(f"❌ {name} 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
        sys.exit(1)
    return hits[0]


def read(p):
    raw = open(p, "rb").read().decode("utf-8")
    return raw.replace("\r\n", "\n"), "\r\n" in raw


pw, lay1, lay2 = one("PlayerWidget.kt"), one("widget_player.xml"), one("widget_player2.xml")
pw_s, pw_c = read(pw)
l1, _ = read(lay1)
l2, l2_c = read(lay2)

if "widget_go_music" in l2:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(src, old, new, what):
    global ok
    if src.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {src.count(old)}곳)")
        ok = False
        return src
    print(f"✔ {what}")
    return src.replace(old, new)


# 1. PlayerWidget.kt
pw_s = rep(pw_s,
           "            if (!big) go.forEachIndexed { i, (viewId, target) -> // 바로가기는 4×2만",
           "            go.forEachIndexed { i, (viewId, target) ->",
           "PlayerWidget.kt: 바로가기 버튼을 4×3에도 연결")
pw_s = rep(pw_s,
           "            val bottomDp = if (big) recentRows(context, views, if (empty) null else t) else 64",
           "            // 4×2: 바로가기 64 / 4×3: 바로가기 54(46 + 위 8) + 최근 줄\n"
           "            val bottomDp = if (big) 54 + recentRows(context, views, if (empty) null else t) else 64",
           "PlayerWidget.kt: 사진 칸 높이 다시 계산")

# 2. widget_player2.xml: 4×2의 바로가기 줄을 그대로 복사해서 사진과 최근 줄 사이에
start = "    <!-- 아래: 바로가기 4개 -->"
if l1.count(start) != 1:
    print("❌ widget_player.xml: 바로가기 줄을 못 찾았어요")
    ok = False
else:
    block = l1[l1.index(start):l1.rindex("</LinearLayout>")]
    if block.count('        android:layout_marginBottom="10dp"\n') != 1:
        print("❌ widget_player.xml: 바로가기 줄 모양이 예상과 달라요")
        ok = False
    else:
        block = block.replace('        android:layout_marginBottom="10dp"\n', "")  # 아래에 최근 줄이 바로 붙게
        block = block.replace("<!-- 아래: 바로가기 4개 -->", "<!-- 가운데: 바로가기 4개 (4×2와 똑같이) -->")
        l2 = rep(l2, "    <!-- 아래: 최근에 들은 것 3개", block + "\n    <!-- 아래: 최근에 들은 것 3개",
                 "widget_player2.xml: 사진 아래에 바로가기 4개")
        l2 = l2.replace("<!-- 홈 위젯 4×3: 위는 4×2 위젯과 똑같이 / 아래 최근에 들은 것 3개 -->",
                        "<!-- 홈 위젯 4×3: 4×2 위젯과 똑같이 + 맨 아래 최근에 들은 것 3개 -->")

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)

for p, s, c in ((pw, pw_s, pw_c), (lay2, l2, l2_c)):
    if c:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
