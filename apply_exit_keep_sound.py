# 종료창: 소리가 나오는 중이면 '소리는 켜 두고 나가기' 한 줄 더
# (화면만 닫고 음악·라디오·믹스는 계속 → 위젯·알림창으로 조작)
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")

hits = []
for d, dirs, files in os.walk(os.path.join(ROOT, "lib")):
    dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
    if "exit_confirm_dialog.dart" in files:
        hits.append(os.path.normpath(os.path.join(d, "exit_confirm_dialog.dart")))
if len(hits) != 1:
    print(f"❌ exit_confirm_dialog.dart 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
    sys.exit(1)
p = hits[0]
raw = open(p, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")

if "소리는 켜 두고 나가기" in s:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(old, new, what):
    global s, ok
    if s.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {s.count(old)}곳)")
        ok = False
        return
    s = s.replace(old, new)
    print(f"✔ {what}")


rep('''import '../providers/theme_provider.dart';
''', '''import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import '../providers/sound_mix_provider.dart';
''', "듣는 중인지 알아볼 파일 불러오기")

rep('''  final primary = Theme.of(context).colorScheme.primary;
  final ok = await showDialog<bool>(''', '''  final primary = Theme.of(context).colorScheme.primary;
  // 소리가 나오는 중인지 (그때만 '소리는 켜 두고 나가기' 보이기)
  var playing = false;
  try {
    final radio = context.read<RadioProvider>();
    playing = context.read<PlayerProvider>().isPlaying ||
        radio.isPlaying ||
        radio.isLoading ||
        context.read<SoundMixProvider>().isPlaying;
  } catch (_) {}
  final ok = await showDialog<bool>(''', "듣는 중인지 확인")

rep('''              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),''',
    '''              padding: EdgeInsets.fromLTRB(22, 10, 22, playing ? 12 : 22), // 한 줄 더 있으면 아래 여백 줄이기''',
    "아래 여백 맞추기")

rep('''                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );''', '''                    ],
                  ),
                  if (playing) ...[
                    const SizedBox(height: 6),
                    // 화면만 닫고 소리는 계속 (위젯·알림창으로 멈추기·다음)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton.icon(
                        onPressed: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          Navigator.pop(ctx, false);
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('moveToBackground');
                        },
                        style: TextButton.styleFrom(
                          // '계속 듣기' 버튼과 같은 글자색
                          foregroundColor: isDark ? Colors.white70 : const Color(0xFF5A5348),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.headphones_rounded, size: 17),
                        label: const Text('소리는 켜 두고 나가기',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );''', "'소리는 켜 두고 나가기' 줄 넣기")

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)
if crlf:
    s = s.replace("\n", "\r\n")
open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
