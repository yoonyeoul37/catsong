# -*- coding: utf-8 -*-
# release_play.py 가 부르는 빌드 담당
#  1) pubspec.yaml 버전 번호 +1   (예: 1.0.0+183 → 1.0.0+184)
#  2) flutter build appbundle --release  → build\app\outputs\bundle\release\app-release.aab
# 혼자 실행해도 돼요: python build_release.py
import os, re, sys, subprocess, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)

PUBSPEC = 'pubspec.yaml'


def bump_version():
    raw = open(PUBSPEC, 'rb').read().decode('utf-8')
    m = re.search(r'^version:[ \t]*(\d+\.\d+\.\d+)\+(\d+)', raw, re.M)  # 줄 끝(줄바꿈)은 건드리지 않음
    if not m:
        print('❌ pubspec.yaml 에서 version: 1.0.0+숫자 줄을 못 찾았어요.'); sys.exit(1)
    name, code = m.group(1), int(m.group(2))
    new_line = f'version: {name}+{code + 1}'
    raw = raw[:m.start()] + new_line + raw[m.end():]  # 이 줄만 바꾸고 나머지·줄바꿈은 그대로
    open(PUBSPEC, 'wb').write(raw.encode('utf-8'))
    print(f'✔ 버전 번호 올림: {name}+{code} → {name}+{code + 1}')
    return code


def restore_version(old_code):
    """빌드가 실패하면 번호를 원래대로 (다음에 다시 해도 번호가 건너뛰지 않게)"""
    raw = open(PUBSPEC, 'rb').read().decode('utf-8')
    raw = re.sub(r'^(version:\s*\d+\.\d+\.\d+\+)\d+', lambda m: f'{m.group(1)}{old_code}', raw, count=1, flags=re.M)
    open(PUBSPEC, 'wb').write(raw.encode('utf-8'))
    print(f'↩ 빌드가 안 돼서 버전 번호를 {old_code} 로 되돌렸어요.')


def main():
    if not os.path.exists(PUBSPEC):
        print('❌ mp3_player_new 폴더에서 실행해 주세요.'); sys.exit(1)
    old = bump_version()
    print('… 빌드 중이에요 (몇 분 걸려요)')
    # 윈도우에서 flutter 는 flutter.bat 이라 shell=True 로 실행
    r = subprocess.run('flutter build appbundle --release', shell=True)
    aab = os.path.join('build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab')
    if r.returncode != 0 or not os.path.exists(aab):
        restore_version(old)
        print('❌ 빌드 실패'); sys.exit(1)
    print(f'✔ 빌드 끝: {aab}')


main()