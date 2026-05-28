// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

class IframePlayer extends StatefulWidget {
  const IframePlayer({super.key, required this.embedUrl});
  final String embedUrl;

  @override
  State<IframePlayer> createState() => _IframePlayerWebState();
}

class _IframePlayerWebState extends State<IframePlayer> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'iframe-player-${widget.embedUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    
    // Register the iframe view factory
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..allow = 'autoplay; encrypted-media; picture-in-picture';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
