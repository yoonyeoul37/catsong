# 파란소리: 완료 알림 바꾸기 1묶음 (곡 목록·재생화면·홈 + 공통 부품)
# 실행: 프로젝트 맨 위 폴더(C:\apps\mp3_player_new)에서  python apply_feedback1.py
# - 바꾸기 전에 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일은 backup_feedback1 폴더에 원본을 저장해요 (되돌리기용)
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"edits": [["widgets/action_feedback.dart", "void showActionFeedback(BuildContext context, {required ActionFeedbackType type, String? message}) {\n  final overlay = Overlay.maybeOf(context, rootOverlay: true);", "void showActionFeedback(BuildContext context,\n    {required ActionFeedbackType type, String? message, IconData? icon}) {\n  if (!context.mounted) return; // 화면이 이미 닫혔으면 안 띄움\n  final overlay = Overlay.maybeOf(context, rootOverlay: true);"], ["widgets/action_feedback.dart", "    builder: (_) => _ActionFeedback(\n      type: type,\n      message: message,", "    builder: (_) => _ActionFeedback(\n      type: type,\n      message: message,\n      icon: icon,"], ["widgets/action_feedback.dart", "  final String? message;\n  final bool isDark;\n  final VoidCallback onDone;\n  const _ActionFeedback({required this.type, this.message, required this.isDark, required this.onDone});", "  final String? message;\n  final IconData? icon; // 자르기·벨소리·잠금처럼 다른 아이콘이 필요할 때\n  final bool isDark;\n  final VoidCallback onDone;\n  const _ActionFeedback(\n      {required this.type, this.message, this.icon, required this.isDark, required this.onDone});"], ["widgets/action_feedback.dart", "                        Icon(icon, color: iconColor, size: 52),", "                        Icon(widget.icon ?? icon, color: iconColor, size: 52),"], ["widgets/song_list_tile.dart", "import 'menu_parts.dart';\n", "import 'menu_parts.dart';\nimport 'action_feedback.dart';\nimport 'paran_toast.dart';\n"], ["widgets/song_list_tile.dart", "        playerProvider.addToPlayNext(song);\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(AppLocalizations.of(context)!.addedToQueue),\n            backgroundColor: AppTheme.surfaceVariant,\n            duration: const Duration(seconds: 2),\n          ),\n        );\n        break;", "        playerProvider.addToPlayNext(song); // (메뉴 안에 \"추가됨 ✓\"가 떠서 따로 알림 없음)\n        break;"], ["widgets/song_list_tile.dart", "        musicProvider.toggleFavorite(song);\n        final isFav = musicProvider.isFavorite(song.id);\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(\n              isFav ? '즐겨찾기에 추가됐습니다' : '즐겨찾기에서 제거됐습니다',\n              style: const TextStyle(color: Colors.white),\n            ),\n            backgroundColor: AppTheme.surfaceVariant,\n            duration: const Duration(seconds: 2),\n          ),\n        );", "        musicProvider.toggleFavorite(song); // (하트가 바로 바뀌어서 따로 알림 없음)"], ["widgets/song_list_tile.dart", "                  playlistProvider.addSongToPlaylist(playlist.id, song);\n                  Navigator.pop(ctx);\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(\n                      content: Text('${playlist.name} ${AppLocalizations.of(context)!.addedToPlaylist}'),\n                      backgroundColor: AppTheme.surfaceVariant,\n                      duration: const Duration(seconds: 2),\n                    ),\n                  );", "                  playlistProvider.addSongToPlaylist(playlist.id, song);\n                  Navigator.pop(ctx);\n                  showActionFeedback(context, type: ActionFeedbackType.added, message: '재생목록에 추가했어요');"], ["widgets/song_list_tile.dart", "                  if (result == true) {\n                    context.read<MusicProvider>().loadSongs();\n                    ScaffoldMessenger.of(context).showSnackBar(\n                      SnackBar(\n                        content: Text(AppLocalizations.of(context)!.deleted),\n                        backgroundColor: Colors.redAccent,\n                        duration: Duration(seconds: 2),\n                      ),\n                    );\n                  } else {\n                    ScaffoldMessenger.of(context).showSnackBar(\n                      SnackBar(\n                        content: Text(AppLocalizations.of(context)!.deleteFailed),\n                        backgroundColor: Colors.redAccent,\n                        duration: Duration(seconds: 2),\n                      ),\n                    );\n                  }\n                }\n              } catch (e) {\n                ScaffoldMessenger.of(context).showSnackBar(\n                  SnackBar(\n                    content: Text('삭제 실패: $e'),\n                    backgroundColor: Colors.redAccent,\n                    duration: const Duration(seconds: 2),\n                  ),\n                );\n              }", "                  if (result == true) {\n                    showActionFeedback(context, type: ActionFeedbackType.deleted); // 🗑 삭제했어요\n                    context.read<MusicProvider>().loadSongs();\n                  } else {\n                    showParanToast(context, AppLocalizations.of(context)!.deleteFailed, error: true);\n                  }\n                }\n              } catch (e) {\n                showParanToast(context, '삭제하지 못했어요', error: true);\n              }"], ["screens/player_screen.dart", "import '../widgets/menu_parts.dart';\n", "import '../widgets/menu_parts.dart';\nimport '../widgets/action_feedback.dart';\n"], ["screens/player_screen.dart", "                  playlistProvider.addSongToPlaylist(playlist.id, song);\n                  Navigator.pop(ctx);\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(\n                      content: Text('${playlist.name} ${AppLocalizations.of(context)!.addedToPlaylist}'),\n                      backgroundColor: AppTheme.surfaceVariant,\n                      duration: const Duration(seconds: 2),\n                    ),\n                  );", "                  playlistProvider.addSongToPlaylist(playlist.id, song);\n                  Navigator.pop(ctx);\n                  showActionFeedback(context, type: ActionFeedbackType.added, message: '재생목록에 추가했어요');"], ["screens/home_screen.dart", "import '../widgets/index_bar.dart';\n", "import '../widgets/index_bar.dart';\nimport '../widgets/action_feedback.dart';\nimport '../widgets/paran_toast.dart';\n"], ["screens/home_screen.dart", "              if (context.mounted) {\n                ScaffoldMessenger.of(context).showSnackBar(\n                  SnackBar(\n                    content: Text(AppLocalizations.of(context)!.deletedCount(successCount)),\n                    backgroundColor: Colors.redAccent,\n                    duration: const Duration(seconds: 2),\n                  ),\n                );\n              }", "              if (context.mounted) {\n                if (successCount > 0) {\n                  showActionFeedback(context,\n                      type: ActionFeedbackType.deleted, message: '$successCount곡을 삭제했어요');\n                } else {\n                  showParanToast(context, '삭제하지 못했어요', error: true);\n                }\n              }"], ["screens/home_screen.dart", "                      ScaffoldMessenger.of(context)\n                        ..hideCurrentSnackBar()\n                        ..showSnackBar(SnackBar(\n                          content: Text(next ? '가수 이름순으로 정렬했어요' : '제목순으로 정렬했어요'),\n                          duration: const Duration(milliseconds: 1200),\n                        ));", "                      showParanToast(context, next ? '가수 이름순으로 정렬했어요' : '제목순으로 정렬했어요',\n                          duration: const Duration(milliseconds: 1500));"]], "new": {"widgets/paran_toast.dart": "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';\nimport '../providers/theme_provider.dart';\n\n/// 파란소리 하단 알림 (오류·안내·되돌리기용) — 앱 전체가 같은 모양\n/// - 안내: showParanToast(context, '마이크 권한이 필요해요');\n/// - 오류: showParanToast(context, 'TV로 보내지 못했어요', error: true);\n/// - 되돌리기: showParanToast(context, '37곡을 정리했어요', actionLabel: '되돌리기', onAction: () {...});\nvoid showParanToast(\n  BuildContext context,\n  String message, {\n  bool error = false,\n  String? actionLabel,\n  VoidCallback? onAction,\n  Duration? duration,\n}) {\n  if (!context.mounted) return;\n  final messenger = ScaffoldMessenger.maybeOf(context);\n  if (messenger == null) return;\n  var isDark = false;\n  try {\n    isDark = context.read<ThemeProvider>().isDarkMode;\n  } catch (_) {}\n  const blue = Color(0xFF2589E8);\n  const red = Color(0xFFE05A4F);\n  final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n\n  messenger\n    ..hideCurrentSnackBar()\n    ..showSnackBar(SnackBar(\n      behavior: SnackBarBehavior.floating,\n      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),\n      padding: EdgeInsets.fromLTRB(16, 12, actionLabel != null ? 6 : 16, 12),\n      elevation: 6,\n      backgroundColor: isDark ? const Color(0xFF2A251E) : Colors.white,\n      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n      // 버튼이 있으면 누를 시간을 넉넉하게\n      duration: duration ?? Duration(seconds: actionLabel != null ? 8 : 3),\n      content: Row(\n        children: [\n          Icon(error ? Icons.error_outline_rounded : Icons.info_outline_rounded,\n              color: error ? red : blue, size: 20),\n          const SizedBox(width: 10),\n          Expanded(\n            child: Text(message,\n                style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500, height: 1.35)),\n          ),\n        ],\n      ),\n      action: actionLabel == null\n          ? null\n          : SnackBarAction(label: actionLabel, textColor: blue, onPressed: onAction ?? () {}),\n    ));\n}\n"}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_feedback1")

