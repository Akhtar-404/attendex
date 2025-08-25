import jwt from 'jsonwebtoken';
const secret = process.env.JWT_SECRET || 'dev';

export function signAccess(payload) {
  return jwt.sign(payload, secret, { expiresIn: '1h' });
}
export function signRefresh(payload) {
  return jwt.sign(payload, secret, { expiresIn: '7d' });
}
export function verifyToken(token) {
  return jwt.verify(token, secret);
}
