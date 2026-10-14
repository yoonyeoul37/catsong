# supabase_download 폴더의 파일을 클라우드플레어 R2(paransori 버킷)에 그대로 올리기
#  - 주소 모양: files.ssing.kr/app-images/xxx.jpg , files.ssing.kr/nature-sounds/xxx.mp3
#  - 키는 실행할 때 붙여넣기 (파일에 저장 안 함)
#  - 먼저 한 번: pip install boto3
import mimetypes, os, sys

try:
    import boto3
    from botocore.config import Config
except ImportError:
    print("❌ 먼저 이걸 실행해 주세요:  pip install boto3")
    sys.exit(1)

BUCKET = "paransori"
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "supabase_download")
if not os.path.isdir(SRC):
    print(f"❌ {SRC} 폴더가 없어요 (download_supabase.py 와 같은 폴더에서 실행해 주세요)")
    sys.exit(1)

account = input("계정 ID(Account ID): ").strip()
key_id = input("액세스 키 ID(Access Key ID): ").strip()
secret = input("비밀 액세스 키(Secret Access Key): ").strip()
if not (account and key_id and secret):
    print("❌ 빈 칸이 있어요")
    sys.exit(1)

s3 = boto3.client("s3", endpoint_url=f"https://{account}.r2.cloudflarestorage.com",
                  aws_access_key_id=key_id, aws_secret_access_key=secret,
                  region_name="auto", config=Config(retries={"max_attempts": 5}))

mimetypes.add_type("audio/mpeg", ".mp3")
mimetypes.add_type("image/webp", ".webp")
mimetypes.add_type("application/json", ".json")

files = []
for d, _, names in os.walk(SRC):
    for n in names:
        p = os.path.join(d, n)
        files.append((p, os.path.relpath(p, SRC).replace(os.sep, "/")))
files.sort(key=lambda x: x[1])
print(f"\n올릴 파일 {len(files)}개\n")

ok, fails = 0, []
for path, key in files:
    ctype = mimetypes.guess_type(key)[0] or "application/octet-stream"
    try:
        s3.upload_file(path, BUCKET, key, ExtraArgs={
            "ContentType": ctype,
            # list.json 은 자주 바뀌니 짧게, 나머지는 오래 저장
            "CacheControl": "public, max-age=300" if key.endswith(".json") else "public, max-age=31536000",
        })
        ok += 1
        print(f"✔ {key}")
    except Exception as e:
        fails.append(key)
        print(f"❌ {key}  ({e})")
        if ok == 0 and len(fails) == 1 and ("AccessDenied" in str(e) or "InvalidAccessKeyId" in str(e) or "SignatureDoesNotMatch" in str(e)):
            print("   키가 틀린 것 같아요. 다시 확인하고 실행해 주세요")
            sys.exit(1)

print()
print(f"올린 파일 {ok}개 / 전체 {len(files)}개")
print("❌ 못 올린 파일이 있어요 — 다시 실행하면 돼요" if fails else "다 됐어요!")
