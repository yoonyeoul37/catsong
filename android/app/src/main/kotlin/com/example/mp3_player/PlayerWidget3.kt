package kr.ssing.catsong

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
