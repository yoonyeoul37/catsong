# -*- coding: utf-8 -*-
# 팟캐스트 화면(회차 목록·재생 화면): 상단·하단 시스템 바를 화면 바탕색(라이트 베이지 / 다크 갈색)과 같게
# + 목록이 아래 내비게이션 바와 겹치지 않게 + 1분 넘게 들은 회차만 'N분 남음'
# (앞서 준 찾기/바꾸기를 했든 안 했든 그대로 돌리면 됨)
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


def rep(label, olds, new, done=None):
    global s
    if (done or new) in s:
        print('✔', label, '(이미 돼 있음)')
        return
    for old in olds:
        if s.count(old) == 1:
            s = s.replace(old, new)
            print('✔', label)
            return
    fail(label + ' — 찾을 코드를 못 찾았어요')


rep('시스템 바 색 함수',
    ["void _buzz() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"],
    "void _buzz() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "\n"
    "/// 상단·하단 시스템 바: 화면 바탕과 같은 색 + 아이콘 색 (라이트는 어두운 아이콘, 다크는 밝은 아이콘)\n"
    "SystemUiOverlayStyle _bars(bool dark) => SystemUiOverlayStyle(\n"
    "      statusBarColor: Colors.transparent,\n"
    "      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,\n"
    "      statusBarBrightness: dark ? Brightness.dark : Brightness.light,\n"
    "      systemNavigationBarColor: _bg(dark),\n"
    "      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,\n"
    "      systemNavigationBarDividerColor: Colors.transparent,\n"
    "    );\n",
    done='SystemUiOverlayStyle _bars(bool dark)')

# ── 회차 목록 화면 ──
rep('회차 목록: 시스템 바 감싸기',
    ["    return Scaffold(\n      backgroundColor: _bg(dark),\n      appBar: AppBar(\n"],
    "    return AnnotatedRegion<SystemUiOverlayStyle>(\n      value: _bars(dark),\n      child: Scaffold(\n      backgroundColor: _bg(dark),\n      appBar: AppBar(\n",
    done='      value: _bars(dark),\n      child: Scaffold(\n      backgroundColor: _bg(dark),\n      appBar: AppBar(')
rep('회차 목록: 위쪽 줄 바탕색·아이콘 색',
    ["        backgroundColor: Colors.transparent,\n        elevation: 0,\n        scrolledUnderElevation: 0,\n",
     "        backgroundColor: _bg(dark), // 목록이 위로 올라가도 상단 아이콘과 겹치지 않게 바탕색 칠하기\n"
     "        surfaceTintColor: Colors.transparent,\n        elevation: 0,\n        scrolledUnderElevation: 0,\n"
     "        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark, // 상단 아이콘 색\n"],
    "        backgroundColor: _bg(dark), // 목록이 위로 올라가도 상단 아이콘과 겹치지 않게\n"
    "        surfaceTintColor: Colors.transparent,\n        elevation: 0,\n        scrolledUnderElevation: 0,\n"
    "        systemOverlayStyle: _bars(dark),\n",
    done='        systemOverlayStyle: _bars(dark),\n')
rep('회차 목록: 아래 내비게이션 바와 안 겹치게',
    ["      body: FutureBuilder<List<PodcastEpisode>>(\n        future: _eps,\n"],
    "      body: SafeArea(\n        top: false, // 목록이 아래 내비게이션 바 밑으로 들어가지 않게\n        child: FutureBuilder<List<PodcastEpisode>>(\n        future: _eps,\n",
    done='        top: false, // 목록이 아래 내비게이션 바 밑으로 들어가지 않게\n')
rep('회차 목록: 괄호 닫기 (SafeArea)',
    ["        },\n      ),\n      bottomNavigationBar: !radioOn && pod.active\n"],
    "        },\n      )),\n      bottomNavigationBar: !radioOn && pod.active\n")
rep('회차 목록: 괄호 닫기 (시스템 바)',
    ["          : null,\n    );\n  }\n\n  Widget _episodeRow("],
    "          : null,\n    ));\n  }\n\n  Widget _episodeRow(")
rep("1분 넘게 들은 회차만 '남음'",
    ["    } else if (ms > 0 && total > 0) {\n"],
    "    } else if (ms >= 60000 && total > 0) { // 1분 넘게 들은 회차만 '남음'\n",
    done="ms >= 60000 && total > 0")

# ── 재생 화면 ──
rep('재생 화면: 시스템 바 감싸기',
    ["    return Scaffold(\n      backgroundColor: _bg(dark),\n      body: SafeArea(\n        child: Column(\n"],
    "    return AnnotatedRegion<SystemUiOverlayStyle>(\n      value: _bars(dark),\n      child: Scaffold(\n      backgroundColor: _bg(dark),\n      body: SafeArea(\n        child: Column(\n",
    done='      child: Scaffold(\n      backgroundColor: _bg(dark),\n      body: SafeArea(\n        child: Column(')
rep('재생 화면: 괄호 닫기',
    ["            const Spacer(flex: 2),\n          ],\n        ),\n      ),\n    );\n  }\n"],
    "            const Spacer(flex: 2),\n          ],\n        ),\n      ),\n    ));\n  }\n")

if s.count('(') != s.count(')') or s.count('{') != s.count('}'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
