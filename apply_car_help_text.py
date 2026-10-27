# -*- coding: utf-8 -*-
# 안드로이드 오토 도움말 문구 (한국어만) — 정중한 말투로
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
 'helpCarWhen': '안드로이드 오토 지원 차량에서 파란소리의 라디오, 음악, 자연의 소리, 팟캐스트를 감상하실 수 있습니다.',
 'helpCarUse1': '휴대폰을 차량에 USB 케이블 또는 무선으로 연결합니다.',
 'helpCarUse2': '차량 디스플레이에서 파란소리를 선택합니다.',
 'helpCarUse3': '라디오, 음악, 팟캐스트, 자연의 소리 탭에서 원하는 콘텐츠를 선택합니다.',
 'helpCarUse4': '운전 중에는 화면을 직접 조작하지 않고 음성으로 편리하게 제어할 수 있습니다.',
 'helpCarFind1': '라디오: 상단에 최근 청취 방송과 즐겨찾기가 배치되며, 하단에는 방송사별(해외는 장르별) 카테고리가 제공됩니다.',
 'helpCarFind2': '음악: 상단의 [랜덤 재생] 선택 시 전체 음원이 무작위로 재생됩니다.',
 'helpCarFind3': '편성표: 방송 중인 프로그램의 이미지와 다음 방송 정보가 함께 표시됩니다.',
 'helpCarVoiceHead': '음성 명령 이용 안내',
 'helpCarVoiceHow': '스티어링 휠의 음성 인식 버튼을 누르거나 "Hey Google"을 호출한 후 다음과 같이 말씀해 주세요.',
 'helpCarVoice3': '"파란소리 재생해 줘" → 최근 청취하던 콘텐츠를 이어서 재생합니다.',
 'helpCarNote': '※ 차량 및 휴대폰이 안드로이드 오토를 지원해야 합니다. 연결 방식과 메뉴 구성은 기기 사양에 따라 다를 수 있습니다.',
 'tellUsModel': '사용 중인 기기 모델명과 오류 발생 상황을 알려주시기 바랍니다.',
}

def load(p):
    s = open(p, 'rb').read().decode('utf-8')
    return s, ('\r\n' if '\r\n' in s else '\n')

ar, ANL = load(ARB)
gn, GNL = load(GEN)
if NEW['helpCarVoiceHead'] in ar and NEW['helpCarVoiceHead'] in gn:
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
