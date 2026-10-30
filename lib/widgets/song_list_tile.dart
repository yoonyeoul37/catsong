import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/point_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../screens/player_screen.dart';
import 'album_eq_overlay.dart';
import 'menu_parts.dart';
import 'action_feedback.dart';
import 'paran_toast.dart';
import 'paran_dialog.dart';
import 'playlist_pick_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/edit_song_screen.dart';
import '../screens/ringtone_screen.dart';
import '../screens/equalizer_screen.dart';
import 'equalizer_animation.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../utils/no_album_helper.dart';
import '../l10n/locale_holder.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songList;
  final bool forceWhiteText;
  final String highlight; // 검색 중이면 검색어 (제목·가수에서 강조 색으로)

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.songList,
    this.forceWhiteText = false,
    this.highlight = '',
  });

  /// 글자 안에서 검색어만 강조 색으로 (대소문자 상관없이, 여러 번 나와도 모두)
  static Widget hlText(String text, String query, TextStyle style, Color hl) {
    final q = query.trim();
    if (q.isEmpty) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    final low = text.toLowerCase(), ql = q.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (true) {
      final j = low.indexOf(ql, i);
      if (j < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (j > i) spans.add(TextSpan(text: text.substring(i, j)));
      spans.add(TextSpan(text: text.substring(j, j + q.length), style: TextStyle(color: hl, fontWeight: FontWeight.w700)));
      i = j + q.length;
    }
    return Text.rich(TextSpan(children: spans), style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  /// 다른 화면(재생화면 메뉴)에서도 같은 곡 정보 창을 띄울 수 있게
  static void showInfo(BuildContext context, Song song) =>
      SongListTile(song: song, index: 0, songList: [song])._showSongInfo(context);

  @override
  Widget build(BuildContext context) {
    // 필요한 값만 지켜보기 → 이 값들이 바뀔 때만 이 줄을 다시 그림 (재생 위치가 움직일 때는 안 그림)
    final isCurrentSong = context.select<PlayerProvider, bool>((p) => p.currentSong?.id == song.id);
    final isPlayingNow = context.select<PlayerProvider, bool>((p) => p.currentSong?.id == song.id && p.isPlaying);
    final isFav = context.select<MusicProvider, bool>((m) => m.isFavorite(song.id));
    final trimmed = context.select<MusicProvider, bool>((m) => m.isTrimmedWithOriginal(song));
    final isNew = context.select<MusicProvider, bool>((m) => m.isNewSong(song)); // 새로 들어온 곡
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = forceWhiteText ? true : context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return _RiseIn(child: InkWell(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        FocusManager.instance.primaryFocus?.unfocus();
        final player = context.read<PlayerProvider>();
        if (isCurrentSong) {
          // 지금 듣는 곡이면 처음부터 다시 틀지 않고 재생화면만 (멈춰 있으면 이어서 재생)
          if (!player.isPlaying) player.togglePlayPause();
        } else {
          player.playFromList(songList, index);
        }
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentSong ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            _buildAlbumArt(isCurrentSong, isPlayingNow, primaryColor, baseColor, trimmed),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: hlText(
                          song.titleDisplay,
                          highlight,
                          TextStyle(
                            color: isCurrentSong ? primaryColor : baseColor,
                            fontSize: 15,
                            fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                          ),
                          primaryColor,
                        ),
                      ),
                      // (새 곡 표시는 목록 맨 위 '새로 들어온 곡' 머리글 점 하나로)
                    ],
                  ),
                  const SizedBox(height: 3),
                  hlText(
                    song.artistDisplay,
                    highlight,
                    TextStyle(
                      color: isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.38),
                      fontSize: 13,
                    ),
                    primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Builder(builder: (context) {
              final playCount = context.select<MusicProvider, int>((m) => m.playCountOf(song));
              final subColor = isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.3);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    song.durationFormatted,
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                  if (playCount > 0) ...[
                    const SizedBox(height: 2),
                    // 누르면 세는 기준 알려주기
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showParanToast(context, tr.playCountHint),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 11, color: subColor),
                          const SizedBox(width: 1),
                          Text(
                            '$playCount',
                            style: TextStyle(color: subColor, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
            GestureDetector(
              onTap: () => _showOptionsSheet(context, isFav),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.more_vert,
                    color: isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.3),
                    size: 20),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildAlbumArt(bool isCurrentSong, bool isPlayingNow, Color primaryColor, Color baseColor,
      bool showTrimBadge) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: song.albumArt != null
              ? Image.memory(
            Uint8List.fromList(song.albumArt!),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: 52,
            cacheHeight: 52,
          )
              : NoArtTile(
            title: song.titleDisplay,
            colorKey: song.uri ?? song.titleDisplay,
            size: 52,
            isDark: baseColor == Colors.white,
          ),
        ),
        if (isCurrentSong)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: AlbumEqOverlay(
                isPlaying: isPlayingNow,
                width: 26,
                height: 22,
              ),
            ),
          ),
        // 자른 곡 표시: 앨범 사진 오른쪽 아래 파란 가위
        // 원본이 목록에 같이 있을 때만 (원본 지우면 자동으로 사라짐)
        if (showTrimBadge)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.content_cut, size: 11, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _showOptionsSheet(BuildContext context, bool isFav) async {
    // 재생화면 스타일 썸네일용 (지금 고른 스타일 · 파란포토 사진)
    final prefs = await SharedPreferences.getInstance();
    int style = prefs.getInt('albumArtStyle') ?? 6; // 처음엔 파란포토
    final savedBg = prefs.getString('nightBgPath'); // 예전 사진(봄·여름…)이면 새 기본 사진으로
    final bgPath = (savedBg == null ||
            RegExp(r'^assets/(spring|summer|autumn|winter|mood|animal|love|etc)_').hasMatch(savedBg))
        ? 'assets/paranphoto/001.png'
        : savedBg;
    final bgIsFile = prefs.getBool('nightBgIsFile') ?? false;
    bool showNew = !(prefs.getBool('hasSeenParanPhoto') ?? false);
    if (!context.mounted) return;
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final sheetColor = isDarkMode ? const Color(0xFF353535) : const Color(0xFFF4EFE5);
    final baseColor = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF1A1A1A);
    final descColor = isDarkMode ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    const accent = Color(0xFF8A8378); // 메뉴 아이콘은 차분한 회색 (재생화면 메뉴와 통일)

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        bool addedNext = false; // "다음에 재생" 눌렀는지 (메뉴 안에 표시)
        // 메뉴를 안 닫고 여러 개 할 수 있게: 즐겨찾기 등이 바로 다시 그려짐
        return StatefulBuilder(builder: (ctx, setSheet) {
        // 메뉴 안에서는 메뉴 자신의 context를 씀 (곡 정보 편집으로 목록이 다시 그려져도 안전)
        final context = ctx;
        final isFav = ctx.watch<MusicProvider>().isFavorite(song.id);
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, size: 24, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 곡 정보 + 빠른 버튼 (즐겨찾기 · 재생목록 · 공유 · 편집)
                MenuSongCard(
                  song: song,
                  isDark: isDarkMode,
                  actions: [
                    MenuQuickAction(isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, tr.favorites, () {
                      _handleMenuAction(context, 'favorite');
                    }),
                    MenuQuickAction(Icons.playlist_add, tr.playlistLabel, () {
                      _handleMenuAction(context, 'playlist');
                    }),
                    // 공유·편집: 메뉴는 그대로 두고 위에 띄움 → 돌아오면 메뉴가 그대로
                    MenuQuickAction(Icons.share, tr.share, () {
                      _handleMenuAction(context, 'share');
                    }),
                    MenuQuickAction(Icons.edit, tr.editInfo, () {
                      _handleMenuAction(context, 'edit');
                    }),
                  ],
                ),
                MenuCard(isDark: isDarkMode, children: [
                  _sheetItem(context, Icons.play_arrow, AppLocalizations.of(context)!.play, 'play', accent, baseColor, isDarkMode),
                  _sheetItem(context, Icons.skip_next, AppLocalizations.of(context)!.playNext, 'play_next', accent, baseColor, isDarkMode,
                      keepOpen: true,
                      afterTap: () => setSheet(() => addedNext = true),
                      trailing: addedNext
                          ? Text(tr.addedCheck,
                              style: const TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w600))
                          : null),
                ]),
                MenuCard(isDark: isDarkMode, children: [
                // 재생화면 메뉴와 똑같은 줄: 셔플 · 반복 · 수면 · 재생화면 스타일 · 배속
                ...playerSettingRows(
                  ctx,
                  song: song,
                  style: style,
                  bgPath: bgPath,
                  bgIsFile: bgIsFile,
                  showNew: showNew,
                  textColor: baseColor,
                  onStyleChanged: () async {
                    final p2 = await SharedPreferences.getInstance();
                    style = p2.getInt('albumArtStyle') ?? 6;
                    showNew = false;
                    if (ctx.mounted) setSheet(() {});
                  },
                ),
                ]),
                MenuCard(isDark: isDarkMode, children: [
                  // 들어갔다 나오면 메뉴가 그대로 있게 (keepOpen)
                  _sheetItem(context, Icons.music_note, tr.ringtone, 'ringtone', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                  _sheetItem(context, Icons.content_cut, tr.trimAudio, 'trim', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                  _sheetItem(context, Icons.info_outline, tr.fileInfo, 'info', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                  _sheetItem(context, Icons.equalizer, AppLocalizations.of(context)!.equalizer, 'equalizer', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                ]),
                MenuCard(isDark: isDarkMode, children: [
                  _sheetItem(context, Icons.delete_outline, AppLocalizations.of(context)!.delete, 'delete', Colors.redAccent, Colors.redAccent, isDarkMode),
                ]),
                const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
        });
      },
    );
  }

  Widget _sheetItem(BuildContext context, IconData icon, String label, String value, Color iconColor, Color textColor, bool isDarkMode,
      {bool keepOpen = false, bool arrow = false, Widget? trailing, VoidCallback? afterTap}) {
    final isDelete = iconColor == Colors.redAccent;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // keepOpen이면 메뉴를 닫지 않고 바로 실행 (여러 개 연달아 가능)
        if (!keepOpen) Navigator.pop(context);
        _handleMenuAction(context, value);
        afterTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        child: Row(
          children: [
            // 카드 안 줄: 아이콘 배경 없이 아이콘만 (삭제는 빨간색)
            SizedBox(width: 24, child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            if (trailing != null) trailing,
            if (arrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 20, color: textColor.withOpacity(0.3)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    final playerProvider = context.read<PlayerProvider>();
    final musicProvider = context.read<MusicProvider>();

    switch (action) {
      case 'play':
        playerProvider.playFromList(songList, index);
        break;
      case 'play_next':
        playerProvider.addToPlayNext(song); // (메뉴 안에 "추가됨 ✓"가 떠서 따로 알림 없음)
        break;
      case 'playlist':
        _showAddToPlaylistDialog(context, song);
        break;
      case 'favorite':
        musicProvider.toggleFavorite(song); // (하트가 바로 바뀌어서 따로 알림 없음)
        break;
      case 'ringtone':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RingtoneScreen(initialSong: song),
          ),
        );
        break;
      case 'trim':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RingtoneScreen(initialSong: song, trimMode: true),
          ),
        );
        break;
      case 'info':
        _showSongInfo(context);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditSongScreen(song: song)),
        );
        break;
      case 'equalizer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EqualizerScreen(),
          ),
        );
        break;
      case 'share':
        if (song.uri != null) {
          final file = XFile(song.uri!);
          await Share.shareXFiles([file], text: song.titleDisplay);
        }
        break;
      case 'delete':
        _showDeleteDialog(context, song);
        break;
    }
  }

  void _showAddToPlaylistDialog(BuildContext context, song) {
    showAddToPlaylistSheet(context, song); // 공통 고르는 창
  }

  void _showSongInfo(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nav = Navigator.of(context, rootNavigator: true);
    showParanSheet(
      context,
      title: l.songInfo,
      header: ParanSongHeader(art: song.albumArt, title: song.titleDisplay, subtitle: song.artistDisplay),
      builder: (ctx, setSheet) => Column(
        children: [
          ParanCard(children: [
            ParanInfoRow(label: l.album, value: song.albumDisplay),
            ParanInfoRow(label: l.playTime, value: song.durationFormatted),
            if (song.uri != null) ParanInfoRow(label: l.path, value: song.uri!),
          ]),
          ParanBigButton(
            label: l.editSong,
            onPressed: () {
              Navigator.pop(ctx);
              nav.push(MaterialPageRoute(builder: (_) => EditSongScreen(song: song)));
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Song song) async {
    // 메뉴가 먼저 닫혀도 괜찮게, 지금 미리 붙잡아 두기
    final appCtx = Navigator.of(context, rootNavigator: true).context;
    final music = context.read<MusicProvider>();
    final failText = AppLocalizations.of(context)!.deleteFailed;
    final ok = await showParanConfirm(
      appCtx,
      title: tr.deleteSongTitle,
      message: tr.deleteSongMessage(song.titleDisplay),
      confirmLabel: tr.delete,
      danger: true,
    );
    if (!ok) return;
    try {
      if (song.uri != null) {
        const platform = MethodChannel('kr.ssing.catsong/media');
        final result = await platform.invokeMethod('deleteSong', {'uri': song.uri});
        if (result == true) {
          showActionFeedback(appCtx, type: ActionFeedbackType.deleted); // 🗑 삭제했어요
          music.loadSongs();
        } else {
          showParanToast(appCtx, failText, error: true);
        }
      }
    } catch (e) {
      showParanToast(appCtx, tr.couldNotDelete, error: true);
    }
  }

}

/// 곡 줄이 화면에 나타날 때 아래에서 살포시 떠오르게
class _RiseIn extends StatefulWidget {
  final Widget child;
  const _RiseIn({required this.child});

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late Animation<Offset> _slide;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;
  ScrollPosition? _pos;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    final curve = _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);
    // 처음 그려진 뒤: 화면에 보이는 줄은 바로 떠오르기
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(first: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.maybeOf(context)?.position;
    if (!identical(p, _pos)) {
      _pos?.removeListener(_check);
      _pos = p;
      if (!_started) _pos?.addListener(_check);
    }
  }

  @override
  void didUpdateWidget(covariant _RiseIn old) {
    super.didUpdateWidget(old);
    // 목록이 바뀌어 줄이 스크롤 없이 화면에 들어온 경우도 챙기기
    if (!_started) WidgetsBinding.instance.addPostFrameCallback((_) => _check(first: true));
  }

  /// 줄이 실제로 화면 안에 들어왔는지 보고 시작
  void _check({bool first = false}) {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final vp = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (vp is! RenderBox || !vp.hasSize) {
      _start(animate: true);
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: vp).dy;
    final h = vp.size.height;
    if (top + box.size.height <= 0 || top >= h) return; // 아직 화면 밖
    // 아래에서 들어오면 아래→위로, 위에서 들어오면 위→아래로 살포시
    final fromTop = !first && top <= h * 0.5;
    if (fromTop) {
      setState(() => _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(_curve));
    }
    _start(animate: true);
  }

  void _start({required bool animate}) {
    _started = true;
    _pos?.removeListener(_check);
    if (animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
