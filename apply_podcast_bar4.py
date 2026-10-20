# -*- coding: utf-8 -*-
# 팟캐스트 재생 화면 아래 줄: 속도 · 수면 · 회차 · 구독 | 종료 (라디오 아래 줄처럼 4개)
#  · 회차: 지금 듣는 팟캐스트의 회차 목록으로 (라디오 '편성표' 자리)
#  · 구독: 구독한 팟캐스트 목록 창 (라디오 '즐겨찾기' 목록 창과 같은 모양) → 누르면 그 팟캐스트로
# (apply_podcast_player_bar.py 를 먼저 돌린 다음에)
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
if 'class _PodBarItem' not in s:
    fail('아래 줄이 아직 없어요. apply_podcast_player_bar.py 를 먼저 돌려 주세요')


def rep(label, old, new, done):
    global s
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep('import', "import '../widgets/more_menu_sheet.dart';\n",
    "import '../widgets/more_menu_sheet.dart';\nimport '../widgets/paran_dialog.dart' show ParanCloseX;\n",
    done="import '../widgets/paran_dialog.dart' show ParanCloseX;")

rep("아래 줄에 '회차' · '구독'",
    '                            builder: (_) => const SleepTimerSheet(podcast: true),\n'
    '                          );\n'
    '                        },\n'
    '                      ),\n'
    '                    ],\n',
    '                            builder: (_) => const SleepTimerSheet(podcast: true),\n'
    '                          );\n'
    '                        },\n'
    '                      ),\n'
    "                      // 회차: 지금 듣는 팟캐스트의 회차 목록 (라디오 '편성표' 자리)\n"
    '                      _PodBarItem(\n'
    '                        dark: dark,\n'
    '                        icon: Icons.format_list_bulleted,\n'
    "                        label: podText('회차', 'Episodes'),\n"
    '                        on: false,\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          _openPodShow(context, s);\n'
    '                        },\n'
    '                      ),\n'
    "                      // 구독: 구독한 팟캐스트 목록 (라디오 '즐겨찾기' 자리)\n"
    '                      _PodBarItem(\n'
    '                        dark: dark,\n'
    '                        icon: CupertinoIcons.heart,\n'
    "                        label: podText('구독', 'Subscribed'),\n"
    '                        on: false,\n'
    '                        onTap: () {\n'
    '                          _buzz();\n'
    '                          showModalBottomSheet(\n'
    '                            context: context,\n'
    '                            backgroundColor: Colors.transparent,\n'
    '                            isScrollControlled: true,\n'
    '                            builder: (_) => const _PodSubsSheet(),\n'
    '                          );\n'
    '                        },\n'
    '                      ),\n'
    '                    ],\n',
    done="label: podText('회차', 'Episodes'),")

if 'class _PodSubsSheet' not in s:
    s = s.rstrip('\n') + '\n' + r'''
/// 팟캐스트 회차 목록 화면 열기 (다른 곳과 같은 부드러운 페이드)
void _openPodShow(BuildContext context, PodcastShow show) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          PodcastShowScreen(show: show, country: tr.localeName.startsWith('ko') ? 'kr' : 'us'),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

/// '구독' 목록 창 — 라디오 '즐겨찾기' 목록 창과 같은 모양
/// 위: 지금 듣는 팟캐스트(먹색 카드) / 아래: 흰 카드에 줄들 · 누르면 그 팟캐스트 회차 목록으로
class _PodSubsSheet extends StatelessWidget {
  const _PodSubsSheet();

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final pod = context.watch<PodcastPlayer>();
    final bg = dark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final card = dark ? const Color(0xFF3E3B37) : Colors.white;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    final list = pod.subs.values.toList().reversed.toList(); // 최근에 구독한 것부터
    final curId = pod.show?.id;
    final current = list.where((x) => x.id == curId).toList();
    final others = list.where((x) => x.id != curId).toList();
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    void open(PodcastShow x) {
      _buzz();
      Navigator.pop(context);
      _openPodShow(context, x);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            // 위: 제목 · 개수 · 닫기
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(podText('구독 중', 'Subscribed'),
                        style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
                  Text(tr.countItems(list.length), style: TextStyle(color: sub, fontSize: 12.5)),
                  const SizedBox(width: 6),
                  ParanCloseX(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.heart, size: 40, color: sub.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(podText('구독한 팟캐스트가 없어요', 'No subscriptions yet'),
                          style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(podText('하트를 누르면 여기에 모여요', 'Tap the heart to keep a podcast here'),
                          textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 12.5)),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 지금 듣는 팟캐스트 (먹색 카드)
                      for (final x in current)
                        GestureDetector(
                          onTap: () => open(x),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                PodcastArt(url: x.art, title: x.title, size: 44, radius: 10),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: bg.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFFF6B5E), shape: BoxShape.circle)),
                                            const SizedBox(width: 5),
                                            Text(tr.listeningNow,
                                                style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(x.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: bg, fontSize: 15, fontWeight: FontWeight.w700)),
                                      if (pod.episode != null)
                                        Text(pod.episode!.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: bg.withOpacity(0.65), fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: bg.withOpacity(0.6), size: 22),
                              ],
                            ),
                          ),
                        ),
                      if (others.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < others.length; i++) ...[
                                if (i > 0) Container(height: 0.5, margin: const EdgeInsets.only(left: 68), color: line),
                                InkWell(
                                  onTap: () => open(others[i]),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            PodcastArt(url: others[i].art, title: others[i].title, size: 44, radius: 10),
                                            // 새 회차가 있으면 빨간 점 (팟캐스트 탭 '구독 중'과 같게)
                                            if (pod.newOnes.contains(others[i].id))
                                              Positioned(
                                                top: -3,
                                                right: -3,
                                                child: Container(
                                                  width: 11,
                                                  height: 11,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFD84A3A),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: card, width: 2),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(others[i].title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
                                              if (others[i].author.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(others[i].author,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: sub, fontSize: 11.5)),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: sub.withOpacity(0.6), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
  }
}
'''
    print('✔ 구독 목록 창 · 회차 목록 열기')
else:
    print('✔ 구독 목록 창 · 회차 목록 열기 (이미 돼 있음)')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
