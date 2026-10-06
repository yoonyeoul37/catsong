# 파란소리: 화면 통일 2: 이퀄라이저 (베이지 바탕·흰 카드·먹색 버튼)
# 실행: C:\apps\mp3_player_new 에서  python apply_screen2.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_screen2 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/equalizer_screen.dart", "import '../widgets/action_feedback.dart';\n", "import '../widgets/action_feedback.dart';\nimport 'package:provider/provider.dart';\nimport '../providers/theme_provider.dart';\n"], ["func", "screens/equalizer_screen.dart", "class EqualizerScreen extends StatelessWidget", "class EqualizerScreen extends StatelessWidget {\n  const EqualizerScreen({super.key});\n\n  static const _point = Color(0xFF2589E8); // 작은 포인트에만 (막대·숫자)\n\n  String _formatFreq(int mHz) {\n    final hz = mHz ~/ 1000; // 안드로이드는 밀리헤르츠로 줌\n    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';\n    return '$hz';\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final fx = SoundEffects.instance;\n    final l = AppLocalizations.of(context)!;\n    final c = _EqPal.of(context);\n\n    Widget card(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) => Container(\n          width: double.infinity,\n          margin: const EdgeInsets.symmetric(horizontal: 16),\n          padding: padding,\n          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),\n          child: child,\n        );\n\n    return Scaffold(\n      backgroundColor: c.bg,\n      appBar: AppBar(\n        backgroundColor: c.bg,\n        elevation: 0,\n        scrolledUnderElevation: 0,\n        titleSpacing: 0,\n        // 위 시계·배터리 + 아래 시스템 아이콘이 바탕색에서도 잘 보이게\n        systemOverlayStyle: SystemUiOverlayStyle(\n          statusBarColor: Colors.transparent,\n          statusBarIconBrightness: c.dark ? Brightness.light : Brightness.dark,\n          statusBarBrightness: c.dark ? Brightness.dark : Brightness.light,\n          systemNavigationBarColor: c.bg,\n          systemNavigationBarIconBrightness: c.dark ? Brightness.light : Brightness.dark,\n        ),\n        title: Text(l.equalizer,\n            style: TextStyle(color: c.ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n        leading: IconButton(\n          onPressed: () => Navigator.pop(context),\n          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.ink, size: 20),\n        ),\n      ),\n      // 버튼은 맨 아래에 모아서: 초기화(흰) · 지금 설정 저장(먹색)\n      bottomNavigationBar: SafeArea(\n        top: false,\n        child: Padding(\n          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),\n          child: Row(\n            children: [\n              Expanded(\n                child: SizedBox(\n                  height: 50,\n                  child: OutlinedButton(\n                    onPressed: () {\n                      HapticFeedback.selectionClick();\n                      fx.reset();\n                    },\n                    style: OutlinedButton.styleFrom(\n                      backgroundColor: c.card,\n                      foregroundColor: c.ink,\n                      side: BorderSide(color: c.line),\n                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                    ),\n                    child: Text(l.reset, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),\n                  ),\n                ),\n              ),\n              const SizedBox(width: 8),\n              Expanded(\n                flex: 2,\n                child: SizedBox(\n                  height: 50,\n                  child: ElevatedButton(\n                    onPressed: fx.ready ? () => _askSave(context, fx) : null,\n                    style: ElevatedButton.styleFrom(\n                      backgroundColor: c.ink,\n                      foregroundColor: c.bg,\n                      disabledBackgroundColor: c.ink.withOpacity(0.4),\n                      elevation: 6,\n                      shadowColor: Colors.black.withOpacity(0.25),\n                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                    ),\n                    child: const Text('지금 설정 저장', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n      body: AnimatedBuilder(\n        animation: fx,\n        builder: (context, _) {\n          if (!fx.ready) {\n            return Center(\n              child: Padding(\n                padding: const EdgeInsets.all(32),\n                child: Text('노래를 한 번 재생하면 이퀄라이저를 쓸 수 있어요',\n                    textAlign: TextAlign.center, style: TextStyle(color: c.sub)),\n              ),\n            );\n          }\n          return SingleChildScrollView(\n            padding: const EdgeInsets.only(bottom: 16),\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                // ───── 내 설정 (저장한 것) ─────\n                if (fx.custom.isNotEmpty) ...[\n                  _title(c, '내 설정'),\n                  card(Wrap(\n                    spacing: 6,\n                    runSpacing: 6,\n                    children: [\n                      for (final p in fx.custom)\n                        _chip(c, p.name, fx.label == p.name, () => fx.useCustom(p),\n                            onLong: () => _askDelete(context, fx, p)),\n                    ],\n                  )),\n                  Padding(\n                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),\n                    child: Text('길게 누르면 지울 수 있어요', style: TextStyle(color: c.sub, fontSize: 11.5)),\n                  ),\n                ],\n\n                // ───── 추천 설정 ─────\n                if (fx.devicePresets.isNotEmpty) ...[\n                  _title(c, l.preset),\n                  card(Wrap(\n                    spacing: 6,\n                    runSpacing: 6,\n                    children: [\n                      for (var i = 0; i < fx.devicePresets.length; i++)\n                        _chip(c, fx.devicePresets[i], fx.label == fx.devicePresets[i], () => fx.useDevicePreset(i)),\n                    ],\n                  )),\n                ],\n\n                // ───── 직접 맞추기 ─────\n                _title(c, '직접 맞추기'),\n                card(\n                  SizedBox(\n                    height: 240,\n                    child: Row(\n                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n                      crossAxisAlignment: CrossAxisAlignment.stretch,\n                      children: List.generate(fx.bands.length, (i) {\n                        final level = fx.bands[i];\n                        return Column(\n                          children: [\n                            Text('${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',\n                                style: const TextStyle(color: _point, fontSize: 11, fontWeight: FontWeight.w700)),\n                            Expanded(\n                              child: RotatedBox(\n                                quarterTurns: 3,\n                                child: SliderTheme(\n                                  data: _sliderTheme(context, c),\n                                  child: Slider(\n                                    value: level.clamp(fx.minLevel, fx.maxLevel).toDouble(),\n                                    min: fx.minLevel.toDouble(),\n                                    max: fx.maxLevel.toDouble(),\n                                    onChanged: (v) => fx.setBand(i, v.toInt()),\n                                  ),\n                                ),\n                              ),\n                            ),\n                            Text(i < fx.freqs.length ? _formatFreq(fx.freqs[i]) : '',\n                                style: TextStyle(color: c.sub, fontSize: 10.5)),\n                          ],\n                        );\n                      }),\n                    ),\n                  ),\n                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),\n                ),\n\n                // ───── 저음 강화 · 공간감 ─────\n                _title(c, '효과'),\n                card(Column(\n                  children: [\n                    _strength(context, c, Icons.speaker_outlined, l.bassBooster, l.enhancesBass, fx.bass, fx.setBass),\n                    Divider(color: c.line, height: 20),\n                    _strength(context, c, Icons.surround_sound_outlined, l.virtualizer, l.surroundEffect, fx.virt,\n                        fx.setVirt),\n                  ],\n                )),\n                // (울림은 폰마다 효과가 없거나 달라서 뺌 — 공간감으로 대신)\n              ],\n            ),\n          );\n        },\n      ),\n    );\n  }\n\n  SliderThemeData _sliderTheme(BuildContext context, _EqPal c) => SliderTheme.of(context).copyWith(\n        activeTrackColor: _point,\n        inactiveTrackColor: c.line,\n        thumbColor: _point,\n        overlayColor: _point.withOpacity(0.1),\n        trackHeight: 3,\n      );\n\n  /// 작은 회색 소제목\n  Widget _title(_EqPal c, String text) => Padding(\n        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),\n        child: Text(text, style: TextStyle(color: c.sub, fontSize: 12, fontWeight: FontWeight.w600)),\n      );\n\n  /// 고르는 칸 (고르면 먹색으로 채움 — 녹음 탭 칸과 같은 모양)\n  Widget _chip(_EqPal c, String label, bool selected, VoidCallback onTap, {VoidCallback? onLong}) {\n    return GestureDetector(\n      onTap: () {\n        HapticFeedback.selectionClick();\n        onTap();\n      },\n      onLongPress: onLong,\n      child: Container(\n        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),\n        decoration: BoxDecoration(\n          color: selected ? c.ink : c.bg,\n          borderRadius: BorderRadius.circular(12),\n        ),\n        child: Text(label,\n            style: TextStyle(\n              color: selected ? c.bg : c.sub,\n              fontSize: 12.5,\n              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,\n            )),\n      ),\n    );\n  }\n\n  Widget _strength(BuildContext context, _EqPal c, IconData icon, String title, String desc, int value,\n      Future<void> Function(int) onChanged) {\n    return Column(\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: [\n        Row(\n          children: [\n            Icon(icon, color: c.sub, size: 18),\n            const SizedBox(width: 8),\n            Text(title, style: TextStyle(color: c.ink, fontSize: 14, fontWeight: FontWeight.w700)),\n            const Spacer(),\n            Text('${(value / 10).toStringAsFixed(0)}%',\n                style: const TextStyle(color: _point, fontSize: 12.5, fontWeight: FontWeight.w700)),\n          ],\n        ),\n        const SizedBox(height: 3),\n        Padding(\n          padding: const EdgeInsets.only(left: 26),\n          child: Text(desc, style: TextStyle(color: c.sub, fontSize: 11.5)),\n        ),\n        SliderTheme(\n          data: _sliderTheme(context, c),\n          child: Slider(\n            value: value.toDouble().clamp(0.0, 1000.0),\n            min: 0,\n            max: 1000,\n            onChanged: (v) => onChanged(v.toInt()),\n          ),\n        ),\n      ],\n    );\n  }\n\n  /// 지금 설정을 이름 붙여 저장\n  void _askSave(BuildContext context, SoundEffects fx) async {\n    final name = await showParanInput(\n      context,\n      title: '지금 설정 저장',\n      initial: '내 설정 ${fx.custom.length + 1}',\n      hint: '예) 출근길, 잠잘 때',\n    );\n    if (name == null || !context.mounted) return;\n    fx.saveCustom(name);\n    showActionFeedback(context, type: ActionFeedbackType.saved);\n  }\n\n  void _askDelete(BuildContext context, SoundEffects fx, FxPreset p) async {\n    HapticFeedback.mediumImpact();\n    final ok = await showParanConfirm(\n      context,\n      title: '\"${p.name}\"을 지울까요?',\n      confirmLabel: '지우기',\n      danger: true,\n    );\n    if (!ok || !context.mounted) return;\n    fx.deleteCustom(p);\n    showActionFeedback(context, type: ActionFeedbackType.deleted);\n  }\n}\n\n/// 화면 공통 색 (베이지 바탕 · 흰 카드 · 먹색)\nclass _EqPal {\n  final bool dark;\n  final Color bg, card, ink, sub, line;\n  const _EqPal(this.dark, this.bg, this.card, this.ink, this.sub, this.line);\n  static _EqPal of(BuildContext context) {\n    final d = context.watch<ThemeProvider>().isDarkMode;\n    return d\n        ? const _EqPal(true, Color(0xFF17140F), Color(0xFF26221C), Color(0xFFF3EFE7), Color(0xFFA29A8B), Color(0xFF3A342B))\n        : const _EqPal(false, Color(0xFFF4EFE5), Colors.white, Color(0xFF17140F), Color(0xFF8A8378), Color(0xFFE2DACB));\n  }\n}"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_screen2")

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
            elif kind == "strall":
                n = s.count(a)
                if n < 1:
                    problems.append(f"{rel}: '{a.strip().splitlines()[0][:60]}' 를 못 찾았어요")
                    continue
                trial[rel] = s.replace(a, b)
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
    print("   문제가 있으면 backup_screen2 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
