# -*- coding: utf-8 -*-
# 라디오 화면 글자 크기: 앱 설정 따라가게
import os, sys, json
KEYS = json.loads('{}')
EDITS = json.loads('[["providers/theme_provider.dart", "import \'package:shared_preferences/shared_preferences.dart\';\\n", "import \'package:shared_preferences/shared_preferences.dart\';\\nimport \'package:provider/provider.dart\';\\n", 1], ["providers/theme_provider.dart", "class ThemeProvider extends ChangeNotifier {\\n", "/// 라디오 목록 화면 글자 크기 — 글자 크기 \'보통\'일 때 지금처럼 1.25,\\n/// 앱 글자 크기 설정과 좁은 폰 자동 줄임(main.dart와 같은 계산)도 같이 따라가게\\nTextScaler radioTextScaler(BuildContext context) {\\n  final t = Provider.of<ThemeProvider>(context, listen: false).textScale;\\n  final fit = (MediaQuery.sizeOf(context).width / 400).clamp(0.85, 1.0);\\n  return TextScaler.linear(1.25 * (t / 1.12) * fit);\\n}\\n\\nclass ThemeProvider extends ChangeNotifier {\\n", 1], ["screens/radio_home_screen.dart", "          textScaler: const TextScaler.linear(1.25),\\n", "          textScaler: radioTextScaler(context),\\n", 1], ["screens/radio_home_screen.dart", "MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.25))", "MediaQuery.of(context).copyWith(textScaler: radioTextScaler(context))", 1], ["screens/radio_korea_screen2.dart", "MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.25))", "MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx))", 1], ["screens/radio_player_screen.dart", "MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.25))", "MediaQuery.of(context).copyWith(textScaler: radioTextScaler(context))", 1], ["screens/radio_country_stations_screen.dart", "MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.25))", "MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx))", 1], ["widgets/overseas_radio_view.dart", "MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.25))", "MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx))", 1]]')
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
if not KEYS or all(k in have for k in KEYS):
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
