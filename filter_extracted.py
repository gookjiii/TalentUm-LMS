import json

with open('translations.json', 'r', encoding='utf-8') as f:
    clean_translations = json.load(f)

with open('extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

clean_extracted = {k: v for k, v in extracted.items() if k in clean_translations}

with open('extracted_strings.json', 'w', encoding='utf-8') as f:
    json.dump(clean_extracted, f, ensure_ascii=False, indent=2)

print(f"Clean extracted strings: {len(clean_extracted)}")
