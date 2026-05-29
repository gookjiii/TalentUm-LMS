import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class IframePlayer extends StatelessWidget {
  const IframePlayer({super.key, required this.embedUrl});
  final String embedUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(AppLocalizations.of(context)!.theBuiltinPlayerIsAvailable),
    );
  }
}
