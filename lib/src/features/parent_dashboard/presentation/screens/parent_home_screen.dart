import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;

    return Scaffold(
      body: CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        streamFactory: () => repo.firestore.collection('users').doc(uid).snapshots(),
        keys: [uid],
        builder: (context, userSnap) {
          if (!userSnap.hasData)
            return const Center(child: CircularProgressIndicator());
          final userData = userSnap.data!.data();
          final childIds = List<String>.from(userData?['childIds'] ?? []);

          if (childIds.isEmpty) {
            return const _NoChildrenState();
          }

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(32, 64, 32, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Панель родителей',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Мониторинг успеваемости ваших детей',
                        style: TextStyle(
                          color: SchoolColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ChildProgressCard(childId: childIds[i]),
                    childCount: childIds.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _ChildProgressCard extends StatelessWidget {
  const _ChildProgressCard({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: repo.firestore.collection('users').doc(childId).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 100);
        final data = snap.data!.data();
        final name = data?['name'] ?? 'Ученик';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SchoolCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SchoolAvatar(
                      name: name,
                      avatarUrl: data?['avatarUrl'],
                      radius: 28,
                      userId: childId,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            '7-й класс "А"',
                            style: TextStyle(
                              color: SchoolColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    _MetricTile(
                      label: 'Ср. балл',
                      value: '4.8',
                      color: SchoolColors.green,
                    ),
                    SizedBox(width: 12),
                    _MetricTile(
                      label: 'Посещаемость',
                      value: '98%',
                      color: SchoolColors.primary,
                    ),
                    SizedBox(width: 12),
                    _MetricTile(
                      label: 'Задания',
                      value: '12/12',
                      color: SchoolColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Последние оценки',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                const _RecentGrades(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: SchoolColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentGrades extends StatelessWidget {
  const _RecentGrades();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GradeBubble(subject: 'Мат', grade: '5'),
        _GradeBubble(subject: 'Рус', grade: '4'),
        _GradeBubble(subject: 'Физ', grade: '5'),
        _GradeBubble(subject: 'Ист', grade: '5'),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: const Text('Все оценки', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _GradeBubble extends StatelessWidget {
  const _GradeBubble({required this.subject, required this.grade});
  final String subject, grade;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SchoolColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            grade,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: SchoolColors.primary,
            ),
          ),
          Text(
            subject,
            style: const TextStyle(fontSize: 9, color: SchoolColors.muted),
          ),
        ],
      ),
    );
  }
}

class _NoChildrenState extends StatelessWidget {
  const _NoChildrenState();

  Future<void> _showLinkChildDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final repo = AppScope.of(context).repository;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Привязать ребенка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите Email вашего ребенка для привязки профиля.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'email@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Привязать'),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.isNotEmpty) {
      try {
        final email = ctrl.text.trim().toLowerCase();
        final snap = await repo.firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          throw 'Пользователь с таким email не найден';
        }

        final childId = snap.docs.first.id;
        final uid = repo.uid;

        await repo.firestore.collection('users').doc(uid).update({
          'childIds': FieldValue.arrayUnion([childId]),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ребенок успешно привязан')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            size: 64,
            color: SchoolColors.border,
          ),
          const SizedBox(height: 24),
          const Text(
            'Дети не привязаны',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Используйте код ребенка, чтобы привязать профиль',
            style: TextStyle(color: SchoolColors.muted),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showLinkChildDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Привязать ребенка'),
          ),
        ],
      ),
    );
  }
}
