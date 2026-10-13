# -*- coding: utf-8 -*-
# 홈 위젯 모양 다듬기: 사진을 위젯 위쪽에 꽉 붙이고, 위젯 바깥 모서리와 똑같이 둥글게
# (사진 모서리와 바깥 모서리가 따로 놀아서 겹쳐 보이던 것)
#  · 안드로이드 12 이상: 폰이 정한 위젯 모서리 크기를 그대로 사용 + 사진도 같이 잘림
#  · 그 아래 버전: 사진 모서리를 바깥과 같은 크기로 직접 둥글게
#  · 위젯 크기를 바꾸면 사진도 그 크기에 딱 맞게 다시 만듦
# apply_widget_b.py → apply_widget_fix.py (→ fix2) 다음에 실행
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if '_backup_widget' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
kt = find('PlayerWidget.kt', 'android')
if not kt or 'WIDGET_GO_resume' not in open(kt, encoding='utf-8').read():
    print('❌ apply_widget_fix.py 를 먼저 실행해 주세요'); sys.exit(1)
if 'paran_w_radius' in open(kt, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)

RES = os.path.join('android', 'app', 'src', 'main', 'res')
writes = {}
ok = True

def edit(path, pairs):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

def new_file(path, text, label):
    writes[path] = (text, True)
    print('✔ %s' % label)

# ── 1) 위젯 코드: 사진을 위젯 크기에 딱 맞게 + 위쪽 두 모서리만 바깥과 같게 ──
edit(kt, [
    ('위젯 크기 바꾸면 다시 그리기',
     "    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {\n"
     "        for (id in appWidgetIds) updateAppWidget(context, appWidgetManager, id)\n    }\n",
     "    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {\n"
     "        for (id in appWidgetIds) updateAppWidget(context, appWidgetManager, id)\n    }\n\n"
     "    // 바탕화면에서 위젯 크기를 바꾸면 사진도 새 크기에 맞게\n"
     "    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager,\n"
     "                                           appWidgetId: Int, newOptions: android.os.Bundle) {\n"
     "        updateAppWidget(context, appWidgetManager, appWidgetId)\n    }\n"),
    ('사진 만들 때 위젯 크기 넘기기',
     "            photo(context)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }\n",
     "            photo(context, appWidgetManager, appWidgetId)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }\n"),
    ('사진: 위젯 크기 받기',
     "        private fun photo(context: Context): Bitmap? {\n",
     "        private fun photo(context: Context, mgr: AppWidgetManager, id: Int): Bitmap? {\n"
     "            // 사진 칸 크기(dp): 위젯 크기 - 아래 바로가기 줄(46 + 위 8 + 아래 10)\n"
     "            val opt = mgr.getAppWidgetOptions(id)\n"
     "            val vw = opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250\n"
     "            val vh = ((opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 180) - 64)\n"
     "                .coerceAtLeast(56)\n"
     "            // 바깥 모서리 크기(dp) = res/values 의 paran_w_radius (안드로이드 12 이상은 폰이 정한 크기)\n"
     "            val dens = context.resources.displayMetrics.density\n"
     "            val radiusDp = context.resources.getDimension(R.dimen.paran_w_radius) / dens\n"),
    ('사진: 칸 모양 그대로 자르기',
     "                val bh = (w / 2.2f).toInt().coerceAtMost(src.height)\n",
     "                val bh = (w * vh.toFloat() / vw).toInt().coerceIn(1, src.height)\n"),
    ('사진: 위쪽 두 모서리만 바깥과 같은 크기로',
     "                val r = w * 0.035f\n",
     "                val r = radiusDp * w / vw\n"),
    ('사진: 아래쪽은 각지게 (바로가기 줄과 맞닿게)',
     "                    addRoundRect(RectF(0f, 0f, w.toFloat(), bh.toFloat()), r, r, Path.Direction.CW)\n",
     "                    addRoundRect(RectF(0f, 0f, w.toFloat(), bh.toFloat()),\n"
     "                        floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f), Path.Direction.CW)\n"),
])

# ── 2) 위젯 모양: 사진을 위·양옆에 꽉 붙이기 ──
lay = find('widget_player.xml', RES)
src, _ = load(lay)
s1 = src.index('<!-- 위: 시간대 라디오 사진')
s2 = src.index('<!-- 아래: 바로가기 4개 -->')
top_part = src[s1:s2]
bottom = src[s2:]
top_part = top_part.replace('android:scaleType="centerCrop"', 'android:scaleType="fitXY"')
top_part = top_part.replace('android:paddingStart="12dp"\n            android:paddingEnd="6dp"\n            android:paddingBottom="8dp"',
                            'android:paddingStart="14dp"\n            android:paddingEnd="8dp"\n            android:paddingBottom="8dp"')
top_part = top_part.replace('android:layout_marginStart="12dp"\n            android:layout_marginTop="8dp"',
                            'android:layout_marginStart="14dp"\n            android:layout_marginTop="10dp"')
bottom = bottom.replace('android:layout_height="46dp"\n        android:layout_marginTop="8dp"\n        android:orientation="horizontal">',
                        'android:layout_height="46dp"\n        android:layout_marginStart="7dp"\n        android:layout_marginTop="8dp"\n'
                        '        android:layout_marginEnd="7dp"\n        android:layout_marginBottom="10dp"\n        android:orientation="horizontal">')
if 'android:layout_marginBottom="10dp"' not in bottom or 'fitXY' not in top_part:
    print('❌ 위젯 모양 파일이 예상과 달라요'); ok = False
new_file(lay, '''<?xml version="1.0" encoding="utf-8"?>
<!-- 홈 위젯 B안: 위 사진(위·양옆 꽉) + 지금 듣는 것 / 아래 바로가기 4개 -->
<!-- @android:id/background + clipToOutline: 안드로이드 12 이상은 폰 모서리 그대로 깔끔하게 잘림 -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@android:id/background"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/paran_widget_bg"
    android:clipToOutline="true"
    android:orientation="vertical">

    ''' + top_part + bottom, '위젯 모양: 사진을 위쪽에 꽉 붙이기')

# ── 3) 모서리 크기 하나로 (바깥 = 사진) ──
bg = find('paran_widget_bg.xml', RES)
edit(bg, [('바깥 모서리 = paran_w_radius', 'android:radius="20dp"', 'android:radius="@dimen/paran_w_radius"')])
new_file(os.path.join(RES, 'values', 'paran_widget_dimens.xml'), '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- 홈 위젯 바깥 모서리 (사진 위쪽 모서리도 같은 크기) -->
    <dimen name="paran_w_radius">18dp</dimen>
</resources>
''', '모서리 크기 (안드로이드 11 이하: 18dp)')
new_file(os.path.join(RES, 'values-v31', 'paran_widget_dimens.xml'), '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- 안드로이드 12 이상: 폰이 정한 위젯 모서리 그대로 -->
    <dimen name="paran_w_radius">@android:dimen/system_app_widget_background_radius</dimen>
</resources>
''', '모서리 크기 (안드로이드 12 이상: 폰 기본)')

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = '_backup_widget4'
for p, (text, crlf) in writes.items():
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if os.path.exists(p):
        b = os.path.join(BK, p)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if crlf else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (원래 것은 _backup_widget4 폴더에 백업)')
