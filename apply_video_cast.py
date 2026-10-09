# -*- coding: utf-8 -*-
# 동영상도 TV로 보기 (구글 캐스트 · 스마트 TV)
# - 동영상 재생화면 위쪽에 TV 버튼 → TV 고르기 → TV에서 보던 곳부터 재생
# - TV로 보는 동안 폰 화면: TV 이름 + 재생/일시정지 + "폰에서 이어 보기"
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
CAST = os.path.join(ROOT, 'lib', 'services', 'cast_service.dart')
SHEETS = os.path.join(ROOT, 'lib', 'widgets', 'cast_sheets.dart')
VIDEO = os.path.join(ROOT, 'lib', 'screens', 'video_screen.dart')

CAST_VIDEO_CODE = r'''  // ───────────────── 동영상 보내기 ─────────────────
  bool get isVideo => _isVideo;

  /// 지금 TV 재생 위치 (어림값) — 폰으로 돌아올 때 이어 보기용
  Duration get tvPosition => _tvPos;

  /// 동영상: 처음 TV에 연결하면서 보내기
  Future<bool> connectVideo(CastDevice device,
      {required String path, required String title, int startSec = 0}) async {
    _device = device;
    try {
      if (device.kind == CastKind.google) {
        _gc = _GoogleCast(device.host);
        _gc!.onMediaStatus = _onGoogleStatus;
        await _gc!.connect();
      }
    } catch (e) {
      debugPrint('구글 캐스트 연결 오류: $e');
      _gc?.close();
      _gc = null;
      _device = null;
      notifyListeners();
      return false;
    }
    final ok = await castVideo(path: path, title: title, startSec: startSec);
    if (!ok) {
      await disconnect();
      return false;
    }
    if (device.kind == CastKind.dlna) _startPolling();
    return true;
  }

  /// 동영상 파일을 폰 서버로 TV에 보내기 (startSec부터)
  Future<bool> castVideo({required String path, required String title, int startSec = 0}) async {
    if (_device == null) return false;
    _currentUri = path;
    _isRadio = false;
    _isVideo = true;
    _song = null; // 파란포토 사진 다시 보내기 안 하게
    try {
      final url = await _serve(path);
      if (url == null) return false;
      _artBytes = null;
      final mime = _mime(path);
      _cmdAt = DateTime.now();
      if (_device!.kind == CastKind.google) {
        await _gc!.load(url, mime, title, '', '', startSec: startSec, metadataType: 0);
      } else {
        final meta = '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
            'xmlns:dc="http://purl.org/dc/elements/1.1/" '
            'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
            '<item id="1" parentID="0" restricted="1">'
            '<dc:title>${_escape(title)}</dc:title>'
            '<upnp:class>object.item.videoItem</upnp:class>'
            '<res protocolInfo="http-get:*:$mime:*">${_escape(url)}</res>'
            '</item></DIDL-Lite>';
        await _soap('SetAVTransportURI',
            '<InstanceID>0</InstanceID><CurrentURI>${_escape(url)}</CurrentURI>'
                '<CurrentURIMetaData>${_escape(meta)}</CurrentURIMetaData>');
        await _soap('Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
        if (startSec > 0) {
          final s = startSec;
          final hms = '${s ~/ 3600}:${((s ~/ 60) % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
          try {
            await _soap('Seek', '<InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>$hms</Target>');
          } catch (_) {}
        }
      }
      _cmdAt = DateTime.now();
      _tvPlaying = true;
      _wasPlaying = true;
      _posBase = Duration(seconds: startSec);
      _posAt = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('동영상 TV로 보내기 오류: $e');
      return false;
    }
  }

  /// 파란포토 사진 정하기 (null이면 곡 앨범 사진)'''

