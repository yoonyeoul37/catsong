# -*- coding: utf-8 -*-
# 개인정보처리방침 · 이용약관: 위젯 사진 · 안드로이드 오토 내용 추가 (22개 언어), 최종 수정 2026년 10월 22일
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행 — 두 파일을 저절로 찾음
# 개인정보처리방침 · 이용약관에 넣을 글 (22개 언어)
# photo: 처리하는 정보(기기 안) 새 줄
# sent / purpose: 외부 서비스 표 'Android Auto (Google)' 줄
# hist: 개정 이력
# aa: 이용약관 서비스 내용 새 줄
# safe / compat: 이용약관 책임의 한계 새 줄 2개
T = {
'ko': dict(
 photo='홈 화면 위젯에 쓰려고 이용자가 직접 고른 사진 (휴대폰 안에만 저장되며 회사 서버로 보내지 않습니다)',
 sent='차 화면에 보여 줄 방송·곡 목록, 지금 듣는 곡·방송 이름, 앨범 사진',
 purpose='차 화면에 목록과 재생 정보 표시, 차에서 음성으로 틀기 (Android Auto·Google 정책을 따름)',
 hist='홈 화면 위젯 사진 바꾸기, 안드로이드 오토(차 화면) 안내 추가',
 aa='안드로이드 오토(차 화면)에서 듣기',
 safe='운전 중에는 안전을 먼저 생각해 주세요. 화면 조작은 차를 안전한 곳에 세운 뒤에 하고, 교통 법규를 지켜 주세요.',
 compat='안드로이드 오토는 차량과 휴대폰에 따라 동작이 다를 수 있으며, 회사는 모든 차량과의 호환을 보장하지 않습니다.'),
'en': dict(
 photo='A photo you choose yourself for the home screen widget (stored only on your phone and never sent to the Company\'s servers)',
 sent='Station and song lists to show on the car screen, the name of the song or station now playing, album art',
 purpose='Showing lists and playback info on the car screen, playing by voice in the car (subject to Android Auto and Google policies)',
 hist='Added information on changing the home screen widget photo and on Android Auto (car screen)',
 aa='Listening in the car with Android Auto',
 safe='Please put safety first while driving. Operate the screen only after stopping in a safe place, and follow traffic laws.',
 compat='Android Auto may work differently depending on the car and phone, and the Company does not guarantee compatibility with every car.'),
'ja': dict(
 photo='ホーム画面ウィジェット用にご自身で選択した写真（スマートフォン内にのみ保存され、当社のサーバーには送信されません）',
 sent='車の画面に表示するラジオ局・曲の一覧、再生中の曲・ラジオ局の名前、アルバムアート',
 purpose='車の画面への一覧と再生情報の表示、車内での音声による再生（Android Auto・Google のポリシーに従います）',
 hist='ホーム画面ウィジェットの写真変更と Android Auto（車の画面）に関する説明を追加',
 aa='Android Auto（車の画面）で聴く',
 safe='運転中は安全を最優先してください。画面の操作は安全な場所に停車してから行い、交通法規を守ってください。',
 compat='Android Auto は車種やスマートフォンによって動作が異なる場合があり、当社はすべての車との互換性を保証しません。'),
'zh': dict(
 photo='您為主畫面小工具自行選擇的照片（僅儲存在您的手機中，不會傳送至本公司的伺服器）',
 sent='要在車用螢幕上顯示的電台與歌曲清單、正在播放的歌曲或電台名稱、專輯封面',
 purpose='在車用螢幕上顯示清單與播放資訊，以及在車上透過語音播放（依 Android Auto 與 Google 政策）',
 hist='新增更換主畫面小工具照片及 Android Auto（車用螢幕）說明',
 aa='透過 Android Auto（車用螢幕）收聽',
 safe='駕駛時請以安全為優先。請將車輛停在安全的地方後再操作螢幕，並遵守交通法規。',
 compat='Android Auto 的運作可能因車輛與手機而異，本公司不保證與所有車輛相容。'),
'vi': dict(
 photo='Ảnh bạn tự chọn cho tiện ích màn hình chính (chỉ lưu trên điện thoại của bạn và không gửi đến máy chủ của Công ty)',
 sent='Danh sách đài và bài hát hiển thị trên màn hình ô tô, tên bài hát hoặc đài đang phát, ảnh album',
 purpose='Hiển thị danh sách và thông tin phát trên màn hình ô tô, phát bằng giọng nói trong ô tô (theo chính sách của Android Auto và Google)',
 hist='Bổ sung thông tin về việc đổi ảnh tiện ích màn hình chính và Android Auto (màn hình ô tô)',
 aa='Nghe trên ô tô với Android Auto',
 safe='Khi lái xe, hãy đặt an toàn lên hàng đầu. Chỉ thao tác trên màn hình sau khi đã dừng xe ở nơi an toàn và tuân thủ luật giao thông.',
 compat='Android Auto có thể hoạt động khác nhau tùy theo xe và điện thoại, và Công ty không đảm bảo tương thích với mọi loại xe.'),
'hi': dict(
 photo='होम स्क्रीन विजेट के लिए आपके द्वारा स्वयं चुनी गई फ़ोटो (केवल आपके फ़ोन में सहेजी जाती है और कंपनी के सर्वर पर नहीं भेजी जाती)',
 sent='कार स्क्रीन पर दिखाने के लिए स्टेशन और गानों की सूची, अभी चल रहे गाने या स्टेशन का नाम, एल्बम आर्ट',
 purpose='कार स्क्रीन पर सूची और प्लेबैक जानकारी दिखाना, कार में आवाज़ से चलाना (Android Auto और Google की नीतियों के अनुसार)',
 hist='होम स्क्रीन विजेट की फ़ोटो बदलने और Android Auto (कार स्क्रीन) की जानकारी जोड़ी गई',
 aa='Android Auto के साथ कार में सुनना',
 safe='गाड़ी चलाते समय सुरक्षा को सबसे पहले रखें। स्क्रीन का उपयोग केवल सुरक्षित स्थान पर गाड़ी रोकने के बाद करें और यातायात नियमों का पालन करें।',
 compat='Android Auto कार और फ़ोन के अनुसार अलग तरह से काम कर सकता है, और कंपनी हर कार के साथ संगतता की गारंटी नहीं देती।'),
'id': dict(
 photo='Foto yang Anda pilih sendiri untuk widget layar utama (hanya disimpan di ponsel Anda dan tidak dikirim ke server Perusahaan)',
 sent='Daftar stasiun dan lagu untuk ditampilkan di layar mobil, nama lagu atau stasiun yang sedang diputar, sampul album',
 purpose='Menampilkan daftar dan info pemutaran di layar mobil, memutar dengan suara di dalam mobil (mengikuti kebijakan Android Auto dan Google)',
 hist='Menambahkan informasi tentang penggantian foto widget layar utama dan Android Auto (layar mobil)',
 aa='Mendengarkan di mobil dengan Android Auto',
 safe='Utamakan keselamatan saat mengemudi. Operasikan layar hanya setelah berhenti di tempat yang aman, dan patuhi peraturan lalu lintas.',
 compat='Android Auto dapat bekerja berbeda tergantung mobil dan ponsel, dan Perusahaan tidak menjamin kompatibilitas dengan semua mobil.'),
'th': dict(
 photo='รูปภาพที่คุณเลือกเองสำหรับวิดเจ็ตหน้าจอหลัก (เก็บไว้ในโทรศัพท์ของคุณเท่านั้นและไม่ส่งไปยังเซิร์ฟเวอร์ของบริษัท)',
 sent='รายการสถานีและเพลงที่จะแสดงบนหน้าจอรถยนต์ ชื่อเพลงหรือสถานีที่กำลังเล่น ภาพปกอัลบั้ม',
 purpose='แสดงรายการและข้อมูลการเล่นบนหน้าจอรถยนต์ และเล่นด้วยเสียงในรถยนต์ (เป็นไปตามนโยบายของ Android Auto และ Google)',
 hist='เพิ่มข้อมูลเกี่ยวกับการเปลี่ยนรูปภาพวิดเจ็ตหน้าจอหลักและ Android Auto (หน้าจอรถยนต์)',
 aa='ฟังในรถยนต์ด้วย Android Auto',
 safe='ขณะขับรถโปรดคำนึงถึงความปลอดภัยเป็นอันดับแรก ใช้งานหน้าจอหลังจากจอดรถในที่ปลอดภัยแล้วเท่านั้น และปฏิบัติตามกฎจราจร',
 compat='Android Auto อาจทำงานแตกต่างกันไปตามรถยนต์และโทรศัพท์ และบริษัทไม่รับประกันความเข้ากันได้กับรถยนต์ทุกรุ่น'),
'es': dict(
 photo='Una foto que eliges tú para el widget de la pantalla de inicio (se guarda solo en tu teléfono y nunca se envía a los servidores de la Empresa)',
 sent='Listas de emisoras y canciones para mostrar en la pantalla del coche, nombre de la canción o emisora en reproducción, carátula del álbum',
 purpose='Mostrar listas e información de reproducción en la pantalla del coche, reproducir por voz en el coche (sujeto a las políticas de Android Auto y Google)',
 hist='se añadió información sobre el cambio de foto del widget de la pantalla de inicio y Android Auto (pantalla del coche)',
 aa='Escuchar en el coche con Android Auto',
 safe='Mientras conduces, la seguridad es lo primero. Usa la pantalla solo después de detenerte en un lugar seguro y respeta las normas de tráfico.',
 compat='Android Auto puede funcionar de forma distinta según el coche y el teléfono, y la Empresa no garantiza la compatibilidad con todos los coches.'),
'pt': dict(
 photo='Uma foto que você mesmo escolhe para o widget da tela inicial (armazenada apenas no seu celular e nunca enviada aos servidores da Empresa)',
 sent='Listas de estações e músicas para exibir na tela do carro, nome da música ou estação em reprodução, capa do álbum',
 purpose='Exibir listas e informações de reprodução na tela do carro, tocar por voz no carro (sujeito às políticas do Android Auto e do Google)',
 hist='incluídas informações sobre a troca da foto do widget da tela inicial e o Android Auto (tela do carro)',
 aa='Ouvir no carro com o Android Auto',
 safe='Ao dirigir, a segurança vem em primeiro lugar. Use a tela somente depois de parar em um local seguro e respeite as leis de trânsito.',
 compat='O Android Auto pode funcionar de forma diferente dependendo do carro e do celular, e a Empresa não garante compatibilidade com todos os carros.'),
'de': dict(
 photo='Ein von Ihnen selbst gewähltes Foto für das Startbildschirm-Widget (wird nur auf Ihrem Handy gespeichert und nie an die Server des Unternehmens gesendet)',
 sent='Sender- und Songlisten für die Anzeige auf dem Autodisplay, Name des gerade laufenden Songs oder Senders, Albumcover',
 purpose='Anzeige von Listen und Wiedergabeinformationen auf dem Autodisplay, Wiedergabe per Sprachbefehl im Auto (gemäß den Richtlinien von Android Auto und Google)',
 hist='Informationen zum Ändern des Startbildschirm-Widget-Fotos und zu Android Auto (Autodisplay) ergänzt',
 aa='Hören im Auto mit Android Auto',
 safe='Beim Fahren hat Sicherheit Vorrang. Bedienen Sie das Display nur, nachdem Sie an einem sicheren Ort angehalten haben, und beachten Sie die Verkehrsregeln.',
 compat='Android Auto kann je nach Auto und Handy unterschiedlich funktionieren; das Unternehmen garantiert keine Kompatibilität mit allen Fahrzeugen.'),
'fr': dict(
 photo='Une photo que vous choisissez vous-même pour le widget de l’écran d’accueil (enregistrée uniquement sur votre téléphone et jamais envoyée aux serveurs de la Société)',
 sent='Listes de stations et de morceaux à afficher sur l’écran de la voiture, nom du morceau ou de la station en cours, pochette de l’album',
 purpose='Afficher les listes et les informations de lecture sur l’écran de la voiture, lancer la lecture à la voix en voiture (selon les règles d’Android Auto et de Google)',
 hist='ajout d’informations sur le changement de photo du widget de l’écran d’accueil et sur Android Auto (écran de la voiture)',
 aa='Écouter en voiture avec Android Auto',
 safe='Au volant, la sécurité passe avant tout. N’utilisez l’écran qu’après vous être arrêté dans un endroit sûr et respectez le code de la route.',
 compat='Android Auto peut fonctionner différemment selon la voiture et le téléphone, et la Société ne garantit pas la compatibilité avec tous les véhicules.'),
'ru': dict(
 photo='Фото, которое вы сами выбрали для виджета главного экрана (хранится только на вашем телефоне и не отправляется на серверы Компании)',
 sent='Списки станций и треков для экрана автомобиля, название звучащего трека или станции, обложка альбома',
 purpose='Показ списков и сведений о воспроизведении на экране автомобиля, включение голосом в машине (в соответствии с правилами Android Auto и Google)',
 hist='добавлены сведения о смене фото виджета главного экрана и об Android Auto (экран автомобиля)',
 aa='Прослушивание в автомобиле через Android Auto',
 safe='За рулём безопасность прежде всего. Пользуйтесь экраном только после остановки в безопасном месте и соблюдайте правила дорожного движения.',
 compat='Android Auto может работать по-разному в зависимости от автомобиля и телефона; Компания не гарантирует совместимость со всеми автомобилями.'),
'it': dict(
 photo='Una foto che scegli tu per il widget della schermata Home (salvata solo sul tuo telefono e mai inviata ai server della Società)',
 sent='Elenchi di stazioni e brani da mostrare sullo schermo dell’auto, nome del brano o della stazione in riproduzione, copertina dell’album',
 purpose='Mostrare elenchi e informazioni di riproduzione sullo schermo dell’auto, avviare la riproduzione con la voce in auto (secondo le norme di Android Auto e Google)',
 hist='aggiunte informazioni sulla modifica della foto del widget della schermata Home e su Android Auto (schermo dell’auto)',
 aa='Ascolto in auto con Android Auto',
 safe='Alla guida la sicurezza viene prima di tutto. Usa lo schermo solo dopo esserti fermato in un luogo sicuro e rispetta il codice della strada.',
 compat='Android Auto può funzionare in modo diverso a seconda dell’auto e del telefono e la Società non garantisce la compatibilità con tutte le auto.'),
'tr': dict(
 photo='Ana ekran widget’ı için kendi seçtiğiniz fotoğraf (yalnızca telefonunuzda saklanır ve Şirketin sunucularına gönderilmez)',
 sent='Araç ekranında gösterilecek istasyon ve şarkı listeleri, çalan şarkının veya istasyonun adı, albüm kapağı',
 purpose='Araç ekranında listeleri ve çalma bilgilerini gösterme, araçta sesle çalma (Android Auto ve Google politikalarına tabidir)',
 hist='Ana ekran widget’ı fotoğrafını değiştirme ve Android Auto (araç ekranı) ile ilgili bilgiler eklendi',
 aa='Android Auto ile araçta dinleme',
 safe='Sürüş sırasında önce güvenliği düşünün. Ekranı yalnızca güvenli bir yerde durduktan sonra kullanın ve trafik kurallarına uyun.',
 compat='Android Auto araca ve telefona göre farklı çalışabilir; Şirket tüm araçlarla uyumluluğu garanti etmez.'),
'pl': dict(
 photo='Zdjęcie wybrane przez Ciebie do widżetu na ekranie głównym (przechowywane tylko w telefonie i nigdy niewysyłane na serwery Spółki)',
 sent='Listy stacji i utworów do wyświetlenia na ekranie samochodu, nazwa odtwarzanego utworu lub stacji, okładka albumu',
 purpose='Wyświetlanie list i informacji o odtwarzaniu na ekranie samochodu, włączanie głosem w samochodzie (zgodnie z zasadami Android Auto i Google)',
 hist='dodano informacje o zmianie zdjęcia widżetu na ekranie głównym oraz o Android Auto (ekran samochodu)',
 aa='Słuchanie w samochodzie z Android Auto',
 safe='Podczas jazdy najważniejsze jest bezpieczeństwo. Korzystaj z ekranu dopiero po zatrzymaniu się w bezpiecznym miejscu i przestrzegaj przepisów ruchu drogowego.',
 compat='Android Auto może działać różnie w zależności od samochodu i telefonu, a Spółka nie gwarantuje zgodności ze wszystkimi samochodami.'),
'uk': dict(
 photo='Фото, яке ви самі вибрали для віджета головного екрана (зберігається лише на вашому телефоні й не надсилається на сервери Компанії)',
 sent='Списки станцій і треків для екрана автомобіля, назва треку або станції, що звучить, обкладинка альбому',
 purpose='Показ списків і відомостей про відтворення на екрані автомобіля, увімкнення голосом в авто (відповідно до правил Android Auto та Google)',
 hist='додано відомості про зміну фото віджета головного екрана та про Android Auto (екран автомобіля)',
 aa='Прослуховування в автомобілі через Android Auto',
 safe='За кермом безпека понад усе. Користуйтеся екраном лише після зупинки в безпечному місці та дотримуйтеся правил дорожнього руху.',
 compat='Android Auto може працювати по-різному залежно від автомобіля й телефона; Компанія не гарантує сумісності з усіма автомобілями.'),
'ro': dict(
 photo='O fotografie aleasă de tine pentru widgetul de pe ecranul de pornire (stocată doar pe telefonul tău și nu este trimisă niciodată pe serverele Companiei)',
 sent='Liste de posturi și melodii afișate pe ecranul mașinii, numele melodiei sau postului redat, coperta albumului',
 purpose='Afișarea listelor și a informațiilor de redare pe ecranul mașinii, redarea prin comandă vocală în mașină (conform politicilor Android Auto și Google)',
 hist='Au fost adăugate informații despre schimbarea fotografiei widgetului de pe ecranul de pornire și despre Android Auto (ecranul mașinii)',
 aa='Ascultare în mașină cu Android Auto',
 safe='La volan, siguranța este pe primul loc. Folosește ecranul doar după ce ai oprit într-un loc sigur și respectă regulile de circulație.',
 compat='Android Auto poate funcționa diferit în funcție de mașină și telefon, iar Compania nu garantează compatibilitatea cu toate mașinile.'),
'cs': dict(
 photo='Fotka, kterou si sami vyberete pro widget na domovské obrazovce (ukládá se pouze ve vašem telefonu a nikdy se neodesílá na servery Společnosti)',
 sent='Seznamy stanic a skladeb pro zobrazení na obrazovce auta, název právě hrající skladby nebo stanice, obal alba',
 purpose='Zobrazení seznamů a informací o přehrávání na obrazovce auta, spuštění hlasem v autě (podle zásad Android Auto a Google)',
 hist='Doplněny informace o změně fotky widgetu na domovské obrazovce a o Android Auto (obrazovka auta)',
 aa='Poslech v autě s Android Auto',
 safe='Při řízení má bezpečnost přednost. Obrazovku ovládejte až po zastavení na bezpečném místě a dodržujte dopravní předpisy.',
 compat='Android Auto může fungovat odlišně podle auta a telefonu a Společnost nezaručuje kompatibilitu se všemi vozy.'),
'hu': dict(
 photo='A kezdőképernyő-widgethez saját maga által választott fénykép (csak a telefonján tárolódik, és soha nem kerül a Társaság szervereire)',
 sent='Az autó kijelzőjén megjelenítendő állomás- és dallista, az éppen szóló dal vagy állomás neve, albumborító',
 purpose='Listák és lejátszási adatok megjelenítése az autó kijelzőjén, hangvezérelt lejátszás az autóban (az Android Auto és a Google szabályai szerint)',
 hist='Tájékoztatás a kezdőképernyő-widget fényképének cseréjéről és az Android Autóról (autó kijelzője)',
 aa='Hallgatás az autóban Android Autóval',
 safe='Vezetés közben a biztonság az első. A kijelzőt csak biztonságos helyen való megállás után kezelje, és tartsa be a közlekedési szabályokat.',
 compat='Az Android Auto autótól és telefontól függően eltérően működhet, és a Társaság nem garantálja a kompatibilitást minden autóval.'),
'ar': dict(
 photo='صورة تختارها بنفسك لأداة الشاشة الرئيسية (تُحفظ على هاتفك فقط ولا تُرسل أبدًا إلى خوادم الشركة)',
 sent='قوائم المحطات والأغاني لعرضها على شاشة السيارة، واسم الأغنية أو المحطة قيد التشغيل، وصورة الألبوم',
 purpose='عرض القوائم ومعلومات التشغيل على شاشة السيارة، والتشغيل بالصوت داخل السيارة (وفق سياسات Android Auto وGoogle)',
 hist='إضافة معلومات عن تغيير صورة أداة الشاشة الرئيسية وعن Android Auto (شاشة السيارة)',
 aa='الاستماع في السيارة باستخدام Android Auto',
 safe='أثناء القيادة، السلامة أولًا. لا تستخدم الشاشة إلا بعد التوقف في مكان آمن، والتزم بقواعد المرور.',
 compat='قد يعمل Android Auto بشكل مختلف بحسب السيارة والهاتف، ولا تضمن الشركة التوافق مع جميع السيارات.'),
'ur': dict(
 photo='ہوم اسکرین ویجیٹ کے لیے آپ کی خود منتخب کردہ تصویر (صرف آپ کے فون میں محفوظ ہوتی ہے اور کمپنی کے سرورز کو کبھی نہیں بھیجی جاتی)',
 sent='کار اسکرین پر دکھانے کے لیے اسٹیشنز اور گانوں کی فہرست، اس وقت چلنے والے گانے یا اسٹیشن کا نام، البم آرٹ',
 purpose='کار اسکرین پر فہرستیں اور پلے بیک کی معلومات دکھانا، کار میں آواز سے چلانا (Android Auto اور Google کی پالیسیوں کے مطابق)',
 hist='ہوم اسکرین ویجیٹ کی تصویر بدلنے اور Android Auto (کار اسکرین) کی معلومات شامل کی گئیں',
 aa='Android Auto کے ذریعے کار میں سننا',
 safe='گاڑی چلاتے وقت حفاظت کو سب سے پہلے رکھیں۔ اسکرین صرف کسی محفوظ جگہ رکنے کے بعد استعمال کریں اور ٹریفک قوانین کی پابندی کریں۔',
 compat='Android Auto کار اور فون کے لحاظ سے مختلف طریقے سے کام کر سکتا ہے، اور کمپنی ہر کار کے ساتھ مطابقت کی ضمانت نہیں دیتی۔'),
}

