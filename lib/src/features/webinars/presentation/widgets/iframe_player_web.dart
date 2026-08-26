// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

class IframePlayer extends StatefulWidget {
  const IframePlayer({
    super.key,
    required this.sourceUrl,
    this.useVideoElement = false,
    this.onReady,
    this.onError,
  });
  final String sourceUrl;
  final bool useVideoElement;
  final VoidCallback? onReady;
  final VoidCallback? onError;

  @override
  State<IframePlayer> createState() => _IframePlayerWebState();
}

class _IframePlayerWebState extends State<IframePlayer> {
  static final Set<String> _registeredViewTypes = <String>{};
  late String _viewId;

  @override
  void initState() {
    super.initState();
    final kind = widget.useVideoElement ? 'video' : 'iframe';
    _viewId = 'webinar-player-$kind-${widget.sourceUrl.hashCode}';

    if (_registeredViewTypes.add(_viewId)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        if (widget.useVideoElement) {
          final video = html.VideoElement()
            ..src = widget.sourceUrl
            ..controls = true
            ..autoplay = false
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = '#000000'
            ..style.objectFit = 'contain'
            ..style.pointerEvents = 'auto'
            ..setAttribute('playsinline', 'true');
          video.onLoadedData.listen((_) => widget.onReady?.call());
          video.onError.listen((_) => widget.onError?.call());
          return video;
        }

        final iframe = html.IFrameElement()
          ..src = widget.sourceUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'auto'
          ..allowFullscreen = true
          ..allow = 'autoplay; encrypted-media; picture-in-picture';
        iframe.onLoad.listen((_) => widget.onReady?.call());
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
