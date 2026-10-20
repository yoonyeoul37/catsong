# -*- coding: utf-8 -*-
# 팟캐스트 재생 화면을 라디오 재생 화면과 같은 틀로
#  · 위: ⌄ 내리기 / 오른쪽 하트(구독 · 누르면 통통 + 작은 하트) · 다크 · 홈 · ⋮ (라디오와 같은 동그란 버튼)
#  · 가운데: 15초 뒤로 · 재생 · 30초 앞으로 만
#  · 맨 아래 줄: 속도 · 수면 | 종료 (라디오 아래 줄과 같은 모양 · 종료는 확인창 → 작별 인사 → 종료)
#  · 재생 막대는 포인트 색 · 그림 모서리 10
# (apply_podcast_sleep.py 를 먼저 돌린 다음에)
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast_screens.dart')


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


if not os.path.exists(PATH):
    fail('파일이 없어요: ' + PATH)
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s
if 'class _PodSleepBadge' not in s:
    fail('수면 타이머가 아직 없어요. apply_podcast_sleep.py 를 먼저 돌려 주세요')


def rep(label, old, new, done):
    global s
    if done == '\x00' and old not in s:  # 지우는 것: 이미 없으면 끝
        print('✔', label, '(이미 돼 있음)')
        return
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep('import',
    "import '../widgets/sleep_timer_sheet.dart';\n",
    "import '../widgets/sleep_timer_sheet.dart';\n"
    "import 'dart:async';\n"
    "import 'package:just_audio/just_audio.dart' show AudioPlayer;\n"
    "import 'package:audio_service/audio_service.dart' show PlaybackState;\n"
    "import '../main.dart' show globalAudioHandler;\n"
    "import '../providers/player_provider.dart' show SimpleAudioHandler, PlayerProvider;\n"
    "import '../utils/point_color.dart';\n"
    "import '../utils/greeting_images.dart';\n"
    "import '../widgets/farewell_title.dart';\n"
    "import '../widgets/exit_confirm_dialog.dart';\n"
    "import '../widgets/more_menu_sheet.dart';\n",
    done="import '../widgets/exit_confirm_dialog.dart';")

# ── 재생 막대 포인트 색 · 그림 모서리 10 ──
rep('재생 막대 포인트 색',
    '    final point = Theme.of(context).colorScheme.primary;\n    final w = MediaQuery.sizeOf(context).width;\n',
    '    final point = pointColorOf(context); // 재생 막대: 앱 포인트 색 (라디오와 같게)\n    final w = MediaQuery.sizeOf(context).width;\n',
    done='final point = pointColorOf(context); // 재생 막대')
rep('그림 모서리 18 → 10',
    'PodcastArt(url: e.art.isNotEmpty ? e.art : s.art, title: s.title, size: art, radius: 18),',
    'PodcastArt(url: e.art.isNotEmpty ? e.art : s.art, title: s.title, size: art, radius: 10),',
    done='size: art, radius: 10),')

# ── 위 버튼 줄 ──
rep('위 버튼 줄 (⌄ / 하트 · 다크 · 홈 · ⋮)',
    '            Align(\n'
    '              alignment: Alignment.centerLeft,\n'
    '              child: IconButton(\n'
    '                onPressed: () => Navigator.pop(context),\n'
    '                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _text(dark), size: 32),\n'
    '              ),\n'
    '            ),\n',
    '            // 위 버튼: 라디오 재생 화면과 같은 동그란 버튼 · 같은 자리\n'
    '            Padding(\n'
    '              padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),\n'
    '              child: Row(\n'
    '                mainAxisAlignment: MainAxisAlignment.spaceBetween,\n'
    '                children: [\n'
    '                  _PodFloat(\n'
    '                    onTap: () {\n'
    '                      _buzz();\n'
    '                      Navigator.pop(context);\n'
    '                    },\n'
    '                    child: Icon(Icons.expand_more, color: _baseOf(dark), size: 13),\n'
    '                  ),\n'
    '                  Row(\n'
    '                    children: [\n'
    '                      // 구독 하트 (회차 목록 화면 하트와 같음 · 켤 때 통통 + 작은 하트)\n'
    '                      _PodFloat(\n'
    '                        child: _PodHeart(\n'
    '                          isFav: pod.isSub(s.id),\n'
    '                          offColor: _baseOf(dark).withOpacity(0.6),\n'
    '                          iconSize: 13,\n'
    '                          box: 29,\n'
    '                          rise: 44,\n'
    '                          miniSize: 9,\n'
    '                          onTap: () {\n'
    '                            _buzz();\n'
    '                            pod.toggleSub(s);\n'
    '                          },\n'
    '                        ),\n'
    '                      ),\n'
    '                      const SizedBox(width: 10),\n'
    '                      _PodFloat(\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          context.read<ThemeProvider>().setDarkMode(!dark);\n'
    '                        },\n'
    '                        child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,\n'
    '                            color: _baseOf(dark), size: 13),\n'
    '                      ),\n'
    '                      const SizedBox(width: 10),\n'
    '                      _PodFloat(\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          Navigator.of(context).popUntil((route) => route.isFirst);\n'
    '                        },\n'
    '                        child: Icon(Icons.home_rounded, color: _baseOf(dark), size: 13),\n'
    '                      ),\n'
    '                      const SizedBox(width: 10),\n'
    '                      _PodFloat(\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          showMoreMenuSheet(context);\n'
    '                        },\n'
    '                        child: Icon(Icons.more_vert, color: _baseOf(dark), size: 13),\n'
    '                      ),\n'
    '                    ],\n'
    '                  ),\n'
    '                ],\n'
    '              ),\n'
    '            ),\n',
    done='// 위 버튼: 라디오 재생 화면과 같은 동그란 버튼')

