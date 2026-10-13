# 위젯 작업에 필요한 '진짜' 파일만 찾아서 C:\apps\보낼파일 폴더에 모아 줘요
# (backup, build 폴더는 건너뜀)
import os, shutil, sys

ROOT = os.getcwd()
OUT = os.path.join(os.path.dirname(ROOT), "보낼파일")
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")

want_any = {"PlayerWidget.kt", "PlayerWidget2.kt", "PlayerWidget3.kt", "MainActivity.kt",
            "headset_resume.dart", "recent_content_provider.dart", "recent_content_entry.dart"}

found = []
for d, dirs, files in os.walk(ROOT):
    dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
    rel = os.path.relpath(d, ROOT).replace("\\", "/")
    for f in files:
        p = os.path.join(d, f)
        if f in want_any:
            found.append(p)
        elif rel == "android/app/src/main" and f == "AndroidManifest.xml":
            found.append(p)
        elif rel in ("android/app/src/main/res/layout", "android/app/src/main/res/xml") and f.startswith("widget_"):
            found.append(p)

if not found:
    print("❌ 아무것도 못 찾았어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요")
    sys.exit(1)

if os.path.isdir(OUT):
    shutil.rmtree(OUT)
os.makedirs(OUT)
names = {}
for p in sorted(found):
    f = os.path.basename(p)
    names[f] = names.get(f, 0) + 1
    name = f if names[f] == 1 else f"{names[f]}_{f}"  # 같은 이름이 또 있으면 번호 붙임
    shutil.copy2(p, os.path.join(OUT, name))
    print("✔", os.path.relpath(p, ROOT), "→", name)

print()
print("다 모았어요:", OUT)
