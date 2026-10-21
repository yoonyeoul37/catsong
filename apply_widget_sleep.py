# -*- coding: utf-8 -*-
# 위젯 수면 타이머 (③단계)
#  - ⋮ 창에 '수면 타이머' 줄 → 누르면 앱과 같은 시간·분 휠 → '설정' 누르면 창 닫히고 위젯에 남은 시간
#  - ⋮ 는 이제 음악·라디오·자연소리 모두 보임 (랜덤·반복 줄은 음악일 때만)
#  - 앱에서 맞춘 수면 타이머도 위젯에 남은 시간이 보임
# 고치는 파일
#  안드로이드: PlayerWidget.kt · WidgetMenuActivity.kt(통째로 새로) · widget_menu.xml(통째로 새로)
#            widget_player.xml · widget_player2.xml · widget_player3.xml · AndroidManifest.xml
#            styles.xml(라이트·다크) · strings.xml 26개
#  앱(lib): headset_resume.dart · player_provider.dart · radio_provider.dart
#  새 파일: paran_btn_point.xml · paran_btn_outline.xml · paran_ic_close.xml
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행 / 하나라도 못 찾으면 ❌ 띄우고 아무것도 저장 안 함
import os
import sys

MAIN = os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(MAIN, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(MAIN, 'res')
LIB = 'lib'

ok = True
files = {}  # 경로 → [글, CRLF]
ORIG = {}   # 고치기 전 글


def fail(msg):
    global ok
    ok = False
    print('❌ ' + msg)


def load(path):
    if path in files:
        return files[path][0]
    if not os.path.exists(path):
        fail(path + ' 파일이 없어요 (프로젝트 폴더에서 실행했는지 확인)')
        return None
    with open(path, 'rb') as f:
        raw = f.read().decode('utf-8')
    files[path] = [raw.replace('\r\n', '\n'), '\r\n' in raw]
    ORIG[path] = files[path][0]
    return files[path][0]


def rep(path, old, new, label):
    t = load(path)
    if t is None:
        return
    n = t.count(old)
    name = os.path.basename(path)
    if n != 1:
        fail(f'{name} — {label}: 찾을 코드를 못 찾았어요' if n == 0 else f'{name} — {label}: 같은 코드가 {n}군데라 못 고쳐요')
        return
    files[path][0] = t.replace(old, new)
    print(f'✔ {name} — {label}')


def whole(path, must_have, must_not, body, label):
    """내가 만든 파일을 통째로 새로 — 예상한 모양일 때만"""
    t = load(path)
    if t is None:
        return
    if must_have not in t or must_not in t:
        fail(f'{os.path.basename(path)} — {label}: 예상한 모양이 아니라 멈춰요')
        return
    files[path][0] = body
    print(f'✔ {os.path.basename(path)} — {label}')


W = os.path.join(KT, 'PlayerWidget.kt')
ACT = os.path.join(KT, 'WidgetMenuActivity.kt')
MENU = os.path.join(RES, 'layout', 'widget_menu.xml')
L1 = os.path.join(RES, 'layout', 'widget_player.xml')
L2 = os.path.join(RES, 'layout', 'widget_player2.xml')
L3 = os.path.join(RES, 'layout', 'widget_player3.xml')
MAN = os.path.join(MAIN, 'AndroidManifest.xml')
STY = os.path.join(RES, 'values', 'styles.xml')
STYN = os.path.join(RES, 'values-night', 'styles.xml')
HR = os.path.join(LIB, 'services', 'headset_resume.dart')
PP = os.path.join(LIB, 'providers', 'player_provider.dart')
RP = os.path.join(LIB, 'providers', 'radio_provider.dart')
NEW = [
    (os.path.join(RES, 'drawable', 'paran_btn_point.xml'), '''<?xml version="1.0" encoding="utf-8"?>
<!-- 위젯 수면 타이머 '설정' 버튼 (포인트 색) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/paran_w_point" />
    <corners android:radius="12dp" />
</shape>
''', "'설정' 버튼 바탕"),
    (os.path.join(RES, 'drawable', 'paran_btn_outline.xml'), '''<?xml version="1.0" encoding="utf-8"?>
<!-- 위젯 수면 타이머 '타이머 취소' 버튼 (빨간 테두리) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#00000000" />
    <stroke android:width="1dp" android:color="#FF5252" />
    <corners android:radius="12dp" />
</shape>
''', "'타이머 취소' 버튼 바탕"),
    (os.path.join(RES, 'drawable', 'paran_ic_close.xml'), '''<?xml version="1.0" encoding="utf-8"?>
<!-- ✕ 닫기 (끝이 둥근 선) -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path android:fillColor="#00000000" android:strokeColor="#FFFFFFFF" android:strokeWidth="1.9"
        android:strokeLineCap="round" android:pathData="M6.5,6.5L17.5,17.5M17.5,6.5L6.5,17.5" />
</vector>
''', '✕ 아이콘'),
]

# ── 이미 적용됐는지 ──
w0 = load(W)
if w0 is None:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)
if 'ACTION_SLEEP' in w0:
    print('이미 적용돼 있어요')
    sys.exit(0)
