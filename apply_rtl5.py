# -*- coding: utf-8 -*-
# 아랍어·우르두어 화면 뒤집기 고침 (apply_rtl1~4.py 내용도 다 들어 있어요 — 이것만 돌리면 돼요)
#  라디오 재생 화면(한국·해외): ⏮ ▶ ⏭ 버튼 순서는 왼쪽→오른쪽 그대로
#  자연소리: 목록 줄 구분선, 재생 화면 ⏮ ▶ ⏭ 순서, 믹스 화면 소리 이름이 % 옆에 붙던 것
#  한국 라디오: 주파수 눈금(88~108)과 숫자 방향, '97.1 MHz' 순서, 방송 시간 '16:05 ~ 18:00' 순서
#  설정: 줄 구분선 · 포인트 색 줄
#  ⋮ 메뉴: 줄 구분선 · 오른쪽 화살표 > 방향
#  음악 목록: '새로 들어온 곡'·초성 머리글이 왼쪽에 붙던 것
#  재생 화면: 'ParanSori' 글자가 'SoriParan'으로 뒤집히던 것, 재생 막대·이전/다음 버튼은 왼쪽→오른쪽 그대로
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)
S = os.path.join('lib', 'screens'); W = os.path.join('lib', 'widgets')
CH_OLD = "_LineIcon(_kIconChevron, size: 18, color: {c}, stroke: 2.0),"
CH_NEW = ("Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, // 아랍어에선 < 방향\n"
          "                  child: _LineIcon(_kIconChevron, size: 18, color: {c}, stroke: 2.0)),")
