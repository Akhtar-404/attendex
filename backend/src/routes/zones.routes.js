import { Router } from 'express';
import { Zone } from '../models/Zone.js';
import { requireAuth, requireRole } from '../middleware/auth.js';

const r = Router();

// Everyone authenticated can read
r.get('/', requireAuth, async (_req, res) => {
  const zones = await Zone.find().lean();
  res.json(zones.map(z => ({ ...z, id: String(z._id), _id: undefined })));
});

// ADMIN only: create
r.post('/', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { name, lat, lng, radiusMeters } = req.body || {};
  if (typeof name !== 'string' || typeof lat !== 'number' || typeof lng !== 'number') {
    return res.status(400).json({ error: 'name, lat, lng required' });
  }
  const z = await Zone.create({
    name,
    center: { type: 'Point', coordinates: [lng, lat] },
    radiusMeters: Number(radiusMeters || 30)
  });
  res.status(201).json(z.toJSON());
});

// ADMIN only: update
r.patch('/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const { name, lat, lng, radiusMeters } = req.body || {};
  const patch = {};
  if (name) patch.name = name;
  if (typeof lat === 'number' && typeof lng === 'number') {
    patch.center = { type: 'Point', coordinates: [lng, lat] };
  }
  if (radiusMeters != null) patch.radiusMeters = Number(radiusMeters);

  const z = await Zone.findByIdAndUpdate(id, patch, { new: true });
  if (!z) return res.status(404).json({ error: 'Zone not found' });
  res.json(z.toJSON());
});

// ADMIN only: delete
r.delete('/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const z = await Zone.findByIdAndDelete(id);
  if (!z) return res.status(404).json({ error: 'Zone not found' });
  res.status(204).end();
});

export default r;
