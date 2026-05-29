import re
import os

def fix_teacher_feed():
    p = 'lib/src/features/feed/presentation/widgets/teacher_feed.dart'
    if os.path.exists(p):
        c = open(p).read()
        # headerTitle is undefined
        c = c.replace(' headerTitle', ' AppLocalizations.of(context)!.feed')
        open(p, 'w').write(c)

def fix_inline_video():
    p = 'lib/src/features/chat/presentation/widgets/chat_bubble/inline_video_player.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('const ', '') # just wipe all consts to be safe
        open(p, 'w').write(c)

def fix_resource_sidebar():
    p = 'lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart'
    if os.path.exists(p):
        lines = open(p).readlines()
        idx = 1375 - 1
        if 0 <= idx < len(lines):
            lines[idx] = lines[idx].replace('const ', '')
        open(p, 'w').writelines(lines)

def fix_parent_home():
    p = 'lib/src/features/parent_dashboard/presentation/screens/parent_home_screen.dart'
    if os.path.exists(p):
        lines = open(p).readlines()
        idx1 = 32 - 1
        idx2 = 168 - 1
        if 0 <= idx1 < len(lines):
            lines[idx1] = lines[idx1].replace('const ', '')
        if 0 <= idx2 < len(lines):
            lines[idx2] = lines[idx2].replace('const ', '')
        open(p, 'w').writelines(lines)

fix_teacher_feed()
fix_inline_video()
fix_resource_sidebar()
fix_parent_home()
print("Fixed final 2")
