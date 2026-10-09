# -*- coding: utf-8 -*-
# 라디오 화면 3곳의 "Radio" 옆 작은 이퀄라이저를 포인트 색으로 (기본 색이면 원래 파란색)
import os, sys

FILES = [
    "lib/screens/radio_home_screen.dart",
    "lib/screens/radio_korea_screen2.dart",
    "lib/screens/radio_country_stations_screen.dart",
]
MARK = "final eqColor = "

OLD1 = """  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,"""
NEW1 = """  Widget build(BuildContext context) {
    final point = context.watch<ThemeProvider>().primaryColor;
    final eqColor = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    return SizedBox(
      height: 14,"""
OLD2 = """                    color: const Color(0xFF2F7DE8),
                    borderRadius: BorderRadius.circular(1.5),"""
NEW2 = """                    color: eqColor,
                    borderRadius: BorderRadius.circular(1.5),"""

results = {}
ok = True
already = 0
for path in FILES:
    name = os.path.basename(path)
    if not os.path.exists(path):
        print(f"❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)")
        ok = False
        continue
    raw = open(path, "rb").read().decode("utf-8")
    crlf = "\r\n" in raw
    text = raw.replace("\r\n", "\n")
    if MARK in text:
        print(f"✔ {name} - 이미 적용돼 있어요")
        already += 1
        continue
    for i, (o, n) in enumerate([(OLD1, NEW1), (OLD2, NEW2)], 1):
        c = text.count(o)
        if c != 1:
            print(f"❌ {name} - {i}번째 고칠 곳을 못 찾았어요 ({c}곳)")
            ok = False
            break
        text = text.replace(o, n)
        print(f"✔ {name} - {i}번째 고침")
    else:
        if "package:provider/provider.dart" not in text or "theme_provider.dart" not in text:
            print(f"❌ {name} - provider/theme_provider import가 없어요")
            ok = False
            continue
        results[path] = text.replace("\n", "\r\n") if crlf else text

if already == len(FILES):
    print("\n이미 적용돼 있어요")
    sys.exit(0)
if not ok:
    print("\n❌ 문제가 있어서 아무것도 저장하지 않았어요")
    sys.exit(1)
for path, text in results.items():
    open(path, "wb").write(text.encode("utf-8"))
print("\n✔ 모두 저장했어요")
