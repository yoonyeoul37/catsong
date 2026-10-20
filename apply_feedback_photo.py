# -*- coding: utf-8 -*-
# 의견 보내기에 스샷(사진) 붙이기 — 최대 3장, 폰에서 줄여서(가로 1080 · 화질 75) 보내고 메일에 첨부로 와요
# (apply_feedback.py 를 먼저 돌린 다음에)
import os, sys

PATH = os.path.join('lib', 'screens', 'feedback_screen.dart')


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


if not os.path.exists(PATH):
    fail('feedback_screen.dart 가 없어요. apply_feedback.py 를 먼저 돌려 주세요')
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s


def rep(label, old, new, done):
    global s
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep('import', "import 'package:package_info_plus/package_info_plus.dart';\n",
    "import 'package:package_info_plus/package_info_plus.dart';\n"
    "import 'package:image_picker/image_picker.dart';\n",
    done="import 'package:image_picker/image_picker.dart';")

rep('사진 목록',
    '  bool _sending = false;\n',
    '  bool _sending = false;\n'
    '  final List<(XFile, Uint8List)> _photos = []; // 붙인 사진 (최대 3장 · 줄인 것)\n'
    '  static const _maxPhotos = 3;\n'
    '  static const _maxBytes = 3800000; // 메일 한 통 5MB 안에 들어가게 (글자로 바꾸면 커져서 넉넉히)\n',
    done='final List<(XFile, Uint8List)> _photos = [];')
rep('Uint8List import', "import 'dart:convert';\n", "import 'dart:convert';\nimport 'dart:typed_data';\n",
    done="import 'dart:typed_data';")

rep('사진 고르기',
    '  void _buzz() => const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n',
    '  void _buzz() => const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n'
    '\n'
    '  /// 갤러리에서 스샷 고르기 — 폰에서 줄여서 (가로 1080 · 화질 75 → 보통 한 장 150~400KB)\n'
    '  Future<void> _pickPhotos() async {\n'
    '    _buzz();\n'
    '    if (_photos.length >= _maxPhotos) return;\n'
    '    try {\n'
    '      final picked = await ImagePicker().pickMultiImage(maxWidth: 1080, maxHeight: 2400, imageQuality: 75);\n'
    '      for (final f in picked) {\n'
    '        if (_photos.length >= _maxPhotos) break;\n'
    '        final bytes = await f.readAsBytes();\n'
    '        if (!mounted) return;\n'
    '        setState(() => _photos.add((f, bytes)));\n'
    '      }\n'
    '    } catch (_) {}\n'
    '  }\n',
    done='Future<void> _pickPhotos() async {')

rep('보낼 때 사진도 같이 (너무 크면 넘는 것 빼기)',
    "    var ok = false;\n    try {\n      final r = await http\n",
    "    // 사진: 합쳐서 너무 크면 넘는 사진은 빼고 보내기\n"
    "    final photos = <Map<String, String>>[];\n"
    "    var total = 0, dropped = false;\n"
    "    for (var i = 0; i < _photos.length; i++) {\n"
    "      final b = _photos[i].$2;\n"
    "      if (total + b.length > _maxBytes) {\n"
    "        dropped = true;\n"
    "        continue;\n"
    "      }\n"
    "      total += b.length;\n"
    "      final n = _photos[i].$1.name.toLowerCase();\n"
    "      final png = n.endsWith('.png');\n"
    "      photos.add({\n"
    "        'name': 'screenshot${i + 1}.${png ? 'png' : 'jpg'}',\n"
    "        'type': png ? 'image/png' : 'image/jpeg',\n"
    "        'data': base64Encode(b),\n"
    "      });\n"
    "    }\n"
    "    var ok = false;\n    try {\n      final r = await http\n",
    done="// 사진: 합쳐서 너무 크면 넘는 사진은 빼고 보내기")
rep('보내는 내용에 사진',
    "              'lang': tr.localeName,\n            }),\n",
    "              'lang': tr.localeName,\n              'photos': photos,\n            }),\n",
    done="'photos': photos,")
rep('기다리는 시간 (사진 있으면 넉넉히)',
    "          .timeout(const Duration(seconds: 15));\n      ok = r.statusCode == 200",
    "          .timeout(Duration(seconds: photos.isEmpty ? 15 : 40));\n      ok = r.statusCode == 200",
    done="Duration(seconds: photos.isEmpty ? 15 : 40)")
rep('보낸 뒤 알림 (일부 사진을 뺐으면)',
    "      showParanToast(context, fbText('보내 주셔서 고마워요', 'Thanks for your feedback'));\n",
    "      showParanToast(\n"
    "          context,\n"
    "          dropped\n"
    "              ? fbText('사진이 너무 커서 일부만 보냈어요', 'Some photos were too large and were left out')\n"
    "              : fbText('보내 주셔서 고마워요', 'Thanks for your feedback'));\n",
    done="fbText('사진이 너무 커서 일부만 보냈어요'")

