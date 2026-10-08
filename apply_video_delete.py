# 동영상: 여러 개 선택 · 전체 삭제 (녹음 화면과 같은 모양) + 이름 바꿔도 NEW 안 붙게
# 실행: python apply_video_delete.py   (mp3_player_new 폴더에서)
import os, sys

SCREEN = os.path.join('lib', 'screens', 'video_screen.dart')
PROVIDER = os.path.join('lib', 'providers', 'video_provider.dart')
DONE_FILE = SCREEN
DONE_MARK = 'deleteVideosFlow'

KOTLIN_EDITS = [
    ("폰에서 동영상 여러 개 지우기 (휴지통 / 영구) — 확인 창 한 번만",
     """                "deleteVideo" -> {""",
     """                "trashVideos", "deleteVideosForever" -> {
                    // 동영상 여러 개 삭제: 휴지통(30일 뒤 완전 삭제) 또는 영구 삭제 — 폰 확인 창은 한 번만
                    val paths = call.argument<List<String>>("paths")
                    if (paths.isNullOrEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val uris = mutableListOf<android.net.Uri>()
                            for (path in paths) {
                                contentResolver.query(
                                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                    arrayOf(MediaStore.Video.Media._ID),
                                    "${MediaStore.Video.Media.DATA}=?",
                                    arrayOf(path), null
                                )?.use {
                                    if (it.moveToFirst()) {
                                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media._ID))
                                        uris.add(android.net.Uri.withAppendedPath(
                                            MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString()))
                                    }
                                }
                            }
                            if (uris.isEmpty()) {
                                result.success(false)
                            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                deleteResult = result
                                val pendingIntent = if (call.method == "trashVideos")
                                    MediaStore.createTrashRequest(contentResolver, uris, true)
                                else
                                    MediaStore.createDeleteRequest(contentResolver, uris)
                                startIntentSenderForResult(pendingIntent.intentSender, 101, null, 0, 0, 0)
                            } else {
                                var count = 0
                                for (uri in uris) count += contentResolver.delete(uri, null, null)
                                result.success(count > 0)
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("DeleteVideos", "Error: ${e.message}", e)
                            result.success(false)
                        }
                    }
                }
                "deleteVideo" -> {"""),
]

PROVIDER_EDITS = [
    ("이름 바꿔도 NEW 안 붙게 (본 표시를 새 이름으로 옮기기)",
     "  Future<void> requestPermissionAndLoad() async {",
     """  // 이름을 바꾸면 경로가 바뀌어 새 영상으로 보이니까, '본 것' 표시를 새 이름으로 옮기기
  Future<void> carrySeen(String oldUri, String newName) async {
    final slash = oldUri.lastIndexOf('/');
    final dot = oldUri.lastIndexOf('.');
    final ext = dot > slash ? oldUri.substring(dot + 1) : 'mp4';
    final newUri = '${oldUri.substring(0, slash + 1)}${newName.contains('.') ? newName : '$newName.$ext'}';
    if (_seen != null && _seen!.contains(oldUri)) {
      _seen!.add(newUri);
      await (await SharedPreferences.getInstance()).setStringList('videoSeenUris', _seen!.toList());
    }
  }

  Future<void> requestPermissionAndLoad() async {"""),
]