for p, _, _ in NEW:
    if os.path.exists(p):
        fail(os.path.basename(p) + ' 파일이 벌써 있어요 — 덮어쓰지 않으려고 멈춰요')

# ═════════ 앱(lib) ═════════
rep(HR, '''  // ───── 홈 위젯 재생 버튼 ─────
''', '''  // ───── 위젯 ⋮ → 수면 타이머 ─────
  /// 위젯에서 수면 타이머 맞추기 — 지금 듣는 것(라디오 / 음악·자연소리)에 맞춰, 0분이면 끄기
  static void widgetSleep(int minutes) {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return;
    if (minutes <= 0) {
      if (pp.isSleepTimerActive) pp.cancelSleepTimer();
      if (radio.isSleepTimerActive) radio.cancelSleepTimer();
      return;
    }
    final d = Duration(minutes: minutes);
    final onRadio = radio.isPlaying || radio.isLoading || (!pp.isPlaying && radio.currentStation != null);
    if (onRadio) {
      if (pp.isSleepTimerActive) pp.cancelSleepTimer();
      radio.setSleepTimer(d);
    } else {
      if (radio.isSleepTimerActive) radio.cancelSleepTimer();
      pp.setSleepTimer(d);
    }
  }

  static Future<void> _sleepChain = Future.value();

  /// 수면 타이머 끝나는 시각을 위젯이 읽게 저장 ('m' 음악·자연 · 'r' 라디오) + 위젯 다시 그리기
  /// 앱에서 맞춘 타이머도 여기로 와서 위젯에 남은 시간이 보임
  static void saveSleepEnd(String k, DateTime? end) {
    _sleepChain = _sleepChain.then((_) async {
      try {
        final p = await SharedPreferences.getInstance();
        if (end == null) {
          await p.remove('w_sleep_$k');
        } else {
          await p.setInt('w_sleep_$k', end.millisecondsSinceEpoch);
        }
        await _ch.invokeMethod('refreshWidget');
      } catch (_) {}
    });
  }

  // ───── 홈 위젯 재생 버튼 ─────
''', '위젯 수면 타이머 받는 곳 + 끝나는 시각 저장')

rep(PP, '''        case 'widgetShuffle':
          toggleShuffle(); // 위젯: 섞기 켜기·끄기
          break;
''', '''        case 'widgetShuffle':
          toggleShuffle(); // 위젯: 섞기 켜기·끄기
          break;
        case 'widgetSleep':
          HeadsetResume.widgetSleep(call.arguments as int? ?? 0); // 위젯 ⋮ → 수면 타이머 (0이면 끄기)
          break;
''', '위젯 → 수면 타이머 신호 받기')
rep(PP, '''    _sleepTimerEnd = DateTime.now().add(duration);
''', '''    _sleepTimerEnd = DateTime.now().add(duration);
    HeadsetResume.saveSleepEnd('m', _sleepTimerEnd); // 위젯에 남은 시간
''', '음악 수면 타이머 → 위젯에 알리기 (켤 때)')
rep(PP, '''      _sleepTimerEnd = null;
      notifyListeners();
    });
''', '''      _sleepTimerEnd = null;
      HeadsetResume.saveSleepEnd('m', null);
      notifyListeners();
    });
''', '음악 수면 타이머 → 위젯에 알리기 (끝날 때)')
rep(PP, '''    _sleepTimer = null;
    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
    notifyListeners();
  }
''', '''    _sleepTimer = null;
    _sleepTimerDuration = null;
    if (_sleepTimerEnd != null) HeadsetResume.saveSleepEnd('m', null);
    _sleepTimerEnd = null;
    notifyListeners();
  }
''', '음악 수면 타이머 → 위젯에 알리기 (끌 때)')

rep(RP, '''import '../services/schedule_service.dart';
''', '''import '../services/schedule_service.dart';
import '../services/headset_resume.dart' show HeadsetResume;
''', '위젯 알리기 불러오기')
rep(RP, '''    _sleepRemaining = duration;
    sleepTick.value = duration;
''', '''    _sleepRemaining = duration;
    sleepTick.value = duration;
    HeadsetResume.saveSleepEnd('r', DateTime.now().add(duration)); // 위젯에 남은 시간
''', '라디오 수면 타이머 → 위젯에 알리기 (켤 때)')
rep(RP, '''    _sleepTimer = null;
    _sleepCountdown = null;
    _sleepRemaining = null;
''', '''    if (_sleepRemaining != null) HeadsetResume.saveSleepEnd('r', null); // 위젯 남은 시간 지우기
    _sleepTimer = null;
    _sleepCountdown = null;
    _sleepRemaining = null;
''', '라디오 수면 타이머 → 위젯에 알리기 (끌 때)')

