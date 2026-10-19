# -*- coding: utf-8 -*-
# 아랍어·우르두어 화면 뒤집기 고침 (apply_rtl1~8.py 내용도 다 들어 있어요 — 이것만 돌리면 돼요)
#  [6차] 아래 미니 플레이어(음악·라디오·자연): ⏮ ▶ ⏭ 순서, 음악 시간 '0:02 / 3:52' 순서
#  [6차] 소개 화면: 뒤로 버튼 자리, '파란 + 소리' 순서, 'Paransori.' 점 위치, 이름 설명 글의 (파란)·(소리) 괄호
#  [6차] 음악 검색: '취소' 글자가 화면 밖으로 잘리던 것
#  [9차] 한국 라디오 '최근' 탭: '오늘/어제'가 한국어로 나오던 것, 나라 이름이 영어(Saudi Arabia)로 나오던 것, '!Dance Wave'처럼 느낌표가 앞에 붙던 것
#  [8차] 재생목록·최근 탭: 제목이 오른쪽 끝에 딱 붙던 것 (여백 맞춤)
#  [8차] 재생목록 줄: '0أغنية' → '0 أغنية' (영어 '0songs'도 '0 songs'로)
#  [7차] 수면 타이머 등 시간 고르는 휠: '분' 글자가 숫자와 겹치던 것 (휠은 왼쪽 시·오른쪽 분 그대로)
#  [7차] 벨소리 만들기·영상 자르기: 시작/끝 막대와 시간 칩도 왼쪽=0초로 (재생 화면 막대와 같게)
#  [7차] 우르두어 알람 안내: 'PM 7:00' → '7:00 PM'
#  [6차] 라디오 나라 목록: '115채널' → '115 채널'처럼 숫자 뒤 띄어쓰기 (한·중·일은 그대로 붙임)
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
 os.path.join(W, 'mini_player.dart'): [
  ("음악 미니 ⏮▶⏭ 순서 (열기)",
   "                        ),\n                        // 이전 버튼 (녹음이면 10초 뒤로)\n",
   "                        ),\n                        Row(textDirection: TextDirection.ltr, mainAxisSize: MainAxisSize.min, children: [ // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n                        // 이전 버튼 (녹음이면 10초 뒤로)\n", 1),
  ("음악 미니 ⏮▶⏭ 순서 (닫기)",
   "                              minWidth: 36, minHeight: 36),\n                        ),\n                        // 녹음이면 배속",
   "                              minWidth: 36, minHeight: 36),\n                        ),\n                        ]),\n                        // 녹음이면 배속", 1),
  ("음악 미니 시간 순서",
   "'${playerProvider.formatDuration(playerProvider.position)} / ${playerProvider.formatDuration(playerProvider.duration)}',",
   "'\\u2066${playerProvider.formatDuration(playerProvider.position)} / ${playerProvider.formatDuration(playerProvider.duration)}\\u2069',", 1),
 ],
 os.path.join(W, 'radio_mini_player.dart'): [
  ("라디오 미니 ⏮▶⏭ 순서 (열기)",
   "                        ),\n                        // 이전 방송 (음악 미니플레이어와 같은 모양)\n",
   "                        ),\n                        Row(textDirection: TextDirection.ltr, mainAxisSize: MainAxisSize.min, children: [ // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n                        // 이전 방송 (음악 미니플레이어와 같은 모양)\n", 1),
  ("라디오 미니 ⏮▶⏭ 순서 (닫기)",
   "                            onPressed: () => step(1),\n                            icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),\n                            iconSize: 26,\n                            padding: const EdgeInsets.all(4),\n                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),\n                          ),\n                      ],",
   "                            onPressed: () => step(1),\n                            icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),\n                            iconSize: 26,\n                            padding: const EdgeInsets.all(4),\n                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),\n                          ),\n                        ]),\n                      ],", 1),
 ],
 os.path.join(W, 'nature_mini_player.dart'): [
  ("자연 미니 ⏮▶⏭ 순서 (열기)",
   "                  ),\n                  // 이전 자연소리 (음악 미니플레이어와 같은 모양)\n",
   "                  ),\n                  Row(textDirection: TextDirection.ltr, mainAxisSize: MainAxisSize.min, children: [ // ⏮ ▶ ⏭ 순서는 어느 언어나 같게\n                  // 이전 자연소리 (음악 미니플레이어와 같은 모양)\n", 1),
  ("자연 미니 ⏮▶⏭ 순서 (닫기)",
   "                    onPressed: () => step(1),\n                    icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),\n                    iconSize: 26,\n                    padding: const EdgeInsets.all(4),\n                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),\n                  ),\n                ],",
   "                    onPressed: () => step(1),\n                    icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),\n                    iconSize: 26,\n                    padding: const EdgeInsets.all(4),\n                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),\n                  ),\n                  ]),\n                ],", 1),
 ],
 os.path.join(S, 'paran_intro_screen.dart'): [
  ("소개 뒤로 버튼 자리",
   "            Positioned(\n              left: 12,\n              top: top + 8,",
   "            PositionedDirectional(\n              start: 12, // 아랍어에선 오른쪽 위\n              top: top + 8,", 1),
  ("소개 '파란 + 소리' 순서",
   "    return Row(\n      mainAxisAlignment: MainAxisAlignment.center,\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: [\n        part('파란'",
   "    return Row(\n      textDirection: TextDirection.ltr, // 아랍어에서도 파란 + 소리 순서\n      mainAxisAlignment: MainAxisAlignment.center,\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: [\n        part('파란'", 1),
  ("소개 'Paransori.' 점 위치",
   "                            Text(t.sign,\n                                style:",
   "                            Text(t.sign,\n                                textDirection: TextDirection.ltr, // 아랍어에서도 Paransori. (점이 뒤)\n                                style:", 1),
 ],
 os.path.join(S, 'home_screen.dart') + '#2': [
  ("음악 검색 '취소' 잘림",
   "          Transform.translate(\n            offset: const Offset(-12, 0),\n            child: TextButton(",
   "          Transform.translate(\n            offset: Offset(Directionality.of(context) == TextDirection.rtl ? 12 : -12, 0), // 아랍어에선 반대쪽으로\n            child: TextButton(", 1),
 ],
 os.path.join(S, 'radio_home_screen.dart'): [
  ("나라 카드 채널 수 (한국)", "count = '${koreanStations.length}${l.radioChannelCount}';", "count = chCountText(koreanStations.length, l);", 1),
  ("나라 카드 채널 수", "count = n != null ? '$n${l.radioChannelCount}' : l.radioPopular200;", "count = n != null ? chCountText(n, l) : l.radioPopular200;", 1),
  ("나라 목록 채널 수 (한국)", "'${koreanStations.length}${AppLocalizations.of(context)!.radioChannelCount}',", "chCountText(koreanStations.length, AppLocalizations.of(context)!),", 1),
  ("나라 목록 채널 수", "? '$count${AppLocalizations.of(context)!.radioChannelCount}'", "? chCountText(count, AppLocalizations.of(context)!)", 1),
  ("채널 수 띄어쓰기 함수",
   "  'AU': 'Australia', 'NZ': 'New Zealand', 'FJ': 'Fiji', 'PG': 'Papua New Guinea',\n};\n",
   "  'AU': 'Australia', 'NZ': 'New Zealand', 'FJ': 'Fiji', 'PG': 'Papua New Guinea',\n};\n\n"
   "/// '115 channels' · '115 قناة' (숫자 뒤 띄어쓰기) — 한·중·일은 '115개 채널'·'115チャンネル'처럼 붙임\n"
   "String chCountText(Object n, AppLocalizations l) {\n"
   "  final s = l.radioChannelCount;\n"
   "  final tight = RegExp(r'^[\\u3040-\\u30ff\\u3400-\\u9fff\\uac00-\\ud7af]').hasMatch(s);\n"
   "  return tight ? '$n$s' : '$n $s';\n"
   "}\n", 1),
 ],
 os.path.join('lib', 'l10n', 'app_ar.arb'): [
  ("아랍어 소개 글 (파란) 괄호", '\\"paran\\" (파란)', '⁦\\"paran\\" (파란)⁩', 1),
  ("아랍어 소개 글 (소리) 괄호", '\\"sori\\" (소리)', '⁦\\"sori\\" (소리)⁩', 1),
 ],
 os.path.join('lib', 'l10n', 'app_ur.arb'): [
  ("우르두어 소개 글 (파란) 괄호", '\\"paran\\" (파란)', '⁦\\"paran\\" (파란)⁩', 1),
  ("우르두어 소개 글 (소리) 괄호", '\\"sori\\" (소리)', '⁦\\"sori\\" (소리)⁩', 1),
 ],
 os.path.join(S, 'player_screen.dart') + '#7': [
  ("수면 타이머 휠 (2곳)", '                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    ),\n', "                    child: Directionality(textDirection: TextDirection.ltr, // 아랍어에서 '분' 글자가 숫자와 겹쳐서 왼쪽→오른쪽으로\n                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    )),\n", 2),
 ],
 os.path.join(S, 'nature_sound_detail_screen.dart') + '#7': [
  ("자연 타이머 휠", '                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    ),\n', "                    child: Directionality(textDirection: TextDirection.ltr, // 아랍어에서 '분' 글자가 숫자와 겹쳐서 왼쪽→오른쪽으로\n                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    )),\n", 1),
 ],
 os.path.join(S, 'sound_mix_screen.dart') + '#7': [
  ("믹스 타이머 휠", '                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    ),\n', "                    child: Directionality(textDirection: TextDirection.ltr, // 아랍어에서 '분' 글자가 숫자와 겹쳐서 왼쪽→오른쪽으로\n                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    )),\n", 1),
 ],
 os.path.join(S, 'voice_recorder_screen.dart'): [
  ("녹음 타이머 휠", '                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    ),\n', "                    child: Directionality(textDirection: TextDirection.ltr, // 아랍어에서 '분' 글자가 숫자와 겹쳐서 왼쪽→오른쪽으로\n                    child: CupertinoTimerPicker(\n                      mode: CupertinoTimerPickerMode.hm,\n                      initialTimerDuration: picked,\n                      onTimerDurationChanged: (d) => picked = d,\n                    )),\n", 1),
 ],
 os.path.join(S, 'ringtone_screen.dart'): [
  ("벨소리 막대 방향 (열기)", '            Expanded(\n              child: SliderTheme(\n                data: sliderTheme,\n', '            Expanded(\n              child: Directionality(textDirection: TextDirection.ltr, // 막대는 아랍어에서도 왼쪽=0초\n              child: SliderTheme(\n                data: sliderTheme,\n',1),
  ("벨소리 막대 방향 (닫기)", '                ),\n              ),\n            ),\n            SizedBox(\n                width: 44,', '                ),\n              ),\n              ),\n            ),\n            SizedBox(\n                width: 44,',1),
  ("벨소리 시간 칩 순서", "                    Row(\n                      mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                      children: [\n                        timeChip(", "                    Row(\n                      textDirection: TextDirection.ltr, // 시작(왼쪽) ~ 끝(오른쪽)\n                      mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                      children: [\n                        timeChip(", 1),
 ],
 os.path.join(S, 'video_trim_screen.dart'): [
  ("영상 자르기 막대 방향 (열기)", '            Expanded(\n              child: SliderTheme(\n                data: sliderTheme,\n', '            Expanded(\n              child: Directionality(textDirection: TextDirection.ltr, // 막대는 아랍어에서도 왼쪽=0초\n              child: SliderTheme(\n                data: sliderTheme,\n',1),
  ("영상 자르기 막대 방향 (닫기)", '                ),\n              ),\n            ),\n            SizedBox(\n                width: 44,', '                ),\n              ),\n              ),\n            ),\n            SizedBox(\n                width: 44,',1),
  ("영상 자르기 시간 칩 순서", "                  Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    children: [\n                      timeChip(", "                  Row(\n                    textDirection: TextDirection.ltr, // 시작(왼쪽) ~ 끝(오른쪽)\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    children: [\n                      timeChip(", 1),
 ],
 os.path.join('lib', 'l10n', 'app_ur.arb') + '#7': [
  ("우르두어 시간 순서 (7:00 PM)", '"timeAmPm": "{time} {ampm}"', '"timeAmPm": "\u2066{time} {ampm}\u2069"', 1),
 ],
 os.path.join(S, 'playlist_screen.dart'): [
  ("재생목록 탭 제목 여백", "padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),", "padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 8),", 1),
  ("재생목록 곡 수 띄어쓰기",
   "Text('${AppLocalizations.of(context)!.playlistLabel} • ${playlist.songCount}${AppLocalizations.of(context)!.songCountSuffix}',",
   "Text('${AppLocalizations.of(context)!.playlistLabel} • ${AppLocalizations.of(context)!.songsCount(playlist.songCount)}',", 1),
 ],
 os.path.join(S, 'recent_screen.dart'): [
  ("최근 탭 제목 여백", "padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),", "padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 8),", 1),
 ],
 os.path.join(S, 'radio_korea_screen2.dart') + '#9': [
  ('라디오 나라 이름 불러오기', "import '../models/radio_station.dart';\n", "import '../models/radio_station.dart';\nimport '../models/radio_country.dart';\n", 1),
  ("최근 탭 '오늘'", "              ? '오늘'\n", '              ? AppLocalizations.of(context)!.today\n', 1),
  ("최근 탭 '어제'", "                  ? '어제'\n", '                  ? AppLocalizations.of(context)!.yesterday\n', 1),
  ('최근 탭 오늘/어제 칸에 맞추기 (열기)', '                      Text(\n                        dayStr,', "                      FittedBox(fit: BoxFit.scaleDown, child: Text( // 긴 말(Aujourd'hui 등)은 칸에 맞게 줄임\n                        dayStr,", 1),
  ('최근 탭 오늘/어제 칸에 맞추기 (닫기)', 'style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 10.5),\n                      ),\n', 'style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 10.5),\n                      )),\n', 1),
  ('최근 탭 나라 이름 번역', "final descStr = koreanStationDesc(station.name) ?? (station.country ?? '');", "final descStr = koreanStationDesc(station.name) ?? (() {\n          // 해외 방송은 나라 이름을 앱 언어로 (목록에 없는 나라는 원래 이름)\n          final cc = station.countryCode?.toUpperCase();\n          for (final c in RadioCountry.supported) {\n            if (c.code == cc) return c.displayName;\n          }\n          return station.country ?? '';\n        })();", 1),
  ('최근 탭 방송 이름 방향', '                      Text(\n                        station.name,\n                        style: TextStyle(\n                          color: isPlaying ? primaryColorOf(context) : baseColor,\n                          fontSize: 15.5,', "                      Text(\n                        '\\u2068${station.name}\\u2069', // 'Dance Wave!' 느낌표가 앞으로 가지 않게\n                        style: TextStyle(\n                          color: isPlaying ? primaryColorOf(context) : baseColor,\n                          fontSize: 15.5,", 1),
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
        if s.count(new) >= cnt:
            print('✔', os.path.basename(p), '·', name, '(이미 돼 있어요)'); continue
        if n != cnt: fail(f'{os.path.basename(p)} · {name} — 찾을 코드가 {cnt}곳이어야 하는데 {n}곳이에요')
        s = s.replace(old, new); print('✔', os.path.basename(p), '·', name)
    for a, b in ['()', '[]', '{}']:
        if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 짝이 안 맞아요')
    if s != o: out[p] = s.replace('\n', '\r\n') if crlf else s
if not out: print('이미 적용돼 있어요'); sys.exit(0)
for p, s in out.items(): open(p, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
