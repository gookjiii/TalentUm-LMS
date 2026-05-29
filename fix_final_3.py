import re
import os

def fix_resource_sidebar():
    p = 'lib/src/features/chat/presentation/widgets/resource_sidebar/resource_sidebar.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('const PopupMenuItem(', 'PopupMenuItem(')
        open(p, 'w').write(c)

def fix_inline_video():
    p = 'lib/src/features/chat/presentation/widgets/chat_bubble/inline_video_player.dart'
    if os.path.exists(p):
        c = open(p).read()
        c = c.replace('const ', '')
        open(p, 'w').write(c)

fix_resource_sidebar()
fix_inline_video()
print("Fixed final 3")
