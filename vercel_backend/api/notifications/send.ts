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

    if (Array.isArray(tokens)) {
      targetTokens = [...tokens];
    }

    if (Array.isArray(userIds) && userIds.length > 0) {
      const db = firebaseAdmin.firestore();
      
      // Fetch tokens for each user. Note: In production, batching or limited concurrency is better.
      const fetchPromises = userIds.map(async (uid: string) => {
        try {
          const snapshot = await db.collection('users').doc(uid).collection('tokens').where('active', '==', true).get();
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

      const message = {
        notification: {
          title,
          body,
        },
        data: notificationData,
        tokens: batchTokens,
      };

      const response = await firebaseAdmin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(batchTokens[idx]);
          console.error('Failed to send to token:', batchTokens[idx], resp.error);
        }
      });
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
