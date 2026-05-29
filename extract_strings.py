import os
import re
import json

def extract_strings(directories):
    strings_map = {}
    # Better regex: match a quote, then any chars EXCEPT quotes or newlines, containing Cyrillic, then the same quote
    pattern = re.compile(r'''(['"])([^'"\n]*?[\u0400-\u04FF]+[^'"\n]*?)\1''')
    
    for directory in directories:
        if not os.path.exists(directory): continue
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith('.dart'):
                    filepath = os.path.join(root, file)
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                        matches = pattern.findall(content)
                        for match in matches:
                            string_val = match[1]
                            # exclude strings with string interpolation for now, we'll fix them manually later
                            if '$' in string_val:
                                continue
                            
                            if string_val not in strings_map:
                                strings_map[string_val] = []
                            if filepath not in strings_map[string_val]:
                                strings_map[string_val].append(filepath)

    with open('extracted_strings.json', 'w', encoding='utf-8') as f:
        json.dump(strings_map, f, ensure_ascii=False, indent=2)
    
    print(f"Extracted {len(strings_map)} safe unique strings without interpolation.")

if __name__ == '__main__':
    extract_strings(['lib/src', 'lib/screens', 'lib/widgets'])
