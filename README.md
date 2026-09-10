# 🛡️ Rakshak Connect (रक्षक कनेक्ट)
### Smart Emergency Response, Citizen Safety & Assistance System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Rakshak Connect** is a feature-packed, production-ready emergency safety and rapid response mobile application developed with Flutter, Firebase, and OpenStreetMap. Designed for distress scenarios, it provides instant 1-tap SOS dispatch, background-resilient tools, live GPS breadcrumb tracking, offline SMS fallback, and a native Android Home Screen widget.

---

## ✨ Key Features

### 🚨 1. Instant 1-Tap Emergency SOS & Offline Fallback
- **Multi-Channel Alert Dispatch:** Sends precise Google Maps coordinates and emergency messages via direct hardware **SMS** and **WhatsApp**.
- **Offline Queue Sync:** In low-connectivity or no-internet zones, alerts are cached locally and automatically synchronized with Cloud Firestore upon reconnection.
- **Ambient Audio Recording:** Automatically captures a 20-second ambient audio recording as emergency evidence and attaches it to the alert record.

### 📍 2. Dual-Engine Live GPS Radar & Breadcrumb Tracking
- **Dual Vector & Tile Mapping:** Seamless 1-tap switching between **Mappls (MapmyIndia)** high-precision Indian vector maps and **OpenStreetMap (OSM)**.
- **Live Polyline Trail:** Glowing neon dual-tone breadcrumb trail with movement-type detection (Walking, Running, Driving) and offline persistent cache.
- **Safe Places POI Radar:** Instant real-time discovery of nearby **Police Stations**, **Hospitals**, **Fire Stations**, and **Safe Shelters** with custom pinpoint badges and quick actions.
- **Accurate Road Routing:** Real turn-by-turn road navigation powered by Mappls Direction API / OSRM with distance in **km** and trip duration, avoiding direct Euclidean lines over buildings.
- **Telemetry HUD Drawer:** Real-time speedometer (km/h), GPS accuracy radius, total distance traveled, and dynamic compass heading indicator.

### 🛡️ 3. Native Android Home Screen Quick SOS Widget (AppWidget)
- **Direct Phone Desktop Access:** Launch critical actions directly from the phone launcher without opening the app:
  - 🚨 **1-Tap SOS Button:** Instant emergency SMS + GPS dispatch.
  - 📢 **Panic Siren:** Instant high-decibel alarm & camera flashlight strobe.
  - 📞 **Fake Call:** Instant incoming call escape.
  - 🟢 **Live Status Indicator:** Real-time emergency contact readiness counter.

### 📢 4. High-Decibel Panic Siren & Strobe Alarm
- **Multi-Sensory Deterrent:** High-frequency audio alarm paired with a **250ms camera flashlight strobe** and screen pulsing to deter attackers and attract bystanders.
- **Hardware Safety:** Automatic lifecycle observers safely release torch and camera hardware when the app is paused.

### 📞 5. Background-Resilient Fake Incoming Call
- **Discreet Safety Exit:** Simulates realistic full-screen incoming calls (caller photo, ringtone audio, vibrating motor, in-call dialer timer).
- **Background Persistence:** Scheduled timers fire reliably even if the app was minimized or the device screen was locked.

### 🩺 6. Digital Medical ID (ICE - In Case of Emergency)
- **Instant Responder Card:** Quick-access digital medical card displaying Blood Group, Organ Donor status, Allergies, Chronic Conditions, Emergency Medications, and Primary Physician.
- **1-Tap Doctor Dialing & SMS Sharing:** Directly contact medical personnel or share ICE details via SMS.

### 🌐 7. Multi-Language Indian Localization
- Supports **7 Indian Languages** with live dynamic in-app language switching:
  - 🇮🇳 English
  - 🇮🇳 हिन्दी (Hindi)
  - 🇮🇳 ગુજરાતી (Gujarati)
  - 🇮🇳 मराठी (Marathi)
  - 🇮🇳 தமிழ் (Tamil)
  - 🇮🇳 తెలుగు (Telugu)
  - 🇮🇳 বাংলা (Bengali)

---

## 🛠️ Technology Stack & Architecture

- **Frontend Framework:** [Flutter](https://flutter.dev) (Material 3, Dark & Light Mode, Glassmorphism UI)
- **State Management:** [Provider](https://pub.dev/packages/provider) (Separation of concerns, selective widget rebuilds)
- **Backend & Cloud:** [Firebase Authentication](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore), [Firebase Cloud Messaging](https://firebase.google.com/products/cloud-messaging)
- **Maps & Navigation:** [flutter_map](https://pub.dev/packages/flutter_map) with OpenStreetMap vector tiles & [geolocator](https://pub.dev/packages/geolocator)
- **Hardware Integrations:** `torch_light` (Camera Strobe), `audioplayers` (Siren & Ringtone), `record` (Ambient Mic Evidence), `home_widget` (Android AppWidget)

---

## 🚀 Getting Started & Installation

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.0 or higher)
- [Android Studio](https://developer.android.com/studio) / VS Code with Flutter extensions
- Android SDK 34+ (compileSdk 36)

### 2. Clone the Repository
```bash
git clone https://github.com/<your-username>/rakshak-connect.git
cd rakshak-connect
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Firebase Configuration
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com).
2. Enable **Email/Password Authentication** and **Cloud Firestore Database**.
3. Download `google-services.json` and place it in:
   ```text
   android/app/google-services.json
   ```

### 5. Run & Build the Application
```bash
# Run in debug mode on connected Android device/emulator
flutter run

# Build optimized split release APKs (Recommended: saves ~60% size per architecture)
flutter build apk --split-per-abi

# Build unified fat release APK
flutter build apk --release
```

The compiled release APKs will be located at:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (Modern 64-bit phones)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (Older 32-bit phones)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (Emulators & tablets)

---

## 📁 Project Directory Structure

```text
lib/
├── constants/       # AppColors, AppStrings, AppRoutes, Theme data
├── localization/    # Multi-language translations & delegates (7 Indian languages)
├── models/          # AlertModel, ContactModel, MedicalProfileModel, BreadcrumbModel, SafePlaceModel
├── providers/       # AuthProvider, ContactProvider, AlertProvider, LocationProvider
├── screens/
│   ├── auth/        # Login, Signup, OTP Verification
│   ├── contacts/    # Emergency Contacts List & CRUD
│   ├── fake_call/   # Setup & Simulated Incoming Call Screen
│   ├── history/     # Alert History with 3-state filter engine
│   ├── home/        # Dashboard with SOS trigger & quick cards
│   ├── location/    # Dual-Engine Live Radar (Mappls & OSM) + Safe Places Drawer
│   ├── medical_id/  # ICE Profile display & edit forms
│   ├── siren/       # Panic Alarm & Flashlight Strobe
│   └── splash/      # Animated splash screen
├── services/        # Firestore, SMS, GPS Tracking, Audio Recorder, RoutingService, SafePlacesService
└── widgets/         # Reusable UI components, Radar Drawer, Quick Cards
```

---

## 🔒 Permissions Used
- `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`: For GPS location alerts and live breadcrumb streaming.
- `SEND_SMS` & `CALL_PHONE`: For dispatching emergency SMS and 1-tap contact dialing.
- `RECORD_AUDIO`: For recording ambient emergency audio evidence.
- `CAMERA` & `FLASHLIGHT`: For the panic strobe alarm.
- `WAKE_LOCK` & `FOREGROUND_SERVICE`: For background-resilient fake call timers and siren playback.

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
