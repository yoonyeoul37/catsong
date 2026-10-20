# -*- coding: utf-8 -*-
# 개인정보처리방침에 '의견 보내기' 안내 추가 (22개 언어)
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')
# (A 한눈에, B 처리하는 정보 줄, C 상자 끝 한 문장, D 서비스 이름, D2 보내는 정보, D3 목적, E 보관, F 개정 이력)
T = {
'ko': ["앱 안 '의견 보내기'로 보낸 글·사진과 (적은 경우) 이메일 주소는 답변과 앱 개선에만 사용합니다.",
       "의견 보내기: 이용자가 직접 쓴 글과 종류, 적은 경우 이메일 주소, 붙인 사진, 기기 모델·운영체제·앱 버전·앱 언어, 접속 국가 (4번 참고)",
       "앱 안 '의견 보내기'로 연락하는 경우도 같습니다.",
       "KNEXM 서버 (의견 보내기 · Cloudflare)",
       "의견 글과 종류, 이메일 주소(선택), 붙인 사진(선택), 기기 모델·운영체제·앱 버전·앱 언어, 접속 국가",
       "문의 답변, 오류 확인과 앱 개선. 붙인 사진은 서버에 저장하지 않고 담당자 이메일로만 전달됩니다.",
       "'의견 보내기'로 받은 글과 정보는 처리를 마친 뒤 최대 1년 동안 보관한 후 삭제하며, 사진이 첨부된 메일도 같습니다. 요청하면 더 일찍 삭제합니다.",
       "앱 안 '의견 보내기'(글·사진·이메일 선택) 안내 추가"],
'en': ["If you use “Send feedback” in the app, we use your message, any photos you attach and your email address (if you enter one) only to reply and to improve the app.",
       "Send feedback: the message and type you write, your email address if you enter one, photos you attach, device model, OS and app version, app language and country of access (see section 4)",
       "The same applies when you contact us through “Send feedback” in the app.",
       "KNEXM server (Send feedback · Cloudflare)",
       "Your message and its type, email address (optional), attached photos (optional), device model, OS and app version, app language, country of access",
       "Replying to inquiries, finding errors and improving the app. Attached photos are not stored on the server; they are only forwarded by email to the person in charge.",
       "Messages received through “Send feedback” are kept for up to one year after we handle them and then deleted, including emails with attached photos. We delete them sooner on request.",
       "Added information on in-app “Send feedback” (message, photos and optional email)"],
'ja': ["アプリ内の「ご意見を送る」で送られた文章・写真と（入力された場合）メールアドレスは、返信とアプリの改善のためにのみ使用します。",
       "ご意見を送る：利用者が入力した文章と種類、入力された場合のメールアドレス、添付された写真、端末のモデル・OS・アプリのバージョン・アプリの言語、接続国（4を参照）",
       "アプリ内の「ご意見を送る」からご連絡いただいた場合も同様です。",
       "KNEXM サーバー（ご意見を送る・Cloudflare）",
       "ご意見の文章と種類、メールアドレス（任意）、添付写真（任意）、端末のモデル・OS・アプリのバージョン・アプリの言語、接続国",
       "お問い合わせへの返信、不具合の確認とアプリの改善。添付写真はサーバーに保存せず、担当者のメールにのみ転送されます。",
       "「ご意見を送る」で受け取った文章と情報は、対応完了後最長1年間保管したのち削除します。写真が添付されたメールも同様です。ご要望があれば早めに削除します。",
       "アプリ内「ご意見を送る」（文章・写真・任意のメール）に関する説明を追加"],
'zh': ["透過應用程式內「傳送意見」寄出的文字、照片及（如有填寫）電子郵件地址，僅用於回覆與改善應用程式。",
       "傳送意見：使用者撰寫的內容與類型、如有填寫的電子郵件地址、附加的照片、裝置型號、作業系統與應用程式版本、應用程式語言、連線國家（參見第 4 條）",
       "透過應用程式內「傳送意見」聯絡時亦同。",
       "KNEXM 伺服器（傳送意見・Cloudflare）",
       "意見內容與類型、電子郵件地址（選填）、附加照片（選填）、裝置型號、作業系統與應用程式版本、應用程式語言、連線國家",
       "回覆詢問、確認錯誤與改善應用程式。附加照片不會儲存在伺服器上，只會以電子郵件轉寄給負責人。",
       "透過「傳送意見」收到的內容與資訊，於處理完畢後最多保存 1 年再刪除，附有照片的郵件亦同。如有要求，將提前刪除。",
       "新增應用程式內「傳送意見」（文字、照片、選填電子郵件）說明"],
'vi': ["Nội dung, ảnh và địa chỉ email (nếu bạn nhập) gửi qua “Gửi góp ý” trong ứng dụng chỉ được dùng để trả lời và cải thiện ứng dụng.",
       "Gửi góp ý: nội dung và loại góp ý bạn viết, địa chỉ email nếu bạn nhập, ảnh đính kèm, kiểu máy, phiên bản hệ điều hành và ứng dụng, ngôn ngữ ứng dụng, quốc gia truy cập (xem mục 4)",
       "Điều này cũng áp dụng khi bạn liên hệ qua “Gửi góp ý” trong ứng dụng.",
       "Máy chủ KNEXM (Gửi góp ý · Cloudflare)",
       "Nội dung và loại góp ý, địa chỉ email (tùy chọn), ảnh đính kèm (tùy chọn), kiểu máy, phiên bản hệ điều hành và ứng dụng, ngôn ngữ ứng dụng, quốc gia truy cập",
       "Trả lời liên hệ, tìm lỗi và cải thiện ứng dụng. Ảnh đính kèm không được lưu trên máy chủ mà chỉ được chuyển qua email cho người phụ trách.",
       "Nội dung nhận qua “Gửi góp ý” được lưu tối đa 1 năm sau khi xử lý rồi xóa, kể cả email có ảnh đính kèm. Chúng tôi sẽ xóa sớm hơn nếu bạn yêu cầu.",
       "Bổ sung thông tin về “Gửi góp ý” trong ứng dụng (nội dung, ảnh, email tùy chọn)"],
'hi': ["ऐप में “प्रतिक्रिया भेजें” से भेजा गया संदेश, फ़ोटो और (यदि आप दें) ईमेल पता केवल जवाब देने और ऐप को बेहतर बनाने के लिए उपयोग किया जाता है।",
       "प्रतिक्रिया भेजें: आपके द्वारा लिखा संदेश और उसका प्रकार, यदि दिया हो तो ईमेल पता, जोड़ी गई फ़ोटो, डिवाइस मॉडल, ऑपरेटिंग सिस्टम और ऐप वर्ज़न, ऐप की भाषा, एक्सेस का देश (धारा 4 देखें)",
       "ऐप में “प्रतिक्रिया भेजें” से संपर्क करने पर भी यही लागू होता है।",
       "KNEXM सर्वर (प्रतिक्रिया भेजें · Cloudflare)",
       "संदेश और उसका प्रकार, ईमेल पता (वैकल्पिक), जोड़ी गई फ़ोटो (वैकल्पिक), डिवाइस मॉडल, ऑपरेटिंग सिस्टम और ऐप वर्ज़न, ऐप की भाषा, एक्सेस का देश",
       "पूछताछ का जवाब देना, त्रुटियाँ ढूंढना और ऐप को बेहतर बनाना। जोड़ी गई फ़ोटो सर्वर पर सहेजी नहीं जातीं, केवल ईमेल से ज़िम्मेदार व्यक्ति को भेजी जाती हैं।",
       "“प्रतिक्रिया भेजें” से मिले संदेश निपटाने के बाद अधिकतम 1 वर्ष तक रखे जाते हैं और फिर हटा दिए जाते हैं; फ़ोटो वाले ईमेल भी। अनुरोध करने पर हम इन्हें पहले हटा देते हैं।",
       "ऐप में “प्रतिक्रिया भेजें” (संदेश, फ़ोटो, वैकल्पिक ईमेल) की जानकारी जोड़ी गई"],
'id': ["Pesan, foto, dan alamat email (jika diisi) yang dikirim lewat “Kirim masukan” di aplikasi hanya digunakan untuk membalas dan meningkatkan aplikasi.",
       "Kirim masukan: pesan dan jenis yang Anda tulis, alamat email jika diisi, foto yang dilampirkan, model perangkat, versi sistem operasi dan aplikasi, bahasa aplikasi, negara akses (lihat bagian 4)",
       "Hal yang sama berlaku jika Anda menghubungi kami lewat “Kirim masukan” di aplikasi.",
       "Server KNEXM (Kirim masukan · Cloudflare)",
       "Pesan dan jenisnya, alamat email (opsional), foto lampiran (opsional), model perangkat, versi sistem operasi dan aplikasi, bahasa aplikasi, negara akses",
       "Membalas pertanyaan, menemukan kesalahan, dan meningkatkan aplikasi. Foto lampiran tidak disimpan di server dan hanya diteruskan melalui email kepada penanggung jawab.",
       "Pesan yang diterima lewat “Kirim masukan” disimpan paling lama 1 tahun setelah ditangani lalu dihapus, termasuk email berisi foto. Kami menghapusnya lebih awal jika diminta.",
       "Menambahkan informasi tentang “Kirim masukan” di aplikasi (pesan, foto, email opsional)"],
'th': ["ข้อความ รูปภาพ และอีเมล (หากกรอก) ที่ส่งผ่าน “ส่งความคิดเห็น” ในแอป จะใช้เพื่อตอบกลับและปรับปรุงแอปเท่านั้น",
       "ส่งความคิดเห็น: ข้อความและประเภทที่คุณเขียน อีเมลหากกรอก รูปภาพที่แนบ รุ่นอุปกรณ์ เวอร์ชันระบบปฏิบัติการและแอป ภาษาของแอป ประเทศที่เชื่อมต่อ (ดูข้อ 4)",
       "กรณีติดต่อผ่าน “ส่งความคิดเห็น” ในแอปก็เช่นเดียวกัน",
       "เซิร์ฟเวอร์ KNEXM (ส่งความคิดเห็น · Cloudflare)",
       "ข้อความและประเภท อีเมล (ไม่บังคับ) รูปภาพที่แนบ (ไม่บังคับ) รุ่นอุปกรณ์ เวอร์ชันระบบปฏิบัติการและแอป ภาษาของแอป ประเทศที่เชื่อมต่อ",
       "ตอบคำถาม ตรวจหาข้อผิดพลาด และปรับปรุงแอป รูปภาพที่แนบจะไม่ถูกเก็บไว้บนเซิร์ฟเวอร์ แต่จะส่งต่อทางอีเมลถึงผู้รับผิดชอบเท่านั้น",
       "ข้อความที่ได้รับผ่าน “ส่งความคิดเห็น” จะเก็บไว้ไม่เกิน 1 ปีหลังดำเนินการเสร็จแล้วจึงลบ รวมถึงอีเมลที่แนบรูปภาพด้วย หากร้องขอ เราจะลบให้เร็วกว่านั้น",
       "เพิ่มข้อมูลเกี่ยวกับ “ส่งความคิดเห็น” ในแอป (ข้อความ รูปภาพ อีเมลแบบไม่บังคับ)"],
'es': ["Si usa “Enviar comentarios” en la app, usamos su mensaje, las fotos que adjunte y su correo (si lo indica) solo para responderle y mejorar la app.",
       "Enviar comentarios: el mensaje y el tipo que escriba, su correo si lo indica, las fotos que adjunte, modelo del dispositivo, versión del sistema y de la app, idioma de la app y país de acceso (véase la sección 4)",
       "Lo mismo se aplica si nos contacta mediante “Enviar comentarios” en la app.",
       "Servidor de KNEXM (Enviar comentarios · Cloudflare)",
       "Mensaje y tipo, correo electrónico (opcional), fotos adjuntas (opcional), modelo del dispositivo, versión del sistema y de la app, idioma de la app, país de acceso",
       "Responder consultas, detectar errores y mejorar la app. Las fotos adjuntas no se guardan en el servidor; solo se reenvían por correo a la persona responsable.",
       "Los mensajes recibidos mediante “Enviar comentarios” se conservan hasta un año después de atenderlos y luego se eliminan, incluidos los correos con fotos. Si lo solicita, los eliminamos antes.",
       "se añadió información sobre “Enviar comentarios” en la app (mensaje, fotos y correo opcional)"],
'pt': ["Se você usar “Enviar feedback” no app, usamos sua mensagem, as fotos anexadas e seu e-mail (se informado) apenas para responder e melhorar o app.",
       "Enviar feedback: a mensagem e o tipo que você escrever, seu e-mail se informado, fotos anexadas, modelo do aparelho, versão do sistema e do app, idioma do app e país de acesso (veja a seção 4)",
       "O mesmo vale quando você nos contata por “Enviar feedback” no app.",
       "Servidor da KNEXM (Enviar feedback · Cloudflare)",
       "Mensagem e tipo, e-mail (opcional), fotos anexadas (opcional), modelo do aparelho, versão do sistema e do app, idioma do app, país de acesso",
       "Responder contatos, encontrar erros e melhorar o app. As fotos anexadas não ficam salvas no servidor; são apenas encaminhadas por e-mail ao responsável.",
       "As mensagens recebidas por “Enviar feedback” ficam guardadas por até 1 ano após o atendimento e depois são excluídas, inclusive e-mails com fotos. Se você pedir, excluímos antes.",
       "incluídas informações sobre “Enviar feedback” no app (mensagem, fotos e e-mail opcional)"],
'de': ["Wenn Sie in der App „Feedback senden“ nutzen, verwenden wir Ihre Nachricht, angehängte Fotos und Ihre E-Mail-Adresse (falls angegeben) nur zur Antwort und zur Verbesserung der App.",
       "Feedback senden: Ihre Nachricht und deren Art, Ihre E-Mail-Adresse (falls angegeben), angehängte Fotos, Gerätemodell, Betriebssystem- und App-Version, App-Sprache, Land des Zugriffs (siehe Abschnitt 4)",
       "Dasselbe gilt, wenn Sie uns über „Feedback senden“ in der App kontaktieren.",
       "KNEXM-Server (Feedback senden · Cloudflare)",
       "Nachricht und Art, E-Mail-Adresse (optional), angehängte Fotos (optional), Gerätemodell, Betriebssystem- und App-Version, App-Sprache, Land des Zugriffs",
       "Beantwortung von Anfragen, Fehlersuche und Verbesserung der App. Angehängte Fotos werden nicht auf dem Server gespeichert, sondern nur per E-Mail an die zuständige Person weitergeleitet.",
       "Über „Feedback senden“ erhaltene Nachrichten werden nach der Bearbeitung höchstens 1 Jahr aufbewahrt und dann gelöscht; das gilt auch für E-Mails mit Fotos. Auf Wunsch löschen wir sie früher.",
       "Informationen zu „Feedback senden“ in der App (Nachricht, Fotos, optionale E-Mail) ergänzt"],
'fr': ["Si vous utilisez « Envoyer un avis » dans l’app, nous utilisons votre message, les photos jointes et votre adresse e-mail (si vous l’indiquez) uniquement pour vous répondre et améliorer l’app.",
       "Envoyer un avis : le message et le type que vous saisissez, votre adresse e-mail si vous l’indiquez, les photos jointes, le modèle de l’appareil, les versions du système et de l’app, la langue de l’app et le pays d’accès (voir section 4)",
       "Il en va de même lorsque vous nous contactez via « Envoyer un avis » dans l’app.",
       "Serveur KNEXM (Envoyer un avis · Cloudflare)",
       "Message et type, adresse e-mail (facultative), photos jointes (facultatives), modèle de l’appareil, versions du système et de l’app, langue de l’app, pays d’accès",
       "Répondre aux demandes, trouver les erreurs et améliorer l’app. Les photos jointes ne sont pas conservées sur le serveur ; elles sont seulement transmises par e-mail à la personne responsable.",
       "Les messages reçus via « Envoyer un avis » sont conservés au maximum 1 an après leur traitement, puis supprimés, y compris les e-mails contenant des photos. Sur demande, nous les supprimons plus tôt.",
       "ajout d’informations sur « Envoyer un avis » dans l’app (message, photos, e-mail facultatif)"],
'ru': ["Если вы пользуетесь функцией «Отправить отзыв» в приложении, мы используем ваше сообщение, прикреплённые фото и адрес электронной почты (если вы его укажете) только для ответа и улучшения приложения.",
       "Отправить отзыв: ваше сообщение и его тип, адрес электронной почты (если указан), прикреплённые фото, модель устройства, версии ОС и приложения, язык приложения, страна подключения (см. раздел 4)",
       "То же относится к обращениям через «Отправить отзыв» в приложении.",
       "Сервер KNEXM («Отправить отзыв» · Cloudflare)",
       "Сообщение и его тип, адрес электронной почты (по желанию), прикреплённые фото (по желанию), модель устройства, версии ОС и приложения, язык приложения, страна подключения",
       "Ответы на обращения, поиск ошибок и улучшение приложения. Прикреплённые фото не хранятся на сервере, а только пересылаются по электронной почте ответственному сотруднику.",
       "Сообщения, полученные через «Отправить отзыв», хранятся не более 1 года после обработки и затем удаляются, включая письма с фото. По запросу мы удалим их раньше.",
       "добавлены сведения о функции «Отправить отзыв» в приложении (сообщение, фото, адрес почты по желанию)"],
'it': ["Se usa “Invia feedback” nell’app, utilizziamo il suo messaggio, le foto allegate e il suo indirizzo e-mail (se indicato) solo per rispondere e migliorare l’app.",
       "Invia feedback: il messaggio e il tipo che scrive, l’indirizzo e-mail se indicato, le foto allegate, modello del dispositivo, versione del sistema e dell’app, lingua dell’app e paese di accesso (vedi sezione 4)",
       "Lo stesso vale se ci contatta tramite “Invia feedback” nell’app.",
       "Server KNEXM (Invia feedback · Cloudflare)",
       "Messaggio e tipo, indirizzo e-mail (facoltativo), foto allegate (facoltative), modello del dispositivo, versione del sistema e dell’app, lingua dell’app, paese di accesso",
       "Rispondere alle richieste, trovare errori e migliorare l’app. Le foto allegate non vengono salvate sul server, ma solo inoltrate via e-mail al responsabile.",
       "I messaggi ricevuti tramite “Invia feedback” sono conservati al massimo 1 anno dopo la gestione e poi eliminati, comprese le e-mail con foto. Su richiesta, li eliminiamo prima.",
       "aggiunte informazioni su “Invia feedback” nell’app (messaggio, foto, e-mail facoltativa)"],
'tr': ["Uygulamadaki “Geri bildirim gönder” ile gönderdiğiniz mesaj, fotoğraflar ve (girdiyseniz) e-posta adresiniz yalnızca yanıt vermek ve uygulamayı geliştirmek için kullanılır.",
       "Geri bildirim gönder: yazdığınız mesaj ve türü, girdiyseniz e-posta adresiniz, eklediğiniz fotoğraflar, cihaz modeli, işletim sistemi ve uygulama sürümü, uygulama dili, erişim ülkesi (bkz. bölüm 4)",
       "Uygulamadaki “Geri bildirim gönder” ile bize ulaştığınızda da aynısı geçerlidir.",
       "KNEXM sunucusu (Geri bildirim gönder · Cloudflare)",
       "Mesaj ve türü, e-posta adresi (isteğe bağlı), eklenen fotoğraflar (isteğe bağlı), cihaz modeli, işletim sistemi ve uygulama sürümü, uygulama dili, erişim ülkesi",
       "Sorulara yanıt vermek, hataları bulmak ve uygulamayı geliştirmek. Eklenen fotoğraflar sunucuda saklanmaz; yalnızca e-postayla sorumlu kişiye iletilir.",
       "“Geri bildirim gönder” ile alınan mesajlar işlem tamamlandıktan sonra en fazla 1 yıl saklanır ve ardından silinir; fotoğraflı e-postalar da buna dahildir. Talep ederseniz daha erken sileriz.",
       "Uygulamadaki “Geri bildirim gönder” (mesaj, fotoğraf, isteğe bağlı e-posta) hakkında bilgi eklendi"],
'pl': ["Jeśli korzystasz z funkcji „Wyślij opinię” w aplikacji, Twoją wiadomość, załączone zdjęcia i adres e-mail (jeśli go podasz) wykorzystujemy wyłącznie do odpowiedzi i ulepszania aplikacji.",
       "Wyślij opinię: napisana przez Ciebie wiadomość i jej rodzaj, adres e-mail (jeśli go podasz), załączone zdjęcia, model urządzenia, wersja systemu i aplikacji, język aplikacji, kraj połączenia (zob. punkt 4)",
       "To samo dotyczy kontaktu przez „Wyślij opinię” w aplikacji.",
       "Serwer KNEXM („Wyślij opinię” · Cloudflare)",
       "Wiadomość i jej rodzaj, adres e-mail (opcjonalnie), załączone zdjęcia (opcjonalnie), model urządzenia, wersja systemu i aplikacji, język aplikacji, kraj połączenia",
       "Odpowiadanie na zapytania, wyszukiwanie błędów i ulepszanie aplikacji. Załączone zdjęcia nie są przechowywane na serwerze, a jedynie przekazywane e-mailem osobie odpowiedzialnej.",
       "Wiadomości otrzymane przez „Wyślij opinię” przechowujemy maksymalnie 1 rok po ich rozpatrzeniu, a następnie usuwamy, w tym e-maile ze zdjęciami. Na prośbę usuniemy je wcześniej.",
       "dodano informacje o funkcji „Wyślij opinię” w aplikacji (wiadomość, zdjęcia, opcjonalny e-mail)"],
'uk': ["Якщо ви користуєтеся функцією «Надіслати відгук» у застосунку, ми використовуємо ваше повідомлення, прикріплені фото та адресу електронної пошти (якщо ви її вкажете) лише для відповіді та вдосконалення застосунку.",
       "Надіслати відгук: ваше повідомлення та його тип, адреса електронної пошти (якщо вказана), прикріплені фото, модель пристрою, версії ОС і застосунку, мова застосунку, країна підключення (див. розділ 4)",
       "Те саме стосується звернень через «Надіслати відгук» у застосунку.",
       "Сервер KNEXM («Надіслати відгук» · Cloudflare)",
       "Повідомлення та його тип, адреса електронної пошти (за бажанням), прикріплені фото (за бажанням), модель пристрою, версії ОС і застосунку, мова застосунку, країна підключення",
       "Відповіді на звернення, пошук помилок і вдосконалення застосунку. Прикріплені фото не зберігаються на сервері, а лише пересилаються електронною поштою відповідальній особі.",
       "Повідомлення, отримані через «Надіслати відгук», зберігаються не довше 1 року після опрацювання, а потім видаляються, зокрема листи з фото. На запит ми видалимо їх раніше.",
       "додано відомості про функцію «Надіслати відгук» у застосунку (повідомлення, фото, адреса пошти за бажанням)"],
'ro': ["Dacă folosiți „Trimite feedback” în aplicație, folosim mesajul, fotografiile atașate și adresa dumneavoastră de e-mail (dacă o introduceți) doar pentru a vă răspunde și a îmbunătăți aplicația.",
       "Trimite feedback: mesajul și tipul scris de dumneavoastră, adresa de e-mail dacă o introduceți, fotografiile atașate, modelul dispozitivului, versiunea sistemului și a aplicației, limba aplicației, țara de acces (vezi secțiunea 4)",
       "Același lucru este valabil când ne contactați prin „Trimite feedback” în aplicație.",
       "Serverul KNEXM („Trimite feedback” · Cloudflare)",
       "Mesajul și tipul, adresa de e-mail (opțional), fotografiile atașate (opțional), modelul dispozitivului, versiunea sistemului și a aplicației, limba aplicației, țara de acces",
       "Răspunsuri la solicitări, găsirea erorilor și îmbunătățirea aplicației. Fotografiile atașate nu sunt stocate pe server, ci doar transmise prin e-mail persoanei responsabile.",
       "Mesajele primite prin „Trimite feedback” sunt păstrate cel mult 1 an după soluționare și apoi șterse, inclusiv e-mailurile cu fotografii. La cerere, le ștergem mai devreme.",
       "Au fost adăugate informații despre „Trimite feedback” în aplicație (mesaj, fotografii, e-mail opțional)"],
'cs': ["Pokud v aplikaci použijete „Odeslat zpětnou vazbu“, vaši zprávu, přiložené fotky a e-mailovou adresu (pokud ji uvedete) použijeme pouze k odpovědi a zlepšení aplikace.",
       "Odeslat zpětnou vazbu: vámi napsaná zpráva a její typ, e-mailová adresa (pokud ji uvedete), přiložené fotky, model zařízení, verze systému a aplikace, jazyk aplikace, země připojení (viz oddíl 4)",
       "Totéž platí, pokud nás kontaktujete přes „Odeslat zpětnou vazbu“ v aplikaci.",
       "Server KNEXM („Odeslat zpětnou vazbu“ · Cloudflare)",
       "Zpráva a její typ, e-mailová adresa (nepovinné), přiložené fotky (nepovinné), model zařízení, verze systému a aplikace, jazyk aplikace, země připojení",
       "Odpovědi na dotazy, hledání chyb a zlepšování aplikace. Přiložené fotky se na serveru neukládají, pouze se e-mailem přeposílají odpovědné osobě.",
       "Zprávy přijaté přes „Odeslat zpětnou vazbu“ uchováváme nejdéle 1 rok po vyřízení a poté je mažeme, včetně e-mailů s fotkami. Na požádání je smažeme dříve.",
       "Doplněny informace o funkci „Odeslat zpětnou vazbu“ v aplikaci (zpráva, fotky, nepovinný e-mail)"],
'hu': ["Ha az alkalmazásban a „Visszajelzés küldése” funkciót használja, üzenetét, a csatolt fotókat és e-mail-címét (ha megadja) kizárólag a válaszadáshoz és az alkalmazás fejlesztéséhez használjuk fel.",
       "Visszajelzés küldése: az Ön által írt üzenet és típusa, e-mail-cím (ha megadja), csatolt fotók, készüléktípus, rendszer- és alkalmazásverzió, az alkalmazás nyelve, a csatlakozás országa (lásd a 4. pontot)",
       "Ugyanez érvényes, ha az alkalmazás „Visszajelzés küldése” funkcióján keresztül keres meg minket.",
       "KNEXM-szerver („Visszajelzés küldése” · Cloudflare)",
       "Üzenet és típusa, e-mail-cím (nem kötelező), csatolt fotók (nem kötelező), készüléktípus, rendszer- és alkalmazásverzió, az alkalmazás nyelve, a csatlakozás országa",
       "Válaszadás a megkeresésekre, hibák felderítése és az alkalmazás fejlesztése. A csatolt fotókat nem tároljuk a szerveren, csak e-mailben továbbítjuk a felelős személynek.",
       "A „Visszajelzés küldése” funkción keresztül érkezett üzeneteket a feldolgozás után legfeljebb 1 évig őrizzük meg, majd töröljük, beleértve a fotókat tartalmazó e-maileket is. Kérésre korábban töröljük őket.",
       "Tájékoztatás az alkalmazás „Visszajelzés küldése” funkciójáról (üzenet, fotók, nem kötelező e-mail)"],
'ar': ["عند استخدام «إرسال ملاحظات» في التطبيق، نستخدم رسالتك والصور المرفقة وعنوان بريدك الإلكتروني (إن أدخلته) للرد عليك وتحسين التطبيق فقط.",
       "إرسال ملاحظات: الرسالة التي تكتبها ونوعها، وعنوان بريدك الإلكتروني إن أدخلته، والصور المرفقة، وطراز الجهاز، وإصدار النظام والتطبيق، ولغة التطبيق، وبلد الاتصال (انظر القسم 4)",
       "وينطبق الأمر نفسه عند التواصل معنا عبر «إرسال ملاحظات» في التطبيق.",
       "خادم KNEXM (إرسال ملاحظات · Cloudflare)",
       "الرسالة ونوعها، والبريد الإلكتروني (اختياري)، والصور المرفقة (اختياري)، وطراز الجهاز، وإصدار النظام والتطبيق، ولغة التطبيق، وبلد الاتصال",
       "الرد على الاستفسارات، واكتشاف الأخطاء، وتحسين التطبيق. لا تُحفظ الصور المرفقة على الخادم، بل تُرسل فقط عبر البريد الإلكتروني إلى الشخص المسؤول.",
       "تُحفظ الرسائل الواردة عبر «إرسال ملاحظات» مدة أقصاها سنة واحدة بعد معالجتها ثم تُحذف، بما في ذلك الرسائل التي تحتوي على صور. ونحذفها في وقت أبكر عند الطلب.",
       "إضافة معلومات عن ميزة «إرسال ملاحظات» في التطبيق (الرسالة والصور والبريد الإلكتروني الاختياري)"],
'ur': ["ایپ میں “رائے بھیجیں” کے ذریعے بھیجا گیا پیغام، تصاویر اور (اگر آپ درج کریں) ای میل پتہ صرف جواب دینے اور ایپ بہتر بنانے کے لیے استعمال ہوتا ہے۔",
       "رائے بھیجیں: آپ کا لکھا ہوا پیغام اور اس کی قسم، اگر درج کیا ہو تو ای میل پتہ، منسلک تصاویر، ڈیوائس ماڈل، آپریٹنگ سسٹم اور ایپ ورژن، ایپ کی زبان، رسائی کا ملک (سیکشن 4 دیکھیں)",
       "ایپ میں “رائے بھیجیں” کے ذریعے رابطہ کرنے پر بھی یہی لاگو ہوتا ہے۔",
       "KNEXM سرور (رائے بھیجیں · Cloudflare)",
       "پیغام اور اس کی قسم، ای میل پتہ (اختیاری)، منسلک تصاویر (اختیاری)، ڈیوائس ماڈل، آپریٹنگ سسٹم اور ایپ ورژن، ایپ کی زبان، رسائی کا ملک",
       "سوالات کا جواب دینا، خرابیاں تلاش کرنا اور ایپ کو بہتر بنانا۔ منسلک تصاویر سرور پر محفوظ نہیں کی جاتیں، صرف ای میل کے ذریعے ذمہ دار شخص کو بھیجی جاتی ہیں۔",
       "“رائے بھیجیں” سے موصول ہونے والے پیغامات کارروائی کے بعد زیادہ سے زیادہ 1 سال تک رکھے جاتے ہیں اور پھر حذف کر دیے جاتے ہیں، تصاویر والی ای میلز سمیت۔ درخواست پر ہم انہیں پہلے حذف کر دیتے ہیں۔",
       "ایپ میں “رائے بھیجیں” (پیغام، تصاویر، اختیاری ای میل) کی معلومات شامل کی گئیں"],
}


