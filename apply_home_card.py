# -*- coding: utf-8 -*-
# 홈 4번: 정리할 곡이 없을 때도 검정 카드 (오늘의 한 곡 / 시간대 추천 / 기능 알려주기)
# + 카드 ✕ (오늘만 숨김, 연달아 3일 닫으면 끌지 한 번 물어봄)
# + 설정 > 꾸미기 "홈 추천 카드" 스위치
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HOME = os.path.join(ROOT, 'lib', 'screens', 'home_screen.dart')
SET = os.path.join(ROOT, 'lib', 'screens', 'settings_screen.dart')
PREF = os.path.join(ROOT, 'lib', 'utils', 'home_card_pref.dart')

PREF_CODE = r'''import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 홈 곡 목록 맨 위 "오늘의 카드" 설정 (홈 화면과 설정 화면이 같이 씀)
class HomeCardPref {
  static final on = ValueNotifier<bool>(true); // 설정 스위치
  static final hiddenToday = ValueNotifier<bool>(false); // 오늘 ✕로 닫았는지
  static bool _loaded = false;

  static String _day(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    on.value = p.getBool('homeCardOn') ?? true;
    hiddenToday.value = p.getString('homeCardHiddenDay') == _day(DateTime.now());
  }

  static Future<void> setOn(bool v) async {
    on.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('homeCardOn', v);
    if (v) {
      hiddenToday.value = false;
      await p.remove('homeCardHiddenDay');
    }
  }

  /// 오늘만 닫기. 사흘 연달아 닫았으면 true (아예 끌지 한 번만 물어보기)
  static Future<bool> closeToday() async {
    hiddenToday.value = true;
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final yesterday = _day(now.subtract(const Duration(days: 1)));
    final last = p.getString('homeCardHiddenDay');
    final streak = last == yesterday ? (p.getInt('homeCardCloseStreak') ?? 0) + 1 : 1;
    await p.setString('homeCardHiddenDay', _day(now));
    await p.setInt('homeCardCloseStreak', streak);
    if (streak >= 3 && !(p.getBool('homeCardAskedOff') ?? false)) {
      await p.setBool('homeCardAskedOff', true);
      return true;
    }
    return false;
  }
}
'''

DAILY_CODE = r'''
  // ───── 정리할 곡이 없을 때: 하루에 하나씩 바뀌는 "오늘의 카드" ─────
  Widget _buildTopCard(MusicProvider music, bool isDark) {
    final clean = _buildCleanHint(music, isDark);
    if (clean is! SizedBox) return clean; // 정리할 곡이 있으면 정리 카드가 먼저
    if (music.metaLoading || _showFavorites || _showRecent || _isSelectionMode) return clean;
    HomeCardPref.load();
    return ValueListenableBuilder<bool>(
      valueListenable: HomeCardPref.on,
      builder: (context, on, _) => !on
          ? const SizedBox.shrink()
          : ValueListenableBuilder<bool>(
              valueListenable: HomeCardPref.hiddenToday,
              builder: (context, hidden, _) =>
                  hidden ? const SizedBox.shrink() : _buildDailyCard(music, isDark),
            ),
    );
  }

  Widget _buildDailyCard(MusicProvider music, bool isDark) {
    final card = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final ink = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final sub = isDark ? const Color(0xFF8A8378) : const Color(0xFFA29A8B);
    final circle = isDark ? const Color(0xFFE4DCCD) : const Color(0xFF2A251D);

    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024, 1, 1)).inDays;
    final songs = music.songs.where((s) => !music.isCallRecordingPath(s.uri)).toList();
    var kind = day % 3; // 날짜 따라 순서대로 (같은 날은 같은 카드)
    if (kind == 0 && songs.isEmpty) kind = 1;

    late IconData icon;
    late String title;
    late Widget subLine;
    String? action;
    VoidCallback? onAction;

    if (kind == 0) {
      // ① 오늘의 한 곡 (같은 날은 같은 곡)
      final i = math.Random(day).nextInt(songs.length);
      final s = songs[i];
      icon = Icons.album_outlined;
      title = '오늘은 이 곡 어때요';
      subLine = Text.rich(
        TextSpan(children: [
          TextSpan(text: s.titleDisplay, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
          TextSpan(text: '  ·  ${s.artistDisplay}'),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: sub, fontSize: 11.5),
      );
      action = '듣기';
      onAction = () => context.read<PlayerProvider>().playFromList(songs, i);
    } else if (kind == 1) {
      // ② 시간대 추천 (자연소리)
      final h = now.hour;
      final (IconData ic, String t, String sound, String line) = h >= 5 && h < 11
          ? (Icons.wb_sunny_outlined, '상쾌한 아침이에요', '새소리', '새소리로 하루를 시작해요')
          : h >= 11 && h < 17
              ? (Icons.local_cafe_outlined, '잠깐 쉬어가요', '시냇물', '시냇물 소리 들으며 한숨 돌려요')
              : h >= 17 && h < 21
                  ? (Icons.waves_rounded, '오늘도 수고했어요', '파도소리', '파도소리 틀어놓고 쉬어요')
                  : (Icons.bedtime_outlined, '늦은 밤엔 잔잔하게', '빗소리', '빗소리 틀어놓고 쉬어요');
      icon = ic;
      title = t;
      subLine = Text(line,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
      final found = PlayerProvider.natureSoundOrder.where((e) => e['name'] == sound);
      if (found.isNotEmpty) {
        action = '듣기';
        final url = found.first['assetPath']!;
        onAction = () => context.read<PlayerProvider>().playNatureSound(url, sound);
      }
    } else {
      // ③ 기능 알려주기 (돌아올 때마다 다른 팁)
      const tips = <(IconData, String, String)>[
        (Icons.notifications_active_outlined, '좋아하는 곡을 벨소리로', '곡 ⋮ 메뉴에서 벨소리·알림음으로 만들 수 있어요'),
        (Icons.movie_outlined, '동영상에서 음악만 저장', '동영상 ⋮ 메뉴 → 음악으로 저장'),
        (Icons.battery_charging_full_rounded, '화면 꺼도 음악이 안 끊기게', '앱 정보 → 배터리 → 제한 없음'),
        (Icons.water_drop_outlined, '음악에 빗소리 섞기', '재생화면 ⋮ 메뉴 → 자연소리 섞기'),
        (Icons.format_quote_rounded, '가사 한 줄 공유', '가사를 꾹 누르면 카드로 보낼 수 있어요'),
      ];
      final tip = tips[(day ~/ 3) % tips.length];
      icon = tip.$1;
      title = tip.$2;
      subLine = Text(tip.$3,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                subLine,
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                onAction?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
                child: Text(action, style: TextStyle(color: card, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          // ✕ = 오늘만 숨기기
          IconButton(
            onPressed: _closeDailyCard,
            icon: Icon(Icons.close_rounded, color: sub, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }

  Future<void> _closeDailyCard() async {
    final ask = await HomeCardPref.closeToday();
    if (!ask || !mounted) return;
    final off = await showParanConfirm(
      context,
      title: '오늘의 카드를 끌까요?',
      message: '설정 → 홈 추천 카드에서 언제든 다시 켤 수 있어요',
      confirmLabel: '끄기',
      cancelLabel: '계속 볼래요',
    );
    if (off) HomeCardPref.setOn(false);
  }

  Widget _buildSongsTab() {'''