CAST_EDITS = [
    ('TV: 동영상 보내는 중 표시',
     "bool _isRadio = false; // 라디오를 보내는 중인지 (라디오는 \"곡 끝\"이 없음)\n",
     "bool _isRadio = false; // 라디오를 보내는 중인지 (라디오는 \"곡 끝\"이 없음)\n"
     "bool _isVideo = false; // 동영상을 보내는 중인지 (끝나도 다음 곡으로 안 넘어감)\n"),
    ('TV: 곡 보낼 땐 동영상 아님',
     "    _currentUri = song.uri; // 먼저 적어둬서 같은 곡을 여러 번 보내지 않게\n"
     "    _isRadio = false;\n",
     "    _currentUri = song.uri; // 먼저 적어둬서 같은 곡을 여러 번 보내지 않게\n"
     "    _isRadio = false;\n"
     "    _isVideo = false;\n"),
    ('TV: 라디오 보낼 땐 동영상 아님',
     "    _isRadio = true;\n    _proxyHeaders = headers;\n",
     "    _isRadio = true;\n    _isVideo = false;\n    _proxyHeaders = headers;\n"),
    ('TV: 동영상 보내기 추가',
     "  /// 파란포토 사진 정하기 (null이면 곡 앨범 사진)",
     CAST_VIDEO_CODE),
    ('TV: 동영상일 땐 사진 다시 보내기 안 함',
     "    if (_device == null || _isRadio || _song == null || _song!.uri == null) return;\n",
     "    if (_device == null || _isRadio || _isVideo || _song == null || _song!.uri == null) return;\n"),
    ('TV: 연결 끊으면 동영상 표시도 끄기',
     "    _currentUri = null;\n    await _server?.close(force: true);\n",
     "    _currentUri = null;\n    _isVideo = false;\n    await _server?.close(force: true);\n"),
    ('TV: 동영상 형식 알려주기',
     "String _mime(String path) {\n"
     "    final ext = path.split('.').last.toLowerCase();\n"
     "    switch (ext) {\n",
     "String _mime(String path) {\n"
     "    final ext = path.split('.').last.toLowerCase();\n"
     "    if (_isVideo) {\n"
     "      switch (ext) {\n"
     "        case 'webm':\n"
     "          return 'video/webm';\n"
     "        case 'mkv':\n"
     "          return 'video/x-matroska';\n"
     "        case '3gp':\n"
     "          return 'video/3gpp';\n"
     "        case 'mov':\n"
     "          return 'video/quicktime';\n"
     "        default:\n"
     "          return 'video/mp4';\n"
     "      }\n"
     "    }\n"
     "    switch (ext) {\n"),
    ('구글 캐스트: 동영상 정보 형식',
     "      {bool live = false, int startSec = 0}) async {\n",
     "      {bool live = false, int startSec = 0, int metadataType = 3}) async {\n"),
    ('구글 캐스트: 동영상 정보 형식 적용',
     "'metadataType': 3,\n",
     "'metadataType': metadataType,\n"),
]
# 곡 끝 → 다음 곡: 동영상일 땐 안 넘어가게 (2군데)
CAST_ALL = [
    ('TV: 동영상 끝나도 다음 곡으로 안 넘어가게',
     "if (!_isRadio) onTrackEnded?.call();",
     "if (!_isRadio && !_isVideo) onTrackEnded?.call();", 2),
]

SHEET_EDITS = [
    ('TV 고르기 창: 제목 바꿀 수 있게',
     "void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick}) {\n",
     "void showCastPickerSheet(BuildContext context,\n"
     "    {required Future<bool> Function(CastDevice) onPick, String title = 'TV로 듣기'}) {\n"),
    ('TV 고르기 창: 제목 적용',
     "                      child: Text('TV로 듣기',\n",
     "                      child: Text(title,\n"),
]

VIDEO_STATE_CODE = r'''  // ───── TV로 보기 (구글 캐스트 · 스마트 TV) ─────
  bool get _castingHere {
    final c = CastService.instance;
    return c.isConnected && c.isVideo && c.currentUri == widget.video.uri;
  }

  Future<void> _openCast() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final cast = CastService.instance;
    if (_castingHere) {
      showCastControlSheet(context, nowPlaying: widget.video.titleDisplay);
      return;
    }
    // 폰은 멈추고, 보던 곳부터 TV로
    Future<bool> send(Future<bool> Function(int startSec) go) async {
      if (!_videoPlayerController.value.isInitialized) return false;
      final pos = _videoPlayerController.value.position.inSeconds;
      _videoPlayerController.pause();
      final ok = await go(pos);
      if (!ok && mounted) _videoPlayerController.play();
      return ok;
    }

    if (cast.isConnected) {
      // 이미 TV에 연결돼 있으면 (음악 보내던 중 등) 같은 TV로 바로
      final ok = await send((s) =>
          cast.castVideo(path: widget.video.uri, title: widget.video.titleDisplay, startSec: s));
      if (!ok && mounted) showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);
      return;
    }
    showCastPickerSheet(
      context,
      title: 'TV로 보기',
      onPick: (d) => send((s) =>
          cast.connectVideo(d, path: widget.video.uri, title: widget.video.titleDisplay, startSec: s)),
    );
  }

  /// TV → 폰으로 돌아오기 (TV에서 보던 곳부터 이어서)
  Future<void> _backToPhone() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final cast = CastService.instance;
    final pos = cast.tvPosition;
    await cast.disconnect();
    if (!mounted) return;
    await _videoPlayerController.seekTo(pos);
    _videoPlayerController.play();
  }

  /// TV로 보는 동안 폰 화면
  Widget _castPanel() {
    final cast = CastService.instance;
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv_rounded, color: Colors.white70, size: 46),
          const SizedBox(height: 12),
          Text('${cast.device?.name ?? 'TV'}에서 보는 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.video.titleDisplay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              cast.tvPlaying ? cast.pause() : cast.play();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Color(0xFFF3EFE7), shape: BoxShape.circle),
              child: Icon(cast.tvPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF17140F), size: 32),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _backToPhone,
            child: const Text('폰에서 이어 보기',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38)),
          ),
        ],
      ),
    );
  }

  // ───── 재생 화면 편의 기능: 두 번 탭 10초 · 재생 속도 · 구간 반복 ─────'''

