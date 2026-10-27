# -*- coding: utf-8 -*-
# 홈 화면 위젯 도움말 문구 (한국어만) — 정중한 말투로
import os, re, sys, json

def find(name):
    for r, _, fs in os.walk('lib'):
        if name in fs: return os.path.join(r, name)
    return None

ARB = find('app_ko.arb')
GEN = find('app_localizations_ko.dart')
for n, p in [('app_ko.arb', ARB), ('app_localizations_ko.dart', GEN)]:
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

NEW = {
 'helpWidgetTitle': '홈 화면 위젯 안내',
 'helpWidgetWhen': '앱을 직접 실행하지 않고도 홈 화면에서 파란소리의 음악, 라디오, 자연의 소리를 바로 감상하실 수 있습니다.',
 'helpWidgetAdd1': '홈 화면의 빈 공간을 길게 누릅니다.',
 'helpWidgetAdd2': '메뉴에서 [위젯]을 선택한 후 파란소리를 찾습니다.',
 'helpWidgetAdd3': '원하는 크기의 위젯을 길게 눌러 홈 화면에 배치합니다.',
 'helpWidgetBasic1': '이미지 위에 현재 재생 중인 곡명 또는 방송 프로그램명이 표시됩니다.',
 'helpWidgetBasic2': '이전 곡, 재생/일시정지, 다음 곡 제어 버튼을 이용하실 수 있습니다.',
 'helpWidgetBasic3': '음악, 라디오, 자연의 소리, 수면 기능 바로가기를 지원합니다.',
 'helpWidgetBasic4': '음악, 라디오, 자연의 소리는 즉시 재생되며, 수면 위젯은 앱 화면으로 연결됩니다.',
 'helpWidgetBig2': '하단에 최근 청취한 항목 3개가 표시됩니다.',
 'helpWidgetBig3': '원하는 항목을 선택하면 즉시 재생됩니다.',
 'helpWidgetTall1': '상단에는 이미지가, 하단에는 재생 정보와 조작 버튼이 표시됩니다.',
 'helpWidgetAll1': '우측 상단의 메뉴 버튼(⋮)을 통해 반복·랜덤 재생, 수면 타이머 설정 및 위젯 이미지 변경이 가능합니다.',
 'helpWidgetAll2': '반복 및 랜덤 재생 기능은 음악 재생 중에만 활성화됩니다.',
 'helpWidgetNote': '※ 위젯의 크기와 배치 형태는 기기 및 홈 화면 설정에 따라 일부 다를 수 있습니다.',
}

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

ar, ANL = load(ARB)
gn, GNL = load(GEN)
if NEW['helpWidgetAll2'] in ar and NEW['helpWidgetAll2'] in gn:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for k, v in NEW.items():
    # app_ko.arb: "키": "값",
    pat = re.compile(r'("%s":\s*)"(?:[^"\\]|\\.)*"' % re.escape(k))
    m = pat.findall(ar)
    if len(m) == 1:
        ar = pat.sub(lambda mm: mm.group(1) + json.dumps(v, ensure_ascii=False), ar)
        print('✔ [app_ko.arb]', k)
    else:
        ok = False; print('❌ [app_ko.arb]', k, '(찾은 개수: %d)' % len(m))
    # app_localizations_ko.dart: String get 키 => '값'; (여러 줄일 수도)
    pat2 = re.compile(r"(String get %s =>)\s*'(?:[^'\\]|\\.)*';" % re.escape(k))
    m2 = pat2.findall(gn)
    if len(m2) == 1:
        dv = v.replace('\\', '\\\\').replace("'", "\\'").replace('"', '\\"').replace('$', '\\$')
        gn = pat2.sub(lambda mm: mm.group(1) + " '" + dv + "';", gn)
        print('✔ [app_localizations_ko.dart]', k)
    else:
        ok = False; print('❌ [app_localizations_ko.dart]', k, '(찾은 개수: %d)' % len(m2))

if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(ARB, 'wb').write(ar.encode('utf-8'))
open(GEN, 'wb').write(gn.encode('utf-8'))
print('저장했어요')
