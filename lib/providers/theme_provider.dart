import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFF06858B);
  double _textScale = 1.12;
  String _fontFamily = 'default';

  Color get primaryColor => _primaryColor;
  double get textScale => _textScale;
  String get fontFamily => _fontFamily;

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
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    if (textScale != null) {
      _textScale = textScale;
    }
    if (fontFamily != null) {
      _fontFamily = fontFamily;
    }
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