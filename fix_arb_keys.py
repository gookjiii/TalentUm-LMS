import json
import re
import os

def fix_key(key):
    if not key: return "unknown"
    if re.match(r'^[0-9_]', key):
        key = "n" + key
    # remove invalid chars (though we already did, but just in case)
    key = re.sub(r'[^a-zA-Z0-9]', '', key)
    return key

# Read ARB files
def fix_arb(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    new_data = {}
    key_mapping = {}
    for k, v in data.items():
        if k.startswith('@'):
            if k[1:] in key_mapping:
                new_data['@' + key_mapping[k[1:]]] = v
            else:
                new_data[k] = v
        else:
            new_k = fix_key(k)
            if new_k != k:
                key_mapping[k] = new_k
            new_data[new_k] = v
            
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, ensure_ascii=False, indent=2)
    return key_mapping

en_map = fix_arb('lib/l10n/app_en.arb')
ru_map = fix_arb('lib/l10n/app_ru.arb')

# Replace keys in codebase
def replace_in_code(mapping):
    if not mapping: return
    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                changed = False
                for old_k, new_k in mapping.items():
                    target = f"AppLocalizations.of(context)!.{old_k}"
                    replacement = f"AppLocalizations.of(context)!.{new_k}"
                    if target in content:
                        content = content.replace(target, replacement)
                        changed = True
                
                if changed:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)

replace_in_code(en_map)
print(f"Fixed keys: {en_map}")
