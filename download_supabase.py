# 수파베이스 파일 전부 내려받기 (R2로 옮기려고)
#  - app-images, nature-sounds 두 버킷의 파일을 폴더 모양 그대로 받음
#  - 받은 곳: 이 파일이 있는 폴더 안 supabase_download
#  - 수파베이스 키(anon public)는 실행할 때 붙여넣기 (파일에 저장 안 함)
import json, os, sys, urllib.parse, urllib.request

BASE = "https://srdzgrinceazcimdwayu.supabase.co"
BUCKETS = ["app-images", "nature-sounds"]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "supabase_download")

key = input("수파베이스 anon public 키를 붙여넣고 엔터: ").strip()
if not key:
    print("❌ 키가 비어 있어요")
    sys.exit(1)
H = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"}


def list_dir(bucket, prefix):
    out, offset = [], 0
    while True:
        body = json.dumps({"prefix": prefix, "limit": 1000, "offset": offset,
                           "sortBy": {"column": "name", "order": "asc"}}).encode()
        req = urllib.request.Request(f"{BASE}/storage/v1/object/list/{bucket}", data=body, headers=H, method="POST")
        with urllib.request.urlopen(req, timeout=60) as r:
            items = json.loads(r.read().decode())
        out += items
        if len(items) < 1000:
            return out
        offset += 1000


def walk(bucket, prefix=""):
    files = []
    for it in list_dir(bucket, prefix):
        name = it["name"]
        if name == ".emptyFolderPlaceholder":
            continue
        path = f"{prefix}{name}"
        if it.get("id") is None:  # 폴더
            files += walk(bucket, path + "/")
        else:
            files.append(path)
    return files


total_files, total_bytes, fails = 0, 0, []
for b in BUCKETS:
    try:
        files = walk(b)
    except Exception as e:
        print(f"❌ {b} 목록을 못 읽었어요: {e}")
        print("   키가 맞는지 확인해 주세요 (anon public 키)")
        sys.exit(1)
    print(f"\n[{b}] {len(files)}개")
    for path in files:
        dst = os.path.join(OUT, b, *path.split("/"))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        url = f"{BASE}/storage/v1/object/public/{b}/" + "/".join(urllib.parse.quote(p) for p in path.split("/"))
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                data = r.read()
            open(dst, "wb").write(data)
            total_files += 1
            total_bytes += len(data)
            print(f"✔ {b}/{path}  ({len(data)//1024} KB)")
        except Exception as e:
            fails.append(f"{b}/{path}")
            print(f"❌ {b}/{path}  ({e})")

print()
print(f"받은 파일 {total_files}개, 모두 {total_bytes/1024/1024:.1f} MB")
print(f"저장한 곳: {OUT}")
if fails:
    print(f"❌ 못 받은 파일 {len(fails)}개 — 다시 실행하면 돼요")
else:
    print("다 됐어요!")
