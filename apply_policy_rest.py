# 개인정보처리방침·이용약관: '수면·집중' → '휴식·집중' (10개 언어) + 최종 수정일 10/15 + 개정 이력 한 줄
import os, re, sys

LANGS = ["ko", "en", "ja", "zh", "vi", "hi", "id", "th", "es", "pt"]

# 최종 수정일 (두 문서 공통)
DATE = {
    "ko": ("최종 수정 2026년 10월 10일", "최종 수정 2026년 10월 15일"),
    "en": ("Last updated October 10, 2026", "Last updated October 15, 2026"),
    "ja": ("最終更新日 2026年10月10日", "最終更新日 2026年10月15日"),
    "zh": ("最後更新 2026年10月10日", "最後更新 2026年10月15日"),
    "vi": ("Cập nhật lần cuối 10 tháng 10, 2026", "Cập nhật lần cuối 15 tháng 10, 2026"),
    "hi": ("अंतिम अपडेट 10 अक्टूबर 2026", "अंतिम अपडेट 15 अक्टूबर 2026"),
    "id": ("Terakhir diperbarui 10 Oktober 2026", "Terakhir diperbarui 15 Oktober 2026"),
    "th": ("อัปเดตล่าสุด 10 ตุลาคม 2026", "อัปเดตล่าสุด 15 ตุลาคม 2026"),
    "es": ("Última actualización 10 de octubre de 2026", "Última actualización 15 de octubre de 2026"),
    "pt": ("Última atualização 10 de outubro de 2026", "Última atualização 15 de outubro de 2026"),
}

# 개인정보처리방침: 받는 파일 목적 한 줄
PRIVACY = {
    "ko": [("자연 소리, 수면·집중 소리, 사진", "자연 소리, 휴식·집중 소리, 사진")],
    "en": [("sleep/focus sounds, and images", "relaxation/focus sounds, and images")],
    "ja": [("自然音、睡眠・集中サウンド、画像", "自然音、休息・集中サウンド、画像")],
    "zh": [("助眠／專注聲音及圖片", "休息／專注聲音及圖片")],
    "vi": [("âm thanh ngủ/tập trung và hình ảnh", "âm thanh thư giãn/tập trung và hình ảnh")],
    "hi": [("नींद/फ़ोकस की आवाज़ें और इमेज", "आराम/फ़ोकस की आवाज़ें और इमेज")],
    "id": [("suara tidur/fokus, dan gambar", "suara relaksasi/fokus, dan gambar")],
    "th": [("เสียงสำหรับการนอนหลับ/การจดจ่อ และรูปภาพ", "เสียงสำหรับการพักผ่อน/การจดจ่อ และรูปภาพ")],
    "es": [("sonidos para dormir/concentrarse e imágenes", "sonidos para relajarse/concentrarse e imágenes")],
    "pt": [("sons para dormir/concentrar-se e imagens", "sons para relaxar/concentrar-se e imagens")],
}

# 개인정보처리방침: 개정 이력 맨 위에 한 줄 추가 (기존 10/10 줄 앞)
HIST = {
    "ko": ("2026년 10월 10일:", "2026년 10월 15일: 파일 저장 서비스를 Supabase에서 Cloudflare R2로 변경, '수면·집중'을 '휴식·집중'으로 이름 변경"),
    "en": ("October 10, 2026:", "October 15, 2026: Changed file storage from Supabase to Cloudflare R2; renamed “sleep/focus” to “relaxation/focus”"),
    "ja": ("2026年10月10日：", "2026年10月15日：ファイル保存サービスをSupabaseからCloudflare R2に変更、「睡眠・集中」を「休息・集中」に名称変更"),
    "zh": ("2026年10月10日：", "2026年10月15日：檔案儲存服務由 Supabase 變更為 Cloudflare R2；「助眠／專注」更名為「休息／專注」"),
    "vi": ("10 tháng 10, 2026:", "15 tháng 10, 2026: Chuyển dịch vụ lưu trữ tệp từ Supabase sang Cloudflare R2; đổi tên “ngủ/tập trung” thành “thư giãn/tập trung”"),
    "hi": ("10 अक्टूबर 2026:", "15 अक्टूबर 2026: फ़ाइल स्टोरेज को Supabase से Cloudflare R2 पर बदला गया; “नींद/फ़ोकस” का नाम बदलकर “आराम/फ़ोकस” किया गया"),
    "id": ("10 Oktober 2026:", "15 Oktober 2026: Mengganti penyimpanan file dari Supabase ke Cloudflare R2; mengubah nama “tidur/fokus” menjadi “relaksasi/fokus”"),
    "th": ("10 ตุลาคม 2026:", "15 ตุลาคม 2026: เปลี่ยนบริการจัดเก็บไฟล์จาก Supabase เป็น Cloudflare R2 และเปลี่ยนชื่อ “การนอนหลับ/การจดจ่อ” เป็น “การพักผ่อน/การจดจ่อ”"),
    "es": ("10 de octubre de 2026:", "15 de octubre de 2026: se cambió el almacenamiento de archivos de Supabase a Cloudflare R2 y se renombró “dormir/concentrarse” como “relajarse/concentrarse”"),
    "pt": ("10 de outubro de 2026:", "15 de outubro de 2026: armazenamento de arquivos alterado de Supabase para Cloudflare R2 e “dormir/concentrar-se” renomeado para “relaxar/concentrar-se”"),
}