def find_target():
    if len(sys.argv) > 1:
        return sys.argv[1]
    if os.path.isfile('privacy_policy.html'):
        return 'privacy_policy.html'
    hits = []
    skip = {'node_modules', 'build', '.dart_tool', '.git', 'android', 'ios', '.gradle'}
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in skip and root.count(os.sep) < 4]
        if 'privacy_policy.html' in files:
            hits.append(os.path.join(root, 'privacy_policy.html'))
    if len(hits) == 1:
        return hits[0]
    print('❌ privacy_policy.html 위치를 못 정했어요:', hits or '없음')
    sys.exit(1)


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def patch(b, L):
    A, B, C, D, D2, D3, E_, F = [esc(x) for x in T[L]]
    out = []
    if D in b:
        return b, ['이미 적용됨']
    # 0) 최종 수정 날짜 19 → 20
    m = re.search(r'(<div class="meta"><span>.*?</span><span>)(.*?)(</span>)', b)
    if not m or '19' not in m.group(2):
        raise Exception('meta 날짜')
    b = b[:m.start(2)] + m.group(2).replace('19', '20', 1) + b[m.end(2):]
    out.append('날짜')
    # 1) 한눈에 보기 마지막에 한 줄
    i = b.find('<section class="sum">'); j = b.find('</ul></section>', i)
    if i < 0 or j < 0: raise Exception('sum')
    b = b[:j] + '<li>' + A + '</li>' + b[j:]
    out.append('한눈에')
    # 2) 01: 외부 서비스에 전달되는 정보(두 번째 목록) 끝 + 상자 끝 문장
    i = b.find('id="%s-s1"' % L); k = b.find('</section>', i)
    u1 = b.find('</ul>', i); u2 = b.find('</ul>', u1 + 5)
    if not (i < u1 < u2 < k): raise Exception('s1 목록')
    b = b[:u2] + '<li>' + B + '</li>' + b[u2:]
    k = b.find('</section>', i)
    bx = b.rfind('</div>', i, k)
    if b.rfind('<div class="box">', i, k) < 0 or bx < 0: raise Exception('s1 상자')
    sp = '' if L in ('ja', 'zh') else ' '
    b = b[:bx] + sp + C + b[bx:]
    out.append('01')
    # 3) 04: 서비스 목록 끝에 새 항목
    i = b.find('id="%s-s4"' % L); k = b.find('</section>', i)
    j = b.find('</div></div></div><div class="box">', i)
    if not (i < j < k): raise Exception('s4')
    j += len('</div></div>')
    m4 = re.search(r'<div class="svc-i"><b>[^<]*</b><div class="kv"><span>(.*?)</span><p>.*?</p><span>(.*?)</span>', b[i:k])
    s_send, s_goal = m4.group(1), m4.group(2)
    item = ('<div class="svc-i"><b>%s</b><div class="kv"><span>%s</span><p>%s</p><span>%s</span><p>%s</p></div></div>'
            % (D, s_send, D2, s_goal, D3))
    b = b[:j] + item + b[j:]
    out.append('04')
    # 4) 05: 다섯 번째 줄(문의 메일) 다음에
    i = b.find('id="%s-s5"' % L); k = b.find('</section>', i)
    lis = [mm.end() for mm in re.finditer('</li>', b[i:k])]
    if len(lis) != 7: raise Exception('s5 줄 수 %d' % len(lis))
    p = i + lis[4]
    b = b[:p] + '<li>' + E_ + '</li>' + b[p:]
    out.append('05')
    # 5) 10: 개정 이력 맨 위
    i = b.find('id="%s-s10"' % L)
    j = b.find('<ul><li>', i) + len('<ul>')
    e = b.find('</li>', j)
    first = b[j + 4:e]
    cut = min([x for x in (first.find(':'), first.find('：')) if x >= 0])
    date = first[:cut].replace('19', '20', 1)
    sep = first[cut:]
    sep = sep[:len(sep) - len(sep.lstrip(':： '))]
    b = b[:j] + '<li>' + date + sep + F + '</li>' + b[j:]
    out.append('10')
    return b, out


