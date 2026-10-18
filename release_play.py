# -*- coding: utf-8 -*-
# 빌드 → 구글 플레이 프로덕션에 올리기 → 검토 보내기 (관리형 게시라 승인 후 직접 '게시')
# 실행: python release_play.py   (mp3_player_new 폴더에서) — 아무것도 안 물어보고 끝까지
#       python release_play.py "업데이트 내용"   ← 내용을 직접 넣고 싶을 때만
#  1) build_release.py 로 버전 번호 +1 하고 .aab 만들기
#  2) 업데이트 내용: 적은 게 없으면 16개 언어 앱 소개 (아래 FULL_NOTES, 스토어에 있는 언어만)
#  3) 플레이 콘솔 프로덕션에 올리고 검토 보내기 → 승인되면 게시 개요에서 직접 '게시'
# 처음 한 번 준비: play-key.json (서비스 계정 키) 를 이 폴더에 두기
import os, sys, subprocess, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)

PACKAGE = 'kr.ssing.catsong'
KEY_FILE = 'play-key.json'
AAB = os.path.join('build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab')
TRACK = 'production'
DEFAULT_NOTES = '작은 개선과 오류 수정'
# 따로 적은 게 없으면 16개 언어 전체 소개를 출시 노트로 (언어마다 500자까지)
# 스토어 등록 정보에 있는 언어만 보내요 (스페인어는 es-419 · es-ES 중 스토어에 있는 것)
FULL_NOTES = {
    'ko-KR': "파란소리 – 음악, 라디오, 자연소리를 하나로\n- 16개 언어 지원 (설정 → 언어에서 앱 언어 바꾸기)\n- MP3·동영상 플레이어, 가사 보기와 가사 카드 공유\n- 장르별 정렬·장르 골라 듣기, 곡 정보에서 장르 수정\n- 한국과 100여 개 나라 라디오, 편성표까지\n- 휴식·집중·잠을 위한 자연소리와 소리 믹스\n- 파란포토 배경 (고정·랜덤, 컬러·흑백·세피아·필름)\n- 수면 타이머, 아침 알람, 홈 화면 위젯\n- TV·스피커로 보내기, 이퀄라이저, 녹음\n- 다크 모드, 포인트 색, 글꼴로 나만의 앱 꾸미기",
    'en-US': "Paransori – music, radio and nature sounds in one app\n- Now in 16 languages (Settings → Language)\n- MP3 & video player with synced lyrics and lyric cards\n- Sort and play by genre, edit song genres\n- Live radio from Korea and 100+ countries\n- Nature sounds & sound mix for rest, focus and sleep\n- Paran Photo backgrounds in color, B&W, sepia or film\n- Sleep timer, morning alarm and home screen widgets\n- Cast to TV and speakers, equalizer, recordings\n- Dark mode, point colors and fonts",
    'ja-JP': "パランソリ – 音楽・ラジオ・自然音をひとつのアプリで\n- 16言語に対応(設定 → 言語でアプリの言語を変更)\n- MP3・動画プレーヤー、歌詞表示と歌詞カードの共有\n- ジャンル別の並べ替え・再生、曲情報でジャンルを編集\n- 韓国と100か国以上のライブラジオ、番組表つき\n- 休息・集中・睡眠のための自然音とサウンドミックス\n- パランフォト背景(固定・ランダム、カラー・モノクロ・セピア・フィルム)\n- スリープタイマー、モーニングアラーム、ホーム画面ウィジェット\n- テレビ・スピーカーへのキャスト、イコライザー、録音\n- ダークモード、ポイントカラー、フォントで自分好みに",
    'zh-TW': "Paransori – 音樂、廣播、大自然聲音一次擁有\n- 支援 16 種語言(設定 → 語言可切換)\n- MP3・影片播放器，歌詞顯示與歌詞卡片分享\n- 依類型排序與播放，可在歌曲資訊中編輯類型\n- 韓國與 100 多個國家的線上廣播，附節目表\n- 放鬆、專注、助眠的大自然聲音與混音\n- Paran Photo 背景(固定・隨機，彩色・黑白・復古・底片)\n- 睡眠定時、晨間鬧鐘、桌面小工具\n- 投放至電視與喇叭、等化器、錄音\n- 深色模式、主題色與字型，打造專屬風格",
    'zh-CN': "Paransori – 音乐、电台、大自然声音一次拥有\n- 支持 16 种语言(设置 → 语言可切换)\n- MP3・视频播放器，歌词显示与歌词卡片分享\n- 按类型排序与播放，可在歌曲信息中编辑类型\n- 韩国与 100 多个国家的在线电台，附节目表\n- 放松、专注、助眠的大自然声音与混音\n- Paran Photo 背景(固定・随机，彩色・黑白・复古・胶片)\n- 睡眠定时、早晨闹钟、桌面小组件\n- 投放到电视与音箱、均衡器、录音\n- 深色模式、主题色与字体，打造专属风格",
    'de-DE': "Paransori – Musik, Radio und Naturklänge in einer App\n- Jetzt auf Deutsch und in 15 weiteren Sprachen\n- MP3- & Videoplayer mit Songtexten und Songtext-Karten\n- Nach Genre sortieren und abspielen\n- Live-Radio aus Korea und über 100 Ländern\n- Naturklänge & Sound-Mix zum Entspannen und Schlafen\n- Paran Photo Hintergründe in Farbe, S/W, Sepia oder Film\n- Sleep-Timer, Wecker und Widgets\n- Auf TV & Lautsprecher streamen, Equalizer, Aufnahmen\n- Dunkelmodus, Akzentfarben und Schriften",
    'fr-FR': "Paransori – musique, radio et sons de la nature dans une seule app\n- Disponible en français et dans 15 autres langues\n- Lecteur MP3 et vidéo avec paroles et cartes de paroles\n- Tri et écoute par genre\n- Radio en direct de Corée et de plus de 100 pays\n- Sons de la nature et mix pour se détendre et dormir\n- Fonds Paran Photo : couleur, N&B, sépia ou film\n- Minuterie de sommeil, réveil et widgets\n- Diffusion sur TV et enceintes, égaliseur, enregistrements\n- Mode sombre, couleurs et polices",
    'es-419': "Paransori – música, radio y sonidos naturales en una sola app\n- Ahora en español y otros 15 idiomas\n- Reproductor de MP3 y video con letras y tarjetas de letras\n- Ordena y escucha por género\n- Radio en vivo de Corea y más de 100 países\n- Sonidos naturales y mezclas para relajarte y dormir\n- Fondos Paran Photo: color, B/N, sepia o película\n- Temporizador, alarma y widgets\n- Envía a TV y bocinas, ecualizador, grabaciones\n- Modo oscuro, colores y fuentes",
    'es-ES': "Paransori – música, radio y sonidos naturales en una sola app\n- Ahora en español y otros 15 idiomas\n- Reproductor de MP3 y video con letras y tarjetas de letras\n- Ordena y escucha por género\n- Radio en vivo de Corea y más de 100 países\n- Sonidos naturales y mezclas para relajarte y dormir\n- Fondos Paran Photo: color, B/N, sepia o película\n- Temporizador, alarma y widgets\n- Envía a TV y bocinas, ecualizador, grabaciones\n- Modo oscuro, colores y fuentes",
    'pt-BR': "Paransori – música, rádio e sons da natureza em um só app\n- Agora em português e mais 15 idiomas\n- Player de MP3 e vídeo com letras e cards de letras\n- Organize e ouça por gênero\n- Rádio ao vivo da Coreia e de mais de 100 países\n- Sons da natureza e mixes para relaxar e dormir\n- Fundos Paran Photo: cor, P&B, sépia ou filme\n- Timer para dormir, despertador e widgets\n- Transmita para TV e caixas de som, equalizador, gravações\n- Modo escuro, cores e fontes",
    'id': "Paransori – musik, radio, dan suara alam dalam satu aplikasi\n- Kini dalam Bahasa Indonesia dan 15 bahasa lain\n- Pemutar MP3 & video dengan lirik dan kartu lirik\n- Urutkan dan putar berdasarkan genre\n- Radio langsung dari Korea dan 100+ negara\n- Suara alam & mix untuk santai dan tidur\n- Latar Paran Photo: warna, hitam putih, sepia, atau film\n- Timer tidur, alarm pagi, dan widget\n- Kirim ke TV & speaker, equalizer, rekaman\n- Mode gelap, warna aksen, dan font",
    'vi': "Paransori – nhạc, radio và âm thanh thiên nhiên trong một ứng dụng\n- Đã có tiếng Việt và 15 ngôn ngữ khác\n- Trình phát MP3 & video, lời bài hát và thẻ lời bài hát\n- Sắp xếp và nghe theo thể loại\n- Radio trực tiếp từ Hàn Quốc và hơn 100 quốc gia\n- Âm thanh thiên nhiên & bản trộn để thư giãn, ngủ ngon\n- Hình nền Paran Photo: màu, đen trắng, sepia, film\n- Hẹn giờ tắt, báo thức buổi sáng, tiện ích\n- Phát lên TV & loa, bộ chỉnh âm, ghi âm\n- Chế độ tối, màu nhấn và phông chữ",
    'th': "Paransori – เพลง วิทยุ และเสียงธรรมชาติในแอปเดียว\n- รองรับภาษาไทยและอีก 15 ภาษา\n- เครื่องเล่น MP3 และวิดีโอ พร้อมเนื้อเพลงและการ์ดเนื้อเพลง\n- เรียงและฟังตามแนวเพลง\n- วิทยุสดจากเกาหลีและกว่า 100 ประเทศ\n- เสียงธรรมชาติและมิกซ์เสียงเพื่อการพักผ่อนและนอนหลับ\n- พื้นหลัง Paran Photo: สี ขาวดำ ซีเปีย หรือฟิล์ม\n- ตั้งเวลาปิด นาฬิกาปลุก และวิดเจ็ต\n- ส่งไปยังทีวีและลำโพง อีควอไลเซอร์ บันทึกเสียง\n- โหมดมืด สีหลัก และฟอนต์",
    'ru-RU': "Paransori – музыка, радио и звуки природы в одном приложении\n- Теперь на 16 языках (Настройки → Язык)\n- MP3 и видеоплеер с синхронизированным текстом и карточками\n- Сортировка и воспроизведение по жанрам, правка жанров\n- Живое радио из Кореи и более 100 стран\n- Звуки природы и микс для отдыха, концентрации и сна\n- Фоны Paran Photo: цвет, Ч/Б, сепия или плёнка\n- Таймер сна, утренний будильник и виджеты\n- Трансляция на ТВ и колонки, эквалайзер, записи\n- Тёмная тема, цвета акцента и шрифты",
    'it-IT': "Paransori – musica, radio e suoni della natura in un'unica app\n- Ora in 16 lingue (Impostazioni → Lingua)\n- Lettore MP3 e video con testi sincronizzati e card\n- Ordina, riproduci e modifica per genere\n- Radio in diretta dalla Corea e da oltre 100 paesi\n- Suoni della natura e mix per relax e sonno\n- Sfondi Paran Photo a colori, B/N, seppia o pellicola\n- Timer di spegnimento, sveglia e widget\n- Cast su TV e altoparlanti, equalizzatore, registrazioni\n- Tema scuro, colori di accento e font",
    'tr-TR': "Paransori – müzik, radyo ve doğa sesleri tek uygulamada\n- Artık 16 dilde (Ayarlar → Dil)\n- Senkronize sözlü MP3 ve video oynatıcı, söz kartları\n- Türe göre sırala, çal ve türleri düzenle\n- Kore ve 100'den fazla ülkeden canlı radyo\n- Dinlenme, odak ve uyku için doğa sesleri ve ses miksi\n- Renkli, siyah-beyaz, sepya veya film Paran Photo arka planları\n- Uyku zamanlayıcısı, sabah alarmı ve ana ekran widget'ları\n- TV'ye yansıtma, ekolayzır, kayıtlar\n- Koyu mod, vurgu renkleri ve yazı tipleri",
    'pl-PL': "Paransori – muzyka, radio i odgłosy natury w jednej aplikacji\n- Teraz w 16 językach (Ustawienia → Język)\n- Odtwarzacz MP3 i wideo z synchronizowanymi tekstami i kartami\n- Sortuj, odtwarzaj i edytuj według gatunku\n- Radio na żywo z Korei i ponad 100 krajów\n- Odgłosy natury i miks do relaksu, skupienia i snu\n- Tła Paran Photo: kolor, cz-b, sepia lub film\n- Wyłącznik czasowy, poranny budzik i widżety\n- Przesyłanie na TV i głośniki, korektor, nagrania\n- Tryb ciemny, kolory akcentu i czcionki",
}


