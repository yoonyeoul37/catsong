# -*- coding: utf-8 -*-
# 이용약관·개인정보: 브라우저 대신 앱 안에서 열기 (폰·브라우저 다크 모드와 상관없이 앱 설정대로)
# 먼저 한 번:  flutter pub add webview_flutter
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
PATH = 'lib/screens/settings_screen.dart'
NEW_FILE = 'lib/screens/policy_web_screen.dart'
MARK = '_openPolicy('

NEW_CODE = r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/theme_provider.dart';

/// 이용약관 · 개인정보 — 앱 안에서 열기
/// 폰 브라우저(삼성 인터넷 등)의 다크 모드와 상관없이 앱의 다크/라이트 그대로 보여요
class PolicyWebScreen extends StatefulWidget {
  final String url;
  final String title;
  const PolicyWebScreen({super.key, required this.url, required this.title});

  @override
  State<PolicyWebScreen> createState() => _PolicyWebScreenState();
}

class _PolicyWebScreenState extends State<PolicyWebScreen> {
  late final WebViewController _c;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final dark = context.read<ThemeProvider>().isDarkMode;
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(dark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (req) {
          final u = req.url;
          // 페이지 안 "홈" 버튼 → 앱 첫 화면으로
          if (u.startsWith('intent://') || u.startsWith('paransori://')) {
            Navigator.of(context).popUntil((r) => r.isFirst);
            return NavigationDecision.prevent;
          }
          // 메일·다른 사이트는 앱 밖에서
          if (!u.startsWith('https://www.ssing.kr') && !u.startsWith('https://ssing.kr')) {
            launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication).catchError((_) => false);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  /// 뒤로: 페이지 안에서 옮겨 다녔으면 그 전 페이지로, 아니면 닫기
  Future<void> _back() async {
    if (await _c.canGoBack()) {
      await _c.goBack();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final bg = dark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final line = dark ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: _back,
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 18),
            ),
            title: Text(widget.title,
                style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: line)),
          ),
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                WebViewWidget(controller: _c),
                if (_loading)
                  Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

EDITS = [
('불러오기',
"""import 'settings_help_screen.dart';
""",
"""import 'settings_help_screen.dart';
import 'policy_web_screen.dart';
"""),
('개인정보 → 앱 안에서',
"""onTap: () => _launchUrl(_policyUrl('privacy_policy'))""",
"""onTap: () => _openPolicy('privacy_policy', l.privacyPolicy)"""),
('이용약관 → 앱 안에서',
"""onTap: () => _launchUrl(_policyUrl('terms_of_service'))""",
"""onTap: () => _openPolicy('terms_of_service', l.termsOfService)"""),
('앱 안에서 여는 함수',
"""  Future<void> _launchUrl(String url) async {""",
"""  /// 약관은 앱 안에서 열기 (폰 브라우저의 다크 모드와 상관없이 앱 설정대로)
  void _openPolicy(String page, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyWebScreen(url: _policyUrl(page), title: title)));
  }

  Future<void> _launchUrl(String url) async {"""),
]

def main():
    if not os.path.exists('pubspec.yaml'):
        print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    if 'webview_flutter' not in open('pubspec.yaml', encoding='utf-8').read():
        print('❌ 먼저 이걸 실행해 주세요:  flutter pub add webview_flutter'); return
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ settings_screen.dart 를 못 찾았어요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    for o, c in ('{}', '()', '[]'):
        if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
            print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    if not os.path.exists(NEW_FILE):
        open(NEW_FILE, 'wb').write((NEW_CODE.replace('\n', '\r\n') if crlf else NEW_CODE).encode('utf-8'))
        print('✔ 새 파일 만들었어요: policy_web_screen.dart')
    print('저장했어요 ✔')

main()
