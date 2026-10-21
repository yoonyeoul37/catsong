package kr.ssing.catsong

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
