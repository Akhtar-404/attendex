import { Router } from 'express';
import { Shift } from '../models/Shift.js';
import { requireAuth, requireRole } from '../middleware/auth.js';

const r = Router();

// Everyone authenticated can read
r.get('/', requireAuth, async (_req, res) => {
  const shifts = await Shift.find().lean();
  res.json(shifts.map(s => ({ ...s, id: String(s._id), _id: undefined })));
});

// ADMIN only: create
r.post('/', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { name, start, end } = req.body || {};
  if (!name || !start || !end) return res.status(400).json({ error: 'name, start, end required' });
  const s = await Shift.create({ name, start, end });
  res.status(201).json(s.toJSON());
});

// ADMIN only: update
r.patch('/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const patch = {};
  ['name', 'start', 'end'].forEach(k => { if (req.body?.[k]) patch[k] = req.body[k]; });
  const s = await Shift.findByIdAndUpdate(id, patch, { new: true });
  if (!s) return res.status(404).json({ error: 'Shift not found' });
  res.json(s.toJSON());
});

// ADMIN only: delete
r.delete('/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const s = await Shift.findByIdAndDelete(id);
  if (!s) return res.status(404).json({ error: 'Shift not found' });
  res.status(204).end();
});

export default r;
