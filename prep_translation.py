import json

with open('extracted_strings.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

keys = list(data.keys())

# Create a clean dict with just Russian text as key, empty string for value
translation_dict = {k: "" for k in keys}

with open('translation_template.json', 'w', encoding='utf-8') as f:
    json.dump(translation_dict, f, ensure_ascii=False, indent=2)

print(f"Prepared {len(keys)} keys for translation in translation_template.json")
