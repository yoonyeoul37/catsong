# -*- coding: utf-8 -*-
# 설정 → 언어: 모든 언어 이름 옆 괄호에 지금 앱 언어로 쓴 이름
#   예) 한국어 화면: Deutsch (독일어) · 繁體中文 (중국어 번체) · 简体中文 (중국어 간체)
# ※ apply_lang_stage2.py 를 먼저 실행한 뒤에
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_lang_names.py
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
E = json.loads('[["lib/providers/theme_provider.dart", "포르투갈어 이름 짧게 (괄호가 두 번 안 붙게)", "    (\'pt\', \'Português (Brasil)\'),\\n", "    (\'pt\', \'Português\'),\\n"], ["lib/screens/settings_screen.dart", "언어 이름 옆 괄호: 지금 앱 언어로 쓴 이름 (모든 언어)", "        // 중국어는 번체·간체를 지금 앱 언어로 괄호 안에 (중국어 화면에선 이름에 이미 있어서 안 붙임)\\n        final zh = Localizations.localeOf(context).languageCode == \'zh\'; // 중국어 화면은 이름에 이미 있음\\n        final tag = zh ? \'\' : code == \'zh_Hant\' ? _langText(\'hant\') : code == \'zh_Hans\' ? _langText(\'hans\') : \'\';\\n        return tag.isEmpty ? l.$2 : \'${l.$2} ($tag)\';\\n", "        // 괄호 안에 지금 앱 언어로 쓴 이름 (예: Deutsch (독일어)) — 지금 언어 자신이면 이름이 같아서 안 붙임\\n        final tag = _langLocalName(code);\\n        return tag.isEmpty || tag == l.$2 ? l.$2 : \'${l.$2} ($tag)\';\\n"], ["lib/screens/settings_screen.dart", "지금 앱 언어로 쓴 언어 이름 (번역 파일 langName…)", "  /// 설정 → 언어: 폰 설정 따라가기 + 앱이 아는 언어들 (고르면 바로 바뀌고 기억)\\n", "  /// 언어 이름을 지금 앱 언어로 (번역 파일 langName…)\\n  String _langLocalName(String code) {\\n    final l = AppLocalizations.of(context)!;\\n    return switch (code) {\\n      \'ko\' => l.langNameKo,\\n      \'en\' => l.langNameEn,\\n      \'ja\' => l.langNameJa,\\n      \'zh_Hant\' => l.langNameZhHant,\\n      \'zh_Hans\' => l.langNameZhHans,\\n      \'id\' => l.langNameId,\\n      \'de\' => l.langNameDe,\\n      \'es\' => l.langNameEs,\\n      \'fr\' => l.langNameFr,\\n      \'pt\' => l.langNamePt,\\n      \'vi\' => l.langNameVi,\\n      \'th\' => l.langNameTh,\\n      _ => \'\',\\n    };\\n  }\\n\\n  /// 설정 → 언어: 폰 설정 따라가기 + 앱이 아는 언어들 (고르면 바로 바뀌고 기억)\\n"]]')
ARB = json.loads('{"ko": {"langNameKo": "한국어", "langNameEn": "영어", "langNameJa": "일본어", "langNameZhHant": "중국어 번체", "langNameZhHans": "중국어 간체", "langNameId": "인도네시아어", "langNameDe": "독일어", "langNameEs": "스페인어", "langNameFr": "프랑스어", "langNamePt": "포르투갈어", "langNameVi": "베트남어", "langNameTh": "태국어"}, "en": {"langNameKo": "Korean", "langNameEn": "English", "langNameJa": "Japanese", "langNameZhHant": "Traditional Chinese", "langNameZhHans": "Simplified Chinese", "langNameId": "Indonesian", "langNameDe": "German", "langNameEs": "Spanish", "langNameFr": "French", "langNamePt": "Portuguese", "langNameVi": "Vietnamese", "langNameTh": "Thai"}, "ja": {"langNameKo": "韓国語", "langNameEn": "英語", "langNameJa": "日本語", "langNameZhHant": "繁体字中国語", "langNameZhHans": "簡体字中国語", "langNameId": "インドネシア語", "langNameDe": "ドイツ語", "langNameEs": "スペイン語", "langNameFr": "フランス語", "langNamePt": "ポルトガル語", "langNameVi": "ベトナム語", "langNameTh": "タイ語"}, "zh_Hant": {"langNameKo": "韓文", "langNameEn": "英文", "langNameJa": "日文", "langNameZhHant": "繁體中文", "langNameZhHans": "簡體中文", "langNameId": "印尼文", "langNameDe": "德文", "langNameEs": "西班牙文", "langNameFr": "法文", "langNamePt": "葡萄牙文", "langNameVi": "越南文", "langNameTh": "泰文"}, "zh": {"langNameKo": "韩语", "langNameEn": "英语", "langNameJa": "日语", "langNameZhHant": "繁体中文", "langNameZhHans": "简体中文", "langNameId": "印尼语", "langNameDe": "德语", "langNameEs": "西班牙语", "langNameFr": "法语", "langNamePt": "葡萄牙语", "langNameVi": "越南语", "langNameTh": "泰语"}, "id": {"langNameKo": "Korea", "langNameEn": "Inggris", "langNameJa": "Jepang", "langNameZhHant": "Tionghoa Tradisional", "langNameZhHans": "Tionghoa Sederhana", "langNameId": "Bahasa Indonesia", "langNameDe": "Jerman", "langNameEs": "Spanyol", "langNameFr": "Prancis", "langNamePt": "Portugis", "langNameVi": "Vietnam", "langNameTh": "Thai"}, "de": {"langNameKo": "Koreanisch", "langNameEn": "Englisch", "langNameJa": "Japanisch", "langNameZhHant": "Trad. Chinesisch", "langNameZhHans": "Vereinf. Chinesisch", "langNameId": "Indonesisch", "langNameDe": "Deutsch", "langNameEs": "Spanisch", "langNameFr": "Französisch", "langNamePt": "Portugiesisch", "langNameVi": "Vietnamesisch", "langNameTh": "Thailändisch"}, "es": {"langNameKo": "Coreano", "langNameEn": "Inglés", "langNameJa": "Japonés", "langNameZhHant": "Chino tradicional", "langNameZhHans": "Chino simplificado", "langNameId": "Indonesio", "langNameDe": "Alemán", "langNameEs": "Español", "langNameFr": "Francés", "langNamePt": "Portugués", "langNameVi": "Vietnamita", "langNameTh": "Tailandés"}, "fr": {"langNameKo": "Coréen", "langNameEn": "Anglais", "langNameJa": "Japonais", "langNameZhHant": "Chinois traditionnel", "langNameZhHans": "Chinois simplifié", "langNameId": "Indonésien", "langNameDe": "Allemand", "langNameEs": "Espagnol", "langNameFr": "Français", "langNamePt": "Portugais", "langNameVi": "Vietnamien", "langNameTh": "Thaï"}, "pt": {"langNameKo": "Coreano", "langNameEn": "Inglês", "langNameJa": "Japonês", "langNameZhHant": "Chinês tradicional", "langNameZhHans": "Chinês simplificado", "langNameId": "Indonésio", "langNameDe": "Alemão", "langNameEs": "Espanhol", "langNameFr": "Francês", "langNamePt": "Português", "langNameVi": "Vietnamita", "langNameTh": "Tailandês"}, "vi": {"langNameKo": "Tiếng Hàn", "langNameEn": "Tiếng Anh", "langNameJa": "Tiếng Nhật", "langNameZhHant": "Tiếng Trung phồn thể", "langNameZhHans": "Tiếng Trung giản thể", "langNameId": "Tiếng Indonesia", "langNameDe": "Tiếng Đức", "langNameEs": "Tiếng Tây Ban Nha", "langNameFr": "Tiếng Pháp", "langNamePt": "Tiếng Bồ Đào Nha", "langNameVi": "Tiếng Việt", "langNameTh": "Tiếng Thái"}, "th": {"langNameKo": "เกาหลี", "langNameEn": "อังกฤษ", "langNameJa": "ญี่ปุ่น", "langNameZhHant": "จีนตัวเต็ม", "langNameZhHans": "จีนตัวย่อ", "langNameId": "อินโดนีเซีย", "langNameDe": "เยอรมัน", "langNameEs": "สเปน", "langNameFr": "ฝรั่งเศส", "langNamePt": "โปรตุเกส", "langNameVi": "เวียดนาม", "langNameTh": "ไทย"}}')
ARBF = {'ko': 'app_ko', 'en': 'app_en', 'ja': 'app_ja', 'zh_Hant': 'app_zh_Hant', 'zh': 'app_zh', 'id': 'app_id', 'de': 'app_de', 'es': 'app_es', 'fr': 'app_fr', 'pt': 'app_pt', 'vi': 'app_vi', 'th': 'app_th'}


