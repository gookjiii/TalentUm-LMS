import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';

import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';
import '../widgets/file_preview.dart';

class HomeworkDetailScreen extends StatefulWidget {
  const HomeworkDetailScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.assignmentId,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;
  final String assignmentId;

  @override
  State<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends State<HomeworkDetailScreen> {
  final TextEditingController _contentController = TextEditingController();
  List<PlatformFile> _files = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() => _files = [..._files, ...result.files]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MediaQuery.sizeOf(context).width < 720
          ? null
          : AppBar(title: Text(l10n.assignment)),
      body: CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        streamFactory: () => widget.repository.firestore
            .collection('assignments')
            .doc(widget.assignmentId)
            .snapshots(),
        keys: [widget.assignmentId],
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data();
          if (data == null) {
            return Center(child: Text(l10n.assignmentNotFound));
          }

          return CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            streamFactory: () => widget.repository.firestore
                .collection('submissions')
                .where('assignmentId', isEqualTo: widget.assignmentId)
                .where('studentId', isEqualTo: widget.repository.uid)
                .limit(1)
                .snapshots(),
            keys: [widget.assignmentId, widget.repository.uid],
            builder: (context, submissionSnapshot) {
              final submission =
                  submissionSnapshot.data?.docs.isNotEmpty == true
                  ? submissionSnapshot.data!.docs.first.data()
                  : null;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AssignmentSummary(data: data),
                        const SizedBox(height: 18),
                        if (widget.appState.role == 'student')
                          submission == null
                              ? _SubmissionForm(
                                  contentController: _contentController,
                                  files: _files,
                                  isUploading: _isUploading,
                                  onPickFiles: _pickFiles,
                                  onRemoveFile: (file) => setState(
                                    () => _files = _files
                                        .where((f) => f != file)
                                        .toList(),
                                  ),
                                  onSubmit: _submit,
                                )
                              : _SubmittedCard(data: submission),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isUploading = true);
    try {
      final submissionId = await widget.repository.createSubmission(
        assignmentId: widget.assignmentId,
        studentId: widget.repository.uid ?? '',
        content: _contentController.text,
      );

      final List<Map<String, dynamic>> attachments = [];
      for (final file in _files) {
        final path =
            'submissions/$submissionId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        Map<String, dynamic>? result;
        if (file.bytes != null) {
          result = await widget.repository.uploadFileWeb(path, file.bytes!);
        } else if (file.path != null) {
          result = await widget.repository.uploadFile(path, File(file.path!));
        }
        if (result != null) {
          attachments.add({
            'type': 'file',
            ...result,
            'name': file.name,
            'size': file.size,
          });
        }
      }

      if (attachments.isNotEmpty) {
        await widget.repository.updateSubmissionAttachments(
          submissionId: submissionId,
          attachments: attachments,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.submissionFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _AssignmentSummary extends StatelessWidget {
  const _AssignmentSummary({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final due = data['dueDate'] as Timestamp?;
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );
    return SchoolCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (due != null)
                StatusChip(
                  label: l10n.due(
                    DateFormat('d MMM, HH:mm', 'ru').format(due.toDate()),
                  ),
                  color: due.toDate().isBefore(DateTime.now())
                      ? SchoolColors.red
                      : SchoolColors.primary,
                  icon: Icons.schedule_rounded,
                ),
              if (attachments.isNotEmpty)
                StatusChip(
                  label: 'Вложений: ${attachments.length}',
                  color: SchoolColors.purple,
                  icon: Icons.attach_file,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data['title']?.toString() ?? l10n.assignment,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            data['description']?.toString() ?? '',
            style: const TextStyle(
              color: SchoolColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              l10n.teacherAttachments,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...attachments.map((file) => FilePreviewWidget(remoteFile: file)),
          ],
        ],
      ),
    );
  }
}

class _SubmissionForm extends StatelessWidget {
  const _SubmissionForm({
    required this.contentController,
    required this.files,
    required this.isUploading,
    required this.onPickFiles,
    required this.onRemoveFile,
    required this.onSubmit,
  });

  final TextEditingController contentController;
  final List<PlatformFile> files;
  final bool isUploading;
  final VoidCallback onPickFiles;
  final ValueChanged<PlatformFile> onRemoveFile;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SchoolCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваша работа',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Заметки к работе',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          ...files.map(
            (file) => FilePreviewWidget(
              localFile: file,
              onRemove: isUploading ? null : () => onRemoveFile(file),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: isUploading ? null : onPickFiles,
                icon: const Icon(Icons.add_link),
                label: const Text('Добавить файлы'),
              ),
              FilledButton.icon(
                onPressed: isUploading ? null : onSubmit,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(isUploading ? l10n.submitting : l10n.submit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmittedCard extends StatelessWidget {
  const _SubmittedCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grade = data['grade'];
    final feedback = data['feedback']?.toString() ?? '';
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );
    return SchoolCard(
      padding: const EdgeInsets.all(22),
      color: SchoolColors.greenContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: grade == null ? l10n.submitted : 'Оценено: $grade%',
            color: grade == null ? SchoolColors.primary : SchoolColors.green,
            icon: grade == null
                ? Icons.check_circle_outline
                : Icons.grade_rounded,
          ),
          const SizedBox(height: 12),
          if ((data['content']?.toString() ?? '').isNotEmpty)
            Text(
              data['content'].toString(),
              style: const TextStyle(height: 1.45),
            ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...attachments.map((file) => FilePreviewWidget(remoteFile: file)),
          ],
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Отзыв учителя',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(feedback),
          ],
        ],
      ),
    );
  }
}
