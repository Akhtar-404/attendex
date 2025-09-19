// backend/src/models/User.js
import mongoose from 'mongoose';
const { Schema, model } = mongoose;

const UserSchema = new Schema({
  name:  { type: String, required: true },
  email: { type: String, required: true, unique: true, index: true },
  hash:  { type: String, required: false },
  role:  { type: String, enum: ['EMPLOYEE','HR','ADMIN'], default: 'EMPLOYEE' },
  active: { type: Boolean, default: true } // <-- Add this line
}, { timestamps: true });

export const User = model('User', UserSchema);