SCREEN_EDITS = [
    ("삭제 창 하나로 통일 (하나·여러 개·전체 모두 녹음과 같은 창)",
     "// 정렬 이름\n",
     """// 동영상 삭제 — 하나·여러 개·전체 모두 같은 창 (녹음 삭제와 같은 방식)
// 큰 버튼: 휴지통으로 (30일 뒤 완전 삭제) / 작은 빨간 글씨: 영구 삭제 · 지웠으면 true
Future<bool> deleteVideosFlow(BuildContext context, List<Video> targets, {bool isAll = false}) async {
  if (targets.isEmpty) return false;
  final n = targets.length;
  final what = (isAll || n > 1) ? '동영상 $n개를' : '이 동영상을';
  final pick = await showParanChoice(
    context,
    title: '$what 삭제할까요?',
    message: '휴지통으로 옮겨져요. 30일 뒤에 완전히 지워져요.',
    confirmLabel: '휴지통으로',
    extraLabel: '영구 삭제',
    danger: true,
  );
  if (pick == 0 || !context.mounted) return false;
  if (pick == 2) {
    // 영구 삭제: 되살릴 수 없다고 한 번 더 확인
    final ok = await showParanConfirm(
      context,
      title: '영구 삭제할까요?',
      message: '$what 영구 삭제하면 되살릴 수 없어요.',
      confirmLabel: '영구 삭제',
      danger: true,
    );
    if (!ok || !context.mounted) return false;
  }
  try {
    final done = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<bool>(
      pick == 1 ? 'trashVideos' : 'deleteVideosForever',
      {'paths': [for (final v in targets) v.uri]},
    );
    if (done != true) return false; // 폰 확인 창에서 취소
    if (!context.mounted) return true;
    context.read<VideoProvider>().loadVideos(quiet: true);
    showActionFeedback(context,
        type: ActionFeedbackType.deleted, message: pick == 1 ? '삭제했어요' : '영구 삭제했어요');
    return true;
  } catch (e) {
    if (context.mounted) showParanToast(context, '삭제하지 못했어요', error: true);
    return false;
  }
}

// 정렬 이름
"""),

    ("여러 개 선택 상태 칸",
     "class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {\n",
     """class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  final Set<String> _selected = {}; // 여러 개 선택 (영상 경로)
  bool _selectMode = false; // ⋮ → 여러 개 선택하기로 켰을 때
  bool get _selecting => _selectMode || _selected.isNotEmpty;

  void _endSelect() => setState(() {
        _selected.clear();
        _selectMode = false;
      });
"""),

    ("⋮ 창 · 선택 막대 · 아래 버튼 (녹음 화면과 같은 모양)",
     "  // 영상 칸들 (최신순·오래된순이면 날짜마다 작은 제목)\n",
     """  // ⋮ 창: 여러 개 선택하기 · 전체 삭제(빨강) — 녹음 관리 창과 같은 모양
  void _showMoreSheet(bool isDark) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final list = context.read<VideoProvider>().videos;
    final bg = isDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF332E26) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final line = isDark ? const Color(0xFF3A342B) : const Color(0xFFEFE9DE);
    const red = Color(0xFFD84A3A);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget action(IconData icon, String label, Color color, Color iconBg, VoidCallback onTap) => InkWell(
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                      child: Icon(icon, color: color, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Text(label, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // 제목 + ✕
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('동영상 관리', style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: sub, size: 22),
                    ),
                  ],
                ),
                if (list.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        action(Icons.check_box_outlined, '여러 개 선택하기', ink, bg,
                            () => setState(() => _selectMode = true)),
                        Divider(height: 1, thickness: 1, color: line),
                        action(Icons.delete_outline_rounded, '전체 삭제', red, red.withOpacity(0.1),
                            () => deleteVideosFlow(context, List.of(list), isAll: true)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 선택 중 위 줄: ✕ · N개 선택 · 전체 선택 (녹음 화면과 같은 모양)
  Widget _selectHeader(List<Video> list, Color baseColor) {
    final all = list.isNotEmpty && _selected.length == list.length;
    return Row(
      children: [
        IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            _endSelect();
          },
          icon: Icon(Icons.close, color: baseColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        ),
        const SizedBox(width: 4),
        Text('${_selected.length}개 선택',
            style: TextStyle(color: baseColor, fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            setState(() {
              if (all) {
                _selected.clear();
              } else {
                _selected
                  ..clear()
                  ..addAll(list.map((v) => v.uri));
              }
            });
          },
          child: Text(all ? '선택 해제' : '전체 선택', style: TextStyle(color: baseColor.withOpacity(0.75))),
        ),
      ],
    );
  }

  // 선택 중 아래 고정 버튼: 공유 · 삭제 (녹음 화면과 같은 먹색 막대)
  Widget _selectBar(List<Video> list, bool isDark) {
    final picked = list.where((v) => _selected.contains(v.uri)).toList();
    final enabled = picked.isNotEmpty;
    final barBg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final barFg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final barRed = isDark ? const Color(0xFFD84A3A) : const Color(0xFFFF8A7A);

    Widget btn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
      final c = enabled ? (color ?? barFg) : barFg.withOpacity(0.35);
      return Expanded(
        child: InkWell(
          onTap: enabled
              ? () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: c, size: 22),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(color: c, fontSize: 11.5)),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        padding: const EdgeInsets.symmetric(vertical: 2),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: barBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.25), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            btn(Icons.share_outlined, '공유', () async {
              await Share.shareXFiles([for (final v in picked) XFile(v.uri)]);
            }),
            btn(Icons.delete_outline, '삭제', () async {
              if (await deleteVideosFlow(context, picked, isAll: true) && mounted) _endSelect();
            }, color: barRed),
          ],
        ),
      ),
    );
  }

  // 영상 칸들 (최신순·오래된순이면 날짜마다 작은 제목)
"""),

    ("영상 칸에 선택 상태 넘기기",
     "                return _VideoTile(key: ValueKey(v.uri), video: v);",
     """                return _VideoTile(
                  key: ValueKey(v.uri),
                  video: v,
                  selecting: _selecting,
                  selected: _selected.contains(v.uri),
                  onSelect: () => setState(
                      () => _selected.contains(v.uri) ? _selected.remove(v.uri) : _selected.add(v.uri)),
                );"""),

    ("화면 아래에 선택 버튼 띄울 자리 (겹쳐 놓기)",
     """    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(""",
     """    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
      CustomScrollView("""),

    ("선택 중이면 위 줄을 'N개 선택'으로",
     """                      Row(
                        children: [
                          Text(AppLocalizations.of(context)!.videos,""",
     """                      _selecting
                          ? _selectHeader(videoProvider.videos, baseColor)
                          : Row(
                        children: [
                          Text(AppLocalizations.of(context)!.videos,"""),

    ("정렬 버튼 옆에 ⋮",
     """                                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: baseColor.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ),
                        ],""",
     """                                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: baseColor.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ),
                          // ⋮ 여러 개 선택하기 · 전체 삭제 (녹음 화면과 같게)
                          IconButton(
                            onPressed: () => _showMoreSheet(isDarkMode),
                            icon: Icon(Icons.more_vert, color: baseColor.withOpacity(0.55), size: 21),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          ),
                        ],"""),

    ("아래 버튼 붙이기 + 목록 끝 여백",
     """          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}""",
     """          // 선택 중엔 아래 버튼에 안 가리게 여백 넉넉히
          SliverPadding(padding: EdgeInsets.only(bottom: _selecting ? 100 : 16)),
        ],
      ),
          // 여러 개 선택 중: 아래 고정 버튼 (공유 · 삭제)
          if (_selecting)
            Positioned(left: 0, right: 0, bottom: 0, child: _selectBar(videoProvider.videos, isDarkMode)),
        ],
      ),
    );
  }
}"""),

    ("영상 칸: 선택 상태 받기",
     """  final Video video;

  const _VideoTile({super.key, required this.video});""",
     """  final Video video;
  final bool selecting; // 여러 개 선택 중
  final bool selected; // 이 영상을 골랐는지
  final VoidCallback? onSelect;

  const _VideoTile({super.key, required this.video, this.selecting = false, this.selected = false, this.onSelect});"""),

    ("영상 칸: 선택 중엔 누르면 고르기만",
     """      onLongPress: () => _showOptions(context),
      onTap: () async {
        _channel.invokeMethod('vibrate');""",
     """      onLongPress: widget.selecting ? null : () => _showOptions(context),
      onTap: () async {
        _channel.invokeMethod('vibrate');
        // 여러 개 선택 중이면 고르기만
        if (widget.selecting) {
          widget.onSelect?.call();
          return;
        }"""),

    ("영상 칸: 오른쪽 위 동그라미 ✓",
     "                    // 이어보기: 어디까지 봤는지 얇은 막대 (포인트색)",
     """                    // 여러 개 선택 중: 고른 건 살짝 어둡게 + 오른쪽 위 동그라미 ✓ (녹음 선택과 같은 먹색)
                    if (widget.selecting) ...[
                      if (widget.selected) Container(color: Colors.black.withOpacity(0.28)),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.selected
                                ? (isDarkMode ? Colors.white.withOpacity(0.9) : const Color(0xFF3A352D))
                                : Colors.black.withOpacity(0.25),
                            border: Border.all(color: Colors.white, width: 1.6),
                          ),
                          child: widget.selected
                              ? Icon(Icons.check, size: 15, color: isDarkMode ? const Color(0xFF17140F) : Colors.white)
                              : null,
                        ),
                      ),
                    ],
                    // 이어보기: 어디까지 봤는지 얇은 막대 (포인트색)"""),

    ("길게 눌러 삭제도 같은 창으로",
     """  Future<void> _deleteVideo(BuildContext context) async {
    final ok = await showParanConfirm(
      context,
      title: '이 동영상을 삭제할까요?',
      message: "'${widget.video.titleDisplay}'이(가) 폰에서 지워져요",
      confirmLabel: '삭제',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await _channel.invokeMethod('deleteVideo', {'uri': widget.video.uri});
      if (!context.mounted) return;
      context.read<VideoProvider>().loadVideos();
      showActionFeedback(context, type: ActionFeedbackType.deleted);
    } catch (e) {
      showParanToast(context, '삭제하지 못했어요', error: true);
    }
  }""",
     """  Future<void> _deleteVideo(BuildContext context) async {
    await deleteVideosFlow(context, [widget.video]); // 휴지통 / 영구 삭제 (모두 같은 창)
  }"""),

    ("길게 눌러 이름 바꿔도 NEW 안 붙게",
     """      if (!context.mounted) return;
      context.read<VideoProvider>().loadVideos();
      showActionFeedback(context, type: ActionFeedbackType.edited, message: '이름을 바꿨어요');""",
     """      if (!context.mounted) return;
      final vp = context.read<VideoProvider>();
      await vp.carrySeen(widget.video.uri, newName); // 이름 바꿔도 NEW 안 붙게
      vp.loadVideos();
      if (!context.mounted) return;
      showActionFeedback(context, type: ActionFeedbackType.edited, message: '이름을 바꿨어요');"""),

    ("재생 화면 ⋮ 이름 바꾸기: NEW 안 붙게 + 목록 새로",
     """                  await const MethodChannel('kr.ssing.catsong/media')
                      .invokeMethod('renameVideo', {
                    'uri': widget.video.uri,
                    'newName': newName,
                  });
                  Navigator.pop(context);""",
     """                  await const MethodChannel('kr.ssing.catsong/media')
                      .invokeMethod('renameVideo', {
                    'uri': widget.video.uri,
                    'newName': newName,
                  });
                  if (!context.mounted) return;
                  final vp = context.read<VideoProvider>();
                  await vp.carrySeen(widget.video.uri, newName); // 이름 바꿔도 NEW 안 붙게
                  vp.loadVideos(quiet: true);
                  if (!context.mounted) return;
                  Navigator.pop(context);"""),

    ("재생 화면 ⋮ 삭제도 같은 창으로",
     """              } else if (value == 'delete') {
                final confirm = await showParanConfirm(
                  context,
                  title: '이 동영상을 삭제할까요?',
                  message: "'${widget.video.titleDisplay}'이(가) 폰에서 지워져요",
                  confirmLabel: '삭제',
                  danger: true,
                );
                if (confirm == true) {
                  await const MethodChannel('kr.ssing.catsong/media')
                      .invokeMethod('deleteVideo', {'uri': widget.video.uri});
                  Navigator.pop(context);
                }
              }""",
     """              } else if (value == 'delete') {
                // 목록과 같은 삭제 창 (휴지통 / 영구 삭제)
                if (await deleteVideosFlow(context, [widget.video]) && context.mounted) {
                  Navigator.pop(context);
                }
              }"""),
]


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def find_main_activity():
    for root, _, files in os.walk(os.path.join('android', 'app', 'src', 'main')):
        if 'MainActivity.kt' in files:
            return os.path.join(root, 'MainActivity.kt')
    return None


def main():
    ma = find_main_activity()
    for path in (SCREEN, PROVIDER):
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path)
            print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
            sys.exit(1)
    if ma is None:
        print('❌ MainActivity.kt 를 못 찾았어요. mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    if DONE_MARK in open(DONE_FILE, encoding='utf-8').read():
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    jobs = [(ma, KOTLIN_EDITS), (PROVIDER, PROVIDER_EDITS), (SCREEN, SCREEN_EDITS)]
    results = {}
    num = 0
    for path, edits in jobs:
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balance(text)
        print(f'[{os.path.basename(path)}]')
        for name, old, new in edits:
            num += 1
            n = text.count(old)
            if n != 1:
                print(f'❌ {num}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
                print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
                sys.exit(1)
            text = text.replace(old, new)
            print(f'✔ {num}. {name}')
        if balance(text) != before:
            print(f'❌ {os.path.basename(path)} 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
            sys.exit(1)
        if crlf:
            text = text.replace('\n', '\r\n')
        results[path] = text

    for path, text in results.items():
        open(path, 'wb').write(text.encode('utf-8'))
    print(f'완료! {num}군데 바꿨어요.')


main()
