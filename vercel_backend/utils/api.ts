import { VercelRequest, VercelResponse } from '@vercel/node';
import { authAdmin } from './firebase';

export function handleCors(req: VercelRequest, res: VercelResponse): boolean {
  const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000,http://localhost:5000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  const origin = req.headers.origin;

  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }

  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.setHeader('Access-Control-Max-Age', '86400');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return true;
  }
  return false;
}

export async function verifyFirebaseToken(req: VercelRequest): Promise<{ uid: string } | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.split('Bearer ')[1].trim();
  try {
    const decodedToken = await authAdmin.verifyIdToken(token);
    return { uid: decodedToken.uid };
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
}

export function requireApiSecret(req: VercelRequest): boolean {
  const serverSecret = process.env.APP_API_SECRET;
  if (!serverSecret) {
    console.error('APP_API_SECRET is not configured for protected endpoint.');
    return false;
  }

  return req.headers.authorization === `Bearer ${serverSecret}`;
}

// Simple in-memory rate limiter
interface RateLimitEntry {
  count: number;
  resetTime: number;
}
const rateLimits = new Map<string, RateLimitEntry>();

export function checkRateLimit(req: VercelRequest, maxRequests = 10, windowMs = 60000): boolean {
  const forwardedFor = req.headers['x-forwarded-for'];
  const ip = Array.isArray(forwardedFor)
    ? forwardedFor[0]
    : (forwardedFor || req.socket.remoteAddress || 'unknown').split(',')[0].trim();
  const now = Date.now();

  let entry = rateLimits.get(ip);
  if (!entry || now > entry.resetTime) {
    entry = { count: 0, resetTime: now + windowMs };
  }

  entry.count++;
  rateLimits.set(ip, entry);

  return entry.count <= maxRequests;
}
