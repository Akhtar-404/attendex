// backend/src/routes/auth.routes.js
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/User.js';

const r = Router();

r.post('/signup', async (req, res) => {
  const { name, email, password, role } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email & password required' });
  const exists = await User.findOne({ email: email.toLowerCase() });
  if (exists) return res.status(409).json({ error: 'Email already in use' });

  const hash = await bcrypt.hash(password, 10);
  const u = await User.create({
    name: name ?? '',
    email: email.toLowerCase(),
    hash,
    role: ['EMPLOYEE', 'HR', 'ADMIN'].includes(role) ? role : 'EMPLOYEE',
    active: true,
  });

  return res.status(201).json({ id: u._id, email: u.email, role: u.role });
});

r.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body ?? {};
    if (!email || !password) return res.status(400).json({ error: 'Email & password required' });

    // IMPORTANT: lowercase + explicitly select hash
    const u = await User.findOne({ email: email.toLowerCase() }).select('+hash');
    if (!u) return res.status(401).json({ error: 'Invalid email or password' });
    if (u.active === false) return res.status(401).json({ error: 'User is inactive' });

    const ok = await bcrypt.compare(password, u.hash || '');
    if (!ok) return res.status(401).json({ error: 'Invalid email or password' });

    const payload = { sub: u._id.toString(), role: u.role };
    const accessToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });
    const refreshToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({
      accessToken,
      refreshToken,
      user: { id: u._id, name: u.name, email: u.email, role: u.role },
    });
  } catch (e) {
    console.error('LOGIN ERROR:', e);
    res.status(500).json({ error: 'Server error' });
  }
});

export default r;
