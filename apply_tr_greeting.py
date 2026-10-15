# -*- coding: utf-8 -*-
# 첫인사·끝인사 번역
import os, sys, json
KEYS = json.loads('{"greetLine1": ["오늘도 좋은 소리와 함께해요", "Welcome back", "今日もいい音と一緒に", "今天也与好声音相伴", "今天也與好聲音相伴", null], "greetLine2": ["반가워요, 잠시 쉬어가요", "Good sounds, good day", "ようこそ、少しひと休み", "欢迎，稍作休息吧", "歡迎，稍作休息吧", null], "greetLine3": ["편안한 하루 되세요", "Take a moment for yourself", "穏やかな一日を", "祝你度过轻松的一天", "祝你度過輕鬆的一天", null], "greetLine4": ["오늘 하루도 반가워요", "Your sounds are waiting", "今日もようこそ", "今天也很高兴见到你", "今天也很高興見到你", null], "greetLine5": ["마음이 쉬어가는 곳, 파란소리", "Relax and listen", "心が休まる場所、Paransori", "让心灵休憩的地方，Paransori", "讓心靈休憩的地方，Paransori", null], "byeLine1": ["좋은 음악과 함께한 하루였어요", "What a day with good music", "いい音楽と過ごした一日でした", "今天有好音乐相伴", "今天有好音樂相伴", null], "byeLine2": ["오늘 하루도 수고했어요", "You did great today", "今日もお疲れさまでした", "今天也辛苦了", "今天也辛苦了", null], "byeLine3": ["편안한 밤 되세요", "Have a peaceful night", "穏やかな夜を", "祝你有个宁静的夜晚", "祝你有個寧靜的夜晚", null], "byeLine4": ["푹 자고 내일 만나요", "Sleep well, see you tomorrow", "ぐっすり眠って、また明日", "好好睡，明天见", "好好睡，明天見", null]}')
EDITS = json.loads('[["main.dart", "    config: const AudioServiceConfig(\\n      androidNotificationChannelId: \'kr.ssing.catsong.audio\',\\n      androidNotificationChannelName: \'파란소리\',", "    config: AudioServiceConfig(\\n      androidNotificationChannelId: \'kr.ssing.catsong.audio\',\\n      androidNotificationChannelName: tr.appName,", 1], ["main.dart", "            title: \'파란소리\',\\n", "            onGenerateTitle: (c) => AppLocalizations.of(c)!.appName,\\n", 1], ["main.dart", "  final String _line = _greetingLines[Random().nextInt(5)];\\n  String get _greet {\\n    final ko = Localizations.localeOf(context).languageCode == \'ko\';\\n    final i = _greetingLines.indexOf(_line);\\n    return ko ? _line : _greetingLinesEn[i];\\n  }", "  final int _lineNo = Random().nextInt(5);\\n  String get _greet {\\n    final l = AppLocalizations.of(context)!;\\n    return [l.greetLine1, l.greetLine2, l.greetLine3, l.greetLine4, l.greetLine5][_lineNo];\\n  }", 1], ["main.dart", "/// 첫인사 인사말 (켤 때마다 하나씩 무작위) — 번역할 때 일본어·중국어 추가\\nconst _greetingLines = <String>[\\n  \'오늘도 좋은 소리와 함께해요\',\\n  \'반가워요, 잠시 쉬어가요\',\\n  \'편안한 하루 되세요\',\\n  \'오늘 하루도 반가워요\',\\n  \'마음이 쉬어가는 곳, 파란소리\',\\n];\\nconst _greetingLinesEn = <String>[\\n  \'Welcome back\',\\n  \'Good sounds, good day\',\\n  \'Take a moment for yourself\',\\n  \'Your sounds are waiting\',\\n  \'Relax and listen\',\\n];\\n\\n", "", 1], ["utils/greeting_images.dart", "import \'package:shared_preferences/shared_preferences.dart\';\\n", "import \'package:shared_preferences/shared_preferences.dart\';\\nimport \'../l10n/app_localizations.dart\';\\n", 1], ["utils/greeting_images.dart", "/// 끝인사 한 줄 인사: 오늘 장면에 맞게 (한국어 화면은 한국어, 그 밖은 영어)\\nString farewellLine(BuildContext context) {\\n  const ko = [\'좋은 음악과 함께한 하루였어요\', \'오늘 하루도 수고했어요\', \'편안한 밤 되세요\', \'푹 자고 내일 만나요\'];\\n  const en = [\'What a day with good music\', \'You did great today\', \'Have a peaceful night\', \'Sleep well, see you tomorrow\'];\\n  return (_lang(context) == \'ko\' ? ko : en)[_scene];\\n}", "/// 끝인사 한 줄 인사: 오늘 장면에 맞게 (화면 언어로)\\nString farewellLine(BuildContext context) {\\n  final l = AppLocalizations.of(context)!;\\n  return [l.byeLine1, l.byeLine2, l.byeLine3, l.byeLine4][_scene];\\n}", 1]]')
LANGS = ['ko', 'en', 'ja', 'zh', 'zh_Hant']
ROOT = 'lib'
def rd(p):
    with open(p, 'r', encoding='utf-8', newline='') as f: return f.read()
