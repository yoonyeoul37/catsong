# -*- coding: utf-8 -*-
# 안드로이드 오토 심사 대비: 라디오 연결 실패 안내 (차 화면 · 알림창) + 도움말 팟캐스트 탭 이름 번역

import os, sys, json

EDITS = [('lib/providers/player_provider.dart', [('  // ───── 라디오 시간 줄: 지금 프로그램 시작~끝 (편성표) ─────', '  /// 라디오 연결 실패: 차 화면 · 알림창에 안내 글 (재생 버튼을 다시 누르면 다시 연결)\n  /// 다시 소리가 나면 setRadioPlaybackState가 보통 상태로 돌려놓음\n  void setRadioError(String message) {\n    if (!_radioMode) return;\n    playbackState.add(PlaybackState(\n      controls: [\n        MediaControl.skipToPrevious,\n        MediaControl.play,\n        MediaControl.skipToNext,\n      ],\n      androidCompactActionIndices: const [0, 1, 2],\n      playing: false,\n      processingState: AudioProcessingState.error,\n      errorCode: 1, // 앱 오류 (안드로이드 ERROR_CODE_APP_ERROR)\n      errorMessage: message,\n      updatePosition: const Duration(milliseconds: -1),\n      speed: 0.0,\n    ));\n  }\n\n  // ───── 라디오 시간 줄: 지금 프로그램 시작~끝 (편성표) ─────')]), ('lib/providers/radio_provider.dart', [('    if (state == RadioPlayerState.error) {\n      _onStationFailed();', '    if (state == RadioPlayerState.error) {\n      _onStationFailed();\n      // 차 화면 · 알림창에도 "재생하지 못했어요" (차에서는 앱 화면을 볼 수 없어서)\n      _simpleHandler?.setRadioError((_errorMessage ?? tr.radioPlaybackFailed).replaceAll(\'\\n\', \' \'));')])]
POD = json.loads('{"ja": "ポッドキャスト", "zh": "播客", "zh_Hant": "Podcast", "de": "Podcasts", "es": "Pódcasts", "fr": "Podcasts", "it": "Podcast", "pt": "Podcasts", "pl": "Podcasty", "ru": "Подкасты", "tr": "Podcastler", "id": "Podcast", "vi": "Podcast", "th": "พอดแคสต์", "uk": "Подкасти", "hi": "पॉडकास्ट", "ro": "Podcasturi", "cs": "Podcasty", "hu": "Podcastok", "ar": "بودكاست", "ur": "پوڈکاسٹ"}')  # 앱 팟캐스트 탭 이름 (podcast_text.dart '팟캐스트' 줄과 같음)
L10N = os.path.join('lib', 'l10n')
KEY = 'helpCarUse3'
LANGS = ['ar','cs','de','es','fr','hi','hu','id','it','ja','pl','pt','ro','ru','th','tr','uk','ur','vi','zh','zh_Hant']


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    pp = os.path.join('lib', 'providers', 'player_provider.dart')
    if os.path.exists(pp) and 'void setRadioError(' in open(pp, encoding='utf-8').read():
        print('이미 적용돼 있어요')
        return
    out = {}
    ok = True
    # 1) 라디오 연결 실패 안내
    for rel, pairs in EDITS:
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel); ok = False; continue
        raw = open(rel, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        t = raw.replace('\r\n', '\n')
        before = gaps(t)
        for i, (old, new) in enumerate(pairs, 1):
            n = t.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n)); ok = False; continue
            t = t.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(t) != before:
            print('❌ %s 괄호가 안 맞아요' % name); ok = False
        out[rel] = t.replace('\n', '\r\n') if crlf else t
    # 2) 설정 도움말 "자동차에서 듣기" 3번: 영어 Podcasts → 앱 팟캐스트 탭 이름
    for lang in LANGS:
        p = os.path.join(L10N, 'app_%s.arb' % lang)
        if not os.path.exists(p):
            print('❌ 파일이 없어요:', p); ok = False; continue
        t = open(p, 'rb').read().decode('utf-8')
        lines = t.split('\n')
        hit = [i for i, l in enumerate(lines) if l.lstrip().startswith('"%s"' % KEY)]
        if len(hit) != 1 or 'Podcasts' not in lines[hit[0]]:
            print('❌ app_%s.arb 자리를 못 찾았어요' % lang); ok = False; continue
        lines[hit[0]] = lines[hit[0]].replace('Podcasts', POD[lang], 1)
        t2 = '\n'.join(lines)
        try:
            json.loads(t2)
        except Exception as e:
            print('❌ app_%s.arb 확인 실패: %s' % (lang, e)); ok = False; continue
        out[p] = t2
        print('✔ app_%s.arb' % lang)
    for lang in LANGS:
        if lang == 'zh_Hant':
            continue
        p = os.path.join(L10N, 'app_localizations_%s.dart' % lang)
        if not os.path.exists(p):
            print('❌ 파일이 없어요:', p); ok = False; continue
        t = open(p, 'rb').read().decode('utf-8')
        lines = t.split('\n')
        hit = [i for i, l in enumerate(lines) if l.startswith('  String get %s =>' % KEY)]
        langs = ['zh', 'zh_Hant'] if lang == 'zh' else [lang]
        # 긴 글자는 다음 줄로 넘어가 있을 수 있어서, ';' 나올 때까지 같이 봄
        spans = []
        for i in hit:
            j = i
            while j < len(lines) - 1 and not lines[j].rstrip().endswith(';'):
                j += 1
            k = next((x for x in range(i, j + 1) if 'Podcasts' in lines[x]), None)
            spans.append(k)
        if len(hit) != len(langs) or None in spans:
            print('❌ app_localizations_%s.dart 자리를 못 찾았어요' % lang); ok = False; continue
        for k, L in zip(spans, langs):
            lines[k] = lines[k].replace('Podcasts', POD[L], 1)
        out[p] = '\n'.join(lines)
        print('✔ app_localizations_%s.dart' % lang)
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요'); sys.exit(1)
    for p, t in out.items():
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
