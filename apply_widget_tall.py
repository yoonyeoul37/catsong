# -*- coding: utf-8 -*-
# 세로 위젯 2×3 (A안) 추가 + 랜덤·반복 아이콘 부드럽게
#  - 새 파일: PlayerWidget3.kt · widget_player3.xml · widget_info3.xml · 아이콘·바탕 그림 5개
#  - 고치는 파일: PlayerWidget.kt · AndroidManifest.xml · colors.xml(라이트·다크)
#  - 바꾸는 아이콘: paran_ic_shuffle · paran_ic_repeat · paran_ic_repeat_one (4×2·4×3 위젯도 같이)
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행
# 하나라도 못 찾으면 ❌ 띄우고 아무것도 저장 안 함
import os
import sys

MAIN = os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(MAIN, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(MAIN, 'res')

ok = True
writes = []  # (경로, 글, CRLF 여부)


def fail(msg):
    global ok
    ok = False
    print('❌ ' + msg)


def load(path):
    if not os.path.exists(path):
        fail(path + ' 파일이 없어요 (프로젝트 폴더에서 실행했는지 확인)')
        return None, True
    with open(path, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def rep(text, old, new, label, name):
    if text is None:
        return None
    n = text.count(old)
    if n != 1:
        fail(f'{name} — {label}: 찾을 코드를 못 찾았어요' if n == 0 else f'{name} — {label}: 같은 코드가 {n}군데라 못 고쳐요')
        return text
    print(f'✔ {name} — {label}')
    return text.replace(old, new)


# ───────────────── 새 파일 ─────────────────
STROKE = ('android:fillColor="#00000000" android:strokeColor="#FFFFFFFF" android:strokeWidth="1.9" '
          'android:strokeLineCap="round" android:strokeLineJoin="round"')


def vector(comment, paths):
    body = '\n'.join(f'    <path {STROKE}\n        android:pathData="{p}" />' for p in paths)
    return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- {comment} -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
{body}
</vector>
'''


SHUFFLE = vector('랜덤 듣기 (끝이 둥근 선 아이콘)', [
    'M3.5,7H6c2,0 3.2,0.9 4.3,2.6l3.4,4.8C14.8,16.1 16,17 18,17h2.5',
    'M3.5,17H6c1.5,0 2.6,-0.5 3.5,-1.5',
    'M14.5,8.5c0.9,-1 2,-1.5 3.5,-1.5h2.5',
    'M18,4.5L20.5,7L18,9.5',
    'M18,14.5L20.5,17L18,19.5',
])
REPEAT_PATHS = [
    'M17,3.5L19.5,6L17,8.5',
    'M4.5,11.5V10a4,4 0,0 1,4 -4h11',
    'M7,20.5L4.5,18L7,15.5',
    'M19.5,12.5V14a4,4 0,0 1,-4 4h-11',
]
REPEAT = vector('반복 (끝이 둥근 선 아이콘)', REPEAT_PATHS)
REPEAT_ONE = vector('한 곡 반복 (끝이 둥근 선 아이콘)', REPEAT_PATHS + ['M11,10.6l1.2,-0.6v4.2'])
TIMER = vector('수면 타이머 (시계)', [
    'M12,13m-7.5,0a7.5,7.5 0,1 1,15 0a7.5,7.5 0,1 1,-15 0',
    'M12,9.5V13l2.2,1.6',
    'M9.5,2.8h5',
])
PHOTO = vector('위젯 사진 바꾸기', [
    'M6.5,4.5h11a3,3 0,0 1,3 3v9a3,3 0,0 1,-3 3h-11a3,3 0,0 1,-3 -3v-9a3,3 0,0 1,3 -3z',
    'M9,10m-1.6,0a1.6,1.6 0,1 1,3.2 0a1.6,1.6 0,1 1,-3.2 0',
    'M5,18l4.5,-4.5 3,3 2.5,-2.5 4,4',
])
MORE = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 세로 위젯 ⋮ 버튼 -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF" android:pathData="M12,8a2,2 0,1 0,0 -4a2,2 0,0 0,0 4zM12,10a2,2 0,1 0,0 4a2,2 0,0 0,0 -4zM12,16a2,2 0,1 0,0 4a2,2 0,0 0,0 -4z" />
</vector>
'''
PLAY_INK = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 세로 위젯 재생 버튼 동그라미 (라이트 먹색 · 다크 크림색) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="@color/paran_w_ink" />
</shape>
'''
BADGE = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 세로 위젯 사진 위 작은 칸 (⋮ 버튼 · 남은 시간) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#59000000" />
    <corners android:radius="12dp" />
</shape>
'''
INFO3 = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 홈 위젯 세로 2×3: 위 사진 + 아래 제목 · 이전/재생/다음 · 바로가기 4개 -->
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="130dp"
    android:minHeight="220dp"
    android:minResizeWidth="130dp"
    android:minResizeHeight="200dp"
    android:targetCellWidth="2"
    android:targetCellHeight="3"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/widget_player3"
    android:previewLayout="@layout/widget_player3"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen">
</appwidget-provider>
'''
WIDGET3_KT = '''package kr.ssing.catsong

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/// 홈 위젯 세로 2×3: 위 사진 + 아래 제목 · 이전/재생/다음 · 바로가기 4개
/// 그리기·버튼은 모두 PlayerWidget이 같이 함 (모양만 다른 것)
class PlayerWidget3 : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) PlayerWidget.updateAppWidget(context, appWidgetManager, id)
    }

    // 바탕화면에서 위젯 크기를 바꾸면 사진도 새 크기에 맞게
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager,
                                           appWidgetId: Int, newOptions: android.os.Bundle) {
        PlayerWidget.updateAppWidget(context, appWidgetManager, appWidgetId)
    }
}
'''


def shortcut(vid, icon, label):
    return f'''        <FrameLayout
            android:id="@+id/{vid}"
            android:layout_width="0dp"
            android:layout_height="match_parent"
            android:layout_weight="1"
            android:contentDescription="@string/{label}">

            <ImageView
                android:layout_width="20dp"
                android:layout_height="20dp"
                android:layout_gravity="center"
                android:src="@drawable/{icon}"
                android:tint="@color/paran_w_sub" />
        </FrameLayout>
