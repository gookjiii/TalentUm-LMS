import json
import os
import re

with open('translations.json', 'r', encoding='utf-8') as f:
    translations = json.load(f)

with open('extracted_strings.json', 'r', encoding='utf-8') as f:
    locations = json.load(f)

def make_key(text):
    clean = re.sub(r'[^a-zA-Z0-9\s]', '', text).strip()
    words = clean.split()
    if not words:
        return "unknownKey"
    key = words[0].lower() + "".join(w.capitalize() for w in words[1:5])
    if re.match(r'^[0-9_]', key):
        key = "n" + key
    return key

keys_map = {}
used_keys = set()

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_arb = json.load(f)
with open('lib/l10n/app_ru.arb', 'r', encoding='utf-8') as f:
    ru_arb = json.load(f)

for existing_k in en_arb.keys():
    used_keys.add(existing_k)

for ru_text, files in locations.items():
    en_text = translations.get(ru_text, ru_text)
    base_key = make_key(en_text)
    key = base_key
    counter = 1
    while key in used_keys:
        if en_arb.get(key) == en_text: # same translation, reuse key
            break
        key = f"{base_key}{counter}"
        counter += 1
    
    used_keys.add(key)
    keys_map[ru_text] = key
    
    en_arb[key] = en_text
    ru_arb[key] = ru_text

with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
    json.dump(en_arb, f, ensure_ascii=False, indent=2)
with open('lib/l10n/app_ru.arb', 'w', encoding='utf-8') as f:
    json.dump(ru_arb, f, ensure_ascii=False, indent=2)

for ru_text, files in locations.items():
    key = keys_map[ru_text]
    replacement = f"AppLocalizations.of(context)!.{key}"
    
    for filepath in files:
        if not os.path.exists(filepath): continue
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        content = content.replace(f"'{ru_text}'", replacement)
        content = content.replace(f'"{ru_text}"', replacement)
        
        if "package:school_world/l10n/app_localizations.dart" not in content and replacement in content:
            import_statement = "import 'package:school_world/l10n/app_localizations.dart';\n"
            first_import = content.find("import ")
            if first_import != -1:
                content = content[:first_import] + import_statement + content[first_import:]
            else:
                content = import_statement + content

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

print("Applied clean translations.")
