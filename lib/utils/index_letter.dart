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
  // 영어 → 대문자
  final ch = String.fromCharCode(c).toUpperCase();
  if (ch.length == 1 && ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) {
    return ch;
  }
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