def load(p):
    if not os.path.exists(p):
        print(f'❌ {p} 파일이 없어요. (apply_lang_stage2.py 먼저 / 프로젝트 폴더에서 실행)'); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def main():
    texts, crlf = {}, {}
    for p in sorted({e[0] for e in E}) + [f'lib/l10n/{f}.arb' for f in ARBF.values()]:
        texts[p], crlf[p] = load(p)
    if '_langLocalName(' in texts['lib/screens/settings_screen.dart'] and '"langNameKo"' in texts['lib/l10n/app_ko.arb']:
        print('이미 적용돼 있어요'); return
    ok = True
    for p, name, old, new in E:
        n = texts[p].count(old)
        if n == 1:
            texts[p] = texts[p].replace(old, new); print(f'✔ {os.path.basename(p)} - {name}')
        else:
            print(f'❌ {os.path.basename(p)} - {name} (찾을 코드가 {n}군데)'); ok = False
    for l, f in ARBF.items():
        p = f'lib/l10n/{f}.arb'
        t = texts[p]
        have = json.loads(t)
        dup = [k for k in ARB[l] if k in have]
        if dup:
            print(f'❌ {f}.arb - 이미 있는 이름: {dup[:3]}'); ok = False; continue
        end = t.rstrip().rfind('}')
        t2 = t[:end].rstrip() + ',\n' + ',\n'.join(
            f'  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}' for k, v in ARB[l].items()) + '\n' + t[end:]
        json.loads(t2)
        texts[p] = t2
        print(f'✔ {f}.arb - 언어 이름 12개')
    if not ok:
        print('\n❌ 문제가 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for p, t in texts.items():
        open(p, 'wb').write((t.replace('\n', '\r\n') if crlf[p] else t).encode('utf-8'))
    print('\n완료! flutter gen-l10n 후 flutter run 해 주세요.')


main()
