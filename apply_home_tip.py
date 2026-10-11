# 홈 팁 카드: 짧은 문구 + 배터리 [설정] 버튼 + 다크 모드에서도 검정 카드
import sys, os
PATH = os.path.join('lib', 'screens', 'home_screen.dart')
if len(sys.argv) > 1: PATH = sys.argv[1]
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

R = [
('카드 색 (다크 모드도 검정)',
"""    final card = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final ink = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final sub = isDark ? const Color(0xFF8A8378) : const Color(0xFFA29A8B);
    final circle = isDark ? const Color(0xFFE4DCCD) : const Color(0xFF2A251D);
""",
"""    // 카드는 라이트·다크 모두 검정 (다크는 바탕보다 한 톤 더 까맣게 + 얇은 테두리)
    final card = isDark ? const Color(0xFF0E0D0B) : const Color(0xFF17140F);
    const ink = Color(0xFFF4EFE5);
    const sub = Color(0xFFA29A8B);
    final circle = isDark ? const Color(0xFF26231F) : const Color(0xFF2A251D);
"""),
('팁 문구 5개',
"""      const tips = <(IconData, String, String)>[
        (Icons.notifications_active_outlined, '좋아하는 곡을 벨소리로', '곡 ⋮ 메뉴에서 벨소리·알림음으로 만들 수 있어요'),
        (Icons.movie_outlined, '동영상에서 음악만 저장', '동영상 ⋮ 메뉴 → 음악으로 저장'),
        (Icons.battery_charging_full_rounded, '화면 꺼도 음악이 안 끊기게', '앱 정보 → 배터리 → 제한 없음'),
        (Icons.water_drop_outlined, '음악에 빗소리 섞기', '재생화면 ⋮ 메뉴 → 자연소리 섞기'),
        (Icons.format_quote_rounded, '가사 한 줄 공유', '가사를 꾹 누르면 카드로 보낼 수 있어요'),
      ];""",
"""      const tips = <(IconData, String, String)>[
        (Icons.battery_charging_full_rounded, '화면 꺼도 계속 들어요', "배터리를 '제한 없음'으로 바꿔 주세요"),
        (Icons.notifications_active_outlined, '노래로 벨소리 만들기', '곡 ⋮ 메뉴에서 바로 만들어요'),
        (Icons.movie_outlined, '동영상 노래만 저장', "동영상 ⋮ 메뉴에서 '음악으로 저장'"),
        (Icons.water_drop_outlined, '음악에 빗소리 더하기', '재생 화면 ⋮ 메뉴 → 자연소리 섞기'),
        (Icons.format_quote_rounded, '가사 한 줄 공유', '가사를 꾹 누르면 카드로 보내요'),
      ];"""),
('배터리 팁에 [설정] 버튼',
"""      subLine = Text(tip.$3,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
    }
""",
"""      subLine = Text(tip.$3,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));
      // 배터리 팁만: [설정] 누르면 파란소리 앱 설정이 바로 열림
      if (tip.$1 == Icons.battery_charging_full_rounded) {
        action = '설정';
        onAction = () => openAppSettings();
      }
    }
"""),
('다크 모드 얇은 테두리',
"""      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [""",
"""      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: ["""),
]

if "화면 꺼도 계속 들어요" in src:
    print('이미 적용돼 있어요'); sys.exit(0)
ok = True
for name, old, new in R:
    n = src.count(old)
    if n != 1:
        print(f'❌ {name}: 찾을 코드를 {"못 찾았어요" if n == 0 else f"{n}곳에서 찾았어요"}'); ok = False
    else:
        src = src.replace(old, new); print(f'✔ {name}')
if not ok:
    print('아무것도 저장하지 않았어요'); sys.exit(1)
out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('저장했어요:', PATH)
