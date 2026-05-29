import os

def fix_student_profile():
    p = 'lib/src/features/profile/presentation/widgets/student_profile.dart'
    with open(p, 'r') as f: content = f.read()
    
    content = content.replace("String _classesLabel = AppLocalizations.of(context)!.noClass;", "String _classesLabel = '';")
    content = content.replace("Future<void> _editName(BuildContext context, String current) async {", "Future<void> _editName(BuildContext context, String current) async {\n    final l10n = AppLocalizations.of(context)!;")
    content = content.replace("Future<void> _confirmSignOut(BuildContext context) async {", "Future<void> _confirmSignOut(BuildContext context) async {\n    final l10n = AppLocalizations.of(context)!;")
    with open(p, 'w') as f: f.write(content)

def fix_auth_screen():
    p = 'lib/src/screens/auth_screen.dart'
    with open(p, 'r') as f: content = f.read()
    content = content.replace('const features = [', 'final features = [') # Just in case it was missed
    with open(p, 'w') as f: f.write(content)

fix_student_profile()
fix_auth_screen()
print("Fixed final lap.")
