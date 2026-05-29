import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace `const Widget( ... AppLocalizations ... )`
    # We'll just remove all `const ` that appear before `AppLocalizations` within a few lines.
    # Actually, a simpler approach: find all `const ` keywords.
    # If the block it modifies contains AppLocalizations, remove the `const `.
    
    # Simple regex to remove const before [ if it contains AppLocalizations
    content = re.sub(r'const\s+(\[[^\]]*AppLocalizations)', r'\1', content)
    
    # Remove const before Widget if it contains AppLocalizations
    content = re.sub(r'const\s+([A-Za-z0-9_]+\s*\([^)]*AppLocalizations)', r'\1', content)
    
    # Also handle the undefined context in specific files manually:
    if 'homework_screen.dart' in filepath:
        content = content.replace('String _formatDate(DateTime d) {', 'String _formatDate(BuildContext context, DateTime d) {')
        content = content.replace('_formatDate(dueDate!)', '_formatDate(context, dueDate!)')
        content = content.replace('_formatDate(dueDate)', '_formatDate(context, dueDate)')
    if 'student_homework.dart' in filepath:
        content = content.replace('String _formatDate(DateTime d) {', 'String _formatDate(BuildContext context, DateTime d) {')
        content = content.replace('_formatDate(assignment.dueDate)', '_formatDate(context, assignment.dueDate)')
    if 'journal_grades_grid.dart' in filepath:
        content = content.replace("String _formatDate(DateTime d) {", "String _formatDate(BuildContext context, DateTime d) {")
        content = content.replace("_formatDate(task['dueDate']", "_formatDate(context, task['dueDate']")
    if 'journal_topics_list.dart' in filepath:
        content = content.replace("String _formatDate(DateTime d) {", "String _formatDate(BuildContext context, DateTime d) {")
        content = content.replace("_formatDate(topic['date']", "_formatDate(context, topic['date']")
    if 'student_today.dart' in filepath:
        content = content.replace('String _formatDate(DateTime d) {', 'String _formatDate(BuildContext context, DateTime d) {')
        content = content.replace('_formatDate(hw.dueDate)', '_formatDate(context, hw.dueDate)')
    if 'firebase_chat_controller.dart' in filepath:
        content = content.replace('AppLocalizations.of(context)!.deletedMessage', '"Сообщение удалено"')
        content = content.replace('AppLocalizations.of(context)!.homework', '"Домашнее задание"')
        content = content.replace('AppLocalizations.of(context)!.systemMessage', '"Системное сообщение"')
    if 'file_preview.dart' in filepath:
        content = content.replace('AppLocalizations.of(context)!.file', '"Файл"')
        content = content.replace('AppLocalizations.of(context)!.unsupportedFileFormat', '"Неподдерживаемый формат файла"')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Applied fixes.")
