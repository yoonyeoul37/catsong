import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import 'paran_dialog.dart';
import 'action_feedback.dart';
import '../l10n/locale_holder.dart';

/// 재생목록에 추가 (곡 목록 ⋮ · 재생화면 ⋮ 같이 씀)
/// 맨 위 "새 재생목록 만들기" → 이름 쓰면 만들고 바로 이 곡을 넣어요
Future<void> showAddToPlaylistSheet(BuildContext context, Song song) async {
  final pp = context.read<PlaylistProvider>();
  final appCtx = Navigator.of(context, rootNavigator: true).context;
  await showParanSheet(
    context,
    title: tr.addToPlaylist,
    builder: (ctx, setSheet) => ParanCard(
      children: [
        ParanRow(
          icon: Icons.add_rounded,
          title: tr.newPlaylistCreate,
          accent: true,
          onTap: () async {
            Navigator.pop(ctx);
            final name = await showParanInput(appCtx,
                title: tr.newPlaylist, hint: tr.playlistHintExample, confirmLabel: tr.createAndAdd);
            if (name == null) return;
            await pp.createPlaylist(name);
            final made = pp.playlists.where((p) => p.name == name).toList();
            if (made.isEmpty) return;
            await pp.addSongToPlaylist(made.last.id, song);
            showActionFeedback(appCtx, type: ActionFeedbackType.added, message: tr.addedToPlaylist);
          },
        ),
        for (final pl in pp.playlists)
          ParanRow(
            icon: Icons.queue_music_rounded,
            title: pl.name,
            trailingText: tr.songsCount(pl.songCount),
            onTap: () {
              pp.addSongToPlaylist(pl.id, song);
              Navigator.pop(ctx);
              showActionFeedback(appCtx, type: ActionFeedbackType.added, message: tr.addedToPlaylist);
            },
          ),
      ],
    ),
  );
}
