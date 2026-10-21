# -*- coding: utf-8 -*-
# 파란소리 소개 '파란소리가 전하고 싶은 마음' 글을 짧게 (23개 언어)
import os, sys, json

L10N = os.path.join('lib', 'l10n')

# (첫 줄, 둘째 문단)
WISH = {
    'ko': ('하루의 모든 순간, 좋아하는 소리로 일상을 채워보세요.',
           '파란소리는 누구나 복잡함 없이 소리를 즐길 수 있는 공간입니다. 한국에서 시작해 전 세계의 일상에 작은 즐거움과 여유를 전합니다.'),
    'en': ('Fill every moment of your day with the sounds you love.',
           'Paransori is a place where anyone can enjoy sound, simply and without fuss. Born in Korea, it brings a little joy and ease to everyday life around the world.'),
    'ja': ('一日のすべての瞬間を、好きな音で満たしてみませんか。',
           'Paransoriは、誰もが迷わず気軽に音を楽しめる場所です。韓国から始まり、世界中の毎日に小さな楽しさとゆとりを届けます。'),
    'zh': ('让喜欢的声音，填满一天中的每个时刻。',
           'Paransori 是一个让每个人都能轻松享受声音的地方。它从韩国出发，为世界各地的日常带来小小的快乐与从容。'),
    'zh_Hant': ('讓喜歡的聲音，填滿一天中的每個時刻。',
                'Paransori 是一個讓每個人都能輕鬆享受聲音的地方。它從韓國出發，為世界各地的日常帶來小小的快樂與從容。'),
    'de': ('Füll jeden Moment deines Tages mit den Klängen, die du liebst.',
           'Paransori ist ein Ort, an dem jeder Klänge ganz unkompliziert genießen kann. In Korea entstanden, bringt es ein wenig Freude und Gelassenheit in den Alltag auf der ganzen Welt.'),
    'es': ('Llena cada momento de tu día con los sonidos que te gustan.',
           'Paransori es un lugar donde cualquiera puede disfrutar del sonido, sin complicaciones. Nació en Corea y lleva un poco de alegría y calma a la vida diaria en todo el mundo.'),
    'fr': ('Remplissez chaque moment de votre journée avec les sons que vous aimez.',
           "Paransori est un espace où chacun peut profiter du son, simplement. Né en Corée, il apporte un peu de joie et de sérénité au quotidien, partout dans le monde."),
    'id': ('Isi setiap momen harimu dengan suara yang kamu sukai.',
           'Paransori adalah tempat di mana siapa pun bisa menikmati suara tanpa ribet. Berawal dari Korea, Paransori membawa sedikit kebahagiaan dan ketenangan ke keseharian di seluruh dunia.'),
    'pt': ('Preencha cada momento do seu dia com os sons que você ama.',
           'O Paransori é um lugar onde qualquer pessoa pode aproveitar o som, sem complicação. Nascido na Coreia, ele leva um pouco de alegria e tranquilidade ao dia a dia no mundo todo.'),
    'th': ('เติมทุกช่วงเวลาของวันด้วยเสียงที่คุณชอบ',
           'Paransori คือพื้นที่ที่ทุกคนเพลิดเพลินกับเสียงได้อย่างง่ายดาย เริ่มต้นจากเกาหลี และส่งต่อความสุขเล็กๆ กับความผ่อนคลายสู่ชีวิตประจำวันทั่วโลก'),
    'vi': ('Hãy lấp đầy từng khoảnh khắc trong ngày bằng những âm thanh bạn yêu thích.',
           'Paransori là nơi ai cũng có thể tận hưởng âm thanh một cách đơn giản. Bắt đầu từ Hàn Quốc, Paransori mang niềm vui nhỏ và sự thư thái đến cuộc sống thường ngày trên khắp thế giới.'),
    'ru': ('Наполните каждое мгновение дня любимыми звуками.',
           'Paransori — место, где каждый может легко наслаждаться звуками. Появившись в Корее, он дарит немного радости и спокойствия повседневной жизни по всему миру.'),
    'it': ('Riempi ogni momento della tua giornata con i suoni che ami.',
           "Paransori è un luogo dove chiunque può godersi il suono, senza complicazioni. Nato in Corea, porta un po' di gioia e di calma nella vita di ogni giorno, in tutto il mondo."),
    'tr': ('Gününün her anını sevdiğin seslerle doldur.',
           "Paransori, herkesin sesin tadını zahmetsizce çıkarabileceği bir alan. Kore'de doğdu; dünyanın dört bir yanındaki gündelik hayata biraz neşe ve huzur katıyor."),
    'pl': ('Wypełnij każdą chwilę dnia ulubionymi dźwiękami.',
           'Paransori to miejsce, w którym każdy może cieszyć się dźwiękiem bez komplikacji. Powstało w Korei i wnosi odrobinę radości i spokoju w codzienność na całym świecie.'),
    'uk': ('Наповніть кожну мить дня улюбленими звуками.',
           'Paransori — простір, де кожен може легко насолоджуватися звуками. Народжений у Кореї, він дарує трохи радості й спокою повсякденню по всьому світу.'),
    'hi': ('अपने दिन के हर पल को अपनी पसंदीदा आवाज़ों से भर दीजिए।',
           'Paransori ऐसी जगह है जहाँ हर कोई बिना किसी झंझट के आवाज़ों का आनंद ले सकता है। कोरिया से शुरू होकर, यह दुनिया भर की रोज़मर्रा ज़िंदगी में थोड़ी खुशी और सुकून लाता है।'),
    'ro': ('Umple fiecare moment al zilei cu sunetele pe care le iubești.',
           'Paransori este un loc în care oricine se poate bucura de sunet, simplu și fără complicații. Născut în Coreea, aduce puțină bucurie și liniște în viața de zi cu zi, în întreaga lume.'),
    'cs': ('Naplňte každou chvíli dne zvuky, které máte rádi.',
           'Paransori je místo, kde si každý může jednoduše užívat zvuk. Vzniklo v Koreji a přináší trochu radosti a klidu do všedních dnů po celém světě.'),
    'hu': ('Töltsd meg a nap minden pillanatát a kedvenc hangjaiddal.',
           'A Paransori egy hely, ahol bárki egyszerűen élvezheti a hangokat. Koreából indult, és egy kis örömöt és nyugalmat visz a hétköznapokba szerte a világon.'),
    'ar': ('املأ كل لحظة من يومك بالأصوات التي تحبها.',
           'Paransori مساحة يستمتع فيها الجميع بالأصوات ببساطة ودون تعقيد. انطلق من كوريا ليضيف قليلًا من البهجة والراحة إلى الحياة اليومية حول العالم.'),
    'ur': ('اپنے دن کے ہر لمحے کو اپنی پسندیدہ آوازوں سے بھر دیں۔',
           'Paransori ایک ایسی جگہ ہے جہاں ہر کوئی بغیر کسی الجھن کے آوازوں سے لطف اٹھا سکتا ہے۔ کوریا سے شروع ہو کر یہ دنیا بھر کی روزمرہ زندگی میں تھوڑی خوشی اور سکون لاتا ہے۔'),
}


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def set_value(text, key, value, fname):
    lines = text.split('\n')
    hit = [i for i, l in enumerate(lines) if l.strip().startswith('"%s":' % key)]
    if len(hit) != 1:
        print('❌', fname, key, '줄을 못 찾았어요 (찾은 개수: %d) — 아무것도 저장 안 했어요' % len(hit))
        sys.exit(1)
    i = hit[0]
    l = lines[i]
    ind = l[:len(l) - len(l.lstrip())]
    comma = ',' if l.rstrip().endswith(',') else ''
    lines[i] = '%s"%s": %s%s' % (ind, key, json.dumps(value, ensure_ascii=False), comma)
    return '\n'.join(lines)


def main():
    ko, _ = load(os.path.join(L10N, 'app_ko.arb'))
    if json.loads(ko).get('introWish1') == WISH['ko'][0]:
        print('이미 적용돼 있어요')
        return
    out = []
    for lang, (w1, w2) in WISH.items():
        p = os.path.join(L10N, 'app_%s.arb' % lang)
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        t, c = load(p)
        t = set_value(t, 'introWish1', w1, os.path.basename(p))
        t = set_value(t, 'introWish2', w2, os.path.basename(p))
        try:
            d = json.loads(t)
            assert d['introWish1'] == w1 and d['introWish2'] == w2
        except Exception as e:
            print('❌', os.path.basename(p), '번역 파일 모양 확인 실패:', e, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        out.append((p, t, c))
        print('✔', os.path.basename(p))
    for p, t, c in out:
        if c:
            t = t.replace('\n', '\r\n')
        with open(p, 'wb') as f:
            f.write(t.encode('utf-8'))
    print('✔ 저장했어요 (%d개 파일)' % len(out))


main()
