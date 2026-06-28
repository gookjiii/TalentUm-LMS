import { VercelRequest, VercelResponse } from '@vercel/node';
import { authAdmin, dbAdmin } from '../../utils/firebase';
import { handleCors, requireApiSecret } from '../../utils/api';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { userId } = req.body;
  if (!userId) {
    return res.status(400).json({ error: 'Missing userId' });
  }

  if (!requireApiSecret(req)) {
    return res.status(401).json({ error: 'Unauthorized' });
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
