import 'package:school_world/l10n/app_localizations.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/string_extensions.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const InlineVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  Future<void> _playVideo() async {
    if (_isInitialized) {
      _videoPlayerController?.play();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _videoPlayerController = controller;
      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio,
        autoPlay: true,
        looping: false,
        showControls: true,
        showOptions: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        allowFullScreen: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _chewieController = chewie;
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = widget.videoUrl.contains('cloudinary.com')
        ? widget.videoUrl.replaceAll(RegExp(r'\.(mp4|mov|webm|mkv)$', caseSensitive: false), '.jpg')
        : null;

    if (_hasError) {
      return Container(
        height: 160,
        color: Colors.black.withOpacity(0.05),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.failedToLoadVideo,
              style: TextStyle(fontSize: 12, color: SchoolColors.muted),
            ),
          ],
        ),
      );
    }

    if (_isInitialized && _chewieController != null && _videoPlayerController != null) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Chewie(
          controller: _chewieController!,
        ),
      );
    }

    // Otherwise, show the Telegram-style preview card
    return AspectRatio(
      aspectRatio: 16 / 9, // Standard video aspect ratio for the card
      child: GestureDetector(
        onTap: _isLoading ? null : _playVideo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image or placeholder
            if (thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: thumbnailUrl.toDirectImageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // Dark overlay for contrast
            Container(
              color: Colors.black.withOpacity(0.25),
            ),

            // Play button or Loading Indicator
            Center(
              child: _isLoading
                  ? SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
            ),

            // Duration tag or label
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.video1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E0854), Color(0xFF1C0A35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.video_collection_rounded,
          color: Colors.white.withOpacity(0.15),
          size: 48,
        ),
      ),
    );
  }
}
