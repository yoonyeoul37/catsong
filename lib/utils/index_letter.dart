/// 곡 제목 첫 글자로 빠른 이동 막대의 글자(A~Z / ㄱ~ㅎ / #)를 정한다.
const _chosung = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

// 쌍자음은 기본 자음으로 (ㄲ → ㄱ)
const _merge = {'ㄲ': 'ㄱ', 'ㄸ': 'ㄷ', 'ㅃ': 'ㅂ', 'ㅆ': 'ㅅ', 'ㅉ': 'ㅈ'};

/// 막대에 나오는 순서: A~Z → ㄱ~ㅎ → #
const kIndexOrder = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  '#',
];

String indexLetterOf(String text) {
  final t = text.trimLeft();
  if (t.isEmpty) return '#';
  final c = t.runes.first;
  // 한글 완성형 (가~힣) → 초성
  if (c >= 0xAC00 && c <= 0xD7A3) {
    final cho = _chosung[(c - 0xAC00) ~/ 588];
    return _merge[cho] ?? cho;
  }
  // 영어 → 대문자 (악센트 글자는 기본 글자로: Ä→A, É→E, Ñ→N)
  final latin = latinLetterOf(c);
  if (latin != null) return latin;
  // 숫자, 기호, 그 밖의 글자
  return '#';
}

/// 막대 항목: 영어는 A-Z 하나로 묶음
const kIndexGroups = [
  'A-Z',
  'ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  '#',
];

String indexGroupOf(String text) {
  final l = indexLetterOf(text);
  final c = l.codeUnitAt(0);
  return (c >= 65 && c <= 90) ? 'A-Z' : l;
}

// ───────── 폰 언어별 빠른 이동 막대 ─────────
// 한국어: A-Z · ㄱ~ㅎ · #   /   일본어: あ~わ · A-Z · #   /   그 밖(영어·중국어 등): A~Z · #

const _kAtoZ = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];
const _kKanaRows = ['あ', 'か', 'さ', 'た', 'な', 'は', 'ま', 'や', 'ら', 'わ'];
const _kIndexGroupsJa = [..._kKanaRows, 'A-Z', '#'];
const _kIndexGroupsLatin = [..._kAtoZ, '#'];
// 태국어: 자음 44개를 11묶음으로 (ก ข ง จ ญ ด บ ม ย ส อ) + A-Z + #
const _kThaiRows = ['ก', 'ข', 'ง', 'จ', 'ญ', 'ด', 'บ', 'ม', 'ย', 'ส', 'อ'];
const _kIndexGroupsTh = [..._kThaiRows, 'A-Z', '#'];
// 러시아어: А~Я (Ё→Е, Й→И, Ъ Ы Ь는 단어 첫 글자로 안 써서 뺌) + A-Z + #
const _kCyrRows = [
  'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'К', 'Л', 'М', 'Н', 'О',
  'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Э', 'Ю', 'Я',
];
const _kIndexGroupsRu = [..._kCyrRows, 'A-Z', '#'];
// 힌디어: 모음(अ) + 자음을 소리 나는 자리별 7묶음 (क च ट त प य श) + A-Z + #
const _kHindiRows = ['अ', 'क', 'च', 'ट', 'त', 'प', 'य', 'श'];
const _kIndexGroupsHi = [..._kHindiRows, 'A-Z', '#'];
// 아랍어·우르두어: 모양 비슷한 글자끼리 18칸 + A-Z + # (우르두어는 ک ہ ی 모양으로)
const _kArabicRows = ['ا', 'ب', 'ج', 'د', 'ر', 'س', 'ص', 'ط', 'ع', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];
const _kUrduRows = ['ا', 'ب', 'ج', 'د', 'ر', 'س', 'ص', 'ط', 'ع', 'ف', 'ق', 'ک', 'ل', 'م', 'ن', 'ہ', 'و', 'ی'];
const _kIndexGroupsAr = [..._kArabicRows, 'A-Z', '#'];
const _kIndexGroupsUr = [..._kUrduRows, 'A-Z', '#'];
// 첫 글자 → 몇 번째 칸
const _arabicGroupOf = <String, int>{
  'ا': 0, 'آ': 0, 'أ': 0, 'إ': 0, 'ٱ': 0, 'ء': 0,
  'ب': 1, 'ت': 1, 'ث': 1, 'پ': 1, 'ٹ': 1,
  'ج': 2, 'ح': 2, 'خ': 2, 'چ': 2,
  'د': 3, 'ذ': 3, 'ڈ': 3,
  'ر': 4, 'ز': 4, 'ڑ': 4, 'ژ': 4,
  'س': 5, 'ش': 5,
  'ص': 6, 'ض': 6,
  'ط': 7, 'ظ': 7,
  'ع': 8, 'غ': 8,
  'ف': 9,
  'ق': 10,
  'ك': 11, 'ک': 11, 'گ': 11,
  'ل': 12,
  'م': 13,
  'ن': 14, 'ں': 14,
  'ه': 15, 'ہ': 15, 'ھ': 15, 'ة': 15,
  'و': 16, 'ؤ': 16,
  'ي': 17, 'ى': 17, 'ی': 17, 'ے': 17, 'ئ': 17,
};

