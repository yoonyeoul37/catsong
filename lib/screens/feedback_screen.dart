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
    ('bug', '오류', 'Bug'),
    ('idea', '제안', 'Idea'),
    ('like', '좋아요', 'Love it'),
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
                child: Text(fbText('어떤 이야기인가요?', 'What is it about?'),
                    style: TextStyle(color: hint, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              // 종류 3개 (고른 것만 먹색)
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
                  decoration: deco(fbText('자유롭게 적어 주세요', 'Write anything you like')),
                ),
              ),
              const SizedBox(height: 8),
              // 사진 (스샷) — 작은 미리보기 + ✕ / 3장 안 됐으면 '+ 사진 붙이기'
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
                                  child: Text('${fbText('사진 붙이기', 'Add photo')}  ${_photos.length}/$_maxPhotos',
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
                  decoration: deco(fbText('답장 받을 이메일 (선택)', 'Email for a reply (optional)')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 18),
                child: Text(
                    fbText('폰 기종 · 앱 버전이 함께 전송돼요. 문제를 빨리 찾는 데만 써요.',
                        'Your phone model and app version are sent too, only to help us find problems faster.'),
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
  '불편한 점이나 바라는 점': {
    'ja': '不具合やご要望',
    'zh': '问题或建议',
    'zh_Hant': '問題或建議',
    'de': 'Probleme oder Wünsche',
    'es': 'Problemas o ideas',
    'fr': 'Problèmes ou idées',
    'it': 'Problemi o idee',
    'pt': 'Problemas ou ideias',
    'pl': 'Problemy lub pomysły',
    'ru': 'Проблемы или идеи',
    'tr': 'Sorunlar veya öneriler',
    'id': 'Masalah atau ide',
    'vi': 'Lỗi hoặc mong muốn',
    'th': 'ปัญหาหรือข้อเสนอแนะ',
    'uk': 'Проблеми чи ідеї',
    'hi': 'समस्या या सुझाव',
    'ro': 'Probleme sau idei',
    'cs': 'Problémy nebo nápady',
    'hu': 'Hibák vagy ötletek',
    'ar': 'مشكلات أو أفكار',
    'ur': 'مسائل یا تجاویز',
  },
  '어떤 이야기인가요?': {
    'ja': 'どんな内容ですか？',
    'zh': '是关于什么的？',
    'zh_Hant': '是關於什麼的？',
    'de': 'Worum geht es?',
    'es': '¿De qué se trata?',
    'fr': 'De quoi s’agit-il ?',
    'it': 'Di cosa si tratta?',
    'pt': 'Sobre o que é?',
    'pl': 'Czego dotyczy?',
    'ru': 'О чём это?',
    'tr': 'Konu nedir?',
    'id': 'Tentang apa?',
    'vi': 'Bạn muốn nói về điều gì?',
    'th': 'เรื่องอะไร',
    'uk': 'Про що це?',
    'hi': 'यह किस बारे में है?',
    'ro': 'Despre ce este vorba?',
    'cs': 'O co jde?',
    'hu': 'Miről szól?',
    'ar': 'عمّ يدور الأمر؟',
    'ur': 'یہ کس بارے میں ہے؟',
  },
  '오류': {
    'ja': '不具合',
    'zh': '问题',
    'zh_Hant': '問題',
    'de': 'Fehler',
    'es': 'Error',
    'fr': 'Bug',
    'it': 'Errore',
    'pt': 'Erro',
    'pl': 'Błąd',
    'ru': 'Ошибка',
    'tr': 'Hata',
    'id': 'Bug',
    'vi': 'Lỗi',
    'th': 'ข้อผิดพลาด',
    'uk': 'Помилка',
    'hi': 'त्रुटि',
    'ro': 'Eroare',
    'cs': 'Chyba',
    'hu': 'Hiba',
    'ar': 'خطأ',
    'ur': 'خرابی',
  },
  '제안': {
    'ja': 'ご要望',
    'zh': '建议',
    'zh_Hant': '建議',
    'de': 'Idee',
    'es': 'Idea',
    'fr': 'Idée',
    'it': 'Idea',
    'pt': 'Ideia',
    'pl': 'Pomysł',
    'ru': 'Идея',
    'tr': 'Öneri',
    'id': 'Ide',
    'vi': 'Góp ý',
    'th': 'ข้อเสนอ',
    'uk': 'Ідея',
    'hi': 'सुझाव',
    'ro': 'Idee',
    'cs': 'Nápad',
    'hu': 'Ötlet',
    'ar': 'اقتراح',
    'ur': 'تجویز',
  },
  '좋아요': {
    'ja': 'いいね',
    'zh': '点赞',
    'zh_Hant': '讚',
    'de': 'Gefällt mir',
    'es': 'Me gusta',
    'fr': 'J’adore',
    'it': 'Mi piace',
    'pt': 'Gostei',
    'pl': 'Podoba mi się',
    'ru': 'Нравится',
    'tr': 'Beğendim',
    'id': 'Suka',
    'vi': 'Thích',
    'th': 'ชอบ',
    'uk': 'Подобається',
    'hi': 'पसंद है',
    'ro': 'Îmi place',
    'cs': 'Líbí se mi',
    'hu': 'Tetszik',
    'ar': 'أعجبني',
    'ur': 'پسند آیا',
  },
  '자유롭게 적어 주세요': {
    'ja': '自由にお書きください',
    'zh': '请随意填写',
    'zh_Hant': '請隨意填寫',
    'de': 'Schreib uns, was du denkst',
    'es': 'Escribe lo que quieras',
    'fr': 'Écris ce que tu veux',
    'it': 'Scrivi liberamente',
    'pt': 'Escreva à vontade',
    'pl': 'Napisz, co chcesz',
    'ru': 'Напишите, что хотите',
    'tr': 'Dilediğini yaz',
    'id': 'Tulis apa saja',
    'vi': 'Hãy viết bất cứ điều gì',
    'th': 'เขียนได้ตามสบาย',
    'uk': 'Напишіть, що хочете',
    'hi': 'जो चाहें लिखें',
    'ro': 'Scrie ce vrei',
    'cs': 'Napište cokoli',
    'hu': 'Írj bármit',
    'ar': 'اكتب ما تشاء',
    'ur': 'جو چاہیں لکھیں',
  },
  '답장 받을 이메일 (선택)': {
    'ja': '返信用メール（任意）',
    'zh': '回复邮箱（选填）',
    'zh_Hant': '回覆信箱（選填）',
    'de': 'E-Mail für Antwort (optional)',
    'es': 'Correo para responder (opcional)',
    'fr': 'E-mail pour répondre (facultatif)',
    'it': 'Email per la risposta (facoltativa)',
    'pt': 'E-mail para resposta (opcional)',
    'pl': 'E-mail do odpowiedzi (opcjonalnie)',
    'ru': 'E-mail для ответа (необязательно)',
    'tr': 'Yanıt için e-posta (isteğe bağlı)',
    'id': 'Email untuk balasan (opsional)',
    'vi': 'Email nhận phản hồi (không bắt buộc)',
    'th': 'อีเมลสำหรับตอบกลับ (ไม่บังคับ)',
    'uk': 'E-mail для відповіді (необов’язково)',
    'hi': 'जवाब के लिए ईमेल (वैकल्पिक)',
    'ro': 'E-mail pentru răspuns (opțional)',
    'cs': 'E-mail pro odpověď (nepovinné)',
    'hu': 'E-mail a válaszhoz (nem kötelező)',
    'ar': 'البريد للرد (اختياري)',
    'ur': 'جواب کے لیے ای میل (اختیاری)',
  },
  '폰 기종 · 앱 버전이 함께 전송돼요. 문제를 빨리 찾는 데만 써요.': {
    'ja': '端末の機種とアプリのバージョンも送信されます。不具合の確認にのみ使います。',
    'zh': '手机型号和应用版本会一并发送，仅用于更快找出问题。',
    'zh_Hant': '手機型號和 App 版本會一併傳送，只用於更快找出問題。',
    'de': 'Handymodell und App-Version werden mitgesendet – nur, damit wir Probleme schneller finden.',
    'es': 'También se envían el modelo del teléfono y la versión de la app, solo para encontrar problemas más rápido.',
    'fr': 'Le modèle du téléphone et la version de l’app sont aussi envoyés, uniquement pour trouver les problèmes plus vite.',
    'it': 'Vengono inviati anche modello del telefono e versione dell’app, solo per trovare i problemi più in fretta.',
    'pt': 'O modelo do celular e a versão do app também são enviados, só para encontrarmos problemas mais rápido.',
    'pl': 'Wysyłamy też model telefonu i wersję aplikacji – tylko po to, by szybciej znaleźć problem.',
    'ru': 'Модель телефона и версия приложения тоже отправляются — только чтобы быстрее найти проблему.',
    'tr': 'Telefon modeli ve uygulama sürümü de gönderilir; yalnızca sorunları daha hızlı bulmak için.',
    'id': 'Model ponsel dan versi aplikasi ikut terkirim, hanya untuk membantu kami menemukan masalah lebih cepat.',
    'vi': 'Dòng máy và phiên bản ứng dụng cũng được gửi kèm, chỉ để tìm lỗi nhanh hơn.',
    'th': 'รุ่นโทรศัพท์และเวอร์ชันแอปจะถูกส่งไปด้วย ใช้เพื่อหาปัญหาให้เร็วขึ้นเท่านั้น',
    'uk': 'Модель телефона й версія застосунку теж надсилаються — лише щоб швидше знайти проблему.',
    'hi': 'फ़ोन मॉडल और ऐप वर्ज़न भी भेजे जाते हैं, सिर्फ़ समस्या जल्दी ढूंढने के लिए।',
    'ro': 'Se trimit și modelul telefonului și versiunea aplicației, doar ca să găsim problemele mai repede.',
    'cs': 'Odesílá se také model telefonu a verze aplikace – jen abychom rychleji našli problém.',
    'hu': 'A telefon típusát és az alkalmazás verzióját is elküldjük, csak a hibák gyorsabb megtalálásához.',
    'ar': 'يُرسل أيضًا طراز الهاتف وإصدار التطبيق، فقط لمساعدتنا في إيجاد المشكلات بسرعة.',
    'ur': 'فون ماڈل اور ایپ ورژن بھی بھیجا جاتا ہے، صرف مسئلہ جلد ڈھونڈنے کے لیے۔',
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
  '사진 붙이기': {
    'ja': '写真を添付',
    'zh': '添加图片',
    'zh_Hant': '新增圖片',
    'de': 'Foto anhängen',
    'es': 'Añadir foto',
    'fr': 'Ajouter une photo',
    'it': 'Aggiungi foto',
    'pt': 'Adicionar foto',
    'pl': 'Dodaj zdjęcie',
    'ru': 'Добавить фото',
    'tr': 'Fotoğraf ekle',
    'id': 'Tambah foto',
    'vi': 'Thêm ảnh',
    'th': 'แนบรูป',
    'uk': 'Додати фото',
    'hi': 'फ़ोटो जोड़ें',
    'ro': 'Adaugă foto',
    'cs': 'Přidat foto',
    'hu': 'Fotó hozzáadása',
    'ar': 'إضافة صورة',
    'ur': 'تصویر شامل کریں',
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
