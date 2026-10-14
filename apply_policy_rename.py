# 개인정보처리방침: 변경 이력에서 '앱 이름 변경(뮤직웨이브 → 파란소리)' 부분만 빼기 (10개 언어 모두)
# 같은 날 들어간 '자연 소리·소리 믹스…' 내용은 그대로 남김
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea", "node_modules")

hits = []
for d, dirs, files in os.walk(ROOT):
    dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
    if "privacy_policy.html" in files:
        hits.append(os.path.normpath(os.path.join(d, "privacy_policy.html")))
if len(hits) != 1:
    print(f"❌ privacy_policy.html 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
    for h in hits:
        print("   ", h)
    sys.exit(1)
p = hits[0]
raw = open(p, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")

if "MusicWave" not in s and "뮤직웨이브" not in s:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
EDITS = [
    ("한국어", "앱 이름 변경(뮤직웨이브 → 파란소리), 자연 소리", "자연 소리"),
    ("영어", "App renamed (MusicWave → Paransori); added nature", "Added nature"),
    ("일본어", "アプリ名を変更（MusicWave → Paransori）、自然音", "自然音"),
    ("중국어(대만)", "應用程式更名（MusicWave → Paransori）；新增", "新增"),
    ("베트남어", "Đổi tên ứng dụng (MusicWave → Paransori); bổ sung", "Bổ sung"),
    ("힌디어", "ऐप का नाम बदला गया (MusicWave → Paransori); प्रकृति", "प्रकृति"),
    ("인도네시아어", "Nama aplikasi diubah (MusicWave → Paransori); menambahkan", "Menambahkan"),
    ("태국어", "เปลี่ยนชื่อแอป (MusicWave → Paransori) และเพิ่ม", "เพิ่ม"),
    ("스페인어", "cambio de nombre de la App (MusicWave → Paransori); se agregó", "se agregó"),
    ("포르투갈어", "App renomeado (MusicWave → Paransori); incluídas", "incluídas"),
]
for name, old, new in EDITS:
    n = s.count(old)
    if n != 1:
        print(f"❌ {name} (찾을 글 {n}곳)")
        ok = False
        continue
    s = s.replace(old, new)
    print(f"✔ {name}")

if "MusicWave" in s or "뮤직웨이브" in s:
    print("❌ 아직 옛 이름이 남은 곳이 있어요")
    ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)
if crlf:
    s = s.replace("\n", "\r\n")
open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
