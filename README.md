# Attendex App

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Setup Instructions](#setup-instructions)
- [Project Structure](#project-structure)
- [Usage](#usage)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Attendex App** is a modern attendance management system built with Flutter (frontend) and Node.js/Express/MongoDB (backend).  
It supports employee check-in/out, admin dashboard, zone/shift management, and attendance analytics.

---

## Features

- Employee check-in/out with location and shift validation
- Admin dashboard: view present employees, download daily Excel reports
- Attendance history calendar for employees
- Zone and shift management
- Secure authentication (JWT)
- Responsive UI with glowing effects

---

## Tech Stack

- **Frontend:** Flutter, Dart
- **Backend:** Node.js, Express
- **Database:** MongoDB
- **Other:** Dio (Flutter HTTP), ExcelJS (backend Excel export)

---

## Setup Instructions

### Backend

1. **Install dependencies:**
   ```sh
   cd backend
   npm install
   ```

2. **Configure environment variables:**
   - Create a `.env` file in the `backend` folder:
     ```
     MONGO_URI=mongodb://localhost:27017/attendex
     JWT_SECRET=your_secret_key
     ```
   - *(Replace with your actual MongoDB URI and secret)*

3. **Start MongoDB:**
   - Make sure MongoDB is running locally or use a cloud MongoDB (like Atlas).

4. **Run the backend server:**
   ```sh
   npm run dev
   ```
   - The server should start (default port is usually 8080 or 3000).

---

### Frontend (Flutter)

1. **Install dependencies:**
   ```sh
   flutter pub get
   ```

2. **Set up API base URL:**
   - When running the app, pass your backend IP and port:
     ```sh
     flutter run --dart-define=API_BASE=http://<your-ip>:8080
     ```
   - Replace `<your-ip>` with your computer's IP address on the same network as your device/emulator.

3. **Android/iOS permissions:**
   - For location features, ensure you have the required permissions in `AndroidManifest.xml` and `Info.plist`.

4. **Run the app:**
   ```sh
   flutter run --dart-define=API_BASE=http://<your-ip>:8080
   ```

---

## Project Structure

```
backend/
  src/
    controllers/
    middleware/
    models/
    routes/
    utils/
  .env
  package.json

lib/
  features/
    admin/
    auth/
    employee/
    gate/
    hr/
  core/
  services/
  app.dart
  main.dart
```

---

## Usage

- **Admin:** Log in, manage zones/shifts, view present employees, download Excel reports.
- **Employee:** Log in, check in/out, view attendance history.

---

## Screenshots

*(Add screenshots of your app’s main pages here)*

---

## Contributing

Pull requests are welcome!  
For major changes, please open an issue first to discuss what you would like to change.

---

## License

MIT
