# 앱 안의 수파베이스 주소를 클라우드플레어 R2 주소로 바꾸기
#  https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/  →  https://files.ssing.kr/
#  (파일 이름·폴더 모양은 그대로라 뒤쪽은 안 바뀜)
#  - lib 과 android/app/src 안의 파일만 (backup 폴더는 건너뜀)
#  - 바꾼 뒤에도 수파베이스 주소가 남아 있으면 ❌ 띄우고 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")
EXT = (".dart", ".kt", ".java", ".xml", ".json")
OLD = "https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/"
NEW = "https://files.ssing.kr/"
MARK = "srdzgrinceazcimdwayu"

targets = []
for under in ("lib", os.path.join("android", "app", "src")):
    base = os.path.join(ROOT, under)
    if not os.path.isdir(base):
        if under == "lib":
            print("❌ lib 폴더가 없어요 — 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요")
            sys.exit(1)
        continue
    for d, dirs, files in os.walk(base):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        for n in files:
            if n.endswith(EXT):
                targets.append(os.path.normpath(os.path.join(d, n)))

changed, left = [], []
for p in targets:
    raw = open(p, "rb").read()
    try:
        s = raw.decode("utf-8")
    except UnicodeDecodeError:
        continue
    if MARK not in s:
        continue
    n = s.count(OLD)
    t = s.replace(OLD, NEW)
    rel = os.path.relpath(p, ROOT)
    if MARK in t:
        for i, line in enumerate(t.splitlines(), 1):
            if MARK in line:
                left.append(f"{rel} {i}줄: {line.strip()[:120]}")
    if n:
        changed.append((p, t, rel, n))

if not changed and not left:
    print("이미 적용돼 있어요")
    sys.exit(0)

for _, _, rel, n in changed:
    print(f"✔ {rel}  ({n}곳)")
if left:
    print()
    print("❌ 모양이 달라서 못 바꾼 수파베이스 주소가 있어요:")
    for x in left:
        print("   " + x)
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요 — 위 내용을 보여 주세요")
    sys.exit(1)

for p, t, _, _ in changed:
    open(p, "wb").write(t.encode("utf-8"))  # 줄바꿈(CRLF)은 손대지 않음
print()
print(f"다 됐어요! 파일 {len(changed)}개, 모두 {sum(c[3] for c in changed)}곳 바꿈")
