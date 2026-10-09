import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

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
  final String? note;
  final String path; // 직접 찾아갈 때 (안드로이드)
  final String? iosPath; // 직접 찾아갈 때 (아이폰)
  const _HelpTopic(this.icon, this.title, this.when, this.android,
      {this.ios, this.note, required this.path, this.iosPath});
}

const _topics = <_HelpTopic>[
  _HelpTopic(
    Icons.perm_media_outlined,
    '음악·동영상 불러오기',
    '곡이나 동영상 목록이 안 나올 때',
    ['아래 설정 열기 누르기', '권한 → 음악 및 오디오 / 사진 및 동영상', '허용 고르고 돌아오기'],
    ios: ['아래 설정 열기 누르기', '미디어 및 Apple Music · 사진 켜기', '앱으로 돌아오기'],
    note: '돌아오면 바로 목록이 나와요',
    path: '설정 → 애플리케이션(앱) → 파란소리 → 권한 → 음악 및 오디오 / 사진 및 동영상',
    iosPath: '설정 → 파란소리 → 미디어 및 Apple Music · 사진',
  ),
  _HelpTopic(
    Icons.battery_charging_full_rounded,
    '화면 꺼도 안 끊기게',
    '화면을 끄면 음악·라디오가 멈출 때',
    ['아래 설정 열기 누르기', '배터리 누르기', '제한 없음 고르기'],
    note: '폰마다 "최적화 안 함"이라고 나올 수도 있어요',
    path: '설정 → 애플리케이션(앱) → 파란소리 → 배터리 → 제한 없음',
  ),
  _HelpTopic(
    Icons.notifications_none_rounded,
    '잠금화면 재생 버튼',
    '잠금화면·알림창에 재생 버튼이 안 보일 때',
    ['아래 설정 열기 누르기', '알림 누르기', '알림 허용 켜기'],
    ios: ['아래 설정 열기 누르기', '알림 누르기', '알림 허용 켜기'],
    path: '설정 → 애플리케이션(앱) → 파란소리 → 알림 → 알림 허용',
    iosPath: '설정 → 파란소리 → 알림 → 알림 허용',
  ),
  _HelpTopic(
    Icons.music_note_outlined,
    '벨소리로 지정',
    '벨소리·알림음 지정이 안 될 때',
    ['아래 설정 열기 누르기', '시스템 설정 변경(설정 변경) 누르기', '허용 켜기'],
    path: '설정 → 애플리케이션(앱) → 파란소리 → 시스템 설정 변경 → 허용',
  ),
];

class SettingsHelpScreen extends StatefulWidget {
  const SettingsHelpScreen({super.key});

  @override
  State<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends State<SettingsHelpScreen> {
  @override
  void initState() {
    super.initState();
    HelpSeen.mark(); // 한 번 열면 ⋮ 메뉴의 점이 사라짐
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
    final isIos = Platform.isIOS;
    final topics = _topics.where((t) => !isIos || t.ios != null).toList();

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
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text('설정 열기를 누르면 파란소리 앱 설정이 바로 열려요',
                  style: TextStyle(color: hint, fontSize: 12.5)),
            ),
            for (final t in topics) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 줄: 아이콘 · 제목 / 이럴 때
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                          child: Icon(t.icon, size: 17, color: sub),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(t.when, style: TextStyle(color: hint, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 1 · 2 · 3 순서
                    for (var i = 0; i < (isIos ? t.ios! : t.android).length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 3),
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                              child: Text('${i + 1}',
                                  style: TextStyle(color: bg, fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text((isIos ? t.ios! : t.android)[i],
                                  style: TextStyle(color: sub, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    if (t.note != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 37, bottom: 4),
                        child: Text(t.note!, style: TextStyle(color: hint, fontSize: 11.5)),
                      ),
                    // 직접 찾아갈 때 전체 경로 (폰 회사마다 메뉴 이름이 조금 달라요)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('직접 찾아갈 때',
                              style: TextStyle(color: hint, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(isIos ? (t.iosPath ?? t.path) : t.path,
                              style: TextStyle(color: sub, fontSize: 12, height: 1.45)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 먹색 버튼: 이 앱 설정 화면 바로 열기
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ink,
                          foregroundColor: bg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('설정 열기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
