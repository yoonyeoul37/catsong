# -*- coding: utf-8 -*-
# 라디오 목록 채널 수: 앞서 시험한 모양(전체 N개 채널 줄 · 반투명 알약 · 흰 띠 안)은 지우고
# 사진 오른쪽 위 '● 102 채널' 하나만 남기기
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python fix_radio_count.py
import os, sys, json

PATH = 'lib/screens/radio_korea_screen2.dart'
S = json.loads(r"""{"SEP_OLD": "      separatorBuilder: (_, i) => i == 0\n          ? const SizedBox(height: 6)\n", "SEP_NEW": "      separatorBuilder: (_, i) => i == 0\n          // 맨 위 사진 카드 밑: 전체 채널 수 (곡 목록 '184곡' 줄과 같은 방식)\n          ? _DialEffect(\n              child: Padding(\n                padding: const EdgeInsets.only(top: 16, left: 2),\n                child: Text(\n                  '${tr.all} ${tr.channelsCount(koreanStationsSorted.length)}',\n                  style: TextStyle(color: baseC.withOpacity(0.55), fontSize: 13, fontWeight: FontWeight.w500),\n                ),\n              ),\n            )\n", "ANCHOR": "              // 사진 아래 크림 띠 (잠시 쉬어가요 카드와 같은 색)\n              Positioned(\n                left: 0,\n                right: 0,\n                bottom: 0,\n", "PILL": "              // 사진 오른쪽 위: 국내 전체 채널 수 (반투명 알약 + 라디오 아이콘)\n              Positioned(\n                top: 10,\n                right: 10,\n                child: Container(\n                  padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),\n                  decoration: BoxDecoration(\n                    color: Colors.black.withOpacity(0.32),\n                    borderRadius: BorderRadius.circular(20),\n                  ),\n                  child: Row(\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      const Icon(Icons.radio_rounded, color: Colors.white, size: 13),\n                      const SizedBox(width: 4),\n                      Text(\n                        '${koreanStations.length}',\n                        style: const TextStyle(\n                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n", "TOPRIGHT": "              // 사진 오른쪽 위: ● 102 채널 (홈 라디오 카드와 같은 모양, 사진 위라 흰 글자 + 옅은 그림자)\n              Positioned(\n                top: 10,\n                right: 12,\n                child: Builder(builder: (context) {\n                  final lang = Localizations.localeOf(context).languageCode;\n                  const shadow = [Shadow(color: Color(0x73000000), blurRadius: 4, offset: Offset(0, 1))];\n                  return Row(\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      Container(\n                        width: 6,\n                        height: 6,\n                        decoration: BoxDecoration(\n                          color: const Color(0xFFE5484D),\n                          shape: BoxShape.circle,\n                          boxShadow: [BoxShadow(color: const Color(0xFFE5484D).withOpacity(0.22), spreadRadius: 2.5)],\n                        ),\n                      ),\n                      const SizedBox(width: 6),\n                      Text('${koreanStations.length}',\n                          textScaler: TextScaler.noScaling,\n                          style: GoogleFonts.quicksand(\n                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, shadows: shadow)),\n                      // 단위는 홈과 같게: 한국어 '채널' · 일본어 '局', 나머지는 숫자만\n                      if (lang == 'ko' || lang == 'ja') ...[\n                        const SizedBox(width: 2),\n                        Text(lang == 'ja' ? '局' : '채널',\n                            textScaler: TextScaler.noScaling,\n                            style: TextStyle(\n                                color: Colors.white.withOpacity(0.9),\n                                fontSize: 10.5,\n                                fontWeight: FontWeight.w700,\n                                shadows: shadow)),\n                      ],\n                    ],\n                  );\n                }),\n              ),\n", "BAND_OLD": "                            Text(diceI >= 0 ? tr.heroDicePick : tr.niceNow,\n                                textScaler: TextScaler.noScaling,\n                                style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),\n", "BAND_NEW": "                            // 첫 줄: '지금 듣기 좋은' + 오른쪽 끝에 ● 102 채널 (홈 라디오 카드와 똑같이)\n                            Row(\n                              children: [\n                                Expanded(\n                                  child: Text(diceI >= 0 ? tr.heroDicePick : tr.niceNow,\n                                      maxLines: 1,\n                                      overflow: TextOverflow.ellipsis,\n                                      textScaler: TextScaler.noScaling,\n                                      style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),\n                                ),\n                                Container(\n                                  width: 6,\n                                  height: 6,\n                                  decoration: BoxDecoration(\n                                    color: const Color(0xFFE5484D),\n                                    shape: BoxShape.circle,\n                                    boxShadow: [BoxShadow(color: const Color(0xFFE5484D).withOpacity(0.22), spreadRadius: 2.5)],\n                                  ),\n                                ),\n                                const SizedBox(width: 6),\n                                Text('${koreanStations.length}',\n                                    textScaler: TextScaler.noScaling,\n                                    style: GoogleFonts.quicksand(\n                                        color: ink.withOpacity(0.78), fontSize: 12, fontWeight: FontWeight.w700)),\n                                // 단위는 홈과 같게: 한국어 '채널' · 일본어 '局', 나머지는 숫자만\n                                if (const ['ko', 'ja'].contains(Localizations.localeOf(context).languageCode)) ...[\n                                  const SizedBox(width: 2),\n                                  Text(Localizations.localeOf(context).languageCode == 'ja' ? '局' : '채널',\n                                      textScaler: TextScaler.noScaling,\n                                      style: TextStyle(color: ink.withOpacity(0.6), fontSize: 10.5, fontWeight: FontWeight.w700)),\n                                ],\n                                const SizedBox(width: 4),\n                              ],\n                            ),\n"}""")

