# -*- coding: utf-8 -*-
# 안드로이드 오토(차 화면) 음악 탭에 색 넣기
#  - 음악 폴더(랜덤 재생 · 최근 · 즐겨찾기 · 전체 · 아티스트 · 장르): 차분한 색 칸 + 흰 아이콘
#  - 곡 목록: 앨범 사진 (앱에서 바꾼 사진 → 곡 파일 안 사진 → 없으면 고양이 사진)
#  - 아티스트 · 장르 목록: 이름 글자 색 칸
import os, sys

CAR = os.path.join('lib', 'services', 'car_browse.dart')
ART = os.path.join('android', 'app', 'src', 'main', 'kotlin', 'com', 'example', 'mp3_player', 'ArtProvider.kt')

EDITS = {
    ART: [
        (
"""import android.graphics.Paint
import android.graphics.Rect""",
"""import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect""",
        ),
        (
"""import android.graphics.Typeface
import android.net.Uri""",
"""import android.graphics.Typeface
import android.media.MediaMetadataRetriever
import android.net.Uri""",
        ),
        (
"""///  - asset : 앱 안의 사진 (자연소리 등)""",
"""///  - asset : 앱 안의 사진 (자연소리 등)
///  - icon  : 색 칸 + 흰 아이콘 (음악 탭 폴더: 랜덤 · 최근 · 즐겨찾기 · 전체 · 아티스트 · 장르)
///  - song  : 곡의 앨범 사진 (앱에서 바꾼 사진 → 곡 파일 안 사진 → 없으면 고양이 사진)""",
        ),
        (
"""                    "asset" -> asset(uri.getQueryParameter("p") ?: "")
                    else -> null""",
"""                    "asset" -> asset(uri.getQueryParameter("p") ?: "")
                    "icon" -> icon(uri.getQueryParameter("k") ?: "", color(uri))
                    "song" -> song(uri.getQueryParameter("u") ?: "", uri.getQueryParameter("k") ?: "")
                        ?: asset(uri.getQueryParameter("p") ?: "")
                    else -> null""",
        ),
        (
"""    /// 글자가 칸보다 길면 줄이기""",
"""    /// 색 칸 + 가운데 흰 아이콘 (아이콘은 24칸 바둑판 기준으로 그림 — 앱 아이콘과 같은 둥근 선)
    private fun icon(k: String, c: Int): Bitmap {
        val n = 256
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val light = mix(c, 0xFFFFFFFF.toInt(), 0.10f)
        cv.drawRect(0f, 0f, n.toFloat(), n.toFloat(), Paint().apply {
            shader = LinearGradient(0f, 0f, n.toFloat(), n.toFloat(), light, c, Shader.TileMode.CLAMP)
        })
        cv.drawCircle(n - 18f, 18f, 66f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x14FFFFFF })
        val s = n * 0.46f / 24f
        cv.translate((n - 24 * s) / 2f, (n - 24 * s) / 2f)
        cv.scale(s, s)
        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFFFFFFF.toInt(); style = Paint.Style.STROKE; strokeWidth = 2f
            strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND
        }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xFFFFFFFF.toInt(); style = Paint.Style.FILL }
        when (k) {
            "shuffle" -> {
                cv.drawPath(Path().apply {
                    moveTo(3.5f, 7f); lineTo(6f, 7f); cubicTo(8f, 7f, 9.2f, 7.9f, 10.3f, 9.6f)
                    lineTo(13.7f, 14.4f); cubicTo(14.8f, 16.1f, 16f, 17f, 18f, 17f); lineTo(20.5f, 17f)
                    moveTo(3.5f, 17f); lineTo(6f, 17f); cubicTo(7.5f, 17f, 8.6f, 16.5f, 9.5f, 15.5f)
                    moveTo(14.5f, 8.5f); cubicTo(15.4f, 7.5f, 16.5f, 7f, 18f, 7f); lineTo(20.5f, 7f)
                    moveTo(18f, 4.5f); lineTo(20.5f, 7f); lineTo(18f, 9.5f)
                    moveTo(18f, 14.5f); lineTo(20.5f, 17f); lineTo(18f, 19.5f)
                }, line)
            }
            "recent" -> {
                cv.drawCircle(12f, 12f, 8f, line)
                cv.drawPath(Path().apply { moveTo(12f, 8f); lineTo(12f, 12f); lineTo(15f, 14f) }, line)
            }
            "fav" -> cv.drawPath(Path().apply {
                moveTo(12f, 20f)
                cubicTo(5f, 15.6f, 3f, 12f, 3f, 9.5f); cubicTo(3f, 6.9f, 5f, 5f, 7.5f, 5f)
                cubicTo(9.3f, 5f, 11f, 6f, 12f, 7.6f); cubicTo(13f, 6f, 14.7f, 5f, 16.5f, 5f)
                cubicTo(19f, 5f, 21f, 6.9f, 21f, 9.5f); cubicTo(21f, 12f, 19f, 15.6f, 12f, 20f)
                close()
            }, fill)
            "all" -> {
                cv.drawPath(Path().apply { moveTo(9f, 18f); lineTo(9f, 6f); lineTo(19f, 4f); lineTo(19f, 16f) }, line)
                cv.drawCircle(7f, 18f, 2.4f, fill)
                cv.drawCircle(17f, 16f, 2.4f, fill)
            }
            "artist" -> {
                cv.drawRoundRect(RectF(9f, 3f, 15f, 14f), 3f, 3f, fill)
                cv.drawArc(RectF(6f, 5f, 18f, 17f), 0f, 180f, false, line)
                cv.drawLine(12f, 17f, 12f, 21f, line)
            }
            "genre" -> {
                cv.drawPath(Path().apply {
                    moveTo(4f, 12f); lineTo(4f, 4f); lineTo(12f, 4f); lineTo(20f, 12f); lineTo(12f, 20f); close()
                }, line)
                cv.drawCircle(8.5f, 8.5f, 1.6f, fill)
            }
            else -> cv.drawCircle(12f, 12f, 7f, line)
        }
        return b
    }

    /// 곡 앨범 사진: 앱에서 바꾼 사진(files/album_art/키.jpg) → 곡 파일 안 사진 — 둘 다 없으면 null (그럼 고양이 사진)
    /// 폰 안 음악 파일만 (앱 안쪽 파일은 안 열어 줌)
    private fun song(u: String, key: String): Bitmap? {
        val ctx = context ?: return null
        if (key.isNotEmpty() && key.all { it.isDigit() }) {
            val f = File(ctx.filesDir, "album_art/$key.jpg")
            if (f.exists()) bytes(f.readBytes(), 320)?.let { return it }
        }
        val ok = u.startsWith("/storage/") || u.startsWith("/sdcard/") || u.startsWith("content://media/")
        if (!ok || u.contains("..")) return null
        val r = MediaMetadataRetriever()
        return try {
            if (u.startsWith("content://")) r.setDataSource(ctx, Uri.parse(u)) else r.setDataSource(u)
            r.embeddedPicture?.let { bytes(it, 320) }
        } catch (_: Exception) {
            null
        } finally {
            try { r.release() } catch (_: Exception) {}
        }
    }

    /// 그림 데이터 → 네모로 잘라 max 크기까지
    private fun bytes(data: ByteArray, max: Int): Bitmap? {
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(data, 0, data.size, o)
        if (o.outWidth <= 0) return null
        var s = 1
        while (minOf(o.outWidth, o.outHeight) / (s * 2) >= max) s *= 2
        val src = BitmapFactory.decodeByteArray(data, 0, data.size,
            BitmapFactory.Options().apply { inSampleSize = s }) ?: return null
        return square(src, max)
    }

    /// 글자가 칸보다 길면 줄이기""",
        ),
        (
"""    /// 저장 그림이 너무 많으면 오래된 것부터 지우기 (300개까지)
    private fun trim(dir: File) {
        val fs = dir.listFiles() ?: return
        if (fs.size <= 300) return
        fs.sortedBy { it.lastModified() }.take(fs.size - 300).forEach { it.delete() }
    }""",
"""    /// 저장 그림이 너무 많으면 오래된 것부터 지우기 (600개까지 — 곡 앨범 사진이 많아서)
    private fun trim(dir: File) {
        val fs = dir.listFiles() ?: return
        if (fs.size <= 600) return
        fs.sortedBy { it.lastModified() }.take(fs.size - 600).forEach { it.delete() }
    }""",
        ),
    ],
    CAR: [
        (
"""import '../utils/nature_sound_catalog.dart';
import 'headset_resume.dart';""",
"""import '../utils/nature_sound_catalog.dart';
import '../utils/no_album_helper.dart';
import 'headset_resume.dart';""",
        ),
        (
"""  static Uri _asset(String asset) => Uri.parse('$_auth/asset?p=${Uri.encodeQueryComponent(asset)}');""",
"""  static Uri _asset(String asset) => Uri.parse('$_auth/asset?p=${Uri.encodeQueryComponent(asset)}');
  /// 색 칸 + 흰 아이콘 (음악 탭 폴더)
  static Uri _iconTile(String kind, int color) => Uri.parse('$_auth/icon?k=$kind&c=${color.toRadixString(16)}');

  /// 곡 앨범 사진 (k: 앱에서 바꾼 사진 파일 이름 · v: 사진이 바뀌면 새로 그리게 · p: 사진 없을 때 고양이 사진)
  static Uri _songArt(Song s) {
    final u = s.uri ?? '';
    return Uri.parse('$_auth/song?u=${Uri.encodeQueryComponent(u)}&k=${u.hashCode.abs()}'
        '&v=${s.albumArt?.length ?? 0}&p=${Uri.encodeQueryComponent(noAlbumImagePath(u.isEmpty ? s.title : u))}');
  }

  /// 음악 탭 폴더 색 (앱 포인트 색과 어울리는 차분한 색)
  static const _musicColors = {
    'shuffle': 0xFF4B56B8, 'recent': 0xFF2E6B5E, 'fav': 0xFF9C3D52,
    'all': 0xFF2F5E9E, 'artist': 0xFF7A5230, 'genre': 0xFF5E4785,
  };
  static Uri _musicIcon(String kind) => _iconTile(kind, _musicColors[kind]!);""",
        ),
        (
"""        title: s.titleDisplay,
        artist: s.artistDisplay,
        playable: true,
        extras: group == null ? null : {_group: group},
      );""",
"""        title: s.titleDisplay,
        artist: s.artistDisplay,
        playable: true,
        artUri: _songArt(s),
        extras: group == null ? null : {_group: group},
      );""",
        ),
        (
"""    MediaItem folder(String id, String title, {String? sub}) => MediaItem(
        id: 'ml:$id', title: title, displaySubtitle: sub, artist: sub, playable: false,
        extras: _style(browsable: _list, playable: _list));""",
"""    MediaItem folder(String id, String title, String icon, {String? sub}) => MediaItem(
        id: 'ml:$id', title: title, displaySubtitle: sub, artist: sub, playable: false,
        artUri: _musicIcon(icon), extras: _style(browsable: _list, playable: _list));""",
        ),
        (
"""            id: 'mshuffle', title: tr.shufflePlay, displaySubtitle: '$all', artist: '$all', playable: true,
            artUri: _icon('paran_ic_shuffle')),
      folder('recent', tr.homeRecentHeader),
      folder('fav', tr.favorites),
      folder('all', tr.all, sub: all > 0 ? '$all' : null),
      folder('artists', tr.artists),
      folder('genres', tr.genre),""",
"""            id: 'mshuffle', title: tr.shufflePlay, displaySubtitle: '$all', artist: '$all', playable: true,
            artUri: _musicIcon('shuffle')),
      folder('recent', tr.homeRecentHeader, 'recent'),
      folder('fav', tr.favorites, 'fav'),
      folder('all', tr.all, 'all', sub: all > 0 ? '$all' : null),
      folder('artists', tr.artists, 'artist'),
      folder('genres', tr.genre, 'genre'),""",
        ),
        (
"""              displaySubtitle: '${counts[n]}',
              artist: '${counts[n]}',
              playable: false,
              extras: _style(playable: _list)),""",
"""              displaySubtitle: '${counts[n]}',
              artist: '${counts[n]}',
              playable: false,
              artUri: _tile(key == 'artists' ? _initials(n) : n, '', _colorOf(n)), // 이름 글자 색 칸
              extras: _style(playable: _list)),""",
        ),
    ],
}

MARK = (CAR, '_songArt')


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    if os.path.exists(MARK[0]):
        with open(MARK[0], 'rb') as f:
            if MARK[1].encode() in f.read():
                print('이미 적용돼 있어요')
                return
    out = {}
    ok = True
    for rel, pairs in EDITS.items():
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(rel, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[rel] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for rel, text in out.items():
        with open(rel, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