VIDEO_EDITS = [
    ('동영상: TV 파일 연결',
     "import 'video_trim_screen.dart';\n",
     "import 'video_trim_screen.dart';\n"
     "import '../services/cast_service.dart';\n"
     "import '../widgets/cast_sheets.dart';\n"),
    ('동영상: TV로 보기 기능',
     "  // ───── 재생 화면 편의 기능: 두 번 탭 10초 · 재생 속도 · 구간 반복 ─────",
     VIDEO_STATE_CODE),
    ('동영상: 위쪽 TV 버튼',
     "        actions: [\n"
     "          PopupMenuButton<String>(\n"
     "            icon: const Icon(Icons.more_vert, color: Colors.white),\n",
     "        actions: [\n"
     "          // TV로 보기\n"
     "          AnimatedBuilder(\n"
     "            animation: CastService.instance,\n"
     "            builder: (context, _) => IconButton(\n"
     "              onPressed: _openCast,\n"
     "              icon: Icon(_castingHere ? Icons.cast_connected_rounded : Icons.cast_rounded,\n"
     "                  color: Colors.white, size: 22),\n"
     "            ),\n"
     "          ),\n"
     "          PopupMenuButton<String>(\n"
     "            icon: const Icon(Icons.more_vert, color: Colors.white),\n"),
    ('동영상: TV로 보는 동안 화면',
     "                        ],\n"
     "                      )\n"
     "                    : const CircularProgressIndicator(color: Colors.white),\n",
     "                          // TV로 보는 중이면 화면을 가리고 TV 조작\n"
     "                          Positioned.fill(\n"
     "                            child: AnimatedBuilder(\n"
     "                              animation: CastService.instance,\n"
     "                              builder: (context, _) =>\n"
     "                                  _castingHere ? _castPanel() : const IgnorePointer(child: SizedBox.shrink()),\n"
     "                            ),\n"
     "                          ),\n"
     "                        ],\n"
     "                      )\n"
     "                    : const CircularProgressIndicator(color: Colors.white),\n"),
    ('동영상: 화면 나가면 TV도 정지',
     "    _videoPlayerController.removeListener(_loopTick);\n"
     "    try {\n"
     "      _savePosition(); // 나갈 때 멈춘 곳 기억\n"
     "    } catch (_) {}\n",
     "    _videoPlayerController.removeListener(_loopTick);\n"
     "    if (_castingHere) CastService.instance.disconnect(); // 화면을 나가면 TV도 정지\n"
     "    try {\n"
     "      _savePosition(); // 나갈 때 멈춘 곳 기억\n"
     "    } catch (_) {}\n"),
]

MARK = 'connectVideo'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def run(path, edits, all_edits, out):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    before = balanced(text)
    ok = True
    for name, old, new in edits:
        if text.count(old) != 1:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    for name, old, new, n in all_edits:
        if text.count(old) != n:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    if before and not balanced(text):
        print('❌ 괄호가 안 맞아요:', os.path.basename(path))
        ok = False
    out.append((path, text.replace('\n', '\r\n') if crlf else text))
    return ok


def main():
    for p in (CAST, SHEETS, VIDEO):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(CAST, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = run(CAST, CAST_EDITS, CAST_ALL, out)
    ok = run(SHEETS, SHEET_EDITS, [], out) and ok
    ok = run(VIDEO, VIDEO_EDITS, [], out) and ok
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