def wr(p, t):
    with open(p, 'w', encoding='utf-8', newline='') as f: f.write(t)
import re
STR = re.compile(r"'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\"|//[^\n]*")
def diff(s):
    s = STR.sub('', s)
    return [s.count(a) - s.count(b) for a, b in ['()', '[]', '{}']]
if not os.path.isdir(ROOT):
    print('❌ lib 폴더가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
out = {}
ok = True
# 1) 번역 문구 넣기
arbs = {}
for i, lang in enumerate(LANGS):
    p = os.path.join(ROOT, 'l10n', 'app_%s.arb' % lang)
    if not os.path.exists(p):
        print('❌', 'app_%s.arb' % lang, '파일이 없어요'); sys.exit(1)
    arbs[lang] = (p, rd(p))
have = json.loads(arbs['ko'][1])
if KEYS and all(k in have for k in KEYS):
    already_keys = True
else:
    already_keys = False
    for lang, (p, t) in arbs.items():
        d = json.loads(t)
        dup = [k for k in KEYS if k in d]
        if dup:
            print('❌', os.path.basename(p), '에 이미 있는 이름:', ', '.join(dup)); ok = False; continue
        nl = '\r\n' if '\r\n' in t else '\n'
        lines = []
        for k, v in KEYS.items():
            val = v[LANGS.index(lang)]
            lines.append('  %s: %s' % (json.dumps(k), json.dumps(val, ensure_ascii=False)))
            if lang in ('ko', 'en') and v[5]:
                ph = {name: {'type': typ} for name, typ in v[5].items()}
                lines.append('  %s: %s' % (json.dumps('@' + k), json.dumps({'placeholders': ph}, ensure_ascii=False)))
        end = t.rstrip()
        if not end.endswith('}'):
            print('❌', os.path.basename(p), '모양이 이상해요'); ok = False; continue
        body = end[:-1].rstrip()
        new = body + ',' + nl + (',' + nl).join(lines) + nl + '}' + (nl if t.endswith(('\n',)) else '')
        try:
            json.loads(new)
        except Exception as ex:
            print('❌', os.path.basename(p), '저장하면 깨져요', ex); ok = False; continue
        out[p] = new
        print('✔', os.path.basename(p), '문구 %d개' % len(KEYS))
# 2) 코드 고치기
done_edits = 0
for rel, old, new, cnt in EDITS:
    p = os.path.join(ROOT, rel)
    if p not in out:
        if not os.path.exists(p):
            print('❌', rel, '파일이 없어요'); ok = False; continue
        out[p] = rd(p)
    t = out[p]
    crlf = '\r\n' in t
    o = old.replace('\n', '\r\n') if crlf else old
    n = new.replace('\n', '\r\n') if crlf else new
    c = t.count(o)
    if (n and o in n and t.count(n) >= 1) or (c == 0 and (n == '' or t.count(n) >= 1)):
        done_edits += 1; continue
    if c != cnt:
        print('❌', rel, '고칠 곳을 못 찾았어요:', old.strip().splitlines()[0][:70]); ok = False; continue
    out[p] = t.replace(o, n)
if done_edits == len(EDITS) and already_keys:
    print('이미 적용돼 있어요'); sys.exit(0)
if done_edits and not ok:
    pass
if not ok:
    print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
for p, t in out.items():
    if p.endswith('.dart'):
        before = diff(rd(p)); after = diff(t)
        if before != after:
            print('❌', p, '괄호 개수가 안 맞아요'); print('❌ 아무것도 저장하지 않았어요'); sys.exit(1)
files = sorted(set(os.path.basename(r) for r, *_ in EDITS))
for p, t in out.items(): wr(p, t)
for f in files: print('✔', f)
print('다 됐어요 (코드 %d곳)' % (len(EDITS) - done_edits))