# ── 가운데 재생 줄: 속도·수면 빼기 ──
rep('재생 줄에서 속도 버튼 빼기',
    '                // 재생 속도 (누를 때마다 1 → 1.25 → 1.5 → 2 → 0.8)\n'
    '                SizedBox(\n'
    '                  width: 64,\n'
    '                  child: TextButton(\n'
    '                    onPressed: () {\n'
    '                      _buzz();\n'
    '                      pod.nextSpeed();\n'
    '                    },\n'
    "                    child: Text('${_speedText(pod.speed)}×',\n"
    '                        style: TextStyle(color: _text(dark), fontSize: 14, fontWeight: FontWeight.w700)),\n'
    '                  ),\n'
    '                ),\n'
    '                const SizedBox(width: 6),\n'
    '                IconButton(\n',
    '                IconButton(\n',
    done='\x00')
rep('재생 줄에서 수면 버튼 빼기',
    '                  icon: _SkipIcon(back: false, color: _text(dark), size: 34),\n'
    '                ),\n'
    '                const SizedBox(width: 6),\n'
    "                // 수면 타이머 (라디오 재생 화면 '수면' 버튼과 같게: 켜지면 남은 분)\n"
    '                SizedBox(\n'
    '                  width: 64,\n'
    '                  child: _PodSleepButton(dark: dark, pod: pod),\n'
    '                ),\n'
    '              ],\n',
    '                  icon: _SkipIcon(back: false, color: _text(dark), size: 34),\n'
    '                ),\n'
    '              ],\n',
    done='\x00')

