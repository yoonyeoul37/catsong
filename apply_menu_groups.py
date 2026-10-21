# -*- coding: utf-8 -*-
# ⋮ 메뉴 정리: 비슷한 것끼리 3묶음(이 화면·기능 / 앱 설정 / 파란소리 응원하기) + 종료 맨 아래
# 검정 브랜드 카드는 그대로, 메뉴가 길면 위아래로 밀어서 보기 (작은 폰에서 잘리지 않게)
import os, sys, json

MENU = os.path.join('lib', 'widgets', 'more_menu_sheet.dart')
L10N = os.path.join('lib', 'l10n')

NEW_CHILDREN = r'''                _TopBar(p: p),
                _IntroCard(p: p, onTap: onIntro),
                // ① 이 화면 · 기능 (화면마다 다른 줄 + 아침 알람)
                _GroupCap(p: p, text: tr.moreGroupTools),
                _MenuGroup(p: p, children: [
                  if (showSongTools) ...[
                    _MenuCard(
                      p: p,
                      icon: _kIconSparkle,
                      title: tr.moreCleanTitle,
                      subtitle: tr.moreCleanSub,
                      onTap: onCleanSongs,
                    ),
                    _MenuCard(
                      p: p,
                      icon: _kIconImage,
                      title: tr.moreArtTitle,
                      subtitle: tr.moreArtSub,
                      onTap: onFindArt,
                    ),
                  ],
                  if (hasHomepage)
                    _MenuCard(
                      p: p,
                      icon: _kIconGlobe,
                      title: tr.moreHomepageTitle,
                      subtitle: tr.moreHomepageSub,
                      onTap: onHomepage,
                    ),
                  // 아침 알람 (켜져 있으면 다음 알람 시간)
                  ValueListenableBuilder<ParanAlarm?>(
                    valueListenable: AlarmService.alarm,
                    builder: (context, a, _) => _MenuCard(
                      p: p,
                      icon: _kIconAlarm,
                      title: tr.moreAlarmTitle,
                      subtitle: a != null && a.enabled
                          ? '${AlarmService.nextLabel(a)} · ${AlarmService.labelOf(a)}'
                          : tr.moreAlarmSub,
                      onTap: onAlarm,
                    ),
                  ),
                ]),
                // ② 앱 설정
                _GroupCap(p: p, text: tr.moreGroupApp),
                _MenuGroup(p: p, children: [
                  // 다크 모드: 누르면 바로 켜고 끄기 (메뉴는 그대로)
                  _MenuCard(
                    p: p,
                    icon: _kIconMoon,
                    title: tr.darkMode,
                    subtitle: tr.darkModeInfo,
                    onTap: () => context.read<ThemeProvider>().setDarkMode(!dark),
                    trailing: _MiniToggle(on: dark, p: p),
                  ),
                  _MenuCard(
                    p: p,
                    icon: _kIconGear,
                    title: tr.settings,
                    subtitle: tr.moreSettingsSub,
                    onTap: onSettings,
                  ),
                  // 한 번도 안 열어봤으면 작은 점
                  ValueListenableBuilder<bool>(
                    valueListenable: HelpSeen.seen,
                    builder: (context, seen, _) => _MenuCard(
                      p: p,
                      icon: _kIconHelp,
                      title: tr.moreHelpTitle,
                      subtitle: tr.moreHelpSub,
                      onTap: onHelp,
                      dot: !seen,
                    ),
                  ),
                ]),
                // ③ 파란소리 응원하기 (공유 · 평가 · 의견)
                _GroupCap(p: p, text: tr.moreGroupSupport),
                _MenuGroup(p: p, children: [
                  _MenuCard(
                    p: p,
                    icon: _kIconShare,
                    title: tr.menuShareTitle,
                    subtitle: shareSubtitle,
                    onTap: onShare,
                  ),
                  _MenuCard(
                    p: p,
                    icon: _kIconStar,
                    title: tr.menuRateTitle,
                    subtitle: tr.moreRateSub,
                    onTap: onRate,
                  ),
                  _MenuCard(
                    p: p,
                    icon: _kIconChat,
                    title: fbText('의견 보내기', 'Send feedback'),
                    subtitle: fbText('파란소리에 바라는 점을 들려주세요.', 'Tell us what you’d like from Paransori.'),
                    onTap: onFeedback,
                  ),
                ]),
                // 종료: 맨 아래 따로 (실수로 누르지 않게)
                if (onExit != null) ...[
                  const SizedBox(height: 10),
                  _MenuGroup(p: p, children: [
                    _MenuCard(
                      p: p,
                      icon: _kIconPower,
                      title: tr.exit,
                      subtitle: '',
                      onTap: onExit!,
                    ),
                  ]),
                ],
                const SizedBox(height: 4),
'''

