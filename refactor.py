import os
import re

def replace_in_file(filepath, replacements):
    with open(filepath, 'r') as f:
        content = f.read()
    
    needs_import = False
    for old_str, new_str in replacements:
        if old_str in content:
            content = content.replace(old_str, new_str)
            needs_import = True
            
    if needs_import and "import 'package:school_world/src/theme.dart';" not in content:
        idx = content.find("import ")
        if idx != -1:
            content = content[:idx] + "import 'package:school_world/src/theme.dart';\n" + content[idx:]
            
    with open(filepath, 'w') as f:
        f.write(content)

base_path = "/Users/mac/Documents/Freelancer/School World/school_world/lib/src/screens"
replace_in_file(f"{base_path}/onboarding_screen.dart", [
    ("padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24)", "padding: AppLayout.pagePadding(context).copyWith(top: 24, bottom: 24)"),
    ("textAlign: TextAlign.start,", "textAlign: TextAlign.justify,"),
    ("Text(l10n.roleTeacherDesc,", "Text(l10n.roleTeacherDesc, textAlign: TextAlign.justify,"),
    ("Text(l10n.roleStudentDesc,", "Text(l10n.roleStudentDesc, textAlign: TextAlign.justify,"),
    ("Text(l10n.joinFirstClassDesc,", "Text(l10n.joinFirstClassDesc, textAlign: TextAlign.justify,")
])

replace_in_file(f"{base_path}/auth_screen.dart", [
    ("padding: const EdgeInsets.all(28)", "padding: AppLayout.pagePadding(context).copyWith(top: 28, bottom: 28)"),
    ("padding: const EdgeInsets.all(48)", "padding: AppLayout.pagePadding(context).copyWith(top: 48, bottom: 48)"),
    ("padding: const EdgeInsets.all(56)", "padding: AppLayout.pagePadding(context).copyWith(top: 56, bottom: 56)"),
    ("textAlign: TextAlign.start,", "textAlign: TextAlign.justify,")
])

# Also update school_widgets.dart
widgets_path = "/Users/mac/Documents/Freelancer/School World/school_world/lib/src/widgets/school_widgets.dart"
with open(widgets_path, 'r') as f:
    widgets_code = f.read()

# Replace EdgeInsets.all(16) and 24 with AppSpacing constants
widgets_code = widgets_code.replace("const EdgeInsets.all(16)", "const EdgeInsets.all(AppSpacing.md)")
widgets_code = widgets_code.replace("const EdgeInsets.all(24)", "const EdgeInsets.all(AppSpacing.lg)")
widgets_code = widgets_code.replace("const EdgeInsets.symmetric(horizontal: 16)", "const EdgeInsets.symmetric(horizontal: AppSpacing.md)")

with open(widgets_path, 'w') as f:
    f.write(widgets_code)

print("Done")
