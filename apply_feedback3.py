# 파란소리: 알림 바꾸기 3묶음 (마지막)
# (자르기·벨소리·설정·재생화면·라디오·수면 타이머·예약·TV·자연소리·곡 정보 정리·앨범 사진)
# 실행: C:\apps\mp3_player_new 에서  python apply_feedback3.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_feedback3 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/ringtone_screen.dart", "import '../l10n/app_localizations.dart';\n", "import '../l10n/app_localizations.dart';\nimport '../widgets/action_feedback.dart';\nimport '../widgets/paran_toast.dart';\n"], ["str", "screens/ringtone_screen.dart", "      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(\n        content: Text('mp3, m4a 파일만 자를 수 있어요'),\n        backgroundColor: Colors.redAccent,\n      ));", "      showParanToast(context, 'mp3, m4a 파일만 자를 수 있어요');"], ["str", "screens/ringtone_screen.dart", "        ScaffoldMessenger.of(context).showSnackBar(SnackBar(\n          content: Text('저장했어요: ${saved.split('/').last}'),\n          backgroundColor: Colors.green,\n          duration: const Duration(seconds: 3),\n        ));\n      } else {\n        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(\n          content: Text('자르기에 실패했어요'),\n          backgroundColor: Colors.redAccent,\n          duration: Duration(seconds: 3),\n        ));\n      }\n    } catch (e) {\n      if (!context.mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar(SnackBar(\n        content: Text('Error: $e'),\n        backgroundColor: Colors.redAccent,\n      ));\n    }", "        showActionFeedback(context, type: ActionFeedbackType.saved, message: '잘랐어요', icon: Icons.content_cut_rounded);\n      } else {\n        showParanToast(context, '자르기에 실패했어요', error: true);\n      }\n    } catch (e) {\n      if (!context.mounted) return;\n      showParanToast(context, '자르기에 실패했어요', error: true);\n    }"], ["str", "screens/ringtone_screen.dart", "        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(AppLocalizations.of(context)!.ringtoneSet),\n            backgroundColor: Colors.green,\n            duration: const Duration(seconds: 3),\n          ),\n        );", "        showActionFeedback(context,\n            type: ActionFeedbackType.saved, message: '벨소리로 지정했어요', icon: Icons.notifications_active_rounded);"], ["str", "screens/ringtone_screen.dart", "        ScaffoldMessenger.of(context).showSnackBar(\n          const SnackBar(\n            content: Text('\"시스템 설정 변경\"을 허용으로 켜고 돌아와서 다시 눌러주세요'),\n            backgroundColor: Color(0xFFE09A2B),\n            duration: Duration(seconds: 5),\n          ),\n        );", "        showParanToast(context, '\"시스템 설정 변경\"을 허용으로 켜고 돌아와서 다시 눌러주세요',\n            duration: const Duration(seconds: 5));"], ["str", "screens/ringtone_screen.dart", "        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(AppLocalizations.of(context)!.ringtoneFailed),\n            backgroundColor: Colors.redAccent,\n            duration: const Duration(seconds: 3),\n          ),\n        );", "        showParanToast(context, AppLocalizations.of(context)!.ringtoneFailed, error: true);"], ["str", "screens/ringtone_screen.dart", "      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Error: $e'),\n          backgroundColor: Colors.redAccent,\n          duration: const Duration(seconds: 3),\n        ),\n      );", "      showParanToast(context, '벨소리를 지정하지 못했어요', error: true);"], ["str", "screens/settings_screen.dart", "import '../l10n/app_localizations.dart';\n", "import '../l10n/app_localizations.dart';\nimport '../widgets/paran_toast.dart';\n"], ["str", "screens/settings_screen.dart", "      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.flashlightError}: $e'), backgroundColor: Colors.grey[800], duration: const Duration(seconds: 2)));", "      showParanToast(context, AppLocalizations.of(context)!.flashlightError, error: true);"], ["str", "screens/settings_screen.dart", "                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.promoUnlocked), backgroundColor: accent, duration: const Duration(seconds: 3)));", "                      showParanToast(context, AppLocalizations.of(context)!.promoUnlocked);"], ["str", "screens/settings_screen.dart", "                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.promoInvalid), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 2)));", "                      showParanToast(context, AppLocalizations.of(context)!.promoInvalid, error: true);"], ["str", "screens/player_screen.dart", "import '../widgets/action_feedback.dart';\n", "import '../widgets/action_feedback.dart';\nimport '../widgets/paran_toast.dart';\n"], ["str", "screens/player_screen.dart", "                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(\n                                  content: Text('TV로 보내지 못했어요. 다시 시도해 주세요.'),\n                                ));", "                                showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);"], ["str", "screens/player_screen.dart", "                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(\n                            content: Text(\n                                AppLocalizations.of(context)!.autoStopFormat(timeLabel),\n                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),\n                            backgroundColor: primaryColor,\n                            duration: const Duration(seconds: 2),\n                          ));", "                          showParanToast(context, AppLocalizations.of(context)!.autoStopFormat(timeLabel));"], ["str", "screens/player_screen.dart", "                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(\n                            content: Text(\n                                AppLocalizations.of(context)!.autoStopFormat(timeLabel),\n                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),\n                            backgroundColor: widget.primaryColor,\n                            duration: const Duration(seconds: 2),\n                          ));", "                          showParanToast(context, AppLocalizations.of(context)!.autoStopFormat(timeLabel));"], ["str", "screens/radio_player_screen.dart", "import '../widgets/exit_confirm_dialog.dart';\n", "import '../widgets/exit_confirm_dialog.dart';\nimport '../widgets/paran_toast.dart';\n"], ["str", "screens/radio_player_screen.dart", "      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(\n        content: Text('방송이 나오고 있을 때 TV로 보낼 수 있어요'),\n      ));", "      showParanToast(context, '방송이 나오고 있을 때 TV로 보낼 수 있어요');"], ["region", "screens/radio_player_screen.dart", "radioAddedToFavoritesToast", "final overlay = Overlay.of(context);", "() => entry.remove());", "// (하트가 바로 바뀌어서 따로 알림 없음)"], ["region", "screens/radio_korea_screen2.dart", "radioAddedToFavoritesToast", "final overlay = Overlay.of(context);", "() => entry.remove());", "// (하트가 바로 바뀌어서 따로 알림 없음)"], ["region", "screens/radio_country_stations_screen.dart", "radioAddedToFavoritesToast", "final overlay = Overlay.of(context);", "() => entry.remove());", "// (하트가 바로 바뀌어서 따로 알림 없음)"], ["str", "screens/radio_favorites_screen.dart", "import '../l10n/app_localizations.dart';\n", "import '../l10n/app_localizations.dart';\nimport '../widgets/action_feedback.dart';\n"], ["str", "screens/radio_favorites_screen.dart", "              final messenger = ScaffoldMessenger.of(context);\n              final removedText = AppLocalizations.of(context)!.radioRemovedFromFavorites;\n              messenger.showSnackBar(\n                SnackBar(\n                  content: Text(removedText),\n                  backgroundColor: AppTheme.surfaceVariant,\n                  duration: const Duration(seconds: 2),\n                ),\n              );", "              showActionFeedback(context, type: ActionFeedbackType.deleted, message: '즐겨찾기에서 뺐어요');"], ["region", "screens/radio_favorites_screen.dart", "const Icon(CupertinoIcons.heart, color: Colors.black38, size: 18)", "final overlay = Overlay.of(context);", "() => entry.remove());", "showActionFeedback(context, type: ActionFeedbackType.deleted, message: '즐겨찾기에서 뺐어요');"], ["str", "widgets/sleep_timer_sheet.dart", "import '../l10n/app_localizations.dart';\n", "import '../l10n/app_localizations.dart';\nimport 'paran_toast.dart';\n"], ["region", "widgets/sleep_timer_sheet.dart", "sleepAutoStopToast", "final overlay = Overlay.of(context);", "() => entry.remove());", "showParanToast(context, l.sleepAutoStopToast(_formatSelected(l, _selectedMinutes)));"], ["str", "widgets/schedule_sheet.dart", "import '../l10n/app_localizations.dart';\n", "import '../l10n/app_localizations.dart';\nimport 'action_feedback.dart';\nimport 'paran_toast.dart';\n"], ["region", "widgets/schedule_sheet.dart", "radioScheduleSetToast", "final overlay = Overlay.of(context);", "() => entry.remove());", "showActionFeedback(context, type: ActionFeedbackType.saved, message: '예약했어요', icon: Icons.schedule_rounded);"], ["str", "widgets/schedule_sheet.dart", "                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(\n                      content: Text(AppLocalizations.of(context)!.radioScheduleCompleteToast(title, fmt(start))),\n                      backgroundColor: primaryColor,\n                    ));", "                    showParanToast(context, AppLocalizations.of(context)!.radioScheduleCompleteToast(title, fmt(start)));"], ["str", "widgets/cast_sheets.dart", "import '../services/cast_service.dart';\n", "import '../services/cast_service.dart';\nimport 'paran_toast.dart';\n"], ["str", "widgets/cast_sheets.dart", "                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(\n                                content: Text('TV로 보내지 못했어요. 다시 시도해 주세요.'),\n                              ));", "                              showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);"], ["str", "screens/nature_sounds_screen.dart", "import 'nature_sound_detail_screen.dart';\n", "import 'nature_sound_detail_screen.dart';\nimport '../widgets/paran_toast.dart';\n"], ["str", "screens/nature_sounds_screen.dart", "        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(content: Text('재생 오류: $e')),\n        );", "        showParanToast(context, '소리를 재생하지 못했어요', error: true);"], ["str", "screens/edit_song_screen.dart", "import '../widgets/action_feedback.dart';\n", "import '../widgets/action_feedback.dart';\nimport '../widgets/paran_toast.dart';\n"], ["str", "screens/edit_song_screen.dart", "      ScaffoldMessenger.of(context)\n          .showSnackBar(const SnackBar(content: Text('인터넷에서 이 곡을 찾지 못했어요')));", "      showParanToast(context, '인터넷에서 이 곡을 찾지 못했어요');"], ["str", "screens/bulk_clean_screen.dart", "import '../utils/song_title_cleaner.dart';\n", "import '../utils/song_title_cleaner.dart';\nimport '../widgets/action_feedback.dart';\nimport '../widgets/paran_toast.dart';\n"], ["func", "screens/bulk_clean_screen.dart", "  Future<void> _undo()", "  Future<void> _undo() async {\n    if (_working) return;\n    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n    final music = context.read<MusicProvider>();\n    final navigator = Navigator.of(context);\n    setState(() => _working = true);\n    final n = await undoBulkClean(music);\n    if (!mounted) return;\n    showActionFeedback(context, type: ActionFeedbackType.edited, message: '$n곡을 되돌렸어요');\n    navigator.pop();\n  }"], ["str", "screens/bulk_clean_screen.dart", "    navigator.pop();\n    messenger.showSnackBar(SnackBar(\n      content: Text('${targets.length}곡을 깔끔하게 정리했어요'),\n      duration: const Duration(seconds: 8),\n      action: SnackBarAction(\n        label: '되돌리기',\n        onPressed: () async {\n          final n = await undoBulkClean(music);\n          messenger.showSnackBar(SnackBar(content: Text('$n곡을 원래대로 되돌렸어요')));\n        },\n      ),\n    ));", "    final appCtx = Navigator.of(context, rootNavigator: true).context;\n    navigator.pop();\n    // 되돌리기 버튼이 있어서 하단 알림으로\n    showParanToast(appCtx, '${targets.length}곡을 깔끔하게 정리했어요', actionLabel: '되돌리기', onAction: () async {\n      final n = await undoBulkClean(music);\n      showActionFeedback(appCtx, type: ActionFeedbackType.edited, message: '$n곡을 되돌렸어요');\n    });"], ["str", "screens/bulk_clean_screen.dart", "    final messenger = ScaffoldMessenger.of(context);\n    final navigator = Navigator.of(context);\n    setState(() {\n      _working = true;\n      _done = 0;\n    });", "    final navigator = Navigator.of(context);\n    setState(() {\n      _working = true;\n      _done = 0;\n    });"], ["str", "screens/bulk_art_screen.dart", "import '../services/music_lookup.dart';\n", "import '../services/music_lookup.dart';\nimport '../widgets/action_feedback.dart';\n"], ["str", "screens/bulk_art_screen.dart", "    navigator.pop();\n    messenger.showSnackBar(SnackBar(content: Text('$ok곡에 앨범 사진을 넣었어요')));", "    showActionFeedback(context, type: ActionFeedbackType.saved, message: '$ok곡에 사진을 넣었어요');\n    navigator.pop();"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_feedback3")

