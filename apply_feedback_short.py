# -*- coding: utf-8 -*-
# 의견 보내기: 길어서 잘리는 번역 짧게 (이메일 칸 · 메뉴 설명 베트남어)
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

EMAIL = {
    'vi': 'Email nhận trả lời (tùy chọn)',
    'es': 'Correo de respuesta (opcional)',
    'fr': 'E-mail de réponse (facultatif)',
    'it': 'Email di risposta (facoltativa)',
    'pt': 'E-mail para resposta (opcional)',
    'id': 'Email balasan (opsional)',
    'de': 'E-Mail für Antwort (optional)',
    'ru': 'E-mail для ответа (по желанию)',
    'uk': 'E-mail для відповіді (опційно)',
    'pl': 'Twój e-mail (opcjonalnie)',
    'tr': 'Yanıt e-postası (isteğe bağlı)',
    'ro': 'E-mail de răspuns (opțional)',
    'hu': 'Válasz e-mail (nem kötelező)',
    'hi': 'जवाब के लिए ईमेल (वैकल्पिक)',
    'th': 'อีเมลสำหรับตอบกลับ (ไม่บังคับ)',
}
MENU_VI_OLD = "'vi': 'Hãy cho chúng tôi biết bạn mong muốn gì ở Paransori',"
MENU_VI_NEW = "'vi': 'Bạn mong muốn gì ở Paransori?',"

p = None
for root, dirs, files in os.walk('lib'):
    if 'feedback_screen.dart' in files:
        p = os.path.join(root, 'feedback_screen.dart')
if not p:
    print('❌ feedback_screen.dart 못 찾음 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

m = re.search(r"\n  '답변받을 이메일 \(선택\)': \{\n((?:    '[^\n]*\n)+?)  \},\n", s)
if not m:
    print('❌ 이메일 칸 번역을 못 찾음 (apply_feedback_text.py 먼저 돌려 주세요)'); sys.exit(1)
blk = m.group(1)
done = all("    '%s': '%s',\n" % (L, t) in blk for L, t in EMAIL.items()) and MENU_VI_OLD not in s
if done:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

ok = True
nb = blk
for L, t in EMAIL.items():
    mm = re.search(r"    '%s': '[^\n]*',\n" % L, nb)
    if not mm:
        print('❌ 이메일 칸', L); ok = False; continue
    nb = nb[:mm.start()] + "    '%s': '%s',\n" % (L, t) + nb[mm.end():]
    print('✔ 이메일 칸', L, '→', t)
s = s[:m.start(1)] + nb + s[m.end(1):]

if MENU_VI_OLD in s:
    s = s.replace(MENU_VI_OLD, MENU_VI_NEW)
    print('✔ 메뉴 설명 베트남어 짧게')
elif MENU_VI_NEW in s:
    print('✔ 메뉴 설명 베트남어 이미 짧음')
else:
    print('❌ 메뉴 설명 베트남어 못 찾음'); ok = False

t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", s)
for a, b in ('()', '[]', '{}'):
    if t.count(a) != t.count(b):
        print('❌ 괄호 안 맞음', a); ok = False
if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)
if crlf: s = s.replace('\n', '\r\n')
open(p, 'wb').write(s.encode('utf-8'))
print('✔ 저장:', os.path.basename(p))
