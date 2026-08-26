import { google, drive_v3 } from 'googleapis';
import { JWT } from 'google-auth-library';

const serviceAccountJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
const clientId = process.env.GOOGLE_CLIENT_ID;
const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
const refreshToken = process.env.GOOGLE_REFRESH_TOKEN;

let activeAuth: any;

function parseJwtCandidate(jsonString: string): JWT | null {
  try {
    let raw = jsonString.trim();
    if (!raw.startsWith('{')) {
      try {
        raw = Buffer.from(raw, 'base64').toString('utf8');
      } catch (_) {}
    }
    const credentials = JSON.parse(raw);
    if (credentials.client_email && credentials.private_key) {
      let key = credentials.private_key;
      if (typeof key === 'string') {
        key = key.replace(/\\n/g, '\n');
      }
      return new JWT({
        email: credentials.client_email,
        key: key,
        scopes: ['https://www.googleapis.com/auth/drive'],
      });
    }
  } catch (e: any) {
    console.warn('Failed to parse service account credentials:', e.message);
  }
  return null;
}

function authCandidates(): any[] {
  const candidates: any[] = [];

  if (clientId && clientSecret && refreshToken) {
    const oauth = new google.auth.OAuth2(clientId, clientSecret);
    oauth.setCredentials({ refresh_token: refreshToken });
    candidates.push(oauth);
  }

  const saJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (saJson) {
    const jwt = parseJwtCandidate(saJson);
    if (jwt) candidates.push(jwt);
  }

  const fbSaJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (fbSaJson) {
    const jwt = parseJwtCandidate(fbSaJson);
    if (jwt) candidates.push(jwt);
  }

  return candidates;
}

async function resolveAuth(): Promise<any> {
  const candidates = activeAuth ? [activeAuth, ...authCandidates()] : authCandidates();
  const seen = new Set<any>();
  let lastError: unknown;

  for (const candidate of candidates) {
    if (seen.has(candidate)) continue;
    seen.add(candidate);
    try {
      const token = await candidate.getAccessToken();
      if (token?.token) {
        activeAuth = candidate;
        return candidate;
      }
    } catch (error) {
      lastError = error;
      if (candidate === activeAuth) activeAuth = undefined;
      console.warn('Google Drive auth candidate failed; trying fallback.');
    }
  }

  throw new Error(
    `Google Drive authentication failed${lastError ? `: ${(lastError as Error).message}` : ''}`,
  );
}

export async function getDriveAccessToken(): Promise<string> {
  const auth = await resolveAuth();
  const token = await auth.getAccessToken();
  if (!token?.token) throw new Error('Google Drive returned an empty access token');
  return token.token;
}

export async function getDriveClient(): Promise<drive_v3.Drive> {
  return google.drive({ version: 'v3', auth: await resolveAuth() });
}

export function getDriveFolderId(): string {
  const folderId = (process.env.GOOGLE_DRIVE_FOLDER_ID || '').trim();
  if (!folderId) throw new Error('GOOGLE_DRIVE_FOLDER_ID is not configured');
  return folderId;
}
