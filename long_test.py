# -*- coding: utf-8 -*-
# 글자 넘침 시험: 영어 번역 파일(app_en.arb)의 낱말을 일부러 40% 길게 만들어요 (독일어처럼 긴 언어 대비)
#   예) Settings → Settingssett,  All songs → Alla songsso
# 한 번 실행 = 길게 바꾸기 / 한 번 더 실행 = 원래대로 되돌리기
# 실행: 프로젝트 폴더(C:\apps\mp3_player_new)에서  python long_test.py
# ※ 시험하는 동안엔 커밋하지 마세요 (원래대로 되돌린 뒤에 커밋)
import os, sys, io, re, json, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)

ARB = 'lib/l10n/app_en.arb'
BAK = 'long_test_backup.txt'  # 원래 app_en.arb (되돌릴 때 씀, 되돌리면 지워짐)

# 자리 표시({count})·복수형 머리({count, plural,)·고르는 말(=1{ other{)은 그대로
KEEP = re.compile(r'\{\w+\}|\{\w+,\s*(?:plural|select)\s*,|(?:=\d+|zero|one|two|few|many|other)\s*\{|[{}]')
WORD = re.compile(r'[A-Za-z]{3,}')


def longer(text):
    if 'http' in text or '@' in text:
        return text
    out, pos = [], 0
    for m in KEEP.finditer(text):
        out.append(WORD.sub(lambda w: w.group(0) + w.group(0)[:math.ceil(len(w.group(0)) * 0.4)].lower(), text[pos:m.start()]))
        out.append(m.group(0))
        pos = m.end()
    out.append(WORD.sub(lambda w: w.group(0) + w.group(0)[:math.ceil(len(w.group(0)) * 0.4)].lower(), text[pos:]))
    return ''.join(out)


def main():
    if not os.path.exists(ARB):
        print(f'❌ {ARB} 파일이 없어요. 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.'); sys.exit(1)
    if os.path.exists(BAK):
        open(ARB, 'wb').write(open(BAK, 'rb').read())
        os.remove(BAK)
        print('↩ 원래 영어로 되돌렸어요. (flutter gen-l10n → flutter run)')
        return
    raw = open(ARB, 'rb').read()
    text = raw.decode('utf-8')
    crlf = '\r\n' in text
    data = json.loads(text)
    n = 0
    for k, v in data.items():
        if k.startswith('@') or not isinstance(v, str):
            continue
        nv = longer(v)
        if nv != v:
            data[k] = nv; n += 1
    out = json.dumps(data, ensure_ascii=False, indent=2)
    if crlf:
        out = out.replace('\n', '\r\n')
    open(BAK, 'wb').write(raw)  # 먼저 원래 것 저장
    open(ARB, 'wb').write(out.encode('utf-8'))
    print(f'✔ 영어 글자 {n}개를 40% 길게 바꿨어요.')
    print('  앱에서 설정 → 언어 → English 로 바꾸고 화면을 둘러보세요.')
    print('  끝나면 python long_test.py 한 번 더 → 원래대로')


main()
