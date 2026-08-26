import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class IframePlayer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Text(AppLocalizations.of(context)!.theBuiltinPlayerIsAvailable),
    );
  }
}
