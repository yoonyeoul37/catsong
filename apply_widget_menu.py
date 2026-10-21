# -*- coding: utf-8 -*-
# 위젯 ⋮ 메뉴 (②단계) — 세 위젯(4×2 · 4×3 · 세로 2×3) 통일
#  - 4×2 · 4×3: 사진 위 랜덤·반복 동그라미 빼고 ⋮ 하나
#  - ⋮ 누르면 바탕화면 위에 작은 창: 랜덤 듣기 · 반복 (수면 타이머 · 사진 바꾸기는 다음 단계에서)
#  - 새 파일: WidgetMenuActivity.kt · widget_menu.xml · paran_menu_bg.xml
#  - 고치는 파일: PlayerWidget.kt · widget_player.xml · widget_player2.xml · widget_player3.xml
#                AndroidManifest.xml · colors.xml(라이트·다크) · strings.xml 26개(창 글자 23개 언어)
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행
# 하나라도 못 찾으면 ❌ 띄우고 아무것도 저장 안 함
import os
import sys

MAIN = os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(MAIN, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(MAIN, 'res')

ok = True
files = {}  # 경로 → [글, CRLF]


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


def cut(path, start, end, new, label):
    """start 부터 그 뒤 처음 나오는 end 까지(포함)를 new 로"""
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


W = os.path.join(KT, 'PlayerWidget.kt')
L1 = os.path.join(RES, 'layout', 'widget_player.xml')
L2 = os.path.join(RES, 'layout', 'widget_player2.xml')
L3 = os.path.join(RES, 'layout', 'widget_player3.xml')
MAN = os.path.join(MAIN, 'AndroidManifest.xml')
COL = os.path.join(RES, 'values', 'colors.xml')
COLN = os.path.join(RES, 'values-night', 'colors.xml')
ACT = os.path.join(KT, 'WidgetMenuActivity.kt')
MENU = os.path.join(RES, 'layout', 'widget_menu.xml')
BG = os.path.join(RES, 'drawable', 'paran_menu_bg.xml')

# ── 이미 적용됐는지 ──
w0 = load(W)
m0 = load(MAN)
if w0 is None or m0 is None:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)
if 'WidgetMenuActivity' in w0 and '.WidgetMenuActivity' in m0 and os.path.exists(ACT):
    print('이미 적용돼 있어요')
    sys.exit(0)
if not os.path.exists(L3):
    fail('widget_player3.xml 이 없어요 — apply_widget_tall.py 먼저 해야 해요')

# ───────── 새 파일 ─────────
ACT_KT = '''package kr.ssing.catsong

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageView
import android.widget.TextView

/// 위젯 ⋮ 를 누르면 바탕화면 위에 뜨는 작은 창 (앱 화면은 안 열림)
/// 랜덤 듣기 · 반복 → 누르면 바로 바뀜 / 바깥을 누르면 닫힘
/// 실제로 바꾸는 건 위젯 버튼과 같은 길(PlayerWidget)로 보냄
class WidgetMenuActivity : Activity() {

    private val h = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.widget_menu)
        findViewById<View>(R.id.menu_root).setOnClickListener { finish() }
        findViewById<View>(R.id.menu_card).setOnClickListener { } // 창 안을 누르면 안 닫힘
        findViewById<View>(R.id.menu_shuffle).setOnClickListener { send(PlayerWidget.ACTION_SHUFFLE) }
        findViewById<View>(R.id.menu_repeat).setOnClickListener { send(PlayerWidget.ACTION_REPEAT) }
        show()
    }

    /// 위젯 버튼과 같은 길로 보내고, 잠깐 뒤 바뀐 값으로 다시 보여 주기
    private fun send(action: String) {
        sendBroadcast(Intent(this, PlayerWidget::class.java).setAction(action))
        h.postDelayed({ if (!isFinishing) show() }, 250)
    }

    private fun show() {
        val lc = PlayerWidget.localized(this) // 앱에서 고른 언어로
        val p = getSharedPreferences("paran_widget", Context.MODE_PRIVATE)
        val fp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val music = try { fp.getBoolean("flutter.w_music", false) } catch (_: Exception) { false }
        val loop = try { fp.getLong("flutter.w_loop", 0L) } catch (_: Exception) { 0L }
        val shuf = try { fp.getBoolean("flutter.w_shuffle", false) } catch (_: Exception) { false }
        @Suppress("DEPRECATION") val point = resources.getColor(R.color.paran_w_point)
        @Suppress("DEPRECATION") val sub = resources.getColor(R.color.paran_w_sub)

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
        // 보여 줄 줄이 하나도 없으면 닫기 (예: 음악을 멈추고 라디오로 바뀜)
        if (!music) finish()
    }

    override fun onDestroy() {
        h.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
'''


def row(rid, icon_id, icon, label_id, value_id):
    icon_attr = f'\n                android:id="@+id/{icon_id}"' if icon_id else ''
    return f'''        <!-- 얇은 줄 -->
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
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/menu_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#59000000">

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
    + row('menu_repeat', 'menu_repeat_icon', 'paran_ic_repeat', 'menu_repeat_label', 'menu_repeat_value') + '''    </LinearLayout>
