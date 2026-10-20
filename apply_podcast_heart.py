# -*- coding: utf-8 -*-
# 팟캐스트 구독 하트: 음악 재생 화면 하트와 같은 모양(가는 선 하트 · 켜면 빨간 꽉 찬 하트)
# + 같은 애니메이션 (켤 때 통통 튀고 작은 하트 셋이 흔들리며 위로 떠오름, 끌 때는 조용히)
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast_screens.dart')


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


if not os.path.exists(PATH):
    fail('파일이 없어요: ' + PATH)
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s


def rep(label, old, new, done):
    global s
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(label + ' — 찾을 코드를 못 찾았어요')
    s = s.replace(old, new)
    print('✔', label)


rep('import', "import 'package:flutter/material.dart';\n",
    "import 'dart:math' as math;\nimport 'package:flutter/cupertino.dart' show CupertinoIcons;\nimport 'package:flutter/material.dart';\n",
    done="import 'package:flutter/cupertino.dart' show CupertinoIcons;")
if "import '../widgets/heart_pop.dart';\n" in s:
    s = s.replace("import '../widgets/heart_pop.dart';\n", '')
    print('✔ 예전 하트 효과 import 빼기')

rep('구독 하트 → 음악 하트와 같은 모양·애니메이션',
    '    return GestureDetector(\n'
    '      onTap: () {\n'
    '        _buzz();\n'
    '        pod.toggleSub(_show, latestGuid: _latestGuid);\n'
    '      },\n'
    '      child: Container(\n'
    '        width: 46,\n'
    '        height: 46,\n'
    '        decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(14)),\n'
    '        child: HeartPop(\n'
    '          on: on,\n'
    '          child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,\n'
    '              size: 22, color: on ? const Color(0xFFE05A4F) : _text(dark)),\n'
    '        ),\n'
    '      ),\n'
    '    );\n',
    '    return _PodHeart(\n'
    '      isFav: on,\n'
    '      offColor: _text(dark).withOpacity(0.7),\n'
    '      onTap: () {\n'
    '        _buzz();\n'
    '        pod.toggleSub(_show, latestGuid: _latestGuid);\n'
    '      },\n'
    '    );\n',
    done='    return _PodHeart(\n')

if 'class _PodHeart extends StatefulWidget' not in s:
    s = s.rstrip('\n') + '\n' + '''
/// 구독 하트 — 음악 재생 화면 하트와 같은 모양·움직임
/// 켤 때만 하트가 통통 튀고 작은 하트 셋이 흔들리며 위로 떠올라요 (끌 때는 조용히)
class _PodHeart extends StatefulWidget {
  final bool isFav;
  final Color offColor;
  final VoidCallback onTap;
  const _PodHeart({required this.isFav, required this.offColor, required this.onTap});

  @override
  State<_PodHeart> createState() => _PodHeartState();
}

class _PodHeartState extends State<_PodHeart> with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE05A4F);
  static const _total = 1240.0; // ms (마지막 작은 하트가 끝날 때까지)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1240));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 하트 통통: 1 → 1.35 → 0.9 → 1 (처음 0.45초)
  double _pop(double ms) {
    if (!_c.isAnimating) return 1;
    final t = (ms / 450).clamp(0.0, 1.0);
    if (t < 0.35) return 1 + 0.35 * Curves.easeOut.transform(t / 0.35);
    if (t < 0.65) return 1.35 - 0.45 * ((t - 0.35) / 0.3);
    return 0.9 + 0.1 * ((t - 0.65) / 0.35);
  }

  /// 작은 하트 하나: 1초 동안 위로 74 올라가며 커졌다가 흐려짐
  Widget _mini(double ms, double startMs, double dx) {
    final t = (ms - startMs) / 1000;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final e = Curves.easeOut.transform(t);
    final op = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
    final wobble = math.sin(t * math.pi * 2) * 3; // 좌우로 살짝 흔들림
    return Transform.translate(
      offset: Offset(dx * e + wobble, -74 * e),
      child: Transform.scale(
        scale: 0.4 + 0.6 * e,
        child: Opacity(
          opacity: op.clamp(0.0, 1.0).toDouble(),
          child: const Icon(CupertinoIcons.heart_fill, color: _red, size: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!widget.isFav) _c.forward(from: 0); // 켤 때만
        widget.onTap();
      },
      child: SizedBox(
        width: 46,
        height: 46,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final ms = _c.value * _total;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_c.isAnimating) ...[
                  _mini(ms, 0, -14),
                  _mini(ms, 120, 4),
                  _mini(ms, 240, 16),
                ],
                Transform.scale(
                  scale: _pop(ms),
                  child: Icon(
                    widget.isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: widget.isFav ? _red : widget.offColor,
                    size: 24,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
'''
    print('✔ 하트 모양·애니메이션 넣기')
else:
    print('✔ 하트 모양·애니메이션 넣기 (이미 돼 있음)')

if 'HeartPop(' in s:
    fail('예전 하트 코드가 남아 있어요')
if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
