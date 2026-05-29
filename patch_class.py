import json
import os

# fix ARB
for path in ['lib/l10n/app_en.arb', 'lib/l10n/app_ru.arb']:
    with open(path, 'r', encoding='utf-8') as f:
        arb = json.load(f)
    if 'class' in arb:
        arb['classText'] = arb['class']
        del arb['class']
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(arb, f, ensure_ascii=False, indent=2)

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # fix auth_screen const features
    content = content.replace('const features = [', 'final features = [')
    
    # fix class keyword
    content = content.replace('AppLocalizations.of(context)!.class', 'AppLocalizations.of(context)!.classText')
    
    # fix expected ] errors
    content = content.replace('AppLocalizations.of(context)!.classTextText', 'AppLocalizations.of(context)!.classText') # in case of double replacement
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Patched class keyword and features list.")
