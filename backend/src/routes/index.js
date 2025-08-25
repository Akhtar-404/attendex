import { Router } from 'express';
import auth from './auth.routes.js';
import zones from './zones.routes.js';
import me from './me.js';
import shifts from './shifts.routes.js';
import attendance from './attendance.routes.js';
import leaves from './leaves.routes.js';
import { requireAuth } from '../middleware/auth.js';
const r = Router();
r.get('/health', (_req, res) => res.json({ ok: true }));

r.use('/auth', auth);
r.use('/zones', requireAuth,zones);
r.use('/shifts', requireAuth,shifts);
r.use('/me',requireAuth, me); 
r.use('/attendance', requireAuth,attendance);
r.use('/leaves', leaves);

export default r;
