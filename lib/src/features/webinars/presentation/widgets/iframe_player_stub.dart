import 'package:flutter/material.dart';

class IframePlayer extends StatelessWidget {
  const IframePlayer({super.key, required this.embedUrl});
  final String embedUrl;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Встроенный плеер доступен в веб-версии.'),
    );
  }
}
