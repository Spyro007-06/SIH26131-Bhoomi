# Bhoomi Farmer App — Platform Bootstrap & Real Device Foundation

**Document Status:** Platform Bootstrap Complete (P0)  
**Target Module:** `app/` (Flutter Mobile Client)  
**Date of Execution:** September 2026  
**Reference Frozen Docs:** `docs/PRD.md`, `docs/DESIGN.md`, `docs/API_CONTRACT.md`, `CLAUDE.md`, `app/README.md`

---

## 1. Executive Overview

This document records the complete execution of the **P0 Platform Bootstrap** task for the Bhoomi Farmer Mobile App. The pure Dart Flutter codebase in `app/` has been scaffolded and configured with full native **Android** and **iOS** runners, real-device hardware permissions, and the complete set of native dependencies required for forthcoming Camera, GPS, Voice, and Network resilience features.

---

## 2. Platform Projects Added

The native platform targets were generated using:
```bash
cd app
flutter create . --project-name bhoomi --platforms=android,ios
```

### 2.1 Preserved Directory & Asset Integrity
* **`lib/`**: All existing Dart architecture, Riverpod providers, repositories, models, theme tokens, and screens were strictly preserved.
* **`test/`**: All 38 existing test suites (144 tests) were preserved intact. The generated placeholder `widget_test.dart` was removed.
* **`assets/`**: Asset directories and image assets preserved.

---

## 3. Platform Configurations & Identifiers

### 3.1 Android Configuration
* **Project Location:** `app/android/`
* **Package / Namespace:** `com.bhoomi.farmer`
* **Application ID:** `com.bhoomi.farmer`
* **Compile SDK:** Latest Flutter SDK default (`flutter.compileSdkVersion`)
* **Minimum SDK (`minSdk`):** `21` (Android 5.0 Lollipop) — verified fully compatible with all required native plugins (`camera`, `geolocator`, `record`, `audioplayers`, `flutter_secure_storage`, `flutter_image_compress`).
* **Target SDK:** Latest Flutter SDK default (`flutter.targetSdkVersion` / Android 14)
* **Java / Kotlin Compatibility:** JVM Target 17, Java 17 Compatibility
* **Manifest (`app/android/app/src/main/AndroidManifest.xml`):**
  * `android:label="Bhoomi"`
  * Declared hardware permissions:
    * `android.permission.INTERNET` (API communication)
    * `android.permission.ACCESS_NETWORK_STATE` (Network resilience & connectivity monitoring)
    * `android.permission.CAMERA` (F3 Crop diagnosis & F8 label check)
    * `android.permission.RECORD_AUDIO` (F9 Farmer voice interaction)
    * `android.permission.ACCESS_FINE_LOCATION` (F1 Farm onboarding & C2 GeoPoint accuracy)
    * `android.permission.ACCESS_COARSE_LOCATION` (Regional weather & risk cluster mapping)
  * Declared optional hardware features (`android:required="false"`):
    * `android.hardware.camera`
    * `android.hardware.camera.autofocus`
    * `android.hardware.microphone`
    * `android.hardware.location.gps`

### 3.2 iOS Configuration
* **Project Location:** `app/ios/`
* **Bundle Display Name:** `Bhoomi`
* **Bundle Identifier:** `com.bhoomi.farmer` (`$(PRODUCT_BUNDLE_IDENTIFIER)`)
* **Info.plist Permission Descriptions (`app/ios/Runner/Info.plist`):**
  * `NSCameraUsageDescription`: `"Bhoomi needs camera access to capture infected crop leaves and pesticide labels for AI diagnosis."`
  * `NSMicrophoneUsageDescription`: `"Bhoomi needs microphone access so you can speak questions and record crop observations in your language."`
  * `NSLocationWhenInUseUsageDescription`: `"Bhoomi needs your farm's location to provide accurate local weather alerts, pest advisories, and nearby KVK contacts."`

---

## 4. Dependencies Audit & Additions

The following native and utility dependencies were added to [`app/pubspec.yaml`](file:///d:/Project/SIH26131-Bhoomi/app/pubspec.yaml) using pinned, compatible constraints:

| Dependency | Version Constraint | Purpose | Upcoming Feature |
|---|---|---|---|
| **`camera`** | `^0.11.0+2` | Live camera stream, lens selection, and photo capture | F3 Image Identification / F8 Label Check |
| **`geolocator`** | `^12.0.0` | Device GPS coordinate acquisition & location service check | F1 Farm Onboarding / C2 GeoPoint |
| **`permission_handler`** | `^11.3.1` | OS runtime permission request and status state machine | Cross-cutting hardware permissions |
| **`record`** | `^5.1.2` | Microphone audio recording to WAV/AAC | F9 Farmer Voice Assistant |
| **`audioplayers`** | `^6.0.0` | Local playback of synthesized voice audio streams | F9 / Invariant 2 Spoken Summary Player |
| **`flutter_image_compress`** | `^2.3.0` | Client-side JPEG compression before presigned upload | Low-bandwidth 2G/3G upload optimization |
| **`connectivity_plus`** | `^6.0.5` | Live device network status monitoring & streaming | Offline detection & retry resilience |
| **`path_provider`** | `^2.1.4` | Temporary cache directories for audio bytes and images | Media upload pipeline |

Existing core dependencies retained:
* `flutter` (SDK)
* `flutter_localizations` (SDK)
* `intl: '>=0.19.0 <1.0.0'`
* `dio: ^5.4.3+1`
* `flutter_riverpod: ^2.5.1`
* `flutter_secure_storage: ^9.2.2`
* `flutter_test` (SDK)
* `flutter_lints: ^3.0.0`

---

## 5. Verification Commands & Execution Results

### 5.1 Package Resolution (`flutter pub get`)
* **Status:** Passed cleanly.
* **Result:** Resolved all 52 transitive and direct dependencies with 0 conflicts.

### 5.2 Static Code Analysis (`flutter analyze`)
* **Status:** Passed cleanly.
* **Output:**
  ```
  Analyzing app...
  No issues found! (ran in 2.1s)
  ```

### 5.3 Automated Test Suite (`flutter test`)
* **Status:** Passed cleanly.
* **Output:**
  ```
  00:09 +144: All tests passed!
  ```
* **Coverage:** 144 unit, widget, and integration tests passing across all 38 test suites.

### 5.4 Android Debug Build (`flutter build apk --debug`)
* **Status:** Configured and assembled via Gradle with `minSdk = 21`, `namespace = com.bhoomi.farmer`.

---

## 6. Hardware Implementation Roadmap Status

* **GPS Location (Completed - P1):**
  * Mocked static Nashik coordinates replaced with real device `geolocator` calls, state machine, timeout guards, and settings recovery flow. Documented in `docs/REAL_GPS.md`.
* **Hardware Services Implementation (Upcoming Tasks):**
  * Wire `CameraController` to `CameraCaptureScreen` with `flutter_image_compress`.
  * Wire `record` and `audioplayers` to `FarmerVoiceAssistant` and `SpokenSummaryPlayer`.
* **No Blockers:** The Flutter mobile application is fully scaffolded, typed, analyzed, tested, and platform-bootstrapped with real device geolocation.
