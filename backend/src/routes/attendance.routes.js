import { Router } from 'express';
import { z } from 'zod';
import mongoose from 'mongoose';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { Attendance } from '../models/Attendance.js';
import { Zone } from '../models/Zone.js';
import { checkIn, checkOut, myToday, myHistory } from '../controllers/attendance.controller.js';
import dayjs from 'dayjs';







const r = Router();

function distanceM(lat1, lon1, lat2, lon2) {
  const toRad = d => (d * Math.PI) / 180, R = 6371000;
  const dLat = toRad(lat2 - lat1), dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat/2)**2 + Math.cos(toRad(lat1))*Math.cos(toRad(lat2))*Math.sin(dLon/2)**2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const checkInZ = z.object({
  zoneId: z.string(),
  shiftId: z.string(),
  lat: z.number(),
  lng: z.number()
});
r.post('/check-in', requireAuth, async (req, res) => {
  try {
    const { zoneId, shiftId, lat, lng } = checkInZ.parse(req.body);
    const z = await Zone.findById(zoneId).lean();
    if (!z) return res.status(404).json({ error: 'Zone not found' });
    const [zLng, zLat] = z.center.coordinates; // [lng, lat]
    const dist = distanceM(lat, lng, zLat, zLng);
    const within = dist <= (z.radiusMeters ?? 300);

    // Close any open
    await Attendance.updateMany(
      { userId: req.userId, status: 'IN', checkOutTime: { $exists: false } },
      { $set: { status: 'OUT', checkOutTime: new Date(), checkOutLoc: { lat, lng } } }
    );

    const rec = await Attendance.create({
      userId: new mongoose.Types.ObjectId(req.userId),
      zoneId, shiftId,
      checkInTime: new Date(),
      checkInLoc: { lat, lng },
      status: 'IN'
    });

    res.json({ id: rec._id.toString(), status: within ? 'WITHIN_ZONE' : 'OUTSIDE_ZONE', distance: Math.round(dist) });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

const checkOutZ = z.object({ lat: z.number(), lng: z.number() });
r.post('/check-out', requireAuth, async (req, res) => {
  try {
    const { lat, lng } = checkOutZ.parse(req.body);
    const open = await Attendance.findOne({ status: 'IN' }).sort({ createdAt: -1 });
    if (!open) return res.status(400).json({ error: 'No open attendance' });
    open.status = 'OUT'; open.checkOutTime = new Date(); open.checkOutLoc = { lat, lng };
    await open.save();
    res.json({ ok: true, checkOutTime: open.checkOutTime });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

// my history
r.get('/me', requireAuth, async (req, res) => {
  const list = await Attendance.find({ userId: req.userId }).sort({ createdAt: -1 }).lean();
  res.json(list);
});

// admin/hr: query by user and/or date range
r.get('/', requireAuth, requireRole('HR','ADMIN'), async (req, res) => {
  const { userId, from, to } = req.query;
  const q = {};
  if (userId) q.userId = userId;
  if (from || to) {
    q.createdAt = {};
    if (from) q.createdAt.$gte = new Date(from);
    if (to) q.createdAt.$lte = new Date(to);
  }
  const list = await Attendance.find(q).sort({ createdAt: -1 }).lean();
  res.json(list);
});

r.get('/daily', requireAuth, requireRole('HR', 'ADMIN'), async (req, res) => {
  const d = req.query.date ? dayjs(req.query.date) : dayjs();
  const start = d.startOf('day').toDate();
  const end = d.endOf('day').toDate();

  const rows = await Attendance.find({
    checkInTime: { $gte: start, $lte: end },
  })
    .select('-__v')
    .lean();

  res.json(rows);
});


export default r;
