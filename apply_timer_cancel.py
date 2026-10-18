# -*- coding: utf-8 -*-
# 타이머 취소 버튼 두 줄 → 한 줄로 (길면 살짝 작아짐) + 긴 언어 3개 글자 줄이기
import os, sys, json

EDITS = [
 ('lib/screens/player_screen.dart',
  "                    child: Text(AppLocalizations.of(context)!.timerCancel),\n",
  "                    child: FittedBox(\n"
  "                      fit: BoxFit.scaleDown,\n"
  "                      child: Text(AppLocalizations.of(context)!.timerCancel, maxLines: 1),\n"
  "                    ),\n"),
 ('lib/l10n/app_es.arb', '"timerCancel": "Cancelar temporizador"', '"timerCancel": "Desactivar"'),
 ('lib/l10n/app_fr.arb', '"timerCancel": "Annuler la minuterie"', '"timerCancel": "Désactiver"'),
 ('lib/l10n/app_tr.arb', '"timerCancel": "Zamanlayıcıyı iptal et"', '"timerCancel": "İptal et"'),
]

def balanced(t):
    for a, b in ('()', '[]', '{}'):
        if t.count(a) != t.count(b): return False
    return True

def main():
    ok = True; files = {}; changed = 0
    for path, old, new in EDITS:
        if path not in files:
            if not os.path.exists(path):
                print('❌ 파일을 못 찾았어요:', path, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
            b = open(path, 'rb').read()
            files[path] = [b.decode('utf-8').replace('\r\n', '\n'), b'\r\n' in b, False]
        t = files[path][0]
        if t.count(new) >= 1 and t.count(old) == 0:
            continue
        if t.count(old) != 1:
            print('❌', path, ': 바꿀 곳을 못 찾았어요'); ok = False; continue
        files[path][0] = t.replace(old, new); files[path][2] = True; changed += 1
        print('✔', os.path.basename(path))
    for path, (t, crlf, ch) in files.items():
        if not ch: continue
        if path.endswith('.arb'):
            try: json.loads(t)
            except Exception as e: print('❌', path, '모양이 깨졌어요:', e); ok = False
        elif not balanced(t):
            print('❌', path, '괄호가 안 맞아요'); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if not changed:
        print('이미 적용돼 있어요'); return 0
    for path, (t, crlf, ch) in files.items():
        if not ch: continue
        if crlf: t = t.replace('\n', '\r\n')
        open(path, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요: %d곳 바꿈' % changed)
    return 0

if __name__ == '__main__':
    sys.exit(main())