'''


LAYOUT3 = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 홈 위젯 세로 2×3 (A안): 위 사진 + 아래 크림 칸 (제목 · 이전/재생/다음 · 바로가기 아이콘 4개) -->
<!-- 아래 칸 높이 148dp는 PlayerWidget.kt TALL_BOTTOM 과 같아야 함 (사진 자르는 크기) -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@android:id/background"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/paran_widget_bg"
    android:clipToOutline="true"
    android:orientation="vertical">

    <!-- 위: 사진 (누르면 앱 열기) -->
    <FrameLayout
        android:id="@+id/widget_top"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1">

        <ImageView
            android:id="@+id/widget_photo"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:scaleType="fitXY"
            android:src="@drawable/paran_widget_photo_empty" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="top|start"
            android:layout_marginStart="12dp"
            android:layout_marginTop="10dp"
            android:shadowColor="#66000000"
            android:shadowDy="1"
            android:shadowRadius="4"
            android:text="Paransori"
            android:textColor="#F2FFFFFF"
            android:textSize="11.5sp"
            android:textStyle="bold" />

        <!-- ⋮ 메뉴 (다음 단계에서 켬) -->
        <ImageView
            android:id="@+id/widget_more"
            android:layout_width="28dp"
            android:layout_height="28dp"
            android:layout_gravity="top|end"
            android:layout_marginTop="6dp"
            android:layout_marginEnd="6dp"
            android:background="@drawable/paran_widget_badge"
            android:padding="6dp"
            android:src="@drawable/paran_ic_more"
            android:tint="#FFFFFF"
            android:visibility="gone" />

        <!-- 수면 타이머 남은 시간 (다음 단계에서 켬) -->
        <LinearLayout
            android:id="@+id/widget_timer"
            android:layout_width="wrap_content"
            android:layout_height="22dp"
            android:layout_gravity="bottom|end"
            android:layout_marginEnd="8dp"
            android:layout_marginBottom="8dp"
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

            <TextView
                android:id="@+id/widget_timer_text"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text=""
                android:textColor="#FFFFFF"
                android:textSize="10sp"
                android:textStyle="bold" />
        </LinearLayout>
    </FrameLayout>

    <!-- 아래: 크림 칸 (148dp) -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="148dp"
        android:orientation="vertical">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:paddingStart="13dp"
            android:paddingTop="10dp"
            android:paddingEnd="13dp">

            <TextView
                android:id="@+id/widget_title"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:maxLines="1"
                android:text="@string/app_name"
                android:textColor="@color/paran_w_ink"
                android:textSize="14sp"
                android:textStyle="bold" />

            <TextView
                android:id="@+id/widget_artist"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="1dp"
                android:ellipsize="end"
                android:maxLines="1"
                android:text="@string/widget_idle_sub"
                android:textColor="@color/paran_w_sub"
                android:textSize="11sp" />

            <TextView
                android:id="@+id/widget_schedule"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:maxLines="1"
                android:text=""
                android:textColor="@color/paran_w_sub"
                android:textSize="10sp"
                android:visibility="gone" />
        </LinearLayout>

        <!-- 이전 · 재생 · 다음 -->
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1"
            android:gravity="center"
            android:orientation="horizontal"
            android:paddingStart="6dp"
            android:paddingEnd="6dp">

            <ImageView
                android:id="@+id/widget_prev"
                android:layout_width="40dp"
                android:layout_height="40dp"
                android:padding="9dp"
                android:src="@drawable/paran_ic_prev"
                android:tint="@color/paran_w_ink" />

            <ImageView
                android:id="@+id/widget_play_pause"
                android:layout_width="44dp"
                android:layout_height="44dp"
                android:layout_marginStart="8dp"
                android:layout_marginEnd="8dp"
                android:background="@drawable/paran_widget_play_ink"
                android:padding="11dp"
                android:src="@drawable/paran_ic_play"
                android:tint="@color/paran_w_bg" />

            <ImageView
                android:id="@+id/widget_next"
                android:layout_width="40dp"
                android:layout_height="40dp"
                android:padding="9dp"
                android:src="@drawable/paran_ic_next"
                android:tint="@color/paran_w_ink" />
        </LinearLayout>

        <!-- 얇은 줄 -->
        <View
            android:layout_width="match_parent"
            android:layout_height="1dp"
            android:layout_marginStart="12dp"
            android:layout_marginEnd="12dp"
            android:background="@color/paran_w_line" />

        <!-- 바로가기 4개 (아이콘만) -->
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="42dp"
            android:layout_marginStart="6dp"
            android:layout_marginEnd="6dp"
            android:orientation="horizontal">

''' + shortcut('widget_go_music', 'paran_ic_music', 'tab_music') \
    + '\n' + shortcut('widget_go_radio', 'paran_ic_radio', 'tab_radio') \
    + '\n' + shortcut('widget_go_nature', 'paran_ic_leaf', 'tab_nature') \
    + '\n' + shortcut('widget_go_sleep', 'paran_ic_moon', 'tab_sleep') + '''        </LinearLayout>
    </LinearLayout>
</LinearLayout>
'''

