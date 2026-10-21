# -*- coding: utf-8 -*-
# 위젯 수면 타이머 휠을 앱과 똑같이 + 안내 문구 다듬기
#  - 위젯 ⋮ → 수면 타이머: 앱처럼 아래에서 올라오는 창(위 모서리 20) + 아이폰식 휠(시간·분) + 포인트 색 '설정' 버튼
#  - 안내 문구: '끝나기 1분 전부터 천천히 작아져요' → '종료 1분 전부터 소리가 작아져요' (앱 · 위젯 모두)
# 새 파일: WheelView.kt · paran_sheet_bg.xml · paran_wheel_band.xml
# 통째로 새로: WidgetMenuActivity.kt · widget_menu.xml (③단계에서 만든 그대로일 때만)
# 고치는 파일: colors.xml(라이트·다크) · values-ko/strings.xml · app_ko.arb · app_localizations_ko.dart
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행 / 하나라도 못 찾으면 ❌ 띄우고 아무것도 저장 안 함
import os
import sys

MAIN = os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(MAIN, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(MAIN, 'res')

ok = True
files = {}


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
    t = load(path)
    if t is None:
        return
    if must_have not in t or must_not in t:
        fail(f'{os.path.basename(path)} — {label}: 예상한 모양이 아니라 멈춰요')
        return
    files[path][0] = body
    print(f'✔ {os.path.basename(path)} — {label}')


ACT = os.path.join(KT, 'WidgetMenuActivity.kt')
WHEEL_P = os.path.join(KT, 'WheelView.kt')
MENU = os.path.join(RES, 'layout', 'widget_menu.xml')
COL = os.path.join(RES, 'values', 'colors.xml')
COLN = os.path.join(RES, 'values-night', 'colors.xml')
KO = os.path.join(RES, 'values-ko', 'strings.xml')
ARB = os.path.join('lib', 'l10n', 'app_ko.arb')
GEN = os.path.join('lib', 'l10n', 'app_localizations_ko.dart')
SHEET = os.path.join(RES, 'drawable', 'paran_sheet_bg.xml')
BAND = os.path.join(RES, 'drawable', 'paran_wheel_band.xml')

if os.path.exists(WHEEL_P):
    print('이미 적용돼 있어요')
    sys.exit(0)
for p in (SHEET, BAND):
    if os.path.exists(p):
        fail(os.path.basename(p) + ' 파일이 벌써 있어요 — 덮어쓰지 않으려고 멈춰요')

WHEEL = '''package kr.ssing.catsong

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.View
import android.widget.OverScroller
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/// 앱 수면 타이머(아이폰식 휠)와 같은 모양의 숫자 휠
/// - 둥근 통 위에 숫자가 감긴 것처럼 위아래로 갈수록 납작하고 흐리게
/// - 가운데 줄은 조금 크게 · 진하게, 오른쪽에 단위(시간 · 분)가 고정
/// - 손가락으로 굴리고, 놓으면 가장 가까운 숫자에 딱 멈춤
class WheelView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : View(context, attrs) {

    var min = 0
    var max = 59
    var unit = ""
    var textColor = 0xFF000000.toInt()
        set(v) { field = v; invalidate() }
    var onChange: ((Int) -> Unit)? = null

    private val dp = resources.displayMetrics.density
    private val itemH = 32f * dp              // 한 줄 높이 (앱 휠과 같음)
    private val squeeze = 1.25f               // 줄 사이를 살짝 좁게 (앱 휠과 같음)
    private val gap = itemH / squeeze         // 실제 줄 간격
    private val dimAlpha = 0.447f             // 가운데가 아닌 줄의 진하기 (앱 휠과 같음)
    private val mag = 2.35f / 2.1f            // 가운데 줄 크게 (앱 휠과 같음)

    private val numPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = 20f * resources.displayMetrics.scaledDensity
        textAlign = Paint.Align.RIGHT
    }
    private val unitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = 20f * resources.displayMetrics.scaledDensity
        textAlign = Paint.Align.LEFT
        typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
    }

    private var pos = 0f                       // 지금 위치 (숫자 칸 단위, 소수 = 굴러가는 중)
    private val scroller = OverScroller(context)
    private var vt: VelocityTracker? = null
    private var lastY = 0f
    private var lastValue = -1

    val value: Int get() = (min + pos.roundToInt()).coerceIn(min, max)

    fun setValue(v: Int) {
        scroller.forceFinished(true)
        pos = (v - min).coerceIn(0, max - min).toFloat()
        lastValue = value
        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = MeasureSpec.getSize(widthMeasureSpec)
        val h = if (MeasureSpec.getMode(heightMeasureSpec) == MeasureSpec.UNSPECIFIED) (216 * dp).toInt()
                else MeasureSpec.getSize(heightMeasureSpec)
        setMeasuredDimension(w, h)
    }

    override fun onDraw(canvas: Canvas) {
        val cy = height / 2f
        val r = height * 1.07f / 2f            // 둥근 통 반지름 (앱 휠과 같은 비율)
        val numRight = width * 0.56f           // 숫자 오른쪽 끝 (단위 바로 왼쪽)
        val first = (pos - 8).toInt().coerceAtLeast(0)
        val last = (pos + 8).toInt().coerceAtMost(max - min)
        for (i in first..last) {
            val theta = (i - pos) * gap / r
            if (abs(theta) >= Math.PI / 2) continue
            val y = cy + r * sin(theta)
            val squash = cos(theta)
            val center = abs(y - cy) < itemH / 2
            numPaint.color = textColor
            numPaint.alpha = if (center) 255 else (255 * dimAlpha).toInt()
            canvas.save()
            canvas.translate(numRight, y)
            val s = if (center) mag else 1f
            canvas.scale(s, squash * s)
            val fm = numPaint.fontMetrics
            canvas.drawText((min + i).toString(), 0f, -(fm.ascent + fm.descent) / 2f, numPaint)
            canvas.restore()
        }
        // 단위 (가운데 줄 오른쪽에 고정)
        unitPaint.color = textColor
        val fm = unitPaint.fontMetrics
        canvas.drawText(unit, numRight + 8 * dp, cy - (fm.ascent + fm.descent) / 2f, unitPaint)
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (vt == null) vt = VelocityTracker.obtain()
        vt?.addMovement(e)
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                scroller.forceFinished(true)
                lastY = e.y
                parent?.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_MOVE -> {
                pos = (pos - (e.y - lastY) / gap).coerceIn(-0.4f, (max - min) + 0.4f)
                lastY = e.y
                changed()
                invalidate()
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                vt?.computeCurrentVelocity(1000)
                val v = vt?.yVelocity ?: 0f
                vt?.recycle(); vt = null
                if (abs(v) > 300 * dp && pos >= 0f && pos <= (max - min).toFloat()) {
                    val startPx = (pos * gap).toInt()
                    scroller.fling(0, startPx, 0, -v.toInt(), 0, 0, 0, ((max - min) * gap).toInt())
                    flinging = true
                } else {
                    snap()
                }
                postInvalidateOnAnimation()
            }
        }
        return true
    }

    private var flinging = false

    /// 가장 가까운 숫자로 부드럽게 맞추기
    private fun snap() {
        flinging = false
        val target = pos.roundToInt().coerceIn(0, max - min)
        val from = (pos * gap).toInt()
        scroller.startScroll(0, from, 0, (target * gap).toInt() - from, 220)
    }

    override fun computeScroll() {
        if (scroller.computeScrollOffset()) {
            pos = scroller.currY / gap
            changed()
            postInvalidateOnAnimation()
        } else if (flinging) {
            snap()
            postInvalidateOnAnimation()
        } else if (abs(pos - pos.roundToInt()) > 0.001f) {
            pos = pos.roundToInt().coerceIn(0, max - min).toFloat()
            changed()
            invalidate()
        }
    }

    private fun changed() {
        val v = value
        if (v != lastValue) {
            lastValue = v
            onChange?.invoke(v)
        }
    }
}
'''

SHEET_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 위젯 수면 타이머 창 (앱 수면 타이머처럼 아래에서 올라오는 창, 위 모서리만 20) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/paran_w_sheet" />
    <corners android:topLeftRadius="20dp" android:topRightRadius="20dp"
        android:bottomLeftRadius="0dp" android:bottomRightRadius="0dp" />
</shape>
'''
BAND_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 휠 가운데 고른 줄 띠 (앱 휠과 같은 연한 회색) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/paran_w_band" />
    <corners android:radius="8dp" />
</shape>
'''


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


MENU_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 위젯 ⋮ 메뉴 창 (WidgetMenuActivity) — 바깥(어두운 곳)을 누르면 닫힘 -->
<!-- menu_card: 메뉴 줄들 / menu_dial: 수면 타이머 (앱 수면 타이머 창과 같은 모양) -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/menu_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#59000000">

    <!-- ── 메뉴 줄들 (떠 있는 카드) ── -->
    <LinearLayout
        android:id="@+id/menu_card"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:layout_marginStart="14dp"
        android:layout_marginEnd="14dp"
        android:layout_marginBottom="24dp"
        android:background="@drawable/paran_menu_bg"
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
    + row('menu_sleep', None, 'paran_ic_timer', 'menu_sleep_label', 'menu_sleep_value') + '''    </LinearLayout>

    <!-- ── 수면 타이머 (앱처럼 아래에 붙어 올라오는 창) ── -->
    <LinearLayout
        android:id="@+id/menu_dial"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:background="@drawable/paran_sheet_bg"
        android:clickable="true"
        android:orientation="vertical"
        android:paddingTop="12dp"
        android:paddingBottom="12dp"
        android:visibility="gone">

        <!-- 제목 가운데 + 오른쪽 ✕ (앱과 같은 짜임) -->
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:paddingStart="12dp"
            android:paddingEnd="12dp">

            <FrameLayout
                android:layout_width="40dp"
                android:layout_height="32dp" />

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
                    android:fontFamily="sans-serif-medium"
                    android:gravity="center"
                    android:textColor="@color/paran_w_text"
                    android:textSize="16sp" />

                <TextView
                    android:id="@+id/menu_dial_hint"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginTop="3dp"
                    android:gravity="center"
                    android:textColor="@color/paran_w_hint"
                    android:textSize="12sp" />
            </LinearLayout>

            <FrameLayout
                android:id="@+id/menu_dial_close"
                android:layout_width="40dp"
                android:layout_height="32dp">

                <ImageView
                    android:layout_width="21dp"
                    android:layout_height="21dp"
                    android:layout_gravity="top|end"
                    android:layout_marginTop="2dp"
                    android:layout_marginEnd="2dp"
                    android:src="@drawable/paran_ic_close"
                    android:tint="@color/paran_w_sub" />
            </FrameLayout>
        </LinearLayout>

        <!-- 시간 · 분 휠 (높이 216, 가운데 연한 띠) — 아랍어에서도 왼쪽→오른쪽 -->
        <FrameLayout
            android:layout_width="320dp"
            android:layout_height="216dp"
            android:layout_gravity="center_horizontal"
            android:layoutDirection="ltr">

            <FrameLayout
                android:layout_width="match_parent"
                android:layout_height="32dp"
                android:layout_gravity="center_vertical"
                android:layout_marginStart="9dp"
                android:layout_marginEnd="9dp"
                android:background="@drawable/paran_wheel_band" />

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:orientation="horizontal">

                <kr.ssing.catsong.WheelView
                    android:id="@+id/menu_hours"
                    android:layout_width="0dp"
                    android:layout_height="match_parent"
                    android:layout_weight="1" />

                <kr.ssing.catsong.WheelView
                    android:id="@+id/menu_minutes"
                    android:layout_width="0dp"
                    android:layout_height="match_parent"
                    android:layout_weight="1" />
            </LinearLayout>
        </FrameLayout>

        <!-- 타이머 취소(켜져 있을 때만) · 설정 -->
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="48dp"
            android:orientation="horizontal"
            android:paddingStart="20dp"
            android:paddingEnd="20dp">

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
</FrameLayout>
'''

ACT_KT = '''package kr.ssing.catsong

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView

/// 위젯 ⋮ 를 누르면 바탕화면 위에 뜨는 작은 창 (앱 화면은 안 열림)
/// 랜덤 듣기 · 반복(음악일 때만) · 수면 타이머 / 바깥을 누르면 닫힘
/// 수면 타이머는 앱 수면 타이머와 같은 창(아래에서 올라옴 + 시간·분 휠 + 포인트 색 '설정')
/// 실제로 바꾸는 건 위젯 버튼과 같은 길(PlayerWidget)로 보냄
class WidgetMenuActivity : Activity() {

    private val h = Handler(Looper.getMainLooper())
    private lateinit var lc: Context
    private var navBottom = 0

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
        val dp = resources.displayMetrics.density
        // 시스템 바: 메뉴 카드는 그만큼 위로 띄우고, 수면 타이머 창은 바닥에 붙인 채 안쪽만 띄우기
        findViewById<View>(R.id.menu_root).setOnApplyWindowInsetsListener { v, insets ->
            @Suppress("DEPRECATION")
            navBottom = insets.systemWindowInsetBottom
            @Suppress("DEPRECATION")
            v.setPadding(0, insets.systemWindowInsetTop, 0, 0)
            val card = findViewById<View>(R.id.menu_card)
            (card.layoutParams as ViewGroup.MarginLayoutParams).bottomMargin = (24 * dp).toInt() + navBottom
            card.requestLayout()
            val dial = findViewById<View>(R.id.menu_dial)
            dial.setPadding(0, (12 * dp).toInt(), 0, (12 * dp).toInt() + navBottom)
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
        val text = color(R.color.paran_w_text)
        findViewById<WheelView>(R.id.menu_hours).apply {
            min = 0; max = 23; textColor = text; setValue(0)
        }
        findViewById<WheelView>(R.id.menu_minutes).apply {
            min = 0; max = 59; textColor = text; setValue(30)
        }
        show()
        h.post(tick)
    }

    @Suppress("DEPRECATION")
    private fun color(id: Int) = resources.getColor(id)

    private fun isNight() =
        (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    /// 앱에서 고른 포인트 색 그대로 (설정 → 포인트 색) — 앱 수면 타이머 '설정' 버튼과 같은 색
    private fun primary(): Int {
        val fp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return try { fp.getLong("flutter.primaryColor", 0xFF2589E8L).toInt() } catch (_: Exception) { 0xFF2589E8.toInt() }
    }

    /// 앱 pointColorOf 와 같은 규칙 — 기본(파란소리)이면 라이트 #2F7DE8 · 다크 #6FB0FF,
    /// 다른 색이면 그대로 (다크에서 너무 어두운 색이면 살짝 밝게)
    private fun point(): Int {
        val p = primary()
        val night = isNight()
        if (p == 0xFF2589E8.toInt()) return if (night) 0xFF6FB0FF.toInt() else 0xFF2F7DE8.toInt()
        if (night && luminance(p) < 0.08) {
            fun mix(c: Int) = (c + (255 - c) * 0.45).toInt()
            return Color.rgb(mix(Color.red(p)), mix(Color.green(p)), mix(Color.blue(p)))
        }
        return p
    }

    private fun luminance(c: Int): Double {
        fun ch(v: Int): Double {
            val s = v / 255.0
            return if (s <= 0.03928) s / 12.92 else Math.pow((s + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * ch(Color.red(c)) + 0.7152 * ch(Color.green(c)) + 0.0722 * ch(Color.blue(c))
    }

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
        val point = point()
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
                setTextColor(point())
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
        findViewById<WheelView>(R.id.menu_hours).unit = lc.getString(R.string.w_unit_hr)
        findViewById<WheelView>(R.id.menu_minutes).unit = lc.getString(R.string.w_unit_min)
        findViewById<TextView>(R.id.menu_sleep_set).apply {
            text = lc.getString(R.string.w_sleep_set)
            backgroundTintList = ColorStateList.valueOf(primary()) // 앱과 같은 포인트 색
        }
        findViewById<TextView>(R.id.menu_sleep_off).apply {
            text = lc.getString(R.string.w_sleep_cancel)
            visibility = if (sleepLeft() > 0) View.VISIBLE else View.GONE // 켜져 있을 때만
        }
        findViewById<View>(R.id.menu_card).visibility = View.GONE
        findViewById<View>(R.id.menu_dial).visibility = View.VISIBLE
    }

    private fun closeDial() {
        findViewById<View>(R.id.menu_dial).visibility = View.GONE
        findViewById<View>(R.id.menu_card).visibility = View.VISIBLE
    }

    private fun setSleep() {
        val mins = findViewById<WheelView>(R.id.menu_hours).value * 60 +
            findViewById<WheelView>(R.id.menu_minutes).value
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

whole(MENU, 'menu_sleep', 'menu_wheel', MENU_XML, '⋮ 창 화면 통째로 새로 (수면 타이머를 앱과 같은 창으로)')
whole(ACT, 'NumberPicker', 'WheelView', ACT_KT, '⋮ 창 코드 통째로 새로 (앱과 같은 휠)')

rep(COL, '''    <color name="paran_w_point">#2F7DE8</color>''', '''    <color name="paran_w_point">#2F7DE8</color>
    <color name="paran_w_sheet">#F4EFE5</color>
    <color name="paran_w_band">#1F767680</color>
    <color name="paran_w_text">#000000</color>
    <color name="paran_w_hint">#80000000</color>''', '수면 타이머 창 색 (라이트, 앱과 같은 값)')
rep(COLN, '''    <color name="paran_w_point">#6FB0FF</color>''', '''    <color name="paran_w_point">#6FB0FF</color>
    <color name="paran_w_sheet">#32302C</color>
    <color name="paran_w_band">#3D767680</color>
    <color name="paran_w_text">#FFFFFF</color>
    <color name="paran_w_hint">#80FFFFFF</color>''', '수면 타이머 창 색 (다크, 앱과 같은 값)')

OLD_KO = '끝나기 1분 전부터 천천히 작아져요'
NEW_KO = '종료 1분 전부터 소리가 작아져요'
rep(KO, f'<string name="w_sleep_hint">{OLD_KO}</string>', f'<string name="w_sleep_hint">{NEW_KO}</string>',
    '안내 문구 다듬기 (위젯)')
rep(ARB, f'"sleepFadeHint": "{OLD_KO}"', f'"sleepFadeHint": "{NEW_KO}"', '안내 문구 다듬기 (앱)')
rep(GEN, f"String get sleepFadeHint => '{OLD_KO}';", f"String get sleepFadeHint => '{NEW_KO}';",
    '안내 문구 다듬기 (앱 번역 파일)')


def gaps(t):
    return [t.count(a) - t.count(b) for a, b in ('{}', '()', '[]')]

if ok:
    if gaps(ACT_KT) != [0, 0, 0]:
        fail('WidgetMenuActivity.kt — 괄호가 안 맞아요')
    if gaps(WHEEL) != [0, 0, 0]:
        fail('WheelView.kt — 괄호가 안 맞아요')

if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

files[WHEEL_P] = [WHEEL, True]
files[SHEET] = [SHEET_XML, True]
files[BAND] = [BAND_XML, True]
print('✔ 새 파일 WheelView.kt — 앱과 같은 모양의 시간·분 휠')
print('✔ 새 파일 paran_sheet_bg.xml — 아래에서 올라오는 창 바탕')
print('✔ 새 파일 paran_wheel_band.xml — 휠 가운데 띠')
for p, (body, crlf) in files.items():
    if crlf:
        body = body.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(body.encode('utf-8'))
print('\n다 됐어요! 위젯 ⋮ → 수면 타이머를 눌러 보세요.')
