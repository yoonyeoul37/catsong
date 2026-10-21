# -*- coding: utf-8 -*-
# 설정 '음성 안내' → '인사 멜로디' (23개 언어) + ⓘ 설명 + 아이콘 음표로
import os, sys, json

L10N = os.path.join('lib', 'l10n')
SETTINGS = os.path.join('lib', 'screens', 'settings_screen.dart')

NEW = {
    'ko': ('인사 멜로디', '앱을 켜고 끌 때 짧은 멜로디가 나와요.'),
    'en': ('Melody', 'A short melody plays when you open or close the app.'),
    'ja': ('メロディー', 'アプリの起動・終了時に短いメロディーが流れます。'),
    'zh': ('问候旋律', '打开或关闭应用时播放一段简短的旋律。'),
    'zh_Hant': ('問候旋律', '開啟或關閉應用程式時播放一段簡短的旋律。'),
    'de': ('Melodie', 'Beim Öffnen und Schließen der App ertönt eine kurze Melodie.'),
    'es': ('Melodía', 'Suena una melodía corta al abrir o cerrar la app.'),
    'fr': ('Mélodie', "Une courte mélodie à l'ouverture et à la fermeture de l'app."),
    'id': ('Melodi', 'Melodi singkat diputar saat kamu membuka atau menutup aplikasi.'),
    'pt': ('Melodia', 'Uma melodia curta toca ao abrir ou fechar o app.'),
    'th': ('เมโลดี้', 'มีเมโลดี้สั้นๆ เมื่อเปิดหรือปิดแอป'),
    'vi': ('Giai điệu', 'Một giai điệu ngắn phát khi bạn mở hoặc đóng ứng dụng.'),
    'ru': ('Мелодия', 'Короткая мелодия при открытии и закрытии приложения.'),
    'it': ('Melodia', "Una breve melodia quando apri o chiudi l'app."),
    'tr': ('Melodi', 'Uygulamayı açarken veya kapatırken kısa bir melodi çalar.'),
    'pl': ('Melodia', 'Krótka melodia przy otwieraniu i zamykaniu aplikacji.'),
    'uk': ('Мелодія', 'Коротка мелодія, коли відкриваєте чи закриваєте додаток.'),
    'hi': ('धुन', 'ऐप खोलने या बंद करने पर एक छोटी-सी धुन बजती है।'),
    'ro': ('Melodie', 'O melodie scurtă se aude când deschizi sau închizi aplicația.'),
    'cs': ('Melodie', 'Při otevření nebo zavření aplikace zazní krátká melodie.'),
    'hu': ('Dallam', 'Rövid dallam szól az app megnyitásakor vagy bezárásakor.'),
    'ar': ('نغمة', 'تُعزف نغمة قصيرة عند فتح التطبيق أو إغلاقه.'),
    'ur': ('دھن', 'ایپ کھولنے یا بند کرنے پر ایک مختصر دھن چلتی ہے۔'),
}

OLD_ICON = "tile(Icons.record_voice_over_outlined, tr.voiceGuide,"
NEW_ICON = "tile(Icons.music_note_outlined, tr.voiceGuide,"  # 인사 멜로디: 음표 아이콘


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def set_value(text, key, value, fname):
    """"key": "옛 글", 한 줄을 찾아 값만 바꾸기"""
    lines = text.split('\n')
    hit = [i for i, l in enumerate(lines) if l.strip().startswith('"%s":' % key)]
    if len(hit) != 1:
        print('❌', fname, key, '줄을 못 찾았어요 (찾은 개수: %d) — 아무것도 저장 안 했어요' % len(hit))
        sys.exit(1)
    i = hit[0]
    l = lines[i]
    indent = l[:len(l) - len(l.lstrip())]
    comma = ',' if l.rstrip().endswith(',') else ''
    lines[i] = '%s"%s": %s%s' % (indent, key, json.dumps(value, ensure_ascii=False), comma)
    return '\n'.join(lines)


def main():
    ko, _ = load(os.path.join(L10N, 'app_ko.arb'))
    if json.loads(ko).get('voiceGuide') == NEW['ko'][0]:
        print('이미 적용돼 있어요')
        return
    out = []
    for lang, (label, info) in NEW.items():
        p = os.path.join(L10N, 'app_%s.arb' % lang)
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        text, crlf = load(p)
        text = set_value(text, 'voiceGuide', label, os.path.basename(p))
        text = set_value(text, 'voiceGuideInfo', info, os.path.basename(p))
        try:
            d = json.loads(text)
        except Exception as e:
            print('❌', os.path.basename(p), 'JSON 모양이 깨졌어요:', e, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        if d['voiceGuide'] != label or d['voiceGuideInfo'] != info:
            print('❌', os.path.basename(p), '값 확인 실패 — 아무것도 저장 안 했어요')
            sys.exit(1)
        out.append((p, text, crlf))
        print('✔', os.path.basename(p), '→', label)
    text, crlf = load(SETTINGS)
    if text.count(OLD_ICON) != 1:
        print('❌ settings_screen.dart 아이콘 줄을 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    out.append((SETTINGS, text.replace(OLD_ICON, NEW_ICON), crlf))
    print('✔ 설정 아이콘 → 음표')
    for p, text, crlf in out:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(p, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('✔ 저장했어요 (%d개 파일)' % len(out))


main()