NEW_FILES = [
    (os.path.join(KT, 'PlayerWidget3.kt'), WIDGET3_KT, '세로 위젯 코드'),
    (os.path.join(RES, 'layout', 'widget_player3.xml'), LAYOUT3, '세로 위젯 화면'),
    (os.path.join(RES, 'xml', 'widget_info3.xml'), INFO3, '세로 위젯 크기 정보'),
    (os.path.join(RES, 'drawable', 'paran_widget_play_ink.xml'), PLAY_INK, '재생 버튼 동그라미'),
    (os.path.join(RES, 'drawable', 'paran_widget_badge.xml'), BADGE, '사진 위 작은 칸'),
    (os.path.join(RES, 'drawable', 'paran_ic_more.xml'), MORE, '⋮ 아이콘'),
    (os.path.join(RES, 'drawable', 'paran_ic_timer.xml'), TIMER, '수면 타이머 아이콘'),
    (os.path.join(RES, 'drawable', 'paran_ic_photo.xml'), PHOTO, '사진 바꾸기 아이콘'),
]
ICONS = [
    (os.path.join(RES, 'drawable', 'paran_ic_shuffle.xml'), SHUFFLE, '랜덤 아이콘 부드럽게'),
    (os.path.join(RES, 'drawable', 'paran_ic_repeat.xml'), REPEAT, '반복 아이콘 부드럽게'),
    (os.path.join(RES, 'drawable', 'paran_ic_repeat_one.xml'), REPEAT_ONE, '한 곡 반복 아이콘 부드럽게'),
]