GROUP_CAP = r'''
// 묶음 제목 (작고 연한 글자)
class _GroupCap extends StatelessWidget {
  final _Pal p;
  final String text;
  const _GroupCap({required this.p, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 14, 6, 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.desc, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// 손잡이 + 닫기(X)'''


INTRO_NEW = r'''// 파란소리 소개 — 맨 위 검정 카드 (예전 아래 브랜드 카드를 합침) · 누르면 소개 화면
class _IntroCard extends StatelessWidget {
  final _Pal p;
  final VoidCallback onTap;
  const _IntroCard({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 먹색 카드 (다크 모드는 크림색) — 설정 화면 맨 위 카드와 한 세트
    final dark = p.sheet.computeLuminance() < 0.5;
    final bg = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = dark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final blue = pointColorOf(context, onDark: !dark); // 카드는 바탕과 반대 색
    final (_, subtitle) = paranIntroMenuText();
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 12, 11),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Paran', style: TextStyle(color: blue)),
                        const TextSpan(text: 'sori'),
                      ]),
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.quicksand(
                          color: fg, fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg.withOpacity(0.65), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 작은 소리 막대 (움직임)
              SizedBox(
                height: 24,
                child: FittedBox(child: _SoundBars(color: blue.withOpacity(0.8))),
              ),
              const SizedBox(width: 6),
              Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, // 아랍어에선 < 방향
                  child: _LineIcon(_kIconChevron, size: 18, color: fg.withOpacity(0.5), stroke: 2.0)),
            ],
          ),
        ),
      ),
    );
  }
}

'''

