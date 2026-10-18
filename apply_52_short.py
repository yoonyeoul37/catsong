# -*- coding: utf-8 -*-
# 아까 뺀 52개 중 고칠 만한 17개만 짧게 다듬어 넣기
#  - 좁은 버튼·탭은 길이를 거의 그대로 유지
#  - 키 이름 + 지금 문구가 정확히 맞을 때만 바꿈 (다르면 ❌, 아무것도 저장 안 함)
import os, sys, json

CHANGES = {
 "fr": [
  [
   "playing",
   "Lecture...",
   "En lecture..."
  ]
 ],
 "it": [
  [
   "stopMix",
   "Ferma mix",
   "Ferma il mix"
  ],
  [
   "playMix",
   "Avvia mix",
   "Avvia il mix"
  ]
 ],
 "de": [
  [
   "ringtone",
   "Als Klingelton",
   "Klingelton festlegen"
  ]
 ],
 "tr": [
  [
   "ringtone",
   "Zil sesi yap",
   "Zil sesi ayarla"
  ]
 ],
 "ru": [
  [
   "play",
   "Играть",
   "Воспроизвести"
  ]
 ],
 "vi": [
  [
   "next",
   "Tiếp",
   "Tiếp theo"
  ],
  [
   "radioSleep",
   "Hẹn tắt",
   "Hẹn giờ"
  ]
 ],
 "id": [
  [
   "recent",
   "Terbaru",
   "Riwayat"
  ],
  [
   "recentListened",
   "Terbaru",
   "Riwayat"
  ],
  [
   "radioSleep",
   "Tidur",
   "Timer"
  ],
  [
   "nowPlaying",
   "Diputar",
   "Sedang diputar"
  ]
 ],
 "es": [
  [
   "set",
   "Fijar",
   "Aplicar"
  ],
  [
   "on",
   "Sí",
   "Encendido"
  ],
  [
   "off",
   "No",
   "Apagado"
  ],
  [
   "justNow",
   "Ahora",
   "Ahora mismo"
  ]
 ],
 "th": [
  [
   "radioRecentListening",
   "ฟังล่าสุด",
   "สถานีที่ฟังล่าสุด"
  ]
 ]
}

def raw(s):
    return json.dumps(s, ensure_ascii=False)[1:-1]

def main():
    ok = True; out = {}; total = 0
    for code, pairs in CHANGES.items():
        path = os.path.join('lib', 'l10n', 'app_%s.arb' % code)
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
        b = open(path, 'rb').read(); crlf = b'\r\n' in b
        text = b.decode('utf-8').replace('\r\n', '\n'); changed = 0
        for key, old, new in pairs:
            o = '"%s": "%s"' % (key, raw(old)); n = '"%s": "%s"' % (key, raw(new))
            if text.count(n) >= 1 and text.count(o) == 0: continue
            if text.count(o) >= 1:  # 같은 키가 두 번 적힌 파일도 있어서 둘 다 바꿈
                text = text.replace(o, n); changed += 1; print('✔', code, key, ':', new.replace('\n', ' / '))
            else:
                print('❌', code, key, ': 지금 문구가 달라서 못 바꿨어요'); ok = False
        try:
            json.loads(text)
        except Exception as e:
            print('❌', path, '모양이 깨졌어요:', e); ok = False
        if changed:
            out[path] = (text, crlf); total += changed
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if not out:
        print('이미 적용돼 있어요'); return 0
    for p, (t, crlf) in out.items():
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요: %d곳 바꿈 (%d개 파일)' % (total, len(out)))
    return 0

if __name__ == '__main__':
    sys.exit(main())