def func_span(s, sig):
    i = s.find(sig)
    if i < 0 or s.find(sig, i + 1) >= 0:
        return None
    j = s.find("{", i + len(sig))
    if j < 0:
        return None
    depth = 0
    k = j
    while k < len(s):
        c = s[k]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return (i, k + 1)
        k += 1
    return None

def main():
    if not os.path.isdir(LIB):
        print("[실패] lib 폴더를 못 찾았어요. 이 파일을 C:\\apps\\mp3_player_new 에 두고 실행해 주세요.")
        sys.exit(1)
    texts, newlines, problems = {}, {}, []
    for op in DATA["ops"]:
        kind, rel = op[0], op[1]
        if rel not in texts:
            p = os.path.join(LIB, rel)
            if not os.path.exists(p):
                problems.append(f"{rel}: 파일이 없어요")
                continue
            with open(p, "r", encoding="utf-8", newline="") as fh:
                raw = fh.read()
            newlines[rel] = "\r\n" if "\r\n" in raw else "\n"
            texts[rel] = raw.replace("\r\n", "\n")
    if not problems:
        # 미리 해보기 (진짜 파일은 아직 안 바꿈)
        trial = dict(texts)
        for op in DATA["ops"]:
            kind, rel = op[0], op[1]
            a = op[2]
            b = op[3] if len(op) > 3 else None
            s = trial[rel]
            if kind == "str":
                n = s.count(a)
                if n != 1:
                    problems.append(f"{rel}: '{a.strip().splitlines()[0][:60]}' → {n}군데 (1군데여야 해요)")
                    continue
                trial[rel] = s.replace(a, b, 1)
            elif kind == "region":
                key, start, end, repl = op[2], op[3], op[4], op[5]
                ki = s.find(key)
                if ki < 0 or s.find(key, ki + 1) >= 0:
                    problems.append(f"{rel}: '{key[:50]}' 를 못 찾았어요")
                    continue
                si = s.rfind(start, 0, ki)
                ei = s.find(end, ki)
                if si < 0 or ei < 0:
                    problems.append(f"{rel}: '{key[:50]}' 주변을 못 찾았어요")
                    continue
                ls = s.rfind("\n", 0, si) + 1
                indent = s[ls:si]
                le = s.find("\n", ei)
                le = len(s) if le < 0 else le + 1
                trial[rel] = s[:ls] + indent + repl + "\n" + s[le:]
            else:
                span = func_span(s, a)
                if span is None:
                    problems.append(f"{rel}: 함수 '{a.strip()[:60]}' 를 못 찾았어요")
                    continue
                trial[rel] = s[:span[0]] + b + s[span[1]:]
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
    for rel, s in trial.items():
        with open(os.path.join(LIB, rel), "w", encoding="utf-8", newline="") as fh:
            fh.write(s.replace("\n", "\r\n") if newlines[rel] == "\r\n" else s)
        print("[완료] 바꿨어요:", rel)
    for rel, content in DATA["new"].items():
        p = os.path.join(LIB, rel)
        if os.path.exists(p):
            print("[참고] 이미 있어서 그대로 둬요:", rel)
            continue
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8", newline="") as fh:
            fh.write(content.replace("\n", "\r\n"))
        print("[완료] 새로 만들었어요:", rel)
    print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
    print("   문제가 있으면 backup_feedback3 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
