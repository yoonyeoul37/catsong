import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../services/alarm_service.dart';
import '../widgets/paran_toast.dart';
import '../l10n/locale_holder.dart';
import 'feedback_screen.dart';

/// 설정 도움말을 한 번이라도 열어봤는지 (⋮ 메뉴의 작은 점 표시용)
/// 'helpSeen2': 위젯 · 안드로이드 오토 안내가 생겨서, 예전에 열어 본 사람에게도 점을 한 번 더 보여 줌
class HelpSeen {
  static final seen = ValueNotifier<bool>(true);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    seen.value = p.getBool('helpSeen2') ?? false;
  }

  static Future<void> mark() async {
    seen.value = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool('helpSeen2', true);
  }
}

/// 도움말 한 칸 (안드로이드 / 아이폰 순서가 다를 수 있음)
class _HelpTopic {
  final IconData icon;
  final String title;
  final String when; // 이럴 때 보세요
  final List<String> android;
  final List<String>? ios; // null이면 아이폰에선 안 보임 (필요 없는 설정)
  final String? note; // 보조 설명
  final String path; // 직접 설정하기 (안드로이드)
  final String? iosPath; // 직접 설정하기 (아이폰)
  final bool exactAlarm; // 설정 열기 → 알람 및 리마인더 화면으로 바로
  const _HelpTopic(this.icon, this.title, this.when, this.android,
      {this.ios, this.note, required this.path, this.iosPath, this.exactAlarm = false});
}

List<_HelpTopic> get _topics => [
  _HelpTopic(
    Icons.perm_media_outlined,
    tr.helpMediaTitle,
    tr.helpMediaWhen,
    [tr.helpStepOpen, tr.helpStepPerm, tr.helpStepMediaAllow],
    ios: [tr.helpStepOpen, tr.helpStepIosMedia, tr.helpStepBack],
    note: tr.helpMediaNote,
    path: tr.helpMediaPath,
    iosPath: tr.helpMediaIosPath,
  ),
  _HelpTopic(
    Icons.battery_charging_full_rounded,
    tr.helpBgTitle,
    tr.helpBgWhen,
    [tr.helpStepOpen, tr.helpStepBattery, tr.helpStepUnrestricted],
    note: tr.helpBgNote,
    path: tr.helpBgPath,
  ),
  _HelpTopic(
    Icons.alarm_rounded,
    tr.helpAlarmTitle,
    tr.helpAlarmWhen,
    [tr.helpStepOpen, tr.helpStepAlarmAllow, tr.helpStepBack],
    note: tr.helpAlarmNote,
    path: tr.helpAlarmPath,
    exactAlarm: true,
  ),
  _HelpTopic(
    Icons.notifications_none_rounded,
    tr.helpLockTitle,
    tr.helpLockWhen,
    [tr.helpStepOpen, tr.helpStepNotif, tr.helpStepNotifAllow],
    ios: [tr.helpStepOpen, tr.helpStepNotif, tr.helpStepNotifAllow],
    note: tr.helpLockNote,
    path: tr.helpLockPath,
    iosPath: tr.helpLockIosPath,
  ),
  _HelpTopic(
    Icons.music_note_outlined,
    tr.helpRingTitle,
    tr.helpRingWhen,
    [tr.helpStepOpen, tr.helpStepModify, tr.helpStepAllowOn],
    note: tr.helpRingNote,
    path: tr.helpRingPath,
  ),
];

/// 쓰는 방법 안내 (위젯 · 안드로이드 오토) — 설정이 아니라서 '설정 열기' 버튼 없음
class _GuideSec {
  final String? head; // 굵은 제목 (위젯 추가 방법 등)
  final String? sub; // 작은 제목 (① 기본형 …)
  final String? lead; // 회색 칸 위 한 줄 (음성 예시 설명)
  final List<String> items;
  final bool numbered; // 1 2 3 동그라미 (아니면 작은 점)
  final bool box; // 회색 칸 안에 (음성 예시)
  const _GuideSec({this.head, this.sub, this.lead, this.items = const [], this.numbered = false, this.box = false});
}

class _Guide {
  final String id; // '새로' 표시 기억용
  final IconData icon;
  final String title;
  final String when;
  final List<_GuideSec> secs;
  final String note;
  const _Guide(this.id, this.icon, this.title, this.when, this.secs, this.note);
}

