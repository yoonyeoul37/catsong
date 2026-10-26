import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import 'alarm_service.dart';
import 'headset_resume.dart';

/// 다른 앱(DownKit · 파일 앱 · 카톡 등)에서 "파란소리로 열기" → 바로 재생 화면 + 그 노래
/// - 앱이 꺼져 있어도, 켜져 있어도 (안드로이드 쪽 MainActivity가 'openAudio'로 주소를 보내 줌)
/// - 내 음악에 같은 파일이 있으면 그 곡으로, 없으면 앱 안에 잠깐 복사한 파일로 틀기
class OpenAudio {
  static const _ch = MethodChannel('kr.ssing.catsong/media');
  static const _route = '/open_audio_player';

  /// 넘겨받은 노래 주소 (첫인사 끄기 · 인삿말 안 하기에 씀)
  static final ValueNotifier<String?> target = ValueNotifier<String?>(null);

  static PlayerProvider? _pp;
  static MusicProvider? _music;
  static String? _last;
  static DateTime _lastAt = DateTime(2000);

  static void init(PlayerProvider pp, MusicProvider music) {
    _pp = pp;
    _music = music;
    final t = target.value;
    if (t != null) _run(t); // 준비 전에 먼저 온 노래
  }

  /// 앱 안에 잠깐 복사한 노래인지 (최근에 들었어요 · 재생 기록에 안 남기기)
  static bool isTemp(Song s) => (s.uri ?? '').contains('/opened_audio/');

  static void request(String uri) {
    // 같은 주소가 두 번 오면 한 번만 (켜질 때 두 길로 올 수 있어서)
    if (uri == _last && DateTime.now().difference(_lastAt) < const Duration(seconds: 3)) return;
    _last = uri;
    _lastAt = DateTime.now();
    target.value = uri;
    if (_pp != null) _run(uri);
  }

  static Future<void> _run(String uri) async {
    final pp = _pp, music = _music;
    if (pp == null || music == null) return;
    try {
      final m = await _ch.invokeMethod('prepareOpenAudio', {'uri': uri});
      if (m is! Map || uri != target.value) return; // 못 받았거나 그사이 다른 노래를 열었으면 그만
      Song? song;
      final libId = m['libId'];
      final libPath = m['libPath'];
      if (libId != null || libPath != null) {
        // 내 음악에 같은 파일이 있으면 그 곡 (즐겨찾기 · 가사가 그대로 이어짐)
        if (music.allSongs.isEmpty) {
          if (!music.isLoading) music.initialize();
          for (var k = 0; k < 20 && music.allSongs.isEmpty; k++) {
            await Future.delayed(const Duration(milliseconds: 250)); // 5초까지
          }
        }
        for (final s in music.allSongs) {
          if (libPath != null && s.uri == libPath) {
            song = s;
            break;
          }
        }
      }
      final path = m['path'] as String?;
      if (song == null && path != null) {
        final name = (m['name'] as String?) ?? '';
        final t = (m['title'] as String?)?.trim() ?? '';
        final art = m['art'];
        song = Song(
          id: -(path.hashCode.abs() + 1),
          title: t.isNotEmpty ? t : _noExt(name),
          artist: (m['artist'] as String?) ?? '',
          album: (m['album'] as String?) ?? '',
          uri: path,
          duration: int.tryParse('${m['duration'] ?? ''}') ?? 0,
          albumArt: art is Uint8List && art.isNotEmpty ? art.toList() : null,
        );
      }
      if (song == null || uri != target.value) return;
      final picked = song;
      // 다음·이전: 내 음악 목록 순서대로 (목록에 있는 곡은 그 자리부터 · 없는 곡은 맨 앞에 두고 목록 처음부터 이어서)
      if (music.allSongs.isEmpty) {
        if (!music.isLoading) music.initialize();
        for (var k = 0; k < 20 && music.allSongs.isEmpty; k++) {
          await Future.delayed(const Duration(milliseconds: 250)); // 5초까지
        }
      }
      var list = <Song>[picked];
      var start = 0;
      try {
        final order = (await HeadsetResume.screenOrder(music.allSongs)).where((x) => x.uri != null).toList();
        final i = order.indexWhere((x) => identical(x, picked) || x.uri == picked.uri);
        if (i >= 0) {
          list = order;
          start = i;
        } else {
          list = [picked, ...order];
        }
      } catch (_) {}
      if (uri != target.value) return; // 그사이 다른 노래를 열었으면 그만
      await pp.playFromList(list, start);
      _showPlayer();
    } catch (e) {
      debugPrint('다른 앱에서 연 노래 재생 오류: $e');
    }
  }

  static String _noExt(String n) {
    final i = n.lastIndexOf('.');
    return i > 0 ? n.substring(0, i) : n;
  }

  /// 음악 재생 화면 열기 (미니플레이어를 눌렀을 때와 같은 모양) · 앱 화면이 준비될 때까지 잠깐 기다림
  static void _showPlayer([int tries = 0]) {
    final nav = AlarmService.navKey.currentState;
    if (nav == null) {
      if (tries < 40) Future.delayed(const Duration(milliseconds: 150), () => _showPlayer(tries + 1));
      return;
    }
    nav.popUntil((r) => r.settings.name != _route); // 이미 이걸로 연 재생 화면이 있으면 닫고 새로
    nav.push(PageRouteBuilder(
      settings: const RouteSettings(name: _route),
      pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }
}
