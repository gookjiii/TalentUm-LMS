import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace('classTextManagement', 'classManagement')
    content = content.replace('classTextDeletedSuccessfully', 'classDeletedSuccessfully')
    
    if 'student_profile.dart' in filepath:
        # implicit_this_reference_in_initializer
        # it might be final l10n = AppLocalizations.of(context)!; at class level
        # Need to move it inside build method or use a getter
        content = content.replace('final l10n = AppLocalizations.of(context)!;', '')
        content = content.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;')

    if 'parent_home_screen.dart' in filepath:
        content = content.replace('const navDest = [', 'final navDest = [')
        content = content.replace('const destinations = [', 'final destinations = [')
        content = content.replace('const _destinations = [', 'final _destinations = [')
        content = content.replace('const parentNav = [', 'final parentNav = [')

    if 'admin_classes_screen.dart' in filepath:
        content = content.replace('const statuses = [', 'final statuses = [')

    if 'admin_dashboard_tab.dart' in filepath:
        content = content.replace('const metrics = [', 'final metrics = [')
        content = content.replace('const _metrics = [', 'final _metrics = [')

    if 'webinars_screen.dart' in filepath:
        content = content.replace('const categories = [', 'final categories = [')
        content = content.replace('const _categories = [', 'final _categories = [')

    if 'teacher_schedule_screen.dart' in filepath:
        content = content.replace('const days = [', 'final days = [')
        content = content.replace('const _days = [', 'final _days = [')

    if 'student_today.dart' in filepath:
        content = content.replace('AppLocalizations.of(context)!.classText', '"Класс"') # or whatever it was

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Applied remaining fixes.")
