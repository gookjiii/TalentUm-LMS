import re
import os

# 1. Chat screen getter
def fix_chat_screen():
    p = 'lib/features/chat/presentation/screens/chat_screen.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('classTextChat', 'unknownKey')
        open(p, 'w').write(c)

# 2. Firebase chat controller context
def fix_firebase_chat():
    p = 'lib/src/features/chat/data/firebase_chat_controller.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('AppLocalizations.of(context)!.unknownKey', "''")
        c = c.replace('AppLocalizations.of(context)!.photo', "'Фото'")
        c = c.replace('AppLocalizations.of(context)!.video', "'Видео'")
        c = c.replace('AppLocalizations.of(context)!.voiceMessage', "'Голосовое сообщение'")
        c = c.replace('AppLocalizations.of(context)!.document', "'Документ'")
        c = c.replace('AppLocalizations.of(context)!.location', "'Геолокация'")
        c = c.replace('AppLocalizations.of(context)!.link', "'Ссылка'")
        open(p, 'w').write(c)

# 3. Class chat screen getter
def fix_class_chat_screen():
    p = 'lib/src/features/chat/presentation/screens/class_chat_screen.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('classTextNotFound1', 'unknownKey')
        open(p, 'w').write(c)

# 4. teacher_feed headerTitle
def fix_teacher_feed():
    p = 'lib/src/features/feed/presentation/widgets/teacher_feed.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('AppLocalizations.of(context)!.headerTitle', "AppLocalizations.of(context)!.feed")
        open(p, 'w').write(c)

# 5. journal_topics_list
def fix_journal_topics():
    p = 'lib/src/features/journal/presentation/widgets/journal_topics_list.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('_monthName(month.key)', '_monthName(context, month.key)')
        c = c.replace('_monthName(month)', '_monthName(context, month)')
        open(p, 'w').write(c)

# Fix invalid constants from analyze output
def fix_invalid_constants():
    errors = [
        ('lib/src/features/chat/presentation/screens/class_chat_screen.dart', 1195),
        ('lib/src/features/chat/presentation/widgets/chat_bubble/inline_video_player.dart', 106),
        ('lib/src/features/chat/presentation/widgets/chat_bubble/inline_video_player.dart', 205),
        ('lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart', 1375),
        ('lib/src/features/feed/presentation/widgets/student_feed.dart', 185),
        ('lib/src/features/feed/presentation/widgets/teacher_feed.dart', 124),
        ('lib/src/features/feed/presentation/widgets/teacher_feed.dart', 182),
        ('lib/src/features/homework/presentation/widgets/teacher_homework.dart', 1205),
        ('lib/src/features/parent_dashboard/presentation/screens/parent_home_screen.dart', 44),
        ('lib/src/features/settings/presentation/tabs/admin_dashboard_tab.dart', 625),
        ('lib/src/features/webinars/presentation/widgets/webinars_screen.dart', 366),
    ]
    for p, line in errors:
        if not os.path.exists(p): continue
        with open(p, 'r') as f: lines = f.readlines()
        idx = line - 1
        if 0 <= idx < len(lines):
            lines[idx] = lines[idx].replace('const ', '')
            lines[idx] = lines[idx].replace('const\n', '\n')
            lines[idx] = lines[idx].replace('const\r', '\r')
        with open(p, 'w') as f: f.writelines(lines)

fix_chat_screen()
fix_firebase_chat()
fix_class_chat_screen()
fix_teacher_feed()
fix_journal_topics()
fix_invalid_constants()

print("All fixes applied!")
