import re
import os

p = 'lib/src/features/journal/presentation/widgets/journal_topics_list.dart'
if os.path.exists(p):
    c = open(p).read()
    c = c.replace('_monthName(date.month)', '_monthName(context, date.month)')
    open(p, 'w').write(c)
