import { VercelRequest, VercelResponse } from '@vercel/node';
import { authAdmin, dbAdmin } from '../../utils/firebase';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { userId } = req.body;
  const authHeader = req.headers.authorization;

  if (!userId) {
    return res.status(400).json({ error: 'Missing userId' });
  }

  // Basic API Secret check to prevent unauthorized public deletion
  const serverSecret = process.env.APP_API_SECRET;
  if (serverSecret && authHeader !== `Bearer ${serverSecret}`) {
    return res.status(401).json({ error: 'Unauthorized: Invalid API Secret' });
  }

  try {
    // 1. Delete user from Firebase Auth
    try {
      await authAdmin.deleteUser(userId);
      console.log(`Successfully deleted user ${userId} from Firebase Auth`);
    } catch (authError: any) {
      // If the user does not exist in Auth, we can still proceed to delete the Firestore document
      if (authError.code === 'auth/user-not-found') {
        console.warn(`User ${userId} not found in Firebase Auth, but will delete Firestore doc`);
      } else {
        throw authError;
      }
    }

    // 2. Delete user document from Firestore (users/{userId})
    await dbAdmin.collection('users').doc(userId).delete();
    console.log(`Successfully deleted user document users/${userId} from Firestore`);

    return res.status(200).json({ success: true });
  } catch (error: any) {
    console.error(`Error deleting user ${userId}:`, error);
    return res.status(500).json({ error: 'Failed to delete user', details: error.message });
  }
}