# ───────────────── 이미 적용됐는지 ─────────────────
W_PATH = os.path.join(KT, 'PlayerWidget.kt')
M_PATH = os.path.join(MAIN, 'AndroidManifest.xml')
C_PATH = os.path.join(RES, 'values', 'colors.xml')
CN_PATH = os.path.join(RES, 'values-night', 'colors.xml')

w_text, w_crlf = load(W_PATH)
m_text, m_crlf = load(M_PATH)
c_text, c_crlf = load(C_PATH)
cn_text, cn_crlf = load(CN_PATH)
for p, _, _ in ICONS:
    if not os.path.exists(p):
        fail(p + ' 파일이 없어요')
if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

if ('PlayerWidget3' in w_text and '.PlayerWidget3' in m_text
        and all(os.path.exists(p) for p, _, _ in NEW_FILES)):
    print('이미 적용돼 있어요')
    sys.exit(0)

# ───────────────── PlayerWidget.kt ─────────────────
N = 'PlayerWidget.kt'
w_text = rep(w_text,
    '''        /// 바탕화면에 붙은 파란소리 위젯 전부 (4×2 + 4×3)
        fun allIds(context: Context): IntArray {
            val mgr = AppWidgetManager.getInstance(context)
            return mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget::class.java)) +
                mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget2::class.java))
        }''',
    '''        /// 바탕화면에 붙은 파란소리 위젯 전부 (4×2 + 4×3 + 세로 2×3)
        fun allIds(context: Context): IntArray {
            val mgr = AppWidgetManager.getInstance(context)
            return mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget::class.java)) +
                mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget2::class.java)) +
                mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget3::class.java))
        }''',
    '세로 위젯도 같이 다시 그리기', N)

w_text = rep(w_text,
    '''            val big = appWidgetManager.getAppWidgetInfo(appWidgetId)?.provider?.className == PlayerWidget2::class.java.name
            val views = RemoteViews(context.packageName, if (big) R.layout.widget_player2 else R.layout.widget_player)''',
    '''            val cls = appWidgetManager.getAppWidgetInfo(appWidgetId)?.provider?.className
            val big = cls == PlayerWidget2::class.java.name
            // 세로 2×3이면 위 사진 + 아래 크림 칸 (제목 · 버튼 · 바로가기 아이콘만)
            val tall = cls == PlayerWidget3::class.java.name
            val views = RemoteViews(context.packageName,
                if (tall) R.layout.widget_player3 else if (big) R.layout.widget_player2 else R.layout.widget_player)''',
    '세로 위젯 모양 고르기', N)

