import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../theme.dart';

class EliteAssignmentHub extends HookWidget {
  const EliteAssignmentHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolColors.darkBg,
      appBar: AppBar(
        title: const Text('Assignment Hub'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text('Assignment Hub Elite Placeholder', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
