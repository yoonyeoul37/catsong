# -*- coding: utf-8 -*-
# 동영상 목록 A안: 회색 칸·큰 ▶ 빼고, 16:9 썸네일 + 시간 작은 표 + 제목 두 줄
import os, re, sys
P = os.path.join('lib', 'screens', 'video_screen.dart')
if not os.path.exists(P):
    sys.exit('❌ video_screen.dart 를 못 찾았어요. mp3_player_new 폴더에서 실행해 주세요.')
raw = open(P, encoding='utf-8').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '// 16:9 썸네일' in s:
    sys.exit('이미 적용돼 있어요.')

def rep(pattern, new, name, regex=False):
    global s
    if regex:
        m = list(re.finditer(pattern, s, re.S))
        if len(m) != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({len(m)}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s[:m[0].start()] + new + s[m[0].end():]
    else:
        n = s.count(pattern)
        if n != 1:
            sys.exit(f'❌ [{name}] 바꿀 곳을 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요 — 이 줄을 보여주세요.')
        s = s.replace(pattern, new)
    print(f'✔ {name}')

# 1) 위 제목: "동영상 (24)" — 다른 목록들과 같은 모양
rep(r"""                      Text\(AppLocalizations\.of\(context\)!\.videos,
                          style: TextStyle\(
                              color: baseColor,
                              fontSize: 18,
                              fontWeight: FontWeight\.bold\)\),
                      Text\(AppLocalizations\.of\(context\)!\.videoCount\(videoProvider\.videos\.length\),
                          style: TextStyle\(
                              color: baseColor\.withOpacity\(0\.7\), fontSize: 13\)\),""",
"""                      Row(
                        children: [
                          Text(AppLocalizations.of(context)!.videos,
                              style: TextStyle(
                                  color: baseColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(width: 8),
                          Text('(${videoProvider.videos.length})',
                              style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                        ],
                      ),""", '위 제목', regex=True)

# 2) 칸 비율·간격 (16:9 썸네일 + 제목 두 줄)
rep("""          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),""",
"""          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.18, // 16:9 사진 + 제목 두 줄
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),""", '칸 비율')

# 3) 칸 모양
TILE = r"""        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 썸네일 (회색 칸·큰 ▶ 없이) + 오른쪽 아래 재생 시간 작은 표
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_thumbnail != null)
                      Image.memory(
                        _thumbnail!,
                        fit: BoxFit.cover,
                        cacheWidth: 400, // 칸 크기만큼만 풀기
                        gaplessPlayback: true,
                      )
                    else
                      Container(
                        color: baseColor.withOpacity(0.06),
                        child: Icon(Icons.movie_outlined, color: baseColor.withOpacity(0.3), size: 26),
                      ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17140F).withOpacity(0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.video.durationFormatted,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 제목 두 줄까지
            Flexible(
              child: Text(
                widget.video.titleDisplay,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ),
          ],
        );"""
rep(r"        return Container\(\n          decoration: BoxDecoration\(\n            color: baseColor\.withOpacity\(0\.06\),\n            borderRadius: BorderRadius\.circular\(12\),\n          \),\n          child: Column\(.*?\n        \);(?=\n      \}\),\n    \);\n  \}\n\})",
    TILE, '칸 모양', regex=True)

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if crlf else s)
print('\n✅ 끝! 동영상 목록이 A안으로 바뀌었어요.')
