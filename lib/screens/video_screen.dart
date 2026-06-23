import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import '../providers/video_provider.dart';
import '../models/video.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoProvider>();
      if (!provider.hasPermission && provider.videos.isEmpty) {
        provider.requestPermissionAndLoad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.watch<VideoProvider>();

    if (videoProvider.permissionDenied) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined,
                    size: 72, color: Colors.white.withOpacity(0.5)),
                const SizedBox(height: 24),
                Text(AppLocalizations.of(context)!.videoPermissionRequired,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.videoPermissionMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(AppLocalizations.of(context)!.openSettings,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (videoProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white60),
        ),
      );
    }

    if (videoProvider.videos.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 72, color: Colors.white.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.noVideosFound,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.background,
            expandedHeight: 80 * MediaQuery.of(context).textScaler.scale(1.0),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.videos,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(AppLocalizations.of(context)!.videoCount(videoProvider.videos.length),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _VideoTile(video: videoProvider.videos[index]);
                },
                childCount: videoProvider.videos.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _VideoTile extends StatefulWidget {
  final Video video;

  const _VideoTile({required this.video});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  static const _channel = MethodChannel('kr.ssing.catsong/media');
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final result = await _channel.invokeMethod('getVideoThumbnail', {
        'path': widget.video.uri,
      });
      if (result != null && mounted) {
        setState(() {
          _thumbnail = Uint8List.fromList(List<int>.from(result));
        });
      }
    } catch (e) {
      // 썸네일 로드 실패
    }
  }

  Future<void> _showOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title: Text(AppLocalizations.of(context)!.rename,
                  style: const TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _renameVideo(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(AppLocalizations.of(context)!.delete,
                  style: const TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteVideo(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameVideo(BuildContext context) async {
    final controller = TextEditingController(text: widget.video.titleDisplay);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(AppLocalizations.of(context)!.rename,
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white60)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppLocalizations.of(context)!.save,
                style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await _channel.invokeMethod('renameVideo', {
          'uri': widget.video.uri,
          'newName': newName,
        });
        context.read<VideoProvider>().loadVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nameChanged,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.surfaceVariant,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.renameFailed(e.toString()),
                style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(AppLocalizations.of(context)!.deleteVideoTitle,
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(AppLocalizations.of(context)!.deleteVideoConfirm(widget.video.titleDisplay),
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _channel.invokeMethod('deleteVideo', {'uri': widget.video.uri});
        context.read<VideoProvider>().loadVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deleted),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.deleteFailedWithError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(video: widget.video),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: _thumbnail != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _thumbnail!,
                      fit: BoxFit.cover,
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 36,
                      ),
                    ),
                  ],
                )
                    : Container(
                  color: AppTheme.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white60,
                        size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.video.titleDisplay,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    widget.video.durationFormatted,
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoPlayerController = VideoPlayerController.file(
      File(widget.video.uri),
    );

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.white,
        handleColor: Colors.white,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.video.titleDisplay,
            style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.rename,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.delete,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'rename') {
                final controller = TextEditingController(text: widget.video.titleDisplay);
                final newName = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surfaceVariant,
                    title: Text(AppLocalizations.of(context)!.rename,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white60)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(color: AppTheme.textHint)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, controller.text),
                        child: Text(AppLocalizations.of(context)!.save,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                );
                if (newName != null && newName.isNotEmpty) {
                  await const MethodChannel('kr.ssing.catsong/media')
                      .invokeMethod('renameVideo', {
                    'uri': widget.video.uri,
                    'newName': newName,
                  });
                  Navigator.pop(context);
                }
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surfaceVariant,
                    title: Text(AppLocalizations.of(context)!.deleteVideoTitle,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    content: Text(
                        AppLocalizations.of(context)!.deleteVideoConfirm(widget.video.titleDisplay),
                        style: const TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(color: AppTheme.textHint)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(AppLocalizations.of(context)!.delete,
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await const MethodChannel('kr.ssing.catsong/media')
                      .invokeMethod('deleteVideo', {'uri': widget.video.uri});
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}