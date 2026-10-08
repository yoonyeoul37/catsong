# -*- coding: utf-8 -*-
# 설정 화면 B안: 맨 위 Paransori 카드 + 자주 켜고 끄는 3칸 + 포인트 색 동그라미 10개 + 아이콘 베이지 칸
import os, re, sys
P = os.path.join('lib', 'screens', 'settings_screen.dart')
if not os.path.exists(P):
    sys.exit('❌ settings_screen.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_heroCard' in s:
    sys.exit('이미 적용돼 있어요.')

def rep(pattern, new, name, regex=False):
    global s
    if regex:
        m = list(re.finditer(pattern, s, re.S))
        if len(m) != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({len(m)}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s[:m[0].start()] + new + s[m[0].end():]
    else:
        n = s.count(pattern)
        if n != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s.replace(pattern, new)
    print(f'✔ {name}')

# 1) 글꼴 불러오기
rep("import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';\n", '불러오기')

# 2) 아이콘 칸 색 + 아이콘 칸
rep("Color _sInputBg(bool d) =>",
    "Color _sIconBg(bool d) => d ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5);\n"
    "/// 메뉴와 같은 아이콘 베이지 칸\n"
    "Widget _iconBox(IconData icon, bool d) => Container(\n"
    "      width: 30,\n"
    "      height: 30,\n"
    "      decoration: BoxDecoration(color: _sIconBg(d), borderRadius: BorderRadius.circular(9)),\n"
    "      child: Icon(icon, size: 17, color: _sTextSub(d)),\n"
    "    );\n"
    "Color _sInputBg(bool d) =>", '아이콘 칸')

# 3) 줄마다 아이콘 → 베이지 칸
rep("                  Icon(icon, color: _sTextHint(isDarkMode), size: 20),\n                  const SizedBox(width: 14),\n",
    "                  _iconBox(icon, isDarkMode),\n                  const SizedBox(width: 12),\n", '줄 아이콘')
rep("Container(height: 0.5, margin: const EdgeInsets.only(left: 50), color: _sBorder(isDarkMode)),",
    "Container(height: 0.5, margin: const EdgeInsets.only(left: 58), color: _sBorder(isDarkMode)),", '구분선 자리')

# 4) 목록 전체 새로
NEW = r"""          // ── 맨 위: Paransori 카드 + 자주 켜고 끄는 3칸 ──
          _heroCard(isDarkMode),
          Consumer<ThemeProvider>(builder: (context, t, _) => _quickTiles(t)),
          // ── 꾸미기 ──
          _buildSection('꾸미기'),
          Consumer<ThemeProvider>(builder: (context, t, _) => _pointColorTile(t)),
          _buildTile(context, icon: Icons.style_outlined, title: l.playerStyle, onTap: () => _showPlayerStyleDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.font_download_outlined, title: l.fontChange, onTap: () => _showFontDialog(context), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.text_fields, title: l.textSize, onTap: () => _showTextSizeDialog(context), primaryColor: primaryColor, isLast: true),
          // ── 음악 관리 ──
          _buildSection('음악 관리'),
          _buildTile(context, icon: Icons.auto_awesome_outlined, title: '곡 정보 한꺼번에 정리',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCleanScreen())),
              primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.photo_library_outlined, title: '앨범 사진 한꺼번에 찾기',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkArtScreen())),
              primaryColor: primaryColor, isLast: true),
          // ── 도구 ──
          _buildSection('도구'),
          _buildTile(context, icon: Icons.equalizer, title: l.equalizer, onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const EqualizerScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child), transitionDuration: const Duration(milliseconds: 250))), primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.music_note_outlined, title: l.ringtone, onTap: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const RingtoneScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child), transitionDuration: const Duration(milliseconds: 250))), primaryColor: primaryColor),
          _buildTile(context, icon: _isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off, title: l.flashlight, subtitle: _isFlashlightOn ? l.on : l.off, onTap: () => _toggleFlashlight(context), primaryColor: primaryColor,
              trailing: Switch(value: _isFlashlightOn, onChanged: (_) => _toggleFlashlight(context), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.emergency, title: l.sos, subtitle: _isSosOn ? l.sosWorking : l.sos, onTap: () => _toggleSOS(context), primaryColor: primaryColor,
              trailing: Switch(value: _isSosOn, onChanged: (_) => _toggleSOS(context), activeColor: Colors.redAccent, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          _buildTile(context, icon: Icons.widgets_outlined, title: l.widget, onTap: () async {
            const platform = MethodChannel('kr.ssing.catsong/media');
            try { await platform.invokeMethod('requestWidgetAdd'); } catch (e) {}
          }, primaryColor: primaryColor, isLast: true),
          // ── 기타 ──
          _buildSection('기타'),
          _buildTile(context, icon: Icons.card_giftcard_outlined, title: l.promoCode, onTap: () async {
            await _showPromoCodeDialog(context);
            if (mounted) setState(() {}); // 맨 위 카드 글자도 바로 바뀌게
          }, primaryColor: primaryColor, isFirst: true),
          _buildTile(context, icon: Icons.star_outline, title: l.rateApp, onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=kr.ssing.catsong'), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.privacy_tip_outlined, title: l.privacyPolicy, onTap: () => _launchUrl(l.privacyPolicyUrl), primaryColor: primaryColor),
          _buildTile(context, icon: Icons.description_outlined, title: l.termsOfService, onTap: () => _launchUrl(l.termsOfServiceUrl), primaryColor: primaryColor, isLast: true),
"""
rep(r"          _buildSection\(l\.themeColor\),\n.*?(?=          const SizedBox\(height: 24\),\n)", NEW, '목록 새로', regex=True)

# 5) 새 부품들 (맨 위 카드 · 3칸 · 포인트 색)
PARTS = r"""  // ───────── B안 부품 ─────────

  /// 버전 + 광고 제거 여부
  Future<(String, bool)> _heroInfo() async {
    final v = await _getAppVersion();
    final p = await SharedPreferences.getInstance();
    return (v, p.getBool('promo_unlocked') ?? false);
  }

  /// 맨 위 먹색 Paransori 카드 (다크 모드는 크림색) — 누르면 프로모션 코드
  Widget _heroCard(bool isDark) {
    final bg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    return FutureBuilder<(String, bool)>(
      future: _heroInfo(),
      builder: (context, snap) {
        final v = snap.data?.$1 ?? '';
        final noAd = snap.data?.$2 ?? false;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await _showPromoCodeDialog(context);
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                  text: 'Paran',
                                  style: TextStyle(color: isDark ? const Color(0xFF2589E8) : const Color(0xFF7FB8F0))),
                              const TextSpan(text: 'sori'),
                            ]),
                            style: GoogleFonts.quicksand(
                                color: fg, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${noAd ? '광고 없이 듣고 계세요' : '음악 · 라디오 · 자연'}${v.isEmpty ? '' : '  ·  $v'}',
                            style: TextStyle(color: fg.withOpacity(0.65), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 자주 켜고 끄는 3칸 (누르면 바로 켜짐/꺼짐)
  Widget _quickTiles(ThemeProvider t) {
    final d = t.isDarkMode;
    Widget tile(IconData icon, String label, bool on, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
              decoration: BoxDecoration(color: _sCard(d), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: on ? _sText(d) : _sIconBg(d),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: on ? _sBg(d) : _sTextSub(d)),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _sText(d), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(on ? '켜짐' : '꺼짐', style: TextStyle(color: _sTextHint(d), fontSize: 11)),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          tile(Icons.dark_mode_outlined, '다크 모드', t.isDarkMode, () => t.setDarkMode(!t.isDarkMode)),
          const SizedBox(width: 8),
          tile(Icons.water_drop_outlined, '효과음', t.feedbackSoundEnabled,
              () => t.setFeedbackSoundEnabled(!t.feedbackSoundEnabled)),
          const SizedBox(width: 8),
          tile(Icons.record_voice_over_outlined, '음성 안내', t.voiceGreetingEnabled,
              () => t.setVoiceGreetingEnabled(!t.voiceGreetingEnabled)),
        ],
      ),
    );
  }

  /// 포인트 색: 이름 + 아래 동그라미 10개 (누르면 바로 바뀜, 폰 크기에 맞춰 한 줄)
  Widget _pointColorTile(ThemeProvider t) {
    final d = t.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: _sCard(d),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(Icons.palette_outlined, d),
              const SizedBox(width: 12),
              Expanded(child: Text('포인트 색', style: TextStyle(color: _sText(d), fontSize: 14.5))),
              Text(t.pointColorName ?? '', style: TextStyle(color: _sTextHint(d), fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Row(
              children: [
                for (var i = 0; i < ThemeProvider.pointColors.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 28),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              t.setPrimaryColor(ThemeProvider.pointColors[i].$2);
                            },
                            child: Builder(builder: (_) {
                              final c = ThemeProvider.pointColors[i].$2;
                              final on = t.primaryColor.value == c.value;
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: on ? _sCard(d) : c,
                                  border: on ? Border.all(color: _sText(d), width: 2) : null,
                                ),
                                padding: on ? const EdgeInsets.all(3) : EdgeInsets.zero,
                                child: on
                                    ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c))
                                    : null,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {"""
rep("  Widget _buildSection(String title) {", PARTS, '새 부품')

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)
print('\n✅ 끝! 설정 화면이 B안으로 바뀌었어요.')
