# 자연소리 색 줄이기(apply_nature3.py) 되돌리기 — 바꾸기 전 원본으로
import os, shutil, sys
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
ROOT = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(ROOT, "backup_nature3", "screens", "nature_sounds_screen.dart")
dst = os.path.join(ROOT, "lib", "screens", "nature_sounds_screen.dart")
if not os.path.exists(src):
    print("[실패] backup_nature3 폴더에서 원본을 못 찾았어요. 이 메시지를 보내주세요.")
    sys.exit(1)
shutil.copy2(src, dst)
print("[완료] 자연소리 화면을 apply_nature3 하기 전으로 되돌렸어요.")
print("[끝] 이제  flutter run  으로 확인해 주세요.")
