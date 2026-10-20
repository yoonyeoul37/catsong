# -*- coding: utf-8 -*-
# 의견 보내기 문구 정리: 종류 2개(오류 신고 · 기능 제안), 종류별 안내 문구, 메뉴 설명 변경
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

LANGS = ['ja', 'zh', 'zh_Hant', 'de', 'es', 'fr', 'it', 'pt', 'pl', 'ru', 'tr', 'id', 'vi', 'th', 'uk', 'hi', 'ro', 'cs', 'hu', 'ar', 'ur']

# 새 문구 번역 (한국어 → 21개 언어)
NEW = {
'파란소리에 바라는 점을 들려주세요.': [
  'Paransoriへのご要望をお聞かせください', '告诉我们你对 Paransori 的期待', '告訴我們你對 Paransori 的期待',
  'Was wünschst du dir von Paransori?', 'Cuéntanos qué esperas de Paransori', 'Dis-nous ce que tu attends de Paransori',
  'Dicci cosa desideri da Paransori', 'Conte o que você espera do Paransori', 'Powiedz, czego oczekujesz od Paransori',
  'Расскажите, чего вы ждёте от Paransori', 'Paransori’den beklentini anlat', 'Ceritakan harapanmu untuk Paransori',
  'Hãy cho chúng tôi biết bạn mong muốn gì ở Paransori', 'บอกเราว่าคุณอยากได้อะไรจาก Paransori', 'Розкажіть, чого ви чекаєте від Paransori',
  'बताइए आप Paransori से क्या चाहते हैं', 'Spune-ne ce îți dorești de la Paransori', 'Řekněte nám, co byste od Paransori chtěli',
  'Mondd el, mit vársz a Paransoritól', 'أخبرنا بما تتمناه من Paransori', 'بتائیں آپ Paransori سے کیا چاہتے ہیں'],
'어떤 의견을 보내시겠어요?': [
  'どのようなご意見ですか？', '你想发送哪种意见？', '你想傳送哪種意見？',
  'Was möchtest du uns senden?', '¿Qué tipo de comentario quieres enviar?', 'Quel type d’avis veux-tu envoyer ?',
  'Che tipo di feedback vuoi inviare?', 'Que tipo de feedback você quer enviar?', 'Jaką opinię chcesz wysłać?',
  'Какой отзыв вы хотите отправить?', 'Ne tür bir geri bildirim göndermek istersin?', 'Masukan apa yang ingin kamu kirim?',
  'Bạn muốn gửi góp ý gì?', 'คุณต้องการส่งความคิดเห็นแบบไหน', 'Який відгук ви хочете надіслати?',
  'आप किस तरह की प्रतिक्रिया भेजना चाहते हैं?', 'Ce fel de feedback vrei să trimiți?', 'Jakou zpětnou vazbu chcete odeslat?',
  'Milyen visszajelzést küldenél?', 'ما نوع الملاحظة التي تريد إرسالها؟', 'آپ کس قسم کی رائے بھیجنا چاہتے ہیں؟'],
'오류 신고': [
  '不具合の報告', '报告问题', '回報問題',
  'Fehler melden', 'Informar de un error', 'Signaler un bug',
  'Segnala un errore', 'Relatar erro', 'Zgłoś błąd',
  'Сообщить об ошибке', 'Hata bildir', 'Laporkan bug',
  'Báo lỗi', 'แจ้งข้อผิดพลาด', 'Повідомити про помилку',
  'त्रुटि बताएं', 'Raportează o eroare', 'Nahlásit chybu',
  'Hiba bejelentése', 'الإبلاغ عن خطأ', 'خرابی کی اطلاع دیں'],
'기능 제안': [
  '機能のご要望', '功能建议', '功能建議',
  'Funktion vorschlagen', 'Sugerir una función', 'Suggérer une fonction',
  'Suggerisci una funzione', 'Sugerir recurso', 'Zaproponuj funkcję',
  'Предложить функцию', 'Özellik öner', 'Usulkan fitur',
  'Đề xuất tính năng', 'เสนอฟีเจอร์', 'Запропонувати функцію',
  'फ़ीचर सुझाएं', 'Sugerează o funcție', 'Navrhnout funkci',
  'Funkció javaslása', 'اقتراح ميزة', 'فیچر تجویز کریں'],
'의견을 자유롭게 남겨주세요.': [
  'ご意見を自由にお書きください', '请随意留下你的意见', '請隨意留下你的意見',
  'Schreib uns gern deine Meinung', 'Déjanos tu opinión libremente', 'Laisse-nous ton avis librement',
  'Lasciaci liberamente il tuo parere', 'Deixe sua opinião à vontade', 'Podziel się swoją opinią',
  'Оставьте свой отзыв', 'Görüşünü dilediğin gibi yaz', 'Silakan tulis masukanmu',
  'Hãy thoải mái để lại góp ý', 'แสดงความคิดเห็นได้ตามสบาย', 'Залиште свій відгук',
  'अपनी राय खुलकर लिखें', 'Lasă-ne liber părerea ta', 'Napište nám svůj názor',
  'Írd meg nyugodtan a véleményed', 'اترك رأيك بحرية', 'اپنی رائے کھل کر لکھیں'],
'어떤 문제가 발생했는지 알려주세요.': [
  'どんな問題が起きたか教えてください', '请告诉我们发生了什么问题', '請告訴我們發生了什麼問題',
  'Beschreib uns, welches Problem aufgetreten ist', 'Cuéntanos qué problema ocurrió', 'Dis-nous quel problème est survenu',
  'Dicci quale problema si è verificato', 'Conte qual problema aconteceu', 'Opisz, jaki problem wystąpił',
  'Расскажите, какая проблема возникла', 'Hangi sorunun oluştuğunu anlat', 'Ceritakan masalah apa yang terjadi',
  'Hãy cho chúng tôi biết lỗi gì đã xảy ra', 'บอกเราว่าเกิดปัญหาอะไรขึ้น', 'Розкажіть, яка проблема виникла',
  'बताइए क्या समस्या हुई', 'Spune-ne ce problemă a apărut', 'Popište, jaký problém nastal',
  'Írd le, milyen hiba történt', 'أخبرنا بالمشكلة التي حدثت', 'بتائیں کیا مسئلہ پیش آیا'],
'파란소리에 바라는 기능을 알려주세요.': [
  'Paransoriに欲しい機能を教えてください', '告诉我们你希望 Paransori 增加的功能', '告訴我們你希望 Paransori 增加的功能',
  'Welche Funktion wünschst du dir in Paransori?', 'Cuéntanos qué función te gustaría en Paransori', 'Dis-nous quelle fonction tu aimerais dans Paransori',
  'Dicci quale funzione vorresti in Paransori', 'Conte qual recurso você gostaria no Paransori', 'Napisz, jakiej funkcji brakuje Ci w Paransori',
  'Расскажите, какую функцию вы хотите в Paransori', 'Paransori’de görmek istediğin özelliği anlat', 'Ceritakan fitur yang kamu inginkan di Paransori',
  'Hãy cho chúng tôi biết tính năng bạn muốn có trong Paransori', 'บอกเราว่าอยากให้ Paransori มีฟีเจอร์อะไร', 'Розкажіть, яку функцію ви хочете в Paransori',
  'बताइए आप Paransori में कौन-सा फ़ीचर चाहते हैं', 'Spune-ne ce funcție ți-ai dori în Paransori', 'Napište, jakou funkci byste v Paransori chtěli',
  'Írd meg, milyen funkciót szeretnél a Paransoriban', 'أخبرنا بالميزة التي تتمناها في Paransori', 'بتائیں آپ Paransori میں کون سا فیچر چاہتے ہیں'],
'사진 첨부': [
  '写真を添付', '添加图片', '新增圖片',
  'Foto anhängen', 'Adjuntar foto', 'Joindre une photo',
  'Allega foto', 'Anexar foto', 'Załącz zdjęcie',
  'Прикрепить фото', 'Fotoğraf ekle', 'Lampirkan foto',
  'Đính kèm ảnh', 'แนบรูป', 'Прикріпити фото',
  'फ़ोटो जोड़ें', 'Atașează foto', 'Přiložit foto',
  'Fotó csatolása', 'إرفاق صورة', 'تصویر منسلک کریں'],
'답변받을 이메일 (선택)': [
  '返信用メール（任意）', '接收回复的邮箱（选填）', '接收回覆的信箱（選填）',
  'E-Mail für die Antwort (optional)', 'Correo para recibir respuesta (opcional)', 'E-mail pour recevoir une réponse (facultatif)',
  'Email per ricevere risposta (facoltativa)', 'E-mail para receber resposta (opcional)', 'E-mail do odpowiedzi (opcjonalnie)',
  'E-mail для ответа (необязательно)', 'Yanıt için e-posta (isteğe bağlı)', 'Email untuk menerima balasan (opsional)',
  'Email nhận phản hồi (không bắt buộc)', 'อีเมลสำหรับรับคำตอบ (ไม่บังคับ)', 'E-mail для відповіді (необов’язково)',
  'जवाब पाने के लिए ईमेल (वैकल्पिक)', 'E-mail pentru răspuns (opțional)', 'E-mail pro odpověď (nepovinné)',
  'E-mail a válaszhoz (nem kötelező)', 'البريد لتلقي الرد (اختياري)', 'جواب کے لیے ای میل (اختیاری)'],
'기기 정보와 앱 버전은 문제 확인을 위해서만 사용돼요.': [
  '端末情報とアプリのバージョンは、問題の確認にのみ使用されます。', '设备信息和应用版本仅用于确认问题。', '裝置資訊和 App 版本只用於確認問題。',
  'Geräteinfos und App-Version werden nur zur Fehlerprüfung verwendet.', 'La información del dispositivo y la versión de la app solo se usan para revisar problemas.', 'Les infos de l’appareil et la version de l’app servent uniquement à vérifier les problèmes.',
  'Le informazioni sul dispositivo e la versione dell’app servono solo per verificare i problemi.', 'As informações do aparelho e a versão do app são usadas só para verificar problemas.', 'Informacje o urządzeniu i wersja aplikacji służą tylko do sprawdzania problemów.',
  'Данные об устройстве и версия приложения используются только для проверки проблем.', 'Cihaz bilgisi ve uygulama sürümü yalnızca sorunları incelemek için kullanılır.', 'Info perangkat dan versi aplikasi hanya digunakan untuk memeriksa masalah.',
  'Thông tin thiết bị và phiên bản ứng dụng chỉ dùng để kiểm tra lỗi.', 'ข้อมูลอุปกรณ์และเวอร์ชันแอปใช้เพื่อตรวจสอบปัญหาเท่านั้น', 'Дані про пристрій і версія застосунку використовуються лише для перевірки проблем.',
  'डिवाइस जानकारी और ऐप वर्ज़न केवल समस्या जांचने के लिए उपयोग होते हैं।', 'Informațiile despre dispozitiv și versiunea aplicației sunt folosite doar pentru verificarea problemelor.', 'Informace o zařízení a verze aplikace slouží jen ke kontrole problémů.',
  'Az eszközadatokat és az alkalmazás verzióját csak a hibák ellenőrzésére használjuk.', 'تُستخدم معلومات الجهاز وإصدار التطبيق للتحقق من المشكلات فقط.', 'ڈیوائس کی معلومات اور ایپ ورژن صرف مسئلہ جانچنے کے لیے استعمال ہوتے ہیں۔'],
}
for k, v in NEW.items():
    assert len(v) == 21, k

