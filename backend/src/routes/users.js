import { Router } from 'express';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { User } from '../models/User.js';

const r = Router();

// List all users (ADMIN or HR)
r.get('/', requireAuth, requireRole('ADMIN', 'HR'), async (_req, res) => {
  const users = await User.find().select('name email role active createdAt').lean();
  res.json(users.map(u => ({ ...u, id: String(u._id), _id: undefined })));
});

// PATCH /users/:id/active -- update active status
r.patch('/:id/active', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { active } = req.body;
  if (typeof active !== 'boolean') {
    return res.status(400).json({ error: 'active must be boolean' });
  }
  const user = await User.findByIdAndUpdate(req.params.id, { active }, { new: true })
    .select('name email role active createdAt')
    .lean();
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ ...user, id: String(user._id), _id: undefined });
});

// PATCH /users/:id/role -- update user role
r.patch('/:id/role', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { role } = req.body;
  if (!['EMPLOYEE', 'HR', 'ADMIN'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  const user = await User.findByIdAndUpdate(req.params.id, { role }, { new: true })
    .select('name email role active createdAt')
    .lean();
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ ...user, id: String(user._id), _id: undefined });
});

export default r;