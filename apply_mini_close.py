# 미니플레이어 X(닫기) 아이콘 살짝 키우기: 14 -> 17 (음악·라디오·자연·믹스 4개)
import os, sys

FILES = [
    'lib/widgets/mini_player.dart',
    'lib/widgets/radio_mini_player.dart',
    'lib/widgets/nature_mini_player.dart',
    'lib/widgets/sound_mix_mini_player.dart',
]
OLD = "Icon(Icons.close_rounded, size: 14, color: const Color(0xFFF4EFE5).withOpacity(0.45))"
NEW = "Icon(Icons.close_rounded, size: 17, color: const Color(0xFFF4EFE5).withOpacity(0.45))"

results = {}
ok = True
done = 0
for path in FILES:
    name = os.path.basename(path)
    if not os.path.exists(path):
        print(f'❌ {name} 파일이 없어요'); ok = False; continue
    with open(path, 'rb') as f:
        raw = f.read()
    text = raw.decode('utf-8')
    if NEW in text and OLD not in text:
        print(f'✔ {name} 이미 적용돼 있어요'); done += 1; continue
    if text.count(OLD) != 1:
        print(f'❌ {name} 바꿀 곳을 못 찾았어요'); ok = False; continue
    results[path] = text.replace(OLD, NEW)
    print(f'✔ {name} X 아이콘 14 → 17')

if not ok:
    print('\n❌ 못 찾은 곳이 있어서 아무것도 저장하지 않았어요'); sys.exit(1)
if done == len(FILES):
    print('\n이미 적용돼 있어요'); sys.exit(0)
for path, text in results.items():
    with open(path, 'wb') as f:
        f.write(text.encode('utf-8'))  # 원래 줄바꿈 그대로
print('\n완료!')
