import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../utils/no_album_helper.dart';

/// 파란소리 포인트 블루
const kMenuBlue = Color(0xFF2589E8);

/// 빠른 버튼 하나 (아이콘 + 글자)
class MenuQuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const MenuQuickAction(this.icon, this.label, this.onTap);
}

/// 점 3개 메뉴 맨 위: 곡 정보 + 빠른 버튼 4개를 흰 카드 하나로
class MenuSongCard extends StatelessWidget {
  final Song song;
  final List<MenuQuickAction> actions;
  final bool isDark;
  const MenuSongCard({super.key, required this.song, required this.actions, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF35302A) : Colors.white;
    final line = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEE9DF);
    final titleColor = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final subColor = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A857B);
    final labelColor = isDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);

    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: song.albumArt != null
                      ? Image.memory(Uint8List.fromList(song.albumArt!),
                      width: 52, height: 52, fit: BoxFit.cover, gaplessPlayback: true)
                      : Image.asset(noAlbumImagePath(song.uri ?? song.title),
                      width: 52, height: 52, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(song.titleDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: titleColor, fontSize: 15.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(song.artistDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subColor, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: line),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: actions[i].onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: i == 0 ? null : Border(left: BorderSide(color: line, width: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Icon(actions[i].icon, color: kMenuBlue, size: 21),
                          const SizedBox(height: 4),
                          Text(actions[i].label, style: TextStyle(color: labelColor, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 메뉴 줄들을 흰 카드 하나로 묶음 (줄 사이 얇은 선)
class MenuCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const MenuCard({super.key, required this.children, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final line = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEE9DF);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF35302A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 0.5, margin: const EdgeInsets.only(left: 48), color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}