import os, re, sys

NEWDAY = '22'  # 최종 수정일: 2026년 10월 22일
MARK = 'Android Auto (Google)'
SKIP = {'.git', 'node_modules', 'build', '.dart_tool', '.gradle', '.idea'}


def find(name):
    hits = []
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in SKIP]
        if name in files:
            hits.append(os.path.join(root, name))
    return hits


def articles(s):
    """(언어, 시작, 끝) — <article ... data-lang="xx"> ~ </article>"""
    out = []
    for m in re.finditer(r'<article class="doc" data-lang="([a-z]+)"', s):
        e = s.find('</article>', m.start())
        out.append((m.group(1), m.start(), e))
    return out


def day(text, old):
    """날짜 글자에서 '일'만 바꾸기 (2026의 20은 건드리지 않음)"""
    n = re.subn(r'(?<!\d)%s(?!\d)' % old, NEWDAY, text, count=1)
    return n


def section(a, lang, sec):
    k = a.find('id="%s-%s"' % (lang, sec))
    if k < 0:
        return -1, -1
    return k, a.find('</section>', k)


def fix_privacy(a, L, t, err):
    # ① 처리하는 정보(기기 안) — 둘째 줄(직접 고른 사진) 다음에 새 줄
    k, e = section(a, L, 's1')
    ul = a.find('<ul>', k)
    li1 = a.find('</li>', ul)
    li2 = a.find('</li>', li1 + 5)
    if k < 0 or ul < 0 or li2 < 0 or li2 > e:
        err.append(L + ' 처리하는 정보'); return a
    p = li2 + 5
    a = a[:p] + '<li>%s</li>' % t['photo'] + a[p:]
    # ② 외부 서비스 표 — Google AdMob 칸 앞에 Android Auto 칸
    m = re.search(r'<div class="svc-i"><b>Google AdMob</b><div class="kv"><span>(.*?)</span><p>.*?</p><span>(.*?)</span>', a)
    if not m:
        err.append(L + ' 외부 서비스 표'); return a
    row = ('<div class="svc-i"><b>Android Auto (Google)</b><div class="kv"><span>%s</span><p>%s</p>'
           '<span>%s</span><p>%s</p></div></div>') % (m.group(1), t['sent'], m.group(2), t['purpose'])
    a = a[:m.start()] + row + a[m.start():]
    # ③ 최종 수정 날짜
    m = re.search(r'(<div class="meta"><span>.*?</span><span>)(.*?)(</span>)', a)
    new, n = day(m.group(2), '20') if m else ('', 0)
    if n != 1:
        err.append(L + ' 최종 수정 날짜'); return a
    a = a[:m.start(2)] + new + a[m.end(2):]
    # ④ 개정 이력 맨 위에 새 줄 (날짜 모양은 바로 아래 줄과 같게)
    k, e = section(a, L, 's10')
    ul = a.find('<ul>', k)
    m = re.match(r'<ul><li>(.*?)</li>', a[ul:])
    if k < 0 or ul < 0 or not m:
        err.append(L + ' 개정 이력'); return a
    first = m.group(1)
    d = re.search(r'(?<!\d)20(?!\d)', first)
    sep = re.search(r'\s?[:：]\s?', first[d.end():]) if d else None
    if not d or not sep:
        err.append(L + ' 개정 이력 날짜'); return a
    head = first[:d.end() + sep.end()]
    head, _ = day(head, '20')
    a = a[:ul + 4] + '<li>%s%s</li>' % (head, t['hist']) + a[ul + 4:]
    return a


