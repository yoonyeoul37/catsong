import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/video.dart';

class VideoProvider extends ChangeNotifier {
  List<Video> _videos = [];
  bool _isLoading = false;
  String _errorMessage = '';

  static const _channel = MethodChannel('com.example.mp3_player/media');

  List<Video> get videos => _videos;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadVideos() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _channel.invokeMethod('getVideoList');
      final List<Video> foundVideos = [];
      int idCounter = 0;

      if (result != null) {
        for (final item in result) {
          final map = Map<String, dynamic>.from(item);
          foundVideos.add(Video(
            id: idCounter++,
            title: map['title'] ?? '제목 없음',
            uri: map['uri'] ?? '',
            duration: map['duration'] ?? 0,
          ));
        }
      }

      foundVideos.sort((a, b) => a.title.compareTo(b.title));
      _videos = foundVideos;
      debugPrint('비디오 스캔 완료: ${_videos.length}개');
      debugPrint('비디오 목록: ${foundVideos.map((v) => v.title).toList()}');
    } catch (e) {
      _errorMessage = '비디오 스캔 오류: $e';
      debugPrint('비디오 스캔 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}