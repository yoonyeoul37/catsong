# -*- coding: utf-8 -*-
# 파란소리 소개 화면 '이름 이야기' 글 바꾸기 (16개 언어 번역 파일) — 다른 글은 그대로
import os, re, sys, json
sys.stdout.reconfigure(encoding='utf-8')
D = os.path.join('lib', 'l10n')

S = {
'ko': "'파란소리'라는 이름에는 맑은 하늘과 푸른 바다가 주는 청량함, 시원한 바람이 전하는 상쾌함, 그리고 자연 속에서 느끼는 편안함을 담았습니다.\n\n영문 이름 'Paransori'는 우리말 '파란소리'를 영어로 번역하지 않고, 한글의 소리를 로마자로 옮긴 이름입니다. '파란'은 'Paran', '소리'는 'Sori'로 표기하고, 하나의 이름으로 이었습니다.\n\n우리말이 가진 고유한 느낌을 간직하면서, 세계 어디에서나 같은 이름으로 기억되기를 바라는 마음을 담았습니다.",
'en': "In Korean, \"paran\" means blue, and \"sori\" means sound. Together, they form \"Paransori\" — a name inspired by clear blue skies, peaceful seas, refreshing breezes, and the comfort of nature.\n\nRather than translating our name into \"Blue Sound,\" we chose to preserve its original Korean pronunciation, written in the Latin alphabet as \"Paransori.\"\n\nBorn in Korea, we hope this name will become familiar to people around the world, bringing a little more calm and joy to everyday life.",
'ja': "韓国語で「パラン（paran）」は青、「ソリ（sori）」は音という意味です。ふたつを合わせた「Paransori」は、澄んだ青空や穏やかな海、さわやかな風、そして自然の中で感じるやすらぎから生まれた名前です。\n\n「Blue Sound」と訳すのではなく、韓国語の響きをそのまま大切にしたくて、アルファベットで「Paransori」と表記しました。\n\n韓国で生まれたこの名前が世界中の人に親しまれ、毎日の暮らしに少しの落ち着きと楽しさを届けられたらうれしいです。",
'zh': "在韩语中，“paran”是蓝色，“sori”是声音。两者合在一起，就是“Paransori”——这个名字的灵感来自湛蓝的天空、平静的大海、清爽的微风，以及大自然带来的舒适。\n\n我们没有把它翻译成“Blue Sound”，而是保留了韩语原本的发音，用拉丁字母写作“Paransori”。\n\n这个诞生于韩国的名字，希望能被世界各地的人们熟悉，为每一天带来多一点平静与快乐。",
'zh_Hant': "在韓語中，「paran」是藍色，「sori」是聲音。兩者合在一起，就是「Paransori」——這個名字的靈感來自湛藍的天空、平靜的大海、清爽的微風，以及大自然帶來的舒適。\n\n我們沒有把它翻譯成「Blue Sound」，而是保留了韓語原本的發音，用拉丁字母寫作「Paransori」。\n\n這個誕生於韓國的名字，希望能被世界各地的人們熟悉，為每一天帶來多一點平靜與快樂。",
'de': "Auf Koreanisch bedeutet „paran“ blau und „sori“ Klang. Zusammen ergeben sie „Paransori“ – ein Name, inspiriert von klarem blauem Himmel, ruhigem Meer, frischer Brise und der Geborgenheit der Natur.\n\nStatt unseren Namen mit „Blue Sound“ zu übersetzen, haben wir die ursprüngliche koreanische Aussprache bewahrt und sie in lateinischen Buchstaben als „Paransori“ geschrieben.\n\nUnser Name stammt aus Korea – und wir hoffen, dass er Menschen auf der ganzen Welt vertraut wird und ihrem Alltag ein wenig mehr Ruhe und Freude schenkt.",
'es': "En coreano, \"paran\" significa azul y \"sori\" significa sonido. Juntas forman \"Paransori\", un nombre inspirado en los cielos azules y despejados, los mares tranquilos, la brisa fresca y la calma de la naturaleza.\n\nEn lugar de traducir nuestro nombre como \"Blue Sound\", preferimos conservar su pronunciación coreana original, escrita en alfabeto latino como \"Paransori\".\n\nEste nombre nació en Corea, y esperamos que se vuelva familiar para personas de todo el mundo y aporte un poco más de calma y alegría al día a día.",
'fr': "En coréen, « paran » signifie bleu et « sori » signifie son. Ensemble, ils forment « Paransori » : un nom inspiré du ciel bleu et dégagé, de la mer paisible, de la brise rafraîchissante et du réconfort de la nature.\n\nPlutôt que de traduire notre nom par « Blue Sound », nous avons choisi de garder sa prononciation coréenne d’origine, écrite en alphabet latin : « Paransori ».\n\nCe nom est né en Corée, et nous espérons qu’il deviendra familier partout dans le monde, en apportant un peu plus de calme et de joie au quotidien.",
'it': "In coreano, \"paran\" significa blu e \"sori\" significa suono. Insieme formano \"Paransori\": un nome ispirato ai cieli azzurri e limpidi, al mare calmo, alla brezza fresca e alla serenità della natura.\n\nInvece di tradurre il nostro nome in \"Blue Sound\", abbiamo scelto di mantenere la sua pronuncia coreana originale, scritta in alfabeto latino come \"Paransori\".\n\nQuesto nome è nato in Corea e speriamo che diventi familiare a persone di tutto il mondo, portando un po’ più di calma e di gioia nella vita di ogni giorno.",
'pt': "Em coreano, \"paran\" significa azul e \"sori\" significa som. Juntas, formam \"Paransori\" — um nome inspirado no céu azul e limpo, no mar tranquilo, na brisa fresca e no conforto da natureza.\n\nEm vez de traduzir nosso nome como \"Blue Sound\", escolhemos manter a pronúncia original em coreano, escrita com o alfabeto latino como \"Paransori\".\n\nEste nome nasceu na Coreia, e esperamos que ele se torne familiar para pessoas do mundo todo, trazendo um pouco mais de calma e alegria ao dia a dia.",
'pl': "Po koreańsku „paran” oznacza niebieski, a „sori” – dźwięk. Razem tworzą „Paransori” – nazwę zainspirowaną czystym błękitnym niebem, spokojnym morzem, orzeźwiającą bryzą i ukojeniem, jakie daje natura.\n\nZamiast tłumaczyć naszą nazwę jako „Blue Sound”, postanowiliśmy zachować jej oryginalne koreańskie brzmienie, zapisane alfabetem łacińskim jako „Paransori”.\n\nTa nazwa narodziła się w Korei. Mamy nadzieję, że stanie się bliska ludziom na całym świecie i wniesie do codzienności trochę więcej spokoju i radości.",
'ru': "По-корейски «паран» значит «синий», а «сори» — «звук». Вместе они образуют Paransori — название, вдохновлённое ясным голубым небом, спокойным морем, свежим ветром и умиротворением природы.\n\nМы не стали переводить его как «Blue Sound», а сохранили настоящее корейское звучание, записав его латиницей: Paransori.\n\nЭто название родилось в Корее, и мы надеемся, что оно станет близким людям по всему миру и добавит в каждый день немного больше спокойствия и радости.",
'tr': "Korecede \"paran\" mavi, \"sori\" ise ses demektir. İkisi bir araya gelerek \"Paransori\"yi oluşturur: berrak mavi gökyüzünden, sakin denizlerden, ferahlatıcı esintilerden ve doğanın huzurundan ilham alan bir isim.\n\nAdımızı \"Blue Sound\" olarak çevirmek yerine, Korece özgün telaffuzunu koruyup Latin harfleriyle \"Paransori\" olarak yazmayı seçtik.\n\nKore'de doğan bu ismin dünyanın dört bir yanındaki insanlara tanıdık gelmesini ve günlük hayata biraz daha huzur ve neşe katmasını diliyoruz.",
'id': "Dalam bahasa Korea, \"paran\" berarti biru dan \"sori\" berarti suara. Keduanya membentuk \"Paransori\" — nama yang terinspirasi dari langit biru yang cerah, laut yang tenang, angin yang menyegarkan, dan ketenangan alam.\n\nAlih-alih menerjemahkan nama kami menjadi \"Blue Sound\", kami memilih mempertahankan pelafalan asli bahasa Korea, yang ditulis dengan huruf Latin sebagai \"Paransori\".\n\nNama ini lahir di Korea, dan kami berharap nama ini menjadi akrab bagi orang-orang di seluruh dunia, membawa sedikit lebih banyak ketenangan dan kegembiraan dalam keseharian.",
'vi': "Trong tiếng Hàn, \"paran\" nghĩa là màu xanh lam, còn \"sori\" nghĩa là âm thanh. Ghép lại, chúng tạo thành \"Paransori\" — cái tên lấy cảm hứng từ bầu trời xanh trong, biển cả êm đềm, những làn gió mát lành và sự dễ chịu của thiên nhiên.\n\nThay vì dịch tên thành \"Blue Sound\", chúng tôi chọn giữ nguyên cách phát âm tiếng Hàn và viết bằng chữ cái Latinh là \"Paransori\".\n\nCái tên này ra đời tại Hàn Quốc, và chúng tôi mong nó sẽ trở nên thân quen với mọi người trên khắp thế giới, mang thêm một chút bình yên và niềm vui vào cuộc sống mỗi ngày.",
'th': "ในภาษาเกาหลี \"paran\" แปลว่าสีฟ้า และ \"sori\" แปลว่าเสียง เมื่อรวมกันจึงเป็น \"Paransori\" ชื่อที่ได้แรงบันดาลใจจากท้องฟ้าสีฟ้าใส ทะเลที่สงบ สายลมที่สดชื่น และความผ่อนคลายจากธรรมชาติ\n\nแทนที่จะแปลชื่อเป็น \"Blue Sound\" เราเลือกเก็บเสียงอ่านภาษาเกาหลีดั้งเดิมไว้ แล้วเขียนด้วยตัวอักษรละตินว่า \"Paransori\"\n\nชื่อนี้เกิดขึ้นที่เกาหลี และเราหวังว่าจะเป็นชื่อที่คุ้นเคยสำหรับผู้คนทั่วโลก พร้อมเติมความสงบและความสุขเล็กๆ ให้กับทุกวัน",
}
LABEL_EN = 'The story behind our name'

