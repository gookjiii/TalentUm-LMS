import os

fixes = [
    ('lib/src/features/feed/presentation/widgets/teacher_feed.dart', 182),
    ('lib/src/features/homework/presentation/widgets/teacher_homework.dart', 1205),
    ('lib/src/features/parent_dashboard/presentation/screens/parent_home_screen.dart', 44),
    ('lib/src/features/settings/presentation/screens/admin_classes_screen.dart', 76),
    ('lib/src/features/settings/presentation/tabs/admin_dashboard_tab.dart', 242),
    ('lib/src/features/settings/presentation/tabs/admin_dashboard_tab.dart', 625),
    ('lib/src/features/webinars/presentation/widgets/webinars_screen.dart', 366),
]

for filepath, linenum in fixes:
    if not os.path.exists(filepath): continue
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    idx = linenum - 1
    if 0 <= idx < len(lines):
        lines[idx] = lines[idx].replace('const ', '', 1)
        
    with open(filepath, 'w') as f:
        f.writelines(lines)

def fix_student_hw():
    p = 'lib/src/features/homework/presentation/widgets/student_homework.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('_getHumanFriendlyDate(due)', '_getHumanFriendlyDate(context, due)')
    with open(p, 'w') as f: f.write(c)

def fix_journal_topics():
    p = 'lib/src/features/journal/presentation/widgets/journal_topics_list.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('String _monthName(int month) {', 'String _monthName(BuildContext context, int month) {')
    c = c.replace('_monthName(t.date.month)', '_monthName(context, t.date.month)')
    c = c.replace('_monthName(topic[\'date\'].month)', '_monthName(context, topic[\'date\'].month)')
    c = c.replace('_monthName(d.month)', '_monthName(context, d.month)')
    with open(p, 'w') as f: f.write(c)

fix_student_hw()
fix_journal_topics()
print("Fixed invalid consts and context issues.")