w_text = rep(w_text,
    '''            views.setTextViewText(R.id.widget_go_music_label, lc.getString(R.string.tab_music))
            views.setTextViewText(R.id.widget_go_radio_label, lc.getString(R.string.tab_radio))
            views.setTextViewText(R.id.widget_go_nature_label, lc.getString(R.string.tab_nature))
            views.setTextViewText(R.id.widget_go_sleep_label, lc.getString(R.string.tab_sleep))''',
    '''            if (tall) {
                // 세로 위젯은 바로가기 글자 없이 아이콘만 → 읽어 주기용 이름만
                views.setContentDescription(R.id.widget_go_music, lc.getString(R.string.tab_music))
                views.setContentDescription(R.id.widget_go_radio, lc.getString(R.string.tab_radio))
                views.setContentDescription(R.id.widget_go_nature, lc.getString(R.string.tab_nature))
                views.setContentDescription(R.id.widget_go_sleep, lc.getString(R.string.tab_sleep))
            } else {
                views.setTextViewText(R.id.widget_go_music_label, lc.getString(R.string.tab_music))
                views.setTextViewText(R.id.widget_go_radio_label, lc.getString(R.string.tab_radio))
                views.setTextViewText(R.id.widget_go_nature_label, lc.getString(R.string.tab_nature))
                views.setTextViewText(R.id.widget_go_sleep_label, lc.getString(R.string.tab_sleep))
            }''',
    '바로가기 글자 (세로 위젯은 아이콘만)', N)

w_text = rep(w_text,
    '''            views.setViewVisibility(R.id.widget_modes, if (music && !empty) View.VISIBLE else View.GONE)''',
    '''            // 세로 위젯은 사진 위 랜덤·반복 버튼 없음 (⋮ 메뉴 안으로)
            if (!tall) {
            views.setViewVisibility(R.id.widget_modes, if (music && !empty) View.VISIBLE else View.GONE)''',
    '랜덤·반복 버튼 (세로 위젯은 빼기) 1', N)

w_text = rep(w_text,
    '''            mode(R.id.widget_shuffle, shuf)
''',
    '''            mode(R.id.widget_shuffle, shuf)
            }
''',
    '랜덤·반복 버튼 (세로 위젯은 빼기) 2', N)

w_text = rep(w_text,
    '''            val bottomDp = if (big) 54 + recentRows(context, views, if (empty) null else t) else 64
            photo(context, appWidgetManager, appWidgetId, bottomDp, big)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }''',
    '''            // 세로 2×3: 아래 크림 칸 148 (widget_player3.xml 과 같은 값)
            val bottomDp = if (tall) TALL_BOTTOM else if (big) 54 + recentRows(context, views, if (empty) null else t) else 64
            photo(context, appWidgetManager, appWidgetId, bottomDp, big, tall)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }''',
    '사진 칸 크기 (세로 위젯)', N)

w_text = rep(w_text,
    '''            views.setOnClickPendingIntent(R.id.widget_repeat, media(ACTION_REPEAT, 4))
            views.setOnClickPendingIntent(R.id.widget_shuffle, media(ACTION_SHUFFLE, 5))''',
    '''            if (!tall) { // 세로 위젯엔 이 버튼이 없음 (없는 버튼을 건드리면 위젯이 안 뜸)
                views.setOnClickPendingIntent(R.id.widget_repeat, media(ACTION_REPEAT, 4))
                views.setOnClickPendingIntent(R.id.widget_shuffle, media(ACTION_SHUFFLE, 5))
            }''',
    '랜덤·반복 누르기 (세로 위젯은 빼기)', N)

w_text = rep(w_text,
    '''        private const val LOAD_MAX = 10000L  // '불러오는 중…' 은 길어도 10초까지만''',
    '''        private const val LOAD_MAX = 10000L  // '불러오는 중…' 은 길어도 10초까지만
        private const val TALL_BOTTOM = 148  // 세로 2×3 위젯 아래 크림 칸 높이(dp)''',
    '세로 위젯 아래 칸 높이 값', N)

w_text = rep(w_text,
    '''        private fun photo(context: Context, mgr: AppWidgetManager, id: Int, bottomDp: Int, big: Boolean): Bitmap? {''',
    '''        private fun photo(context: Context, mgr: AppWidgetManager, id: Int, bottomDp: Int, big: Boolean,
                          tall: Boolean = false): Bitmap? {''',
    '사진 만들기 (세로 위젯 받기)', N)

