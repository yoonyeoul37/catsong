# -*- coding: utf-8 -*-
# 고정 높이 버튼 글자 한 줄로
import os, sys, json
KEYS = json.loads('{}')
EDITS = json.loads('[["widgets/lyrics_card_sheet.dart", "                      child: Text(tr.revert, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),", "                      child: FittedBox(\\n                        fit: BoxFit.scaleDown,\\n                        child: Text(tr.revert, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),\\n                      ),", 1], ["widgets/lyrics_card_sheet.dart", "                      child: Text(tr.apply, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),", "                      child: FittedBox(\\n                        fit: BoxFit.scaleDown,\\n                        child: Text(tr.apply, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),\\n                      ),", 1], ["screens/alarm_screen.dart", "              child: Text(tr.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),", "              child: FittedBox(\\n                fit: BoxFit.scaleDown,\\n                child: Text(tr.save, maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),\\n              ),", 1], ["screens/alarm_ring_screen.dart", "                        child: Text(tr.turnOff, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),", "                        child: FittedBox(\\n                          fit: BoxFit.scaleDown,\\n                          child: Text(tr.turnOff, maxLines: 1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),\\n                        ),", 1], ["screens/alarm_ring_screen.dart", "                        child: Text(tr.snooze5, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),", "                        child: FittedBox(\\n                          fit: BoxFit.scaleDown,\\n                          child: Text(tr.snooze5, maxLines: 1, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),\\n                        ),", 1], ["screens/home_screen.dart", "          child: Text(tr.done, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),", "          child: FittedBox(\\n            fit: BoxFit.scaleDown,\\n            child: Text(tr.done, maxLines: 1, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),\\n          ),", 1], ["widgets/action_feedback.dart", "                                  child: Text(tr.undo,\\n                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),", "                                  child: FittedBox(\\n                                    fit: BoxFit.scaleDown,\\n                                    child: Text(tr.undo,\\n                                        maxLines: 1, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),\\n                                  ),", 1], ["widgets/action_feedback.dart", "                                  child: Text(tr.ok,\\n                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),", "                                  child: FittedBox(\\n                                    fit: BoxFit.scaleDown,\\n                                    child: Text(tr.ok,\\n                                        maxLines: 1, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),\\n                                  ),", 1]]')
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