def keep_key_out_of_github():
    """키 파일이 깃허브에 올라가지 않게 .gitignore 에 넣기"""
    gi = '.gitignore'
    text = open(gi, 'rb').read().decode('utf-8') if os.path.exists(gi) else ''
    if KEY_FILE not in text.split():
        nl = '\r\n' if '\r\n' in text else '\n'
        add = ('' if text.endswith(('\n', '\r\n')) or not text else nl) + KEY_FILE + nl
        open(gi, 'ab').write(add.encode('utf-8'))
        print(f'✔ .gitignore 에 {KEY_FILE} 를 넣었어요 (키가 깃허브에 안 올라가게)')


def main():
    if not os.path.exists('pubspec.yaml'):
        print('❌ mp3_player_new 폴더에서 실행해 주세요.'); sys.exit(1)
    if not os.path.exists(KEY_FILE):
        print(f'❌ {KEY_FILE} 가 없어요. 서비스 계정 키 파일을 이 폴더에 {KEY_FILE} 이름으로 넣어 주세요.'); sys.exit(1)
    keep_key_out_of_github()
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print('❌ 처음 한 번 설치가 필요해요:  pip install google-api-python-client google-auth'); sys.exit(1)

    # 1) 빌드
    r = subprocess.run([sys.executable, 'build_release.py'])
    if r.returncode != 0 or not os.path.exists(AAB):
        print('❌ 빌드가 안 돼서 올리지 않았어요.'); sys.exit(1)

    # 2) 업데이트 내용
    # 묻지 않고 바로: 명령어 뒤에 적은 게 있으면 그걸, 없으면 기본 문구
    notes = ' '.join(sys.argv[1:]).strip() or DEFAULT_NOTES
    if len(notes) > 500:
        print('❌ 업데이트 내용은 500자까지예요.'); sys.exit(1)
    print(f'✔ 업데이트 내용: {notes}')

    # 3) 플레이 콘솔에 올리기
    try:
        creds = service_account.Credentials.from_service_account_file(
            KEY_FILE, scopes=['https://www.googleapis.com/auth/androidpublisher'])
        svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)
        edits = svc.edits()
        eid = edits.insert(packageName=PACKAGE, body={}).execute()['id']
        print('… 올리는 중이에요 (1~2분)')
        media = MediaFileUpload(AAB, mimetype='application/octet-stream', resumable=True)
        vc = edits.bundles().upload(packageName=PACKAGE, editId=eid, media_body=media).execute()['versionCode']
        print(f'✔ 앱 번들 올림 (버전 코드 {vc})')
        # 출시 노트는 스토어 등록 정보에 있는 언어만 (없는 언어까지 보내면 오류가 날 수 있어서)
        try:
            have = {x['language'] for x in edits.listings().list(packageName=PACKAGE, editId=eid).execute().get('listings', [])}
        except Exception:
            have = set()
        notes_all = [{'language': k, 'text': v} for k, v in FULL_NOTES.items() if not have or k in have]
        skipped = [k for k in FULL_NOTES if have and k not in have]
        if not sys.argv[1:]:
            print(f'✔ 출시 노트 {len(notes_all)}개 언어' + (f' (스토어에 아직 없는 언어는 빼요: {", ".join(skipped)})' if skipped else ''))
        edits.tracks().update(
            packageName=PACKAGE, editId=eid, track=TRACK,
            body={'track': TRACK, 'releases': [{
                'versionCodes': [str(vc)],
                'status': 'completed',
                # 명령어 뒤에 적은 게 있으면 한국어로 그걸, 없으면 16개 언어 전체 소개
                'releaseNotes': ([{'language': 'ko-KR', 'text': notes}] if sys.argv[1:] else notes_all),
            }]}).execute()
        print('✔ 프로덕션에 새 버전 넣음')
        # 먼저 '저장만' → 이 앱이 '자동으로 검토에 보내는' 설정이라 안 되면 그냥 저장(=검토로 감)
        try:
            edits.commit(packageName=PACKAGE, editId=eid, changesNotSentForReview=True).execute()
            print('✔ 저장했어요! 플레이 콘솔 → 게시 개요 → "검토를 위해 변경사항 전송"을 눌러 주세요.')
        except Exception as e:
            if 'sent for review automatically' not in str(e):
                raise
            edits.commit(packageName=PACKAGE, editId=eid).execute()
            print('✔ 검토 보냈어요! (관리형 게시라 승인돼도 게시 개요에서 직접 "게시"를 눌러야 스토어에 나와요)')
    except Exception as e:
        msg = str(e)
        print('❌ 올리지 못했어요.')
        if '403' in msg or 'permission' in msg.lower():
            print('   권한 문제예요. 플레이 콘솔 → 사용자 및 권한에서 서비스 계정에 출시 권한이 있는지 확인해 주세요.')
            print('   (처음 초대한 뒤에는 하루 정도 지나야 될 때도 있어요)')
        elif 'versionCode' in msg or 'already been used' in msg:
            print('   같은 버전 번호가 이미 올라가 있어요. 다시 실행하면 번호를 올려서 새로 만들어요.')
        else:
            print('  ', msg[:400])
        sys.exit(1)


main()