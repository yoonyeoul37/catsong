# -*- coding: utf-8 -*-
# GPT가 다듬은 나머지 11개 언어 문구 넣기 (de es fr pt it ru tr pl id vi th)
#  - 키 이름 + 지금 문구가 정확히 맞을 때만 바꿈 (다르면 ❌, 아무것도 저장 안 함)
#  - 뺀 것: 버튼·탭·좁은 칸 글자가 길어진 것, 수면 버튼·연결 실패·재생 안 됨 표시,
#           파란소리 소개 메뉴 문구(오늘 정한 문장), 국내 라디오 슬로건
import os, sys, json

CHANGES = {
 "th": [
  [
   "noSongs",
   "ไม่พบไฟล์ MP3",
   "ไม่พบไฟล์เพลง MP3"
  ],
  [
   "scanningMusic",
   "กำลังสแกนเพลง...",
   "กำลังค้นหาเพลง..."
  ],
  [
   "version",
   "ข้อมูลเวอร์ชัน",
   "เวอร์ชัน"
  ],
  [
   "playMusic",
   "ลองเปิดเพลงฟังกัน",
   "ลองฟังเพลงกันเลย"
  ],
  [
   "clearRecent",
   "ล้างเพลงล่าสุด",
   "ล้างประวัติการเล่น"
  ],
  [
   "clearRecentConfirm",
   "ล้างเพลงที่เล่นล่าสุดทั้งหมดใช่ไหม",
   "ต้องการล้างประวัติการเล่นทั้งหมดไหม?"
  ],
  [
   "ringtoneFailed",
   "ตั้งเสียงเรียกเข้าไม่สำเร็จ",
   "ไม่สามารถตั้งค่าเสียงเรียกเข้าได้"
  ],
  [
   "deleteFailed",
   "ลบไม่สำเร็จ",
   "ไม่สามารถลบได้"
  ],
  [
   "flashlightError",
   "ไฟฉายขัดข้อง",
   "ไม่สามารถเปิดไฟฉายได้"
  ],
  [
   "radioNoFavoritesDesc",
   "แตะ ♡ ที่ช่องเพื่อเพิ่ม",
   "แตะ ♡ ข้างสถานีเพื่อเพิ่มในรายการโปรด"
  ],
  [
   "radioPlayFirst",
   "โปรดเปิดสถานีวิทยุก่อน",
   "กรุณาเปิดวิทยุก่อน"
  ],
  [
   "radioScheduleCompleteToast",
   "ตั้งเวลา {title} {time} แล้ว",
   "ตั้งเวลา {title} {time} เรียบร้อยแล้ว"
  ],
  [
   "radioPlaybackFailed",
   "เล่นไม่สำเร็จ",
   "ไม่สามารถเล่นได้"
  ],
  [
   "radioNoStationsFound",
   "ไม่พบสถานี",
   "ไม่พบสถานีวิทยุ"
  ],
  [
   "radioKoreaTitle",
   "วิทยุเกาหลี",
   "เสียงจากทั่วโลก"
  ],
  [
   "radioSloganGB",
   "ที่ซึ่งประเพณีพบปัจจุบัน",
   "เมื่อเรื่องราวดั้งเดิมพบกับเสียงร่วมสมัย"
  ],
  [
   "radioSloganCZ",
   "เสียงแห่งโบฮีเมีย",
   "เสียงจากเช็กเกีย"
  ],
  [
   "radioExitConfirmTitle",
   "ออกจากวิทยุไหม",
   "ต้องการออกจากวิทยุไหม?"
  ],
  [
   "radioExitConfirmMessage",
   "หากออกตอนนี้ เสียงจะหยุดเล่น",
   "แล้วกลับมาฟังเสียงดีๆ ด้วยกันอีกนะ"
  ],
  [
   "musicExitConfirmTitle",
   "หยุดเล่นเพลงไหม",
   "ต้องการหยุดเล่นเพลงไหม?"
  ],
  [
   "musicExitConfirmMessage",
   "หากออกตอนนี้ เพลงจะหยุดเล่น",
   "แล้วกลับมาฟังเสียงดีๆ ด้วยกันอีกนะ"
  ],
  [
   "homeTipScheduleTitle",
   "ตั้งเวลาเปิดวิทยุ",
   "ตั้งเวลาให้วิทยุเล่น"
  ],
  [
   "homeRecentEmpty",
   "ยังไม่มีรายการที่เล่น",
   "ยังไม่มีรายการที่ฟังล่าสุด"
  ],
  [
   "musicLoadError",
   "เกิดข้อผิดพลาดในการโหลดเพลง",
   "ไม่สามารถโหลดเพลงได้"
  ],
  [
   "musicScanError",
   "สแกนเพลงผิดพลาด",
   "ไม่สามารถค้นหาเพลงได้"
  ],
  [
   "cardMakeFailed",
   "สร้างการ์ดไม่สำเร็จ โปรดลองอีกครั้ง",
   "ไม่สามารถสร้างการ์ดได้ ลองอีกครั้งนะ"
  ],
  [
   "photoLoadFailed",
   "โหลดรูปไม่สำเร็จ",
   "ไม่สามารถโหลดรูปภาพได้"
  ],
  [
   "trimFailed",
   "ตัดไม่สำเร็จ",
   "ไม่สามารถตัดไฟล์ได้"
  ],
  [
   "ringtoneFailedMsg",
   "ตั้งเสียงเรียกเข้าไม่สำเร็จ",
   "ไม่สามารถตั้งเป็นเสียงเรียกเข้าได้"
  ],
  [
   "renameFailed",
   "เปลี่ยนชื่อไม่สำเร็จ",
   "ไม่สามารถเปลี่ยนชื่อได้"
  ],
  [
   "videoScanError",
   "สแกนวิดีโอผิดพลาด",
   "ไม่สามารถค้นหาวิดีโอได้"
  ],
  [
   "saveMusicFailed",
   "บันทึกเป็นเพลงไม่สำเร็จ",
   "ไม่สามารถบันทึกเป็นเพลงได้"
  ],
  [
   "trimFailed2",
   "ตัดไม่สำเร็จ",
   "ไม่สามารถตัดไฟล์ได้"
  ],
  [
   "radioShareSub",
   "แชร์สิ่งที่คุณกำลังฟัง",
   "แชร์สถานีที่คุณกำลังฟัง"
  ],
  [
   "scheduledToast",
   "ตั้งเวลาแล้ว",
   "ตั้งเวลาสำเร็จแล้ว"
  ],
  [
   "stationLoadFailed",
   "โหลดสถานีนี้ไม่ได้\nโปรดเลือกสถานีอื่น",
   "ไม่สามารถโหลดสถานีนี้ได้\nโปรดเลือกสถานีอื่น"
  ],
  [
   "soundPlayFailed",
   "เล่นเสียงไม่สำเร็จ",
   "ไม่สามารถเล่นเสียงได้"
  ],
  [
   "noMyMusic",
   "ไม่มีเพลงในโทรศัพท์นี้",
   "ยังไม่มีเพลงในเครื่อง"
  ],
  [
   "mixSub",
   "สร้างเสียงผ่อนคลายในแบบของคุณเอง",
   "เลือกผสมเสียงที่ชอบ เพื่อสร้างบรรยากาศในแบบของคุณ"
  ],
  [
   "lastMix",
   "มิกซ์ล่าสุด",
   "มิกซ์ครั้งล่าสุด"
  ],
  [
   "introFeature5Title",
   "มิกซ์เสียงของคุณเอง",
   "ผสมเสียงในแบบของคุณ"
  ]
 ],
 "fr": [
  [
   "play",
   "Lire",
   "Lecture"
  ],
  [
   "nowPlaying",
   "En lecture",
   "À l’écoute"
  ],
  [
   "noSongs",
   "Aucun fichier MP3 trouvé",
   "Aucun fichier MP3 sur cet appareil"
  ],
  [
   "addMusic",
   "Ajoutez des fichiers audio sur votre appareil",
   "Ajoutez des fichiers audio à votre appareil"
  ],
  [
   "scanningMusic",
   "Recherche de musique...",
   "Recherche de vos morceaux..."
  ],
  [
   "editSong",
   "Modifier les infos du titre",
   "Modifier les informations du morceau"
  ],
  [
   "sleepTimer",
   "Minuterie de sommeil",
   "Minuteur de veille"
  ],
  [
   "widget",
   "Widget d'accueil",
   "Widget de l’écran d’accueil"
  ],
  [
   "noRecentSongs",
   "Aucun titre écouté récemment",
   "Aucun morceau écouté récemment"
  ],
  [
   "playMusic",
   "Lancez un peu de musique",
   "Écoutez de la musique"
  ],
  [
   "clearRecent",
   "Effacer les récents",
   "Effacer l’historique"
  ],
  [
   "clearRecentConfirm",
   "Effacer tous les titres écoutés récemment ?",
   "Effacer tout l’historique d’écoute ?"
  ],
  [
   "playAll",
   "Tout lire",
   "Tout écouter"
  ],
  [
   "noAlbums",
   "Aucun album trouvé",
   "Aucun album"
  ],
  [
   "noArtists",
   "Aucun artiste trouvé",
   "Aucun artiste"
  ],
  [
   "permissionRequired",
   "Autorisation de stockage requise",
   "Accès aux fichiers audio requis"
  ],
  [
   "permissionMessage",
   "L'accès au stockage est nécessaire\npour trouver vos fichiers MP3.",
   "Autorisez l’accès aux fichiers audio\npour retrouver vos MP3."
  ],
  [
   "deleted",
   "Supprimé",
   "Élément supprimé"
  ],
  [
   "deleteFailed",
   "Échec de la suppression",
   "Suppression impossible"
  ],
  [
   "playNext",
   "Lire ensuite",
   "Écouter ensuite"
  ],
  [
   "flashlightError",
   "Erreur de la lampe torche",
   "Impossible d’allumer la lampe torche"
  ],
  [
   "preset",
   "Préréglage",
   "Préréglages"
  ],
  [
   "virtualizer",
   "Virtualiseur",
   "Effet spatial"
  ],
  [
   "reviewMessage",
   "Laissez-nous une note !\nCela nous aide à améliorer l'app 😊",
   "Donnez-nous votre avis !\nCela nous aide à améliorer l’application 😊"
  ],
  [
   "reviewButton",
   "⭐ Noter l'app",
   "⭐ Noter l’application"
  ],
  [
   "styleCD",
   "CD qui tourne",
   "CD en rotation"
  ],
  [
   "styleCard",
   "Carte pochette",
   "Pochette d’album"
  ],
  [
   "autoStopCountdownSuffix",
   "avant l'arrêt auto",
   "avant l’arrêt automatique"
  ],
  [
   "radioSchedule",
   "Programmer",
   "Programmation"
  ],
  [
   "sleepTimerActiveDesc",
   "Minuterie en cours",
   "Minuteur en cours"
  ],
  [
   "cancelTimerX",
   "× Annuler la minuterie",
   "× Annuler le minuteur"
  ]
 ],
 "it": [
  [
   "scanningMusic",
   "Scansione musica...",
   "Cerco la tua musica..."
  ],
  [
   "editSong",
   "Modifica info brano",
   "Modifica informazioni brano"
  ],
  [
   "sleepTimer",
   "Timer spegnimento",
   "Timer di spegnimento"
  ],
  [
   "playerStyle",
   "Stile player",
   "Stile del lettore"
  ],
  [
   "ringtone",
   "Imposta suoneria",
   "Imposta come suoneria"
  ],
  [
   "promoCode",
   "Codice promo",
   "Codice promozionale"
  ],
  [
   "clearRecent",
   "Cancella brani recenti",
   "Cancella cronologia"
  ],
  [
   "clearRecentConfirm",
   "Cancellare tutti i brani ascoltati di recente?",
   "Vuoi cancellare tutta la cronologia di ascolto?"
  ],
  [
   "noAlbums",
   "Nessun album trovato",
   "Nessun album disponibile"
  ],
  [
   "noArtists",
   "Nessun artista trovato",
   "Nessun artista disponibile"
  ],
  [
   "promoInvalid",
   "Codice promo non valido",
   "Codice promozionale non valido"
  ],
  [
   "promoEnter",
   "Inserisci il codice promo",
   "Inserisci il codice promozionale"
  ],
  [
   "permissionRequired",
   "Serve l'accesso alla memoria",
   "Autorizzazione di accesso ai file necessaria"
  ],
  [
   "permissionMessage",
   "Per cercare i file MP3\nserve l'accesso alla memoria.",
   "Per trovare i file MP3\nè necessario autorizzare l’accesso ai file."
  ],
  [
   "flashlightError",
   "Errore torcia",
   "Impossibile accendere la torcia"
  ],
  [
   "homeTipCastTitle",
   "Ascolta su TV o speaker",
   "Ascolta sulla TV o sugli altoparlanti"
  ],
  [
   "couldNotDelete",
   "Impossibile eliminare",
   "Non è stato possibile eliminare"
  ],
  [
   "dailyEveningLine",
   "Rilassati con il suono delle onde",
   "Prenditi una pausa con il suono delle onde"
  ],
  [
   "dailyTipMixTitle",
   "Aggiungi la pioggia alla musica",
   "Aggiungi il suono della pioggia alla musica"
  ],
  [
   "musicLoadError",
   "Errore nel caricamento della musica",
   "Non è stato possibile caricare la musica"
  ],
  [
   "musicScanError",
   "Errore nella scansione musica",
   "Non è stato possibile cercare la musica"
  ],
  [
   "natureMix",
   "Mix suoni natura",
   "Mix di suoni della natura"
  ],
  [
   "cardMakeFailed",
   "Impossibile creare la card. Riprova.",
   "Non è stato possibile creare la scheda. Riprova."
  ],
  [
   "pleaseWait",
   "Attendi un momento",
   "Un momento..."
  ],
  [
   "videoScanError",
   "Errore nella scansione video",
   "Non è stato possibile cercare i video"
  ],
  [
   "noRecentStations",
   "Nessuna stazione ascoltata di recente",
   "Nessuna radio ascoltata di recente"
  ],
  [
   "stationLoadFailed",
   "Impossibile caricare la stazione.\nScegline un'altra.",
   "Non è stato possibile caricare la radio.\nScegli un’altra stazione."
  ],
  [
   "mixSub",
   "Crea il tuo paesaggio sonoro rilassante.",
   "Crea la tua atmosfera con i suoni che ami."
  ],
  [
   "noFavNature",
   "Nessun suono della natura preferito",
   "Nessun suono della natura tra i preferiti"
  ],
  [
   "infoLongTimeD",
   "Riproduce in casuale i brani non ascoltati da un mese",
   "Riproduce in ordine casuale i brani che non ascolti da un mese"
  ],
  [
   "pickNatureSound",
   "Scegli suono della natura",
   "Scegli un suono della natura"
  ],
  [
   "alarmSound",
   "Suono sveglia",
   "Suono della sveglia"
  ],
  [
   "introEverydayTitle",
   "Il suono nella tua giornata",
   "I suoni della tua giornata"
  ]
 ],
 "pl": [
  [
   "nowPlaying",
   "Odtwarzane",
   "Teraz odtwarzane"
  ],
  [
   "scanningMusic",
   "Skanowanie muzyki...",
   "Wyszukiwanie muzyki..."
  ],
  [
   "sleepTimer",
   "Wyłącznik czasowy",
   "Minutnik uśpienia"
  ],
  [
   "ringtone",
   "Ustaw dzwonek",
   "Ustaw jako dzwonek"
  ],
  [
   "version",
   "Informacje o wersji",
   "Wersja"
  ],
  [
   "playMusic",
   "Włącz jakąś muzykę",
   "Posłuchaj muzyki"
  ],
  [
   "clearRecent",
   "Wyczyść ostatnie utwory",
   "Wyczyść historię odtwarzania"
  ],
  [
   "clearRecentConfirm",
   "Wyczyścić wszystkie ostatnio odtwarzane utwory?",
   "Usunąć całą historię odtwarzania?"
  ],
  [
   "timerCancel",
   "Anuluj wyłącznik",
   "Anuluj minutnik"
  ],
  [
   "flashlightError",
   "Błąd latarki",
   "Nie udało się włączyć latarki"
  ],
  [
   "radioRecentListening",
   "Ostatnio słuchane",
   "Ostatnio słuchane stacje"
  ],
  [
   "sleepTimerDesc",
   "Wyłączy się automatycznie po wybranym czasie",
   "Odtwarzanie zatrzyma się automatycznie po wybranym czasie"
  ],
  [
   "sleepTimerActiveDesc",
   "Wyłącznik czasowy działa",
   "Minutnik uśpienia jest włączony"
  ],
  [
   "cancelTimerX",
   "× Anuluj wyłącznik",
   "× Anuluj minutnik"
  ],
  [
   "radioNoFavorites",
   "Brak ulubionych",
   "Nie masz jeszcze ulubionych stacji"
  ],
  [
   "radioPlayFirst",
   "Najpierw włącz stację radiową",
   "Najpierw włącz radio"
  ],
  [
   "radioPlaybackFailed",
   "Nie udało się odtworzyć.",
   "Nie udało się rozpocząć odtwarzania."
  ],
  [
   "radioExitConfirmMessage",
   "Jeśli teraz wyjdziesz, odtwarzanie się zatrzyma.",
   "Do usłyszenia następnym razem!"
  ],
  [
   "musicExitConfirmMessage",
   "Jeśli teraz wyjdziesz, odtwarzanie się zatrzyma.",
   "Do usłyszenia następnym razem!"
  ],
  [
   "homeTipScheduleSub",
   "Stuknij Ramówka pod odtwarzaczem radia",
   "Stuknij „Zaplanuj” pod odtwarzaczem radia"
  ],
  [
   "homeTipSleepTitle",
   "Wyłącznik czasowy na noc",
   "Zasypiaj z minutnikiem"
  ],
  [
   "homeTipSleepSub",
   "Stuknij Uśpienie pod odtwarzaczem",
   "Stuknij „Sen” pod odtwarzaczem"
  ],
  [
   "homeRecentHeader",
   "Ostatnio odtwarzane",
   "Ostatnio słuchane"
  ],
  [
   "homeRecentEmpty",
   "Nic jeszcze nie odtwarzano",
   "Nie masz ostatnio słuchanych utworów"
  ],
  [
   "dailyTipVideoTitle",
   "Zapisz dźwięk z filmu",
   "Zapisz sam dźwięk z filmu"
  ],
  [
   "dailyTipMixTitle",
   "Dodaj deszcz do muzyki",
   "Dodaj odgłosy deszczu do muzyki"
  ],
  [
   "dailyOffMessage",
   "Możesz ją włączyć ponownie w Ustawieniach.",
   "Możesz ją ponownie włączyć w Ustawieniach → Karty polecane na ekranie głównym."
  ],
  [
   "moreArtTitle",
   "Znajdź okładki",
   "Znajdź okładki albumów"
  ],
  [
   "musicLoadError",
   "Błąd wczytywania muzyki",
   "Nie udało się wczytać muzyki"
  ],
  [
   "musicScanError",
   "Błąd skanowania muzyki",
   "Nie udało się wyszukać muzyki"
  ],
  [
   "sleepFadeHint",
   "Ostatnia minuta stopniowo cichnie",
   "W ostatniej minucie dźwięk stopniowo cichnie"
  ],
  [
   "playerScreen",
   "Styl odtwarzacza",
   "Ekran odtwarzania"
  ],
  [
   "lyricsDeleteMine",
   "Usuń mój tekst",
   "Usuń dodany tekst"
  ],
  [
   "pickRightArt",
   "Wybierz właściwą okładkę",
   "Wybierz odpowiednią okładkę albumu"
  ],
  [
   "noSongsWithoutArt",
   "Żadnemu utworowi nie brakuje okładki",
   "Wszystkie utwory mają okładki"
  ],
  [
   "artSummary",
   "Bez okładki: {missing} · Znaleziono: {found}",
   "Bez okładki: {missing} · Znalezione: {found}"
  ],
  [
   "saveCurrentEq",
   "Zapisz ustawienia",
   "Zapisz bieżące ustawienia"
  ],
  [
   "accurateNamesHelp",
   "Dokładne nazwy wykonawcy i tytułu pomagają",
   "Dokładny tytuł i nazwa wykonawcy ułatwią wyszukiwanie"
  ],
  [
   "noVoiceRec",
   "Brak nagrań głosowych",
   "Nie masz nagrań głosowych"
  ],
  [
   "noCallRec",
   "Brak nagrań rozmów",
   "Nie masz nagrań rozmów"
  ],
  [
   "autoSaveWhen",
   "Zapisz automatycznie po osiągnięciu tej długości",
   "Zapisz automatycznie po osiągnięciu wybranego czasu"
  ],
  [
   "castFailedRetry",
   "Nie udało się wysłać na TV. Spróbuj ponownie.",
   "Nie udało się przesłać na telewizor. Spróbuj ponownie."
  ]
 ],
 "de": [
  [
   "pause",
   "Pause",
   "Pausieren"
  ],
  [
   "next",
   "Weiter",
   "Nächster"
  ],
  [
   "previous",
   "Zurück",
   "Vorheriger"
  ],
  [
   "noSongs",
   "Keine MP3-Dateien gefunden",
   "Keine MP3-Dateien vorhanden"
  ],
  [
   "scanningMusic",
   "Musik wird gesucht...",
   "Musik wird gesucht …"
  ],
  [
   "playbackSpeed",
   "Wiedergabetempo",
   "Abspielgeschwindigkeit"
  ],
  [
   "repeatOne",
   "Titel wiederholen",
   "Aktuellen Titel wiederholen"
  ],
  [
   "version",
   "Versionsinfo",
   "Version"
  ],
  [
   "noRecentSongs",
   "Noch keine zuletzt gespielten Titel",
   "Noch keine Titel abgespielt"
  ],
  [
   "playMusic",
   "Spiel doch etwas Musik ab",
   "Hör dir etwas Musik an"
  ]
 ],
 "ru": [
  [
   "ringtone",
   "Сделать рингтоном",
   "Установить как рингтон"
  ],
  [
   "playMusic",
   "Включите музыку",
   "Послушайте музыку"
  ],
  [
   "clearRecent",
   "Очистить недавние",
   "Очистить историю"
  ],
  [
   "clearRecentConfirm",
   "Очистить все недавно прослушанные песни?",
   "Очистить историю прослушивания?"
  ],
  [
   "playAll",
   "Слушать все",
   "Воспроизвести всё"
  ],
  [
   "flashlightError",
   "Ошибка фонарика",
   "Не удалось включить фонарик"
  ],
  [
   "lyricsLoading",
   "Загрузка текста...",
   "Загружаем текст песни..."
  ],
  [
   "lyricsErrorNotFound",
   "Текст не найден",
   "Текст песни не найден"
  ],
  [
   "radioRecentListening",
   "Недавно слушали",
   "Недавно прослушанные"
  ],
  [
   "radioSchedule",
   "Программа",
   "Расписание"
  ],
  [
   "radioScheduleTitle",
   "Программа {station}",
   "Программа передач: {station}"
  ],
  [
   "radioPlayFirst",
   "Сначала включите радиостанцию",
   "Сначала включите радио"
  ],
  [
   "radioScheduleCompleteToast",
   "{title}: запланировано на {time}",
   "{title}: эфир запланирован на {time}"
  ],
  [
   "radioPlaybackFailed",
   "Не удалось воспроизвести.",
   "Не удалось запустить воспроизведение."
  ],
  [
   "selectRange",
   "Выберите отрезок",
   "Выберите фрагмент"
  ],
  [
   "homeTipScheduleTitle",
   "Запланируйте радио",
   "Включайте радио по расписанию"
  ],
  [
   "homeTipScheduleSub",
   "Нажмите «Программа» под плеером радио",
   "Нажмите «Запланировать» под радиоплеером"
  ],
  [
   "dailyTipMixSub",
   "Меню ⋮ плеера → Микс звуков природы",
   "Меню ⋮ в плеере → «Микс звуков природы»"
  ],
  [
   "musicLoadError",
   "Ошибка загрузки музыки",
   "Не удалось загрузить музыку"
  ],
  [
   "musicScanError",
   "Ошибка поиска музыки",
   "Не удалось найти музыку"
  ],
  [
   "shufflePlay",
   "Перемешать",
   "Случайный порядок"
  ],
  [
   "lyricsSaved",
   "Сохранено как текст этой песни",
   "Текст песни сохранён"
  ],
  [
   "previewListen",
   "Прослушать",
   "Предпрослушивание"
  ],
  [
   "songInfoNotFound",
   "Не удалось найти данные об этой песне",
   "Не удалось найти информацию о песне"
  ],
  [
   "videoScanError",
   "Ошибка поиска видео",
   "Не удалось найти видео"
  ],
  [
   "radioShareSub",
   "Поделитесь тем, что слушаете.",
   "Расскажите друзьям, что слушаете."
  ],
  [
   "scheduleFull",
   "Больше нельзя. Удалите старые в «Расписании».",
   "Достигнут лимит. Удалите прошедшие записи в разделе «Расписание»."
  ],
  [
   "scheduleSub",
   "В заданное время включится эта станция",
   "В выбранное время включится эта радиостанция"
  ],
  [
   "scheduleLimit",
   "Не больше 5 расписаний. Удалите старые, чтобы добавить.",
   "Можно создать до 5 записей. Удалите прошедшие, чтобы добавить новую."
  ],
  [
   "noRecentStations",
   "Нет недавно прослушанных станций",
   "Вы ещё не слушали радиостанции"
  ],
  [
   "niceNow",
   "Хорошо слушать сейчас",
   "Что послушать сейчас"
  ],
  [
   "playMix",
   "Включить микс",
   "Воспроизвести микс"
  ],
  [
   "lastMix",
   "Последний микс",
   "Предыдущий микс"
  ],
  [
   "infoLongTimeD",
   "Перемешивает песни, которые вы не слушали месяц",
   "Воспроизводит в случайном порядке песни, которые вы не слушали месяц"
  ],
  [
   "headsetPlay",
   "Сразу включать",
   "Воспроизводить сразу"
  ],
  [
   "greetLine5",
   "Расслабьтесь и слушайте",
   "Место, где можно отдохнуть душой — Paransori"
  ],
  [
   "genreShuffle",
   "Перемешиваем: {label} · песен: {n}",
   "{label} · {n} песен в случайном порядке"
  ],
  [
   "introFeature5Title",
   "Свой микс звуков",
   "Мой звуковой микс"
  ],
  [
   "introFeature5Desc",
   "Включайте любимые звуки вместе и создавайте свою атмосферу.",
   "Сочетайте любимые звуки и создавайте настроение под себя."
  ],
  [
   "nature07Desc",
   "Ровный дождь помогает сосредоточиться и унимает тревогу",
   "Монотонный шум дождя помогает сосредоточиться и расслабиться"
  ],
  [
   "nature11Desc",
   "Звонкое пение птиц снимает стресс и поднимает настроение",
   "Звонкое пение птиц помогает расслабиться и поднимает настроение"
  ],
  [
   "nature13Desc",
   "Треск дров создаёт уют для глубокого расслабления",
   "Потрескивание дров создаёт уютную атмосферу для отдыха"
  ]
 ],
 "vi": [
  [
   "previous",
   "Trước",
   "Trước đó"
  ],
  [
   "noSongs",
   "Không tìm thấy tệp MP3",
   "Chưa có tệp MP3 nào"
  ],
  [
   "addMusic",
   "Hãy thêm tệp nhạc vào thiết bị của bạn",
   "Thêm tệp nhạc vào thiết bị để bắt đầu nghe"
  ],
  [
   "scanningMusic",
   "Đang quét nhạc...",
   "Đang tìm nhạc..."
  ],
  [
   "editSong",
   "Sửa thông tin bài hát",
   "Chỉnh sửa thông tin bài hát"
  ],
  [
   "playerStyle",
   "Kiểu trình phát",
   "Giao diện trình phát"
  ],
  [
   "sos",
   "Đèn khẩn cấp SOS",
   "Tín hiệu SOS khẩn cấp"
  ],
  [
   "version",
   "Thông tin phiên bản",
   "Phiên bản"
  ],
  [
   "noRecentSongs",
   "Chưa có bài hát phát gần đây",
   "Chưa có bài hát nào được phát gần đây"
  ],
  [
   "playMusic",
   "Hãy phát một bài nhạc",
   "Thử nghe một bài nhạc nhé"
  ],
  [
   "clearRecent",
   "Xóa bài hát gần đây",
   "Xóa lịch sử phát"
  ],
  [
   "clearRecentConfirm",
   "Xóa tất cả bài hát đã phát gần đây?",
   "Xóa toàn bộ lịch sử phát gần đây?"
  ],
  [
   "noAlbums",
   "Không tìm thấy album",
   "Chưa có album nào"
  ],
  [
   "noArtists",
   "Không tìm thấy nghệ sĩ",
   "Chưa có nghệ sĩ nào"
  ],
  [
   "ringtoneFailed",
   "Không thể đặt nhạc chuông",
   "Không đặt được nhạc chuông"
  ],
  [
   "permissionRequired",
   "Cần quyền truy cập bộ nhớ",
   "Cần quyền truy cập tệp nhạc"
  ],
  [
   "deleted",
   "Đã xóa",
   "Đã xóa thành công"
  ],
  [
   "deleteFailed",
   "Xóa thất bại",
   "Không thể xóa"
  ],
  [
   "flashlightError",
   "Lỗi đèn pin",
   "Không bật được đèn pin"
  ],
  [
   "reviewMessage",
   "Hãy để lại đánh giá nhé!\nĐiều đó giúp chúng tôi cải thiện ứng dụng 😊",
   "Hãy đánh giá ứng dụng nhé!\nÝ kiến của bạn giúp Paransori ngày càng tốt hơn 😊"
  ],
  [
   "unknownArtist",
   "Nghệ sĩ không rõ",
   "Nghệ sĩ không xác định"
  ],
  [
   "unknownAlbum",
   "Album không rõ",
   "Album không xác định"
  ],
  [
   "lyricsErrorNetwork",
   "Vui lòng kiểm tra kết nối Internet",
   "Vui lòng kiểm tra kết nối mạng"
  ],
  [
   "justNow",
   "Vừa xong",
   "Vừa mới đây"
  ],
  [
   "radioRecentListening",
   "Nghe gần đây",
   "Đã nghe gần đây"
  ],
  [
   "sleepTimerActiveDesc",
   "Hẹn giờ đang chạy",
   "Bộ hẹn giờ đang hoạt động"
  ],
  [
   "countryGE",
   "Gruzia",
   "Georgia"
  ],
  [
   "categorySeoulGyeonggi",
   "Seoul/Gyeonggi",
   "Seoul / Gyeonggi"
  ],
  [
   "categoryRegionalPrivate",
   "Đài tư nhân địa phương",
   "Đài phát thanh địa phương"
  ],
  [
   "regionCapital",
   "Vùng thủ đô",
   "Khu vực thủ đô"
  ],
  [
   "radioNoFavoritesDesc",
   "Nhấn ♡ trên một kênh để thêm",
   "Nhấn ♡ bên cạnh kênh để thêm vào yêu thích"
  ]
 ],
 "tr": [
  [
   "noSongs",
   "MP3 dosyası bulunamadı",
   "MP3 dosyası bulunamadı."
  ],
  [
   "addMusic",
   "Cihazına müzik dosyası ekle",
   "Cihazına müzik dosyaları ekle."
  ],
  [
   "scanningMusic",
   "Müzikler taranıyor...",
   "Müzikler aranıyor..."
  ],
  [
   "repeatOne",
   "Birini tekrarla",
   "Geçerli şarkıyı tekrarla"
  ],
  [
   "version",
   "Sürüm bilgisi",
   "Sürüm"
  ],
  [
   "noRecentSongs",
   "Son çalınan şarkı yok",
   "Henüz dinlenen şarkı yok"
  ],
  [
   "playMusic",
   "Biraz müzik çal",
   "Biraz müzik dinlemeye ne dersin?"
  ],
  [
   "clearRecent",
   "Son çalınanları temizle",
   "Dinleme geçmişini temizle"
  ],
  [
   "clearRecentConfirm",
   "Son çalınan tüm şarkılar temizlensin mi?",
   "Dinleme geçmişi temizlensin mi?"
  ],
  [
   "permissionRequired",
   "Depolama izni gerekli",
   "Depolama izni gerekiyor"
  ],
  [
   "permissionMessage",
   "MP3 dosyalarını taramak için\ndepolama izni gerekli.",
   "MP3 dosyalarını bulmak için\ndepolama izni gerekiyor."
  ],
  [
   "flashlightError",
   "El feneri hatası",
   "El feneri açılamadı"
  ],
  [
   "musicExitConfirmMessage",
   "Şimdi çıkarsan çalma durur.",
   "Güzel seslerde yine buluşalım."
  ],
  [
   "menuRadioSub",
   "Dünyanın dört bir yanından\nradyo dinle.",
   "Farklı radyo yayınlarını\nhemen dinle."
  ],
  [
   "dailyLongTime",
   "Uzun zamandır dinlemedin",
   "Uzun zamandır dinlemediğin şarkılar"
  ],
  [
   "dailyNotPlayedSub",
   "Bir daha dinlesen mi?",
   "Yeniden dinlemeye ne dersin?"
  ],
  [
   "dailyDayLine",
   "Akan bir dereyle rahatla",
   "Dere sesiyle biraz soluklan"
  ],
  [
   "dailyEveningLine",
   "Dalga sesleriyle dinlen",
   "Dalga sesleri eşliğinde dinlen"
  ],
  [
   "dailyNightLine",
   "Yağmur sesiyle dinlen",
   "Yağmur sesi eşliğinde dinlen"
  ],
  [
   "dailyTipMixSub",
   "Oynatıcı ⋮ menüsü → Doğa sesi karışımı",
   "Oynatıcı ⋮ menüsü → Doğa sesleri miksajı"
  ],
  [
   "moreAlarmSub",
   "Müzik, radyo veya doğa sesiyle uyan",
   "Sevdiğin müzik, radyo veya doğa sesleriyle uyan"
  ],
  [
   "musicLoadError",
   "Müzik yüklenirken hata oluştu",
   "Müzikler yüklenemedi"
  ],
  [
   "musicScanError",
   "Müzik tarama hatası",
   "Müzikler aranırken bir sorun oluştu"
  ],
  [
   "natureMix",
   "Doğa sesi karışımı",
   "Doğa sesleri miksajı"
  ],
  [
   "videoScanError",
   "Video tarama hatası",
   "Videolar aranırken bir sorun oluştu"
  ],
  [
   "radioShareText",
   "Şu an dinlediğim: {name}! Paransori'de benimle dinle 🎧",
   "Şu anda {name} dinliyorum! Paransori’de birlikte dinleyelim 🎧"
  ],
  [
   "radioShareSub",
   "Dinlediğini paylaş.",
   "Dinlediğin yayını paylaş."
  ],
  [
   "pickFromSchedule",
   "Yayın akışından program seç",
   "Yayın akışından bir program seç"
  ],
  [
   "diceNoProgram",
   "Program bilgisi yok",
   "Program bilgisi bulunamadı"
  ],
  [
   "recentListened",
   "Son dinlenen",
   "Son dinlenenler"
  ],
  [
   "noRecentStations",
   "Son dinlenen istasyon yok",
   "Henüz dinlenen radyo yok"
  ],
  [
   "loadingMoreStations",
   "Daha fazla istasyon yükleniyor",
   "Daha fazla radyo yükleniyor..."
  ],
  [
   "stationLoadFailed",
   "Bu istasyon yüklenemiyor.\nLütfen başka birini seç.",
   "Bu radyo yüklenemedi.\nLütfen başka bir kanal seç."
  ],
  [
   "natureShareText",
   "Paransori'de doğa sesleriyle dinleniyorum 🌊",
   "Paransori’de doğa sesleriyle huzurlu bir mola veriyorum 🌊"
  ],
  [
   "mixSub",
   "Kendi dinlendirici ses ortamını oluştur.",
   "Sevdiğin seslerle kendi ortamını oluştur."
  ],
  [
   "myMixDefault",
   "Ses karışımım",
   "Kendi ses miksim"
  ],
  [
   "lastMix",
   "Son karışım",
   "Son miks"
  ],
  [
   "restFocusSoon",
   "Dinlen · Odaklan yakında geliyor",
   "Dinlenme ve odaklanma özelliği yakında"
  ],
  [
   "restFocusSub",
   "Dinlenmek ve odaklanmak için sakin sesler",
   "Sakin seslerle dinlen ve odaklan"
  ],
  [
   "headsetDesc",
   "Kulaklık bağlanınca çalmaya devam eder",
   "Kulaklık bağlandığında müzik kaldığı yerden devam eder"
  ],
  [
   "infoLongTimeD",
   "Bir aydır çalmadığın şarkıları karıştırır",
   "Bir aydır dinlemediğin şarkıları karışık çalar"
  ],
  [
   "infoWeekD",
   "Son 7 gündeki çalmalar ve en sevdiğin şarkı",
   "Son 7 gündeki dinleme sayın ve en çok dinlediğin şarkı"
  ]
 ],
 "pt": [
  [
   "noSongs",
   "Nenhum arquivo MP3 encontrado",
   "Nenhum arquivo MP3 no dispositivo"
  ],
  [
   "addMusic",
   "Adicione músicas ao seu aparelho",
   "Adicione músicas ao dispositivo"
  ],
  [
   "sleepTimer",
   "Timer para dormir",
   "Temporizador de sono"
  ],
  [
   "playerStyle",
   "Estilo do player",
   "Estilo da tela de reprodução"
  ],
  [
   "ringtone",
   "Definir toque",
   "Definir como toque"
  ],
  [
   "noRecentSongs",
   "Nenhuma música tocada recentemente",
   "Você ainda não ouviu nenhuma música"
  ],
  [
   "playMusic",
   "Toque alguma música",
   "Que tal ouvir uma música?"
  ],
  [
   "clearRecent",
   "Limpar recentes",
   "Limpar histórico"
  ],
  [
   "clearRecentConfirm",
   "Limpar todas as músicas tocadas recentemente?",
   "Quer limpar todo o histórico de reprodução?"
  ],
  [
   "noAlbums",
   "Nenhum álbum encontrado",
   "Nenhum álbum disponível"
  ],
  [
   "noArtists",
   "Nenhum artista encontrado",
   "Nenhum artista disponível"
  ],
  [
   "permissionRequired",
   "Permissão de armazenamento necessária",
   "Permissão de acesso aos arquivos necessária"
  ],
  [
   "permissionMessage",
   "É preciso permitir o acesso ao armazenamento\npara buscar arquivos MP3.",
   "Permita o acesso aos arquivos\npara encontrar suas músicas MP3."
  ],
  [
   "deleted",
   "Excluída",
   "Item excluído"
  ],
  [
   "deleteFailed",
   "Falha ao excluir",
   "Não foi possível excluir"
  ],
  [
   "flashlightError",
   "Erro na lanterna",
   "Não foi possível ligar a lanterna"
  ],
  [
   "lyricsLoading",
   "Carregando letra...",
   "Carregando a letra..."
  ],
  [
   "radioSelectCountry",
   "Escolher país",
   "Selecionar país"
  ],
  [
   "radioSchedule",
   "Programação",
   "Agendar"
  ],
  [
   "sleepTimerDesc",
   "Desliga automaticamente após o tempo escolhido",
   "A reprodução para após o tempo escolhido"
  ],
  [
   "sleepTimerActiveDesc",
   "Timer ativado",
   "Temporizador ativo"
  ],
  [
   "radioNoFavorites",
   "Nenhum favorito ainda",
   "Você ainda não tem rádios favoritas"
  ],
  [
   "radioNoFavoritesDesc",
   "Toque em ♡ numa emissora para adicioná-la",
   "Toque em ♡ ao lado de uma rádio para adicioná-la"
  ],
  [
   "radioLoadingPopular",
   "Carregando emissoras populares...",
   "Carregando rádios populares..."
  ],
  [
   "radioScheduleTitle",
   "Programação da {station}",
   "Programação de {station}"
  ],
  [
   "radioLoadingSchedule",
   "Carregando programação...",
   "Carregando a programação..."
  ],
  [
   "radioPlayFirst",
   "Toque uma emissora de rádio primeiro",
   "Escolha uma rádio para ouvir primeiro"
  ],
  [
   "radioScheduleCompleteToast",
   "{title} agendado para {time}",
   "{title} agendado para as {time}"
  ],
  [
   "radioPlaybackFailed",
   "Falha na reprodução.",
   "Não foi possível reproduzir."
  ],
  [
   "radioNoStationsFound",
   "Nenhuma emissora encontrada",
   "Nenhuma rádio encontrada"
  ],
  [
   "radioKoreaTitle",
   "Rádio da Coreia",
   "Sons do mundo"
  ],
  [
   "radioSloganSG",
   "A vibe da Cidade do Leão",
   "No ritmo da Cidade do Leão"
  ],
  [
   "musicLoadError",
   "Erro ao carregar músicas",
   "Não foi possível carregar as músicas"
  ],
  [
   "musicScanError",
   "Erro ao buscar músicas",
   "Não foi possível encontrar as músicas"
  ],
  [
   "pleaseWait",
   "Aguarde um momento",
   "Só um instante..."
  ],
  [
   "dateUnknown",
   "Data desconhecida",
   "Data não disponível"
  ],
  [
   "videoScanError",
   "Erro ao buscar vídeos",
   "Não foi possível encontrar os vídeos"
  ],
  [
   "stationLoadFailed",
   "Não foi possível carregar esta emissora.\nEscolha outra.",
   "Não foi possível carregar esta rádio.\nEscolha outra."
  ],
  [
   "turnBackOn",
   "Ligar de novo",
   "Ativar novamente"
  ],
  [
   "helpMediaTitle",
   "Carregar músicas e vídeos",
   "Acessar músicas e vídeos"
  ]
 ],
 "id": [
  [
   "scanningMusic",
   "Memindai musik...",
   "Mencari musik..."
  ],
  [
   "playbackSpeed",
   "Kecepatan putar",
   "Kecepatan pemutaran"
  ],
  [
   "repeatMode",
   "Mode ulang",
   "Mode pengulangan"
  ],
  [
   "noRepeat",
   "Tanpa ulang",
   "Tidak diulang"
  ],
  [
   "repeatOne",
   "Ulangi satu",
   "Ulangi lagu ini"
  ],
  [
   "repeatAll",
   "Ulangi semua",
   "Ulangi semua lagu"
  ],
  [
   "version",
   "Info versi",
   "Versi"
  ],
  [
   "playMusic",
   "Putar musik dulu, yuk",
   "Yuk, dengarkan musik"
  ],
  [
   "clearRecent",
   "Hapus lagu terbaru",
   "Hapus riwayat pemutaran"
  ],
  [
   "clearRecentConfirm",
   "Hapus semua lagu yang baru diputar?",
   "Hapus seluruh riwayat pemutaran?"
  ],
  [
   "ringtoneFailed",
   "Gagal mengatur nada dering",
   "Tidak dapat mengatur nada dering"
  ],
  [
   "permissionRequired",
   "Perlu izin penyimpanan",
   "Izin akses penyimpanan diperlukan"
  ],
  [
   "permissionMessage",
   "Izin penyimpanan diperlukan\nuntuk memindai file MP3.",
   "Untuk mencari file MP3,\nizinkan akses penyimpanan."
  ],
  [
   "deleteFailed",
   "Gagal menghapus",
   "Tidak dapat menghapus"
  ],
  [
   "enhancesBass",
   "Mempertebal suara bass",
   "Meningkatkan suara bass"
  ],
  [
   "surroundEffect",
   "Membuat efek suara surround",
   "Memberikan efek suara yang lebih luas"
  ],
  [
   "radioRecentListening",
   "Baru didengar",
   "Terakhir didengarkan"
  ],
  [
   "radioPopular200",
   "200 Populer",
   "200 Terpopuler"
  ],
  [
   "radioPlayFirst",
   "Putar stasiun radio dulu",
   "Putar radio terlebih dahulu"
  ],
  [
   "radioScheduleCompleteToast",
   "{title} {time} dijadwalkan",
   "{title} dijadwalkan pada {time}"
  ],
  [
   "radioPlaybackFailed",
   "Gagal memutar.",
   "Tidak dapat memutar siaran."
  ],
  [
   "radioSloganAU",
   "Suara Negeri Kanguru",
   "Suara dari belahan bumi selatan"
  ],
  [
   "homeTipAlarmSub",
   "Musik, radio, atau suara alam",
   "Bangun dengan musik, radio, atau suara alam"
  ],
  [
   "homeTipCastTitle",
   "Putar di TV atau speaker",
   "Dengarkan lewat TV atau speaker"
  ],
  [
   "homeTipSleepTitle",
   "Timer tidur sebelum tidur",
   "Atur timer sebelum tidur"
  ],
  [
   "homeTipSleepSub",
   "Ketuk Tidur di bawah pemutar",
   "Ketuk Timer tidur di layar pemutar"
  ],
  [
   "homeRecentHeader",
   "Baru diputar",
   "Baru didengarkan"
  ],
  [
   "homeRecentEmptySub",
   "Yang diputar 30 dtk+ akan muncul di sini",
   "Musik, radio, dan suara alam yang didengarkan minimal 30 detik akan muncul di sini"
  ],
  [
   "listen",
   "Putar",
   "Dengarkan"
  ],
  [
   "dailyEveningLine",
   "Rileks dengan suara ombak",
   "Beristirahat ditemani suara ombak"
  ],
  [
   "dailyNightLine",
   "Rileks dengan suara hujan",
   "Beristirahat ditemani suara hujan"
  ],
  [
   "dailyTipMixTitle",
   "Tambah suara hujan ke musikmu",
   "Padukan musik dengan suara hujan"
  ],
  [
   "dailyTipMixSub",
   "Menu ⋮ pemutar → Mix suara alam",
   "Menu ⋮ di pemutar → Campur suara alam"
  ],
  [
   "musicLoadError",
   "Gagal memuat musik",
   "Tidak dapat memuat musik"
  ],
  [
   "musicScanError",
   "Gagal memindai musik",
   "Tidak dapat mencari musik"
  ],
  [
   "castPlayingNow",
   "Sedang diputar di {device}",
   "Sedang diputar melalui {device}"
  ],
  [
   "natureMix",
   "Mix suara alam",
   "Campur suara alam"
  ],
  [
   "lyricsDeleteMessage",
   "Setelah dihapus, kami akan mencarinya lagi secara online.",
   "Setelah dihapus, lirik akan dicari lagi di internet."
  ],
  [
   "cardMakeFailed",
   "Gagal membuat kartu. Coba lagi, ya.",
   "Kartu tidak dapat dibuat. Coba lagi, ya."
  ],
  [
   "photoLoadFailed",
   "Gagal memuat foto",
   "Foto tidak dapat dimuat"
  ],
  [
   "trimFailed",
   "Gagal memotong",
   "Tidak dapat memotong"
  ],
  [
   "nowListening",
   "Sedang diputar",
   "Sedang didengarkan"
  ],
  [
   "videoScanError",
   "Gagal memindai video",
   "Tidak dapat mencari video"
  ],
  [
   "saveMusicFailed",
   "Gagal menyimpan sebagai musik",
   "Tidak dapat menyimpan sebagai musik"
  ],
  [
   "youtubeOpenFailed",
   "Gagal membuka YouTube",
   "YouTube tidak dapat dibuka"
  ],
  [
   "noRecentStations",
   "Belum ada stasiun yang diputar",
   "Belum ada siaran yang didengarkan"
  ],
  [
   "soundPlayFailed",
   "Gagal memutar suara",
   "Suara tidak dapat diputar"
  ],
  [
   "natureTitle1",
   "Suara",
   "Alam"
  ],
  [
   "natureSub",
   "Suara untuk menenangkan pikiran",
   "Dengarkan suara yang menenangkan"
  ],
  [
   "mixSub",
   "Racik suasana santaimu sendiri.",
   "Ciptakan suasana nyaman dengan suara pilihanmu."
  ],
  [
   "overlayOnHint",
   "Lapisi musikmu dengan suara alam yang lembut",
   "Padukan musik dengan suara alam yang lembut"
  ],
  [
   "overlayIdleHint",
   "Ikut diputar saat musik menyala",
   "Suara alam ikut diputar saat musik diputar"
  ],
  [
   "lastMix",
   "Mix terakhir",
   "Campuran terakhir"
  ],
  [
   "headsetDesc",
   "Melanjutkan putar saat headphone tersambung",
   "Lanjutkan musik saat headphone tersambung"
  ],
  [
   "headsetPlay",
   "Langsung putar",
   "Putar sekarang"
  ],
  [
   "greetLine2",
   "Suara indah, hari yang indah",
   "Senang bertemu lagi. Yuk, istirahat sejenak."
  ],
  [
   "greetLine4",
   "Suaramu sudah menunggu",
   "Senang bertemu lagi hari ini"
  ],
  [
   "greetLine5",
   "Santai dan dengarkan",
   "Tempat untuk melepas penat bersama Paransori"
  ],
  [
   "introNameLabel",
   "Tentang nama",
   "Kisah di balik nama"
  ],
  [
   "introFeature5Title",
   "Mix suara pribadi",
   "Campuran suara pilihanmu"
  ],
  [
   "introMenuTitle",
   "Tentang Paransori",
   "Kenali Paransori"
  ]
 ],
 "es": [
  [
   "noSongs",
   "No se encontraron archivos MP3",
   "No hay archivos MP3"
  ],
  [
   "addMusic",
   "Agrega archivos de música a tu dispositivo",
   "Añade música a tu dispositivo"
  ],
  [
   "editSong",
   "Editar info de la canción",
   "Editar datos de la canción"
  ],
  [
   "songInfo",
   "Info de la canción",
   "Detalles de la canción"
  ],
  [
   "ringtone",
   "Poner como tono",
   "Establecer como tono"
  ],
  [
   "widget",
   "Widget de inicio",
   "Widget de la pantalla de inicio"
  ],
  [
   "noRecentSongs",
   "No hay canciones recientes",
   "Todavía no has escuchado ninguna canción"
  ],
  [
   "playMusic",
   "Pon algo de música",
   "Escucha algo de música"
  ],
  [
   "clearRecent",
   "Borrar recientes",
   "Borrar historial"
  ],
  [
   "clearRecentConfirm",
   "¿Borrar todas las canciones recientes?",
   "¿Quieres borrar todo el historial de reproducción?"
  ],
  [
   "ringtoneFailed",
   "No se pudo poner el tono",
   "No se pudo establecer el tono"
  ],
  [
   "promoEnter",
   "Ingresa el código promocional",
   "Introduce el código promocional"
  ],
  [
   "permissionRequired",
   "Se necesita permiso de almacenamiento",
   "Se necesita acceso a tus archivos"
  ],
  [
   "permissionMessage",
   "Se necesita permiso de almacenamiento\npara buscar archivos MP3.",
   "Necesitamos acceso a tus archivos\npara encontrar tu música MP3."
  ],
  [
   "allowPermission",
   "Dar permiso",
   "Permitir acceso"
  ],
  [
   "playNext",
   "Reproducir después",
   "Reproducir a continuación"
  ],
  [
   "flashlightError",
   "Error de la linterna",
   "No se pudo encender la linterna"
  ],
  [
   "reviewMessage",
   "¡Déjanos una calificación!\nNos ayuda a mejorar la app 😊",
   "Tu valoración nos ayuda\na seguir mejorando la app 😊"
  ],
  [
   "autoStopFormat",
   "Se apagará solo en {time}",
   "Se detendrá automáticamente en {time}"
  ],
  [
   "autoStopCountdownSuffix",
   "para apagarse",
   "para detenerse"
  ],
  [
   "playlistNameHint",
   "Nombre de la playlist",
   "Nombre de la lista"
  ],
  [
   "lyricsLoading",
   "Cargando letra...",
   "Cargando la letra..."
  ],
  [
   "radioSelectCountry",
   "Elegir país",
   "Seleccionar país"
  ],
  [
   "radioSchedule",
   "Programación",
   "Programar"
  ],
  [
   "sleepTimerDesc",
   "Se apaga solo después del tiempo elegido",
   "La reproducción se detendrá al terminar el tiempo elegido"
  ],
  [
   "sleepTimerActiveDesc",
   "El temporizador está activo",
   "El temporizador está en marcha"
  ]
 ]
}

