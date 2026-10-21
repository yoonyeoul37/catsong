# -*- coding: utf-8 -*-
# 위젯 사진 바꾸기 (④단계)
#  - ⋮ 창에 '위젯 사진 바꾸기' → 폰 사진 고르기(사진 권한 필요 없음) → 자르기(움직이고 두 손가락으로 키우기) → 완료
#  - 사진 한 장을 세 위젯(4×2 · 4×3 · 세로 2×3)이 같이 씀 — 정한 곳을 가운데로 위젯마다 알맞게 자름
#  - '기본 사진으로': 직접 넣은 사진이 있을 때만 보임 → 원래 사진(하루 한 장)으로
# 새 파일: CropView.kt · paran_ic_reset.xml
# 통째로 새로: WidgetMenuActivity.kt · widget_menu.xml (③ 다듬기 그대로일 때만)
# 고치는 파일: PlayerWidget.kt · AndroidManifest.xml · strings.xml 26개
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행 / 하나라도 못 찾으면 ❌ 띄우고 아무것도 저장 안 함
import os
import sys

MAIN = os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(MAIN, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(MAIN, 'res')

ok = True
files = {}
ORIG = {}


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


def cut(path, start, end, new, label):
    t = load(path)
    if t is None:
        return
    name = os.path.basename(path)
    if t.count(start) != 1:
        fail(f'{name} — {label}: 시작 위치를 못 찾았어요')
        return
    i = t.index(start)
    j = t.find(end, i)
    if j < 0:
        fail(f'{name} — {label}: 끝 위치를 못 찾았어요')
        return
    files[path][0] = t[:i] + new + t[j + len(end):]
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


W = os.path.join(KT, 'PlayerWidget.kt')
ACT = os.path.join(KT, 'WidgetMenuActivity.kt')
CROP_P = os.path.join(KT, 'CropView.kt')
MENU = os.path.join(RES, 'layout', 'widget_menu.xml')
MAN = os.path.join(MAIN, 'AndroidManifest.xml')
RESET = os.path.join(RES, 'drawable', 'paran_ic_reset.xml')

if os.path.exists(CROP_P):
    print('이미 적용돼 있어요')
    sys.exit(0)
if os.path.exists(RESET):
    fail('paran_ic_reset.xml 파일이 벌써 있어요 — 덮어쓰지 않으려고 멈춰요')

ACT_KT = '''package kr.ssing.catsong

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
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
/// 위젯 사진 바꾸기: 폰 사진 고르기(권한 필요 없음) → 자르기 → 세 위젯 모두 그 사진
/// 실제로 바꾸는 건 위젯 버튼과 같은 길(PlayerWidget)로 보냄
class WidgetMenuActivity : Activity() {

    private val h = Handler(Looper.getMainLooper())
    private lateinit var lc: Context
    private var navBottom = 0
    private var aspect = 2f          // 누른 위젯의 사진 칸 모양 (가로 ÷ 세로) — 자르기 틀
    private var picked: Bitmap? = null

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
        aspect = intent.getFloatExtra("aspect", 2f)
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
            val bar = findViewById<View>(R.id.menu_crop_bar)
            bar.setPadding(bar.paddingLeft, bar.paddingTop, bar.paddingRight, (20 * dp).toInt() + navBottom)
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
        findViewById<View>(R.id.menu_photo).setOnClickListener { pickPhoto() }
        findViewById<View>(R.id.menu_photo_reset).setOnClickListener { resetPhoto() }
        findViewById<View>(R.id.menu_crop_cancel).setOnClickListener { closeCrop() }
        findViewById<View>(R.id.menu_crop_done).setOnClickListener { savePhoto() }

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
        findViewById<TextView>(R.id.menu_photo_label).text = lc.getString(R.string.w_photo_change)
        findViewById<TextView>(R.id.menu_photo_value).text = "›"
        findViewById<TextView>(R.id.menu_photo_reset_label).text = lc.getString(R.string.w_photo_reset)
        // '기본 사진으로'는 직접 넣은 사진이 있을 때만
        findViewById<View>(R.id.menu_photo_reset).visibility =
            if (photoFile().exists()) View.VISIBLE else View.GONE
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

    // ───── 위젯 사진 바꾸기 ─────
    private fun photoFile() = java.io.File(filesDir, "widget_photo.jpg")

    /// 폰 사진 고르기 화면 (안드로이드 13 이상: 사진 선택 도구 / 그 밑: 파일에서 고르기) — 사진 권한 필요 없음
    private fun pickPhoto() {
        val i = if (android.os.Build.VERSION.SDK_INT >= 33) {
            Intent(MediaStore.ACTION_PICK_IMAGES)
        } else {
            Intent(Intent.ACTION_GET_CONTENT).setType("image/*").addCategory(Intent.CATEGORY_OPENABLE)
        }
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(i, PICK)
        } catch (_: Exception) {
            try {
                @Suppress("DEPRECATION")
                startActivityForResult(Intent(Intent.ACTION_GET_CONTENT).setType("image/*")
                    .addCategory(Intent.CATEGORY_OPENABLE), PICK)
            } catch (_: Exception) {}
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK) return
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) return // 고르지 않고 돌아옴 → 메뉴 그대로
        // 자르기 화면 먼저 (검은 화면) → 사진 읽히면 바로 보임
        findViewById<TextView>(R.id.menu_crop_hint).text = lc.getString(R.string.w_photo_hint)
        findViewById<TextView>(R.id.menu_crop_cancel).text = lc.getString(R.string.w_photo_cancel)
        findViewById<TextView>(R.id.menu_crop_done).apply {
            text = lc.getString(R.string.w_photo_done)
            backgroundTintList = ColorStateList.valueOf(primary())
        }
        findViewById<View>(R.id.menu_card).visibility = View.GONE
        findViewById<View>(R.id.menu_crop).visibility = View.VISIBLE
        Thread {
            val b = load(uri)
            runOnUiThread {
                if (isFinishing) return@runOnUiThread
                if (b == null) {
                    closeCrop()
                } else {
                    picked = b
                    findViewById<CropView>(R.id.menu_crop_view).apply {
                        aspect = this@WidgetMenuActivity.aspect
                        setBitmap(b)
                    }
                }
            }
        }.start()
    }

    /// 고른 사진 읽기 — 긴 쪽 1600 정도로 줄이고, 폰으로 찍을 때 돌아간 방향(EXIF)도 바로잡기
    private fun load(uri: Uri): Bitmap? = try {
        val cr = contentResolver
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        cr.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, o) }
        var s = 1
        while (maxOf(o.outWidth, o.outHeight) / (s * 2) >= 1600) s *= 2
        var b = cr.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = s })
        }
        if (b != null && android.os.Build.VERSION.SDK_INT >= 24) {
            val ori = cr.openInputStream(uri)?.use {
                android.media.ExifInterface(it).getAttributeInt(
                    android.media.ExifInterface.TAG_ORIENTATION, android.media.ExifInterface.ORIENTATION_NORMAL)
            } ?: android.media.ExifInterface.ORIENTATION_NORMAL
            val deg = when (ori) {
                android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
            if (deg != 0f) {
                val m = android.graphics.Matrix().apply { postRotate(deg) }
                val r = Bitmap.createBitmap(b, 0, 0, b.width, b.height, m, true)
                if (r != b) b.recycle()
                b = r
            }
        }
        if (b != null && maxOf(b.width, b.height) > 1600) {
            val k = 1600f / maxOf(b.width, b.height)
            val r = Bitmap.createScaledBitmap(b, (b.width * k).toInt(), (b.height * k).toInt(), true)
            if (r != b) b.recycle()
            b = r
        }
        b
    } catch (_: Exception) {
        null
    }

    private fun closeCrop() {
        findViewById<View>(R.id.menu_crop).visibility = View.GONE
        findViewById<View>(R.id.menu_card).visibility = View.VISIBLE
        picked = null
    }

    /// 완료: 사진 + 정한 곳 저장 → 세 위젯 다시 그리기 → 닫기
    private fun savePhoto() {
        val b = picked ?: return
        val (cx, cy, zoom) = findViewById<CropView>(R.id.menu_crop_view).result()
        findViewById<View>(R.id.menu_crop_done).isEnabled = false
        Thread {
            try {
                val tmp = java.io.File(filesDir, "widget_photo.tmp")
                tmp.outputStream().use { b.compress(Bitmap.CompressFormat.JPEG, 90, it) }
                tmp.renameTo(photoFile())
                getSharedPreferences("paran_widget", Context.MODE_PRIVATE).edit()
                    .putFloat("photo_cx", cx).putFloat("photo_cy", cy).putFloat("photo_zoom", zoom).apply()
            } catch (_: Exception) {}
            runOnUiThread {
                PlayerWidget.refreshAll(this)
                finish()
            }
        }.start()
    }

    /// 기본 사진으로 (직접 넣은 사진 지우기)
    private fun resetPhoto() {
        photoFile().delete()
        getSharedPreferences("paran_widget", Context.MODE_PRIVATE).edit()
            .remove("photo_cx").remove("photo_cy").remove("photo_zoom").apply()
        PlayerWidget.refreshAll(this)
        finish()
    }

    companion object {
        private const val PICK = 7
    }

    override fun onDestroy() {
        h.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
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

            <!-- 얇은 줄 -->
            <View
                android:layout_width="match_parent"
                android:layout_height="1dp"
                android:background="@color/paran_w_line" />

            <LinearLayout
                android:id="@+id/menu_shuffle"
                android:layout_width="match_parent"
                android:layout_height="52dp"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="2dp"
                android:paddingEnd="2dp">

                <ImageView
                    android:layout_width="20dp"
                    android:layout_height="20dp"
                    android:src="@drawable/paran_ic_shuffle"
                    android:tint="@color/paran_w_ink" />

                <TextView
                    android:id="@+id/menu_shuffle_label"
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="14dp"
                    android:layout_weight="1"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_ink"
                    android:textSize="14sp" />

                <TextView
                    android:id="@+id/menu_shuffle_value"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="10dp"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_sub"
                    android:textSize="12.5sp" />
            </LinearLayout>

            <!-- 얇은 줄 -->
            <View
                android:layout_width="match_parent"
                android:layout_height="1dp"
                android:background="@color/paran_w_line" />

            <LinearLayout
                android:id="@+id/menu_repeat"
                android:layout_width="match_parent"
                android:layout_height="52dp"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="2dp"
                android:paddingEnd="2dp">

                <ImageView
                android:id="@+id/menu_repeat_icon"
                    android:layout_width="20dp"
                    android:layout_height="20dp"
                    android:src="@drawable/paran_ic_repeat"
                    android:tint="@color/paran_w_ink" />

                <TextView
                    android:id="@+id/menu_repeat_label"
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="14dp"
                    android:layout_weight="1"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_ink"
                    android:textSize="14sp" />

                <TextView
                    android:id="@+id/menu_repeat_value"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="10dp"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_sub"
                    android:textSize="12.5sp" />
            </LinearLayout>

            <!-- 얇은 줄 -->
            <View
                android:layout_width="match_parent"
                android:layout_height="1dp"
                android:background="@color/paran_w_line" />

            <LinearLayout
                android:id="@+id/menu_sleep"
                android:layout_width="match_parent"
                android:layout_height="52dp"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="2dp"
                android:paddingEnd="2dp">

                <ImageView
                    android:layout_width="20dp"
                    android:layout_height="20dp"
                    android:src="@drawable/paran_ic_timer"
                    android:tint="@color/paran_w_ink" />

                <TextView
                    android:id="@+id/menu_sleep_label"
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="14dp"
                    android:layout_weight="1"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_ink"
                    android:textSize="14sp" />

                <TextView
                    android:id="@+id/menu_sleep_value"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="10dp"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_sub"
                    android:textSize="12.5sp" />
            </LinearLayout>

            <!-- 얇은 줄 -->
            <View
                android:layout_width="match_parent"
                android:layout_height="1dp"
                android:background="@color/paran_w_line" />

            <LinearLayout
                android:id="@+id/menu_photo"
                android:layout_width="match_parent"
                android:layout_height="52dp"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="2dp"
                android:paddingEnd="2dp">

                <ImageView
                    android:layout_width="20dp"
                    android:layout_height="20dp"
                    android:src="@drawable/paran_ic_photo"
                    android:tint="@color/paran_w_ink" />

                <TextView
                    android:id="@+id/menu_photo_label"
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="14dp"
                    android:layout_weight="1"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_ink"
                    android:textSize="14sp" />

                <TextView
                    android:id="@+id/menu_photo_value"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="10dp"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_sub"
                    android:textSize="15sp" />
            </LinearLayout>

            <!-- 얇은 줄 -->
            <View
                android:layout_width="match_parent"
                android:layout_height="1dp"
                android:background="@color/paran_w_line" />

            <LinearLayout
                android:id="@+id/menu_photo_reset"
                android:layout_width="match_parent"
                android:layout_height="52dp"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="2dp"
                android:paddingEnd="2dp">

                <ImageView
                    android:layout_width="20dp"
                    android:layout_height="20dp"
                    android:src="@drawable/paran_ic_reset"
                    android:tint="@color/paran_w_ink" />

                <TextView
                    android:id="@+id/menu_photo_reset_label"
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="14dp"
                    android:layout_weight="1"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_ink"
                    android:textSize="14sp" />

                <TextView
                    android:id="@+id/menu_photo_reset_value"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="10dp"
                    android:maxLines="1"
                    android:textColor="@color/paran_w_sub"
                    android:textSize="15sp" />
            </LinearLayout>
    </LinearLayout>

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

    <!-- ── 위젯 사진 자르기 (화면 가득) ── -->
    <FrameLayout
        android:id="@+id/menu_crop"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="#FF000000"
        android:clickable="true"
        android:visibility="gone">

        <kr.ssing.catsong.CropView
            android:id="@+id/menu_crop_view"
            android:layout_width="match_parent"
            android:layout_height="match_parent" />

        <TextView
            android:id="@+id/menu_crop_hint"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="top|center_horizontal"
            android:layout_marginStart="24dp"
            android:layout_marginTop="24dp"
            android:layout_marginEnd="24dp"
            android:gravity="center"
            android:textColor="#CCFFFFFF"
            android:textSize="13sp" />

        <LinearLayout
            android:id="@+id/menu_crop_bar"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_gravity="bottom"
            android:orientation="horizontal"
            android:paddingStart="20dp"
            android:paddingTop="12dp"
            android:paddingEnd="20dp"
            android:paddingBottom="20dp">

            <TextView
                android:id="@+id/menu_crop_cancel"
                android:layout_width="0dp"
                android:layout_height="48dp"
                android:layout_marginEnd="8dp"
                android:layout_weight="1"
                android:background="?android:attr/selectableItemBackground"
                android:gravity="center"
                android:maxLines="1"
                android:textColor="#FFFFFF"
                android:textSize="15sp" />

            <TextView
                android:id="@+id/menu_crop_done"
                android:layout_width="0dp"
                android:layout_height="48dp"
                android:layout_weight="1"
                android:background="@drawable/paran_btn_point"
                android:gravity="center"
                android:maxLines="1"
                android:textColor="#FFFFFF"
                android:textSize="15sp"
                android:textStyle="bold" />
        </LinearLayout>
    </FrameLayout>
</FrameLayout>
'''
CROP = '''package kr.ssing.catsong

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import kotlin.math.max
import kotlin.math.min

/// 위젯 사진 자르기 화면
/// - 가운데 틀(위젯 사진 칸 모양) 안에 보일 곳을 손가락으로 움직이고, 두 손가락으로 키워서 정함
/// - 틀 밖은 어둡게, 사진은 틀을 늘 꽉 채움 (빈 곳 안 생김)
/// - 결과: 틀 가운데가 사진의 어디인지(0~1) + 얼마나 키웠는지(1 = 꽉 맞춤)
class CropView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : View(context, attrs) {

    /// 틀 모양 (가로 ÷ 세로) — 누른 위젯의 사진 칸과 같게
    var aspect = 2f
        set(v) { field = v.coerceIn(0.4f, 4f); fit() }

    private val dp = resources.displayMetrics.density
    private var bmp: Bitmap? = null
    private val frame = RectF()
    private var scale = 1f      // 사진 → 화면 배율
    private var tx = 0f         // 사진 왼쪽 위가 화면 어디에 있는지
    private var ty = 0f
    private var minScale = 1f   // 틀을 딱 채우는 배율
    private val mx = Matrix()
    private val imgPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
    private val dimPaint = Paint().apply { color = 0x99000000.toInt() }
    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1.5f * dp
        color = 0xE6FFFFFF.toInt()
    }

    fun setBitmap(b: Bitmap) {
        bmp = b
        fit()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        fit()
    }

    /// 틀 자리 잡고, 사진을 틀에 꽉 맞춰 가운데로
    private fun fit() {
        val b = bmp ?: return
        if (width == 0 || height == 0) return
        var fw = width - 48 * dp
        var fh = fw / aspect
        if (fh > height * 0.62f) {
            fh = height * 0.62f
            fw = fh * aspect
        }
        frame.set((width - fw) / 2f, (height - fh) / 2f, (width + fw) / 2f, (height + fh) / 2f)
        minScale = max(frame.width() / b.width, frame.height() / b.height)
        scale = minScale
        tx = frame.centerX() - b.width * scale / 2f
        ty = frame.centerY() - b.height * scale / 2f
        invalidate()
    }

    /// 사진이 틀을 늘 꽉 채우게 (빈 곳이 안 생기게) 위치 맞추기
    private fun clamp() {
        val b = bmp ?: return
        scale = scale.coerceIn(minScale, minScale * 4f)
        val w = b.width * scale
        val h = b.height * scale
        tx = tx.coerceIn(frame.right - w, frame.left)
        ty = ty.coerceIn(frame.bottom - h, frame.top)
    }

    override fun onDraw(canvas: Canvas) {
        val b = bmp ?: return
        mx.reset()
        mx.postScale(scale, scale)
        mx.postTranslate(tx, ty)
        canvas.drawBitmap(b, mx, imgPaint)
        // 틀 밖 어둡게 + 틀 테두리 (위젯처럼 둥근 모서리)
        val r = 18 * dp
        val hole = Path().apply {
            fillType = Path.FillType.EVEN_ODD
            addRect(0f, 0f, width.toFloat(), height.toFloat(), Path.Direction.CW)
            addRoundRect(frame, r, r, Path.Direction.CW)
        }
        canvas.drawPath(hole, dimPaint)
        canvas.drawRoundRect(frame, r, r, linePaint)
    }

    private val scaler = ScaleGestureDetector(context, object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(d: ScaleGestureDetector): Boolean {
            val old = scale
            scale = (scale * d.scaleFactor).coerceIn(minScale, minScale * 4f)
            val f = scale / old
            // 두 손가락 가운데를 중심으로 키우기
            tx = d.focusX - (d.focusX - tx) * f
            ty = d.focusY - (d.focusY - ty) * f
            clamp()
            invalidate()
            return true
        }
    })

    private var lastX = 0f
    private var lastY = 0f
    private var pointer = -1

    override fun onTouchEvent(e: MotionEvent): Boolean {
        scaler.onTouchEvent(e)
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                pointer = e.getPointerId(0)
                lastX = e.x
                lastY = e.y
                parent?.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_POINTER_DOWN, MotionEvent.ACTION_POINTER_UP -> {
                // 손가락 수가 바뀌면 남은 손가락 기준으로 다시
                val up = if (e.actionMasked == MotionEvent.ACTION_POINTER_UP) e.actionIndex else -1
                val i = (0 until e.pointerCount).firstOrNull { it != up } ?: 0
                pointer = e.getPointerId(i)
                lastX = e.getX(i)
                lastY = e.getY(i)
            }
            MotionEvent.ACTION_MOVE -> {
                val i = e.findPointerIndex(pointer)
                if (i >= 0 && !scaler.isInProgress) {
                    tx += e.getX(i) - lastX
                    ty += e.getY(i) - lastY
                    clamp()
                    invalidate()
                }
                if (i >= 0) {
                    lastX = e.getX(i)
                    lastY = e.getY(i)
                }
            }
        }
        return true
    }

    /// 결과: (가운데 x 0~1, 가운데 y 0~1, 키운 정도 1~4)
    fun result(): Triple<Float, Float, Float> {
        val b = bmp ?: return Triple(0.5f, 0.5f, 1f)
        val cx = ((frame.centerX() - tx) / scale) / b.width
        val cy = ((frame.centerY() - ty) / scale) / b.height
        return Triple(cx.coerceIn(0f, 1f), cy.coerceIn(0f, 1f), max(1f, min(4f, scale / minScale)))
    }
}
'''
RESET_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 기본 사진으로 (되돌리기 화살표, 끝이 둥근 선) -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path android:fillColor="#00000000" android:strokeColor="#FFFFFFFF" android:strokeWidth="1.9"
        android:strokeLineCap="round" android:strokeLineJoin="round"
        android:pathData="M5,12a7,7 0,1 0,2.05 -4.95" />
    <path android:fillColor="#00000000" android:strokeColor="#FFFFFFFF" android:strokeWidth="1.9"
        android:strokeLineCap="round" android:strokeLineJoin="round"
        android:pathData="M4.5,4.5v3.5h3.5" />
</vector>
'''

whole(ACT, 'WheelView', 'CropView', ACT_KT, '⋮ 창 코드 통째로 새로 (사진 바꾸기 · 자르기)')
whole(MENU, 'menu_dial', 'menu_crop', MENU_XML, '⋮ 창 화면 통째로 새로 (사진 바꾸기 줄 · 자르기 화면)')

# ───── PlayerWidget.kt ─────
cut(W, '''            val path = "flutter_assets/assets/widget_photo${n + 1}.jpg"
''', '''                val out = Bitmap.createBitmap(w, bh, Bitmap.Config.ARGB_8888)
''', '''            val path = "flutter_assets/assets/widget_photo${n + 1}.jpg"
            // 직접 넣은 사진(⋮ → 위젯 사진 바꾸기)이 있으면 그걸로
            val custom = java.io.File(context.filesDir, "widget_photo.jpg")
            val useCustom = custom.exists()
            fun openSrc(): java.io.InputStream = if (useCustom) custom.inputStream() else context.assets.open(path)
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                openSrc().use { BitmapFactory.decodeStream(it, null, bounds) }
                var sample = 1
                while (bounds.outWidth / (sample * 2) >= 560) sample *= 2
                val src = openSrc().use {
                    BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
                } ?: return null
                // 자를 곳 (sl · top = 왼쪽 위, w · bh = 크기)
                val left: Int
                val top: Int
                val w: Int
                val bh: Int
                if (useCustom) {
                    // 자르기 화면에서 정한 곳을 가운데로, 이 위젯 사진 칸 모양에 맞게
                    val wp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    val cx = wp.getFloat("photo_cx", 0.5f)
                    val cy = wp.getFloat("photo_cy", 0.5f)
                    val zoom = wp.getFloat("photo_zoom", 1f).coerceIn(1f, 4f)
                    val aspect = vw.toFloat() / vh
                    var cw = src.width.toFloat()
                    var ch = cw / aspect
                    if (ch > src.height) {
                        ch = src.height.toFloat()
                        cw = ch * aspect
                    }
                    w = (cw / zoom).toInt().coerceIn(1, src.width)
                    bh = (ch / zoom).toInt().coerceIn(1, src.height)
                    left = (cx * src.width - w / 2f).toInt().coerceIn(0, src.width - w)
                    top = (cy * src.height - bh / 2f).toInt().coerceIn(0, src.height - bh)
                } else {
                    left = 0
                    w = src.width
                    bh = (w * vh.toFloat() / vw).toInt().coerceIn(1, src.height)
                    top = ((src.height - bh) * 0.35f).toInt()
                }
                val out = Bitmap.createBitmap(w, bh, Bitmap.Config.ARGB_8888)
''', '사진: 직접 넣은 사진이면 정한 곳으로 자르기')
rep(W, '''                c.drawBitmap(src, Rect(0, top, w, top + bh), Rect(0, 0, w, bh), Paint(Paint.FILTER_BITMAP_FLAG))''',
    '''                c.drawBitmap(src, Rect(left, top, left + w, top + bh), Rect(0, 0, w, bh), Paint(Paint.FILTER_BITMAP_FLAG))''',
    '사진 자를 곳 (왼쪽도 정한 곳으로)')
rep(W, '''            photo(context, appWidgetManager, appWidgetId, bottomDp, big, tall)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }''',
    '''            val photoBmp = photo(context, appWidgetManager, appWidgetId, bottomDp, big, tall)
            photoBmp?.let { views.setImageViewBitmap(R.id.widget_photo, it) }
            // 이 위젯 사진 칸 모양 (가로 ÷ 세로) → ⋮ 창 자르기 틀을 같은 모양으로
            val photoAspect = photoBmp?.let { it.width.toFloat() / it.height } ?: 2f''',
    '사진 칸 모양 기억')
rep(W, '''            val menu = Intent(context, WidgetMenuActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            views.setOnClickPendingIntent(R.id.widget_more, PendingIntent.getActivity(
                context, 6, menu, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))''',
    '''            val menu = Intent(context, WidgetMenuActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra("aspect", photoAspect)
            }
            // 위젯마다 따로 (사진 칸 모양이 달라서 — 같은 번호면 마지막 위젯 값으로 덮임)
            views.setOnClickPendingIntent(R.id.widget_more, PendingIntent.getActivity(
                context, 1000 + appWidgetId, menu, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))''',
    '⋮ 에 사진 칸 모양 같이 보내기')

# ───── AndroidManifest.xml ─────
rep(MAN, '''            android:name=".WidgetMenuActivity"
            android:exported="false"
            android:excludeFromRecents="true"
            android:noHistory="true"
''', '''            android:name=".WidgetMenuActivity"
            android:exported="false"
            android:excludeFromRecents="true"
''', '⋮ 창: 사진 고르고 돌아올 수 있게 (noHistory 빼기)')

# ───── strings.xml (23개 언어) ─────
# (위젯 사진 바꾸기, 기본 사진으로, 자르기 안내, 취소, 완료) — 취소 · 완료는 앱 번역(ARB)과 같은 말
PH = {
    'en': ('Change widget photo', 'Use default photo', 'Drag and pinch to choose what shows', 'Cancel', 'Done'),
    'ko': ('위젯 사진 바꾸기', '기본 사진으로', '움직이고 두 손가락으로 키워서 보일 곳을 정해요', '취소', '완료'),
    'ja': ('ウィジェットの写真を変更', '元の写真に戻す', '動かしたり2本指で拡大したりして表示範囲を決めます', 'キャンセル', '完了'),
    'zh': ('更换小组件照片', '恢复默认照片', '拖动并双指缩放，选择显示区域', '取消', '完成'),
    'zh_Hant': ('更換小工具相片', '恢復預設相片', '拖曳並雙指縮放，選擇顯示範圍', '取消', '完成'),
    'de': ('Widget-Foto ändern', 'Standardfoto verwenden', 'Verschieben und zoomen, um den Ausschnitt zu wählen', 'Abbrechen', 'Fertig'),
    'es': ('Cambiar foto del widget', 'Usar foto predeterminada', 'Arrastra y pellizca para elegir la zona visible', 'Cancelar', 'Listo'),
    'fr': ('Changer la photo du widget', 'Photo par défaut', 'Faites glisser et pincez pour choisir le cadrage', 'Annuler', 'Terminé'),
    'it': ('Cambia foto del widget', 'Usa foto predefinita', "Trascina e pizzica per scegliere l'inquadratura", 'Annulla', 'Fatto'),
    'pt': ('Trocar foto do widget', 'Usar foto padrão', 'Arraste e use dois dedos para escolher o enquadramento', 'Cancelar', 'Concluído'),
    'ru': ('Сменить фото виджета', 'Фото по умолчанию', 'Двигайте и масштабируйте, чтобы выбрать область', 'Отмена', 'Готово'),
    'uk': ('Змінити фото віджета', 'Фото за замовчуванням', 'Рухайте й масштабуйте, щоб вибрати область', 'Скасувати', 'Готово'),
    'pl': ('Zmień zdjęcie widżetu', 'Domyślne zdjęcie', 'Przesuń i powiększ, aby wybrać kadr', 'Anuluj', 'Gotowe'),
    'cs': ('Změnit fotku widgetu', 'Výchozí fotka', 'Posuňte a přibližte pro výběr výřezu', 'Zrušit', 'Hotovo'),
    'hu': ('Widgetfotó módosítása', 'Alapértelmezett fotó', 'Mozgasd és nagyítsd a kivágás kiválasztásához', 'Mégse', 'Kész'),
    'ro': ('Schimbă fotografia widgetului', 'Fotografie implicită', 'Trage și mărește pentru a alege încadrarea', 'Anulează', 'Gata'),
    'tr': ('Widget fotoğrafını değiştir', 'Varsayılan fotoğraf', 'Görünecek alanı seçmek için sürükleyip yakınlaştırın', 'İptal', 'Bitti'),
    'ar': ('تغيير صورة الأداة', 'الصورة الافتراضية', 'اسحب وكبّر لاختيار الجزء الظاهر', 'إلغاء', 'تم'),
    'hi': ('विजेट फ़ोटो बदलें', 'डिफ़ॉल्ट फ़ोटो', 'दिखने वाला हिस्सा चुनने के लिए खिसकाएँ और ज़ूम करें', 'रद्द करें', 'हो गया'),
    'ur': ('ویجیٹ تصویر بدلیں', 'ڈیفالٹ تصویر', 'دکھنے والا حصہ چننے کے لیے سرکائیں اور زوم کریں', 'منسوخ', 'ہو گیا'),
    'id': ('Ganti foto widget', 'Pakai foto bawaan', 'Geser dan cubit untuk memilih bagian yang tampil', 'Batal', 'Selesai'),
    'vi': ('Đổi ảnh tiện ích', 'Dùng ảnh mặc định', 'Kéo và thu phóng để chọn phần hiển thị', 'Hủy', 'Xong'),
    'th': ('เปลี่ยนรูปวิดเจ็ต', 'ใช้รูปเริ่มต้น', 'ลากและซูมเพื่อเลือกส่วนที่แสดง', 'ยกเลิก', 'เสร็จสิ้น'),
}
FOLDER = {'values': 'en', 'values-en': 'en', 'values-ko': 'ko', 'values-ja': 'ja', 'values-zh': 'zh',
          'values-zh-rTW': 'zh_Hant', 'values-zh-rHK': 'zh_Hant', 'values-zh-rMO': 'zh_Hant',
          'values-de': 'de', 'values-es': 'es', 'values-fr': 'fr', 'values-it': 'it', 'values-pt': 'pt',
          'values-ru': 'ru', 'values-uk': 'uk', 'values-pl': 'pl', 'values-cs': 'cs', 'values-hu': 'hu',
          'values-ro': 'ro', 'values-tr': 'tr', 'values-ar': 'ar', 'values-hi': 'hi', 'values-ur': 'ur',
          'values-in': 'id', 'values-vi': 'vi', 'values-th': 'th'}
KEYS = ('w_photo_change', 'w_photo_reset', 'w_photo_hint', 'w_photo_cancel', 'w_photo_done')


def esc(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('"', '\\"')


for folder, code in FOLDER.items():
    lines = '    <!-- 위젯 ⋮ 사진 바꾸기 -->\n' + ''.join(
        f'    <string name="{k}">{esc(v)}</string>\n' for k, v in zip(KEYS, PH[code]))
    rep(os.path.join(RES, folder, 'strings.xml'), '</resources>', lines + '</resources>', '사진 바꾸기 글자')


def gaps(t):
    return [t.count(a) - t.count(b) for a, b in ('{}', '()', '[]')]

if ok:
    if gaps(files[W][0]) != gaps(ORIG[W]):
        fail('PlayerWidget.kt — 괄호가 안 맞아요')
    for name, body in (('WidgetMenuActivity.kt', ACT_KT), ('CropView.kt', CROP)):
        if gaps(body) != [0, 0, 0]:
            fail(name + ' — 괄호가 안 맞아요')

if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

files[CROP_P] = [CROP, True]
files[RESET] = [RESET_XML, True]
print('✔ 새 파일 CropView.kt — 사진 자르기 화면')
print('✔ 새 파일 paran_ic_reset.xml — 기본 사진으로 아이콘')
for p, (body, crlf) in files.items():
    if crlf:
        body = body.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(body.encode('utf-8'))
print('\n다 됐어요! 위젯 ⋮ → 위젯 사진 바꾸기를 눌러 보세요.')