# ── 맨 아래 줄 (라디오 아래 줄과 같게) ──
rep('맨 아래 줄: 속도 · 수면 | 종료',
    '            const Spacer(flex: 2),\n'
    '          ],\n'
    '        ),\n'
    '      ),\n'
    '    ));\n'
    '  }\n'
    '\n'
    '  static String _speedText',
    '            const Spacer(flex: 2),\n'
    '          ],\n'
    '        ),\n'
    '      ),\n'
    '      // 아래 줄: 라디오 재생 화면 아래 줄과 같은 모양 (얇은 선 위 · 아이콘 + 글자 · 세로줄 · 종료)\n'
    '      bottomNavigationBar: Container(\n'
    '        decoration: BoxDecoration(\n'
    '          color: _bg(dark),\n'
    '          border: Border(\n'
    '              top: BorderSide(color: dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB), width: 0.5)),\n'
    '        ),\n'
    '        child: SafeArea(\n'
    '          top: false,\n'
    '          child: Padding(\n'
    '            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),\n'
    '            child: Row(\n'
    '              children: [\n'
    '                Expanded(\n'
    '                  child: Row(\n'
    '                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n'
    '                    children: [\n'
    '                      // 재생 속도 (누를 때마다 1 → 1.25 → 1.5 → 2 → 0.8)\n'
    '                      _PodBarItem(\n'
    '                        dark: dark,\n'
    "                        top: Text('${_speedText(pod.speed)}×',\n"
    '                            textScaler: TextScaler.noScaling,\n'
    '                            style: TextStyle(\n'
    '                                color: pod.speed != 1.0 ? _strongOf(dark) : _mutedOf(dark),\n'
    '                                fontSize: 15,\n'
    '                                fontWeight: FontWeight.w700,\n'
    '                                height: 22 / 15)),\n'
    "                        label: podText('속도', 'Speed'),\n"
    '                        on: pod.speed != 1.0,\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          pod.nextSpeed();\n'
    '                        },\n'
    '                      ),\n'
    '                      // 수면 타이머 (켜지면 남은 분)\n'
    '                      _PodBarItem(\n'
    '                        dark: dark,\n'
    '                        icon: Icons.bedtime_outlined,\n'
    '                        label: pod.isSleepTimerActive && pod.sleepRemaining != null\n'
    '                            ? tr.durM(pod.sleepRemaining!.inMinutes + 1)\n'
    '                            : AppLocalizations.of(context)!.radioSleep,\n'
    '                        on: pod.isSleepTimerActive,\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          showModalBottomSheet(\n'
    '                            context: context,\n'
    '                            backgroundColor: Colors.transparent,\n'
    '                            barrierColor: Colors.black.withOpacity(0.7),\n'
    '                            isScrollControlled: true,\n'
    '                            useSafeArea: true,\n'
    '                            builder: (_) => const SleepTimerSheet(podcast: true),\n'
    '                          );\n'
    '                        },\n'
    '                      ),\n'
    '                    ],\n'
    '                  ),\n'
    '                ),\n'
    '                Container(\n'
    '                  width: 1,\n'
    '                  height: 28,\n'
    '                  margin: const EdgeInsets.symmetric(horizontal: 4),\n'
    '                  color: _baseOf(dark).withOpacity(0.12),\n'
    '                ),\n'
    '                // 종료: 확인창 → 작별 인사 → 종료 (라디오와 같음)\n'
    '                GestureDetector(\n'
    '                  behavior: HitTestBehavior.opaque,\n'
    '                  onTap: () async {\n'
    '                    if (await showExitConfirm(context) && context.mounted) _podFarewellAndExit(context);\n'
    '                  },\n'
    '                  child: Padding(\n'
    '                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),\n'
    '                    child: Column(\n'
    '                      mainAxisSize: MainAxisSize.min,\n'
    '                      children: [\n'
    '                        Icon(Icons.power_settings_new_rounded, color: _baseOf(dark).withOpacity(0.55), size: 22),\n'
    '                        const SizedBox(height: 3),\n'
    '                        Text(AppLocalizations.of(context)!.exit,\n'
    '                            style: TextStyle(\n'
    '                                color: _baseOf(dark).withOpacity(0.55), fontSize: 10.5, fontWeight: FontWeight.w500)),\n'
    '                      ],\n'
    '                    ),\n'
    '                  ),\n'
    '                ),\n'
    '              ],\n'
    '            ),\n'
    '          ),\n'
    '        ),\n'
    '      ),\n'
    '    ));\n'
    '  }\n'
    '\n'
    '  static String _speedText',
    done='bottomNavigationBar: Container(\n        decoration: BoxDecoration(\n          color: _bg(dark),')

# ── 하트: 크기를 받을 수 있게 (회차 목록 화면 하트는 그대로) ──
rep('하트 크기 받기',
    '  final bool isFav;\n  final Color offColor;\n  final VoidCallback onTap;\n'
    '  const _PodHeart({required this.isFav, required this.offColor, required this.onTap});\n',
    '  final bool isFav;\n  final Color offColor;\n  final VoidCallback onTap;\n'
    '  final double iconSize; // 하트 크기\n'
    '  final double box; // 누르는 칸\n'
    '  final double rise; // 작은 하트가 올라가는 높이\n'
    '  final double miniSize; // 작은 하트 크기\n'
    '  const _PodHeart({\n'
    '    required this.isFav,\n'
    '    required this.offColor,\n'
    '    required this.onTap,\n'
    '    this.iconSize = 24,\n'
    '    this.box = 46,\n'
    '    this.rise = 74,\n'
    '    this.miniSize = 12,\n'
    '  });\n',
    done='final double miniSize; // 작은 하트 크기')
rep('하트: 올라가는 높이', '      offset: Offset(dx * e + wobble, -74 * e),\n',
    '      offset: Offset(dx * e * widget.box / 46 + wobble, -widget.rise * e),\n', done='-widget.rise * e')
rep('하트: 작은 하트 크기', '          child: const Icon(CupertinoIcons.heart_fill, color: _red, size: 12),\n',
    '          child: Icon(CupertinoIcons.heart_fill, color: _red, size: widget.miniSize),\n', done='size: widget.miniSize')
rep('하트: 누르는 칸', '        width: 46,\n        height: 46,\n        child: AnimatedBuilder(\n',
    '        width: widget.box,\n        height: widget.box,\n        child: AnimatedBuilder(\n', done='width: widget.box,')
rep('하트: 하트 크기', '                    size: 24,\n                  ),\n                ),\n              ],\n',
    '                    size: widget.iconSize,\n                  ),\n                ),\n              ],\n', done='size: widget.iconSize,')

