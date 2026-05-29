import re
import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # fix const variables
    content = content.replace('const months = [', 'final months = [')
    content = content.replace('const tabs = [', 'final tabs = [')
    content = content.replace('const items = [', 'final items = [')
    content = content.replace('const pages = [', 'final pages = [')
    content = content.replace('const _tabs = [', 'final _tabs = [')
    content = content.replace('const _items = [', 'final _items = [')
    content = content.replace('const _pages = [', 'final _pages = [')
    
    # file_preview.dart: undefined context
    if 'file_preview.dart' in filepath:
        content = content.replace('AppLocalizations.of(context)!.file', '"Файл"')
        content = content.replace('AppLocalizations.of(context)!.unsupportedFileFormat', '"Неподдерживаемый формат файла"')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Applied final fixes.")