# (이름, 찾을, 바꿀, 몇 곳)
jobs = {
 os.path.join(S, 'settings_screen.dart'): [
  ("설정 줄 구분선", "margin: const EdgeInsets.only(left: 58), color: _sBorder(isDarkMode))",
   "margin: const EdgeInsetsDirectional.only(start: 58), color: _sBorder(isDarkMode))", 1),
  ("포인트 색 줄", "          Padding(\n            padding: const EdgeInsets.only(left: 42),\n            child: Row(",
   "          Padding(\n            padding: const EdgeInsetsDirectional.only(start: 42),\n            child: Row(", 1),
 ],
 os.path.join(W, 'paran_dialog.dart'): [
  ("카드 안 줄 구분선", "margin: const EdgeInsets.only(left: 46), color: p.line)",
   "margin: const EdgeInsetsDirectional.only(start: 46), color: p.line)", 1),
 ],
 os.path.join(W, 'more_menu_sheet.dart'): [
  ("⋮ 메뉴 줄 구분선", "margin: const EdgeInsets.only(left: 60), color: line)",
   "margin: const EdgeInsetsDirectional.only(start: 60), color: line)", 1),
  ("⋮ 메뉴 화살표", CH_OLD.format(c='p.chevron'), CH_NEW.format(c='p.chevron'), 1),
  ("⋮ 메뉴 화살표 (소개 줄)", CH_OLD.format(c='point.withOpacity(0.85)'), CH_NEW.format(c='point.withOpacity(0.85)'), 1),
 ],
 os.path.join(W, 'menu_parts.dart'): [
  ("메뉴 카드 줄 구분선", "margin: const EdgeInsets.only(left: 48), color: line)",
   "margin: const EdgeInsetsDirectional.only(start: 48), color: line)", 1),
 ],
 os.path.join(S, 'home_screen.dart'): [
  ("목록 머리글 여백", "EdgeInsets.fromLTRB(22, 14, 12, 2)", "EdgeInsetsDirectional.fromSTEB(22, 14, 12, 2)", 2),
  ("목록 머리글 자리", "alignment: Alignment.bottomLeft,", "alignment: AlignmentDirectional.bottomStart,", 4),
 ],
 os.path.join(S, 'player_screen.dart'): [
  ("ParanSori 글자 순서",
   "                    Row(\n                      mainAxisSize: MainAxisSize.min,\n                      children: [\n                        // \"파란\"만 숨쉬기",
   "                    Row(\n                      textDirection: TextDirection.ltr, // 아랍어에서도 Paran + Sori 순서\n                      mainAxisSize: MainAxisSize.min,\n                      children: [\n                        // \"파란\"만 숨쉬기", 1),
  ("재생 막대 방향",
   "          const SizedBox(height: 8),\n          TweenAnimationBuilder<double>(\n            // 잡고 있을 때만 1.4배",
   "          const SizedBox(height: 8),\n          Directionality(textDirection: TextDirection.ltr, // 재생 막대는 아랍어에서도 왼쪽→오른쪽\n          child: TweenAnimationBuilder<double>(\n            // 잡고 있을 때만 1.4배", 1),
  ("재생 막대 닫기 + 시간 줄",
   "          ),\n          ),\n          Row(\n            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n            children: [\n              Text(playerProvider.formatDuration(playerProvider.position),",
   "          ),\n          ),\n          ),\n          Row(\n            textDirection: TextDirection.ltr,\n            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n            children: [\n              Text(playerProvider.formatDuration(playerProvider.position),", 1),
  ("이전·재생·다음 버튼 순서",
   "          Row(\n            mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n            children: [\n              IconButton(\n                onPressed: () {\n                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                  playerProvider.playPrevious();",
   "          Row(\n            textDirection: TextDirection.ltr, // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n            mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n            children: [\n              IconButton(\n                onPressed: () {\n                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                  playerProvider.playPrevious();", 1),
 ],
 os.path.join(W, 'overseas_radio_view.dart'): [
  ("해외 라디오 재생 버튼 순서",
   "                            // 아래 조작 버튼\n                            Row(\n                              mainAxisAlignment: MainAxisAlignment.spaceBetween,",
   "                            // 아래 조작 버튼\n                            Row(\n                              textDirection: TextDirection.ltr, // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n                              mainAxisAlignment: MainAxisAlignment.spaceBetween,", 1),
 ],
 os.path.join(S, 'radio_player_screen.dart'): [
  ("한국 라디오 재생 버튼 순서",
   "    return Row(\n      mainAxisAlignment: MainAxisAlignment.center,\n      children: [\n        // 이전",
   "    return Row(\n      textDirection: TextDirection.ltr, // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n      mainAxisAlignment: MainAxisAlignment.center,\n      children: [\n        // 이전", 1),
 ],
 os.path.join(S, 'nature_sounds_screen.dart'): [
  ("자연 목록 줄 구분선", "margin: const EdgeInsets.only(left: 78, right: 12),",
   "margin: const EdgeInsetsDirectional.only(start: 78, end: 12),", 1),
 ],
 os.path.join(S, 'nature_sound_detail_screen.dart'): [
  ("자연 재생 버튼 순서",
   "                    child: Row(\n                      mainAxisAlignment: MainAxisAlignment.spaceAround,\n                      children: [\n                        GestureDetector(\n                          behavior: HitTestBehavior.opaque, // 아이콘 주변 빈 곳도 눌리게",
   "                    child: Row(\n                      textDirection: TextDirection.ltr, // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n                      mainAxisAlignment: MainAxisAlignment.spaceAround,\n                      children: [\n                        GestureDetector(\n                          behavior: HitTestBehavior.opaque, // 아이콘 주변 빈 곳도 눌리게", 1),
 ],
 os.path.join(S, 'sound_mix_screen.dart'): [
  ("믹스 소리 이름 자리",
   "                child: Align(\n                  alignment: Alignment.centerLeft,\n                  child: GestureDetector(\n                    behavior: HitTestBehavior.opaque,\n                    onTap: onLabelTap,",
   "                child: Align(\n                  alignment: AlignmentDirectional.centerStart, // 아랍어에선 오른쪽(아이콘 옆)\n                  child: GestureDetector(\n                    behavior: HitTestBehavior.opaque,\n                    onTap: onLabelTap,", 1),
 ],
 os.path.join(W, 'frequency_ruler.dart'): [
  ("주파수 눈금 방향 (열기)",
   "    return Column(\n      children: [\n        SizedBox(\n          height: 34,",
   "    // 주파수 눈금은 아랍어에서도 88(왼쪽) → 108(오른쪽)\n    return Directionality(textDirection: TextDirection.ltr, child: Column(\n      children: [\n        SizedBox(\n          height: 34,", 1),
  ("주파수 눈금 방향 (닫기)",
   "      ],\n    );\n  }\n}\n\nclass _TickPainter",
   "      ],\n    ));\n  }\n}\n\nclass _TickPainter", 1),
 ],
 os.path.join(S, 'radio_korea_screen2.dart'): [
  ("목록 주파수 MHz 순서",
   "                              key: const ValueKey('freq'),\n                              maxLines: 1,",
   "                              key: const ValueKey('freq'),\n                              textDirection: TextDirection.ltr, // 97.1 MHz 순서 그대로\n                              maxLines: 1,", 1),
 ],
 os.path.join(S, 'radio_player_screen.dart') + '#2': [
  ("방송 시간 순서 (KBS)",
   "return '${radioProvider.formatScheduleTime(kbsStart)} ~ ${radioProvider.formatScheduleTime(kbsEnd)}';",
   "return '\\u2066${radioProvider.formatScheduleTime(kbsStart)} ~ ${radioProvider.formatScheduleTime(kbsEnd)}\\u2069'; // 아랍어에서도 시작 ~ 끝 순서", 1),
  ("방송 시간 순서 (MBC)", "return '${fmt(mbcStart)} ~ ${fmt(mbcEnd)}';", "return '\\u2066${fmt(mbcStart)} ~ ${fmt(mbcEnd)}\\u2069';", 1),
  ("방송 시간 순서 (SBS)", "return '$sbsStart ~ $sbsEnd';", "return '\\u2066$sbsStart ~ $sbsEnd\\u2069';", 1),
  ("편성표 지금 방송 시간 순서", "Text('${_hm(cur.start)} – ${_hm(cur.end)} · ", "Text('\\u2066${_hm(cur.start)} – ${_hm(cur.end)}\\u2069 · ", 1),
 ],
}
out = {}
merged = {}
for k, v in jobs.items(): merged.setdefault(k.split('#')[0], []).extend(v)
for p, eds in merged.items():
    if not os.path.exists(p): fail('파일을 못 찾았어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
    for name, old, new, cnt in eds:
        n = s.count(old)
        if n == 0 and s.count(new) >= cnt:
            print('✔', os.path.basename(p), '·', name, '(이미 돼 있어요)'); continue
        if n != cnt: fail(f'{os.path.basename(p)} · {name} — 찾을 코드가 {cnt}곳이어야 하는데 {n}곳이에요')
        s = s.replace(old, new); print('✔', os.path.basename(p), '·', name)
    for a, b in ['()', '[]', '{}']:
        if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 짝이 안 맞아요')
    if s != o: out[p] = s.replace('\n', '\r\n') if crlf else s
if not out: print('이미 적용돼 있어요'); sys.exit(0)
for p, s in out.items(): open(p, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