HOME_EDITS = [
    ('홈: 설정 파일 연결',
     "import '../widgets/paran_dialog.dart';\n",
     "import '../widgets/paran_dialog.dart';\n"
     "import '../utils/home_card_pref.dart';\n"),
    ('홈: 맨 위 카드 자리',
     "            _buildCleanHint(musicProvider, isDarkMode), // 정리할 곡이 있으면 알려주기\n",
     "            _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드\n"),
    ('홈: 오늘의 카드 만들기',
     "\n  Widget _buildSongsTab() {",
     DAILY_CODE),
]

SET_EDITS = [
    ('설정: 파일 연결',
     "import 'player_screen.dart' show showPlayerStyleMenu;\n",
     "import 'player_screen.dart' show showPlayerStyleMenu;\n"
     "import '../utils/home_card_pref.dart';\n"),
    ('설정: 처음에 값 읽기',
     "  bool _isSosOn = false;\n\n  @override\n  void dispose() {",
     "  bool _isSosOn = false;\n\n"
     "  @override\n"
     "  void initState() {\n"
     "    super.initState();\n"
     "    HomeCardPref.load();\n"
     "  }\n\n"
     "  @override\n  void dispose() {"),
    ('설정: 꾸미기에 "홈 추천 카드" 스위치',
     "          _buildTile(context, icon: Icons.text_fields, title: l.textSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor, isLast: true),\n",
     "          _buildTile(context, icon: Icons.text_fields, title: l.textSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor),\n"
     "          ValueListenableBuilder<bool>(\n"
     "            valueListenable: HomeCardPref.on,\n"
     "            builder: (context, on, _) => _buildTile(context,\n"
     "                icon: Icons.view_agenda_outlined,\n"
     "                title: '홈 추천 카드',\n"
     "                onTap: () => HomeCardPref.setOn(!on),\n"
     "                primaryColor: primaryColor,\n"
     "                isLast: true,\n"
     "                trailing: Switch(value: on, onChanged: (v) => HomeCardPref.setOn(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),\n"
     "          ),\n"),
]

MARK = '_buildTopCard'


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


def apply(path, edits, results):
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
    if before and not balanced(text):
        print('❌ 괄호가 안 맞아요:', os.path.basename(path))
        ok = False
    results.append((path, text.replace('\n', '\r\n') if crlf else text))
    return ok


def main():
    for p in (HOME, SET):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(HOME, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    results = []
    ok = apply(HOME, HOME_EDITS, results)
    ok = apply(SET, SET_EDITS, results) and ok
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in results:
        open(path, 'wb').write(text.encode('utf-8'))
    if not os.path.exists(PREF):
        open(PREF, 'wb').write(PREF_CODE.replace('\n', '\r\n').encode('utf-8'))
        print('✔ 새 파일 만듦: lib/utils/home_card_pref.dart')
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