# ── 안 쓰게 된 오른쪽 수면 버튼 모양 → 아래 줄 버튼 모양으로 바꾸기 ──
a = s.find("/// 재생 화면 '수면' 버튼 — 라디오 재생 화면 아래 버튼과 같은 모양")
if a >= 0:
    b = s.find("/// 수면 타이머 남은 시간 줄", a)
    if b < 0:
        fail('예전 수면 버튼 모양 끝을 못 찾았어요')
    s = s[:a] + s[b:]
    print('✔ 예전 오른쪽 수면 버튼 지우기')
else:
    print('✔ 예전 오른쪽 수면 버튼 지우기 (이미 돼 있음)')

if 'class _PodBarItem' not in s:
    s = s.rstrip('\n') + '\n' + r'''
// 라디오 재생 화면과 같은 색 (위 버튼 · 아래 줄)
Color _baseOf(bool dark) => dark ? Colors.white : Colors.black;
Color _strongOf(bool dark) => dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
Color _mutedOf(bool dark) => dark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);

/// 위 동그란 버튼 — 라디오 재생 화면 위 버튼과 같은 모양 (29 · 연한 바탕 · 아이콘 13)
class _PodFloat extends StatelessWidget {
  final VoidCallback? onTap; // 하트처럼 안에서 누르기를 받으면 비워 둠
  final Widget child;
  const _PodFloat({this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = _baseOf(context.watch<ThemeProvider>().isDarkMode);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: base.withOpacity(0.07),
          border: Border.all(color: base.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// 아래 줄 버튼 — 라디오 재생 화면 아래 버튼과 같은 모양 (아이콘 22 + 글자 10.5, 켜지면 진하게)
class _PodBarItem extends StatelessWidget {
  final bool dark;
  final IconData? icon;
  final Widget? top; // 아이콘 대신 글자 (속도 1×)
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _PodBarItem({required this.dark, this.icon, this.top, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = on ? _strongOf(dark) : _mutedOf(dark);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 22, child: Center(child: top ?? Icon(icon, color: c, size: 22))),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: c,
                  fontSize: 10.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

/// 종료: 작별 인사 → 소리 천천히 작게 → 앱 닫기 (라디오 재생 화면과 같은 순서)
void _podFarewellAndExit(BuildContext context) {
  final langCode = Localizations.localeOf(context).languageCode;
  final farewellAsset = langCode == 'ko' ? 'assets/farewell_ko_v4.mp3' : 'assets/greet_outro.mp3';
  if (context.read<ThemeProvider>().voiceGreetingEnabled) { // 한국어는 목소리 · 해외는 멜로디
    final farewellPlayer = AudioPlayer();
    farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
  }
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.05, end: 0.85),
          duration: const Duration(milliseconds: 7000), // 끝인사: 서서히 어둡게
          curve: Curves.easeIn,
          builder: (_, darkValue, __) => Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: farewellImage(context),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(darkValue), BlendMode.darken),
              ),
            ),
            alignment: Alignment.center,
            child: const FarewellTitle(),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);

  // 끝인사 동안 팟캐스트 소리를 1.5초에 걸쳐 천천히 작게
  final pod = PodcastPlayer.instance;
  final fadePlayer = context.read<PlayerProvider>().player;
  final fadeRadio = context.read<RadioProvider>();
  final fadeStart = DateTime.now();
  Timer.periodic(const Duration(milliseconds: 50), (t) {
    final p = (DateTime.now().difference(fadeStart).inMilliseconds / 1500).clamp(0.0, 1.0);
    final v = 1 - 0.88 * Curves.easeOut.transform(p);
    fadePlayer.setVolume(v);
    fadeRadio.setAlarmVolume(v);
    if (p >= 1) t.cancel();
  });

  Future.delayed(const Duration(milliseconds: 6500), () async {
    final fadeOutEntry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Container(color: Colors.black, width: double.infinity, height: double.infinity),
        ),
      ),
    );
    overlay.insert(fadeOutEntry);

    pod.cancelSleepTimer();
    if (pod.isPlaying) await pod.toggle(); // 멈추면서 듣던 곳 기억
    await fadePlayer.stop();
    await fadeRadio.stopRadio();
    await fadeRadio.setAlarmVolume(1.0); // 다음에 켤 때는 원래 크기로
    final handler = globalAudioHandler;
    if (handler is SimpleAudioHandler) {
      handler.playbackState.add(PlaybackState());
      handler.mediaItem.add(null);
      await handler.stop();
    }

    await Future.delayed(const Duration(milliseconds: 900));
    entry.remove();
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('closeApp');
  });
}
'''
    print('✔ 위 버튼 · 아래 줄 · 종료 모양')
else:
    print('✔ 위 버튼 · 아래 줄 · 종료 모양 (이미 돼 있음)')

for bad in ('_PodSleepButton',):
    if bad in s:
        fail(f'예전 코드({bad})가 남아 있어요')
if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
