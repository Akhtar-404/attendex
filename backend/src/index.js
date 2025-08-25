import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import routes from './routes/index.js';

dotenv.config();

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.use('/', routes);

// helpful crash logs
process.on('unhandledRejection', e => console.error('UNHANDLED', e));
process.on('uncaughtException', e => console.error('UNCAUGHT', e));

(async () => {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected');
  const port = process.env.PORT || 8080;
  app.listen(port, () => console.log(`API on http://localhost:${port}`));
})();