# ═════════ PlayerWidget.kt ═════════
rep(W, '''        const val ACTION_SHUFFLE = "kr.ssing.catsong.SHUFFLE"
''', '''        const val ACTION_SHUFFLE = "kr.ssing.catsong.SHUFFLE"
        const val ACTION_SLEEP = "kr.ssing.catsong.SLEEP" // ⋮ 창 → 수면 타이머 (minutes, 0이면 끄기)
''', '수면 타이머 신호 이름')
rep(W, '''            a.startsWith(ACTION_KIND) -> {''', '''            a == ACTION_SLEEP -> {
                // ⋮ 창에서 맞춘 수면 타이머 → 앱(다트)에게 (앱이 막 깨어나는 중이면 조금 기다렸다가)
                val m = intent.getIntExtra("minutes", 0)
                if (MainActivity.mediaChannel != null) {
                    toApp("widgetSleep", m) {}
                } else {
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        try { MainActivity.mediaChannel?.invokeMethod("widgetSleep", m) } catch (_: Exception) {}
                    }, 1500)
                }
            }
            a.startsWith(ACTION_KIND) -> {''', '수면 타이머 신호 받기')
rep(W, '''            // ⋮ 메뉴: 지금은 음악일 때만 (랜덤 듣기 · 반복) — 세 위젯 모두 같음
            val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val music = try { fp.getBoolean("flutter.w_music", false) } catch (_: Exception) { false }
            views.setViewVisibility(R.id.widget_more, if (music && !empty) View.VISIBLE else View.GONE)
''', '''            // ⋮ 메뉴: 듣는 게 있으면 언제나 (랜덤·반복 줄은 창에서 음악일 때만) — 세 위젯 모두 같음
            val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            views.setViewVisibility(R.id.widget_more, if (!empty) View.VISIBLE else View.GONE)
            // 수면 타이머 남은 시간 (음악·자연 'm' · 라디오 'r' 중 늦게 끝나는 것) — 1초마다 저절로 줄어듦
            val sleepEnd = maxOf(
                try { fp.getLong("flutter.w_sleep_m", 0L) } catch (_: Exception) { 0L },
                try { fp.getLong("flutter.w_sleep_r", 0L) } catch (_: Exception) { 0L })
            val sleepLeft = sleepEnd - System.currentTimeMillis()
            if (sleepLeft > 0 && android.os.Build.VERSION.SDK_INT >= 24) {
                views.setViewVisibility(R.id.widget_timer, View.VISIBLE)
                views.setChronometer(R.id.widget_timer_text,
                    android.os.SystemClock.elapsedRealtime() + sleepLeft, null, true)
                views.setChronometerCountDown(R.id.widget_timer_text, true)
            } else {
                views.setViewVisibility(R.id.widget_timer, View.GONE)
                views.setChronometer(R.id.widget_timer_text, android.os.SystemClock.elapsedRealtime(), null, false)
            }
''', '⋮ 언제나 보이기 + 남은 시간 표시')

# ═════════ 위젯 화면 ═════════
TIMER_BADGE = '''

        <!-- 수면 타이머 남은 시간 (⋮ 왼쪽) -->
        <LinearLayout
            android:id="@+id/widget_timer"
            android:layout_width="wrap_content"
            android:layout_height="22dp"
            android:layout_gravity="top|end"
            android:layout_marginTop="9dp"
            android:layout_marginEnd="42dp"
            android:background="@drawable/paran_widget_badge"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="7dp"
            android:paddingEnd="8dp"
            android:visibility="gone">

            <ImageView
                android:layout_width="11dp"
                android:layout_height="11dp"
                android:layout_marginEnd="3dp"
                android:src="@drawable/paran_ic_timer"
                android:tint="#FFFFFF" />

            <Chronometer
                android:id="@+id/widget_timer_text"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:textColor="#FFFFFF"
                android:textSize="10sp"
                android:textStyle="bold" />
        </LinearLayout>'''
MORE_END = '''            android:src="@drawable/paran_ic_more"
            android:tint="#FFFFFF"
            android:visibility="gone" />'''
for L in (L1, L2):
    rep(L, MORE_END, MORE_END + TIMER_BADGE, '사진 위 남은 시간 칸 넣기')
rep(L3, '''            <TextView
                android:id="@+id/widget_timer_text"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text=""
                android:textColor="#FFFFFF"''', '''            <Chronometer
                android:id="@+id/widget_timer_text"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:textColor="#FFFFFF"''', '남은 시간 글자 → 저절로 줄어드는 시계')
rep(L3, '        <!-- 수면 타이머 남은 시간 (다음 단계에서 켬) -->', '        <!-- 수면 타이머 남은 시간 -->',
    '설명 글 바꾸기')

