package kr.ssing.catsong

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/// 안드로이드 오토(차 화면) 칸 그림
/// 차 화면은 인터넷 주소 그림을 직접 못 읽어서, 앱이 그림 파일로 만들어 건네줌
///  - tile  : 방송사 색 칸 + 큰 글자(KBS) + 작은 글자(Classic FM) — 앱 방송사별 칸과 같은 느낌
///  - web   : 인터넷 그림(해외 방송 로고 · 팟캐스트 그림)을 받아서 (못 받으면 색 칸)
///  - asset : 앱 안의 사진 (자연소리 등)
/// 한 번 만든 그림은 cache/car_art 에 저장해서 다음엔 바로
class ArtProvider : ContentProvider() {

    // 앱이 화면 없이 켜졌을 때(차 · 위젯) 앱 ↔ 폰 신호 통로 연결 (소리 주도권 · 위젯 갱신)
    // 앱 화면이 열리면 앱이 자기 통로로 다시 바꿔 끼움
    override fun onCreate(): Boolean {
        context?.let { PlayerWidget.attachHeadless(it) }
        return true
    }
    override fun getType(uri: Uri) = "image/png"
    override fun query(u: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun insert(u: Uri, v: ContentValues?): Uri? = null
    override fun delete(u: Uri, s: String?, a: Array<out String>?) = 0
    override fun update(u: Uri, v: ContentValues?, s: String?, a: Array<out String>?) = 0

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        val ctx = context ?: return null
        if (mode != "r") return null // 읽기만
        val dir = File(ctx.cacheDir, "car_art").apply { mkdirs() }
        val key = Integer.toHexString(uri.toString().hashCode()) + "_" + uri.toString().length
        val f = File(dir, "$key.png")
        if (!f.exists() || f.length() == 0L) {
            val bmp = try {
                when (uri.path?.trim('/')) {
                    "tile" -> tile(uri.getQueryParameter("t") ?: "", uri.getQueryParameter("s") ?: "", color(uri))
                    "web" -> web(uri.getQueryParameter("u") ?: "", color(uri))
                        ?: tile(initials(uri.getQueryParameter("t") ?: ""), "", color(uri))
                    "asset" -> asset(uri.getQueryParameter("p") ?: "")
                    else -> null
                }
            } catch (_: Exception) {
                null
            } ?: return null
            val tmp = File(dir, "$key.tmp")
            tmp.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
            tmp.renameTo(f)
            bmp.recycle()
            trim(dir)
        }
        return ParcelFileDescriptor.open(f, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    private fun color(uri: Uri): Int = try {
        (uri.getQueryParameter("c") ?: "ff3a342a").toLong(16).toInt() or 0xFF000000.toInt()
    } catch (_: Exception) {
        0xFF3A342A.toInt()
    }

    private fun initials(name: String): String {
        val w = name.trim().split(Regex("\\s+")).firstOrNull() ?: return ""
        return if (w.length <= 4) w else w.substring(0, 1).uppercase()
    }

    /// 색 칸: 위 왼쪽이 조금 밝은 그라데이션 + 오른쪽 위 연한 동그라미 + 아래 왼쪽 글자
    private fun tile(big: String, small: String, c: Int): Bitmap {
        val n = 256
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val light = mix(c, 0xFFFFFFFF.toInt(), 0.10f)
        cv.drawRect(0f, 0f, n.toFloat(), n.toFloat(), Paint().apply {
            shader = LinearGradient(0f, 0f, n.toFloat(), n.toFloat(), light, c, Shader.TileMode.CLAMP)
        })
        cv.drawCircle(n - 18f, 18f, 66f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x14FFFFFF })
        val bold = Typeface.create("sans-serif", Typeface.BOLD)
        if (small.isEmpty()) {
            // 글자 하나뿐 (해외 방송 첫 글자 등): 가운데 크게
            val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFFFFFFF.toInt(); typeface = bold; textAlign = Paint.Align.CENTER
                textSize = if (big.length <= 1) 120f else 72f
            }
            fit(p, big, n - 40f)
            val fm = p.fontMetrics
            cv.drawText(big, n / 2f, n / 2f - (fm.ascent + fm.descent) / 2f, p)
        } else {
            val pb = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xFFFFFFFF.toInt(); typeface = bold; textSize = 64f }
            val ps = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xD9FFFFFF.toInt(); textSize = 30f }
            fit(pb, big, n - 44f)
            fit(ps, small, n - 44f)
            cv.drawText(big, 22f, n - 62f, pb)
            cv.drawText(small, 22f, n - 22f, ps)
        }
        return b
    }

    /// 글자가 칸보다 길면 줄이기
    private fun fit(p: Paint, s: String, max: Float) {
        while (p.textSize > 14f && p.measureText(s) > max) p.textSize -= 2f
    }

    private fun mix(a: Int, b: Int, t: Float): Int {
        fun ch(sh: Int) = (((a shr sh) and 0xFF) * (1 - t) + ((b shr sh) and 0xFF) * t).toInt()
        return (0xFF shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
    }

    /// 인터넷 그림 받기 (4초 안에, 2MB까지) — 작은 로고는 색 칸 가운데에 얹기
    private fun web(url: String, c: Int): Bitmap? {
        if (!url.startsWith("http://") && !url.startsWith("https://")) return null
        val con = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 4000; readTimeout = 4000; instanceFollowRedirects = true
            setRequestProperty("User-Agent", "Paransori/1.0 (Android)")
        }
        val bytes = try {
            if (con.responseCode !in 200..299) return null
            con.inputStream.use { ins ->
                val out = java.io.ByteArrayOutputStream()
                val buf = ByteArray(16 * 1024)
                while (true) {
                    val r = ins.read(buf)
                    if (r < 0) break
                    out.write(buf, 0, r)
                    if (out.size() > 2 * 1024 * 1024) return null
                }
                out.toByteArray()
            }
        } finally {
            con.disconnect()
        }
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, o)
        if (o.outWidth <= 0) return null
        var s = 1
        while (maxOf(o.outWidth, o.outHeight) / (s * 2) >= 512) s *= 2
        val src = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
            BitmapFactory.Options().apply { inSampleSize = s }) ?: return null
        return if (maxOf(src.width, src.height) < 160) onTile(src, c) else square(src, 512)
    }

    /// 작은 로고: 흰 칸 가운데에 (로고가 잘 보이게)
    private fun onTile(src: Bitmap, c: Int): Bitmap {
        val n = 256
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        cv.drawColor(0xFFF4EFE5.toInt())
        val side = (n * 0.62f)
        val k = side / maxOf(src.width, src.height)
        val w = src.width * k
        val h = src.height * k
        cv.drawBitmap(src, null, RectF((n - w) / 2f, (n - h) / 2f, (n + w) / 2f, (n + h) / 2f),
            Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG))
        src.recycle()
        return b
    }

    /// 가운데를 네모로 잘라 크기 맞추기
    private fun square(src: Bitmap, max: Int): Bitmap {
        val side = minOf(src.width, src.height)
        val l = (src.width - side) / 2
        val t = (src.height - side) / 2
        val n = minOf(max, side)
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        Canvas(b).drawBitmap(src, Rect(l, t, l + side, t + side), Rect(0, 0, n, n), Paint(Paint.FILTER_BITMAP_FLAG))
        src.recycle()
        return b
    }

    /// 앱 안 사진 (assets/…) — 네모로 잘라 512까지
    private fun asset(path: String): Bitmap? {
        if (!path.startsWith("assets/") || path.contains("..")) return null
        val ctx = context ?: return null
        val full = "flutter_assets/$path"
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        ctx.assets.open(full).use { BitmapFactory.decodeStream(it, null, o) }
        var s = 1
        while (minOf(o.outWidth, o.outHeight) / (s * 2) >= 512) s *= 2
        val src = ctx.assets.open(full).use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = s })
        } ?: return null
        return square(src, 512)
    }

    /// 저장 그림이 너무 많으면 오래된 것부터 지우기 (300개까지)
    private fun trim(dir: File) {
        val fs = dir.listFiles() ?: return
        if (fs.size <= 300) return
        fs.sortedBy { it.lastModified() }.take(fs.size - 300).forEach { it.delete() }
    }
}
