package kr.ssing.catsong

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
