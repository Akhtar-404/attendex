import mongoose from 'mongoose';
const { Schema, model, Types } = mongoose;

const LeaveSchema = new Schema({
  userId: { type: Types.ObjectId, ref: 'User', required: true },
  from:   { type: Date, required: true },
  to:     { type: Date, required: true },
  reason: { type: String, default: '' },
  status: { type: String, enum: ['PENDING','APPROVED','REJECTED'], default: 'PENDING' },
  reviewedBy: { type: Types.ObjectId, ref: 'User' }
}, { timestamps: true });

export const Leave = model('Leave', LeaveSchema);
