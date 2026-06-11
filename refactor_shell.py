import os

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
replace_in_file(f"{base_path}/student_shell.dart", [
    ("margin: const EdgeInsets.fromLTRB(16, 0, 16, 24)", "margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg)"),
    ("margin: const EdgeInsets.fromLTRB(16, 0, 16, 12)", "margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md)")
])

replace_in_file(f"{base_path}/teacher_workspace_screen.dart", [
    ("margin: const EdgeInsets.fromLTRB(16, 0, 16, 12)", "margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md)")
])

print("Done")