</FrameLayout>
'''

BG_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- 위젯 ⋮ 메뉴 창 바탕 (위젯과 같은 크림색 · 다크는 먹색) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/paran_w_bg" />
    <corners android:radius="@dimen/paran_w_radius" />
</shape>
'''

NEW = [(ACT, ACT_KT, '⋮ 메뉴 창 코드'), (MENU, MENU_XML, '⋮ 메뉴 창 화면'), (BG, BG_XML, '⋮ 메뉴 창 바탕')]
for p, _, _ in NEW:
    if os.path.exists(p):
        fail(os.path.basename(p) + ' 파일이 벌써 있어요 — 덮어쓰지 않으려고 멈춰요')

# ───────── 위젯 화면 3개: ⋮ ─────────
MORE_VIEW = '''        <!-- ⋮ 메뉴 (누르면 바탕화면 위에 작은 창) -->
        <ImageView
            android:id="@+id/widget_more"
            android:layout_width="28dp"
            android:layout_height="28dp"
            android:layout_gravity="top|end"
            android:layout_marginTop="6dp"
            android:layout_marginEnd="8dp"
            android:background="@drawable/paran_widget_badge"
            android:padding="6dp"
            android:src="@drawable/paran_ic_more"
            android:tint="#FFFFFF"
            android:visibility="gone" />'''
for L in (L1, L2):
    cut(L, '        <!-- 섞기 · 반복 (음악일 때만 보임) -->', '\n        </LinearLayout>', MORE_VIEW,
        '사진 위 랜덤·반복 동그라미 → ⋮ 하나')
rep(L3, '        <!-- ⋮ 메뉴 (다음 단계에서 켬) -->', '        <!-- ⋮ 메뉴 (누르면 바탕화면 위에 작은 창) -->',
    '⋮ 설명 글 바꾸기')

# ───────── PlayerWidget.kt ─────────
cut(W, '            // 섞기 · 반복 (음악일 때만, 꺼져 있으면 흐리게)\n',
    '''            mode(R.id.widget_shuffle, shuf)
            }
''',
    '''            // ⋮ 메뉴: 지금은 음악일 때만 (랜덤 듣기 · 반복) — 세 위젯 모두 같음
            val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val music = try { fp.getBoolean("flutter.w_music", false) } catch (_: Exception) { false }
            views.setViewVisibility(R.id.widget_more, if (music && !empty) View.VISIBLE else View.GONE)
''',
    '사진 위 랜덤·반복 → ⋮ 보이기')
rep(W,
    '''            if (!tall) { // 세로 위젯엔 이 버튼이 없음 (없는 버튼을 건드리면 위젯이 안 뜸)
                views.setOnClickPendingIntent(R.id.widget_repeat, media(ACTION_REPEAT, 4))
                views.setOnClickPendingIntent(R.id.widget_shuffle, media(ACTION_SHUFFLE, 5))
            }''',
    '''            // ⋮ → 바탕화면 위 작은 창 (앱 화면은 안 열림)
            val menu = Intent(context, WidgetMenuActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            views.setOnClickPendingIntent(R.id.widget_more, PendingIntent.getActivity(
                context, 6, menu, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))''',
    '⋮ 누르면 메뉴 창 열기')

# ───────── AndroidManifest.xml ─────────
rep(MAN,
    '''        <!-- 홈 위젯 세로 2×3 (버튼은 모두 PlayerWidget이 받음) -->''',
    '''        <!-- 위젯 ⋮ 메뉴 창 (바탕화면 위에 작은 창만, 앱 화면은 안 열림 · 최근 앱에도 안 남음) -->
        <activity
            android:name=".WidgetMenuActivity"
            android:exported="false"
            android:excludeFromRecents="true"
            android:noHistory="true"
            android:taskAffinity=""
            android:theme="@android:style/Theme.Translucent.NoTitleBar" />

        <!-- 홈 위젯 세로 2×3 (버튼은 모두 PlayerWidget이 받음) -->''',
    '⋮ 메뉴 창 등록')

# ───────── colors.xml ─────────
rep(COL, '''    <color name="paran_w_line">#1417140F</color>''',
    '''    <color name="paran_w_line">#1417140F</color>
    <color name="paran_w_point">#2F7DE8</color>''', '켜짐 글자 색 (라이트)')
rep(COLN, '''    <color name="paran_w_line">#1AF3EFE7</color>''',
    '''    <color name="paran_w_line">#1AF3EFE7</color>
    <color name="paran_w_point">#6FB0FF</color>''', '켜짐 글자 색 (다크)')