# 이용약관: (먼저 바꿀 한 문장, 나머지 전부 바꿀 말)
TERMS = {
    "ko": ("수면·집중 소리는 휴식을 돕기 위한 콘텐츠이며", "휴식·집중 소리는 편안한 시간을 돕기 위한 콘텐츠이며", "수면·집중", "휴식·집중"),
    "en": ("Sleep and focus sounds are content to help you relax", "Relaxation and focus sounds are content to help you unwind", "sleep/focus", "relaxation/focus"),
    "ja": ("睡眠・集中サウンドはリラックスを助ける", "休息・集中サウンドはリラックスを助ける", "睡眠・集中", "休息・集中"),
    "zh": ("睡眠・專注音是幫助放鬆的內容", "休息・專注音是幫助放鬆的內容", "助眠／專注", "休息／專注"),
    "vi": ("Âm thanh ngủ và tập trung", "Âm thanh thư giãn và tập trung", "ngủ/tập trung", "thư giãn/tập trung"),
    "hi": ("नींद और फ़ोकस ध्वनियाँ", "आराम और फ़ोकस ध्वनियाँ", "नींद/फ़ोकस", "आराम/फ़ोकस"),
    "id": ("Suara tidur dan fokus", "Suara relaksasi dan fokus", "tidur/fokus", "relaksasi/fokus"),
    "th": ("เสียงสำหรับการนอนและการจดจ่อ", "เสียงสำหรับการพักผ่อนและการจดจ่อ", "การนอนหลับ/การจดจ่อ", "การพักผ่อน/การจดจ่อ"),
    "es": ("Los sonidos para dormir y concentrarse", "Los sonidos para relajarse y concentrarse", "dormir/concentrarse", "relajarse/concentrarse"),
    "pt": ("Os sons para dormir e focar", "Os sons para relaxar e focar", "dormir/concentrar-se", "relaxar/concentrar-se"),
}

def find(name):
    hits = []
    for root, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in (".git", "build", ".dart_tool", "node_modules")]
        if name in files:
            hits.append(os.path.join(root, name))
    return hits

def split_articles(text):
    parts = {}
    for m in re.finditer(r'<article class="doc" data-lang="(\w+)".*?</article>', text, re.S):
        parts[m.group(1)] = (m.start(), m.end())
    return parts

ok = True
out = {}
changed = 0

for fname, kind in (("privacy_policy.html", "privacy"), ("terms_of_service.html", "terms")):
    found = find(fname)
    if len(found) != 1:
        print(f"❌ {fname} 파일을 {len(found)}개 찾았어요")
        ok = False
        continue
    path = found[0]
    text = open(path, "rb").read().decode("utf-8")
    arts = split_articles(text)
    pieces = []
    last = 0
    for lang in LANGS:
        if lang not in arts:
            print(f"❌ {fname} {lang} 부분을 못 찾았어요")
            ok = False
            continue
        s, e = arts[lang]
        a = text[s:e]
        msgs = []
        # 날짜
        o, n = DATE[lang]
        if a.count(o) == 1:
            a = a.replace(o, n); msgs.append("날짜"); changed += 1
        elif a.count(n) != 1:
            print(f"❌ {fname} {lang} 날짜 못 찾음"); ok = False
        if kind == "privacy":
            for o, n in PRIVACY[lang]:
                if a.count(o) == 1:
                    a = a.replace(o, n); msgs.append("이름"); changed += 1
                elif a.count(n) != 1:
                    print(f"❌ {fname} {lang} 이름 못 찾음"); ok = False
            key, line = HIST[lang]
            if line in a:
                pass
            elif a.count("<ul><li>" + key) == 1:
                a = a.replace("<ul><li>" + key, "<ul><li>" + line + "</li><li>" + key)
                msgs.append("개정 이력"); changed += 1
            else:
                print(f"❌ {fname} {lang} 개정 이력 자리 못 찾음"); ok = False
        else:
            o1, n1, o2, n2 = TERMS[lang]
            if a.count(o1) == 1:
                a = a.replace(o1, n1); msgs.append("첫 문장"); changed += 1
            elif a.count(n1) != 1:
                print(f"❌ {fname} {lang} 첫 문장 못 찾음"); ok = False
            c = a.count(o2)
            if c > 0:
                a = a.replace(o2, n2); msgs.append(f"이름 {c}곳"); changed += 1
            elif n2 not in a:
                print(f"❌ {fname} {lang} 이름 못 찾음"); ok = False
        if msgs:
            print(f"✔ {fname} {lang}: " + ", ".join(msgs))
        pieces.append(text[last:s]); pieces.append(a); last = e
    pieces.append(text[last:])
    out[path] = "".join(pieces)

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if changed == 0:
    print("이미 적용돼 있어요")
    sys.exit(0)
for path, t in out.items():
    open(path, "wb").write(t.encode("utf-8"))
print("완료")
