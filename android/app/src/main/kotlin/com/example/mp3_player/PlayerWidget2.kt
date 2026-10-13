package kr.ssing.catsong

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/// 홈 위젯 4×3: 4×2 위젯 + 아래에 최근에 들은 것 3개
/// 그리기·버튼은 모두 PlayerWidget이 같이 함 (모양만 큰 것)
class PlayerWidget2 : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) PlayerWidget.updateAppWidget(context, appWidgetManager, id)
    }

    // 바탕화면에서 위젯 크기를 바꾸면 사진도 새 크기에 맞게
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager,
                                           appWidgetId: Int, newOptions: android.os.Bundle) {
        PlayerWidget.updateAppWidget(context, appWidgetManager, appWidgetId)
    }
}