pat = lambda key: re.compile(r'("' + key + r'"\s*:\s*)"(?:[^"\\]|\\.)*"')
if not os.path.isdir(D):
    print('❌ 폴더를 못 찾았어요:', D); sys.exit(1)

out = {}
done = 0
for lang, text in S.items():
    p = os.path.join(D, f'app_{lang}.arb')
    if not os.path.exists(p):
        print(f'❌ {p} 파일이 없어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    if json.loads(raw).get('introNameStory') == text:
        done += 1
        continue
    rep = lambda m, t=text: m.group(1) + json.dumps(t, ensure_ascii=False)
    new, n = pat('introNameStory').subn(rep, raw)
    if n != 1:
        print(f'❌ {lang}: introNameStory를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    if lang == 'en':
        new, n2 = pat('introNameLabel').subn(lambda m: m.group(1) + json.dumps(LABEL_EN), new)
        if n2 != 1:
            print('❌ en: introNameLabel을 못 찾았어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    try:
        if json.loads(new)['introNameStory'] != text: raise ValueError
    except Exception:
        print(f'❌ {lang}: 바꾼 뒤 파일 확인 실패. 아무것도 저장 안 했어요.'); sys.exit(1)
    out[p] = new
    print('✔', lang)

if not out:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, new in out.items():
    open(p, 'wb').write(new.encode('utf-8'))
print(f'저장했어요. ({len(out)}개 언어)')