/// 아랍 글자 첫 글자 → 막대 칸, 아니면 null
String? _arabicRow(int c, bool urdu) {
  final i = _arabicGroupOf[String.fromCharCode(c)];
  if (i == null) return null;
  return (urdu ? _kUrduRows : _kArabicRows)[i];
}

/// 힌디어(데바나가리) 첫 글자 → 막대 칸, 아니면 null
String? _hindiRow(int c) {
  if ((c >= 0x0904 && c <= 0x0914) || c == 0x0960 || c == 0x0961 || (c >= 0x0972 && c <= 0x0977)) {
    return 'अ'; // 모음 글자 (अ आ इ ई उ ऊ ए ऐ ओ औ …)
  }
  if (c >= 0x0958 && c <= 0x095F) { // 점 붙은 자음 (क़ ख़ ग़ ज़ ड़ ढ़ फ़ य़)
    return const ['क', 'क', 'क', 'च', 'ट', 'ट', 'प', 'य'][c - 0x0958];
  }
  if (c < 0x0915 || c > 0x0939) return null;
  if (c <= 0x0919) return 'क'; // क ख ग घ ङ
  if (c <= 0x091E) return 'च'; // च छ ज झ ञ
  if (c <= 0x0923) return 'ट'; // ट ठ ड ढ ण
  if (c <= 0x0929) return 'त'; // त थ द ध न
  if (c <= 0x092E) return 'प'; // प फ ब भ म
  if (c <= 0x0935) return 'य'; // य र ल व
  return 'श'; // श ष स ह
}

/// 러시아어(키릴) 첫 글자 → 막대 칸, 아니면 null (우크라이나어 Є·І·Ї·Ґ도 비슷한 글자로)
String? _cyrRow(int c) {
  var up = String.fromCharCode(c).toUpperCase();
  up = const {'Ё': 'Е', 'Й': 'И', 'Є': 'Е', 'І': 'И', 'Ї': 'И', 'Ґ': 'Г'}[up] ?? up;
  return _kCyrRows.contains(up) ? up : null;
}

/// 태국어 제목 → 자음 묶음 (เ แ โ ใ ไ 처럼 자음 앞에 쓰는 모음은 건너뛰고 뒤 자음으로), 아니면 null
String? _thaiRow(String t) {
  for (final c in t.runes) {
    if (c >= 0x0E40 && c <= 0x0E44) continue; // 앞에 쓰는 모음
    if (c < 0x0E01 || c > 0x0E2E) return null; // 태국어 자음이 아님
    if (c == 0x0E01) return 'ก';
    if (c <= 0x0E06) return 'ข'; // ข ฃ ค ฅ ฆ
    if (c == 0x0E07) return 'ง';
    if (c <= 0x0E0C) return 'จ'; // จ ฉ ช ซ ฌ
    if (c <= 0x0E13) return 'ญ'; // ญ ฎ ฏ ฐ ฑ ฒ ณ
    if (c <= 0x0E19) return 'ด'; // ด ต ถ ท ธ น
    if (c <= 0x0E1F) return 'บ'; // บ ป ผ ฝ พ ฟ
    if (c <= 0x0E21) return 'ม'; // ภ ม
    if (c <= 0x0E27) return 'ย'; // ย ร ฤ ล ฦ ว
    if (c <= 0x0E2B) return 'ส'; // ศ ษ ส ห
    return 'อ'; // ฬ อ ฮ
  }
  return null;
}

/// 막대에 나오는 칸 (폰 언어 코드: ko, ja, en, zh ...)
List<String> indexGroupsFor(String lang) {
  if (lang == 'ko') return kIndexGroups;
  if (lang == 'ja') return _kIndexGroupsJa;
  if (lang == 'th') return _kIndexGroupsTh;
  if (lang == 'ru' || lang == 'uk') return _kIndexGroupsRu;
  if (lang == 'hi') return _kIndexGroupsHi;
  if (lang == 'ar') return _kIndexGroupsAr;
  if (lang == 'ur') return _kIndexGroupsUr;
  return _kIndexGroupsLatin;
}

