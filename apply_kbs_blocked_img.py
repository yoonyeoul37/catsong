# -*- coding: utf-8 -*-
# KBS 편성 사진 중 바깥에서 못 여는 주소(padmin.static.kbs.co.kr)는 처음부터 '사진 없음' → 바로 기본 이미지
# 실행: python apply_kbs_blocked_img.py   (프로젝트 폴더에서)
import os, sys


def find(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)


p = find('radio_provider.dart')
if not p:
    print('❌ radio_provider.dart 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
with open(p, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if '_kbsImage(' in t:
    print('이미 적용돼 있어요'); sys.exit(0)
cnt = lambda x: [x.count(a) - x.count(b) for a, b in ('()', '{}', '[]')]
before = cnt(t)

# 1) 도우미 넣기
anchor = '  static Map<String, String>? _parseKbsChannelFromUrl(String streamUrl) {\n'
if t.count(anchor) != 1:
    print('❌ 1번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
t = t.replace(anchor, """  /// KBS 편성 사진: 바깥에서 못 여는 주소(접근 거부)는 '사진 없음'으로 → 바로 기본 이미지
  static String? _kbsImage(dynamic url) {
    final u = url?.toString() ?? '';
    if (u.isEmpty || u.contains('padmin.static.kbs.co.kr')) return null;
    return u;
  }

""" + anchor)
print('✔ 1번 고침 (도우미 추가)')

# 2) 목록 사진 2곳
a = "            s['image'] = s['image_w'];\n"
if t.count(a) != 2:
    print(f'❌ 2번 고칠 곳이 2군데가 아니에요 ({t.count(a)}군데) — 아무것도 저장 안 했어요'); sys.exit(1)
t = t.replace(a, "            s['image'] = _kbsImage(s['image_w']);\n")
print('✔ 2번 고침 (편성표 목록 사진 2곳)')

# 3) 지금 프로그램 사진 1곳
b = "              merged['image'] = s['image_w'];\n"
if t.count(b) != 1:
    print('❌ 3번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
t = t.replace(b, "              merged['image'] = _kbsImage(s['image_w']);\n")
print('✔ 3번 고침 (지금 프로그램 사진)')

if cnt(t) != before:
    print('❌ 괄호 짝이 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
with open(p, 'w', encoding='utf-8', newline='') as f:
    f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
