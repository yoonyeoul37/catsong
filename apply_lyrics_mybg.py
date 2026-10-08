# -*- coding: utf-8 -*-
# 가사 배경에 "내 사진" 넣기 + 관리(✕로 빼기) + 사진 밝기 보고 글자색 자동
import os, sys

PATH = os.path.join('lib', 'screens', 'lyrics_screen.dart')
if not os.path.exists(PATH):
    sys.exit('❌ lyrics_screen.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')

raw = open(PATH, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

def rep(old, new, name):
    global s
    n = s.count(old)
    if n != 1:
        sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 파일이 바뀌었을 수 있어요 — 아무것도 저장 안 했어요.')
    s = s.replace(old, new)
    print(f'✔ {name}')

if 'lyricsMyPhotos' in s:
    sys.exit('이미 적용돼 있어요.')

# 1) import
rep("import 'dart:ui' as ui;\n",
    "import 'dart:ui' as ui;\nimport 'dart:io';\nimport 'package:image_picker/image_picker.dart';\n",
    '불러오기 추가')

# 2) 내 사진 상태
rep("  static String _randomSongKey = ''; // 랜덤 사진을 고른 노래 (같은 노래 동안은 그대로)\n",
    "  static String _randomSongKey = ''; // 랜덤 사진을 고른 노래 (같은 노래 동안은 그대로)\n"
    "  static String? _myBg; // 내 사진 배경 (파일 경로) — 있으면 이게 먼저\n"
    "  static bool _myLight = false; // 내 사진이 밝은지 (밝으면 먹색 글자, 어두우면 흰 글자)\n"
    "  List<String> _myPhotos = []; // 가사 배경용 내 사진 목록\n"
    "  bool _manageMy = false; // 내 사진 관리(✕) 모드\n",
    '내 사진 상태')

# 3) 열 때 내 사진 불러오기
rep("      if (random != _random && mounted) setState(() => _random = random);\n      if (random) return;\n",
    "      if (random != _random && mounted) setState(() => _random = random);\n"
    "      // 내 사진 목록 (지워진 파일은 빼기)\n"
    "      _myPhotos = (p.getStringList('lyricsMyPhotos') ?? []).where((f) => File(f).existsSync()).toList();\n"
    "      final my = p.getString('lyricsBgMy');\n"
    "      if (!random && my != null && File(my).existsSync()) {\n"
    "        _myLight = p.getBool('lyricsBgMyLight') ?? false;\n"
    "        if (mounted) setState(() => _myBg = my);\n"
    "        return;\n"
    "      }\n"
    "      if (_myBg != null && mounted) setState(() => _myBg = null);\n"
    "      if (random) return;\n",
    '열 때 내 사진 불러오기')

# 4) 밝기
rep("  bool get _light => _bg != 0 && _kLightBgs.contains(_bg);\n",
    "  bool get _light => _myBg != null ? _myLight : (_bg != 0 && _kLightBgs.contains(_bg));\n"
    "  bool get _hasPhoto => _myBg != null || _bg != 0;\n"
    "  bool get _busy => _myBg != null || _kBusyBgs.contains(_bg); // 내 사진은 글자가 잘 보이게 막을 조금 진하게\n"
    "\n"
    "  /// 사진 위쪽 60%(가사 자리)가 밝은지 재보기 → 글자색 자동\n"
    "  Future<bool> _isBright(String path) async {\n"
    "    try {\n"
    "      final bytes = await File(path).readAsBytes();\n"
    "      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 40);\n"
    "      final frame = await codec.getNextFrame();\n"
    "      final img = frame.image;\n"
    "      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);\n"
    "      if (data == null) return false;\n"
    "      final w = img.width, rows = (img.height * 0.6).round();\n"
    "      var sum = 0.0;\n"
    "      var n = 0;\n"
    "      for (var y = 0; y < rows; y++) {\n"
    "        for (var x = 0; x < w; x++) {\n"
    "          final i = (y * w + x) * 4;\n"
    "          sum += 0.299 * data.getUint8(i) + 0.587 * data.getUint8(i + 1) + 0.114 * data.getUint8(i + 2);\n"
    "          n++;\n"
    "        }\n"
    "      }\n"
    "      img.dispose();\n"
    "      return n > 0 && sum / n > 150;\n"
    "    } catch (_) {\n"
    "      return false;\n"
    "    }\n"
    "  }\n"
    "\n"
    "  /// 내 사진으로 배경 바꾸기\n"
    "  Future<void> _useMyPhoto(String path) async {\n"
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "    final light = await _isBright(path);\n"
    "    if (!mounted) return;\n"
    "    setState(() {\n"
    "      _myBg = path;\n"
    "      _myLight = light;\n"
    "      _random = false;\n"
    "    });\n"
    "    final p = await SharedPreferences.getInstance();\n"
    "    await p.setString('lyricsBgMy', path);\n"
    "    await p.setBool('lyricsBgMyLight', light);\n"
    "    await p.setBool('lyricsBgRandom', false);\n"
    "  }\n"
    "\n"
    "  /// + 사진 추가 (여러 장 한 번에, 넣자마자 첫 장으로)\n"
    "  Future<void> _addMyPhotos(StateSetter setSheet) async {\n"
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "    final picked = await ImagePicker().pickMultiImage(imageQuality: 90, maxWidth: 1440);\n"
    "    if (picked.isEmpty || !mounted) return;\n"
    "    for (final f in picked.reversed) {\n"
    "      if (!_myPhotos.contains(f.path)) _myPhotos.insert(0, f.path);\n"
    "    }\n"
    "    setSheet(() {});\n"
    "    final p = await SharedPreferences.getInstance();\n"
    "    await p.setStringList('lyricsMyPhotos', _myPhotos);\n"
    "    await _useMyPhoto(picked.first.path);\n"
    "    setSheet(() {});\n"
    "  }\n"
    "\n"
    "  /// 관리 ✕: 목록에서 빼기 (지금 배경이면 파란소리 사진으로 돌아가기)\n"
    "  Future<void> _removeMyPhoto(String path, StateSetter setSheet) async {\n"
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "    _myPhotos.remove(path);\n"
    "    final wasCurrent = _myBg == path;\n"
    "    if (wasCurrent) setState(() => _myBg = null);\n"
    "    if (_myPhotos.isEmpty) _manageMy = false;\n"
    "    setSheet(() {});\n"
    "    final p = await SharedPreferences.getInstance();\n"
    "    await p.setStringList('lyricsMyPhotos', _myPhotos);\n"
    "    if (wasCurrent) await p.remove('lyricsBgMy');\n"
    "  }\n",
    '밝기·추가·빼기')

# 5) 랜덤 켜면 내 사진 끄기
rep("        _randomSongKey = song?.uri ?? song?.title ?? ''; // 지금 노래는 이 사진으로\n        _bg = next;\n      });\n",
    "        _randomSongKey = song?.uri ?? song?.title ?? ''; // 지금 노래는 이 사진으로\n        _bg = next;\n        _myBg = null; // 랜덤은 파란소리 사진 중에서\n      });\n",
    '랜덤이면 내 사진 끄기')

# 6) 파란소리 사진 고르면 내 사진 끄기
rep("              setState(() {\n                _bg = i;\n                _random = false; // 사진을 하나 고르면 랜덤은 끄고 이 사진으로 고정\n              });\n",
    "              setState(() {\n                _bg = i;\n                _myBg = null; // 파란소리 사진을 고르면 내 사진은 끄기\n                _random = false; // 사진을 하나 고르면 랜덤은 끄고 이 사진으로 고정\n              });\n",
    '파란소리 사진 고르면 내 사진 끄기')
rep("              await p.setBool('lyricsBgRandom', false);\n              if (ctx.mounted) Navigator.pop(ctx);\n",
    "              await p.setBool('lyricsBgRandom', false);\n              await p.remove('lyricsBgMy');\n              if (ctx.mounted) Navigator.pop(ctx);\n",
    '고른 것 저장')
rep("          final selected = !_random && _bg == i;\n",
    "          final selected = !_random && _myBg == null && _bg == i;\n",
    '선택 표시')

# 7) 창 열 때 관리 모드 끄기
rep("  void _pickBackground() {\n    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n",
    "  void _pickBackground() {\n    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n    _manageMy = false;\n",
    '관리 모드 초기화')

# 8) 내 사진 칸 (추가·고르기·✕)
rep("        final sub = dark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n        return Column(\n",
    "        final sub = dark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n"
    "\n"
    "        // + 사진 추가\n"
    "        Widget addTile() => GestureDetector(\n"
    "              onTap: () => _addMyPhotos(setSheet),\n"
    "              child: Container(\n"
    "                decoration: BoxDecoration(\n"
    "                  color: dark ? const Color(0xFF26221C) : Colors.white,\n"
    "                  borderRadius: BorderRadius.circular(12),\n"
    "                  border: Border.all(color: dark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB), width: 1.2),\n"
    "                ),\n"
    "                child: Column(\n"
    "                  mainAxisAlignment: MainAxisAlignment.center,\n"
    "                  children: [\n"
    "                    Icon(Icons.add_rounded, color: sub, size: 26),\n"
    "                    const SizedBox(height: 4),\n"
    "                    Text('사진 추가', style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w600)),\n"
    "                  ],\n"
    "                ),\n"
    "              ),\n"
    "            );\n"
    "\n"
    "        // 내 사진 한 장 (관리 모드면 ✕)\n"
    "        Widget myTile(String f) {\n"
    "          final selected = !_random && _myBg == f;\n"
    "          return GestureDetector(\n"
    "            onTap: _manageMy\n"
    "                ? null\n"
    "                : () async {\n"
    "                    await _useMyPhoto(f);\n"
    "                    setSheet(() {});\n"
    "                    if (ctx.mounted) Navigator.pop(ctx);\n"
    "                  },\n"
    "            child: Container(\n"
    "              decoration: BoxDecoration(\n"
    "                borderRadius: BorderRadius.circular(12),\n"
    "                border: Border.all(\n"
    "                    color: selected && !_manageMy ? const Color(0xFF17140F) : Colors.transparent, width: 2.5),\n"
    "              ),\n"
    "              child: ClipRRect(\n"
    "                borderRadius: BorderRadius.circular(10),\n"
    "                child: Stack(\n"
    "                  fit: StackFit.expand,\n"
    "                  children: [\n"
    "                    Image.file(File(f),\n"
    "                        fit: BoxFit.cover,\n"
    "                        cacheWidth: 270, // 작게 미리보기\n"
    "                        errorBuilder: (_, __, ___) => Container(color: const Color(0x22000000))),\n"
    "                    if (selected && !_manageMy)\n"
    "                      const Positioned(\n"
    "                        right: 6,\n"
    "                        top: 6,\n"
    "                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),\n"
    "                      ),\n"
    "                    if (_manageMy)\n"
    "                      Positioned(\n"
    "                        right: 5,\n"
    "                        top: 5,\n"
    "                        child: GestureDetector(\n"
    "                          onTap: () => _removeMyPhoto(f, setSheet),\n"
    "                          child: Container(\n"
    "                            width: 26,\n"
    "                            height: 26,\n"
    "                            decoration: const BoxDecoration(color: Color(0xB317140F), shape: BoxShape.circle),\n"
    "                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),\n"
    "                          ),\n"
    "                        ),\n"
    "                      ),\n"
    "                  ],\n"
    "                ),\n"
    "              ),\n"
    "            ),\n"
    "          );\n"
    "        }\n"
    "\n"
    "        // 칸 제목 (내 사진 · 파란소리 사진)\n"
    "        Widget header(String t, {Widget? trailing}) => Padding(\n"
    "              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),\n"
    "              child: Row(\n"
    "                children: [\n"
    "                  Text(t, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w700)),\n"
    "                  const Spacer(),\n"
    "                  if (trailing != null) trailing,\n"
    "                ],\n"
    "              ),\n"
    "            );\n"
    "\n"
    "        return Column(\n",
    '내 사진 칸 만들기')

# 9) 그리드 위에 내 사진 칸 + 제목
rep("            GridView.count(\n              crossAxisCount: 3,\n              shrinkWrap: true,\n              physics: const NeverScrollableScrollPhysics(),\n              mainAxisSpacing: 8,\n              crossAxisSpacing: 8,\n              childAspectRatio: 9 / 16,\n              children: [for (var i = 1; i <= _kLyricsBgCount; i++) tile(i)],\n            ),\n",
    "            // ── 내 사진 ──\n"
    "            header('내 사진',\n"
    "                trailing: _myPhotos.isEmpty\n"
    "                    ? null\n"
    "                    : GestureDetector(\n"
    "                        onTap: () => setSheet(() => _manageMy = !_manageMy),\n"
    "                        child: Text(_manageMy ? '완료' : '관리',\n"
    "                            style: TextStyle(\n"
    "                                color: _manageMy ? Theme.of(ctx).colorScheme.primary : sub,\n"
    "                                fontSize: 12.5,\n"
    "                                fontWeight: FontWeight.w600)),\n"
    "                      )),\n"
    "            GridView.count(\n"
    "              crossAxisCount: 3,\n"
    "              shrinkWrap: true,\n"
    "              physics: const NeverScrollableScrollPhysics(),\n"
    "              mainAxisSpacing: 8,\n"
    "              crossAxisSpacing: 8,\n"
    "              childAspectRatio: 9 / 16,\n"
    "              children: [if (!_manageMy) addTile(), for (final f in _myPhotos) myTile(f)],\n"
    "            ),\n"
    "            // ── 파란소리 사진 ──\n"
    "            header('파란소리 사진'),\n"
    "            GridView.count(\n              crossAxisCount: 3,\n              shrinkWrap: true,\n              physics: const NeverScrollableScrollPhysics(),\n              mainAxisSpacing: 8,\n              crossAxisSpacing: 8,\n              childAspectRatio: 9 / 16,\n              children: [for (var i = 1; i <= _kLyricsBgCount; i++) tile(i)],\n            ),\n",
    '내 사진 칸 넣기')

# 10) 배경 그리기: 내 사진이면 파일로
rep("            if (_bg != 0)\n              // 배경 사진은 한 번만 그리고 고정 (가사가 바뀔 때마다 다시 안 그리게)\n              RepaintBoundary(\n                child: CachedNetworkImage(\n",
    "            if (_myBg != null)\n"
    "              // 내 사진 배경 (화면 크기만큼만 풀기)\n"
    "              RepaintBoundary(\n"
    "                child: Image.file(File(_myBg!),\n"
    "                    fit: BoxFit.cover,\n"
    "                    cacheWidth: 1080,\n"
    "                    gaplessPlayback: true,\n"
    "                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF14110C))),\n"
    "              )\n"
    "            else if (_bg != 0)\n              // 배경 사진은 한 번만 그리고 고정 (가사가 바뀔 때마다 다시 안 그리게)\n              RepaintBoundary(\n                child: CachedNetworkImage(\n",
    '배경에 내 사진 그리기')

# 11) 글자 막: 내 사진도
rep("            // 글자가 잘 보이게 얇은 막 (밝은 사진은 크림색, 어두운 사진은 검은색)\n            if (_bg != 0)\n",
    "            // 글자가 잘 보이게 얇은 막 (밝은 사진은 크림색, 어두운 사진은 검은색)\n            if (_hasPhoto)\n",
    '글자 막')
rep("            // 맨 아래 시스템 아이콘 자리만 살짝 막 깔기 (사진마다 아래 밝기가 달라서)\n            if (_bg != 0)\n",
    "            // 맨 아래 시스템 아이콘 자리만 살짝 막 깔기 (사진마다 아래 밝기가 달라서)\n            if (_hasPhoto)\n",
    '아래 막')
s_before = s
s = s.replace("const Color(0xFFF4EFE5).withOpacity(_kBusyBgs.contains(_bg) ? 0.72 : 0.55),",
              "const Color(0xFFF4EFE5).withOpacity(_busy ? 0.72 : 0.55),")
s = s.replace("const Color(0xFFF4EFE5).withOpacity(_kBusyBgs.contains(_bg) ? 0.5 : 0.3),",
              "const Color(0xFFF4EFE5).withOpacity(_busy ? 0.5 : 0.3),")
print('✔ 막 진하기' if s != s_before else '… 막 진하기 (그대로)')

out = s.replace('\n', '\r\n') if crlf else s
open(PATH, 'w', encoding='utf-8', newline='').write(out)
print('\n✅ 끝! 가사 배경에 "내 사진"이 생겼어요.')