/// 히라가나·가타카나 첫 글자 → 50음 줄 (あ か さ ...), 아니면 null
String? _kanaRow(int c) {
  if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60; // 가타카나 → 히라가나
  if (c >= 0x30F7 && c <= 0x30FA) return 'わ'; // ヷ ヸ ヹ ヺ
  if (c < 0x3041 || c > 0x3096) return null;
  if (c <= 0x304A || c == 0x3094) return 'あ';
  if (c <= 0x3054 || c == 0x3095 || c == 0x3096) return 'か';
  if (c <= 0x305E) return 'さ';
  if (c <= 0x3069) return 'た';
  if (c <= 0x306E) return 'な';
  if (c <= 0x307D) return 'は';
  if (c <= 0x3082) return 'ま';
  if (c <= 0x3088) return 'や';
  if (c <= 0x308D) return 'ら';
  return 'わ';
}

/// 곡 제목(또는 가수) → 막대 칸
String indexGroupFor(String text, String lang) {
  if (lang == 'ko') return indexGroupOf(text);
  final t = text.trimLeft();
  if (t.isEmpty) return '#';
  final c = t.runes.first;
  if (lang == 'th') {
    final row = _thaiRow(t);
    if (row != null) return row;
    return latinLetterOf(c) != null ? 'A-Z' : '#';
  }
  if (lang == 'ar' || lang == 'ur') {
    final row = _arabicRow(c, lang == 'ur');
    if (row != null) return row;
    return latinLetterOf(c) != null ? 'A-Z' : '#';
  }
  if (lang == 'hi') {
    final row = _hindiRow(c);
    if (row != null) return row;
    return latinLetterOf(c) != null ? 'A-Z' : '#';
  }
  if (lang == 'ru' || lang == 'uk') {
    final row = _cyrRow(c);
    if (row != null) return row;
    return latinLetterOf(c) != null ? 'A-Z' : '#';
  }
  final ch = latinLetterOf(c) ?? ''; // 악센트 글자는 기본 글자로 (Ä→A, É→E, Ñ→N, Đ→D)
  final isLatin = ch.isNotEmpty;
  if (lang == 'ja') {
    final row = _kanaRow(c);
    if (row != null) return row;
    return isLatin ? 'A-Z' : '#'; // 한자 제목은 읽는 법을 몰라서 #
  }
  return isLatin ? ch : '#';
}

// ───────── 악센트 글자 → 기본 글자 (Ä→A, É→E, Ñ→N, Đ→D, Ş→S, 베트남어 Ế→E …) ─────────
// 스페인어·포르투갈어·독일어·프랑스어·베트남어 제목도 A~Z 칸으로 (예전엔 전부 # 으로 갔음)
const _foldFrom =
    'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝŸĀĂĄĆĈĊČĎĒĔĖĘĚĜĞĠĢĤĨĪĬĮİĴĶĹĻĽŃŅŇŌŎŐŔŖŘŚŜŞŠŢŤŨŪŬŮŰŲŴŶŹŻŽƠƯǍǏǑǓǕǗǙǛǞǠǦǨǪǬǴǸǺȀȂȄȆȈȊȌȎȐȒȔȖȘȚȞȦȨȪȬȮȰȲḀḂḄḆḈḊḌḎḐḒḔḖḘḚḜḞḠḢḤḦḨḪḬḮḰḲḴḶḸḺḼḾṀṂṄṆṈṊṌṎṐṒṔṖṘṚṜṞṠṢṤṦṨṪṬṮṰṲṴṶṸṺṼṾẀẂẄẆẈẊẌẎẐẒẔẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼẾỀỂỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪỬỮỰỲỴỶỸĐŁØÆŒÞÐĦŦĿŊƗƵẞ';
const _foldTo =
    'AAAAAACEEEEIIIINOOOOOUUUUYYAAACCCCDEEEEEGGGGHIIIIIJKLLLNNNOOORRRSSSSTTUUUUUUWYZZZOUAIOUUUUUAAGKOOGNAAAEEIIOORRUUSTHAEOOOOYABBBCDDDDDEEEEEFGHHHHHIIKKKLLLLMMMNNNNOOOOPPRRRRSSSSSTTTTUUUUUVVWWWWWXXYZZZAAAAAAAAAAAAEEEEEEEEIIOOOOOOOOOOOOUUUUUUUYYYYDLOAOTDHTLNIZS';

/// 첫 글자 → 영어 대문자 A~Z (악센트는 기본 글자로, ß→S), 영어 글자가 아니면 null
String? latinLetterOf(int rune) {
  var up = String.fromCharCode(rune).toUpperCase();
  if (up.isEmpty) return null;
  up = up.substring(0, 1); // ß → SS 처럼 두 글자가 되면 첫 글자만
  final i = _foldFrom.indexOf(up);
  if (i >= 0) up = _foldTo[i];
  final u = up.codeUnitAt(0);
  return (u >= 65 && u <= 90) ? up : null;
}
