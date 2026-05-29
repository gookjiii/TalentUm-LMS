import urllib.request
import urllib.parse
import json
import time
import sys

def translate(text):
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=ru&tl=en&dt=t&q=" + urllib.parse.quote(text)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req)
        data = json.loads(response.read().decode('utf-8'))
        return "".join([part[0] for part in data[0]])
    except Exception as e:
        print(f"Error translating '{text}': {e}")
        return text

with open('translation_template.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

count = 0
for k in data:
    if not data[k]:
        data[k] = translate(k)
        count += 1
        if count % 50 == 0:
            print(f"Translated {count} strings...")
        time.sleep(0.05)

with open('translations.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Translation complete.")
