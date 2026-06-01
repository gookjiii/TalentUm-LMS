import { google } from 'googleapis';
import { JWT } from 'google-auth-library';

const serviceAccountJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
const clientId = process.env.GOOGLE_CLIENT_ID;
const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
const refreshToken = process.env.GOOGLE_REFRESH_TOKEN;

let authClient: any;

if (clientId && clientSecret && refreshToken) {
  // Use OAuth2 Refresh Token (Best for Personal @gmail.com accounts with 5TB quota)
  const oauth2Client = new google.auth.OAuth2(clientId, clientSecret);
  oauth2Client.setCredentials({ refresh_token: refreshToken });
  authClient = oauth2Client;
} else if (serviceAccountJson) {
  // Use Service Account (Best for Workspace accounts with Shared Drives)
  const credentials = JSON.parse(serviceAccountJson);
  if (credentials.private_key) {
    credentials.private_key = credentials.private_key.replace(/\\n/g, '\n');
  }
  authClient = new JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ['https://www.googleapis.com/auth/drive'],
  });
} else {
  throw new Error('Missing Google authentication configuration. Please provide either GOOGLE_SERVICE_ACCOUNT_JSON or GOOGLE_CLIENT_ID + GOOGLE_CLIENT_SECRET + GOOGLE_REFRESH_TOKEN');
}

export const auth = authClient;
export const driveClient = google.drive({ version: 'v3', auth: auth });
export const SHARED_FOLDER_ID = process.env.GOOGLE_DRIVE_FOLDER_ID || '';
