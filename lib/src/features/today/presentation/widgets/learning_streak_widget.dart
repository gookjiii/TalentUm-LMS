import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class LearningStreakWidget extends StatelessWidget {
  const LearningStreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;

    return CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      streamFactory: () => repo.firestore.collection('users').doc(uid).snapshots(),
      keys: [uid],
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final streak = data?['streak'] as int? ?? 0;
        final lastActivity = data?['lastActivity'] as Timestamp?;

        bool activeToday = false;
        if (lastActivity != null) {
          final last = lastActivity.toDate();
          final now = DateTime.now();
          activeToday =
              last.day == now.day &&
              last.month == now.month &&
              last.year == now.year;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: SchoolColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SchoolColors.orange.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _FireIcon(active: activeToday),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak-дневная серия!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      activeToday
                          ? 'Сегодняшняя цель достигнута'
                          : 'Выполни задание, чтобы не прервать серию',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FireIcon extends StatefulWidget {
  const _FireIcon({required this.active});
  final bool active;
  @override
  State<_FireIcon> createState() => _FireIconState();
}

class _FireIconState extends State<_FireIcon> {
  bool _grow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() => _grow = !_grow);
      }
    });
  }

  @override
  void didUpdateWidget(_FireIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startTimer();
    } else if (!widget.active && oldWidget.active) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.active ? (_grow ? 1.15 : 0.96) : 1.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: Icon(
        Icons.local_fire_department_rounded,
        color: widget.active ? Colors.orange : Colors.grey.withOpacity(0.5),
        size: 40,
      ),
    );
  }
}
