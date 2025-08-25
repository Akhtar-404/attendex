import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { Leave } from '../models/Leave.js';

const r = Router();

const applyZ = z.object({
  from: z.string(), // ISO date
  to:   z.string(),
  reason: z.string().optional()
});
r.post('/', requireAuth, async (req, res) => {
  try {
    const { from, to, reason } = applyZ.parse(req.body);
    const rec = await Leave.create({
      userId: req.userId,
      from: new Date(from),
      to: new Date(to),
      reason: reason || ''
    });
    res.status(201).json(rec);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

r.get('/me', requireAuth, async (req, res) => {
  const list = await Leave.find({ userId: req.userId }).sort({ createdAt: -1 }).lean();
  res.json(list);
});

// HR list all pending
r.get('/', requireAuth, requireRole('HR','ADMIN'), async (_req, res) => {
  const list = await Leave.find().sort({ createdAt: -1 }).lean();
  res.json(list);
});

// HR approve/reject
const statusZ = z.object({ status: z.enum(['APPROVED','REJECTED']) });
r.patch('/:id/status', requireAuth, requireRole('HR','ADMIN'), async (req, res) => {
  try {
    const { status } = statusZ.parse(req.body);
    const rec = await Leave.findByIdAndUpdate(
      req.params.id, { status, reviewedBy: req.userId }, { new: true }
    );
    if (!rec) return res.status(404).json({ error: 'Not found' });
    res.json(rec);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

export default r;
