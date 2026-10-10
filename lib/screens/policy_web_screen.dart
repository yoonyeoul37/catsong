import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
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
    // 글자 크기: 폰 글꼴 크기 설정 때문에 커지지 않게 (브라우저에서 보던 크기 그대로)
    final p = _c.platform;
    if (p is AndroidWebViewController) p.setTextZoom(100);
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
          // 위쪽 줄 없이 페이지 머리(홈·언어)만 · 뒤로는 폰 뒤로가기
          body: SafeArea(
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
