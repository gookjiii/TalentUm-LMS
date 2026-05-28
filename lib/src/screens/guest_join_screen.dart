import 'package:flutter/material.dart';

import '../../main.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

class GuestJoinScreen extends StatefulWidget {
  const GuestJoinScreen({
    required this.classId,
    required this.inviteCode,
    super.key,
  });

  final String classId;
  final String inviteCode;

  @override
  State<GuestJoinScreen> createState() => _GuestJoinScreenState();
}

class _GuestJoinScreenState extends State<GuestJoinScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _lastError;
  String? _rawError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SchoolCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: SchoolLogo(size: 72)),
                  const SizedBox(height: 20),
                  const Text(
                    'Tham gia lớp học',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: SchoolColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập tên của bạn để tham gia nhóm chat ngay lập tức. Không cần tạo tài khoản.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SchoolColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 24),
                  if (_lastError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SchoolColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SchoolColors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _lastError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: SchoolColors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (_rawError != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Lỗi kỹ thuật'),
                                    content: SingleChildScrollView(
                                      child: Text(_rawError!),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('Đóng'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Xem chi tiết lỗi',
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                  color: SchoolColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    onSubmitted: (_) => _join(),
                    decoration: const InputDecoration(
                      labelText: 'Tên của bạn',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _loading ? null : _join,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    label: Text(_loading ? 'Đang tham gia...' : 'Vào lớp học'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      AppScope.of(context).appState.markJoined();
                    },
                    child: const Text('Đăng nhập bằng tài khoản chính'),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: SchoolColors.muted,
                      fontSize: 10,
                    ),
                    child: Column(
                      children: [
                        Text('Class ID: ${widget.classId}'),
                        const SizedBox(height: 2),
                        Text('Invite Code: ${widget.inviteCode}'),
                      ],
                    ),
                  ),
                  if (_lastError != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _lastError = null;
                          _rawError = null;
                        });
                      },
                      child: const Text('Thử lại'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _join() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _lastError = 'Vui lòng nhập tên của bạn.');
      return;
    }
    setState(() {
      _loading = true;
      _lastError = null;
      _rawError = null;
    });
    try {
      final scope = AppScope.of(context);
      final result = await scope.repository.joinClassAsGuest(
        classId: widget.classId,
        inviteCode: widget.inviteCode,
        displayName: name,
      );

      if (result['ok'] == true) {
        scope.appState.selectClass(widget.classId);
        scope.appState.markJoined();
        scope.appState.setRole('student');
      } else {
        setState(
          () => _lastError = 'Không thể tham gia: Máy chủ phản hồi lỗi.',
        );
      }
    } catch (error) {
      String message = error.toString();
      String userFriendly = 'Đã có lỗi xảy ra khi tham gia lớp học.';

      if (message.contains('permission-denied')) {
        userFriendly = 'Liên kết không hợp lệ hoặc mã mời đã hết hạn.';
      } else if (message.contains('not-found')) {
        userFriendly = 'Lớp học không tồn tại.';
      } else if (message.contains('network-request-failed')) {
        userFriendly = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại internet.';
      }

      if (mounted) {
        setState(() {
          _lastError = userFriendly;
          _rawError = message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
