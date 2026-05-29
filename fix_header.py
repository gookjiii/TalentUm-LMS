import re
import os

p = 'lib/src/features/feed/presentation/widgets/teacher_feed.dart'
if os.path.exists(p):
    c = open(p).read()
    c = c.replace('AppLocalizations.of(context)!.feed = Column(', 'final headerTitle = Column(')
    c = c.replace('AppLocalizations.of(context)!.feed,', 'headerTitle,')
    c = c.replace('Expanded(child: AppLocalizations.of(context)!.feed)', 'Expanded(child: headerTitle)')
    open(p, 'w').write(c)

print("Fixed headerTitle")
