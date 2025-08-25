// backend/src/controllers/attendance.controller.js
// ESM module style; change to require(...) if your project is CJS.

import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc.js';
import timezone from 'dayjs/plugin/timezone.js';
import { Attendance } from '../models/Attendance.js';
import { Zone } from '../models/Zone.js';
import { Shift } from '../models/Shift.js';

dayjs.extend(utc);
dayjs.extend(timezone);

// ---------- helpers ----------

/** Haversine distance in meters between two lat/lng points */
function haversineMeters(aLat, aLng, bLat, bLng) {
  const R = 6371000; // meters
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const la1 = toRad(aLat);
  const la2 = toRad(bLat);

  const sinDLat = Math.sin(dLat / 2);
  const sinDLng = Math.sin(dLng / 2);

  const h =
    sinDLat * sinDLat +
    Math.cos(la1) * Math.cos(la2) * sinDLng * sinDLng;

  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** small helper to send consistent errors */
function bad(res, status, msg, extra = {}) {
  return res.status(status).json({ error: msg, ...extra });
}

/** ensure value is a finite number */
function isNum(x) {
  return typeof x === 'number' && Number.isFinite(x);
}

/** start-of-day and end-of-day (UTC by default; change tz if you store local) */
function dayBounds(date = new Date(), tz /* e.g., 'Asia/Kolkata' */) {
  const d = tz ? dayjs(date).tz(tz) : dayjs(date).utc();
  const start = tz ? d.startOf('day').toDate() : d.startOf('day').toDate();
  const end = tz ? d.endOf('day').toDate() : d.endOf('day').toDate();
  return { start, end };
}

// ---------- controllers ----------

/**
 * POST /attendance/check-in
 * Body: { lat:number, lng:number, zoneId:string, shiftId:string }
 */
export const checkIn = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return bad(res, 401, 'Unauthorized');


 const { lat, lng, zoneId, shiftId } = req.body ?? {};

if (zoneId === "null")
  zoneId = null;
if (shiftId === "null") shiftId = null;
    // Validate body
    if (!isNum(lat) || !isNum(lng)) {
      return bad(res, 400, 'lat/lng must be numbers');
    }
    if (!zoneId || !shiftId) {
      return bad(res, 400, 'zoneId and shiftId are required');
    }

    // Ensure zone exists
    const zone = await Zone.findById(zoneId).lean();
    if (!zone) return bad(res, 404, 'Zone not found');

    // Expected zone fields: { center: { lat, lng }, radiusMeters }
    const zCenter = zone.center ?? {};
    const zRadius = Number(zone.radiusMeters ?? 0);
    if (!isNum(zCenter.lat) || !isNum(zCenter.lng) || !isNum(zRadius) || zRadius <= 0) {
      return bad(res, 500, 'Zone is misconfigured');
    }

    // Ensure shift exists
    const shift = await Shift.findById(shiftId).lean();
    if (!shift) return bad(res, 404, 'Shift not found');

    // Optional: verify current time is within shift window (if your app requires)
    // Expected fields: startTime, endTime as "HH:mm" or timestamps
    // You can safely skip this if you don’t track time windows.

    // Check not already checked in (open record for today without checkout)
    const { start, end } = dayBounds(new Date());
    const open = await Attendance.findOne({
      user: userId,
      createdAt: { $gte: start, $lte: end },
      checkInAt: { $ne: null },
      checkOutAt: null,
    });
    if (open) {
      return bad(res, 409, 'Already checked in and not checked out yet', {
        attendanceId: open._id,
      });
    }

    // Geo-fence: ensure within zone radius
    const dist = haversineMeters(lat, lng, zCenter.lat, zCenter.lng);
    const inside = dist <= zRadius;
    if (!inside) {
      return bad(res, 400, 'You are outside the allowed zone', {
        distanceMeters: Math.round(dist),
        allowedRadiusMeters: Math.round(zRadius),
      });
    }

    // Create attendance
    const now = new Date();
    const att = await Attendance.create({
      user: userId,
      zone: zoneId,
      shift: shiftId,
      checkInAt: now,
      checkInLocation: { type: 'Point', coordinates: [lng, lat] }, // GeoJSON [lng, lat]
      meta: {
        source: 'mobile',
        version: 1,
      },
    });

    return res.status(201).json({
      ok: true,
      attendanceId: att._id,
      checkInAt: att.checkInAt,
    });
  } catch (err) {
    // Log server-side if you have a logger
    return bad(res, 500, 'Internal error', { detail: err?.message });
  }
};

/**
 * POST /attendance/check-out
 * Body: { lat:number, lng:number }
 */
export const checkOut = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return bad(res, 401, 'Unauthorized');

    const { lat, lng } = req.body ?? {};
    if (!isNum(lat) || !isNum(lng)) {
      return bad(res, 400, 'lat/lng must be numbers');
    }

    // Find open attendance for today
    const { start, end } = dayBounds(new Date());
    const att = await Attendance.findOne({
      user: userId,
      createdAt: { $gte: start, $lte: end },
      checkInAt: { $ne: null },
      checkOutAt: null,
    });
    if (!att) {
      return bad(res, 409, 'You have not checked in today or already checked out');
    }

    const now = new Date();
    att.checkOutAt = now;
    att.checkOutLocation = { type: 'Point', coordinates: [lng, lat] };

    // Calculate worked duration (minutes)
    const ms = now.getTime() - att.checkInAt.getTime();
    const minutes = Math.max(0, Math.round(ms / 60000));
    att.workedMinutes = minutes;

    await att.save();

    return res.json({
      ok: true,
      attendanceId: att._id,
      checkInAt: att.checkInAt,
      checkOutAt: att.checkOutAt,
      workedMinutes: att.workedMinutes,
    });
  } catch (err) {
    return bad(res, 500, 'Internal error', { detail: err?.message });
  }
};

/**
 * GET /attendance/me/today
 * Returns today’s record (if any)
 */
export const myToday = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return bad(res, 401, 'Unauthorized');

    const { start, end } = dayBounds(new Date());
    const att = await Attendance.findOne({
      user: userId,
      createdAt: { $gte: start, $lte: end },
    })
      .populate('zone', 'name')
      .populate('shift', 'name')
      .lean();

    return res.json({ ok: true, record: att ?? null });
  } catch (err) {
    return bad(res, 500, 'Internal error', { detail: err?.message });
  }
};

/**
 * GET /attendance/me
 * Query: page=1 size=20
 */
export const myHistory = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return bad(res, 401, 'Unauthorized');

    const page = Math.max(1, parseInt(req.query.page ?? '1', 10));
    const size = Math.min(100, Math.max(1, parseInt(req.query.size ?? '20', 10)));

    const [items, total] = await Promise.all([
      Attendance.find({ user: userId })
        .sort({ createdAt: -1 })
        .skip((page - 1) * size)
        .limit(size)
        .populate('zone', 'name')
        .populate('shift', 'name')
        .lean(),
      Attendance.countDocuments({ user: userId }),
    ]);

    return res.json({
      ok: true,
      page,
      size,
      total,
      items,
    });
  } catch (err) {
    return bad(res, 500, 'Internal error', { detail: err?.message });
  }
};
