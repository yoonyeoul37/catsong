import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../widgets/paran_toast.dart';
import '../l10n/locale_holder.dart';

// ─────────────────────────────────────────────────────────────
// 의견 보내기 — ⋮ 메뉴 · 도움말 맨 아래에서 열림
// 보내면: Cloudflare(ssing.kr 작은 서버)에 저장 + ceo@knexm.com으로 메일 알림
// ─────────────────────────────────────────────────────────────
const _kFeedbackUrl = 'https://paransori-feedback.knexm03505.workers.dev/';
const _kFeedbackKey = 'paransori-catsong-2026'; // 서버 코드의 KEY와 같은 값

/// 의견 보내기 글자: 한국어면 한국어 / 그 밖은 아래 번역표 → 없으면 영어
String fbText(String ko, String en) {
  final l = tr.localeName.replaceAll('-', '_');
  if (l.startsWith('ko')) return ko;
  final key = l.startsWith('zh')
      ? ((l.contains('Hant') || l.contains('TW') || l.contains('HK')) ? 'zh_Hant' : 'zh')
      : l.split('_').first;
  return _fbTr[ko]?[key] ?? en;
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _kinds = [
    ('bug', '오류 신고', 'Report a bug'),
    ('idea', '기능 제안', 'Suggest a feature'),
  ];
  String _kind = 'idea';
  final _msg = TextEditingController();
  final _email = TextEditingController();
  final _msgFocus = FocusNode();
  bool _sending = false;
  final List<(XFile, Uint8List)> _photos = []; // 붙인 사진 (최대 3장 · 줄인 것)
  static const _maxPhotos = 3;
  static const _maxBytes = 3800000; // 메일 한 통 5MB 안에 들어가게 (글자로 바꾸면 커져서 넉넉히)

  @override
  void initState() {
    super.initState();
    _msg.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _msg.dispose();
    _email.dispose();
    _msgFocus.dispose();
    super.dispose();
  }

  void _buzz() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  /// 갤러리에서 스샷 고르기 — 폰에서 줄여서 (가로 1080 · 화질 75 → 보통 한 장 150~400KB)
  Future<void> _pickPhotos() async {
    _buzz();
    if (_photos.length >= _maxPhotos) return;
    try {
      final picked = await ImagePicker().pickMultiImage(maxWidth: 1080, maxHeight: 2400, imageQuality: 75);
      for (final f in picked) {
        if (_photos.length >= _maxPhotos) break;
        final bytes = await f.readAsBytes();
        if (!mounted) return;
        setState(() => _photos.add((f, bytes)));
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    _buzz();
    if (_sending) return;
    final text = _msg.text.trim();
    if (text.length < 2) {
      _msgFocus.requestFocus(); // 글이 없으면 글 칸으로
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showParanToast(context, fbText('이메일 주소를 다시 확인해 주세요', 'Please check the email address'), error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    var device = '', ver = '';
    try {
      if (Platform.isIOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        device = '${i.utsname.machine} · iOS ${i.systemVersion}';
      } else {
        final a = await DeviceInfoPlugin().androidInfo;
        device = '${a.manufacturer} ${a.model} · Android ${a.version.release}';
      }
    } catch (_) {}
    try {
      final p = await PackageInfo.fromPlatform();
      ver = '${p.version} (${p.buildNumber})';
    } catch (_) {}
    // 사진: 합쳐서 너무 크면 넘는 사진은 빼고 보내기
    final photos = <Map<String, String>>[];
    var total = 0, dropped = false;
    for (var i = 0; i < _photos.length; i++) {
      final b = _photos[i].$2;
      if (total + b.length > _maxBytes) {
        dropped = true;
        continue;
      }
      total += b.length;
      final n = _photos[i].$1.name.toLowerCase();
      final png = n.endsWith('.png');
      photos.add({
        'name': 'screenshot${i + 1}.${png ? 'png' : 'jpg'}',
        'type': png ? 'image/png' : 'image/jpeg',
        'data': base64Encode(b),
      });
    }
    var ok = false;
    try {
      final r = await http
          .post(
            Uri.parse(_kFeedbackUrl),
            headers: {'content-type': 'application/json', 'x-paransori': _kFeedbackKey},
            body: jsonEncode({
              'kind': _kind,
              'message': text,
              'email': email,
              'device': device,
              'app_version': ver,
              'lang': tr.localeName,
              'photos': photos,
            }),
          )
          .timeout(Duration(seconds: photos.isEmpty ? 15 : 40));
      ok = r.statusCode == 200 && (jsonDecode(r.body)['ok'] == true);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      showParanToast(
          context,
          dropped
              ? fbText('사진이 너무 커서 일부만 보냈어요', 'Some photos were too large and were left out')
              : fbText('보내 주셔서 고마워요', 'Thanks for your feedback'));
      Navigator.pop(context);
    } else {
      showParanToast(context, fbText('보내지 못했어요. 인터넷 연결을 확인해 주세요.', "Couldn't send. Please check your connection."),
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDarkMode;
    // 색: 도움말 화면과 같게
    final bg = d ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF32302C) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = d ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
    final ready = _msg.text.trim().length >= 2;

    InputDecoration deco(String h) => InputDecoration(
          hintText: h,
          hintStyle: TextStyle(color: hint, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          counterText: '',
        );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(fbText('의견 보내기', 'Send feedback'),
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                child: Text(fbText('어떤 의견을 보내시겠어요?', 'What would you like to send?'),
                    style: TextStyle(color: hint, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              // 종류 2개 (고른 것만 먹색 · 가로 반반)
              Row(
                children: [
                  for (var i = 0; i < _kinds.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _buzz();
                          setState(() => _kind = _kinds[i].$1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 40,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: _kind == _kinds[i].$1 ? ink : card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(fbText(_kinds[i].$2, _kinds[i].$3),
                                maxLines: 1,
                                style: TextStyle(
                                  color: _kind == _kinds[i].$1 ? bg : sub,
                                  fontSize: 13.5,
                                  fontWeight: _kind == _kinds[i].$1 ? FontWeight.w700 : FontWeight.w500,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              // 글
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: _msg,
                  focusNode: _msgFocus,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 3000,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(color: ink, fontSize: 14.5, height: 1.5),
                  decoration: deco(_kind == 'bug'
                      ? fbText('어떤 문제가 발생했는지 알려주세요.', 'Tell us what went wrong.')
                      : _kind == 'idea'
                          ? fbText('파란소리에 바라는 기능을 알려주세요.', 'Tell us what feature you’d like in Paransori.')
                          : fbText('의견을 자유롭게 남겨주세요.', 'Feel free to share your thoughts.')),
                ),
              ),
              const SizedBox(height: 8),
              // 사진 (스샷) — 작은 미리보기 + ✕ / 3장 안 됐으면 '+ 사진 첨부'
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (var i = 0; i < _photos.length; i++) ...[
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_photos[i].$2, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 192),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () {
                                _buzz();
                                setState(() => _photos.removeAt(i));
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(color: ink, shape: BoxShape.circle, border: Border.all(color: bg, width: 2)),
                                child: Icon(Icons.close_rounded, size: 12, color: bg),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (_photos.length < _maxPhotos)
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickPhotos,
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 20, color: sub),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text('${fbText('사진 첨부', 'Attach photo')}  ${_photos.length}/$_maxPhotos',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: sub, fontSize: 13.5, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 이메일 (선택)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  maxLength: 200,
                  style: TextStyle(color: ink, fontSize: 14.5),
                  decoration: deco(fbText('답변받을 이메일 (선택)', 'Email for a reply (optional)')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 18),
                child: Text(
                    fbText('기기 정보와 앱 버전은 문제 확인을 위해서만 사용돼요.',
                        'Device info and app version are used only to check problems.'),
                    style: TextStyle(color: hint, fontSize: 11.5, height: 1.5)),
              ),
              // 보내기 (글이 있으면 진하게)
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ready ? ink : ink.withOpacity(0.35),
                    foregroundColor: bg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: bg))
                      : Text(fbText('보내기', 'Send'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 번역표 (한국어 글자 → 21개 언어 · 영어는 fbText 두 번째 칸)
// ─────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> _fbTr = {
  '의견 보내기': {
    'ja': 'ご意見を送る',
    'zh': '发送反馈',
    'zh_Hant': '傳送意見',
    'de': 'Feedback senden',
    'es': 'Enviar comentarios',
    'fr': 'Envoyer un avis',
    'it': 'Invia feedback',
    'pt': 'Enviar feedback',
    'pl': 'Wyślij opinię',
    'ru': 'Отправить отзыв',
    'tr': 'Geri bildirim gönder',
    'id': 'Kirim masukan',
    'vi': 'Gửi góp ý',
    'th': 'ส่งความคิดเห็น',
    'uk': 'Надіслати відгук',
    'hi': 'प्रतिक्रिया भेजें',
    'ro': 'Trimite feedback',
    'cs': 'Odeslat zpětnou vazbu',
    'hu': 'Visszajelzés küldése',
    'ar': 'إرسال ملاحظات',
    'ur': 'رائے بھیجیں',
  },
  '서비스 이용 중 개선점이나 건의사항을 전달합니다.': {
    'ja': 'Paransoriへのご要望をお聞かせください',
    'zh': '告诉我们你对 Paransori 的期待',
    'zh_Hant': '告訴我們你對 Paransori 的期待',
    'de': 'Was wünschst du dir von Paransori?',
    'es': 'Cuéntanos qué esperas de Paransori',
    'fr': 'Dis-nous ce que tu attends de Paransori',
    'it': 'Dicci cosa desideri da Paransori',
    'pt': 'Conte o que você espera do Paransori',
    'pl': 'Powiedz, czego oczekujesz od Paransori',
    'ru': 'Расскажите, чего вы ждёте от Paransori',
    'tr': 'Paransori’den beklentini anlat',
    'id': 'Ceritakan harapanmu untuk Paransori',
    'vi': 'Bạn mong muốn gì ở Paransori?',
    'th': 'บอกเราว่าคุณอยากได้อะไรจาก Paransori',
    'uk': 'Розкажіть, чого ви чекаєте від Paransori',
    'hi': 'बताइए आप Paransori से क्या चाहते हैं',
    'ro': 'Spune-ne ce îți dorești de la Paransori',
    'cs': 'Řekněte nám, co byste od Paransori chtěli',
    'hu': 'Mondd el, mit vársz a Paransoritól',
    'ar': 'أخبرنا بما تتمناه من Paransori',
    'ur': 'بتائیں آپ Paransori سے کیا چاہتے ہیں',
  },
  '어떤 의견을 보내시겠어요?': {
    'ja': 'どのようなご意見ですか？',
    'zh': '你想发送哪种意见？',
    'zh_Hant': '你想傳送哪種意見？',
    'de': 'Was möchtest du uns senden?',
    'es': '¿Qué tipo de comentario quieres enviar?',
    'fr': 'Quel type d’avis veux-tu envoyer ?',
    'it': 'Che tipo di feedback vuoi inviare?',
    'pt': 'Que tipo de feedback você quer enviar?',
    'pl': 'Jaką opinię chcesz wysłać?',
    'ru': 'Какой отзыв вы хотите отправить?',
    'tr': 'Ne tür bir geri bildirim göndermek istersin?',
    'id': 'Masukan apa yang ingin kamu kirim?',
    'vi': 'Bạn muốn gửi góp ý gì?',
    'th': 'คุณต้องการส่งความคิดเห็นแบบไหน',
    'uk': 'Який відгук ви хочете надіслати?',
    'hi': 'आप किस तरह की प्रतिक्रिया भेजना चाहते हैं?',
    'ro': 'Ce fel de feedback vrei să trimiți?',
    'cs': 'Jakou zpětnou vazbu chcete odeslat?',
    'hu': 'Milyen visszajelzést küldenél?',
    'ar': 'ما نوع الملاحظة التي تريد إرسالها؟',
    'ur': 'آپ کس قسم کی رائے بھیجنا چاہتے ہیں؟',
  },
  '오류 신고': {
    'ja': '不具合の報告',
    'zh': '报告问题',
    'zh_Hant': '回報問題',
    'de': 'Fehler melden',
    'es': 'Informar de un error',
    'fr': 'Signaler un bug',
    'it': 'Segnala un errore',
    'pt': 'Relatar erro',
    'pl': 'Zgłoś błąd',
    'ru': 'Сообщить об ошибке',
    'tr': 'Hata bildir',
    'id': 'Laporkan bug',
    'vi': 'Báo lỗi',
    'th': 'แจ้งข้อผิดพลาด',
    'uk': 'Повідомити про помилку',
    'hi': 'त्रुटि बताएं',
    'ro': 'Raportează o eroare',
    'cs': 'Nahlásit chybu',
    'hu': 'Hiba bejelentése',
    'ar': 'الإبلاغ عن خطأ',
    'ur': 'خرابی کی اطلاع دیں',
  },
  '기능 제안': {
    'ja': '機能のご要望',
    'zh': '功能建议',
    'zh_Hant': '功能建議',
    'de': 'Funktion vorschlagen',
    'es': 'Sugerir una función',
    'fr': 'Suggérer une fonction',
    'it': 'Suggerisci una funzione',
    'pt': 'Sugerir recurso',
    'pl': 'Zaproponuj funkcję',
    'ru': 'Предложить функцию',
    'tr': 'Özellik öner',
    'id': 'Usulkan fitur',
    'vi': 'Đề xuất tính năng',
    'th': 'เสนอฟีเจอร์',
    'uk': 'Запропонувати функцію',
    'hi': 'फ़ीचर सुझाएं',
    'ro': 'Sugerează o funcție',
    'cs': 'Navrhnout funkci',
    'hu': 'Funkció javaslása',
    'ar': 'اقتراح ميزة',
    'ur': 'فیچر تجویز کریں',
  },
  '의견을 자유롭게 남겨주세요.': {
    'ja': 'ご意見を自由にお書きください',
    'zh': '请随意留下你的意见',
    'zh_Hant': '請隨意留下你的意見',
    'de': 'Schreib uns gern deine Meinung',
    'es': 'Déjanos tu opinión libremente',
    'fr': 'Laisse-nous ton avis librement',
    'it': 'Lasciaci liberamente il tuo parere',
    'pt': 'Deixe sua opinião à vontade',
    'pl': 'Podziel się swoją opinią',
    'ru': 'Оставьте свой отзыв',
    'tr': 'Görüşünü dilediğin gibi yaz',
    'id': 'Silakan tulis masukanmu',
    'vi': 'Hãy thoải mái để lại góp ý',
    'th': 'แสดงความคิดเห็นได้ตามสบาย',
    'uk': 'Залиште свій відгук',
    'hi': 'अपनी राय खुलकर लिखें',
    'ro': 'Lasă-ne liber părerea ta',
    'cs': 'Napište nám svůj názor',
    'hu': 'Írd meg nyugodtan a véleményed',
    'ar': 'اترك رأيك بحرية',
    'ur': 'اپنی رائے کھل کر لکھیں',
  },
  '어떤 문제가 발생했는지 알려주세요.': {
    'ja': 'どんな問題が起きたか教えてください',
    'zh': '请告诉我们发生了什么问题',
    'zh_Hant': '請告訴我們發生了什麼問題',
    'de': 'Beschreib uns, welches Problem aufgetreten ist',
    'es': 'Cuéntanos qué problema ocurrió',
    'fr': 'Dis-nous quel problème est survenu',
    'it': 'Dicci quale problema si è verificato',
    'pt': 'Conte qual problema aconteceu',
    'pl': 'Opisz, jaki problem wystąpił',
    'ru': 'Расскажите, какая проблема возникла',
    'tr': 'Hangi sorunun oluştuğunu anlat',
    'id': 'Ceritakan masalah apa yang terjadi',
    'vi': 'Hãy cho chúng tôi biết lỗi gì đã xảy ra',
    'th': 'บอกเราว่าเกิดปัญหาอะไรขึ้น',
    'uk': 'Розкажіть, яка проблема виникла',
    'hi': 'बताइए क्या समस्या हुई',
    'ro': 'Spune-ne ce problemă a apărut',
    'cs': 'Popište, jaký problém nastal',
    'hu': 'Írd le, milyen hiba történt',
    'ar': 'أخبرنا بالمشكلة التي حدثت',
    'ur': 'بتائیں کیا مسئلہ پیش آیا',
  },
  '파란소리에 바라는 기능을 알려주세요.': {
    'ja': 'Paransoriに欲しい機能を教えてください',
    'zh': '告诉我们你希望 Paransori 增加的功能',
    'zh_Hant': '告訴我們你希望 Paransori 增加的功能',
    'de': 'Welche Funktion wünschst du dir in Paransori?',
    'es': 'Cuéntanos qué función te gustaría en Paransori',
    'fr': 'Dis-nous quelle fonction tu aimerais dans Paransori',
    'it': 'Dicci quale funzione vorresti in Paransori',
    'pt': 'Conte qual recurso você gostaria no Paransori',
    'pl': 'Napisz, jakiej funkcji brakuje Ci w Paransori',
    'ru': 'Расскажите, какую функцию вы хотите в Paransori',
    'tr': 'Paransori’de görmek istediğin özelliği anlat',
    'id': 'Ceritakan fitur yang kamu inginkan di Paransori',
    'vi': 'Hãy cho chúng tôi biết tính năng bạn muốn có trong Paransori',
    'th': 'บอกเราว่าอยากให้ Paransori มีฟีเจอร์อะไร',
    'uk': 'Розкажіть, яку функцію ви хочете в Paransori',
    'hi': 'बताइए आप Paransori में कौन-सा फ़ीचर चाहते हैं',
    'ro': 'Spune-ne ce funcție ți-ai dori în Paransori',
    'cs': 'Napište, jakou funkci byste v Paransori chtěli',
    'hu': 'Írd meg, milyen funkciót szeretnél a Paransoriban',
    'ar': 'أخبرنا بالميزة التي تتمناها في Paransori',
    'ur': 'بتائیں آپ Paransori میں کون سا فیچر چاہتے ہیں',
  },
  '답변받을 이메일 (선택)': {
    'ja': '返信用メール（任意）',
    'zh': '接收回复的邮箱（选填）',
    'zh_Hant': '接收回覆的信箱（選填）',
    'de': 'E-Mail für Antwort (optional)',
    'es': 'Correo de respuesta (opcional)',
    'fr': 'E-mail de réponse (facultatif)',
    'it': 'Email di risposta (facoltativa)',
    'pt': 'E-mail para resposta (opcional)',
    'pl': 'Twój e-mail (opcjonalnie)',
    'ru': 'E-mail для ответа (по желанию)',
    'tr': 'Yanıt e-postası (isteğe bağlı)',
    'id': 'Email balasan (opsional)',
    'vi': 'Email nhận trả lời (tùy chọn)',
    'th': 'อีเมลสำหรับตอบกลับ (ไม่บังคับ)',
    'uk': 'E-mail для відповіді (опційно)',
    'hi': 'जवाब के लिए ईमेल (वैकल्पिक)',
    'ro': 'E-mail de răspuns (opțional)',
    'cs': 'E-mail pro odpověď (nepovinné)',
    'hu': 'Válasz e-mail (nem kötelező)',
    'ar': 'البريد لتلقي الرد (اختياري)',
    'ur': 'جواب کے لیے ای میل (اختیاری)',
  },
  '기기 정보와 앱 버전은 문제 확인을 위해서만 사용돼요.': {
    'ja': '端末情報とアプリのバージョンは、問題の確認にのみ使用されます。',
    'zh': '设备信息和应用版本仅用于确认问题。',
    'zh_Hant': '裝置資訊和 App 版本只用於確認問題。',
    'de': 'Geräteinfos und App-Version werden nur zur Fehlerprüfung verwendet.',
    'es': 'La información del dispositivo y la versión de la app solo se usan para revisar problemas.',
    'fr': 'Les infos de l’appareil et la version de l’app servent uniquement à vérifier les problèmes.',
    'it': 'Le informazioni sul dispositivo e la versione dell’app servono solo per verificare i problemi.',
    'pt': 'As informações do aparelho e a versão do app são usadas só para verificar problemas.',
    'pl': 'Informacje o urządzeniu i wersja aplikacji służą tylko do sprawdzania problemów.',
    'ru': 'Данные об устройстве и версия приложения используются только для проверки проблем.',
    'tr': 'Cihaz bilgisi ve uygulama sürümü yalnızca sorunları incelemek için kullanılır.',
    'id': 'Info perangkat dan versi aplikasi hanya digunakan untuk memeriksa masalah.',
    'vi': 'Thông tin thiết bị và phiên bản ứng dụng chỉ dùng để kiểm tra lỗi.',
    'th': 'ข้อมูลอุปกรณ์และเวอร์ชันแอปใช้เพื่อตรวจสอบปัญหาเท่านั้น',
    'uk': 'Дані про пристрій і версія застосунку використовуються лише для перевірки проблем.',
    'hi': 'डिवाइस जानकारी और ऐप वर्ज़न केवल समस्या जांचने के लिए उपयोग होते हैं।',
    'ro': 'Informațiile despre dispozitiv și versiunea aplicației sunt folosite doar pentru verificarea problemelor.',
    'cs': 'Informace o zařízení a verze aplikace slouží jen ke kontrole problémů.',
    'hu': 'Az eszközadatokat és az alkalmazás verzióját csak a hibák ellenőrzésére használjuk.',
    'ar': 'تُستخدم معلومات الجهاز وإصدار التطبيق للتحقق من المشكلات فقط.',
    'ur': 'ڈیوائس کی معلومات اور ایپ ورژن صرف مسئلہ جانچنے کے لیے استعمال ہوتے ہیں۔',
  },
  '보내기': {
    'ja': '送信',
    'zh': '发送',
    'zh_Hant': '傳送',
    'de': 'Senden',
    'es': 'Enviar',
    'fr': 'Envoyer',
    'it': 'Invia',
    'pt': 'Enviar',
    'pl': 'Wyślij',
    'ru': 'Отправить',
    'tr': 'Gönder',
    'id': 'Kirim',
    'vi': 'Gửi',
    'th': 'ส่ง',
    'uk': 'Надіслати',
    'hi': 'भेजें',
    'ro': 'Trimite',
    'cs': 'Odeslat',
    'hu': 'Küldés',
    'ar': 'إرسال',
    'ur': 'بھیجیں',
  },
  '보내 주셔서 고마워요': {
    'ja': 'ご意見ありがとうございます',
    'zh': '感谢你的反馈',
    'zh_Hant': '感謝你的意見',
    'de': 'Danke für dein Feedback',
    'es': 'Gracias por tus comentarios',
    'fr': 'Merci pour ton avis',
    'it': 'Grazie per il feedback',
    'pt': 'Obrigado pelo feedback',
    'pl': 'Dziękujemy za opinię',
    'ru': 'Спасибо за отзыв',
    'tr': 'Geri bildirimin için teşekkürler',
    'id': 'Terima kasih atas masukanmu',
    'vi': 'Cảm ơn bạn đã góp ý',
    'th': 'ขอบคุณสำหรับความคิดเห็น',
    'uk': 'Дякуємо за відгук',
    'hi': 'प्रतिक्रिया के लिए धन्यवाद',
    'ro': 'Mulțumim pentru feedback',
    'cs': 'Děkujeme za zpětnou vazbu',
    'hu': 'Köszönjük a visszajelzést',
    'ar': 'شكرًا على ملاحظاتك',
    'ur': 'آپ کی رائے کا شکریہ',
  },
  '보내지 못했어요. 인터넷 연결을 확인해 주세요.': {
    'ja': '送信できませんでした。インターネット接続を確認してください。',
    'zh': '发送失败。请检查网络连接。',
    'zh_Hant': '傳送失敗。請檢查網路連線。',
    'de': 'Senden fehlgeschlagen. Bitte prüfe deine Verbindung.',
    'es': 'No se pudo enviar. Revisa tu conexión.',
    'fr': 'Envoi impossible. Vérifie ta connexion.',
    'it': 'Invio non riuscito. Controlla la connessione.',
    'pt': 'Não foi possível enviar. Verifique sua conexão.',
    'pl': 'Nie udało się wysłać. Sprawdź połączenie.',
    'ru': 'Не удалось отправить. Проверьте подключение.',
    'tr': 'Gönderilemedi. Bağlantını kontrol et.',
    'id': 'Gagal mengirim. Periksa koneksi internet.',
    'vi': 'Không gửi được. Hãy kiểm tra kết nối mạng.',
    'th': 'ส่งไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่อ',
    'uk': 'Не вдалося надіслати. Перевірте з’єднання.',
    'hi': 'भेजा नहीं जा सका। कृपया कनेक्शन जांचें।',
    'ro': 'Nu s-a putut trimite. Verifică conexiunea.',
    'cs': 'Odeslání se nezdařilo. Zkontrolujte připojení.',
    'hu': 'Nem sikerült elküldeni. Ellenőrizd a kapcsolatot.',
    'ar': 'تعذّر الإرسال. تحقّق من الاتصال بالإنترنت.',
    'ur': 'بھیجا نہیں جا سکا۔ براہ کرم کنکشن چیک کریں۔',
  },
  '이메일 주소를 다시 확인해 주세요': {
    'ja': 'メールアドレスをご確認ください',
    'zh': '请检查邮箱地址',
    'zh_Hant': '請檢查電子郵件地址',
    'de': 'Bitte prüfe die E-Mail-Adresse',
    'es': 'Revisa la dirección de correo',
    'fr': 'Vérifie l’adresse e-mail',
    'it': 'Controlla l’indirizzo email',
    'pt': 'Verifique o endereço de e-mail',
    'pl': 'Sprawdź adres e-mail',
    'ru': 'Проверьте адрес e-mail',
    'tr': 'E-posta adresini kontrol et',
    'id': 'Periksa alamat email',
    'vi': 'Hãy kiểm tra lại địa chỉ email',
    'th': 'กรุณาตรวจสอบอีเมล',
    'uk': 'Перевірте адресу e-mail',
    'hi': 'ईमेल पता जांचें',
    'ro': 'Verifică adresa de e-mail',
    'cs': 'Zkontrolujte e-mailovou adresu',
    'hu': 'Ellenőrizd az e-mail-címet',
    'ar': 'تحقّق من البريد الإلكتروني',
    'ur': 'ای میل پتہ چیک کریں',
  },
  '사진 첨부': {
    'ja': '写真を添付',
    'zh': '添加图片',
    'zh_Hant': '新增圖片',
    'de': 'Foto anhängen',
    'es': 'Adjuntar foto',
    'fr': 'Joindre une photo',
    'it': 'Allega foto',
    'pt': 'Anexar foto',
    'pl': 'Załącz zdjęcie',
    'ru': 'Прикрепить фото',
    'tr': 'Fotoğraf ekle',
    'id': 'Lampirkan foto',
    'vi': 'Đính kèm ảnh',
    'th': 'แนบรูป',
    'uk': 'Прикріпити фото',
    'hi': 'फ़ोटो जोड़ें',
    'ro': 'Atașează foto',
    'cs': 'Přiložit foto',
    'hu': 'Fotó csatolása',
    'ar': 'إرفاق صورة',
    'ur': 'تصویر منسلک کریں',
  },
  '사진이 너무 커서 일부만 보냈어요': {
    'ja': '写真が大きすぎるため、一部だけ送信しました',
    'zh': '图片太大，只发送了部分',
    'zh_Hant': '圖片太大，只傳送了部分',
    'de': 'Einige Fotos waren zu groß und wurden nicht gesendet',
    'es': 'Algunas fotos eran demasiado grandes y no se enviaron',
    'fr': 'Certaines photos étaient trop lourdes et n’ont pas été envoyées',
    'it': 'Alcune foto erano troppo grandi e non sono state inviate',
    'pt': 'Algumas fotos eram grandes demais e não foram enviadas',
    'pl': 'Niektóre zdjęcia były za duże i nie zostały wysłane',
    'ru': 'Некоторые фото слишком большие и не отправлены',
    'tr': 'Bazı fotoğraflar çok büyük olduğu için gönderilmedi',
    'id': 'Beberapa foto terlalu besar dan tidak terkirim',
    'vi': 'Một số ảnh quá lớn nên không được gửi',
    'th': 'บางรูปใหญ่เกินไปจึงไม่ได้ส่ง',
    'uk': 'Деякі фото завеликі й не надіслані',
    'hi': 'कुछ फ़ोटो बहुत बड़ी थीं, इसलिए नहीं भेजी गईं',
    'ro': 'Unele fotografii erau prea mari și nu au fost trimise',
    'cs': 'Některé fotky byly příliš velké a nebyly odeslány',
    'hu': 'Néhány fotó túl nagy volt, ezért nem küldtük el',
    'ar': 'بعض الصور كبيرة جدًا ولم تُرسل',
    'ur': 'کچھ تصاویر بہت بڑی تھیں اس لیے نہیں بھیجی گئیں',
  },
};
