# -*- coding: utf-8 -*-
# 주사위 '다시 던지기'를 빨리 눌러도 새로 나온 방송이 나오게
#  · radio_dice.dart: 이전 방송이 아직 연결 중이어도 새 방송으로 (force)
#  · radio_provider.dart: 늦게 끝난 예전 요청이 새 방송을 덮어쓰지 않게 (가장 마지막 요청만 재생)
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

def find(name):
    for root, dirs, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

def load(name):
    p = find(name)
    if not p:
        print('❌', name, '못 찾음 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    raw = open(p, 'rb').read().decode('utf-8')
    return p, raw.replace('\r\n', '\n'), '\r\n' in raw

ok = True
def rep(s, label, old, new):
    global ok
    n = s.count(old)
    if n != 1:
        print('❌', label, '(찾은 개수 %d)' % n); ok = False; return s
    print('✔', label)
    return s.replace(old, new)

pp, p, pcrlf = load('radio_provider.dart')
dp, d, dcrlf = load('radio_dice.dart')

if '_playGen' in p and 'playStation(pick.station, force: true)' in d:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

# ── radio_provider.dart ──
p = rep(p, '마지막 요청 번호 추가',
    "  Future<void> playStation(RadioStation station, {bool force = false}) async {\n",
    "  int _playGen = 0; // 가장 마지막에 누른 방송 번호 (늦게 끝난 예전 요청이 새 방송을 덮어쓰지 않게)\n\n"
    "  Future<void> playStation(RadioStation station, {bool force = false}) async {\n")
p = rep(p, '방송 틀 때마다 번호 올리기',
    "    _userPaused = false;\n    _armStall(15);",
    "    final gen = ++_playGen;\n    _userPaused = false;\n    _armStall(15);")
p = rep(p, '주소 찾는 사이 다른 방송을 눌렀으면 그만',
    "      debugPrint('FINAL_URL: $playUrl');\n",
    "      if (gen != _playGen) return; // 주소 찾는 사이 다른 방송을 눌렀으면 이건 그만\n"
    "      debugPrint('FINAL_URL: $playUrl');\n")
p = rep(p, '연결 끝났을 때 다른 방송이면 기록 안 함',
    "        play: true,\n      );\n\n      await recordListened(station);",
    "        play: true,\n      );\n\n      if (gen != _playGen) return; // 연결되는 사이 다른 방송을 눌렀으면 기록 안 함\n"
    "      await recordListened(station);")
p = rep(p, '예전 요청 실패는 화면에 안 띄움',
    "    } catch (e) {\n      debugPrint('라디오 재생 실패: $e');",
    "    } catch (e) {\n      if (gen != _playGen) return; // 예전 요청이 실패한 건 무시 (지금 방송은 따로 연결 중)\n"
    "      debugPrint('라디오 재생 실패: $e');")

# ── radio_dice.dart ──
d = rep(d, '주사위: 연결 중이어도 새 방송으로',
    "    context.read<RadioProvider>().playStation(pick.station);",
    "    context.read<RadioProvider>().playStation(pick.station, force: true); // 이전 방송이 아직 연결 중이어도 새로 나온 방송으로")

def brackets(s, name):
    global ok
    t = re.sub(r"'''.*?'''", "''", s, flags=re.S)
    t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", t)
    t = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', t)
    t = re.sub(r'//[^\n]*', '', t)
    for a, b in ('()', '[]', '{}'):
        if t.count(a) != t.count(b):
            print('❌ 괄호 안 맞음', name, a, t.count(a), t.count(b)); ok = False
brackets(p, 'radio_provider.dart')
brackets(d, 'radio_dice.dart')

if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)
for path, s, crlf in ((pp, p, pcrlf), (dp, d, dcrlf)):
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
    print('✔ 저장:', os.path.basename(path))
