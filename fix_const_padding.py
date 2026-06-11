import os
import re

base_paths = [
    "/Users/mac/Documents/Freelancer/School World/school_world/lib/src/screens",
    "/Users/mac/Documents/Freelancer/School World/school_world/lib/src/features"
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
            
            # Replace 'const Padding(\n  padding: context.screenPadding' with 'Padding(\n  padding: context.screenPadding'
            content = re.sub(r'const\s+Padding\s*\(\s*padding:\s*context\.(screenPadding|horizontalPadding)', r'Padding(padding: context.\1', content)
            
            # Replace 'const Padding(padding: context.screenPadding'
            content = re.sub(r'const\s+Padding\(\s*padding:\s*context\.(screenPadding|horizontalPadding)', r'Padding(padding: context.\1', content)
            
            # Replace 'const EdgeInsets.symmetric(horizontal: context.horizontalPadding)' -> 'EdgeInsets.symmetric(horizontal: context.horizontalPadding)'
            content = content.replace("const EdgeInsets.symmetric(horizontal: context.horizontalPadding)", "EdgeInsets.symmetric(horizontal: context.horizontalPadding)")
            
            if content != original:
                with open(filepath, 'w') as f:
                    f.write(content)
                print(f"Fixed const in {filepath}")

print("Done")