w_text = rep(w_text,
    '''?: if (big) 280 else 180) - bottomDp)''',
    '''?: if (tall) 270 else if (big) 280 else 180) - bottomDp)''',
    '사진 기본 높이 (세로 위젯)', N)

w_text = rep(w_text,
    '''                c.drawRect(0f, 0f, w.toFloat(), bh.toFloat(), Paint().apply {
                    shader = LinearGradient(0f, bh * 0.25f, 0f, bh.toFloat(),
                        0x00000000, 0x99000000.toInt(), Shader.TileMode.CLAMP)
                })''',
    '''                if (tall) {
                    // 세로 위젯: 글자가 사진 밖(아래 크림 칸)이라 위쪽만 살짝 (Paransori · ⋮ 잘 보이게)
                    c.drawRect(0f, 0f, w.toFloat(), bh.toFloat(), Paint().apply {
                        shader = LinearGradient(0f, 0f, 0f, bh * 0.45f,
                            0x47000000, 0x00000000, Shader.TileMode.CLAMP)
                    })
                } else {
                    c.drawRect(0f, 0f, w.toFloat(), bh.toFloat(), Paint().apply {
                        shader = LinearGradient(0f, bh * 0.25f, 0f, bh.toFloat(),
                            0x00000000, 0x99000000.toInt(), Shader.TileMode.CLAMP)
                    })
                }''',
    '사진 어둡게 하는 곳 (세로 위젯은 위쪽만)', N)

# ───────────────── AndroidManifest.xml ─────────────────
m_text = rep(m_text,
    '''                android:resource="@xml/widget_info2" />
        </receiver>''',
    '''                android:resource="@xml/widget_info2" />
        </receiver>

        <!-- 홈 위젯 세로 2×3 (버튼은 모두 PlayerWidget이 받음) -->
        <receiver
            android:name=".PlayerWidget3"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_info3" />
        </receiver>''',
    '세로 위젯 등록', 'AndroidManifest.xml')

# ───────────────── colors.xml ─────────────────
c_text = rep(c_text,
    '''    <color name="paran_w_sub">#5A5348</color>''',
    '''    <color name="paran_w_sub">#5A5348</color>
    <color name="paran_w_line">#1417140F</color>''',
    '얇은 줄 색 (라이트)', 'values/colors.xml')
cn_text = rep(cn_text,
    '''    <color name="paran_w_sub">#CFC8BB</color>''',
    '''    <color name="paran_w_sub">#CFC8BB</color>
    <color name="paran_w_line">#1AF3EFE7</color>''',
    '얇은 줄 색 (다크)', 'values-night/colors.xml')

# ───────────────── 새 파일 · 아이콘 ─────────────────
for p, body, label in NEW_FILES:
    if os.path.exists(p):
        fail(f'{os.path.basename(p)} 파일이 벌써 있어요 — 덮어쓰지 않으려고 멈춰요')
    else:
        writes.append((p, body, True))
        print(f'✔ 새 파일 {os.path.basename(p)} — {label}')
for p, body, label in ICONS:
    writes.append((p, body, True))
    print(f'✔ {os.path.basename(p)} — {label}')

# ───────────────── 괄호 확인 ─────────────────
def balanced(t):
    return t.count('{') == t.count('}') and t.count('(') == t.count(')')

if ok:
    if not balanced(w_text):
        fail('PlayerWidget.kt — 괄호가 안 맞아요')
    for p, body, _ in NEW_FILES:
        if p.endswith('.kt') and not balanced(body):
            fail(os.path.basename(p) + ' — 괄호가 안 맞아요')

if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

writes += [(W_PATH, w_text, w_crlf), (M_PATH, m_text, m_crlf), (C_PATH, c_text, c_crlf), (CN_PATH, cn_text, cn_crlf)]
for p, body, crlf in writes:
    if crlf:
        body = body.replace('\r\n', '\n').replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(body.encode('utf-8'))
print('\n다 됐어요! 폰 바탕화면 → 위젯 → 파란소리에서 세로 위젯(2×3)을 찾아 붙여 보세요.')
