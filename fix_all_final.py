import re
import os
import subprocess

# Fix firebase_chat_controller
c = open('lib/src/features/chat/data/firebase_chat_controller.dart').read()
c = c.replace('AppLocalizations.of(context)!.postDeleted', "'Пост удален'")
open('lib/src/features/chat/data/firebase_chat_controller.dart', 'w').write(c)

# Fix teacher_feed headerTitle
c = open('lib/src/features/feed/presentation/widgets/teacher_feed.dart').read()
c = c.replace('AppLocalizations.of(context)!.headerTitle', "AppLocalizations.of(context)!.feed")
open('lib/src/features/feed/presentation/widgets/teacher_feed.dart', 'w').write(c)

# Fix journal_topics_list
c = open('lib/src/features/journal/presentation/widgets/journal_topics_list.dart').read()
c = c.replace('_monthName(month)', '_monthName(context, month)')
open('lib/src/features/journal/presentation/widgets/journal_topics_list.dart', 'w').write(c)

# Run a smart regex over the files that have invalid_constant
files = [
    'lib/src/features/chat/presentation/screens/class_chat_screen.dart',
    'lib/src/features/chat/presentation/widgets/chat_bubble/inline_video_player.dart',
    'lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart',
    'lib/src/features/feed/presentation/widgets/student_feed.dart',
    'lib/src/features/feed/presentation/widgets/teacher_feed.dart',
    'lib/src/features/homework/presentation/widgets/teacher_homework.dart',
    'lib/src/features/parent_dashboard/presentation/screens/parent_home_screen.dart',
    'lib/src/features/settings/presentation/tabs/admin_dashboard_tab.dart',
    'lib/src/features/webinars/presentation/widgets/webinars_screen.dart',
]

for p in files:
    if not os.path.exists(p): continue
    c = open(p).read()
    
    # Very aggressive but effective:
    # Find all "const <WidgetName>(" and if AppLocalizations occurs before the next ";", remove the "const "
    # Actually, let's just find every "const " and remove it if it's near AppLocalizations
    
    lines = c.split('\n')
    for i in range(len(lines)):
        if 'const ' in lines[i]:
            # Look ahead up to 10 lines
            block = '\n'.join(lines[i:i+10])
            if 'AppLocalizations' in block:
                lines[i] = lines[i].replace('const ', '', 1)
                
    open(p, 'w').write('\n'.join(lines))

print("Fixed everything")
