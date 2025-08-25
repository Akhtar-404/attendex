import mongoose from 'mongoose';
const { Schema, model } = mongoose;

const ShiftSchema = new Schema({
  name:  { type: String, required: true },
  start: { type: String, required: true }, // "09:00"
  end:   { type: String, required: true }  // "18:00"
}, { timestamps: true });

export const Shift = model('Shift', ShiftSchema);
