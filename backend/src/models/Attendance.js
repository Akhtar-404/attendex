import mongoose from 'mongoose';
const { Schema, model, Types } = mongoose;

const AttendanceSchema = new Schema({
  userId: { type: Types.ObjectId, ref: 'User', required: true, index: true },
  zoneId: { type: Types.ObjectId, ref: 'Zone' },
  shiftId:{ type: Types.ObjectId, ref: 'Shift' },
  checkInTime:  { type: Date },
  checkInLoc:   { lat: Number, lng: Number },
  checkOutTime: { type: Date },
  checkOutLoc:  { lat: Number, lng: Number },
  status:       { type: String, enum: ['IN','OUT'], default: 'OUT' }
}, { timestamps: true });

export const Attendance = model('Attendance', AttendanceSchema);
