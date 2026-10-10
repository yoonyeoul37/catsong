import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/radio_provider.dart';
import '../providers/theme_provider.dart';
import '../services/alarm_service.dart';
import '../services/headset_resume.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/paran_toast.dart';
import '../widgets/action_feedback.dart';
import 'package:permission_handler/permission_handler.dart';

/// 아침 알람 맞추기 (더보기 메뉴에서)
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  late ParanAlarm _a = AlarmService.alarm.value?.copy() ?? ParanAlarm();
  bool _waitPerm = false; // 권한 허용하러 설정에 다녀오는 중

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 설정에서 돌아오면: 허용했으면 바로 저장, 안 했으면 짧게 알려주기
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed || !_waitPerm) return;
    _waitPerm = false;
    if (await AlarmService.canExact()) {
      if (mounted) _save();
    } else if (mounted) {
      showParanToast(context, '알람 및 리마인더를 허용해야 울릴 수 있어요');
    }
  }
  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  // ───── 깨울 소리 고르기 ─────

  void _pickMusic(String kind, String label) {
    _vib();
    setState(() {
      _a.kind = kind;
      _a.label = label;
      _a.refId = null;
      _a.station = null;
    });
  }

  /// 한 곡 고르기 (검색칸 + 곡 목록)
  void _pickSong() {
    final music = context.read<MusicProvider>();
    final all = music.allSongs.where((s) => !music.isCallRecordingPath(s.uri)).toList();
    if (all.isEmpty) {
      showParanToast(context, '폰에 있는 노래가 없어요');
      return;
    }
    final d = context.read<ThemeProvider>().isDarkMode;
    final point = context.read<ThemeProvider>().primaryColor;
    final sheet = d ? const Color(0xFF2B2926) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF32302C) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = d ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    var q = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 키보드 위로
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          decoration: BoxDecoration(color: sheet, borderRadius: BorderRadius.circular(22)),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              final key = q.trim().toLowerCase();
              final list = key.isEmpty
                  ? all
                  : all
                      .where((s) =>
                          s.titleDisplay.toLowerCase().contains(key) || s.artistDisplay.toLowerCase().contains(key))
                      .toList();
              return Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text('알람 곡 고르기',
                              style: TextStyle(
                                  color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        ),
                      ),
                      ParanCloseX(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setSheet(() => q = v),
                    style: TextStyle(color: ink, fontSize: 14.5),
                    cursorColor: ink,
                    decoration: InputDecoration(
                      hintText: '제목이나 가수로 찾기',
                      hintStyle: TextStyle(color: hint, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: hint, size: 20),
                      filled: true,
                      fillColor: card,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ink, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: list.isEmpty
                        ? Center(child: Text('찾는 곡이 없어요', style: TextStyle(color: hint, fontSize: 13)))
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final s = list[i];
                              final sel = _a.kind == 'song' && _a.refId == s.uri;
                              return InkWell(
                                onTap: () {
                                  _vib();
                                  setState(() {
                                    _a.kind = 'song';
                                    _a.refId = s.uri;
                                    _a.label = '${s.titleDisplay} · ${s.artistDisplay}';
                                    _a.station = null;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.titleDisplay,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: ink,
                                                    fontSize: 14.5,
                                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                                            const SizedBox(height: 2),
                                            Text(s.artistDisplay,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: hint, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      if (sel) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.check_circle_rounded, size: 20, color: point),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _pickPlaylist() {
    final lists = context.read<PlaylistProvider>().playlists;
    if (lists.isEmpty) {
      showParanToast(context, '재생목록을 먼저 만들어 주세요');
      return;
    }
    showParanSheet(
      context,
      title: '재생목록 고르기',
      builder: (ctx, setSheet) => ParanCard(
        children: [
          for (final p in lists)
            ParanRow(
              icon: Icons.queue_music_rounded,
              title: p.name,
              trailingText: '${p.songs.length}곡',
              selected: _a.kind == 'playlist' && _a.refId == p.id,
              onTap: () {
                setState(() {
                  _a.kind = 'playlist';
                  _a.refId = p.id;
                  _a.label = p.name;
                  _a.station = null;
                });
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _pickRadio() {
    final favs = context.read<RadioProvider>().favorites;
    if (favs.isEmpty) {
      showParanToast(context, '라디오 즐겨찾기에 채널을 먼저 담아 주세요');
      return;
    }
    showParanSheet(
      context,
      title: '라디오 채널 고르기',
      builder: (ctx, setSheet) => ParanCard(
        children: [
          for (final s in favs)
            ParanRow(
              icon: Icons.radio_rounded,
              title: s.name,
              selected: _a.kind == 'radio' && _a.refId == s.stationUuid,
              onTap: () {
                setState(() {
                  _a.kind = 'radio';
                  _a.refId = s.stationUuid;
                  _a.label = s.name;
                  _a.station = s.toJson();
                });
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _pickNature() {
    showParanSheet(
      context,
      title: '자연 소리 고르기',
      builder: (ctx, setSheet) => ParanCard(
        children: [
          for (final n in PlayerProvider.natureSoundOrder)
            ParanRow(
              icon: Icons.forest_outlined,
              title: n['name']!,
              selected: _a.kind == 'nature' && _a.refId == n['name'],
              onTap: () {
                setState(() {
                  _a.kind = 'nature';
                  _a.refId = n['name'];
                  _a.label = n['name']!;
                  _a.station = null;
                });
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  // ───── 저장 ─────

  Future<void> _save() async {
    _vib();
    final ok = await AlarmService.save(_a);
    if (!mounted) return;
    if (!ok) {
      final go = await showParanConfirm(
        context,
        title: '알람 권한이 필요해요',
        message: '정해진 시간에 깨우려면 "알람 및 리마인더"를 허용해 주세요. 허용하고 돌아오면 바로 저장돼요.',
        confirmLabel: '설정 열기',
      );
      if (go) {
        _waitPerm = true;
        AlarmService.openExactSettings();
      }
      return;
    }
    if (_a.enabled) {
      // 알림 권한: 알람이 울릴 때 알림으로 화면을 띄워서 꼭 필요
      try {
        if (await Permission.notification.isDenied) await Permission.notification.request();
      } catch (_) {}
      // 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기 허용 (안 해도 알람 소리는 울림)
      if (!await AlarmService.canFullScreen() && mounted) {
        final go = await showParanConfirm(
          context,
          title: '잠금화면에 알람 화면 띄우기',
          message: '"전체 화면 알림"을 허용하면 잠금화면 위로 알람 화면이 바로 떠요. 허용 안 해도 알람 소리는 울려요.',
          confirmLabel: '설정 열기',
          cancelLabel: '나중에',
        );
        if (go) AlarmService.openFullScreenSettings();
      }
      // 배터리 사용 "제한 없음" 부탁 (한 번만)
      if (mounted) {
        await HeadsetResume.askBattery(context, 'alarm',
            '정해진 시간에 알람 곡을 틀려면 배터리 사용을 "제한 없음"으로 해 주는 게 좋아요.\n허용 안 해도 대부분 잘 울리지만, 일부 폰은 절전 때문에 늦을 수 있어요.');
      }
    }
    if (!mounted) return;
    // 화면 가운데 피드백 (저장·수정 때와 같은 모양)
    showActionFeedback(
      context,
      type: ActionFeedbackType.saved,
      icon: _a.enabled ? Icons.alarm_rounded : Icons.alarm_off_rounded,
      message: _a.enabled ? '${AlarmService.nextLabel(_a)}에 깨워 드릴게요' : '알람을 껐어요',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final d = theme.isDarkMode;
    final point = theme.primaryColor;
    final bg = d ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF32302C) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final onInk = d ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = d ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
    final iconBg = d ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5);

    Widget box(List<Widget> children, {EdgeInsets? padding}) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );

    Widget head(String t, [String? right]) => Row(
          children: [
            Text(t, style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (right != null) Text(right, style: TextStyle(color: hint, fontSize: 12.5)),
          ],
        );

    // 깨울 소리 한 줄
    Widget soundRow(IconData icon, String title, bool selected, VoidCallback onTap, {String? sub, bool more = false}) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, size: 17, color: hint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: ink,
                              fontSize: 14.5,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                      if (sub != null) ...[
                        const SizedBox(height: 2),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: hint, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 20, color: point)
                else if (more)
                  Icon(Icons.chevron_right_rounded, size: 20, color: hint),
              ],
            ),
          ),
        );

    final next = AlarmService.nextLabel(_a);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('아침 알람',
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            // 켜기·끄기
            box([
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('알람', style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_a.enabled ? '$next에 울려요' : '꺼져 있어요',
                            style: TextStyle(color: hint, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _a.enabled,
                    activeColor: point,
                    onChanged: (v) {
                      _vib();
                      setState(() => _a.enabled = v);
                    },
                  ),
                ],
              ),
            ], padding: const EdgeInsets.fromLTRB(16, 8, 8, 8)),
            // 시간
            Opacity(
              opacity: _a.enabled ? 1 : 0.45,
              child: IgnorePointer(
                ignoring: !_a.enabled,
                child: Column(
                  children: [
                    box([
                      head('시간'),
                      SizedBox(
                        height: 170,
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
                            brightness: d ? Brightness.dark : Brightness.light,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(color: ink, fontSize: 22),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: DateTime(2000, 1, 1, _a.hour, _a.minute),
                            onDateTimeChanged: (t) => setState(() {
                              _a.hour = t.hour;
                              _a.minute = t.minute;
                            }),
                          ),
                        ),
                      ),
                    ]),
                    // 반복 요일
                    box([
                      head('반복', AlarmService.daysText(_a.days)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 1; i <= 7; i++)
                            GestureDetector(
                              onTap: () {
                                _vib();
                                setState(() {
                                  _a.days.contains(i) ? _a.days.remove(i) : _a.days.add(i);
                                  _a.days.sort();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _a.days.contains(i) ? ink : Colors.transparent,
                                  border: Border.all(color: _a.days.contains(i) ? ink : line, width: 1.2),
                                ),
                                child: Text(_dayNames[i - 1],
                                    style: TextStyle(
                                        color: _a.days.contains(i) ? onInk : ink,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('요일을 하나도 안 고르면 한 번만 울려요', style: TextStyle(color: hint, fontSize: 12)),
                    ]),
                    // 깨울 소리
                    box([
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: head('알람 소리'),
                      ),
                      soundRow(Icons.music_note_rounded, '한 곡', _a.kind == 'song', _pickSong,
                          sub: _a.kind == 'song' ? _a.label : '고른 노래 하나를 반복해서', more: true),
                      soundRow(Icons.shuffle_rounded, '음악 전체 랜덤', _a.kind == 'music_all',
                          () => _pickMusic('music_all', '음악 전체 랜덤')),
                      soundRow(Icons.favorite_border_rounded, '음악 즐겨찾기 랜덤', _a.kind == 'music_fav',
                          () => _pickMusic('music_fav', '음악 즐겨찾기 랜덤')),
                      soundRow(Icons.queue_music_rounded, '재생목록', _a.kind == 'playlist', _pickPlaylist,
                          sub: _a.kind == 'playlist' ? _a.label : null, more: true),
                      soundRow(Icons.radio_rounded, '라디오', _a.kind == 'radio', _pickRadio,
                          sub: _a.kind == 'radio' ? _a.label : '즐겨찾기한 채널', more: true),
                      soundRow(Icons.forest_outlined, '자연', _a.kind == 'nature', _pickNature,
                          sub: _a.kind == 'nature' ? _a.label : '새소리 · 시냇물 · 파도', more: true),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Text('작은 소리로 시작해서 30초 동안 천천히 커져요',
                            style: TextStyle(color: hint, fontSize: 12)),
                      ),
                    ], padding: const EdgeInsets.fromLTRB(0, 14, 0, 14)),
                    // 알람 소리 크기 (폰 소리를 줄여 놔도 이 크기로)
                    box([
                      head('알람 소리 크기', '${(_a.volume * 100).round()}%'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.volume_down_rounded, size: 20, color: hint),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                activeTrackColor: point,
                                inactiveTrackColor: line,
                                thumbColor: point,
                                overlayColor: point.withOpacity(0.1),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              ),
                              child: Slider(
                                value: _a.volume.clamp(0.2, 1.0),
                                min: 0.2,
                                max: 1.0,
                                divisions: 8,
                                onChanged: (v) => setState(() => _a.volume = v),
                              ),
                            ),
                          ),
                          Icon(Icons.volume_up_rounded, size: 20, color: hint),
                        ],
                      ),
                      Text('폰 소리를 줄여 놔도 이 크기로 울리고, 끄면 원래대로 돌아가요',
                          style: TextStyle(color: hint, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: onInk,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
