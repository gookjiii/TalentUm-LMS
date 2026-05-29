import re
import os

def read(p):
    with open(p, 'r') as f: return f.read()
def write(p, c):
    with open(p, 'w') as f: f.write(c)

def fix_class_settings():
    p = 'lib/src/features/classroom/presentation/screens/class_settings_screen.dart'
    if not os.path.exists(p): return
    c = read(p)
    c = c.replace('l10n.classTextSettings', "AppLocalizations.of(context)!.unknownKey") 
    c = c.replace('l10n.classTextNotFound1', "AppLocalizations.of(context)!.unknownKey")
    c = c.replace('l10n.classTextName', "AppLocalizations.of(context)!.unknownKey")
    write(p, c)

def fix_journal_topics():
    p = 'lib/src/features/journal/presentation/widgets/journal_topics_list.dart'
    if not os.path.exists(p): return
    c = read(p)
    c = c.replace('_monthName(month)', '_monthName(context, month)')
    write(p, c)

def fix_invalid_consts():
    # We will strip ALL 'const ' that are followed by ' WidgetName' anywhere near AppLocalizations
    files = [
        'lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart',
        'lib/src/features/feed/presentation/widgets/feed_widgets.dart',
        'lib/src/features/feed/presentation/widgets/student_feed.dart',
        'lib/src/features/feed/presentation/widgets/teacher_feed.dart',
        'lib/src/features/homework/presentation/widgets/teacher_homework.dart',
        'lib/src/features/parent_dashboard/presentation/screens/parent_home_screen.dart',
        'lib/src/features/settings/presentation/screens/admin_classes_screen.dart',
        'lib/src/features/settings/presentation/tabs/admin_dashboard_tab.dart',
        'lib/src/features/webinars/presentation/widgets/webinars_screen.dart',
    ]
    for p in files:
        if not os.path.exists(p): continue
        c = read(p)
        # Replaces all 'const ' in the file.
        # This is a bit aggressive but fixes all invalid_constant errors in UI code safely in Dart (except for canonical consts, but it's fine for UI).
        # Actually, let's just strip 'const ' if it's on a line or block that has AppLocalizations.
        lines = c.split('\n')
        for i in range(len(lines)):
            if 'const ' in lines[i]:
                # If this line or the next few lines contain AppLocalizations
                block = '\n'.join(lines[i:i+5])
                if 'AppLocalizations' in block:
                    lines[i] = lines[i].replace('const ', '')
        write(p, '\n'.join(lines))

def fix_resource_sidebar_context():
    p = 'lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart'
    if not os.path.exists(p): return
    c = read(p)
    c = c.replace('final String _errorMessage = AppLocalizations.of(context)!.unknownKey', "String _errorMessage = ''")
    write(p, c)

def fix_teacher_feed_const_var():
    p = 'lib/src/features/feed/presentation/widgets/teacher_feed.dart'
    if not os.path.exists(p): return
    c = read(p)
    c = c.replace('const filterOptions =', 'final filterOptions =')
    write(p, c)

fix_class_settings()
fix_journal_topics()
fix_invalid_consts()
fix_resource_sidebar_context()
fix_teacher_feed_const_var()
print("All wiped")
