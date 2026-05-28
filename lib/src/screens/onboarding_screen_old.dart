import 'package:flutter/material.dart';

import '../../main.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _selectedRole = 'student';
  final _codeController = TextEditingController();
  Map<String, dynamic>? _previewData;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Top Bar with progress and back button
              _buildTopBar(),
              const SizedBox(height: 32),
              // Step Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 0)
          GestureDetector(
            onTap: () => setState(() => _step--),
            child: const Row(
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: SchoolColors.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    color: SchoolColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(width: 48),
        Row(
          children: List.generate(3, (i) {
            final active = i <= _step;
            return Container(
              width: 24,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? SchoolColors.primary : SchoolColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        if (_step == 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Skip',
              style: TextStyle(color: SchoolColors.textSecondary),
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildWelcome();
      case 1:
        return _buildRoleSelection();
      case 2:
        return _buildJoinClass();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcome() {
    return Column(
      children: [
        const Expanded(child: Center(child: OnboardingIllustration())),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SchoolColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: SchoolColors.primary),
                SizedBox(width: 6),
                Text(
                  'One platform. Five worlds.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SchoolColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: 'Your classroom,\n',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
              children: [
                TextSpan(
                  text: 'connected.',
                  style: TextStyle(color: SchoolColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'School World brings together chat, homework, and announcements — so you never miss a thing your teachers post.',
          style: TextStyle(
            fontSize: 15,
            color: SchoolColors.textSecondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Get started'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    final roles = [
      {
        'id': 'student',
        'label': 'Student',
        'desc': 'Join classes, chat, submit homework',
        'color': SchoolColors.primary,
        'icon': Icons.school,
      },
      {
        'id': 'teacher',
        'label': 'Teacher',
        'desc': 'Manage classes, post and pin materials',
        'color': SchoolColors.green,
        'icon': Icons.groups,
      },
      {
        'id': 'parent',
        'label': 'Parent / Guardian',
        'desc': 'Follow your child\'s progress and grades',
        'color': SchoolColors.red,
        'icon': Icons.favorite,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who\'s joining today?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pick your role — we\'ll tailor the app to what you do most.',
          style: TextStyle(fontSize: 14, color: SchoolColors.textSecondary),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: ListView.separated(
            itemCount: roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = roles[index];
              final isSelected = _selectedRole == r['id'];
              final color = r['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = r['id'] as String),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : SchoolColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          r['icon'] as IconData,
                          color: color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['label'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              r['desc'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: SchoolColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? color : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? color : SchoolColors.border,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _onContinueRole,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue as ${_selectedRole[0].toUpperCase()}${_selectedRole.substring(1)}',
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinClass() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your classes',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your school invite code to preview and join your class.',
          style: TextStyle(fontSize: 14, color: SchoolColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.key_outlined, size: 20),
            hintText: 'Enter code...',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loading ? null : _previewClass,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Preview class'),
        ),
        if (_previewData != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SchoolColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SchoolColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: SchoolColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (_previewData!['className'] as String)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _previewData!['className'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _previewData!['teacherName'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SchoolColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: SchoolColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _previewData == null || _loading ? null : _onJoinClass,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Join class'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _onContinueRole() async {
    AppScope.of(context).appState.setOnboardingRole(_selectedRole);
    if (_selectedRole == 'teacher') {
      await _ensureProfile();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _ensureProfile() async {
    final repo = AppScope.of(context).repository;
    final user = repo.auth.currentUser;
    if (user == null) {
      _showMessage('Please sign in before onboarding.');
      return;
    }
    await repo.createProfile(
      role: _selectedRole,
      name: user.displayName ?? user.email?.split('@').first ?? 'User',
    );
  }

  Future<void> _previewClass() async {
    if (_codeController.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = await AppScope.of(
        context,
      ).repository.validateInviteCode(_codeController.text);
      setState(() => _previewData = data);
    } catch (_) {
      _showMessage('Invite code was not found.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onJoinClass() async {
    if (_previewData == null) return;
    setState(() => _loading = true);
    try {
      await _ensureProfile();
      if (!mounted) return;
      final scope = AppScope.of(context);
      final result = await scope.repository.joinClass(
        _previewData!['classId'].toString(),
      );
      if (mounted) {
        scope.appState.selectClass(result['classId'].toString());
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: CustomPaint(painter: _IllustrationPainter()),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background circles
    canvas.drawCircle(
      center,
      90,
      Paint()..color = SchoolColors.primary.withOpacity(0.06),
    );
    canvas.drawCircle(
      center,
      60,
      Paint()..color = SchoolColors.green.withOpacity(0.07),
    );

    // Phone body
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 42, 40, 84, 148),
      const Radius.circular(16),
    );
    canvas.drawRRect(phoneRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..color = SchoolColors.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Screen
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 38, 44, 76, 140),
      const Radius.circular(13),
    );
    canvas.drawRRect(screenRect, Paint()..color = const Color(0xFFF8FAFC));

    // Chat bubbles
    final bubblePaintBlue = Paint()..color = SchoolColors.primary;
    final bubblePaintGray = Paint()..color = const Color(0xFFE2E8F0);

    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width / 2 - 32, 60 + i * 40, 36 + i * 4, 16),
          const Radius.circular(8),
        ),
        bubblePaintBlue,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width / 2 - 20, 80 + i * 40, 48 - i * 4, 16),
          const Radius.circular(8),
        ),
        bubblePaintGray,
      );
    }

    // Avatars
    _drawAvatar(canvas, const Offset(40, 60), SchoolColors.yellow, 'A');
    _drawAvatar(canvas, const Offset(200, 80), SchoolColors.green, 'M');
    _drawAvatar(canvas, const Offset(30, 140), SchoolColors.red, 'P');
    _drawAvatar(canvas, const Offset(210, 160), SchoolColors.purple, 'L');

    // Dotted lines (simulated)
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      const Offset(54, 64),
      const Offset(80, 70),
      linePaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(186, 84),
      const Offset(160, 90),
      linePaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(44, 138),
      const Offset(80, 140),
      linePaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(196, 162),
      const Offset(160, 162),
      linePaint,
    );
  }

  void _drawAvatar(Canvas canvas, Offset pos, Color color, String initial) {
    canvas.drawCircle(pos, 14, Paint()..color = color);
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 2;
    const dashSpace = 3;
    final distance = (p2 - p1).distance;
    final direction = (p2 - p1) / distance;
    var currentDist = 0.0;
    while (currentDist < distance) {
      canvas.drawLine(
        p1 + direction * currentDist,
        p1 + direction * (currentDist + dashWidth),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