def fix_terms(a, L, t, err):
    # ① 서비스 내용 — 맨 끝(홈 화면 위젯, 손전등) 다음에
    k, e = section(a, L, 's2')
    p = a.rfind('</ul>', k, e)
    if k < 0 or p < 0:
        err.append(L + ' 서비스 내용'); return a
    a = a[:p] + '<li>%s</li>' % t['aa'] + a[p:]
    # ② 책임의 한계 — 맨 끝에 두 줄
    k, e = section(a, L, 's10')
    p = a.rfind('</ul>', k, e)
    if k < 0 or p < 0:
        err.append(L + ' 책임의 한계'); return a
    a = a[:p] + '<li>%s</li><li>%s</li>' % (t['safe'], t['compat']) + a[p:]
    # ③ 최종 수정 날짜 (15일 → 22일)
    m = re.search(r'(<div class="meta"><span>.*?</span><span>)(.*?)(</span>)', a)
    new, n = day(m.group(2), '15') if m else ('', 0)
    if n != 1:
        err.append(L + ' 최종 수정 날짜'); return a
    a = a[:m.start(2)] + new + a[m.end(2):]
    return a


def run(name, fix):
    hits = find(name)
    if len(hits) != 1:
        print('❌ %s 파일을 %s' % (name, '못 찾았어요' if not hits else '여러 개 찾았어요: ' + ', '.join(hits)))
        return None
    path = hits[0]
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s or T['ko']['aa'] in s:
        return 'done'
    arts = articles(s)
    err = []
    langs = [x[0] for x in arts]
    miss = [L for L in T if L not in langs]
    extra = [L for L in langs if L not in T]
    if miss or extra:
        print('❌ %s 언어가 안 맞아요 (없음: %s / 번역 없음: %s)' % (name, miss, extra))
        return None
    # 뒤에서부터 고쳐야 앞 위치가 안 밀림
    for L, st, en in reversed(arts):
        a = fix(s[st:en], L, T[L], err)
        s = s[:st] + a + s[en:]
    if err:
        for x in err:
            print('❌ %s: %s 자리를 못 찾았어요' % (name, x))
        return None
    if s.count('<li>') != s.count('</li>') or s.count('<div') != s.count('</div>'):
        print('❌ %s 태그가 안 맞아요' % name)
        return None
    print('✔ %s (%d개 언어)' % (name, len(arts)))
    return path, (s.replace('\n', '\r\n') if crlf else s)


def main():
    a = run('privacy_policy.html', fix_privacy)
    b = run('terms_of_service.html', fix_terms)
    if a == 'done' and b == 'done':
        print('이미 적용돼 있어요')
        return
    if a is None or b is None or a == 'done' or b == 'done':
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for path, text in (a, b):
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