# (묶음1, 묶음2, 묶음3)
CAPS = {
    'ko': ('이 화면 · 기능', '앱 설정', '파란소리 응원하기'),
    'en': ('Tools', 'App settings', 'Support Paransori'),
    'ja': ('この画面の機能', 'アプリ設定', 'Paransoriを応援'),
    'zh': ('本页功能', '应用设置', '支持 Paransori'),
    'zh_Hant': ('本頁功能', '應用程式設定', '支持 Paransori'),
    'de': ('Funktionen', 'App-Einstellungen', 'Paransori unterstützen'),
    'es': ('Funciones', 'Ajustes de la app', 'Apoya a Paransori'),
    'fr': ('Fonctions', "Réglages de l'app", 'Soutenir Paransori'),
    'id': ('Fitur', 'Pengaturan aplikasi', 'Dukung Paransori'),
    'pt': ('Recursos', 'Configurações do app', 'Apoie o Paransori'),
    'th': ('ฟีเจอร์', 'ตั้งค่าแอป', 'สนับสนุน Paransori'),
    'vi': ('Tính năng', 'Cài đặt ứng dụng', 'Ủng hộ Paransori'),
    'ru': ('Функции', 'Настройки приложения', 'Поддержать Paransori'),
    'it': ('Funzioni', 'Impostazioni app', 'Sostieni Paransori'),
    'tr': ('Özellikler', 'Uygulama ayarları', "Paransori'yi destekle"),
    'pl': ('Funkcje', 'Ustawienia aplikacji', 'Wesprzyj Paransori'),
    'uk': ('Функції', 'Налаштування застосунку', 'Підтримати Paransori'),
    'hi': ('सुविधाएँ', 'ऐप सेटिंग्स', 'Paransori का साथ दें'),
    'ro': ('Funcții', 'Setările aplicației', 'Susține Paransori'),
    'cs': ('Funkce', 'Nastavení aplikace', 'Podpořte Paransori'),
    'hu': ('Funkciók', 'Alkalmazásbeállítások', 'Támogasd a Paransorit'),
    'ar': ('الميزات', 'إعدادات التطبيق', 'ادعم Paransori'),
    'ur': ('خصوصیات', 'ایپ کی ترتیبات', 'Paransori کا ساتھ دیں'),
}
KEYS = ('moreGroupTools', 'moreGroupApp', 'moreGroupSupport')


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def main():
    if not os.path.exists(MENU):
        print('❌ 파일을 못 찾았어요:', MENU, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    text, crlf = load(MENU)
    if '_GroupCap' in text:
        print('이미 적용돼 있어요')
        return
    if '_MiniToggle' not in text:
        print('❌ apply_top_buttons.py 를 먼저 돌려 주세요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    out = []
    # 0) 밀어서 보기 (먼저: 맨 아래 브랜드 카드 줄을 기준으로 자리를 찾아서)
    old = "          child: Padding(\n            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),\n"
    new = "          child: SingleChildScrollView( // 메뉴가 길면 위아래로 (작은 폰에서 잘리지 않게)\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),\n"
    if text.count(old) != 1:
        print('❌ 밀어서 보기 시작 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(old, new)
    old = "                _BrandCard(p: p),\n              ],\n            ),\n          ),\n        ),\n      ),\n    );\n  }\n}\n"
    new = "                _BrandCard(p: p),\n              ],\n            ),\n          ),\n          ),\n        ),\n      ),\n    );\n  }\n}\n"
    if text.count(old) != 1:
        print('❌ 밀어서 보기 끝 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(old, new)
    print('✔ 메뉴가 길면 밀어서 보기')
    # 1) 메뉴 줄 순서
    a = "                _TopBar(p: p),\n"
    b = "                _BrandCard(p: p),\n"
    if text.count(a) != 1 or text.count(b) != 1 or text.find(a) > text.find(b):
        print('❌ 메뉴 줄 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    s, e = text.find(a), text.find(b) + len(b)
    text = text[:s] + NEW_CHILDREN + text[e:]
    print('✔ 메뉴 3묶음 + 종료 맨 아래')
    # 2-1) 메뉴 높이: 화면의 90%까지만 (맨 위 시계 줄을 덮지 않게)
    old = "      child: Container(\n        decoration: BoxDecoration(\n          color: p.sheet,\n"
    new = "      child: Container(\n        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),\n        decoration: BoxDecoration(\n          color: p.sheet,\n"
    if text.count(old) != 1:
        print('❌ 메뉴 높이 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(old, new)
    print('✔ 메뉴 높이 화면의 90%까지')
    # 4-1) 소개 카드를 검정으로, 아래 브랜드 카드 모양은 지우기 (소리 막대는 소개 카드가 씀)
    a = text.find("// 파란소리 소개 — 다른 메뉴와 살짝 다르게")
    b = text.find("// 흰 카드 하나에 줄들을 묶기")
    if a < 0 or b < 0 or b < a:
        print('❌ 소개 카드 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text[:a] + INTRO_NEW + text[b:]
    a = text.find("// 브랜드 영역 (문구 + 아주 은은한 음파 막대)")
    b = text.find("class _SoundBars extends StatefulWidget")
    if a < 0 or b < 0 or b < a:
        print('❌ 브랜드 카드 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text[:a] + "// 작은 소리 막대 (소개 카드)\n" + text[b:]
    print('✔ 소개 카드 검정으로 · 아래 브랜드 카드 빼기')
    # 3) 묶음 제목
    old = "\n// 손잡이 + 닫기(X)"
    if text.count(old) != 1:
        print('❌ 묶음 제목 넣을 자리를 못 찾았어요 — 아무것도 저장 안 했어요')
        sys.exit(1)
    text = text.replace(old, GROUP_CAP)
    print('✔ 묶음 제목 모양')
    out.append((MENU, text, crlf))
    # 4) 번역 23개
    for lang, caps in CAPS.items():
        p = os.path.join(L10N, 'app_%s.arb' % lang)
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        t, c = load(p)
        lines = t.split('\n')
        hit = [i for i, l in enumerate(lines) if l.strip().startswith('"darkMode":')]
        if len(hit) != 1 or not lines[hit[0]].rstrip().endswith(','):
            print('❌', os.path.basename(p), 'darkMode 줄을 못 찾았어요 — 아무것도 저장 안 했어요')
            sys.exit(1)
        ind = lines[hit[0]][:len(lines[hit[0]]) - len(lines[hit[0]].lstrip())]
        add = ['%s"%s": %s,' % (ind, k, json.dumps(v, ensure_ascii=False)) for k, v in zip(KEYS, caps)]
        lines[hit[0] + 1:hit[0] + 1] = add
        t = '\n'.join(lines)
        try:
            d = json.loads(t)
            assert all(d[k] == v for k, v in zip(KEYS, caps))
        except Exception as ex:
            print('❌', os.path.basename(p), '번역 파일 모양 확인 실패:', ex, '— 아무것도 저장 안 했어요')
            sys.exit(1)
        out.append((p, t, c))
        print('✔', os.path.basename(p), '→', ' / '.join(caps))
    for p, t, c in out:
        if c:
            t = t.replace('\n', '\r\n')
        with open(p, 'wb') as f:
            f.write(t.encode('utf-8'))
    print('✔ 저장했어요 (%d개 파일)' % len(out))


main()