def read(rel):
    with open(os.path.join(LIB, rel), "r", encoding="utf-8", newline="") as f:
        return f.read()

def main():
    if not os.path.isdir(LIB):
        print("[실패] lib 폴더를 못 찾았어요. 이 파일을 C:\\apps\\mp3_player_new 에 두고 실행해 주세요.")
        sys.exit(1)
    texts, newlines, problems = {}, {}, []
    for rel, old, new in DATA["edits"]:
        if rel not in texts:
            if not os.path.exists(os.path.join(LIB, rel)):
                problems.append(f"{rel}: 파일이 없어요")
                continue
            raw = read(rel)
            newlines[rel] = "\r\n" if "\r\n" in raw else "\n"
            texts[rel] = raw.replace("\r\n", "\n")
        n = texts[rel].count(old)
        if n != 1:
            first = old.strip().splitlines()[0][:60]
            problems.append(f"{rel}: '{first}' → {n}군데 (1군데여야 해요)")
    if problems:
        print("[실패] 아래 곳을 못 찾아서 아무것도 안 바꿨어요. 이 내용을 그대로 보내주세요:")
        for p in problems:
            print("   -", p)
        sys.exit(1)

    os.makedirs(BACKUP, exist_ok=True)
    for rel in texts:
        dst = os.path.join(BACKUP, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(os.path.join(LIB, rel), dst)

    for rel, old, new in DATA["edits"]:
        texts[rel] = texts[rel].replace(old, new, 1)
    for rel, s in texts.items():
        with open(os.path.join(LIB, rel), "w", encoding="utf-8", newline="") as f:
            f.write(s.replace("\n", newlines[rel]) if newlines[rel] == "\r\n" else s)
        print("[완료] 바꿨어요:", rel)

    for rel, content in DATA["new"].items():
        p = os.path.join(LIB, rel)
        if os.path.exists(p):
            print("[참고] 이미 있어서 그대로 둬요:", rel)
            continue
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8", newline="") as f:
            f.write(content.replace("\n", "\r\n"))
        print("[완료] 새로 만들었어요:", rel)

    print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
    print("   문제가 있으면 backup_feedback1 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