# ───────── strings.xml (23개 언어) ─────────
# 순서: 랜덤 듣기 · 반복 · 켜짐 · 꺼짐 · 한 곡 반복 · 전체 반복
EN = ('Shuffle', 'Repeat', 'On', 'Off', 'Repeat one', 'Repeat all')
ZH_T = ('隨機播放', '循環', '開', '關', '單曲循環', '列表循環')
TR = {
    'values': EN, 'values-en': EN,
    'values-ko': ('랜덤 듣기', '반복', '켜짐', '꺼짐', '한 곡 반복', '전체 반복'),
    'values-ja': ('ランダム再生', 'リピート', 'オン', 'オフ', '1曲リピート', '全曲リピート'),
    'values-zh': ('随机播放', '循环', '开', '关', '单曲循环', '列表循环'),
    'values-zh-rTW': ZH_T, 'values-zh-rHK': ZH_T, 'values-zh-rMO': ZH_T,
    'values-de': ('Zufallswiedergabe', 'Wiederholen', 'An', 'Aus', 'Titel wiederholen', 'Alle wiederholen'),
    'values-es': ('Aleatorio', 'Repetir', 'Activado', 'Desactivado', 'Repetir una', 'Repetir todo'),
    'values-fr': ('Lecture aléatoire', 'Répéter', 'Activé', 'Désactivé', 'Répéter un titre', 'Tout répéter'),
    'values-it': ('Casuale', 'Ripeti', 'Attivo', 'Disattivo', 'Ripeti brano', 'Ripeti tutto'),
    'values-pt': ('Aleatório', 'Repetir', 'Ativado', 'Desativado', 'Repetir uma', 'Repetir todas'),
    'values-ru': ('Случайный порядок', 'Повтор', 'Вкл.', 'Выкл.', 'Повтор трека', 'Повтор всех'),
    'values-uk': ('Випадковий порядок', 'Повтор', 'Увімк.', 'Вимк.', 'Повтор треку', 'Повтор усіх'),
    'values-pl': ('Losowo', 'Powtarzaj', 'Wł.', 'Wył.', 'Powtarzaj utwór', 'Powtarzaj wszystko'),
    'values-cs': ('Náhodně', 'Opakovat', 'Zap.', 'Vyp.', 'Opakovat skladbu', 'Opakovat vše'),
    'values-hu': ('Véletlenszerű', 'Ismétlés', 'Be', 'Ki', 'Egy szám ismétlése', 'Összes ismétlése'),
    'values-ro': ('Aleatoriu', 'Repetare', 'Activat', 'Dezactivat', 'Repetă o piesă', 'Repetă tot'),
    'values-tr': ('Karışık çal', 'Tekrarla', 'Açık', 'Kapalı', 'Bir şarkıyı tekrarla', 'Tümünü tekrarla'),
    'values-ar': ('تشغيل عشوائي', 'تكرار', 'تشغيل', 'إيقاف', 'تكرار مقطع واحد', 'تكرار الكل'),
    'values-hi': ('शफ़ल', 'दोहराएँ', 'चालू', 'बंद', 'एक गाना दोहराएँ', 'सभी दोहराएँ'),
    'values-ur': ('بے ترتیب', 'دہرائیں', 'آن', 'آف', 'ایک گانا دہرائیں', 'سب دہرائیں'),
    'values-in': ('Acak', 'Ulangi', 'Aktif', 'Nonaktif', 'Ulangi satu', 'Ulangi semua'),
    'values-vi': ('Phát ngẫu nhiên', 'Lặp lại', 'Bật', 'Tắt', 'Lặp một bài', 'Lặp tất cả'),
    'values-th': ('สุ่มเพลง', 'เล่นซ้ำ', 'เปิด', 'ปิด', 'เล่นซ้ำเพลงเดียว', 'เล่นซ้ำทั้งหมด'),
}
KEYS = ('w_menu_shuffle', 'w_menu_repeat', 'w_menu_on', 'w_menu_off', 'w_menu_repeat_one', 'w_menu_repeat_all')
for folder, words in TR.items():
    p = os.path.join(RES, folder, 'strings.xml')
    lines = '    <!-- 위젯 ⋮ 메뉴 창 -->\n' + ''.join(
        f'    <string name="{k}">{v}</string>\n' for k, v in zip(KEYS, words))
    rep(p, '</resources>', lines + '</resources>', '⋮ 메뉴 글자')

# ───────── 괄호 확인 ─────────
def balanced(t):
    return t.count('{') == t.count('}') and t.count('(') == t.count(')')

if ok:
    if not balanced(files[W][0]):
        fail('PlayerWidget.kt — 괄호가 안 맞아요')
    if not balanced(ACT_KT):
        fail('WidgetMenuActivity.kt — 괄호가 안 맞아요')
    for L in (L1, L2, L3):
        if 'widget_shuffle' in files[L][0] or 'widget_repeat' in files[L][0]:
            fail(os.path.basename(L) + ' — 예전 랜덤·반복 버튼이 남아 있어요')
    if 'R.id.widget_shuffle' in files[W][0] or 'R.id.widget_repeat' in files[W][0]:
        fail('PlayerWidget.kt — 예전 랜덤·반복 버튼 코드가 남아 있어요')

if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

for p, body, label in NEW:
    files[p] = [body, True]
    print(f'✔ 새 파일 {os.path.basename(p)} — {label}')
for p, (body, crlf) in files.items():
    if crlf:
        body = body.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(body.encode('utf-8'))
print('\n다 됐어요! 음악을 틀고 위젯 사진 오른쪽 위 ⋮ 를 눌러 보세요.')
