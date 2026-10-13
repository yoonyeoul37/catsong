# 종료창을 원래대로 (오늘 넣은 '소리는 켜 두고 나가기' 줄 · 질문 창 빼기)
# exit_confirm_dialog.dart 를 오늘 고치기 전 내용으로 되돌림
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")
hits = []
for d, dirs, files in os.walk(os.path.join(ROOT, "lib")):
    dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
    if "exit_confirm_dialog.dart" in files:
        hits.append(os.path.normpath(os.path.join(d, "exit_confirm_dialog.dart")))
if len(hits) != 1:
    print("❌ exit_confirm_dialog.dart 을(를) " + ("못 찾았어요" if not hits else "여러 개 찾았어요"))
    sys.exit(1)
p = hits[0]
raw = open(p, "rb").read().decode("utf-8")

ORIG = 'import \'package:flutter/material.dart\';\nimport \'package:flutter/services.dart\';\nimport \'package:provider/provider.dart\';\nimport \'../providers/theme_provider.dart\';\nimport \'../l10n/app_localizations.dart\';\nimport \'photo_dialog.dart\' show ParanBanner;\n\n/// 종료 확인창 (홈·음악·라디오·자연소리 공통)\n/// 위: 그림(아래로 스며듦) + 경계 가운데 Paransori / 가운데: "종료하시겠어요?" / 아래: 계속 듣기 · 종료\n/// 종료를 누르면 true\nFuture<bool> showExitConfirm(BuildContext context) async {\n  const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n  final isDark = context.read<ThemeProvider>().isDarkMode;\n  final l = AppLocalizations.of(context)!;\n  final primary = Theme.of(context).colorScheme.primary;\n  final ok = await showDialog<bool>(\n    context: context,\n    builder: (ctx) {\n      final bg = isDark ? const Color(0xFF2B2926) : Colors.white;\n      final titleColor = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n      final subColor = isDark ? const Color(0xFFB8B0A2) : const Color(0xFFA39C90);\n      return Dialog(\n        backgroundColor: bg,\n        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),\n        clipBehavior: Clip.antiAlias,\n        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          children: [\n            // 그림 + 경계 가운데 Paransori (업데이트·리뷰 창과 같은 부품)\n            ParanBanner(\n              image: isDark ? \'assets/exit_banner_night.jpg\' : \'assets/exit_banner.jpg\',\n              bg: bg,\n              isDark: isDark,\n            ),\n            Padding(\n              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),\n              child: Column(\n                children: [\n                  // 질문은 크고 굵게\n                  Text(\n                    \'종료하시겠어요?\',\n                    textAlign: TextAlign.center,\n                    style: TextStyle(\n                        color: titleColor, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),\n                  ),\n                  const SizedBox(height: 6),\n                  // 인사는 작고 연하게\n                  Text(\n                    l.musicExitConfirmMessage.replaceAll(\'.\', \'\'),\n                    textAlign: TextAlign.center,\n                    style: TextStyle(color: subColor, fontSize: 12.5),\n                  ),\n                  const SizedBox(height: 22),\n                  Row(\n                    children: [\n                      Expanded(\n                        child: SizedBox(\n                          height: 50,\n                          child: OutlinedButton(\n                            onPressed: () {\n                              const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n                              Navigator.pop(ctx, false);\n                            },\n                            style: OutlinedButton.styleFrom(\n                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF5A5348),\n                              backgroundColor: isDark ? const Color(0xFF353330) : Colors.white,\n                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2DACB)),\n                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                              // 살짝 떠 보이게 연한 그림자\n                              elevation: 3,\n                              shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.12),\n                            ),\n                            child: Text(l.radioExitKeepListening, style: const TextStyle(fontSize: 14.5)),\n                          ),\n                        ),\n                      ),\n                      const SizedBox(width: 10),\n                      Expanded(\n                        child: SizedBox(\n                          height: 50,\n                          child: ElevatedButton(\n                            onPressed: () {\n                              const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n                              Navigator.pop(ctx, true);\n                            },\n                            style: ElevatedButton.styleFrom(\n                              backgroundColor: primary,\n                              foregroundColor: Colors.white,\n                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                              // 파란빛 그림자로 떠 보이게\n                              elevation: 6,\n                              shadowColor: primary.withOpacity(0.45),\n                            ),\n                            child: Text(l.radioExitConfirmButton,\n                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),\n                          ),\n                        ),\n                      ),\n                    ],\n                  ),\n                ],\n              ),\n            ),\n          ],\n        ),\n      );\n    },\n  );\n  return ok == true;\n}'

if raw.replace("\r\n", "\n") == ORIG:
    print("이미 적용돼 있어요")
    sys.exit(0)
if "moveToBackground" not in raw or "showExitConfirm" not in raw:
    print("❌ 오늘 고친 종료창이 아니에요 (아무것도 저장 안 했어요)")
    sys.exit(1)
if "\r\n" in raw:
    ORIG = ORIG.replace("\n", "\r\n")
open(p, "wb").write(ORIG.encode("utf-8"))
print("✔ 종료창 원래대로 (작은 줄 뺌)")
print()
print("다 됐어요!")
