# 개인정보처리방침: Supabase → Cloudflare R2 (10개 언어)
import os, sys

NAME = "privacy_policy.html"
NEW = "<b>Cloudflare R2 (files.ssing.kr)</b>"
OLD = [
    ("한국어", "<b>Supabase (서버: 일본 도쿄)</b>"),
    ("영어", "<b>Supabase (server: Tokyo, Japan)</b>"),
    ("일본어", "<b>Supabase（サーバー：日本・東京）</b>"),
    ("중국어", "<b>Supabase（伺服器：日本東京）</b>"),
    ("베트남어", "<b>Supabase (máy chủ: Tokyo, Nhật Bản)</b>"),
    ("힌디어", "<b>Supabase (सर्वर: टोक्यो, जापान)</b>"),
    ("인도네시아어", "<b>Supabase (server: Tokyo, Jepang)</b>"),
    ("태국어", "<b>Supabase (เซิร์ฟเวอร์: โตเกียว ญี่ปุ่น)</b>"),
    ("스페인어", "<b>Supabase (servidor: Tokio, Japón)</b>"),
    ("포르투갈어", "<b>Supabase (servidor: Tóquio, Japão)</b>"),
]

found = []
for root, dirs, files in os.walk("."):
    dirs[:] = [d for d in dirs if d not in (".git", "build", ".dart_tool", "node_modules")]
    if NAME in files:
        found.append(os.path.join(root, NAME))

if len(found) != 1:
    print(f"❌ {NAME} 파일을 {len(found)}개 찾았어요. 아무것도 저장 안 했어요.")
    for f in found:
        print("   ", f)
    sys.exit(1)

path = found[0]
raw = open(path, "rb").read()
text = raw.decode("utf-8")

if "Supabase" not in text and text.count(NEW) == len(OLD):
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
for lang, old in OLD:
    if text.count(old) == 1:
        text = text.replace(old, NEW)
        print(f"✔ {lang}")
    else:
        print(f"❌ {lang} 못 찾음")
        ok = False

if not ok or "Supabase" in text:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)

open(path, "wb").write(text.encode("utf-8"))
print(f"완료: {path}")
