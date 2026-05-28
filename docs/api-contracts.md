# API Contracts

## Chat

`ChatRepository.watchClassMessages(classId, limit: 30)` streams class messages ordered by `createdAt`.

`ChatRepository.sendTextMessage(classId, senderId, content)` validates message text before writing to Firestore.
