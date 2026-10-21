package kr.ssing.catsong

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