def raw(s):
    return json.dumps(s, ensure_ascii=False)[1:-1]

def main():
    ok = True; out = {}; total = 0
    for code, pairs in CHANGES.items():
        path = os.path.join('lib', 'l10n', 'app_%s.arb' % code)
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
        b = open(path, 'rb').read(); crlf = b'\r\n' in b
        text = b.decode('utf-8').replace('\r\n', '\n'); changed = 0
        for key, old, new in pairs:
            o = '"%s": "%s"' % (key, raw(old)); n = '"%s": "%s"' % (key, raw(new))
            if text.count(n) >= 1 and text.count(o) == 0: continue
            if text.count(o) >= 1:  # 같은 키가 두 번 적힌 파일도 있어서 둘 다 바꿈
                text = text.replace(o, n); changed += 1; print('✔', code, key, ':', new.replace('\n', ' / '))
            else:
                print('❌', code, key, ': 지금 문구가 달라서 못 바꿨어요'); ok = False
        try:
            json.loads(text)
        except Exception as e:
            print('❌', path, '모양이 깨졌어요:', e); ok = False
        if changed:
            out[path] = (text, crlf); total += changed
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if not out:
        print('이미 적용돼 있어요'); return 0
    for p, (t, crlf) in out.items():
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요: %d곳 바꿈 (%d개 파일)' % (total, len(out)))
    return 0

if __name__ == '__main__':
    sys.exit(main())
