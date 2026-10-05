import 'song.dart';

/// 통화 녹음 파일 하나 (일반 음악과 따로 관리)
/// 삼성 파일 이름 예: "통화 녹음 101호 김명○_250530_121928.m4a"
class CallRecording {
  final String path;
  final String name; // 상대방 이름 또는 번호
  final DateTime dateTime; // 통화한 날짜·시간
  int durationMs; // 통화 길이 (나중에 읽어서 채움)
  final bool isVoice; // 음성 녹음(녹음기 앱)이면 true

  CallRecording({
    required this.path,
    required this.name,
    required this.dateTime,
    this.durationMs = 0,
    this.isVoice = false,
  });

  /// 파일 이름에서 이름·날짜 뽑기 (모양이 다르면 파일 이름·수정 시간 사용)
  factory CallRecording.fromPath(String path, DateTime fallbackTime, {bool isVoice = false}) {
    final file = path.split('/').last;
    final base = file.replaceAll(RegExp(r'\.[^.]+$'), '');
    // 음성 녹음은 이름에 날짜가 없어서 (예: 음성 001.m4a) 파일 이름 + 저장된 시간 사용
    if (isVoice) {
      // 파란소리 녹음은 이름에 날짜가 있음 (예: 녹음 251006_110930)
      final v = RegExp(r'^(.*?)\s*(\d{6})_(\d{6})$').firstMatch(base);
      if (v != null) {
        final d = v.group(2)!;
        final t = v.group(3)!;
        final dt = DateTime(
          2000 + int.parse(d.substring(0, 2)),
          int.parse(d.substring(2, 4)),
          int.parse(d.substring(4, 6)),
          int.parse(t.substring(0, 2)),
          int.parse(t.substring(2, 4)),
          int.parse(t.substring(4, 6)),
        );
        final n = v.group(1)!.trim();
        return CallRecording(path: path, name: n.isEmpty ? '녹음' : n, dateTime: dt, isVoice: true);
      }
      return CallRecording(path: path, name: base, dateTime: fallbackTime, isVoice: true);
    }
    final m = RegExp(r'^(?:통화 녹음|Call recording)\s*(.*?)_(\d{6})_(\d{6})$', caseSensitive: false)
        .firstMatch(base);
    if (m != null) {
      final d = m.group(2)!;
      final t = m.group(3)!;
      final dt = DateTime(
        2000 + int.parse(d.substring(0, 2)),
        int.parse(d.substring(2, 4)),
        int.parse(d.substring(4, 6)),
        int.parse(t.substring(0, 2)),
        int.parse(t.substring(2, 4)),
        int.parse(t.substring(4, 6)),
      );
      final name = m.group(1)!.trim();
      return CallRecording(path: path, name: name.isEmpty ? '알 수 없음' : name, dateTime: dt);
    }
    return CallRecording(path: path, name: base, dateTime: fallbackTime);
  }

  /// 재생할 때 쓰는 곡 모양으로 (id는 일반 음악과 안 겹치게 음수)
  Song toSong(int index) => Song(
    id: -100000 - index,
    title: name,
    artist: isVoice ? '음성 녹음' : '통화 녹음',
    album: '',
    uri: path,
    duration: durationMs,
  );

  /// 예: 5월 30일 (금) 오후 12:19
  String get dateLabel {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final h = dateTime.hour;
    final ampm = h < 12 ? '오전' : '오후';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final year = dateTime.year != now.year ? '${dateTime.year}년 ' : '';
    return '$year${dateTime.month}월 ${dateTime.day}일 (${days[dateTime.weekday - 1]}) $ampm $h12:$mm';
  }

  /// 예: 1분 23초 / 45초 / 1시간 2분
  String get durationLabel {
    if (durationMs <= 0) return '';
    final s = durationMs ~/ 1000;
    if (s >= 3600) return '${s ~/ 3600}시간 ${(s % 3600) ~/ 60}분';
    if (s >= 60) return '${s ~/ 60}분 ${s % 60}초';
    return '$s초';
  }
}