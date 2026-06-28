import { google } from 'googleapis';
import { JWT } from 'google-auth-library';

const serviceAccountJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
const clientId = process.env.GOOGLE_CLIENT_ID;
const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
const refreshToken = process.env.GOOGLE_REFRESH_TOKEN;

let serviceAuthClient: any = null;
let oauthAuthClient: any = null;

try {
  if (serviceAccountJson) {
    const credentials = JSON.parse(serviceAccountJson);
    if (credentials.private_key) {
      credentials.private_key = credentials.private_key.replace(/\\n/g, '\n');
    }
    serviceAuthClient = new JWT({
      email: credentials.client_email,
      key: credentials.private_key,
      scopes: ['https://www.googleapis.com/auth/drive'],
    });
  }
} catch (e) {
  console.error('Failed to initialize Service Account:', e);
}

try {
  if (clientId && clientSecret && refreshToken) {
    const oauth2Client = new google.auth.OAuth2(clientId, clientSecret);
    oauth2Client.setCredentials({ refresh_token: refreshToken });
    oauthAuthClient = oauth2Client;
  }
} catch (e) {
  console.error('Failed to initialize OAuth:', e);
}

// Export a function to get working auth client by trying both
export const getWorkingAuthClient = async () => {
  // We prefer OAuth because it has 15GB storage quota on My Drive.
  if (oauthAuthClient) {
    try {
      const token = await oauthAuthClient.getAccessToken();
      if (token && token.token) return oauthAuthClient;
    } catch (e: any) {
      console.warn('OAuth failed (likely invalid_grant), falling back to Service Account:', e.message);
    }
  }

  // Fallback to Service Account
  if (serviceAuthClient) {
    try {
      const token = await serviceAuthClient.getAccessToken();
      if (token && token.token) return serviceAuthClient;
    } catch (e: any) {
      console.warn('Service account failed:', e.message);
    }
  }

  throw new Error('No valid Google Drive authentication method available.');
};

// Export a dynamic drive client getter
export const getDriveClient = async () => {
  const auth = await getWorkingAuthClient();
  return google.drive({ version: 'v3', auth });
};

export const SHARED_FOLDER_ID = process.env.GOOGLE_DRIVE_FOLDER_ID || '';
