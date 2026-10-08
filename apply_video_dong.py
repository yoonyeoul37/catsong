# 동영상 찍은 곳: 동까지 ("서울 중구 명동") — 목록 칸은 짧게 "중구 명동"
# 실행: python apply_video_dong.py   (mp3_player_new 폴더에서)
import os, sys

SCREEN = os.path.join('lib', 'screens', 'video_screen.dart')
PROVIDER = os.path.join('lib', 'providers', 'video_provider.dart')
DONE_FILE = PROVIDER
DONE_MARK = 'videoPlaces2'

KOTLIN_EDITS = [
    ("주소에서 동·읍·면 찾아 붙이기",
     """                            .take(2)
                        place = if (parts.isNotEmpty()) parts.joinToString(" ") else a.countryName""",
     """                            .take(2)
                        // 동·읍·면까지 (예: 명동, 정자동, 기장읍) — 도로 이름(○○로)만 있는 주소면 구까지만
                        val dongRule = Regex("^[가-힣0-9.]+(동|읍|면|가|리)$")
                        val candidates = listOfNotNull(a.subLocality, a.thoroughfare, a.featureName) +
                            (a.getAddressLine(0) ?: "").split(" ")
                        val dong = candidates.map { it.trim() }
                            .firstOrNull { it.isNotEmpty() && dongRule.matches(it) && it !in parts }
                        val base = if (parts.isNotEmpty()) parts else listOfNotNull(a.countryName)
                        place = (base + listOfNotNull(dong)).joinToString(" ").ifBlank { null }"""),
]

PROVIDER_EDITS = [
    ("예전에 기억한 지역(동 없음)은 새로 찾기 — 불러오기",
     "getStringList('videoPlaces') ?? [];",
     "getStringList('videoPlaces2') ?? []; // 2 = 동까지 (예전 것은 새로 찾기)"),
    ("예전에 기억한 지역(동 없음)은 새로 찾기 — 저장",
     ".setStringList('videoPlaces', [",
     ".setStringList('videoPlaces2', ["),
]

SCREEN_EDITS = [
    ("목록 칸은 짧게 뒤 두 낱말만 (중구 명동)",
     """                                child: Text(
                                  place,
                                  maxLines: 1,""",
     """                                child: Text(
                                  // 칸이 좁아서 뒤 두 낱말만 (서울 중구 명동 → 중구 명동)
                                  place.split(' ').length > 2
                                      ? place.split(' ').sublist(place.split(' ').length - 2).join(' ')
                                      : place,
                                  maxLines: 1,"""),
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
    for path in (SCREEN, PROVIDER):
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path)
            print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
            sys.exit(1)
    if ma is None:
        print('❌ MainActivity.kt 를 못 찾았어요. mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    if DONE_MARK in open(DONE_FILE, encoding='utf-8').read():
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    jobs = [(ma, KOTLIN_EDITS), (PROVIDER, PROVIDER_EDITS), (SCREEN, SCREEN_EDITS)]
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
