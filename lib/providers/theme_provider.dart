import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFF2589E8); // 포인트 색 (기본: 파란소리)
  double _textScale = 1.12;
  String _fontFamily = 'default';
  bool _isDarkMode = false;
  bool _seasonalEffectEnabled = true;
  bool _voiceGreetingEnabled = true;
  bool _feedbackSoundEnabled = true; // 완료 효과음 (물방울 소리·진동)

  Color get primaryColor => _primaryColor;

  /// 포인트 색 8가지 (설정 → 포인트 색) — 체크·스위치·막대 같은 작은 곳의 색
  static const pointColors = <(String, Color)>[
    ('파란소리', Color(0xFF2589E8)),
    ('숲', Color(0xFF3E8E6A)),
    ('노을', Color(0xFFE07A4F)),
    ('라벤더', Color(0xFF8A6FD1)),
    ('먹색', Color(0xFF4A4038)),
    ('벚꽃', Color(0xFFD46A8C)),
    ('바다', Color(0xFF1F9AA0)),
    ('햇살', Color(0xFFC4962C)),
    ('와인', Color(0xFFA6474F)),
    ('밤하늘', Color(0xFF3F51A3)),
  ];

  /// 지금 포인트 색 이름 (예전에 고른 다른 색이면 null)
  String? get pointColorName {
    for (final c in pointColors) {
      if (c.$2.value == _primaryColor.value) return c.$1;
    }
    return null;
  }
  double get textScale => _textScale;
  String get fontFamily => _fontFamily;
  bool get isDarkMode => _isDarkMode;
  bool get seasonalEffectEnabled => _seasonalEffectEnabled;
  bool get voiceGreetingEnabled => _voiceGreetingEnabled;
  bool get feedbackSoundEnabled => _feedbackSoundEnabled;

  Future<void> setFeedbackSoundEnabled(bool value) async {
    _feedbackSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feedbackSoundEnabled', value);
    notifyListeners();
  }

  Future<void> setVoiceGreetingEnabled(bool value) async {
    _voiceGreetingEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voiceGreetingEnabled', value);
    notifyListeners();
  }

  Future<void> setSeasonalEffectEnabled(bool value) async {
    _seasonalEffectEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seasonalEffectEnabled', value);
    notifyListeners();
  }

  /// 라이트/다크에 맞는 상단 상태바·하단 시스템 바 설정
  SystemUiOverlayStyle get systemBarStyle => _isDarkMode
      ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF24221F),
          systemNavigationBarIconBrightness: Brightness.light,
        )
      : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFEDE7DA),
          systemNavigationBarIconBrightness: Brightness.dark,
        );

  /// 라이트/다크에 맞게 상단 상태바·하단 시스템 바 아이콘 색을 맞춘다
  void _applySystemBars() {
    SystemChrome.setSystemUIOverlayStyle(
      _isDarkMode
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Color(0xFF24221F),
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Color(0xFFEDE7DA),
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    _applySystemBars();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  static const List<Map<String, String>> availableFonts = [
    {'key': 'default', 'name': 'Default Font'},
    {'key': 'noto_sans', 'name': 'Noto Sans KR (Clean)'},
    {'key': 'jua', 'name': 'Jua (Cute)'},
    {'key': 'gaegu', 'name': 'Gaegu (Handwriting)'},
    {'key': 'nanum_gothic', 'name': 'Nanum Gothic (Soft)'},
    {'key': 'do_hyeon', 'name': 'Do Hyeon (Modern)'},
    {'key': 'cute_font', 'name': 'Cute Font (Cute)'},
    {'key': 'stylish', 'name': 'Stylish (Elegant)'},
    {'key': 'sunflower', 'name': 'Sunflower (Light)'},
    {'key': 'hi_melody', 'name': 'Hi Melody (Emotional)'},
    {'key': 'poor_story', 'name': 'Poor Story (Handwriting)'},
    {'key': 'east_sea_dokdo', 'name': 'East Sea Dokdo (Unique)'},
    {'key': 'nanum_brush', 'name': 'Nanum Brush Script (Brush)'},
    {'key': 'nanum_myeongjo', 'name': 'Nanum Myeongjo (Serif)'},
    {'key': 'black_and_white', 'name': 'Black And White Picture (Special)'},
    {'key': 'gowun_dodum', 'name': 'Gowun Dodum (Round)'},
    {'key': 'gowun_batang', 'name': 'Gowun Batang (Batang)'},
    {'key': 'nanum_pen', 'name': 'Nanum Pen Script (Pen)'},
    {'key': 'single_day', 'name': 'Single Day (Cute)'},
    {'key': 'yeon_sung', 'name': 'Yeon Sung (Soft)'},
  ];
  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('primaryColor');
    final textScale = prefs.getDouble('textScale');
    final fontFamily = prefs.getString('fontFamily');
    final isDarkMode = prefs.getBool('isDarkMode');
    final seasonalEffectEnabled = prefs.getBool('seasonalEffectEnabled');
    final voiceGreetingEnabled = prefs.getBool('voiceGreetingEnabled');
    final feedbackSoundEnabled = prefs.getBool('feedbackSoundEnabled');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    if (textScale != null) {
      _textScale = textScale;
    }
    if (fontFamily != null) {
      _fontFamily = fontFamily;
    }
    if (isDarkMode != null) {
      _isDarkMode = isDarkMode;
    }
    if (seasonalEffectEnabled != null) {
      _seasonalEffectEnabled = seasonalEffectEnabled;
    }
    if (voiceGreetingEnabled != null) {
      _voiceGreetingEnabled = voiceGreetingEnabled;
    }
    if (feedbackSoundEnabled != null) {
      _feedbackSoundEnabled = feedbackSoundEnabled;
    }
    _applySystemBars();
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', scale);
    notifyListeners();
  }

  Future<void> setFontFamily(String fontKey) async {
    _fontFamily = fontKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', fontKey);
    notifyListeners();
  }

  TextTheme getTextTheme() {
    switch (_fontFamily) {
      case 'noto_sans':
        return GoogleFonts.notoSansKrTextTheme();
      case 'jua':
        return GoogleFonts.juaTextTheme();
      case 'gaegu':
        return GoogleFonts.gaeguTextTheme();
      case 'nanum_gothic':
        return GoogleFonts.nanumGothicTextTheme();
      case 'do_hyeon':
        return GoogleFonts.doHyeonTextTheme();
      case 'cute_font':
        return GoogleFonts.cuteFontTextTheme();
      case 'stylish':
        return GoogleFonts.stylishTextTheme();
      case 'sunflower':
        return GoogleFonts.sunflowerTextTheme();
      case 'hi_melody':
        return GoogleFonts.hiMelodyTextTheme();
      case 'poor_story':
        return GoogleFonts.poorStoryTextTheme();
      case 'east_sea_dokdo':
        return GoogleFonts.eastSeaDokdoTextTheme();
      case 'nanum_brush':
        return GoogleFonts.nanumBrushScriptTextTheme();
      case 'nanum_myeongjo':
        return GoogleFonts.nanumMyeongjoTextTheme();
      case 'black_and_white':
        return GoogleFonts.blackAndWhitePictureTextTheme();
      case 'gowun_dodum':
        return GoogleFonts.gowunDodumTextTheme();
      case 'gowun_batang':
        return GoogleFonts.gowunBatangTextTheme();
      case 'nanum_pen':
        return GoogleFonts.nanumPenScriptTextTheme();
      case 'single_day':
        return GoogleFonts.singleDayTextTheme();
      case 'yeon_sung':
        return GoogleFonts.yeonSungTextTheme();
      default:
        return const TextTheme();
    }
  }
}