List<_Guide> get _guides => [
  _Guide('widget', Icons.widgets_outlined, tr.helpWidgetTitle, tr.helpWidgetWhen, [
    _GuideSec(head: tr.helpWidgetAddHead, items: [tr.helpWidgetAdd1, tr.helpWidgetAdd2, tr.helpWidgetAdd3], numbered: true),
    _GuideSec(head: tr.helpWidgetSizeHead, sub: tr.helpWidgetBasic,
        items: [tr.helpWidgetBasic1, tr.helpWidgetBasic2, tr.helpWidgetBasic3, tr.helpWidgetBasic4]),
    _GuideSec(sub: tr.helpWidgetBig, items: [tr.helpWidgetBig1, tr.helpWidgetBig2, tr.helpWidgetBig3]),
    _GuideSec(sub: tr.helpWidgetTall, items: [tr.helpWidgetTall1, tr.helpWidgetTall2]),
    _GuideSec(head: tr.helpWidgetAllHead, items: [tr.helpWidgetAll1, tr.helpWidgetAll2]),
  ], tr.helpWidgetNote),
  _Guide('car', Icons.directions_car_outlined, tr.helpCarTitle, tr.helpCarWhen, [
    _GuideSec(head: tr.helpCarUseHead, items: [tr.helpCarUse1, tr.helpCarUse2, tr.helpCarUse3, tr.helpCarUse4], numbered: true),
    _GuideSec(head: tr.helpCarFindHead, items: [tr.helpCarFind1, tr.helpCarFind2, tr.helpCarFind3]),
    _GuideSec(head: tr.helpCarVoiceHead, lead: tr.helpCarVoiceHow,
        items: [tr.helpCarVoice1, tr.helpCarVoice2, tr.helpCarVoice3], box: true),
  ], tr.helpCarNote),
];

class SettingsHelpScreen extends StatefulWidget {
  const SettingsHelpScreen({super.key, this.openGuide});
  final String? openGuide; // 홈 팁 [보기] → 이 안내 카드('widget' · 'car')를 펼친 채로 열기

  @override
  State<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends State<SettingsHelpScreen> {
  int? _open; // 펼친 카드 (한 번에 하나만)
  final List<GlobalKey> _keys = List.generate(_topics.length + _guides.length, (_) => GlobalKey()); // 설정 카드 + 안내 카드
  Set<String> _seenNew = {}; // 한 번 펼쳐 본 안내 카드 ('새로' 표시 없앰)
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
  bool _newLoaded = false;

  // 돋보기: 이 화면 글자만 크게 (기본 → 크게 → 아주 크게, 기억)
  static const _levels = [1.0, 1.2, 1.4];
  static List<String> get _levelNames => [tr.zoomDefault, tr.zoomLarge, tr.zoomXLarge];
  double _zoom = 1.0;
  final Map<int, Offset> _pointers = {};
  double? _pinchStartDist;
  double _pinchStartZoom = 1.0;

  @override
  void initState() {
    super.initState();
    HelpSeen.mark(); // 한 번 열면 ⋮ 메뉴의 점이 사라짐
    SharedPreferences.getInstance().then((p) {
      final z = p.getDouble('helpZoom');
      if (z != null && mounted) setState(() => _zoom = z.clamp(1.0, 1.6));
      if (mounted) {
        setState(() {
          _seenNew = (p.getStringList('helpNewSeen') ?? const <String>[]).toSet();
          _newLoaded = true;
        });
      }
    });
    // 홈 팁 [보기]로 왔으면: 안내 카드는 아래쪽이라 먼저 맨 아래로 → 펼치고 → 카드 위쪽이 보이게
    final g = widget.openGuide;
    if (g != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final gi = _guides.indexWhere((x) => x.id == g);
        if (gi < 0 || !mounted) return;
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        _toggleGuide(gi);
        Future.delayed(const Duration(milliseconds: 560), () {
          final ctx = _keys[_topics.length + gi].currentContext;
          if (ctx != null && mounted) {
            Scrollable.ensureVisible(ctx, alignment: 0.02, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
          }
        });
      });
    }
  }