# ═════════ 창 모양(테마) ═════════
def theme(parent):
    return f'''    <!-- 위젯 ⋮ 메뉴 창: 투명 바탕 위 작은 창 (시간·분 휠이 예쁘게 나오게 머티리얼 모양) -->
    <style name="WidgetMenuTheme" parent="{parent}">
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:windowAnimationStyle">@android:style/Animation.Translucent</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
        <item name="android:navigationBarColor">@android:color/transparent</item>
        <item name="android:colorAccent">@color/paran_w_point</item>
        <item name="android:backgroundDimEnabled">false</item>
    </style>
</resources>'''
rep(STY, '</resources>', theme('@android:style/Theme.Material.Light.NoActionBar'), '⋮ 창 모양 (라이트)')
rep(STYN, '</resources>', theme('@android:style/Theme.Material.NoActionBar'), '⋮ 창 모양 (다크)')
rep(MAN, '''            android:taskAffinity=""
            android:theme="@android:style/Theme.Translucent.NoTitleBar" />''', '''            android:taskAffinity=""
            android:theme="@style/WidgetMenuTheme" />''', '⋮ 창 모양 연결')

# ═════════ ⋮ 창 화면 (통째로 새로) ═════════
def row(rid, icon_id, icon, label_id, value_id):
    icon_attr = f'\n                android:id="@+id/{icon_id}"' if icon_id else ''
    return f'''            <!-- 얇은 줄 -->
            <View
                android:layout_width="match_parent"
                android:layout_height="1dp"
                android:background="@color/paran_w_line" />

            <LinearLayout
                android:id="@+id/{rid}"
                android:layout_width="match_parent"
                android:layout_height="52dp"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="2dp"
                android:paddingEnd="2dp">

                <ImageView{icon_attr}
                    android:layout_width="20dp"
                    android:layout_height="20dp"
                    android:src="@drawable/{icon}"
                    android:tint="@color/paran_w_ink" />

                <TextView
                    android:id="@+id/{label_id}"
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="14dp"
                    android:layout_weight="1"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_ink"
                    android:textSize="14sp" />

                <TextView
                    android:id="@+id/{value_id}"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="10dp"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_sub"
                    android:textSize="12.5sp" />
            </LinearLayout>
'''


def wheel(pid, unit_id):
    return f'''            <NumberPicker
                android:id="@+id/{pid}"
                android:layout_width="64dp"
                android:layout_height="wrap_content"
                android:descendantFocusability="blocksDescendants" />

            <TextView
                android:id="@+id/{unit_id}"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="2dp"
                android:layout_marginEnd="14dp"
                android:textColor="@color/paran_w_ink"
                android:textSize="15sp" />
'''


MENU_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 위젯 ⋮ 메뉴 창 (WidgetMenuActivity) — 바깥(어두운 곳)을 누르면 닫힘 -->
<!-- menu_list: 메뉴 줄들 / menu_dial: 수면 타이머 시간·분 휠 (앱 수면 타이머와 같은 모양) -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/menu_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#59000000">

    <LinearLayout
        android:id="@+id/menu_card"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:layout_marginStart="14dp"
        android:layout_marginEnd="14dp"
        android:layout_marginBottom="24dp"
        android:background="@drawable/paran_menu_bg"
        android:orientation="vertical">

        <!-- ── 메뉴 줄들 ── -->
        <LinearLayout
            android:id="@+id/menu_list"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:paddingStart="18dp"
            android:paddingTop="16dp"
            android:paddingEnd="18dp"
            android:paddingBottom="6dp">

            <TextView
                android:id="@+id/menu_title"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:maxLines="1"
                android:textColor="@color/paran_w_ink"
                android:textSize="15sp"
                android:textStyle="bold" />

            <TextView
                android:id="@+id/menu_sub"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="2dp"
                android:ellipsize="end"
                android:maxLines="1"
                android:textColor="@color/paran_w_sub"
                android:textSize="12sp" />

            <FrameLayout
                android:layout_width="match_parent"
                android:layout_height="12dp" />

''' + row('menu_shuffle', None, 'paran_ic_shuffle', 'menu_shuffle_label', 'menu_shuffle_value') + '\n' \
    + row('menu_repeat', 'menu_repeat_icon', 'paran_ic_repeat', 'menu_repeat_label', 'menu_repeat_value') + '\n' \
    + row('menu_sleep', None, 'paran_ic_timer', 'menu_sleep_label', 'menu_sleep_value') + '''        </LinearLayout>

        <!-- ── 수면 타이머: 시간·분 휠 ── -->
        <LinearLayout
            android:id="@+id/menu_dial"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:paddingStart="12dp"
            android:paddingTop="12dp"
            android:paddingEnd="12dp"
            android:paddingBottom="16dp"
            android:visibility="gone">

            <!-- 제목 가운데 + 오른쪽 ✕ (앱과 같은 짜임) -->
            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:gravity="center_vertical"
                android:orientation="horizontal">

                <FrameLayout
                    android:layout_width="40dp"
                    android:layout_height="40dp" />

                <LinearLayout
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_weight="1"
                    android:gravity="center_horizontal"
                    android:orientation="vertical">

                    <TextView
                        android:id="@+id/menu_dial_title"
                        android:layout_width="wrap_content"
                        android:layout_height="wrap_content"
                        android:gravity="center"
                        android:textColor="@color/paran_w_ink"
                        android:textSize="16sp"
                        android:textStyle="bold" />

                    <TextView
                        android:id="@+id/menu_dial_hint"
                        android:layout_width="wrap_content"
                        android:layout_height="wrap_content"
                        android:layout_marginTop="3dp"
                        android:gravity="center"
                        android:textColor="@color/paran_w_sub"
                        android:textSize="12sp" />
                </LinearLayout>

                <ImageView
                    android:id="@+id/menu_dial_close"
                    android:layout_width="40dp"
                    android:layout_height="40dp"
                    android:background="?android:attr/selectableItemBackgroundBorderless"
                    android:padding="9dp"
                    android:src="@drawable/paran_ic_close"
                    android:tint="@color/paran_w_sub" />
            </LinearLayout>

            <!-- 시간 · 분 (아랍어에서도 숫자 → 단위 순서 그대로) -->
            <LinearLayout
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_gravity="center_horizontal"
                android:layout_marginTop="6dp"
                android:gravity="center_vertical"
                android:layoutDirection="ltr"
                android:orientation="horizontal">

