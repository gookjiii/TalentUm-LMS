import { VercelRequest, VercelResponse } from '@vercel/node';
import { firebaseAdmin } from '../../utils/firebase';
import { handleCors, verifyFirebaseToken, checkRateLimit } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  if (!checkRateLimit(req, 20, 60000)) { // 20 requests per minute per IP
    return res.status(429).json({ error: 'Too Many Requests' });
  }

  const authUser = await verifyFirebaseToken(req);
  if (!authUser) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing Firebase ID token' });
  }

  try {
    const { tokens, userIds, title, body, data } = req.body;

    if (typeof title !== 'string' || title.trim().length === 0 || title.length > 120) {
      return res.status(400).json({ error: 'Bad Request: title must be a non-empty string up to 120 characters' });
    }

    if (typeof body !== 'string' || body.trim().length === 0 || body.length > 500) {
      return res.status(400).json({ error: 'Bad Request: body must be a non-empty string up to 500 characters' });
    }

    if (tokens !== undefined && !Array.isArray(tokens)) {
      return res.status(400).json({ error: 'Bad Request: tokens must be an array' });
    }

    if (userIds !== undefined && !Array.isArray(userIds)) {
      return res.status(400).json({ error: 'Bad Request: userIds must be an array' });
    }

    if ((Array.isArray(tokens) && tokens.length > 1000) || (Array.isArray(userIds) && userIds.length > 1000)) {
      return res.status(400).json({ error: 'Bad Request: Payload exceeds maximum allowed tokens/userIds (1000)' });
    }

    if (data !== undefined && (typeof data !== 'object' || data === null || Array.isArray(data))) {
      return res.status(400).json({ error: 'Bad Request: data must be an object' });
    }

    let targetTokens: string[] = [];

    if (Array.isArray(tokens)) {
      targetTokens = tokens.filter((token): token is string => typeof token === 'string' && token.trim().length > 0);
    }

    if (Array.isArray(userIds) && userIds.length > 0) {
      const db = firebaseAdmin.firestore();

      // Fetch tokens for each user. Note: In production, batching or limited concurrency is better.
      const fetchPromises = userIds
        .filter((uid): uid is string => typeof uid === 'string' && uid.trim().length > 0)
        .map(async (uid: string) => {
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

    // Send notifications in batches of 500 (Firebase limit)
    const MAX_BATCH_SIZE = 500;
    let successCount = 0;
    let failureCount = 0;
    const failedTokens: string[] = [];

    for (let i = 0; i < targetTokens.length; i += MAX_BATCH_SIZE) {
      const batchTokens = targetTokens.slice(i, i + MAX_BATCH_SIZE);
      const message = {
        notification: {
          title,
          body,
        },
        data: sanitizeNotificationData(data),
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

function sanitizeNotificationData(data: unknown): Record<string, string> {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(data)
      .filter(([key, value]) => key.length <= 128 && typeof value === 'string' && value.length <= 1024)
      .slice(0, 20)
  );
}
