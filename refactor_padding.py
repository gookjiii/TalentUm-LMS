import os

base_paths = [
    "/Users/mac/Documents/Freelancer/School World/school_world/lib/src/screens",
    "/Users/mac/Documents/Freelancer/School World/school_world/lib/src/features"
]

replacements = [
    ("padding: const EdgeInsets.all(16.0)", "padding: context.screenPadding"),
    ("padding: const EdgeInsets.all(16)", "padding: context.screenPadding"),
    ("padding: const EdgeInsets.all(24)", "padding: context.screenPadding"),
    ("EdgeInsets.symmetric(horizontal: 16)", "EdgeInsets.symmetric(horizontal: context.horizontalPadding)"),
    ("EdgeInsets.symmetric(horizontal: 16.0)", "EdgeInsets.symmetric(horizontal: context.horizontalPadding)"),
    ("EdgeInsets.symmetric(horizontal: 24)", "EdgeInsets.symmetric(horizontal: context.horizontalPadding)"),
    ("padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)", "padding: context.screenPadding"),
]

for base_path in base_paths:
    for root, _, files in os.walk(base_path):
        for file in files:
            if not file.endswith('.dart'):
                continue
                
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
                
            original = content
            needs_import = False
            
            for old_str, new_str in replacements:
                if old_str in content:
                    content = content.replace(old_str, new_str)
                    needs_import = True
            
            if needs_import and "import '../utils/responsive_utils.dart';" not in content and "import '../../utils/responsive_utils.dart';" not in content and "import 'package:school_world/src/utils/responsive_utils.dart';" not in content:
                idx = content.find("import ")
                if idx != -1:
                    content = content[:idx] + "import 'package:school_world/src/utils/responsive_utils.dart';\n" + content[idx:]
                    
            if content != original:
                with open(filepath, 'w') as f:
                    f.write(content)
                print(f"Updated {filepath}")

print("Done")