''' + wheel('menu_hours', 'menu_hours_unit') + '\n' + wheel('menu_minutes', 'menu_minutes_unit') + '''            </LinearLayout>

            <!-- 타이머 취소(켜져 있을 때만) · 설정 -->
            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="48dp"
                android:layout_marginStart="8dp"
                android:layout_marginTop="10dp"
                android:layout_marginEnd="8dp"
                android:orientation="horizontal">

                <TextView
                    android:id="@+id/menu_sleep_off"
                    android:layout_width="0dp"
                    android:layout_height="match_parent"
                    android:layout_marginEnd="8dp"
                    android:layout_weight="1"
                    android:background="@drawable/paran_btn_outline"
                    android:gravity="center"
                    android:maxLines="1"
                    android:textColor="#FF5252"
                    android:textSize="14sp"
                    android:visibility="gone" />

                <TextView
                    android:id="@+id/menu_sleep_set"
                    android:layout_width="0dp"
                    android:layout_height="match_parent"
                    android:layout_weight="1"
                    android:background="@drawable/paran_btn_point"
                    android:gravity="center"
                    android:maxLines="1"
                    android:textColor="#FFFFFF"
                    android:textSize="14sp"
                    android:textStyle="bold" />
            </LinearLayout>
        </LinearLayout>
    </LinearLayout>
</FrameLayout>
'''
whole(MENU, 'menu_shuffle', 'menu_sleep', MENU_XML, '⋮ 창 화면 통째로 새로 (수면 타이머 줄 · 휠)')

ACT_KT = '''package kr.ssing.catsong

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageView
import android.widget.NumberPicker
import android.widget.TextView

/// 위젯 ⋮ 를 누르면 바탕화면 위에 뜨는 작은 창 (앱 화면은 안 열림)
/// 랜덤 듣기 · 반복(음악일 때만) · 수면 타이머 / 바깥을 누르면 닫힘
/// 실제로 바꾸는 건 위젯 버튼과 같은 길(PlayerWidget)로 보냄
class WidgetMenuActivity : Activity() {

    private val h = Handler(Looper.getMainLooper())
    private lateinit var lc: Context

    // 창이 열려 있는 동안 수면 타이머 남은 시간 1초마다 다시 보이기
    private val tick = object : Runnable {
        override fun run() {
            if (isFinishing) return
            showSleep()
            h.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.widget_menu)
        lc = PlayerWidget.localized(this) // 앱에서 고른 언어로
        // 아래 시스템 바(내비게이션 바)에 창이 가리지 않게 그만큼 띄우기
        findViewById<View>(R.id.menu_root).setOnApplyWindowInsetsListener { v, insets ->
            @Suppress("DEPRECATION")
            v.setPadding(0, insets.systemWindowInsetTop, 0, insets.systemWindowInsetBottom)
            insets
        }
        findViewById<View>(R.id.menu_root).setOnClickListener { finish() }
        findViewById<View>(R.id.menu_card).setOnClickListener { } // 창 안을 누르면 안 닫힘
        findViewById<View>(R.id.menu_shuffle).setOnClickListener { send(PlayerWidget.ACTION_SHUFFLE) }
        findViewById<View>(R.id.menu_repeat).setOnClickListener { send(PlayerWidget.ACTION_REPEAT) }
        findViewById<View>(R.id.menu_sleep).setOnClickListener { openDial() }
        findViewById<View>(R.id.menu_dial_close).setOnClickListener { closeDial() }
        findViewById<View>(R.id.menu_sleep_set).setOnClickListener { setSleep() }
        findViewById<View>(R.id.menu_sleep_off).setOnClickListener { sleep(0) }

        // 시간 0~23 · 분 0~59, 처음엔 30분 (앱 수면 타이머와 같음)
        val ink = color(R.color.paran_w_ink)
        findViewById<NumberPicker>(R.id.menu_hours).apply {
            minValue = 0; maxValue = 23; value = 0
            if (android.os.Build.VERSION.SDK_INT >= 29) setTextColor(ink)
        }
        findViewById<NumberPicker>(R.id.menu_minutes).apply {
            minValue = 0; maxValue = 59; value = 30
            setFormatter { String.format(java.util.Locale.US, "%02d", it) }
            if (android.os.Build.VERSION.SDK_INT >= 29) setTextColor(ink)
        }
        show()
        h.post(tick)
    }