def main():
    if not os.path.exists(PATH):
        print('❌ 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    done = []
    if S['SEP_NEW'] in s:
        s = s.replace(S['SEP_NEW'], S['SEP_OLD']); done.append('목록 위 "전체 N개 채널" 줄 지움')
    while S['PILL'] in s:
        s = s.replace(S['PILL'], '', 1); done.append('사진 위 반투명 알약 지움')
    if S['BAND_NEW'] in s:
        s = s.replace(S['BAND_NEW'], S['BAND_OLD']); done.append('흰 띠 안 ● 채널 지움 (원래 글자로)')
    n = s.count(S['TOPRIGHT'])
    if n == 0:
        if s.count(S['ANCHOR']) != 1:
            print('❌ 사진 아래 크림 띠 자리를 못 찾았어요. 아무것도 저장하지 않았어요.'); sys.exit(1)
        s = s.replace(S['ANCHOR'], S['TOPRIGHT'] + S['ANCHOR']); done.append('사진 오른쪽 위 ● 채널 넣음')
    elif n > 1:
        s = s.replace(S['TOPRIGHT'], '', n - 1); done.append(f'사진 오른쪽 위 ● 채널 겹친 것 {n - 1}개 지움')
    # 손으로 조금 바꿔서 위에서 못 잡은 게 남았는지 확인
    left = [m for m in ('반투명 알약 + 라디오 아이콘', "전체 채널 수 (곡 목록 '184곡'", "첫 줄: '지금 듣기 좋은' + 오른쪽 끝에") if m in s]
    if left:
        print('❌ 예전 모양이 조금 바뀐 채로 남아 있어서 자동으로 못 지웠어요:', ', '.join(left))
        print('   아무것도 저장하지 않았어요. radio_korea_screen2.dart 파일을 보내 주세요.'); sys.exit(1)
    if not done:
        print('이미 적용돼 있어요'); return
    for d in done: print('✔ radio_korea_screen2.dart -', d)
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('\n완료! 채널 수는 사진 오른쪽 위 하나만 남았어요.')

if __name__ == '__main__':
    main()
