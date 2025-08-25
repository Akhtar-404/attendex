import mongoose from 'mongoose';
const { Schema, model } = mongoose;

const ZoneSchema = new Schema({
  name: { type: String, required: true },
  center: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true } // [lng,lat]
  },
  radiusMeters: { type: Number, default: 30 }
}, { timestamps: true });

ZoneSchema.index({ center: '2dsphere' });
export const Zone = model('Zone', ZoneSchema);
