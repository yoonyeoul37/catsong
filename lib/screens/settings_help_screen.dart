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

/// 설정 도움말을 한 번이라도 열어봤는지 (⋮ 메뉴의 작은 점 표시용)
class HelpSeen {
  static final seen = ValueNotifier<bool>(true);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    seen.value = p.getBool('helpSeen') ?? false;
  }

  static Future<void> mark() async {
    seen.value = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool('helpSeen', true);
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

const _topics = <_HelpTopic>[
  _HelpTopic(
    Icons.perm_media_outlined,
    '음악·동영상 불러오기',
    '음악이나 동영상이 목록에 나타나지 않을 때',
    ['[설정 열기] 선택', '[권한] 선택', '[음악 및 오디오]와 [사진 및 동영상] 허용'],
    ios: ['[설정 열기] 선택', '[미디어 및 Apple Music]과 [사진] 켜기', '앱으로 돌아오기'],
    note: '허용한 뒤 앱으로 돌아오면 목록이 바로 나타나요.',
    path: '설정 → 애플리케이션 → 파란소리 → 권한 → 음악 및 오디오 / 사진 및 동영상',
    iosPath: '설정 → 파란소리 → 미디어 및 Apple Music · 사진',
  ),
  _HelpTopic(
    Icons.battery_charging_full_rounded,
    '백그라운드 재생',
    '화면을 껐을 때 음악이 멈추는 경우',
    ['[설정 열기] 선택', '[배터리] 선택', '[제한 없음] 선택'],
    note: '화면을 꺼도 음악과 라디오가 끊기지 않도록 도와줘요.\n휴대폰에 따라 "최적화 안 함" 등 다른 이름으로 표시될 수 있어요.',
    path: '설정 → 애플리케이션 → 파란소리 → 배터리 → 제한 없음',
  ),
  _HelpTopic(
    Icons.alarm_rounded,
    '아침 알람',
    '알람이 울리지 않거나 지연되는 경우',
    ['[설정 열기] 선택', '[알람 및 리마인더] 허용', '앱으로 돌아오기'],
    note: '"백그라운드 재생"의 배터리 설정도 함께 해 두면 알람이 더 정확하게 울려요.',
    path: '설정 → 애플리케이션 → 파란소리 → 알람 및 리마인더 → 허용',
    exactAlarm: true,
  ),
  _HelpTopic(
    Icons.notifications_none_rounded,
    '잠금 화면 재생 버튼',
    '잠금 화면이나 알림창에 재생 버튼이 표시되지 않을 때',
    ['[설정 열기] 선택', '[알림] 선택', '[알림 허용] 켜기'],
    ios: ['[설정 열기] 선택', '[알림] 선택', '[알림 허용] 켜기'],
    note: '알림을 허용해야 잠금 화면과 알림창에 재생 버튼이 표시돼요.',
    path: '설정 → 애플리케이션 → 파란소리 → 알림 → 알림 허용',
    iosPath: '설정 → 파란소리 → 알림 → 알림 허용',
  ),
  _HelpTopic(
    Icons.music_note_outlined,
    '벨소리 설정',
    '벨소리나 알림음을 설정할 수 없을 때',
    ['[설정 열기] 선택', '[시스템 설정 변경] 선택', '[허용] 켜기'],
    note: '허용한 뒤 벨소리 설정을 다시 시도해 보세요.',
    path: '설정 → 애플리케이션 → 파란소리 → 시스템 설정 변경 → 허용',
  ),
];

class SettingsHelpScreen extends StatefulWidget {
  const SettingsHelpScreen({super.key});

  @override
  State<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends State<SettingsHelpScreen> {
  int? _open; // 펼친 카드 (한 번에 하나만)
  final List<GlobalKey> _keys = List.generate(_topics.length, (_) => GlobalKey());

  // 돋보기: 이 화면 글자만 크게 (기본 → 크게 → 아주 크게, 기억)
  static const _levels = [1.0, 1.2, 1.4];
  static const _levelNames = ['기본', '크게', '아주 크게'];
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
    });
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
      showParanToast(context, '설정 화면을 열 수 없어요. 아래 "직접 설정하기" 순서대로 이동해 주세요');
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
    final body = '어떤 문제가 있나요?\n(여기에 적어 주세요)\n\n\n\n'
        '── 아래는 자동으로 들어가요 ──\n'
        '휴대폰 모델: $model\n'
        '${Platform.isIOS ? '시스템' : '안드로이드'}: $os\n'
        '앱 버전: 파란소리 $ver';
    // (+ 대신 %20 으로: 메일 앱에 + 가 그대로 보이는 것 방지)
    final uri = Uri.parse('mailto:$_contactMail'
        '?subject=${Uri.encodeComponent('[파란소리 문의]')}'
        '&body=${Uri.encodeComponent(body)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok && mounted) {
      await Clipboard.setData(const ClipboardData(text: _contactMail));
      if (mounted) showParanToast(context, '메일 앱을 찾을 수 없어 주소를 복사했어요 ($_contactMail)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDarkMode;
    final bg = d ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF32302C) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final iconBg = d ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5);
    final line = d ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
    final line2 = d ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    final isIos = Platform.isIOS;
    final mq = MediaQuery.of(context);
    final z = _zoom;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('설정 도움말',
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text('앱 사용 중 문제가 발생하면 아래 안내를 확인하세요.',
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
                                                  Text('직접 설정하기',
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
                                                child: const Text('설정 열기',
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
                                Text('추가 도움이 필요하신가요?',
                                    style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('휴대폰 모델과 문제 상황을 알려주세요.',
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
                          onPressed: _mailUs,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: card,
                            foregroundColor: ink,
                            side: BorderSide(color: line2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          label: const Text('이메일 문의',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text(_contactMail, style: TextStyle(color: hint, fontSize: 12))),
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
