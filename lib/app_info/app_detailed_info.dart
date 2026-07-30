/*
# HRMS - Employee Attendance & Live Location Tracking System

## Project Overview

**HRMS** is an enterprise-grade Human Resource Management System with Employee Attendance and Live Location Tracking, built using **Flutter** for Android devices.

The application operates on an **Offline-First Architecture** following **Clean Architecture** principles. It ensures reliable attendance management, configurable verification policies, break tracking, foreground live location tracking, device reboot recovery, and automatic data synchronization.

---

## 1. Initial Landing & Role-Based Entry

When the application is launched for the first time or when no session is active, the initial landing page presents two primary entry points:

- **Login as Company**: For company registration, onboarding status, and administrative setup.
- **Login as Employee**: For daily employee authentication, attendance marking, break tracking, and profile settings.

---

## 2. Company Onboarding & Management Flow

### Company Registration
- A new company registers via the app or web portal by filling in company details:
  - Company Name
  - Address
  - GST Number / Registration ID
  - Owner / Authorized Person Name
  - Email Address
  - Contact Number
- Upon registration submission, the company account is placed in **Pending** status.

### Super Admin Review & Approval
- Super Admin reviews the company application via the Admin Panel.
- Account approval or rejection takes place (typically within 2 business days).
- Once approved, the company status changes to **Active**.

### Employee Provisioning & Credential Sharing
- Active companies can add employees and configure their profiles.
- Company creates initial login credentials (User ID / Password) for each employee.
- Credential Distribution:
  - Sent directly to the employee via **WhatsApp** (with option for Email/SMS backup).

---

## 3. Employee Authentication & Security Setup

### Splash & Initial Login
- **Splash Screen**: Displays branding upon app launch and automatically navigates to the Login screen.
- **First Login Prompt**:
  - Employee logs in using the credentials received via email.
  - On the first successful login, the employee is prompted to change their default password (can be changed immediately or skipped to change later in Settings/Profile).

### Quick Login Configuration
After the first successful authentication, the user is prompted to set up one or more Quick Login methods:
- **Biometrics**: Fingerprint or Face ID (based on device hardware support).
- **PIN Code**: 4-digit or 6-digit security PIN.
- **Face Lock**: Device-supported facial recognition.

### Daily Authentication Routine
- On subsequent app launches, the user authenticates via Quick Login (Biometric / PIN / Face Lock).
- A fallback option ("Use Password Instead") is always available for full credential authentication.
- **Security Policies**:
  - Preferences and encrypted credentials are held securely in local storage.
  - Quick login options can be toggled on/off in Settings.
  - Re-authentication with full password is required if the session expires or the password is changed.

---

## 4. Attendance & Workday Lifecycle

### Attendance Lifecycle
1. **Start Attendance**: At the beginning of the workday, the employee slides to mark attendance.
2. **Active Workday**: Attendance session becomes active. Break features and location tracking (if enabled) are initiated.
3. **Close Attendance**: At the end of the day (EOD), the employee slides/taps to close attendance.
   - Displays a confirmation popup before closing.
   - Stops tracking, finalizes the session, and locks further attendance/break actions for the day.

### Break Management Flow
- The **Break** option activates **only after** attendance has been started for the day.
- **Workflow**:
  - **Start Attendance** $\rightarrow$ Break option enabled.
  - Tap **Start Break** $\rightarrow$ Break timer starts; location tracking pauses.
  - During Break $\rightarrow$ Only **End Break** action is available.
  - Tap **End Break** $\rightarrow$ Employee can choose to start another break or Close Attendance; location tracking resumes.
  - **Close Attendance** $\rightarrow$ Confirmation popup; attendance session completes.

---

## 5. Company-Configurable Attendance Policies

Companies can customize attendance verification policies per employee or department. The app dynamically adapts the attendance UI based on the active company configuration.

### Policy Configurations
- **Attendance Only**: Simple slide gesture to mark attendance.
- **Attendance + Image Verification**: Requires photo evidence before marking attendance.
  - *Selfie*: Front camera selfie photo.
  - *Odometer*: Photo of vehicle odometer for travel/mileage tracking.
  - *Both*: Both selfie and odometer photos required.
- **Attendance + Live Tracking**: Automatically triggers continuous background location tracking during working hours.
- **Attendance + Travel Mode**: Prompts employee to select their conveyance mode upon marking attendance.
- **Combined Policies**: Any hybrid combination of the above settings.

### Travel Modes
When Travel Mode selection is enabled, employees choose their mode of transit:
- Bike
- Car
- Public Transport
- Walking
- Office / No Travel

---

## 6. Background Location Tracking & Sync Service

### Continuous Location Tracking
- Starts immediately upon marking attendance (if tracking policy is enabled).
- Runs as an Android **Foreground Service** (`flutter_background_service`).
- Continuously collects location data across all app states:
  - App Open
  - Background
  - Minimized
  - App Closed / Terminated (where Android platform policies permit)
- **Break Time Handling**: Tracking **automatically pauses/stops** during break time and **resumes** when the break ends.
- Collected Telemetry: Latitude, Longitude, Accuracy, Speed, Bearing, Altitude, Timestamp, Battery Level.

### Reboot Recovery
- Registers `BOOT_COMPLETED` receiver.
- Checks local database for active attendance session on device reboot.
- Automatically restarts background tracking service without requiring manual app launch by the employee.

### Offline-First Storage & Synchronization
- **Local Storage (Source of Truth)**: All location points and attendance actions are written locally to the **Drift (SQLite)** database first.
- **Sync Service**: Dedicated background module using `connectivity_plus` to monitor network state.
- **Auto-Sync**: Automatically pushes unsynced records to the cloud when internet connection is active, marking uploaded records as synced. Includes retry and deduplication mechanisms.

---

## 7. Architecture & Technology Stack

### Core Stack
- **Framework**: Flutter (Latest Stable) / Dart
- **Target OS**: Android (Material 3 Design)
- **Architecture Pattern**: Clean Architecture with Feature-Based Folder Structure
- **State Management**: `flutter_bloc` & `equatable`
- **Dependency Injection**: `get_it`
- **Local Storage**: Drift Database (SQLite) & SharedPreferences
- **Backend**: Offline-First with temporary Firebase backend (Core, Auth, Firestore), structured for seamless future migration to REST APIs.

### Main Packages
- `flutter_bloc`, `equatable`, `get_it`
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `drift`, `path_provider`, `shared_preferences`
- `flutter_background_service`, `geolocator`, `permission_handler`
- `connectivity_plus`, `http`, `logger`, `intl`

---

## 8. Directory & Layer Structure

```
lib/
├── ui/                 # All User Interface & State Management
│   ├── bloc/           # BLoC state management
│   ├── screens/        # App screens (company, employee, auth)
│   └── widgets/        # Reusable UI widgets & dialogs
├── backend/            # Backend, Firebase & Remote Services
│   ├── models/         # Entities & data models
│   ├── repositories/   # Repository interfaces & implementations
│   └── services/       # Firebase & remote data sources
├── local/              # Local Storage & Device Services
│   ├── database/       # Drift local database
│   ├── datasource/     # Local data source
│   ├── helpers/        # Permission helpers
│   └── services/       # Background location & sync services
├── di/                 # Dependency injection container
├── app_info/           # App documentation & metadata
└── main.dart           # App entry point
```

---

## 9. Future Enhancements

- Multi-channel credential dispatch (SMS / WhatsApp)
- Face Recognition & QR-based attendance verification
- Geofencing and dynamic office perimeters
- Shift, leave, and holiday management
- Admin analytics, live employee tracking map, and payroll integration
*/