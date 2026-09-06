import { VercelRequest, VercelResponse } from '@vercel/node';
import { firebaseAdmin } from '../../utils/firebase';
import { handleCors, verifyFirebaseToken, checkRateLimit } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  if (!checkRateLimit(req)) return res.status(429).json({ error: 'Too Many Requests' });
  if (!await verifyFirebaseToken(req)) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing Firebase ID token' });
  }

  try {
    const { tokens, userIds, title, body, data } = req.body;

    let targetTokens: string[] = [];
    const tokenDocMap = new Map<string, FirebaseFirestore.DocumentReference>();

    if (Array.isArray(tokens)) {
      targetTokens = [...tokens];
    }

    if (Array.isArray(userIds) && userIds.length > 0) {
      const db = firebaseAdmin.firestore();
      
      // Fetch tokens for each user. Note: In production, batching or limited concurrency is better.
      const fetchPromises = userIds.map(async (uid: string) => {
        try {
          const snapshot = await db.collection('users').doc(uid).collection('tokens').where('active', '==', true).get();
          snapshot.docs.forEach(doc => {
            const tok = doc.data().token;
            if (tok && typeof tok === 'string') {
              tokenDocMap.set(tok, doc.ref);
            }
          });
          return snapshot.docs.map(doc => doc.data().token as string).filter(t => !!t);
        } catch (err) {
          console.error(`Error fetching tokens for user ${uid}:`, err);
          return [];
        }
      });

      const userTokensArrays = await Promise.all(fetchPromises);
      for (const tArr of userTokensArrays) {
        targetTokens.push(...tArr);
      }
    }

    // Deduplicate tokens
    targetTokens = [...new Set(targetTokens)];

    if (targetTokens.length === 0) {
      return res.status(200).json({ success: true, message: 'No valid tokens found to send.' });
    }

    if (typeof title !== 'string' || title.trim().length === 0 || title.length > 120 ||
        typeof body !== 'string' || body.trim().length === 0 || body.length > 500) {
      return res.status(400).json({ error: 'Bad Request: Missing title or body' });
    }

    // Send notifications in batches of 500 (Firebase limit)
    const MAX_BATCH_SIZE = 500;
    let successCount = 0;
    let failureCount = 0;
    const failedTokens: string[] = [];

    for (let i = 0; i < targetTokens.length; i += MAX_BATCH_SIZE) {
      const batchTokens = targetTokens.slice(i, i + MAX_BATCH_SIZE);
      // FCM data values must be strings. Normalizing them here prevents a
      // malformed optional field from causing the entire chat notification to
      // be dropped by Firebase Admin.
      const notificationData: Record<string, string> = {};
      if (data && typeof data === 'object') {
        for (const [key, value] of Object.entries(data)) {
          if (value !== undefined && value !== null) {
            notificationData[key] = String(value);
          }
        }
      }

      // Determine deduplication tag / collapse key so the OS collapses duplicate notifications
      const collapseKey =
        notificationData.messageId ||
        notificationData.tag ||
        (notificationData.roomId ? `room_${notificationData.roomId}` : undefined);

      const message: any = {
        notification: {
          title,
          body,
        },
        data: notificationData,
        tokens: batchTokens,
        android: {
          priority: 'high',
          notification: {
            icon: 'ic_launcher',
            color: '#1E293B',
            sound: 'default',
            ...(collapseKey ? { tag: collapseKey } : {}),
          },
          ...(collapseKey ? { collapseKey } : {}),
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
          headers: {
            'apns-priority': '10',
            ...(collapseKey ? { 'apns-collapse-id': collapseKey } : {}),
          },
        },
        webpush: {
          notification: {
            title,
            body,
            icon: '/favicon.png',
            badge: '/favicon.png',
            ...(collapseKey ? { tag: collapseKey } : {}),
          },
          fcmOptions: {
            link: '/',
          },
        },
      };

      const response = await firebaseAdmin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;

      const tokensToDeactivate: FirebaseFirestore.DocumentReference[] = [];

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const failedToken = batchTokens[idx];
          failedTokens.push(failedToken);
          const errorCode = resp.error?.code;
          console.error('Failed to send to token:', failedToken, errorCode, resp.error?.message);

          if (
            errorCode === 'messaging/registration-token-not-registered' ||
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/unregistered'
          ) {
            const docRef = tokenDocMap.get(failedToken);
            if (docRef) {
              tokensToDeactivate.push(docRef);
            }
          }
        }
      });

      if (tokensToDeactivate.length > 0) {
        try {
          const db = firebaseAdmin.firestore();
          const batch = db.batch();
          tokensToDeactivate.slice(0, 500).forEach(ref => {
            batch.update(ref, {
              active: false,
              deactivatedAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
            });
          });
          await batch.commit();
          console.log(`Deactivated ${tokensToDeactivate.length} invalid tokens in Firestore`);
        } catch (cleanupErr) {
          console.error('Error deactivating invalid tokens in Firestore:', cleanupErr);
        }
      }
    }

    return res.status(200).json({
      success: true,
      successCount: successCount,
      failureCount: failureCount,
      failedTokens,
    });
  } catch (error: any) {
    console.error('Error sending push notification:', error);
    return res.status(500).json({ error: 'Internal Server Error', details: error.message || String(error) });
  }
}