    @Suppress("DEPRECATION")
    private fun color(id: Int) = resources.getColor(id)

    /// 위젯 버튼과 같은 길로 보내고, 잠깐 뒤 바뀐 값으로 다시 보여 주기
    private fun send(action: String) {
        sendBroadcast(Intent(this, PlayerWidget::class.java).setAction(action))
        h.postDelayed({ if (!isFinishing) show() }, 250)
    }

    private fun show() {
        val p = getSharedPreferences("paran_widget", Context.MODE_PRIVATE)
        val fp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val music = try { fp.getBoolean("flutter.w_music", false) } catch (_: Exception) { false }
        val loop = try { fp.getLong("flutter.w_loop", 0L) } catch (_: Exception) { 0L }
        val shuf = try { fp.getBoolean("flutter.w_shuffle", false) } catch (_: Exception) { false }
        val point = color(R.color.paran_w_point)
        val sub = color(R.color.paran_w_sub)

        findViewById<TextView>(R.id.menu_title).text = p.getString("t", null) ?: lc.getString(R.string.app_name)
        val a = p.getString("a", null) ?: ""
        findViewById<TextView>(R.id.menu_sub).apply {
            text = a
            visibility = if (a.isEmpty()) View.GONE else View.VISIBLE
        }

        // 랜덤 · 반복: 음악 들을 때만
        val vis = if (music) View.VISIBLE else View.GONE
        findViewById<View>(R.id.menu_shuffle).visibility = vis
        findViewById<View>(R.id.menu_repeat).visibility = vis
        findViewById<TextView>(R.id.menu_shuffle_label).text = lc.getString(R.string.w_menu_shuffle)
        findViewById<TextView>(R.id.menu_repeat_label).text = lc.getString(R.string.w_menu_repeat)
        findViewById<TextView>(R.id.menu_sleep_label).text = lc.getString(R.string.w_menu_sleep)
        findViewById<TextView>(R.id.menu_shuffle_value).apply {
            text = lc.getString(if (shuf) R.string.w_menu_on else R.string.w_menu_off)
            setTextColor(if (shuf) point else sub)
            paint.isFakeBoldText = shuf
        }
        // 0 반복 안 함 → 1 한 곡 반복 → 2 전체 반복 (위젯 순서 그대로)
        findViewById<ImageView>(R.id.menu_repeat_icon).setImageResource(
            if (loop == 1L) R.drawable.paran_ic_repeat_one else R.drawable.paran_ic_repeat)
        findViewById<TextView>(R.id.menu_repeat_value).apply {
            text = lc.getString(when (loop) {
                1L -> R.string.w_menu_repeat_one
                2L -> R.string.w_menu_repeat_all
                else -> R.string.w_menu_off
            })
            setTextColor(if (loop != 0L) point else sub)
            paint.isFakeBoldText = loop != 0L
        }
        showSleep()
    }

    /// 수면 타이머 남은 시간(밀리초) — 음악·자연 'm' · 라디오 'r' 중 늦게 끝나는 것
    private fun sleepLeft(): Long {
        val fp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val end = maxOf(
            try { fp.getLong("flutter.w_sleep_m", 0L) } catch (_: Exception) { 0L },
            try { fp.getLong("flutter.w_sleep_r", 0L) } catch (_: Exception) { 0L })
        return end - System.currentTimeMillis()
    }

    /// 메뉴 줄의 '28분' / '1시간 5분' (꺼져 있으면 '꺼짐')
    private fun showSleep() {
        val left = sleepLeft()
        findViewById<TextView>(R.id.menu_sleep_value).apply {
            if (left > 0) {
                val mins = ((left + 59_999) / 60_000).toInt() // 올림 (59초 남아도 1분)
                text = if (mins >= 60) lc.getString(R.string.w_sleep_fmt_hm, mins / 60, mins % 60)
                       else lc.getString(R.string.w_sleep_fmt_m, mins)
                setTextColor(color(R.color.paran_w_point))
                paint.isFakeBoldText = true
            } else {
                text = lc.getString(R.string.w_menu_off)
                setTextColor(color(R.color.paran_w_sub))
                paint.isFakeBoldText = false
            }
            invalidate()
        }
    }