  Future<void> _saveZoom() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('helpZoom', _zoom);
  }

  int get _levelIndex {
    var best = 0;
    for (var i = 0; i < _levels.length; i++) {
      if ((_levels[i] - _zoom).abs() < (_levels[best] - _zoom).abs()) best = i;
    }
    return best;
  }

  /// 돋보기 버튼: 다음 크기로
  void _nextZoom() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final next = _levels.firstWhere((l) => l > _zoom + 0.01, orElse: () => _levels.first);
    setState(() => _zoom = next);
    _saveZoom();
  }

  // ── 두 손가락으로 벌리면 크게, 오므리면 작게 ──
  double _dist() {
    final p = _pointers.values.toList();
    return (p[0] - p[1]).distance;
  }

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _pinchStartDist = _dist();
      _pinchStartZoom = _zoom;
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _pinchStartDist;
    if (_pointers.length == 2 && start != null && start > 0) {
      final z = (_pinchStartZoom * _dist() / start).clamp(1.0, 1.6);
      if ((z - _zoom).abs() > 0.01) setState(() => _zoom = z);
    }
  }

  void _onUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _pinchStartDist != null) {
      _pinchStartDist = null;
      _saveZoom();
    }
  }

  void _toggle(int i) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    setState(() => _open = _open == i ? null : i);
    // 펼친 카드가 화면 아래로 잘리면 살짝 올려서 보여주기
    if (_open == i) {
      Future.delayed(const Duration(milliseconds: 260), () {
        final ctx = _keys[i].currentContext;
        if (ctx != null && mounted) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
        }
      });
    }
  }

  /// 안내 카드 펼치기 (처음 펼치면 '새로' 표시 없앰)
  void _toggleGuide(int gi) {
    final id = _guides[gi].id;
    if (!_seenNew.contains(id)) {
      setState(() => _seenNew.add(id));
      SharedPreferences.getInstance().then((p) => p.setStringList('helpNewSeen', _seenNew.toList()));
    }
    _toggle(_topics.length + gi);
  }

  /// 안내 카드 한 장 (위의 설정 카드와 같은 모양 · 펼치면 순서 · 설명 · 음성 예시)
  Widget _guideCard(int gi,
      {required Color card,
      required Color ink,
      required Color sub,
      required Color hint,
      required Color iconBg,
      required Color line,
      required Color bg,
      required double z}) {
    final g = _guides[gi];
    final ki = _topics.length + gi;
    final open = _open == ki;
    final isNew = _newLoaded && !_seenNew.contains(g.id);
    // 줄 앞 표시: 순서는 먹색 동그라미 숫자, 나머지는 작은 점 (같은 폭이라 글자 줄이 맞음)
    Widget mark(int? n) => SizedBox(
          width: 22 * z,
          height: 22 * z,
          child: n != null
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                  child: Text('$n', style: TextStyle(color: bg, fontSize: 11.5, fontWeight: FontWeight.w700)),
                )
              : Center(
                  child: Container(
                    width: 5 * z,
                    height: 5 * z,
                    decoration: BoxDecoration(color: hint, shape: BoxShape.circle),
                  ),
                ),
        );
    Widget row(String text, int? n) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 3),
              mark(n),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 2 * z),
                  child: Text(text, style: TextStyle(color: sub, fontSize: 13.5, height: 1.4)),
                ),
              ),
            ],
          ),
        );
    return Container(
      key: _keys[ki],
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 줄 (설정 카드와 같게)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _toggleGuide(gi),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 30 * z,
                      height: 30 * z,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                      child: Icon(g.icon, size: 17 * z, color: sub),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(g.title,
                                    style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                              ),
                              if (isNew)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF2F7DE8), borderRadius: BorderRadius.circular(6)),
                                  child: Text(tr.helpNewBadge,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(g.when, style: TextStyle(color: hint, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 230),
                      curve: Curves.easeOutCubic,
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: hint, size: 24 * z),
                    ),
                  ],
                ),
              ),
            ),
            // 펼친 내용
            AnimatedSize(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 1, thickness: 0.5, color: line),
                          const SizedBox(height: 14),
                          for (final s in g.secs) ...[
                            if (s.head != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 3, bottom: 10),
                                child: Text(s.head!,
                                    style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
                              ),
                            if (s.sub != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 3, bottom: 8),
                                child: Text(s.sub!,
                                    style: TextStyle(color: sub, fontSize: 13, fontWeight: FontWeight.w700)),
                              ),
                            if (s.box)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                decoration:
                                    BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (s.lead != null) ...[
                                      Text(s.lead!,
                                          style: TextStyle(
                                              color: hint, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.4)),
                                      const SizedBox(height: 6),
                                    ],
                                    for (final it in s.items)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(it, style: TextStyle(color: sub, fontSize: 13, height: 1.5)),
                                      ),
                                  ],
                                ),
                              )
                            else
                              for (var i = 0; i < s.items.length; i++) row(s.items[i], s.numbered ? i + 1 : null),
                            const SizedBox(height: 4),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(g.note, style: TextStyle(color: hint, fontSize: 12, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 설정 열기: 안 열리면 앱 정보 화면으로, 그것도 안 되면 안내
  Future<void> _openSettings(_HelpTopic t) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (t.exactAlarm) {
      try {
        await AlarmService.openExactSettings();
        return;
      } catch (_) {}
    }
    var ok = false;
    try {
      ok = await openAppSettings();
    } catch (_) {}
    if (!ok && mounted) {
      showParanToast(context, tr.helpCantOpen);
    }
  }

  // ── 문의하기: 메일 앱 열기 (폰 기종 · 안드로이드 · 앱 버전 미리 채움) ──
  static const _contactMail = 'info@knexm.com';
  late final Future<PackageInfo> _pkg = PackageInfo.fromPlatform();

  Future<void> _mailUs() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    var model = '', os = '', ver = '';
    try {
      if (Platform.isIOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        model = i.utsname.machine;
        os = 'iOS ${i.systemVersion}';
      } else {
        final a = await DeviceInfoPlugin().androidInfo;
        model = '${a.manufacturer} ${a.model}';
        os = '${a.version.release} (SDK ${a.version.sdkInt})';
      }
    } catch (_) {}
    try {
      final p = await _pkg;
      ver = '${p.version} (${p.buildNumber})';
    } catch (_) {}
    final body = '${tr.mailBodyAsk}\n\n\n\n'
        '${tr.mailBodyAuto}\n'
        '${tr.mailModel}: $model\n'
        '${Platform.isIOS ? tr.mailSystem : tr.mailAndroid}: $os\n'
        '${tr.mailAppVersion}: Paransori $ver';
    // (+ 대신 %20 으로: 메일 앱에 + 가 그대로 보이는 것 방지)
    final uri = Uri.parse('mailto:$_contactMail'
        '?subject=${Uri.encodeComponent(tr.mailSubject)}'
        '&body=${Uri.encodeComponent(body)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok && mounted) {
      await Clipboard.setData(const ClipboardData(text: _contactMail));
      if (mounted) showParanToast(context, tr.mailCopied(_contactMail));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDarkMode;
    final bg = d ? const Color(0xFF242424) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF323232) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final iconBg = d ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5);
    final line = d ? const Color(0xFF4A4A4A) : const Color(0xFFEEE9DF);
    final line2 = d ? const Color(0xFF4A4A4A) : const Color(0xFFE2DACB);
    final isIos = Platform.isIOS;
    final mq = MediaQuery.of(context);
    final z = _zoom;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(tr.moreHelpTitle,
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),
        ),
        actions: [
          // 돋보기: 기본 → 크게 → 아주 크게
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _nextZoom,
              style: TextButton.styleFrom(
                foregroundColor: ink,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(48, 40),
              ),
              icon: Icon(_levelIndex == _levels.length - 1 ? Icons.zoom_out_rounded : Icons.zoom_in_rounded, size: 22),
              label: Text(_levelNames[_levelIndex],
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),
      ),
      body: SafeArea(
        top: false,
        child: Listener(
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onUp,
          // 이 화면 글자만 크게 (앱 전체 글자 크기 × 돋보기)
          child: MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * z)),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(tr.helpIntro,
                      style: TextStyle(color: hint, fontSize: 12.5)),
                ),
                for (var ti = 0; ti < _topics.length; ti++)
                  if (!isIos || _topics[ti].ios != null) ...[
                    Builder(builder: (_) {
                      final t = _topics[ti];
                      final open = _open == ti;
                      final steps = isIos ? t.ios! : t.android;
                      return Container(
                        key: _keys[ti],
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 제목 줄 (카드 위쪽 전체를 눌러 펼치기/접기)
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _toggle(ti),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30 * z,
                                        height: 30 * z,
                                        decoration:
                                            BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                                        child: Icon(t.icon, size: 17 * z, color: sub),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.title,
                                                style: TextStyle(
                                                    color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            Text(t.when, style: TextStyle(color: hint, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      AnimatedRotation(
                                        turns: open ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 230),
                                        curve: Curves.easeOutCubic,
                                        child: Icon(Icons.keyboard_arrow_down_rounded, color: hint, size: 24 * z),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 펼친 내용: 순서 → 보조 설명 → 직접 설정하기 → 설정 열기
                              AnimatedSize(
                                duration: const Duration(milliseconds: 230),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: !open
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Divider(height: 1, thickness: 0.5, color: line),
                                            const SizedBox(height: 14),
                                            for (var i = 0; i < steps.length; i++)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 10),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(width: 3),
                                                    Container(
                                                      width: 22 * z,
                                                      height: 22 * z,
                                                      alignment: Alignment.center,
                                                      decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                                                      child: Text('${i + 1}',
                                                          style: TextStyle(
                                                              color: bg, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Padding(
                                                        padding: EdgeInsets.only(top: 2 * z),
                                                        child: Text(steps[i],
                                                            style: TextStyle(color: sub, fontSize: 13.5, height: 1.4)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (t.note != null)
                                              Padding(
                                                padding: EdgeInsets.only(left: 15 + 22 * z, bottom: 6),
                                                child: Text(t.note!,
                                                    style: TextStyle(color: hint, fontSize: 12, height: 1.5)),
                                              ),
                                            // 직접 설정하기 (폰 회사마다 메뉴 이름이 조금 달라요)
                                            Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(top: 6, bottom: 12),
                                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                              decoration:
                                                  BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(tr.setManually,
                                                      style: TextStyle(
                                                          color: hint, fontSize: 11.5, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 3),
                                                  Text(isIos ? (t.iosPath ?? t.path) : t.path,
                                                      style: TextStyle(color: sub, fontSize: 12.5, height: 1.5)),
                                                ],
                                              ),
                                            ),
                                            // 먹색 버튼: 이 앱 설정 화면 바로 열기
                                            SizedBox(
                                              width: double.infinity,
                                              height: 48,
                                              child: ElevatedButton(
                                                onPressed: () => _openSettings(t),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: ink,
                                                  foregroundColor: bg,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: Text(tr.openSettings,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                // ── 이렇게도 들을 수 있어요: 위젯 · 안드로이드 오토 (둘 다 안드로이드 기능이라 아이폰에선 안 보임) ──
                if (!isIos) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                    child: Text(tr.helpGuideHeader,
                        style: TextStyle(color: sub, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                  for (var gi = 0; gi < _guides.length; gi++) ...[
                    _guideCard(gi,
                        card: card, ink: ink, sub: sub, hint: hint, iconBg: iconBg, line: line, bg: bg, z: z),
                    const SizedBox(height: 10),
                  ],
                ],
                // ── 그래도 안 되면: 문의하기 (펼치지 않는 카드) ──
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30 * z,
                            height: 30 * z,
                            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                            child: Icon(Icons.mail_outline_rounded, size: 17 * z, color: sub),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr.needMoreHelp,
                                    style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(tr.tellUsModel,
                                    style: TextStyle(color: hint, fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: card,
                            foregroundColor: ink,
                            side: BorderSide(color: line2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: Text(fbText('의견 보내기', 'Send feedback'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 메일 주소: 누르면 메일 앱 (예전처럼)
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _mailUs,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Text(_contactMail,
                                style: TextStyle(
                                    color: hint, fontSize: 12, decoration: TextDecoration.underline, decorationColor: hint)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 맨 아래 작은 회사 표시
                const SizedBox(height: 22),
                FutureBuilder<PackageInfo>(
                  future: _pkg,
                  builder: (context, snap) => Column(
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Paran', style: TextStyle(color: Color(0xFF2589E8))),
                          const TextSpan(text: 'sori'),
                          TextSpan(
                              text: snap.hasData ? '  v${snap.data!.version}' : '',
                              style: TextStyle(color: hint, fontSize: 11.5, fontWeight: FontWeight.w500)),
                        ]),
                        style: GoogleFonts.quicksand(color: sub, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text('KNEXM Co., Ltd.', style: TextStyle(color: hint, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