rep('글 칸 아래에 사진 줄',
    "              const SizedBox(height: 8),\n              // 이메일 (선택)\n",
    "              const SizedBox(height: 8),\n"
    "              // 사진 (스샷) — 작은 미리보기 + ✕ / 3장 안 됐으면 '+ 사진 붙이기'\n"
    "              SizedBox(\n"
    "                height: 64,\n"
    "                child: Row(\n"
    "                  children: [\n"
    "                    for (var i = 0; i < _photos.length; i++) ...[\n"
    "                      Stack(\n"
    "                        clipBehavior: Clip.none,\n"
    "                        children: [\n"
    "                          ClipRRect(\n"
    "                            borderRadius: BorderRadius.circular(10),\n"
    "                            child: Image.memory(_photos[i].$2, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 192),\n"
    "                          ),\n"
    "                          Positioned(\n"
    "                            top: -6,\n"
    "                            right: -6,\n"
    "                            child: GestureDetector(\n"
    "                              onTap: () {\n"
    "                                _buzz();\n"
    "                                setState(() => _photos.removeAt(i));\n"
    "                              },\n"
    "                              child: Container(\n"
    "                                width: 22,\n"
    "                                height: 22,\n"
    "                                decoration: BoxDecoration(color: ink, shape: BoxShape.circle, border: Border.all(color: bg, width: 2)),\n"
    "                                child: Icon(Icons.close_rounded, size: 12, color: bg),\n"
    "                              ),\n"
    "                            ),\n"
    "                          ),\n"
    "                        ],\n"
    "                      ),\n"
    "                      const SizedBox(width: 10),\n"
    "                    ],\n"
    "                    if (_photos.length < _maxPhotos)\n"
    "                      Expanded(\n"
    "                        child: GestureDetector(\n"
    "                          onTap: _pickPhotos,\n"
    "                          child: Container(\n"
    "                            height: 64,\n"
    "                            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)),\n"
    "                            child: Row(\n"
    "                              mainAxisAlignment: MainAxisAlignment.center,\n"
    "                              children: [\n"
    "                                Icon(Icons.add_photo_alternate_outlined, size: 20, color: sub),\n"
    "                                const SizedBox(width: 6),\n"
    "                                Flexible(\n"
    "                                  child: Text('${fbText('사진 붙이기', 'Add photo')}  ${_photos.length}/$_maxPhotos',\n"
    "                                      maxLines: 1,\n"
    "                                      overflow: TextOverflow.ellipsis,\n"
    "                                      style: TextStyle(color: sub, fontSize: 13.5, fontWeight: FontWeight.w500)),\n"
    "                                ),\n"
    "                              ],\n"
    "                            ),\n"
    "                          ),\n"
    "                        ),\n"
    "                      ),\n"
    "                  ],\n"
    "                ),\n"
    "              ),\n"
    "              const SizedBox(height: 8),\n"
    "              // 이메일 (선택)\n",
    done="onTap: _pickPhotos,")

# 번역표에 새 글자 2개
NEW_TR = {
    '사진 붙이기': ['写真を添付', '添加图片', '新增圖片', 'Foto anhängen', 'Añadir foto', 'Ajouter une photo', 'Aggiungi foto', 'Adicionar foto', 'Dodaj zdjęcie', 'Добавить фото', 'Fotoğraf ekle', 'Tambah foto', 'Thêm ảnh', 'แนบรูป', 'Додати фото', 'फ़ोटो जोड़ें', 'Adaugă foto', 'Přidat foto', 'Fotó hozzáadása', 'إضافة صورة', 'تصویر شامل کریں'],
    '사진이 너무 커서 일부만 보냈어요': ['写真が大きすぎるため、一部だけ送信しました', '图片太大，只发送了部分', '圖片太大，只傳送了部分', 'Einige Fotos waren zu groß und wurden nicht gesendet', 'Algunas fotos eran demasiado grandes y no se enviaron', 'Certaines photos étaient trop lourdes et n’ont pas été envoyées', 'Alcune foto erano troppo grandi e non sono state inviate', 'Algumas fotos eram grandes demais e não foram enviadas', 'Niektóre zdjęcia były za duże i nie zostały wysłane', 'Некоторые фото слишком большие и не отправлены', 'Bazı fotoğraflar çok büyük olduğu için gönderilmedi', 'Beberapa foto terlalu besar dan tidak terkirim', 'Một số ảnh quá lớn nên không được gửi', 'บางรูปใหญ่เกินไปจึงไม่ได้ส่ง', 'Деякі фото завеликі й не надіслані', 'कुछ फ़ोटो बहुत बड़ी थीं, इसलिए नहीं भेजी गईं', 'Unele fotografii erau prea mari și nu au fost trimise', 'Některé fotky byly příliš velké a nebyly odeslány', 'Néhány fotó túl nagy volt, ezért nem küldtük el', 'بعض الصور كبيرة جدًا ولم تُرسل', 'کچھ تصاویر بہت بڑی تھیں اس لیے نہیں بھیجی گئیں'],
}
LANGS = ['ja', 'zh', 'zh_Hant', 'de', 'es', 'fr', 'it', 'pt', 'pl', 'ru', 'tr', 'id', 'vi', 'th', 'uk', 'hi', 'ro', 'cs', 'hu', 'ar', 'ur']


def q(x):
    return "'" + x.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


if "  '사진 붙이기': {" not in s:
    block = ''
    for k, v in NEW_TR.items():
        block += f'  {q(k)}: {{\n' + ''.join(f'    {q(l)}: {q(x)},\n' for l, x in zip(LANGS, v)) + '  },\n'
    end = s.rfind('};')
    if end < 0:
        fail('번역표 끝을 못 찾았어요')
    s = s[:end] + block + s[end:]
    print('✔ 번역표에 새 글자 2개 (23개 언어)')
else:
    print('✔ 번역표에 새 글자 2개 (이미 돼 있음)')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
