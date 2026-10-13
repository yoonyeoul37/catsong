# -*- coding: utf-8 -*-
# 글꼴 정리: 로고(퀵샌드)·큰 제목(도현체)만 남기고 나머지는 전부 설정 글꼴을 따라가게
#  + 처음 설치하면 쓰는 '기본' 글꼴을 수트로 (theme_provider.dart 한 줄로 바꿀 수 있음)
#  - 라디오 목록 방송 이름: 라인 시드 고정 → 설정 글꼴
#  - 라디오 맨 위 추천 카드 방송 이름(한국·해외), KBS·MBC 칩: 도현체 → 설정 글꼴
#  - 홈 아래 '녹음' 탭: 동글체 → 다른 탭과 같게
#  - 설정 글꼴 목록: '기본' → '스포카 한 산스', 수트에 '(기본)' 표시
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)

F = {}
for n in ('theme_provider.dart', 'settings_screen.dart', 'radio_korea_screen2.dart',
          'radio_country_stations_screen.dart', 'home_screen.dart'):
    F[n] = find(n, 'lib')
    if not F[n]:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

if "_fontFamily = 'suit'" in open(F['theme_provider.dart'], encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)
if "'suit'" not in open(F['theme_provider.dart'], encoding='utf-8').read():
    print('❌ apply_fonts_more.py 를 먼저 해 주세요 (수트 글꼴이 아직 없어요)'); sys.exit(1)

writes = {}
ok = True
def edit(name, pairs):
    global ok
    path = F[name]
    src, crlf = writes[path] if path in writes else load(path)
    for item in pairs:
        label, old, new = item[0], item[1], item[2]
        optional = len(item) > 3 and item[3]
        n = src.count(old)
        if n == 0 and optional:
            print('✔ %s (해당 없음 — 이미 정리돼 있어요)' % label); continue
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

edit('theme_provider.dart', [
    ('기본 글꼴: 수트 (바꾸려면 이 한 줄)',
     "  String _fontFamily = 'default';\n",
     "  String _fontFamily = 'suit'; // 처음 설치하면 쓰는 글꼴 — 바꾸려면 이 한 줄만 (예: 'pretendard', 'line_seed', 'default'=스포카)\n"),
    ('뺀 글꼴을 쓰던 사람도 수트로',
     "? fontFamily : 'default';\n",
     "? fontFamily : 'suit';\n"),
])
edit('settings_screen.dart', [
    ('설정: 글꼴 이름 (스포카 · 수트 기본)',
     "    const names = {\n"
     "      'pretendard': '프리텐다드',\n",
     "    const names = {\n"
     "      'default': '스포카 한 산스',\n"
     "      'pretendard': '프리텐다드',\n"),
    ('설정: 수트에 (기본) 표시',
     "      'suit': '수트 (SUIT)',\n",
     "      'suit': '수트 (기본)',\n"),
])
edit('radio_korea_screen2.dart', [
    ('라디오: 목록 방송 이름 → 설정 글꼴',
     "                      // 라디오 목록 방송 이름은 라인 시드 (또렷하고 깔끔하게)\n"
     "                      style: TextStyle(\n"
     "                        fontFamily: 'LINESeedKR',\n",
     "                      // 라디오 목록 방송 이름 (설정 글꼴)\n"
     "                      style: TextStyle(\n", True),
    ('라디오: 맨 위 추천 카드 방송 이름 → 설정 글꼴',
     "                            Text(ks.name,\n"
     "                                maxLines: 1,\n"
     "                                overflow: TextOverflow.ellipsis,\n"
     "                                textScaler: TextScaler.noScaling,\n"
     "                                style: GoogleFonts.doHyeon(color: ink, fontSize: 18)),\n",
     "                            Text(ks.name,\n"
     "                                maxLines: 1,\n"
     "                                overflow: TextOverflow.ellipsis,\n"
     "                                textScaler: TextScaler.noScaling,\n"
     "                                style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),\n"),
    ('라디오: KBS·MBC 칩 → 설정 글꼴',
     "                  style: GoogleFonts.doHyeon(\n"
     "                    color: const Color(0xFF17140F).withOpacity(0.8),\n"
     "                    fontSize: station.broadcaster.length > 3 ? 10.5 : 12.5,\n"
     "                  ),\n",
     "                  style: TextStyle(\n"
     "                    color: const Color(0xFF17140F).withOpacity(0.8),\n"
     "                    fontSize: station.broadcaster.length > 3 ? 10 : 12,\n"
     "                    fontWeight: FontWeight.w700,\n"
     "                    letterSpacing: -0.2,\n"
     "                  ),\n"),
])
edit('radio_country_stations_screen.dart', [
    ('해외 라디오: 맨 위 추천 카드 방송 이름 → 설정 글꼴',
     "                              Text(st.name,\n"
     "                                  maxLines: 1,\n"
     "                                  overflow: TextOverflow.ellipsis,\n"
     "                                  textScaler: TextScaler.noScaling,\n"
     "                                  style: GoogleFonts.doHyeon(color: ink, fontSize: 18)),\n",
     "                              Text(st.name,\n"
     "                                  maxLines: 1,\n"
     "                                  overflow: TextOverflow.ellipsis,\n"
     "                                  textScaler: TextScaler.noScaling,\n"
     "                                  style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),\n"),
])
edit('home_screen.dart', [
    ('홈: 녹음 탭 글꼴 → 다른 탭과 같게',
     "                  // 녹음 탭: 고운돋움 서체\n"
     "                  ? GoogleFonts.dongle(\n"
     "                      color: isSelected ? baseColor : baseColor.withOpacity(0.54),\n"
     "                      fontSize: 19,\n",
     "                  // 녹음 탭도 다른 탭과 같은 글꼴\n"
     "                  ? TextStyle(\n"
     "                      color: isSelected ? baseColor : baseColor.withOpacity(0.54),\n"
     "                      fontSize: 14,\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_font_tidy')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_font_tidy)')