    private fun openDial() {
        findViewById<TextView>(R.id.menu_dial_title).text = lc.getString(R.string.w_sleep_ask)
        findViewById<TextView>(R.id.menu_dial_hint).text = lc.getString(R.string.w_sleep_hint)
        findViewById<TextView>(R.id.menu_hours_unit).text = lc.getString(R.string.w_unit_hr)
        findViewById<TextView>(R.id.menu_minutes_unit).text = lc.getString(R.string.w_unit_min)
        findViewById<TextView>(R.id.menu_sleep_set).text = lc.getString(R.string.w_sleep_set)
        findViewById<TextView>(R.id.menu_sleep_off).apply {
            text = lc.getString(R.string.w_sleep_cancel)
            visibility = if (sleepLeft() > 0) View.VISIBLE else View.GONE // 켜져 있을 때만
        }
        findViewById<View>(R.id.menu_list).visibility = View.GONE
        findViewById<View>(R.id.menu_dial).visibility = View.VISIBLE
    }

    private fun closeDial() {
        findViewById<View>(R.id.menu_dial).visibility = View.GONE
        findViewById<View>(R.id.menu_list).visibility = View.VISIBLE
    }

    private fun setSleep() {
        val mins = findViewById<NumberPicker>(R.id.menu_hours).value * 60 +
            findViewById<NumberPicker>(R.id.menu_minutes).value
        if (mins <= 0) return // 0시간 0분은 무시
        sleep(mins)
    }

    /// 수면 타이머 맞추기 (0이면 끄기) → 창 닫기, 위젯에 남은 시간은 앱이 저장하면 바로 보임
    private fun sleep(minutes: Int) {
        sendBroadcast(Intent(this, PlayerWidget::class.java)
            .setAction(PlayerWidget.ACTION_SLEEP).putExtra("minutes", minutes))
        finish()
    }

