import re
import os

def fix_class_settings():
    p = 'lib/src/features/classroom/presentation/screens/class_settings_screen.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('AppLocalizations.of(context)!.classTextSettings', "AppLocalizations.of(context)!.unknownKey") 
    c = c.replace('AppLocalizations.of(context)!.classTextNotFound1', "AppLocalizations.of(context)!.unknownKey")
    c = c.replace('AppLocalizations.of(context)!.classTextName', "AppLocalizations.of(context)!.unknownKey")
    with open(p, 'w') as f: f.write(c)
    
fix_class_settings()
