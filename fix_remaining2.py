import os

def fix_student_homework():
    p = 'lib/src/features/homework/presentation/widgets/student_homework.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('String _getHumanFriendlyDate(DateTime date) {', 'String _getHumanFriendlyDate(BuildContext context, DateTime date) {')
    c = c.replace('_getHumanFriendlyDate(assignment.dueDate)', '_getHumanFriendlyDate(context, assignment.dueDate)')
    c = c.replace('_getHumanFriendlyDate(hw.dueDate)', '_getHumanFriendlyDate(context, hw.dueDate)') # just in case
    with open(p, 'w') as f: f.write(c)

def fix_teacher_homework():
    p = 'lib/src/features/homework/presentation/widgets/teacher_homework.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('const markFilters = [', 'final markFilters = [')
    c = c.replace('const _markFilters = [', 'final _markFilters = [')
    with open(p, 'w') as f: f.write(c)

def fix_journal_grades_grid():
    p = 'lib/src/features/journal/presentation/widgets/journal_grades_grid.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('Color _getMarkColor(String mark) {', 'Color _getMarkColor(BuildContext context, String mark) {')
    c = c.replace('_getMarkColor(grade)', '_getMarkColor(context, grade)')
    c = c.replace('_getMarkColor(studentGrade)', '_getMarkColor(context, studentGrade)')
    c = c.replace('_getMarkColor(mark)', '_getMarkColor(context, mark)')
    c = c.replace('_getMarkColor(grade.value)', '_getMarkColor(context, grade.value)')
    with open(p, 'w') as f: f.write(c)

def fix_journal_topics_list():
    p = 'lib/src/features/journal/presentation/widgets/journal_topics_list.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('String _formatDate(DateTime d) {', 'String _formatDate(BuildContext context, DateTime d) {')
    c = c.replace('_formatDate(topic.date)', '_formatDate(context, topic.date)')
    c = c.replace('_formatDate(topic[\'date\'])', '_formatDate(context, topic[\'date\'])')
    with open(p, 'w') as f: f.write(c)

def fix_student_today():
    p = 'lib/src/features/today/presentation/widgets/student_today.dart'
    if not os.path.exists(p): return
    with open(p, 'r') as f: c = f.read()
    c = c.replace('String get _greeting {', 'String _greeting(BuildContext context) {')
    c = c.replace('$_greeting, $name', '${_greeting(context)}, $name')
    with open(p, 'w') as f: f.write(c)

fix_student_homework()
fix_teacher_homework()
fix_journal_grades_grid()
fix_journal_topics_list()
fix_student_today()
print("Fixed remaining2")