def entry(ko):
    def q(t): return t.replace('\\', '\\\\').replace("'", "\\'")
    lines = ["  '%s': {" % q(ko)]
    for L, t in zip(LANGS, NEW[ko]):
        lines.append("    '%s': '%s'," % (L, q(t)))
    lines.append('  },')
    return '\n'.join(lines) + '\n'

def find(name):
    for root, dirs, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

ok = True
results = {}

def load(name):
    p = find(name)
    if not p:
        print('❌', name, '못 찾음 (프로젝트 폴더에서 실행해 주세요)'); return None, None, None
    raw = open(p, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    return p, raw.replace('\r\n', '\n'), crlf

def rep(s, label, old, new):
    global ok
    n = s.count(old)
    if n != 1:
        print('❌', label, '(찾은 개수 %d)' % n); ok = False; return s
    print('✔', label)
    return s.replace(old, new)

def remove_entry(s, ko, label):
    global ok
    m = re.search(r"\n  '%s': \{\n(?:    '[^\n]*\n)+?  \},\n" % re.escape(ko), s)
    if not m:
        print('❌', label); ok = False; return s
    print('✔', label)
    return s[:m.start() + 1] + s[m.end():]

def replace_entry(s, old_ko, new_ko, label):
    global ok
    m = re.search(r"\n  '%s': \{\n(?:    '[^\n]*\n)+?  \},\n" % re.escape(old_ko), s)
    if not m:
        print('❌', label); ok = False; return s
    print('✔', label)
    return s[:m.start() + 1] + entry(new_ko) + s[m.end():]

# ── feedback_screen.dart ──
fp, f, fcrlf = load('feedback_screen.dart')
mp, m, mcrlf = load('more_menu_sheet.dart')
if fp is None or mp is None:
    sys.exit(1)

if "'기능 제안'" in f and "'파란소리에 바라는 점을 들려주세요.'" in m:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

f = rep(f, '종류 2개 (오류 신고 · 기능 제안), 좋아요 삭제',
    "    ('bug', '오류', 'Bug'),\n    ('idea', '제안', 'Idea'),\n    ('like', '좋아요', 'Love it'),\n  ];",
    "    ('bug', '오류 신고', 'Report a bug'),\n    ('idea', '기능 제안', 'Suggest a feature'),\n  ];")
f = rep(f, '질문 문구',
    "fbText('어떤 이야기인가요?', 'What is it about?')",
    "fbText('어떤 의견을 보내시겠어요?', 'What would you like to send?')")
f = rep(f, '주석: 종류 2개', '// 종류 3개 (고른 것만 먹색)', '// 종류 2개 (고른 것만 먹색 · 가로 반반)')
f = rep(f, '글 칸 안내: 고른 종류에 따라 바뀜 (쓴 글은 그대로)',
    "decoration: deco(fbText('자유롭게 적어 주세요', 'Write anything you like')),",
    "decoration: deco(_kind == 'bug'\n"
    "                      ? fbText('어떤 문제가 발생했는지 알려주세요.', 'Tell us what went wrong.')\n"
    "                      : _kind == 'idea'\n"
    "                          ? fbText('파란소리에 바라는 기능을 알려주세요.', 'Tell us what feature you’d like in Paransori.')\n"
    "                          : fbText('의견을 자유롭게 남겨주세요.', 'Feel free to share your thoughts.')),")
f = rep(f, '사진 첨부',
    "fbText('사진 붙이기', 'Add photo')", "fbText('사진 첨부', 'Attach photo')")
f = rep(f, '주석: 사진 첨부', "'+ 사진 붙이기'", "'+ 사진 첨부'")
f = rep(f, '이메일 칸',
    "fbText('답장 받을 이메일 (선택)', 'Email for a reply (optional)')",
    "fbText('답변받을 이메일 (선택)', 'Email for a reply (optional)')")
f = rep(f, '아래 안내 문구',
    "fbText('폰 기종 · 앱 버전이 함께 전송돼요. 문제를 빨리 찾는 데만 써요.',\n"
    "                        'Your phone model and app version are sent too, only to help us find problems faster.'),",
    "fbText('기기 정보와 앱 버전은 문제 확인을 위해서만 사용돼요.',\n"
    "                        'Device info and app version are used only to check problems.'),")
# 번역표
f = replace_entry(f, '불편한 점이나 바라는 점', '파란소리에 바라는 점을 들려주세요.', '번역: 메뉴 설명')
f = replace_entry(f, '어떤 이야기인가요?', '어떤 의견을 보내시겠어요?', '번역: 질문 문구')
f = replace_entry(f, '오류', '오류 신고', '번역: 오류 신고')
f = replace_entry(f, '제안', '기능 제안', '번역: 기능 제안')
f = remove_entry(f, '좋아요', '번역: 좋아요 삭제')
f = replace_entry(f, '자유롭게 적어 주세요',
                  '의견을 자유롭게 남겨주세요.', '번역: 글 칸 기본 안내')
# 종류별 안내 2개는 기본 안내 바로 뒤에
anchor = "  '답장 받을 이메일 (선택)': {"
f = rep(f, '번역: 종류별 안내 2개 추가', anchor,
        entry('어떤 문제가 발생했는지 알려주세요.') + entry('파란소리에 바라는 기능을 알려주세요.') + anchor)
f = replace_entry(f, '답장 받을 이메일 (선택)', '답변받을 이메일 (선택)', '번역: 이메일 칸')
f = replace_entry(f, '폰 기종 · 앱 버전이 함께 전송돼요. 문제를 빨리 찾는 데만 써요.',
                  '기기 정보와 앱 버전은 문제 확인을 위해서만 사용돼요.', '번역: 아래 안내 문구')
f = replace_entry(f, '사진 붙이기', '사진 첨부', '번역: 사진 첨부')

# 남은 것 확인
for bad in ["'like'", "좋아요", "'오류'", "'제안'", '자유롭게 적어 주세요', '사진 붙이기', '답장 받을', '폰 기종', '어떤 이야기인가요']:
    if bad in f:
        print('❌ 예전 글자가 남아 있음:', bad); ok = False

# ── more_menu_sheet.dart ──
m = rep(m, '메뉴 설명 문구',
    "subtitle: fbText('불편한 점이나 바라는 점', 'Problems or ideas'),",
    "subtitle: fbText('파란소리에 바라는 점을 들려주세요.', 'Tell us what you’d like from Paransori.'),")

# 괄호 확인
def brackets(s, name):
    global ok
    t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", s)
    t = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', t)
    t = re.sub(r'//[^\n]*', '', t)
    for a, b in ('()', '[]', '{}'):
        if t.count(a) != t.count(b):
            print('❌ 괄호 안 맞음', name, a, t.count(a), t.count(b)); ok = False
brackets(f, 'feedback_screen.dart')
brackets(m, 'more_menu_sheet.dart')

if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)

for p, s, crlf in ((fp, f, fcrlf), (mp, m, mcrlf)):
    if crlf: s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))
    print('✔ 저장:', os.path.basename(p))
