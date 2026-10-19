# -*- coding: utf-8 -*-
# 파란소리 소개 화면: '소리와 함께하는 일상'·'파란소리가 전하고 싶은 마음' 본문만 바꾸기 (16개 언어)
# 제목·첫 인사·마무리·'파란소리에 담긴 의미'·'파란소리에서 만나는 소리'·디자인은 그대로
import os, re, sys, json
sys.stdout.reconfigure(encoding='utf-8')
D = os.path.join('lib', 'l10n')
K = ['introEveryday1', 'introEveryday2', 'introWish1', 'introWish2']
T = {
'ko': [
 "파란소리는 일상의 다양한 순간에 편안하게 함께하고 싶습니다.",
 "음악 한 곡, 익숙한 라디오 방송, 잔잔한 빗소리 하나가 평범한 하루를 조금 더 기분 좋게 만들어 줄 수 있으니까요. 그래서 파란소리는 복잡함은 덜고, 듣는 즐거움은 더해 누구나 쉽고 편안하게 사용할 수 있는 소리의 공간을 만들어가고 있습니다.",
 "좋아하는 소리를 듣는 시간은 생각보다 우리 가까이에 있습니다. 아침을 시작할 때도, 일하는 중에도, 하루를 마무리하는 조용한 밤에도.\n\n파란소리는 누구나 원하는 소리를 쉽고 편안하게 만날 수 있기를 바랍니다. 다양한 소리를 하나의 공간에 담고, 듣는 순간만큼은 복잡함 없이 온전히 즐길 수 있도록 만들어가고 있습니다.",
 "한국에서 시작된 파란소리가 세계 여러 곳의 사람들과 함께하며, 저마다의 일상에 작은 즐거움과 여유를 더할 수 있기를 바랍니다."],
'en': [
 "Paransori hopes to be a comfortable companion in all kinds of everyday moments.",
 "A single song, a familiar radio show, or the soft sound of rain can make an ordinary day feel a little better. That's why we're building Paransori as a space for sound with less complexity and more joy in listening — easy and comfortable for anyone to use.",
 "Time with the sounds we love is closer than we think — as the morning begins, in the middle of work, and on quiet nights as the day winds down.\n\nWe hope everyone can find the sounds they want, easily and comfortably. So we bring many kinds of sound together in one place, letting you simply enjoy every moment of listening, free from complexity.",
 "Paransori began in Korea, and we hope it can be part of people's lives around the world, adding a little joy and ease to every day."],
'ja': [
 "Paransoriは、毎日のいろいろな瞬間に、心地よく寄り添いたいと思っています。",
 "一曲の音楽、聴き慣れたラジオ番組、静かな雨の音。それだけで、いつもの一日が少しだけ心地よくなるから。だからParansoriは、わずらわしさを減らして聴く楽しさを増やし、誰でも気軽に心地よく使える音の空間をつくっています。",
 "好きな音を聴く時間は、思っているよりずっと身近にあります。朝のはじまりにも、仕事の合間にも、一日を終える静かな夜にも。\n\n聴きたい音に、誰もが気軽に心地よく出会えるように。Paransoriはさまざまな音をひとつの場所に集め、聴いているあいだは何も気にせず、ただ楽しめる空間をつくっています。",
 "韓国で生まれたParansoriが、世界のいろいろな場所で人々と出会い、それぞれの毎日に小さな楽しさとゆとりを添えられますように。"],
'zh': [
 "Paransori 希望在日常的各种时刻，轻松自在地陪伴着你。",
 "一首歌、一档熟悉的电台节目、一阵轻柔的雨声，都能让平凡的一天多一点好心情。所以 Paransori 减少繁琐，增加聆听的乐趣，努力打造一个人人都能轻松、舒适使用的声音空间。",
 "聆听喜欢的声音，其实离我们比想象中更近。开启早晨的时候，忙碌工作的时候，还有结束一天的安静夜晚。\n\n我们希望每个人都能轻松、舒适地遇见想听的声音。因此，Paransori 把各种声音汇集在同一个地方，让你在聆听的那一刻没有繁琐，尽情享受。",
 "从韩国出发的 Paransori，希望能与世界各地的人们相伴，为每个人的日常增添一点小快乐与从容。"],
'zh_Hant': [
 "Paransori 希望在日常的各種時刻，輕鬆自在地陪伴著你。",
 "一首歌、一個熟悉的電台節目、一陣輕柔的雨聲，都能讓平凡的一天多一點好心情。所以 Paransori 減少繁瑣，增加聆聽的樂趣，努力打造一個人人都能輕鬆、舒適使用的聲音空間。",
 "聆聽喜歡的聲音，其實離我們比想像中更近。開啟早晨的時候，忙碌工作的時候，還有結束一天的安靜夜晚。\n\n我們希望每個人都能輕鬆、舒適地遇見想聽的聲音。因此，Paransori 把各種聲音匯集在同一個地方，讓你在聆聽的那一刻沒有繁瑣，盡情享受。",
 "從韓國出發的 Paransori，希望能與世界各地的人們相伴，為每個人的日常增添一點小快樂與從容。"],
'de': [
 "Paransori möchte dich in ganz unterschiedlichen Momenten deines Alltags entspannt begleiten.",
 "Ein Song, eine vertraute Radiosendung oder leiser Regen – manchmal reicht das schon, um einen gewöhnlichen Tag ein bisschen schöner zu machen. Deshalb gestalten wir Paransori als einen Ort für Klänge, der weniger kompliziert ist und mehr Freude am Zuhören bringt – einfach und angenehm für alle.",
 "Die Zeit mit Klängen, die wir lieben, ist näher, als wir denken – wenn der Morgen beginnt, mitten bei der Arbeit und in ruhigen Nächten, wenn der Tag ausklingt.\n\nWir wünschen uns, dass alle die Klänge, die sie hören möchten, einfach und entspannt finden. Darum vereinen wir viele Arten von Klang an einem Ort – damit du jeden Moment des Zuhörens ganz ohne Umstände genießen kannst.",
 "Paransori hat in Korea begonnen. Wir hoffen, Menschen auf der ganzen Welt zu begleiten und ihrem Alltag ein wenig Freude und Gelassenheit zu schenken."],
'es': [
 "Paransori quiere acompañarte con comodidad en los distintos momentos de tu día a día.",
 "Una canción, un programa de radio conocido o el suave sonido de la lluvia pueden hacer que un día cualquiera se sienta un poco mejor. Por eso, en Paransori creamos un espacio de sonido con menos complicaciones y más placer de escuchar, fácil y cómodo para todos.",
 "El tiempo para escuchar los sonidos que nos gustan está más cerca de lo que pensamos: al empezar la mañana, en medio del trabajo y en las noches tranquilas al final del día.\n\nQueremos que cualquiera pueda encontrar los sonidos que busca de forma fácil y cómoda. Por eso reunimos sonidos de todo tipo en un solo lugar, para que disfrutes cada momento de escucha sin complicaciones.",
 "Paransori nació en Corea, y esperamos acompañar a personas de todo el mundo, sumando un poco de alegría y calma a su día a día."],
'fr': [
 "Paransori souhaite vous accompagner en douceur dans les nombreux moments de votre quotidien.",
 "Une chanson, une émission de radio familière ou le doux bruit de la pluie peuvent rendre une journée ordinaire un peu plus agréable. C’est pourquoi nous faisons de Paransori un espace sonore plus simple, où l’écoute devient un vrai plaisir, facile et agréable pour tous.",
 "Le temps passé à écouter les sons que l’on aime est plus proche qu’on ne le pense : au début de la matinée, au milieu du travail, et pendant les soirées calmes, quand la journée s’achève.\n\nNous souhaitons que chacun puisse trouver facilement et sereinement les sons qu’il aime. C’est pourquoi nous réunissons toutes sortes de sons en un seul endroit, pour que vous profitiez pleinement de chaque moment d’écoute, sans complications.",
 "Lancée en Corée, l’application Paransori espère accompagner des personnes partout dans le monde et apporter à chaque quotidien un peu plus de joie et de sérénité."],
'it': [
 "Paransori vuole accompagnarti con leggerezza nei tanti momenti della tua giornata.",
 "Una canzone, un programma radio familiare o il suono delicato della pioggia possono rendere una giornata qualunque un po’ più piacevole. Per questo facciamo di Paransori uno spazio sonoro con meno complicazioni e più piacere di ascoltare, semplice e comodo per tutti.",
 "Il tempo per ascoltare i suoni che amiamo è più vicino di quanto pensiamo: all’inizio della mattina, durante il lavoro e nelle sere tranquille, quando la giornata finisce.\n\nVorremmo che chiunque potesse trovare i suoni che desidera in modo semplice e comodo. Per questo riuniamo tanti tipi di suoni in un unico posto, così puoi goderti ogni momento di ascolto senza complicazioni.",
 "Nata in Corea, l’app Paransori spera di accompagnare persone di tutto il mondo, aggiungendo un po’ di gioia e serenità alla vita di ogni giorno."],
'pt': [
 "O Paransori quer acompanhar você com tranquilidade nos vários momentos do dia a dia.",
 "Uma música, um programa de rádio conhecido ou o som suave da chuva podem deixar um dia comum um pouco melhor. Por isso, estamos fazendo do Paransori um espaço de som com menos complicação e mais prazer em ouvir, fácil e confortável para todos.",
 "O tempo de ouvir os sons que amamos está mais perto do que imaginamos: ao começar a manhã, no meio do trabalho e nas noites tranquilas, quando o dia termina.\n\nQueremos que qualquer pessoa encontre os sons que deseja de forma fácil e confortável. Por isso reunimos vários tipos de som em um só lugar, para que você aproveite cada momento de escuta sem complicação.",
 "O Paransori nasceu na Coreia e espera estar com pessoas do mundo todo, trazendo um pouco mais de alegria e tranquilidade ao dia a dia de cada um."],
'pl': [
 "Paransori chce spokojnie towarzyszyć ci w różnych chwilach codzienności.",
 "Jedna piosenka, znana audycja radiowa czy cichy szum deszczu potrafią sprawić, że zwykły dzień staje się trochę przyjemniejszy. Dlatego tworzymy Paransori jako przestrzeń dźwięków, w której jest mniej komplikacji, a więcej radości ze słuchania – prostą i wygodną dla każdego.",
 "Czas na słuchanie ulubionych dźwięków jest bliżej, niż myślimy – gdy zaczyna się poranek, w trakcie pracy i w ciche wieczory, gdy dzień dobiega końca.\n\nChcemy, by każdy mógł łatwo i wygodnie znaleźć dźwięki, których szuka. Dlatego zbieramy różne dźwięki w jednym miejscu, by każda chwila słuchania była po prostu przyjemnością – bez zbędnych komplikacji.",
 "Paransori powstało w Korei. Mamy nadzieję towarzyszyć ludziom na całym świecie i dodawać ich codzienności odrobinę radości i spokoju."],
'ru': [
 "Paransori хочет спокойно сопровождать вас в самые разные моменты повседневной жизни.",
 "Одна песня, знакомая радиопередача или тихий шум дождя могут сделать обычный день чуть лучше. Поэтому мы создаём Paransori как пространство звуков, где меньше сложностей и больше удовольствия от прослушивания, — простое и удобное для каждого.",
 "Время для любимых звуков ближе, чем кажется: когда начинается утро, посреди работы и тихими вечерами, когда день подходит к концу.\n\nМы хотим, чтобы каждый мог легко и удобно найти звуки, которые ему нужны. Поэтому мы собираем самые разные звуки в одном месте — чтобы каждой минутой слушания можно было просто наслаждаться, без лишних сложностей.",
 "Paransori появился в Корее, и мы надеемся быть рядом с людьми по всему миру, добавляя в их будни немного радости и спокойствия."],
'tr': [
 "Paransori, gündelik hayatın farklı anlarında sana rahatça eşlik etmek istiyor.",
 "Tek bir şarkı, tanıdık bir radyo programı ya da yumuşak bir yağmur sesi, sıradan bir günü biraz daha güzel kılabilir. Bu yüzden Paransori'yi karmaşayı azaltan ve dinleme keyfini artıran, herkesin kolayca ve rahatça kullanabileceği bir ses alanı olarak geliştiriyoruz.",
 "Sevdiğimiz sesleri dinlediğimiz zaman sandığımızdan daha yakın: güne başlarken, çalışırken ve günün sona erdiği sakin gecelerde.\n\nHerkesin istediği seslere kolayca ve rahatça ulaşabilmesini istiyoruz. Bu yüzden birçok farklı sesi tek bir yerde topluyoruz; böylece dinlediğin her anın karmaşa olmadan tadını çıkarabilirsin.",
 "Kore'de başlayan Paransori'nin dünyanın dört bir yanındaki insanlara eşlik etmesini ve her güne biraz neşe ve huzur katmasını diliyoruz."],
'id': [
 "Paransori ingin menemani kamu dengan nyaman di berbagai momen sehari-hari.",
 "Satu lagu, siaran radio yang akrab, atau suara hujan yang lembut bisa membuat hari biasa terasa sedikit lebih menyenangkan. Karena itu, kami membangun Paransori sebagai ruang suara yang lebih sederhana dan lebih menyenangkan untuk didengar, mudah dan nyaman digunakan oleh siapa saja.",
 "Waktu untuk mendengarkan suara yang kita sukai sebenarnya lebih dekat dari yang kita kira: saat pagi dimulai, di sela pekerjaan, hingga malam yang tenang saat hari berakhir.\n\nKami ingin semua orang bisa menemukan suara yang mereka inginkan dengan mudah dan nyaman. Karena itu, kami mengumpulkan berbagai suara dalam satu tempat, agar kamu bisa menikmati setiap momen mendengarkan tanpa ribet.",
 "Berawal dari Korea, Paransori berharap bisa menemani orang-orang di seluruh dunia dan menambahkan sedikit kegembiraan serta ketenangan dalam keseharian mereka."],
'vi': [
 "Paransori mong được nhẹ nhàng đồng hành cùng bạn trong những khoảnh khắc khác nhau của cuộc sống thường ngày.",
 "Một bài hát, một chương trình radio quen thuộc hay tiếng mưa rơi khe khẽ cũng có thể khiến một ngày bình thường trở nên dễ chịu hơn. Vì vậy, Paransori đang tạo nên một không gian âm thanh bớt phức tạp, thêm niềm vui khi lắng nghe, để ai cũng có thể sử dụng dễ dàng và thoải mái.",
 "Khoảng thời gian lắng nghe những âm thanh mình yêu thích gần hơn chúng ta tưởng: khi bắt đầu buổi sáng, giữa giờ làm việc, hay trong những đêm yên tĩnh khép lại một ngày.\n\nChúng tôi mong ai cũng có thể tìm thấy âm thanh mình muốn một cách dễ dàng và thoải mái. Vì vậy, chúng tôi gom nhiều loại âm thanh vào cùng một nơi, để bạn tận hưởng trọn vẹn từng khoảnh khắc lắng nghe mà không phải bận tâm điều gì.",
 "Bắt đầu từ Hàn Quốc, Paransori mong được đồng hành cùng mọi người trên khắp thế giới, mang thêm chút niềm vui và thư thái vào cuộc sống mỗi ngày."],
'th': [
 "Paransori อยากอยู่เคียงข้างคุณอย่างสบายใจในทุกช่วงเวลาของชีวิตประจำวัน",
 "เพลงสักเพลง รายการวิทยุที่คุ้นเคย หรือเสียงฝนเบาๆ ก็ทำให้วันธรรมดาดีขึ้นได้อีกนิด Paransori จึงตั้งใจสร้างพื้นที่แห่งเสียงที่ลดความยุ่งยาก เพิ่มความสุขในการฟัง และใช้งานได้ง่ายและสบายสำหรับทุกคน",
 "เวลาที่ได้ฟังเสียงที่ชอบอยู่ใกล้เรามากกว่าที่คิด ทั้งตอนเริ่มต้นเช้าวันใหม่ ระหว่างทำงาน และในค่ำคืนเงียบสงบตอนจบวัน\n\nเราอยากให้ทุกคนได้พบเสียงที่ต้องการได้อย่างง่ายดายและสบายใจ เราจึงรวบรวมเสียงหลากหลายไว้ในที่เดียว เพื่อให้คุณเพลิดเพลินกับทุกช่วงเวลาของการฟังได้อย่างเต็มที่ โดยไม่ต้องยุ่งยาก",
 "Paransori เริ่มต้นจากเกาหลี และหวังว่าจะได้อยู่เคียงข้างผู้คนทั่วโลก เติมความสุขเล็กๆ และความผ่อนคลายให้กับทุกวัน"],
}
def pat(k): return re.compile(r'("' + k + r'"\s*:\s*)"(?:[^"\\]|\\.)*"')
out = {}
for lang, vals in T.items():
    p = os.path.join(D, f'app_{lang}.arb')
    if not os.path.exists(p):
        print(f'❌ {p} 파일이 없어요. 아무것도 저장 안 했어요.'); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    cur = json.loads(raw)
    if all(cur.get(k) == v for k, v in zip(K, vals)):
        continue
    new = raw
    for k, v in zip(K, vals):
        new, n = pat(k).subn(lambda m, t=v: m.group(1) + json.dumps(t, ensure_ascii=False), new)
        if n != 1:
            print(f'❌ {lang}: {k}를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    j = json.loads(new)
    if any(j[k] != v for k, v in zip(K, vals)):
        print(f'❌ {lang}: 바꾼 뒤 확인 실패. 아무것도 저장 안 했어요.'); sys.exit(1)
    out[p] = new
    print('✔', lang)
if not out:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, new in out.items():
    open(p, 'wb').write(new.encode('utf-8'))
print(f'저장했어요. ({len(out)}개 언어)')
