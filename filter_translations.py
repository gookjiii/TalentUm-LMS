import json

with open('translations.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# separate out strings with $
clean_data = {}
interpolated_data = {}

for k, v in data.items():
    if '$' in k:
        interpolated_data[k] = v
    else:
        clean_data[k] = v

with open('translations.json', 'w', encoding='utf-8') as f:
    json.dump(clean_data, f, ensure_ascii=False, indent=2)

with open('interpolated_strings.json', 'w', encoding='utf-8') as f:
    json.dump(interpolated_data, f, ensure_ascii=False, indent=2)

print(f"Clean strings: {len(clean_data)}, Interpolated strings: {len(interpolated_data)}")
