import { VercelRequest, VercelResponse } from '@vercel/node';
import { authAdmin, dbAdmin } from './firebase';

const DEFAULT_ALLOWED_ORIGINS = [
  'https://talentum.web.app',
  'https://talentum.firebaseapp.com',
  'http://localhost:3000',
  'http://localhost:5000',
];

export function handleCors(req: VercelRequest, res: VercelResponse): boolean {
  const configuredOrigins = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  const allowedOrigins = configuredOrigins.length > 0
    ? configuredOrigins
    : DEFAULT_ALLOWED_ORIGINS;
  const origin = req.headers.origin;

  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, X-Upload-Url, Content-Range, X-Upload-Content-Range, X-Upload-Content-Type, X-Upload-Content-Length');
  res.setHeader('Access-Control-Expose-Headers', 'Range, Content-Range');
  res.setHeader('Access-Control-Max-Age', '86400');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return true;
  }
  return false;
}

export async function verifyFirebaseToken(req: VercelRequest): Promise<any | null> {
  const authorization = req.headers.authorization;
  const header = Array.isArray(authorization) ? authorization[0] : authorization;
  if (!header || !header.startsWith('Bearer ')) return null;

  try {
    return await authAdmin.verifyIdToken(header.slice('Bearer '.length).trim());
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
}

export async function requireUserOrAdmin(
  req: VercelRequest,
  userId: string,
): Promise<any | null> {
  const token = await verifyFirebaseToken(req);
  if (!token) return null;
  if (token.uid === userId || token.admin === true || token.role === 'admin') {
    return token;
  }

  try {
    const snapshot = await dbAdmin.collection('users').doc(token.uid).get();
    const role = snapshot.data()?.role;
    return role === 'admin' || role === 'leadTeacher' ? token : null;
  } catch (error) {
    console.error('Failed to resolve user role:', error);
    return null;
  }
}

export async function requireAdminToken(req: VercelRequest): Promise<any | null> {
  const token = await verifyFirebaseToken(req);
  if (!token) return null;
  if (token.admin === true || token.role === 'admin') return token;

  try {
    const snapshot = await dbAdmin.collection('users').doc(token.uid).get();
    const role = snapshot.data()?.role;
    return role === 'admin' || role === 'leadTeacher' ? token : null;
  } catch (error) {
    console.error('Failed to resolve admin role:', error);
    return null;
  }
}

export async function requireAuthenticatedUser(req: VercelRequest): Promise<any | null> {
  const token = await verifyFirebaseToken(req);
  if (!token) return null;

  const claimedRole = token.role;
  if (claimedRole) {
    return { ...token, resolvedRole: claimedRole };
  }

  try {
    const snapshot = await dbAdmin.collection('users').doc(token.uid).get();
    const role = snapshot.data()?.role || 'student';
    return { ...token, resolvedRole: role };
  } catch (error) {
    console.error('Failed to resolve user role:', error);
    return { ...token, resolvedRole: 'student' };
  }
}

export async function requireStaffToken(req: VercelRequest): Promise<any | null> {
  const token = await verifyFirebaseToken(req);
  if (!token) return null;

  const claimedRole = token.role;
  if (claimedRole === 'admin' || claimedRole === 'leadTeacher' || claimedRole === 'teacher') {
    return { ...token, resolvedRole: claimedRole };
  }

  try {
    const snapshot = await dbAdmin.collection('users').doc(token.uid).get();
    const role = snapshot.data()?.role;
    if (role === 'admin' || role === 'leadTeacher' || role === 'teacher') {
      return { ...token, resolvedRole: role };
    }
    return null;
  } catch (error) {
    console.error('Failed to resolve staff role:', error);
    return null;
  }
}

export function checkRateLimit(req: VercelRequest, maxRequests = 20, windowMs = 60000): boolean {
  const forwardedFor = req.headers['x-forwarded-for'];
  const ip = Array.isArray(forwardedFor)
    ? forwardedFor[0]
    : (forwardedFor || req.socket.remoteAddress || 'unknown').split(',')[0].trim();
  const now = Date.now();
  const key = `${ip}:${req.url?.split('?')[0] || ''}`;
  const existing = rateLimits.get(key);
  if (!existing || now > existing.resetTime) {
    rateLimits.set(key, { count: 1, resetTime: now + windowMs });
    return true;
  }
  existing.count += 1;
  return existing.count <= maxRequests;
}

interface RateLimitEntry {
  count: number;
  resetTime: number;
}

const rateLimits = new Map<string, RateLimitEntry>();
