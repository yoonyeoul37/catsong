# 빌드할 때마다 버전 번호(+숫자)를 자동으로 하나 올리고 앱 번들(.aab) 만들기
# 실행: python build_release.py   (mp3_player_new 폴더에서)
#  - pubspec.yaml 의 version: 1.0.0+137 → 1.0.0+138 로 바꾸고 바로 빌드
#  - 빌드가 실패하면 번호를 원래대로 되돌려요 (번호가 괜히 올라가지 않게)
import os, re, subprocess, sys

PUBSPEC = 'pubspec.yaml'


def main():
    if not os.path.exists(PUBSPEC):
        print('❌ pubspec.yaml 을 못 찾았어요. mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    raw = open(PUBSPEC, 'rb').read().decode('utf-8')
    m = re.search(r'^version:[ \t]*([0-9.]+)\+(\d+)', raw, re.M)
    if not m:
        print('❌ pubspec.yaml 에서 "version: 1.0.0+숫자" 줄을 못 찾았어요. 아무것도 바꾸지 않았어요.')
        sys.exit(1)

    name, old = m.group(1), int(m.group(2))
    new = old + 1
    line_old = m.group(0)
    line_new = f'version: {name}+{new}'
    text = raw.replace(line_old, line_new, 1)  # 줄바꿈(CRLF)은 그대로
    open(PUBSPEC, 'wb').write(text.encode('utf-8'))
    print(f'✔ 버전 번호: {name}+{old} → {name}+{new}')

    print('… 빌드 중이에요 (몇 분 걸려요)')
    try:
        r = subprocess.run('flutter build appbundle --release', shell=True)
        ok = r.returncode == 0
    except Exception as e:
        print('❌ flutter 를 실행하지 못했어요:', e)
        ok = False

    if not ok:
        open(PUBSPEC, 'wb').write(raw.encode('utf-8'))  # 실패하면 번호 되돌리기
        print(f'❌ 빌드가 실패해서 버전 번호를 {name}+{old} 로 되돌렸어요.')
        sys.exit(1)

    print(f'완료! {name}+{new} 로 빌드했어요.')
    print(r'   파일: build\app\outputs\bundle\release\app-release.aab')


main()
