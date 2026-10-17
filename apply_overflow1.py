# -*- coding: utf-8 -*-
# 글자 넘침 고치기 1: 아래 탭 이름 · 위 탭(전체·즐겨찾기·최근) · 재생화면 ⋮ 메뉴 스타일 썸네일 이름
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python apply_overflow1.py
import os, sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
FILES = {'home': 'lib/screens/home_screen.dart', 'player': 'lib/screens/player_screen.dart'}
E = json.loads('[["home", "아래 탭 이름: 한 줄로, 길면 살짝 작게 (글자 크기 최대여도 안 넘치게)", "                      Text(\\n                        items[index][\'label\'] as String,\\n                        style: TextStyle(\\n                          color: isSelected ? baseColor : baseColor.withOpacity(0.6),\\n                          fontSize: 10,\\n                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,\\n                        ),\\n                      ),\\n", "                      // 한 줄로만 · 칸보다 길면 살짝 작게 · 글자 크기 설정은 1.2배까지만 (아래 칸 높이가 정해져 있어서)\\n                      Padding(\\n                        padding: const EdgeInsets.symmetric(horizontal: 2),\\n                        child: FittedBox(\\n                          fit: BoxFit.scaleDown,\\n                          child: Text(\\n                            items[index][\'label\'] as String,\\n                            maxLines: 1,\\n                            textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),\\n                            style: TextStyle(\\n                              color: isSelected ? baseColor : baseColor.withOpacity(0.6),\\n                              fontSize: 10,\\n                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,\\n                            ),\\n                          ),\\n                        ),\\n                      ),\\n"], ["home", "위 탭(전체·즐겨찾기·최근): 길면 옆으로 밀어 보기", "            Padding(\\n              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),\\n              child: Row(\\n                children: [\\n                  _buildFilterTab(\\n                    AppLocalizations.of(context)!.all,\\n", "            Padding(\\n              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),\\n              child: Row(\\n                children: [\\n                  // 탭이 길면(긴 언어·큰 글자) 옆으로 밀어 보기 — 통화녹음 칩은 오른쪽 끝 그대로\\n                  Expanded(\\n                    child: SingleChildScrollView(\\n                      scrollDirection: Axis.horizontal,\\n                      child: Row(\\n                        children: [\\n                  _buildFilterTab(\\n                    AppLocalizations.of(context)!.all,\\n"], ["home", "위 탭 닫기 + 통화녹음 칩 자리", "                    Theme.of(context).colorScheme.primary,\\n                  ),\\n                  // 녹음 (일반 음악과 따로) — 아이폰은 다른 앱 파일을 못 읽어서 안드로이드만\\n                  if (Platform.isAndroid) const Spacer(), // 통화녹음은 오른쪽 끝으로\\n", "                    Theme.of(context).colorScheme.primary,\\n                  ),\\n                        ],\\n                      ),\\n                    ),\\n                  ),\\n                  // 녹음 (일반 음악과 따로) — 아이폰은 다른 앱 파일을 못 읽어서 안드로이드만\\n                  if (Platform.isAndroid) const SizedBox(width: 10), // 통화녹음은 오른쪽 끝으로\\n"], ["player", "재생화면 스타일 썸네일 이름: 사진 폭 안에서 한 줄로 (메뉴 글자가 안 밀리게)", "            Text(label,\\n                style: TextStyle(\\n                  color: sel ? _sheetBlue : _sheetSub,\\n                  fontSize: 9.5,\\n                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,\\n                )),\\n", "            // 이름은 사진 폭(48) 안에서 한 줄로 · 길면 살짝 작게 (긴 언어·큰 글자에서 왼쪽 메뉴 글자가 안 밀리게)\\n            SizedBox(\\n              width: 48,\\n              child: FittedBox(\\n                fit: BoxFit.scaleDown,\\n                child: Text(label,\\n                    maxLines: 1,\\n                    style: TextStyle(\\n                      color: sel ? _sheetBlue : _sheetSub,\\n                      fontSize: 9.5,\\n                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,\\n                    )),\\n              ),\\n            ),\\n"]]')

def main():
    texts, crlf = {}, {}
    for k, p in FILES.items():
        if not os.path.exists(p):
            print(f'❌ {p} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
        raw = open(p, 'rb').read().decode('utf-8')
        crlf[k] = '\r\n' in raw
        texts[k] = raw.replace('\r\n', '\n')
    if 'clamp(maxScaleFactor: 1.2)' in texts['home'] and 'width: 48,\n              child: FittedBox' in texts['player']:
        print('이미 적용돼 있어요'); return
    ok = True
    for f, name, old, new in E:
        n = texts[f].count(old)
        if n == 1:
            texts[f] = texts[f].replace(old, new); print(f'✔ {os.path.basename(FILES[f])} - {name}')
        else:
            print(f'❌ {os.path.basename(FILES[f])} - {name} (찾을 코드가 {n}군데)'); ok = False
    if not ok:
        print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요.'); sys.exit(1)
    for k, p in FILES.items():
        t = texts[k].replace('\n', '\r\n') if crlf[k] else texts[k]
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n완료!')

main()
