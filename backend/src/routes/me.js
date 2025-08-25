// backend/src/routes/me.routes.js
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js'; // whatever your auth middleware is called
import { User } from '../models/User.js';            // adjust import path if needed

const r = Router();

/**
 * GET /me  -> return the authenticated user's public profile
 */
r.get('/me', requireAuth, async (req, res) => {
  try {
    const u = await User.findById(req.user.id)
      .select('name email role createdAt')
      .lean();
    if (!u) return res.status(404).json({ error: 'User not found' });
    res.json(u);
  } catch (e) {
    res.status(500).json({ error: 'Internal error' });
  }
});

export default r;
