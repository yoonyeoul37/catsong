# -*- coding: utf-8 -*-
# 국내 라디오 → 팟캐스트 → 주제별 찾기(검색 결과)에서 시스템 뒤로가기를 누르면
# 라디오 '전체' 목록으로 가 버리던 것 → 팟캐스트 인기 순위로 돌아가게 (위 ×와 같게)
#  - 팟캐스트 화면과 라디오 화면이 뒤로가기를 동시에 받아서 바깥(라디오)이 '전체'로 바꿨음
#  - 팟캐스트가 검색·주제 결과를 보는 중이면 바깥 라디오 화면은 가만히
import os, sys

KR = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
PS = os.path.join('lib', 'podcast', 'podcast_screens.dart')

EDITS = {
    PS: [
        (
"""class PodcastTab extends StatefulWidget {
  final String country; // 'kr' · 'US' 등 (나라별 순위)""",
"""class PodcastTab extends StatefulWidget {
  /// 주제·검색 결과를 보는 중이면 true (바깥 라디오 화면의 뒤로가기가 끼어들지 않게)
  static bool inSearch = false;
  final String country; // 'kr' · 'US' 등 (나라별 순위)""",
        ),
        (
"""  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();""",
"""  @override
  void dispose() {
    PodcastTab.inSearch = false;
    _search.dispose();
    _searchFocus.dispose();""",
        ),
        (
"""    final searching = _query.isNotEmpty;
""",
"""    final searching = _query.isNotEmpty;
    PodcastTab.inSearch = searching || _searchOpen;
""",
        ),
    ],
    KR: [
        (
"""              if (!didPop) setState(() => _mode = _ViewMode.all);""",
"""              // 팟캐스트에서 주제·검색 결과를 보는 중이면 → 팟캐스트 화면이 순위로 돌려놓음 (여기선 그대로)
              if (_mode == _ViewMode.podcast && PodcastTab.inSearch) return;
              if (!didPop) setState(() => _mode = _ViewMode.all);""",
        ),
    ],
}

MARK = (PS, 'static bool inSearch')


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
