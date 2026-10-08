# 동영상 찍은 곳: 첫 주소가 도로명(○○로·○○길)이라 동이 없으면, 다른 후보 주소에서 동 찾기
# 실행: python apply_video_dong2.py   (mp3_player_new 폴더에서)
import os, sys

PROVIDER = os.path.join('lib', 'providers', 'video_provider.dart')
DONE_FILE = PROVIDER
DONE_MARK = 'videoPlaces3'

KOTLIN_EDITS = [
    ("주소 후보를 1개 → 5개 받기",
     """                    val a = android.location.Geocoder(this, java.util.Locale.getDefault())
                        .getFromLocation(lat, lng, 1)?.firstOrNull()""",
     """                    val all = android.location.Geocoder(this, java.util.Locale.getDefault())
                        .getFromLocation(lat, lng, 5) ?: emptyList()
                    val a = all.firstOrNull()
                    all.forEachIndexed { i, x ->
                        android.util.Log.d("VideoPlace", "후보$i=${x.getAddressLine(0)} | subLoc=${x.subLocality} | road=${x.thoroughfare} | feat=${x.featureName}")
                    }"""),
    ("동은 후보 주소 전부에서 찾기",
     """                        val candidates = listOfNotNull(a.subLocality, a.thoroughfare, a.featureName) +
                            (a.getAddressLine(0) ?: "").split(" ")""",
     """                        // 첫 주소가 도로명이면 동이 없어서, 다른 후보 주소들에서도 찾기
                        val candidates = all.flatMap { x ->
                            listOfNotNull(x.subLocality, x.thoroughfare, x.featureName) +
                                (x.getAddressLine(0) ?: "").split(" ")
                        }"""),
]

PROVIDER_EDITS = [
    ("예전에 기억한 지역(동 없음)은 새로 찾기 — 불러오기",
     "getStringList('videoPlaces2') ?? []; // 2 = 동까지 (예전 것은 새로 찾기)",
     "getStringList('videoPlaces3') ?? []; // 3 = 후보 주소에서 동 찾기 (예전 것은 새로 찾기)"),
    ("예전에 기억한 지역(동 없음)은 새로 찾기 — 저장",
     ".setStringList('videoPlaces2', [",
     ".setStringList('videoPlaces3', ["),
]


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def find_main_activity():
    for root, _, files in os.walk(os.path.join('android', 'app', 'src', 'main')):
        if 'MainActivity.kt' in files:
            return os.path.join(root, 'MainActivity.kt')
    return None


def main():
    ma = find_main_activity()
    if not os.path.exists(PROVIDER):
        print('❌ 파일을 못 찾았어요:', PROVIDER)
        print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)
    if ma is None:
        print('❌ MainActivity.kt 를 못 찾았어요. mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    if DONE_MARK in open(DONE_FILE, encoding='utf-8').read():
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    jobs = [(ma, KOTLIN_EDITS), (PROVIDER, PROVIDER_EDITS)]
    results = {}
    num = 0
    for path, edits in jobs:
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balance(text)
        print(f'[{os.path.basename(path)}]')
        for name, old, new in edits:
            num += 1
            n = text.count(old)
            if n != 1:
                print(f'❌ {num}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
                print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
                sys.exit(1)
            text = text.replace(old, new)
            print(f'✔ {num}. {name}')
        if balance(text) != before:
            print(f'❌ {os.path.basename(path)} 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
            sys.exit(1)
        if crlf:
            text = text.replace('\n', '\r\n')
        results[path] = text

    for path, text in results.items():
        open(path, 'wb').write(text.encode('utf-8'))
    print(f'완료! {num}군데 바꿨어요.')


main()