    override fun onDestroy() {
        h.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
'''
whole(ACT, 'class WidgetMenuActivity', 'menu_sleep', ACT_KT, '⋮ 창 코드 통째로 새로 (수면 타이머)')

# ═════════ strings.xml (23개 언어) ═════════
# (수면 타이머, 몇 시간 몇 분 후?, 1분 전부터 작아져요, 설정, 타이머 취소, 시간, 분) — 앱 번역(ARB)과 같은 말
SL = {
    'en': ('Sleep timer', 'Stop playing after how long?', 'Fades out during the last minute', 'Set', 'Cancel timer', 'hr', 'min'),
    'ko': ('수면 타이머', '몇 시간 몇 분 후 정지할까요?', '끝나기 1분 전부터 천천히 작아져요', '설정', '타이머 취소', '시간', '분'),
    'ja': ('スリープタイマー', '何時間何分後に停止しますか？', '終了1分前から少しずつ小さくなります', '設定', 'タイマーをキャンセル', '時間', '分'),
    'zh': ('睡眠计时器', '多久后停止播放？', '结束前1分钟开始逐渐变小', '设置', '取消计时器', '小时', '分'),
    'zh_Hant': ('睡眠計時器', '多久後停止播放？', '結束前1分鐘開始逐漸變小', '設定', '取消計時器', '小時', '分'),
    'de': ('Sleep-Timer', 'Wann soll die Wiedergabe stoppen?', 'Wird in der letzten Minute leiser', 'Festlegen', 'Timer beenden', 'Std.', 'Min.'),
    'es': ('Temporizador', '¿Detener después de cuánto tiempo?', 'Baja el volumen en el último minuto', 'Aplicar', 'Desactivar', 'h', 'min'),
    'fr': ('Minuteur de veille', 'Arrêter la lecture dans combien de temps ?', 'Baisse progressive du son la dernière minute', 'Définir', 'Désactiver', 'h', 'min'),
    'it': ('Timer di spegnimento', 'Fermare la riproduzione tra quanto?', "Il volume cala nell'ultimo minuto", 'Imposta', 'Annulla timer', 'h', 'min'),
    'pt': ('Temporizador de sono', 'Parar de tocar depois de quanto tempo?', 'O som diminui aos poucos no último minuto', 'Definir', 'Cancelar timer', 'h', 'min'),
    'ru': ('Таймер сна', 'Через сколько остановить?', 'В последнюю минуту звук плавно затихнет', 'Установить', 'Отменить таймер', 'ч', 'мин'),
    'uk': ('Таймер сну', 'Через скільки зупинити?', 'Звук стихає протягом останньої хвилини', 'Задати', 'Скасувати таймер', 'год', 'хв'),
    'pl': ('Minutnik uśpienia', 'Po jakim czasie zatrzymać?', 'W ostatniej minucie dźwięk stopniowo cichnie', 'Ustaw', 'Anuluj minutnik', 'godz.', 'min'),
    'cs': ('Časovač spánku', 'Za jak dlouho přehrávání zastavit?', 'V poslední minutě se zvuk ztiší', 'Nastavit', 'Zrušit časovač', 'h', 'min'),
    'hu': ('Elalvásidőzítő', 'Mennyi idő múlva álljon le?', 'Az utolsó percben fokozatosan elhalkul', 'Beállítás', 'Időzítő törlése', 'óra', 'perc'),
    'ro': ('Temporizator somn', 'Oprești redarea după cât timp?', 'Sunetul scade treptat în ultimul minut', 'Setează', 'Anulează temporizatorul', 'h', 'min'),
    'tr': ('Uyku zamanlayıcı', 'Ne kadar sonra dursun?', 'Son dakikada sesi yavaşça kısılır', 'Ayarla', 'İptal et', 'sa', 'dk'),
    'ar': ('مؤقت النوم', 'إيقاف التشغيل بعد كم من الوقت؟', 'يخفت الصوت تدريجيًا في الدقيقة الأخيرة', 'تعيين', 'إلغاء المؤقت', 'س', 'د'),
    'hi': ('स्लीप टाइमर', 'कितनी देर बाद बंद करें?', 'आख़िरी मिनट में धीरे-धीरे आवाज़ कम होगी', 'सेट करें', 'टाइमर रद्द करें', 'घंटे', 'मिनट'),
    'ur': ('سلیپ ٹائمر', 'کتنی دیر بعد بند کریں؟', 'آخری منٹ میں آواز آہستہ کم ہوتی ہے', 'سیٹ کریں', 'ٹائمر منسوخ کریں', 'گھنٹہ', 'منٹ'),
    'id': ('Timer tidur', 'Berhenti memutar setelah berapa lama?', 'Suara mengecil pelan di menit terakhir', 'Atur', 'Batalkan timer', 'jam', 'mnt'),
    'vi': ('Hẹn giờ tắt', 'Dừng phát sau bao lâu?', 'Âm lượng nhỏ dần trong phút cuối', 'Đặt', 'Hủy hẹn giờ', 'giờ', 'phút'),
    'th': ('ตั้งเวลาปิด', 'หยุดเล่นหลังจากนานเท่าไร', 'เสียงจะค่อยๆ เบาลงในนาทีสุดท้าย', 'ตั้งค่า', 'ยกเลิกตัวจับเวลา', 'ชม.', 'นาที'),
}
FOLDER = {'values': 'en', 'values-en': 'en', 'values-ko': 'ko', 'values-ja': 'ja', 'values-zh': 'zh',
          'values-zh-rTW': 'zh_Hant', 'values-zh-rHK': 'zh_Hant', 'values-zh-rMO': 'zh_Hant',
          'values-de': 'de', 'values-es': 'es', 'values-fr': 'fr', 'values-it': 'it', 'values-pt': 'pt',
          'values-ru': 'ru', 'values-uk': 'uk', 'values-pl': 'pl', 'values-cs': 'cs', 'values-hu': 'hu',
          'values-ro': 'ro', 'values-tr': 'tr', 'values-ar': 'ar', 'values-hi': 'hi', 'values-ur': 'ur',
          'values-in': 'id', 'values-vi': 'vi', 'values-th': 'th'}
NO_GAP = ('ko', 'ja', 'zh', 'zh_Hant')  # 숫자와 단위를 붙여 씀 (28분)


def esc(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('"', '\\"')


for folder, code in FOLDER.items():
    s = SL[code]
    gap = '' if code in NO_GAP else ' '
    fmt_m = f'%1$d{gap}{s[6]}'
    fmt_hm = f'%1$d{gap}{s[5]} %2$d{gap}{s[6]}'
    pairs = [('w_menu_sleep', s[0]), ('w_sleep_ask', s[1]), ('w_sleep_hint', s[2]), ('w_sleep_set', s[3]),
             ('w_sleep_cancel', s[4]), ('w_unit_hr', s[5]), ('w_unit_min', s[6]),
             ('w_sleep_fmt_m', fmt_m), ('w_sleep_fmt_hm', fmt_hm)]
    lines = '    <!-- 위젯 ⋮ 수면 타이머 -->\n' + ''.join(
        f'    <string name="{k}">{esc(v)}</string>\n' for k, v in pairs)
    rep(os.path.join(RES, folder, 'strings.xml'), '</resources>', lines + '</resources>', '수면 타이머 글자')

# ═════════ 확인 ═════════
def gaps(t):
    return [t.count(a) - t.count(b) for a, b in ('{}', '()', '[]')]

# 괄호: 고치기 전과 '열고 닫은 차이'가 같아야 함 (원래 글자 속 괄호 때문에 차이가 있을 수 있어서)
if ok:
    for p in (W, HR, PP, RP):
        if gaps(files[p][0]) != gaps(ORIG[p]):
            fail(os.path.basename(p) + ' — 괄호가 안 맞아요')
    if gaps(ACT_KT) != [0, 0, 0]:
        fail('WidgetMenuActivity.kt — 괄호가 안 맞아요')

if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

for p, body, label in NEW:
    files[p] = [body, True]
    print(f'✔ 새 파일 {os.path.basename(p)} — {label}')
for p, (body, crlf) in files.items():
    if crlf:
        body = body.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(body.encode('utf-8'))
print('\n다 됐어요! 위젯 ⋮ → 수면 타이머를 눌러 보세요.')
