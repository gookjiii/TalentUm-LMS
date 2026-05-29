import os

filepath = 'lib/src/features/today/presentation/widgets/student_today.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace('String _greeting() {', 'String _greeting(BuildContext context) {')
content = content.replace('_greeting()', '_greeting(context)')

content = content.replace('String _getDisplayName(User? user) {', 'String _getDisplayName(BuildContext context, User? user) {')
content = content.replace('_getDisplayName(user)', '_getDisplayName(context, user)')
content = content.replace('_getDisplayName(null)', '_getDisplayName(context, null)')

with open(filepath, 'w') as f:
    f.write(content)

print("Fixed student_today.dart")
