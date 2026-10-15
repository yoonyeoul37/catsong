# 번역 준비: 안 쓰는 옛날 문구 지우기 (한·영·일·중 번역 파일 4개)
# 지우는 것: 예전 재생화면 스타일 · "~됐습니다" 옛 알림 · 옛 확인창/버튼 · 옛 라디오 예약 문구
# 남기는 것: 라디오 나라별 구호 · 지역 이름 · 앱 이름/약관 주소 · 다크 모드/타이머 같은 기본 단어
import json, re, sys

FILES = ["lib/l10n/app_ko.arb", "lib/l10n/app_en.arb", "lib/l10n/app_ja.arb", "lib/l10n/app_zh.arb"]

DELETE = [
    # 예전 재생화면 스타일
    "styleCDDesc", "styleCassette", "styleCassetteDesc", "styleCardDesc",
    "styleVisualizer", "styleVisualizerDesc", "styleGradient", "styleGradientDesc", "themeColorHint",
    # "~됐습니다" 옛 알림
    "addedToFavorites", "removedFromFavorites", "songSaved", "ringtoneSet", "promoUnlocked",
    "addedToQueue", "addedToPlaylist", "deletedCount", "nameChanged", "renameFailed",
    "deleteFailedWithError", "radioRemovedFromFavorites", "radioAddedToFavoritesToast", "radioScheduleSetToast",
    # 옛 확인창 · 버튼
    "addToPlaylist", "addToFavorites", "removeFromFavorites", "setRingtone", "themeColor", "clearAll",
    "swipeToChange", "deleteSongConfirm", "deleteSongConfirmFormat", "noPlaylists", "deleteSelected",
    "deleteSelectedConfirm", "videoCount", "deleteVideoTitle", "deleteVideoConfirm",
    "videoPermissionRequired", "videoPermissionMessage", "openSettings", "newPlaylist",
    "renamePlaylistTitle", "deletePlaylistTitle", "deletePlaylistConfirm", "lyricsNotFound",
    "lyricsSearchPrompt", "lyricsSearchButton", "lyricsErrorLoadFailed", "deleteAllTooltip",
    "rangeFormat", "sosWorking",
    # 옛 라디오 예약 · 타이머
    "radioConnecting", "radioPopularCount", "radioScheduleChannelSwitch", "radioMaxSchedules",
    "radioSelectTime", "radioSetSchedule", "radioCancelAllSchedules", "minutesAfterEnd", "hoursAfterEnd",
]

def remove_keys(text, keys):
    lines = text.split("\n")
    out = []
    i = 0
    removed = set()
    while i < len(lines):
        ln = lines[i]
        m = re.match(r'^\s*"(@?)(\w+)"\s*:', ln)
        if m and m.group(2) in keys:
            removed.add(m.group(2))
            if m.group(1) == "@" and ln.rstrip().endswith("{"):
                # @key 설명 묶음: 같은 들여쓰기의 닫는 } 까지
                indent = len(ln) - len(ln.lstrip())
                i += 1
                while i < len(lines):
                    l2 = lines[i]
                    if (len(l2) - len(l2.lstrip())) == indent and l2.strip().startswith("}"):
                        break
                    i += 1
            i += 1
            continue
        out.append(ln)
        i += 1
    s = "\n".join(out)
    s = re.sub(r",(\s*\n\s*})", r"\1", s)  # 마지막 줄 뒤 쉼표 정리
    return s, removed

ok = True
results = {}
already = 0
for p in FILES:
    try:
        raw = open(p, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({p})"); ok = False; continue
    crlf = "\r\n" in raw
    t = raw.replace("\r\n", "\n")
    before = json.loads(t)
    present = [k for k in DELETE if k in before]
    name = p.split("/")[-1]
    if not present:
        print(f"· {name} 이미 적용돼 있어요"); already += 1; continue
    t2, removed = remove_keys(t, set(DELETE))
    try:
        after = json.loads(t2)
    except Exception as e:
        print(f"❌ {name} 정리 뒤 파일 모양이 깨져요 ({e})"); ok = False; continue
    left = [k for k in DELETE if k in after or ("@" + k) in after]
    lost = [k for k in before if k not in after and k.lstrip("@") not in DELETE]
    if left or lost:
        print(f"❌ {name} 남은 것 {left[:3]} / 잘못 지운 것 {lost[:3]}"); ok = False; continue
    results[p] = (t2, crlf)
    print(f"✔ {name}: {len(present)}개 지움 (남은 문구 {len([k for k in after if not k.startswith('@')])}개)")

if not ok:
    print("❌ 아무것도 저장 안 했어요."); sys.exit(1)
if not results:
    print("이미 적용돼 있어요"); sys.exit(0)

# 코드에서 지운 문구를 쓰는 곳이 없는지 마지막 확인
import os
code = ""
for dp, dn, fn in os.walk("lib"):
    if "l10n" in dp: continue
    for f in fn:
        if f.endswith(".dart") and ".bak" not in f:
            code += open(os.path.join(dp, f), encoding="utf-8").read()
used = [k for k in DELETE if re.search(r"\b" + re.escape(k) + r"\b", code)]
if used:
    print(f"❌ 코드에서 아직 쓰는 문구가 있어요: {used}. 아무것도 저장 안 했어요."); sys.exit(1)

for p, (t, crlf) in results.items():
    if crlf:
        t = t.replace("\n", "\r\n")
    open(p, "wb").write(t.encode("utf-8"))
print("완료")
