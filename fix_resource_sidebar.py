import re
import os

p = 'lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart'
if os.path.exists(p):
    with open(p, 'r') as f: c = f.read()
    c = c.replace('AppLocalizations.of(context)!.helloImYourTeachingAssistant', "'Привет, я ваш учебный ассистент'")
    with open(p, 'w') as f: f.write(c)
