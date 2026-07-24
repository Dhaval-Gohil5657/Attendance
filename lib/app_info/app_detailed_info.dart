/*
# Attendance - Employee Attendance & Live Location Tracking (POC)

## Project Overview

Attendance is an Android-based employee attendance and live location tracking application built using Flutter. This project is currently being developed as a **Proof of Concept (POC)** to validate the core functionality of an enterprise attendance system.

The main objective of this POC is to ensure that once an employee marks attendance, the application can continuously track the employee's location, even when the application is running in the background, minimized, or (where Android permits) closed. The system should also be able to recover automatically after a device reboot, continue tracking, work offline, and synchronize data once internet connectivity becomes available.

Although this is currently a POC, the project should be designed using enterprise-level architecture so it can later evolve into a complete Employee Management System without requiring major structural changes.

The application should follow modern Flutter development practices, maintain clean code, and be easy to scale and maintain.

---

# Primary Objectives

The primary goals of this POC are:

- Allow employees to mark attendance.
- Start continuous background location tracking.
- Continue tracking while the application is:
  - Open
  - Running in background
  - Minimized
  - Closed (where Android allows)
- Automatically restart tracking after device reboot if attendance is still active.
- Store location data locally when internet is unavailable.
- Automatically synchronize pending records when connectivity is restored.
- Build the application using scalable architecture suitable for enterprise applications.

---

# Platform

- Flutter (Latest Stable)
- Dart (Latest Version)
- Android Only (POC)
- Material 3 Design

---

# Architecture

The application must follow **Clean Architecture** with a Feature-Based Folder Structure.

Use the following layers:

```
Presentation Layer
│
├── Screens
├── Widgets
├── BLoC
│
Domain Layer
│
├── Entities
├── Repositories
├── Use Cases
│
Data Layer
│
├── Models
├── Local Data Source
├── Remote Data Source
├── Repository Implementation
│
Core
│
├── Services
├── Utilities
├── Helpers
├── Constants
```

---

# State Management

Use:

- flutter_bloc
- equatable

---

# Dependency Injection

Use:

- get_it

---

# Local Storage

Use:

- Drift Database
- SharedPreferences

Drift should be used for storing attendance and location data.

SharedPreferences should be used only for lightweight application settings.

---

# Temporary Backend

Since backend APIs are not yet available, use Firebase.

Firebase Services:

- Firebase Core
- Firebase Authentication
- Cloud Firestore

The architecture must allow replacing Firebase with REST APIs later by changing only the Remote Data Source.

---

# Core Modules

## 1. Authentication

Initially support:

- Anonymous Login

Later support:

- Employee Login
- JWT Authentication
- Company Login

---

## 2. Attendance

Employee should be able to:

- Mark Attendance
- View Current Attendance Status
- Check Out

Attendance should generate an Attendance Session.

Tracking begins immediately after attendance is marked.

Tracking stops only after Check Out.

---

## 3. Background Tracking

After attendance:

Start a Foreground Service.

Continue collecting location every configurable interval.

Default interval:

30 seconds.

Tracking should continue when:

- App Open
- Background
- Minimized
- Closed (where Android permits)

---

## 4. Device Restart Recovery

If the phone restarts:

- Receive BOOT_COMPLETED
- Read saved tracking state
- Restart tracking automatically
- Continue uploading locations

The employee should not need to manually reopen the app.

---

## 5. Offline Support

Application must continue functioning without internet.

If internet is unavailable:

- Continue location tracking
- Save attendance locally
- Save every GPS point locally
- Never lose data

When internet becomes available:

- Automatically upload pending data
- Mark uploaded records as synced

---

## 6. Synchronization

Create a dedicated Sync Service.

Responsibilities:

- Detect connectivity
- Upload pending attendance
- Upload pending locations
- Retry failed uploads
- Prevent duplicate uploads

Synchronization should happen automatically.

---

## 7. Location Tracking

Collect:

- Latitude
- Longitude
- Accuracy
- Speed
- Bearing
- Altitude
- Timestamp
- Battery Percentage

Use:

- geolocator

---

## 8. Permissions

Request:

- Fine Location
- Background Location
- Notification Permission
- Ignore Battery Optimization (if required)

Handle all denied permission cases gracefully.

---

# Data Layer

The application must follow an Offline-First Architecture.

Every location must first be stored locally.

Internet availability should never affect tracking.

The local database is the source of truth.

Firebase is used only as temporary cloud storage.

---

# Local Database

Use Drift.

### Attendance Table

- attendanceId
- employeeId
- checkInTime
- checkOutTime
- status
- isTracking
- createdAt

### Location Table

- id
- attendanceId
- latitude
- longitude
- accuracy
- speed
- bearing
- altitude
- batteryLevel
- timestamp
- isSynced

---

# Firestore Collections

employees

attendance

location_logs

---

# Home Screen

Simple UI.

Display:

- Employee Name (Dummy for now)
- Attendance Status
- Tracking Status
- GPS Status
- Internet Status
- Current Latitude
- Current Longitude
- Pending Sync Count

Buttons:

- Mark Attendance
- Check Out

---

# Background Service

Use:

- flutter_background_service

Responsibilities:

- Receive GPS location
- Save locally
- Trigger synchronization
- Continue running after app minimization
- Recover after reboot

---

# Repository Pattern

Presentation

↓

Repository

↓

Local Database

↓

Firebase

No screen should directly access Firebase.

---

# Logging

Use:

- logger

Log:

- Login
- Attendance
- Check Out
- Tracking Started
- Tracking Stopped
- GPS Update
- Offline Save
- Sync Started
- Sync Completed
- Sync Failed
- Device Reboot
- Service Restart

---

# Connectivity

Use:

- connectivity_plus

Detect:

- Mobile Data
- WiFi
- Offline Mode

Automatically trigger synchronization.

---

# Packages

## Architecture

- flutter_bloc
- equatable
- get_it

## Firebase

- firebase_core
- firebase_auth
- cloud_firestore

## Local Storage

- drift
- path_provider
- shared_preferences

## Background Services

- flutter_background_service

## Location

- geolocator

## Permissions

- permission_handler

## Connectivity

- connectivity_plus

## Network

- http

## Utilities

- logger
- intl

---

# Folder Structure

```
lib/

core/
    constants/
    helpers/
    services/
    utils/

data/
    datasource/
        local/
        remote/
    models/
    repositories/

domain/
    entities/
    repositories/
    usecases/

presentation/
    bloc/
    screens/
    widgets/

main.dart
```

---

# Coding Standards

- Clean Architecture
- SOLID Principles
- Repository Pattern
- Dependency Injection
- Null Safety
- Modular Development
- Feature-Based Structure
- Reusable Widgets
- Proper Documentation
- Production Ready Code

---

# Future Features (Not Part of POC)

The application architecture should support future implementation of:

- Employee Login
- Company Login
- QR Attendance
- Face Recognition Attendance
- Geofencing
- Shift Management
- Work Schedule
- Break Management
- Leave Management
- Holiday Calendar
- Attendance History
- Live Employee Tracking
- Admin Dashboard
- Reports
- Analytics
- Payroll
- Expense Management
- Team Management
- Push Notifications
- Multi Organization Support
- Role Based Access Control
- Web Admin Panel

---

# POC Success Criteria

The POC will be considered successful if it demonstrates the following:

- Employee can mark attendance.
- Attendance creates a tracking session.
- Background location tracking starts immediately.
- Tracking continues while the app is minimized.
- Tracking automatically resumes after device reboot.
- Tracking continues even if internet is unavailable.
- Every location is stored locally before syncing.
- Pending locations synchronize automatically once internet is restored.
- Check Out successfully stops tracking.
- No location data is lost.
- The architecture is scalable, maintainable, and ready for enterprise-level expansion.

---

# Important Notes

- This is an Android-only Proof of Concept.
- Focus on reliability rather than UI design.
- UI should be simple, clean, and functional.
- Firebase is a temporary backend and will be replaced with REST APIs in the future.
- The project should be developed with scalability in mind, ensuring that new enterprise modules can be added without major architectural changes.
- Every feature should be implemented in a modular manner with clear separation of concerns.
 */