def main():
    path = find_target()
    raw = open(path, 'rb').read()
    s = raw.decode('utf-8')
    ok = True
    res = []
    pos = 0
    arts = list(re.finditer(r'<article class="doc"[^>]*data-lang="(\w+)"', s))
    if len(arts) != 22:
        print('❌ 언어 수가 %d개 (22개여야 함)' % len(arts)); sys.exit(1)
    for m in arts:
        L = m.group(1)
        st = m.start(); en = s.find('</article>', st)
        res.append(s[pos:st])
        b = s[st:en]
        try:
            nb, steps = patch(b, L)
            print('✔', L, ' '.join(steps))
        except Exception as ex:
            print('❌', L, ex); ok = False; nb = b
        res.append(nb)
        pos = en
    res.append(s[pos:])
    ns = ''.join(res)
    for tag in ('li', 'ul', 'div', 'section', 'article', 'p', 'span', 'b'):
        o = len(re.findall(r'<%s[\s>]' % tag, ns)); c = ns.count('</%s>' % tag)
        if o != c:
            print('❌ 태그 짝 안 맞음:', tag, o, c); ok = False
    if not ok:
        print('❌ 저장 안 함'); sys.exit(1)
    if ns == s:
        print('✔ 바뀐 것 없음 (이미 적용됨)'); return
    if b'\r\n' in raw:
        ns = ns.replace('\r\n', '\n').replace('\n', '\r\n')
    open(path, 'wb').write(ns.encode('utf-8'))
    print('✔ 저장:', path)


main()
